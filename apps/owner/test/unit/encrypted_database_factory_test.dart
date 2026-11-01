import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:owner/data/database/encrypted_database_factory.dart';
import 'package:owner/database/pot/encryption_key_material.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  const testKeyHexA =
      '0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20';
  const testKeyHexB =
      'fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210';

  group('EncryptedDatabaseFactory (F-06)', () {
    late Directory tempDir;
    late File dbFile;
    const factory = EncryptedDatabaseFactory();

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('walimapp_db_factory_test_');
      dbFile = File('${tempDir.path}/test_encrypted.db');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        try {
          await tempDir.delete(recursive: true);
        } catch (_) {
          // Ignore Windows file lock delays
        }
      }
    });

    test('reports canonical expected cipher as chacha20', () {
      expect(factory.expectedCipher, 'chacha20');
    });

    test('opens verified encrypted database, executes queries, and closes cleanly', () {
      final keyMaterial = EncryptionKeyMaterial.fromHex(testKeyHexA);

      final db = factory.openEncryptedDatabase(
        dbFile: dbFile,
        keyMaterial: keyMaterial,
      );

      // Verify operational queries execute
      db.execute('CREATE TABLE sample_venue (id INTEGER PRIMARY KEY, name TEXT, city TEXT);');
      db.execute("INSERT INTO sample_venue (name, city) VALUES ('Salle El Bahdja', 'Alger');");

      final rows = db.select('SELECT id, name, city FROM sample_venue WHERE id = 1;');
      expect(rows, hasLength(1));
      expect(rows.first['name'], 'Salle El Bahdja');
      expect(rows.first['city'], 'Alger');

      // Verify PRAGMA cipher returns chacha20
      final cipherCheck = db.select('PRAGMA cipher;');
      expect(cipherCheck.first.values.first, 'chacha20');

      db.close();
      keyMaterial.dispose();
    });

    test('reopens existing database with matching key and verifies data persistence', () {
      final key1 = EncryptionKeyMaterial.fromHex(testKeyHexA);
      final db1 = factory.openEncryptedDatabase(dbFile: dbFile, keyMaterial: key1);
      db1.execute('CREATE TABLE persisted_data (id INTEGER PRIMARY KEY, note TEXT);');
      db1.execute("INSERT INTO persisted_data (note) VALUES ('Persisted in encrypted file');");
      db1.close();
      key1.dispose();

      // Reopen with matching key
      final key2 = EncryptionKeyMaterial.fromHex(testKeyHexA);
      final db2 = factory.openEncryptedDatabase(dbFile: dbFile, keyMaterial: key2);
      final rows = db2.select('SELECT note FROM persisted_data WHERE id = 1;');
      expect(rows.first['note'], 'Persisted in encrypted file');
      db2.close();
      key2.dispose();
    });

    test('rejects wrong key with SQLITE_NOTADB (extended code 26)', () {
      final validKey = EncryptionKeyMaterial.fromHex(testKeyHexA);
      final db1 = factory.openEncryptedDatabase(dbFile: dbFile, keyMaterial: validKey);
      db1.execute('CREATE TABLE secret (val TEXT);');
      db1.execute("INSERT INTO secret VALUES ('confidential');");
      db1.close();
      validKey.dispose();

      // Attempt to open with wrong key material
      final wrongKey = EncryptionKeyMaterial.fromHex(testKeyHexB);
      expect(
        () => factory.openEncryptedDatabase(dbFile: dbFile, keyMaterial: wrongKey),
        throwsA(
          isA<SqliteException>().having(
            (e) => e.extendedResultCode,
            'extendedResultCode',
            26, // SQLITE_NOTADB
          ),
        ),
      );
      wrongKey.dispose();
    });

    test('rejects invalid key hex string before touching SQLite database', () {
      expect(
        () => EncryptionKeyMaterial.fromHex('short'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => EncryptionKeyMaterial.fromHex('zz' * 32),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
