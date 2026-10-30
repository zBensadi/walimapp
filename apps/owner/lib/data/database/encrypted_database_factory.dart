import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import '../../database/pot/encrypted_sqlite_opener.dart';
import '../../database/pot/encryption_key_material.dart';

/// Reusable factory service for opening fail-closed encrypted SQLite database connections.
///
/// Wraps the verified [EncryptedSqliteOpener] from Feature 001, enforcing `sqlite3mc`
/// (`chacha20`, `legacy = 0`) AEAD encryption with pre-key cipher verification and
/// fail-closed runtime guards across debug, profile, and release builds.
///
/// Per FR-002 and FR-012, this factory introduces **zero** production business tables
/// in this slice and serves as the architectural bridge for future venue-scoped repositories.
class EncryptedDatabaseFactory {
  const EncryptedDatabaseFactory();

  /// Canonical cipher expected for all WalimApp encrypted SQLite databases.
  String get expectedCipher => kExpectedSqlite3McCipher;

  /// Opens a raw SQLite database file with fail-closed `sqlite3mc` encryption.
  ///
  /// Enforces:
  /// 1. Pre-key configuration: `PRAGMA cipher = 'chacha20'`, `PRAGMA legacy = 0`.
  /// 2. Pre-key guard: Verifies active cipher is `chacha20` and legacy is `0`.
  /// 3. Key application: `PRAGMA key = "x'<hex>'"` applied only after verification.
  /// 4. Post-key test: Schema-touching query to verify page 1 decryption.
  /// 5. Operational PRAGMAs: Foreign keys enabled, WAL journal mode, Normal sync.
  Database openEncryptedDatabase({
    required File dbFile,
    required EncryptionKeyMaterial keyMaterial,
    bool enableWal = true,
  }) {
    final (rawDb, _) = EncryptedSqliteOpener.openRawVerifiedDatabase(
      dbFile: dbFile,
      keyMaterial: keyMaterial,
      enableWal: enableWal,
    );
    return rawDb;
  }
}
