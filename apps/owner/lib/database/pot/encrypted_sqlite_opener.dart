import 'dart:io';

import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';

import 'encryption_key_material.dart';
import 'pot_database.dart';

/// Canonical canonical cipher identifier required by Constitution Principle I
/// and `ADR-002` (`sqlite3mc` ChaCha20-Poly1305 256-bit AEAD).
const String kExpectedSqlite3McCipher = 'chacha20';

/// Result of opening and verifying an encrypted `sqlite3mc` connection.
final class VerifiedEncryptedConnection {
  const VerifiedEncryptedConnection({
    required this.database,
    required this.rawDatabase,
    required this.activeCipher,
    required this.sqliteVersion,
  });

  final PotDatabase database;
  final Database rawDatabase;
  final String activeCipher;
  final String sqliteVersion;

  Future<void> close() async {
    await database.close();
  }
}

/// Fail-closed SQLite Multiple Ciphers (`sqlite3mc`) connection opener (`FR-002`..`FR-005`).
///
/// Enforces the mandatory pre-key verification sequence across `debug`,
/// `profile`, and `release` builds:
/// 1. Explicitly sets `PRAGMA cipher = 'chacha20';` and `PRAGMA legacy = 0;`.
/// 2. **Before applying `PRAGMA key`**, queries `SELECT sqlite3mc_config('cipher');`
///    (and falls back to `PRAGMA cipher;` if needed) plus `SELECT sqlite3mc_config('chacha20', 'legacy');`
///    to verify that the `sqlite3mc` encryption extension is active and has selected
///    `'chacha20'` (`legacy = 0`) for the upcoming key operation.
///    Why before `PRAGMA key`? In `sqlite3mc`, `sqlite3mc_config('cipher')` without a
///    prefix reports the cipher configured for the next `key`/`rekey` operation and
///    transient parameters revert after use.
/// 3. Applies `PRAGMA key = "x'<64-hex>'";` only after pre-key verification succeeds.
/// 4. Executes a schema-touching query (`SELECT count(*) FROM sqlite_master;`) to
///    verify that the database header/page 1 can be decrypted and read (`SQLITE_NOTADB`
///    result code `26` is thrown immediately on key or cipher mismatch).
/// 5. Applies standard connection PRAGMAs (`foreign_keys = ON`, `journal_mode = WAL`,
///    `synchronous = NORMAL`).
final class EncryptedSqliteOpener {
  const EncryptedSqliteOpener._();

  /// Opens [dbFile] with [keyMaterial] and wraps it in a [PotDatabase].
  ///
  /// [expectedCipherOverride] and [configuredCipherOverride] exist strictly to
  /// allow automated negative testing of the unconditional runtime fail-closed
  /// `StateError` guard (`FR-003`) in all build modes (`debug`, `profile`,
  /// `release`).
  static VerifiedEncryptedConnection openPotDatabase({
    required File dbFile,
    required EncryptionKeyMaterial keyMaterial,
    String expectedCipherOverride = kExpectedSqlite3McCipher,
    String configuredCipherOverride = kExpectedSqlite3McCipher,
    bool enableWal = true,
  }) {
    final (rawDb, activeCipher) = openRawVerifiedDatabase(
      dbFile: dbFile,
      keyMaterial: keyMaterial,
      expectedCipherOverride: expectedCipherOverride,
      configuredCipherOverride: configuredCipherOverride,
      enableWal: enableWal,
    );

    final executor = NativeDatabase.opened(
      rawDb,
      closeUnderlyingOnClose: true,
    );
    final potDb = PotDatabase(executor);
    return VerifiedEncryptedConnection(
      database: potDb,
      rawDatabase: rawDb,
      activeCipher: activeCipher,
      sqliteVersion: sqlite3.version.libVersion,
    );
  }

  /// Opens a raw `sqlite3` [Database] at [dbFile] using the fail-closed
  /// 5-step `sqlite3mc` verification sequence.
  ///
  /// Throws:
  /// - [StateError] if [keyMaterial] is disposed, if `sqlite3mc` is unavailable,
  ///   or if the pre-key active cipher / `legacy` setting does not match
  ///   [expectedCipherOverride] (`'chacha20'`) and `legacy == 0`.
  /// - [SqliteException] (result code `26` / `SQLITE_NOTADB`) if [dbFile] is an
  ///   existing database encrypted with a different key or cipher.
  static (Database, String) openRawVerifiedDatabase({
    required File dbFile,
    required EncryptionKeyMaterial keyMaterial,
    String expectedCipherOverride = kExpectedSqlite3McCipher,
    String configuredCipherOverride = kExpectedSqlite3McCipher,
    bool enableWal = true,
  }) {
    // Validate key material before touching SQLite (`FR-004`).
    final keyLiteral = keyMaterial.toSqliteBlobLiteral();

    dbFile.parent.createSync(recursive: true);
    final rawDb = sqlite3.open(dbFile.path);

    try {
      // Step 1: Explicitly configure transient cipher parameters BEFORE PRAGMA key (`FR-002`).
      rawDb.execute("PRAGMA cipher = '$configuredCipherOverride';");
      rawDb.execute('PRAGMA legacy = 0;');

      // Step 2: Unconditionally verify pre-key cipher selection & sqlite3mc availability
      // BEFORE applying PRAGMA key (`FR-003`). Never use `assert(...)`.
      final activeCipher = _readConfiguredCipherBeforeKey(rawDb);
      if (activeCipher != expectedCipherOverride) {
        throw StateError(
          'Fail-closed SQLite encryption guard triggered before PRAGMA key: '
          'expected pre-key cipher "$expectedCipherOverride", '
          'but sqlite3mc reported "$activeCipher".',
        );
      }

      final activeLegacy = _readConfiguredLegacyBeforeKey(
        rawDb,
        cipherName: activeCipher,
      );
      if (activeLegacy != 0) {
        throw StateError(
          'Fail-closed SQLite encryption guard triggered before PRAGMA key: '
          'expected legacy = 0 for cipher "$activeCipher", '
          'but sqlite3mc reported "$activeLegacy".',
        );
      }

      // Step 3: Apply the 256-bit key ONLY after pre-key cipher verification succeeds (`FR-004`).
      rawDb.execute('PRAGMA key = "$keyLiteral";');

      // Step 4: Execute a schema-touching query to verify page 1 decryption (`FR-005`).
      rawDb.select('SELECT count(*) FROM sqlite_master;');

      // Step 5: Configure operational PRAGMAs on the authenticated connection (`FR-005`).
      rawDb.execute('PRAGMA foreign_keys = ON;');
      if (enableWal) {
        rawDb.execute('PRAGMA journal_mode = WAL;');
      }
      rawDb.execute('PRAGMA synchronous = NORMAL;');

      return (rawDb, activeCipher);
    } on Object {
      rawDb.close();
      rethrow;
    }
  }

  /// Attempts to open and read [dbFile] with **no** `PRAGMA key` applied,
  /// used strictly in Check 3 (`US3` / `FR-009`) to prove that an unkeyed
  /// standard SQLite connection is rejected with `SQLITE_NOTADB` (`26`).
  static void probeUnkeyedReadAndDispose(File dbFile) {
    final rawDb = sqlite3.open(dbFile.path);
    try {
      rawDb.select('SELECT count(*) FROM sqlite_master;');
    } finally {
      rawDb.close();
    }
  }

  static String _readConfiguredCipherBeforeKey(Database rawDb) {
    // Note: On an existing encrypted database file, preparing a `SELECT ...`
    // statement before `PRAGMA key` triggers `sqlite3ReadSchema()` on encrypted
    // page 1 and fails with `SQLITE_NOTADB (26)`. `PRAGMA cipher;` and
    // `PRAGMA legacy;` execute with `PragFlg_NeedSchema == 0` before `PRAGMA key`.
    try {
      final pragmaResult = rawDb.select('PRAGMA cipher;');
      if (pragmaResult.isNotEmpty && pragmaResult.first.values.isNotEmpty) {
        final value = pragmaResult.first.values.first?.toString().trim();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    } on SqliteException catch (e) {
      throw StateError(
        'Fail-closed SQLite encryption guard: PRAGMA cipher failed '
        '(${e.message}).',
      );
    }

    try {
      final result = rawDb.select("SELECT sqlite3mc_config('cipher') AS cipher;");
      if (result.isNotEmpty) {
        final value = result.first['cipher']?.toString().trim();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    } on SqliteException catch (e) {
      throw StateError(
        'Fail-closed SQLite encryption guard: sqlite3mc_config(\'cipher\') '
        'is unavailable (${e.message}). Native sqlite3mc build hook did not '
        'link SQLite3 Multiple Ciphers.',
      );
    }

    return '<empty>';
  }

  static int? _readConfiguredLegacyBeforeKey(
    Database rawDb, {
    required String cipherName,
  }) {
    try {
      final pragmaResult = rawDb.select('PRAGMA legacy;');
      if (pragmaResult.isNotEmpty && pragmaResult.first.values.isNotEmpty) {
        final rawValue = pragmaResult.first.values.first;
        if (rawValue is int) {
          return rawValue;
        }
        if (rawValue != null) {
          return int.tryParse(rawValue.toString().trim());
        }
      }
    } on SqliteException catch (e) {
      throw StateError(
        'Fail-closed SQLite encryption guard: PRAGMA legacy failed '
        '(${e.message}).',
      );
    }

    try {
      final result = rawDb.select(
        "SELECT sqlite3mc_config('$cipherName', 'legacy') AS legacy;",
      );
      if (result.isNotEmpty) {
        final rawValue = result.first['legacy'];
        if (rawValue is int) {
          return rawValue;
        }
        if (rawValue != null) {
          return int.tryParse(rawValue.toString().trim());
        }
      }
    } on SqliteException catch (e) {
      throw StateError(
        'Fail-closed SQLite encryption guard: sqlite3mc_config(\'$cipherName\', \'legacy\') '
        'failed (${e.message}).',
      );
    }
    return null;
  }
}
