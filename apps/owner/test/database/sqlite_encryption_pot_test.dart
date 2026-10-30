import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:owner/database/pot/encrypted_sqlite_opener.dart';
import 'package:owner/database/pot/encryption_key_material.dart';
import 'package:owner/database/pot/pot_database.dart';
import 'package:owner/database/pot/sqlite_encryption_pot_suite.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' hide Row;
import 'package:uuid/uuid.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('walimapp_pot_unit_test_');
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } on Object {
      // Ignore Windows file lock cleanup delays.
    }
  });

  group('US1 — Fail-Closed Encrypted Database Lifecycle with Correct Key', () {
    test(
      'verifies pre-key chacha20 & legacy=0 configuration before PRAGMA key, '
      'writes trilingual + integer DZD row, closes, reopens, and reads identical data',
      () async {
        final dbFile = File(p.join(tempDir.path, 'us1_lifecycle.db'));
        final keyA = EncryptionKeyMaterial.fromHex(kPotTestKeyHexA);
        addTearDown(keyA.dispose);

        final conn1 = EncryptedSqliteOpener.openPotDatabase(
          dbFile: dbFile,
          keyMaterial: keyA,
        );
        expect(conn1.activeCipher, equals('chacha20'));
        expect(conn1.sqliteVersion, isNotEmpty);

        final recordId = const Uuid().v4();
        final expected = PotProbeRecord(
          id: recordId,
          sentinelText: kPotSentinelText,
          localeSampleAr: kPotSampleAr,
          localeSampleFr: kPotSampleFr,
          localeSampleEn: kPotSampleEn,
          amountDzd: kPotSampleAmountDzd,
          createdAtUtc: kPotSampleCreatedAtUtc,
        );

        await conn1.database.insertProbeRecord(expected);
        await conn1.close();

        final conn2 = EncryptedSqliteOpener.openPotDatabase(
          dbFile: dbFile,
          keyMaterial: keyA,
        );
        final integrity = await conn2.database.runIntegrityCheck();
        final actual = await conn2.database.getProbeRecordById(recordId);
        await conn2.close();

        expect(integrity.toLowerCase(), equals('ok'));
        expect(actual, isNotNull);
        expect(actual, equals(expected));
        expect(actual!.localeSampleAr, equals(kPotSampleAr));
        expect(actual.localeSampleFr, equals(kPotSampleFr));
        expect(actual.localeSampleEn, equals(kPotSampleEn));
        expect(actual.amountDzd, equals(250000));
      },
    );

    test(
      'fails closed with unconditional StateError before PRAGMA key when '
      'pre-key cipher does not match expected cipher',
      () {
        final dbFile = File(p.join(tempDir.path, 'us1_mismatch.db'));
        final keyA = EncryptionKeyMaterial.fromHex(kPotTestKeyHexA);
        addTearDown(keyA.dispose);

        expect(
          () => EncryptedSqliteOpener.openRawVerifiedDatabase(
            dbFile: dbFile,
            keyMaterial: keyA,
            expectedCipherOverride: 'aes256cbc',
          ),
          throwsA(
            isA<StateError>().having(
              (StateError e) => e.message,
              'message',
              contains('Fail-closed SQLite encryption guard triggered before PRAGMA key'),
            ),
          ),
        );
      },
    );

    test(
      'rejects malformed key strings with ArgumentError before opening SQLite '
      'and zeros key bytes on dispose()',
      () {
        expect(
          () => EncryptionKeyMaterial.fromHex(''),
          throwsArgumentError,
        );
        expect(
          () => EncryptionKeyMaterial.fromHex('1234'),
          throwsArgumentError,
        );
        expect(
          () => EncryptionKeyMaterial.fromHex(kPotTestKeyHexA.substring(0, 63)),
          throwsArgumentError,
        );
        expect(
          () => EncryptionKeyMaterial.fromHex('g' * 64),
          throwsArgumentError,
        );

        final key = EncryptionKeyMaterial.fromHex(kPotTestKeyHexA.toUpperCase());
        expect(key.lengthInBytes, equals(32));
        expect(key.toSqliteBlobLiteral(), equals("x'$kPotTestKeyHexA'"));
        key.dispose();
        expect(key.isDisposed, isTrue);
        expect(key.toSqliteBlobLiteral, throwsStateError);
      },
    );
  });

  group('US2 — Raw File Ciphertext & Non-Plaintext Verification on Disk', () {
    test(
      'on-disk encrypted .db and -wal files do not start with SQLite format 3 '
      'header and contain zero plaintext sentinel bytes',
      () async {
        final dbFile = File(p.join(tempDir.path, 'us2_ciphertext.db'));
        final walFile = File('${dbFile.path}-wal');
        final keyA = EncryptionKeyMaterial.fromHex(kPotTestKeyHexA);
        addTearDown(keyA.dispose);

        final conn = EncryptedSqliteOpener.openPotDatabase(
          dbFile: dbFile,
          keyMaterial: keyA,
        );
        await conn.database.insertProbeRecord(
          PotProbeRecord(
            id: const Uuid().v4(),
            sentinelText: kPotSentinelText,
            localeSampleAr: kPotSampleAr,
            localeSampleFr: kPotSampleFr,
            localeSampleEn: kPotSampleEn,
            amountDzd: kPotSampleAmountDzd,
            createdAtUtc: kPotSampleCreatedAtUtc,
          ),
        );

        if (walFile.existsSync() && walFile.lengthSync() > 0) {
          expect(
            SqliteEncryptionPotSuite.verifyFileContainsNoPlaintext(
              walFile,
              requireMinimumLength: false,
            ),
            isTrue,
            reason: 'Active -wal file must not leak plaintext sentinel bytes.',
          );
        }

        await conn.close();

        expect(dbFile.existsSync(), isTrue);
        expect(dbFile.lengthSync(), greaterThanOrEqualTo(100));
        expect(
          SqliteEncryptionPotSuite.verifyFileContainsNoPlaintext(
            dbFile,
            requireMinimumLength: true,
          ),
          isTrue,
          reason:
              'Flushed encrypted .db file must not start with SQLite header or contain plaintext.',
        );
      },
    );

    test(
      'control check: raw byte scanner detects plaintext in an unencrypted SQLite database',
      () {
        final plainDbFile = File(p.join(tempDir.path, 'us2_plain_control.db'));
        final rawDb = sqlite3.open(plainDbFile.path);
        rawDb.execute(
          'CREATE TABLE pot_probe_records (id TEXT PRIMARY KEY, sentinel_text TEXT);',
        );
        rawDb.execute(
          "INSERT INTO pot_probe_records VALUES ('1', '$kPotSentinelText');",
        );
        rawDb.close();

        expect(
          SqliteEncryptionPotSuite.verifyFileContainsNoPlaintext(
            plainDbFile,
            requireMinimumLength: true,
          ),
          isFalse,
          reason:
              'Scanner must fail when inspecting an unencrypted SQLite file.',
        );
      },
    );
  });

  group('US3 — Wrong-Key & Unencrypted Access Rejection (SQLITE_NOTADB)', () {
    test(
      'rejects wrong 256-bit key and unkeyed access with SQLITE_NOTADB (code 26) '
      'and preserves database integrity for valid-key reopen',
      () async {
        final dbFile = File(p.join(tempDir.path, 'us3_rejection.db'));
        final keyA = EncryptionKeyMaterial.fromHex(kPotTestKeyHexA);
        final keyB = EncryptionKeyMaterial.fromHex(kPotTestKeyHexB);
        addTearDown(() {
          keyA.dispose();
          keyB.dispose();
        });

        final recordId = const Uuid().v4();
        final expected = PotProbeRecord(
          id: recordId,
          sentinelText: kPotSentinelText,
          localeSampleAr: kPotSampleAr,
          localeSampleFr: kPotSampleFr,
          localeSampleEn: kPotSampleEn,
          amountDzd: kPotSampleAmountDzd,
          createdAtUtc: kPotSampleCreatedAtUtc,
        );

        final conn1 = EncryptedSqliteOpener.openPotDatabase(
          dbFile: dbFile,
          keyMaterial: keyA,
        );
        await conn1.database.insertProbeRecord(expected);
        await conn1.close();

        // Wrong key (Key_B != Key_A) must throw SqliteException with code 26 (SQLITE_NOTADB).
        expect(
          () => EncryptedSqliteOpener.openRawVerifiedDatabase(
            dbFile: dbFile,
            keyMaterial: keyB,
          ),
          throwsA(
            isA<SqliteException>().having(
              (SqliteException e) => e.extendedResultCode & 0xFF,
              'SQLITE_NOTADB primary result code',
              equals(SqlError.SQLITE_NOTADB),
            ),
          ),
        );

        // Unkeyed access must also throw SqliteException with code 26 (SQLITE_NOTADB).
        expect(
          () => EncryptedSqliteOpener.probeUnkeyedReadAndDispose(dbFile),
          throwsA(
            isA<SqliteException>().having(
              (SqliteException e) => e.extendedResultCode & 0xFF,
              'SQLITE_NOTADB primary result code',
              equals(SqlError.SQLITE_NOTADB),
            ),
          ),
        );

        // Subsequent reopen with valid Key_A must succeed with intact data.
        final conn2 = EncryptedSqliteOpener.openPotDatabase(
          dbFile: dbFile,
          keyMaterial: keyA,
        );
        final integrity = await conn2.database.runIntegrityCheck();
        final restored = await conn2.database.getProbeRecordById(recordId);
        await conn2.close();

        expect(integrity.toLowerCase(), equals('ok'));
        expect(restored, equals(expected));
      },
    );
  });

  group('Full Suite — PotVerificationReport Contract', () {
    test('runAllChecks() passes all 4 checks and serializes valid JSON report', () async {
      final report = await SqliteEncryptionPotSuite.runAllChecks(
        parentTempDir: tempDir,
      );

      expect(report.errorDetail, isNull);
      expect(report.activeCipher, equals('chacha20'));
      expect(report.lifecycleRoundtripPassed, isTrue);
      expect(report.rawFileEncryptedPassed, isTrue);
      expect(report.wrongKeyRejectedNotadbPassed, isTrue);
      expect(report.failClosedGuardPassed, isTrue);
      expect(report.allPassed, isTrue);
      expect(report.durationMs, greaterThanOrEqualTo(0));

      final stdoutLine = report.toStdoutLine();
      expect(stdoutLine, startsWith('POT_REPORT_JSON:'));
      final decoded = jsonDecode(
        stdoutLine.substring('POT_REPORT_JSON:'.length),
      ) as Map<String, Object?>;
      expect(decoded['active_cipher'], equals('chacha20'));
      expect(decoded['all_passed'], isTrue);
    });
  });
}
