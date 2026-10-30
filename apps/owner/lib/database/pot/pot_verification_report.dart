import 'dart:convert';

/// Structured result of executing the 4 mandatory SQLite encryption
/// Proof-of-Technology checks on a target platform and build mode (`FR-010`).
///
/// Matches `specs/001-sqlite-encryption-pot/contracts/pot-verification-report.schema.json`.
/// Note: [durationMs] is recorded as an informational timing measurement (`SC-004`),
/// not a hard pass/fail gate that triggers optimization work in this PoT.
final class PotVerificationReport {
  const PotVerificationReport({
    required this.platform,
    required this.buildMode,
    required this.sqliteVersion,
    required this.activeCipher,
    required this.lifecycleRoundtripPassed,
    required this.rawFileEncryptedPassed,
    required this.wrongKeyRejectedNotadbPassed,
    required this.failClosedGuardPassed,
    required this.durationMs,
    this.errorDetail,
  });

  /// Target platform (`'android'` or `'windows'`).
  final String platform;

  /// Flutter build mode (`'debug'`, `'profile'`, or `'release'`).
  final String buildMode;

  /// Runtime SQLite version string reported by `sqlite3.version.libVersion`.
  final String sqliteVersion;

  /// Active cipher verified prior to `PRAGMA key` (`'chacha20'`).
  final String activeCipher;

  /// Check 1 (`US1` / `FR-007`): Create, write trilingual + integer DZD row,
  /// close, reopen with same key, `PRAGMA integrity_check`, and verify read equality.
  final bool lifecycleRoundtripPassed;

  /// Check 2 (`US2` / `FR-008`): Raw on-disk `.db` (and `-wal`) file inspection
  /// confirms absence of `"SQLite format 3\x00"` header and zero occurrences of
  /// plaintext sentinel strings.
  final bool rawFileEncryptedPassed;

  /// Check 3 (`US3` / `FR-009`): Wrong-key and unkeyed access attempts both fail
  /// with `SqliteException` carrying extended result code `26` (`SQLITE_NOTADB`),
  /// without corrupting subsequent reopen with the valid key.
  final bool wrongKeyRejectedNotadbPassed;

  /// Check 4 (`US1` / `FR-003` / `FR-004`): Pre-key cipher mismatch throws
  /// unconditional `StateError` (never `assert`) and malformed key throws
  /// `ArgumentError`.
  final bool failClosedGuardPassed;

  /// Total wall-clock execution time in milliseconds (`SC-004` informational
  /// measurement).
  final int durationMs;

  /// Optional diagnostic message if any check failed.
  final String? errorDetail;

  /// `true` if and only if all 4 cryptographic and fail-closed checks passed
  /// and [activeCipher] is `'chacha20'`.
  bool get allPassed =>
      activeCipher == 'chacha20' &&
      lifecycleRoundtripPassed &&
      rawFileEncryptedPassed &&
      wrongKeyRejectedNotadbPassed &&
      failClosedGuardPassed;

  /// Converts this report to a JSON-encodable map matching
  /// `pot-verification-report.schema.json`.
  Map<String, Object?> toJson() => <String, Object?>{
        'platform': platform,
        'build_mode': buildMode,
        'sqlite_version': sqliteVersion,
        'active_cipher': activeCipher,
        'lifecycle_roundtrip_passed': lifecycleRoundtripPassed,
        'raw_file_encrypted_passed': rawFileEncryptedPassed,
        'wrong_key_rejected_notadb_passed': wrongKeyRejectedNotadbPassed,
        'fail_closed_guard_passed': failClosedGuardPassed,
        'duration_ms': durationMs,
        'all_passed': allPassed,
        if (errorDetail != null) 'error_detail': errorDetail,
      };

  /// Formats the single-line machine-readable stdout marker:
  /// `POT_REPORT_JSON:<json>`
  String toStdoutLine() => 'POT_REPORT_JSON:${jsonEncode(toJson())}';
}
