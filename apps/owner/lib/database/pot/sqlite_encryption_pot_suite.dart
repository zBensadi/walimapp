import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

import 'encrypted_sqlite_opener.dart';
import 'encryption_key_material.dart';
import 'pot_database.dart';
import 'pot_verification_report.dart';

/// Deterministic 256-bit (`64-hex`) test keys used exclusively by the isolated
/// SQLite encryption Proof-of-Technology suite.
const String kPotTestKeyHexA =
    '0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20';
const String kPotTestKeyHexB =
    'fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210';

/// High-entropy trilingual sentinel strings used for round-trip and raw
/// on-disk ciphertext verification (`FR-007`, `FR-008`, `SC-002`).
const String kPotSentinelText = 'WALIMAPP_PLAINTEXT_SENTINEL_قاعة_الحفلات_2026';
const String kPotSampleAr = 'قاعة الأفراح والولائم بالجزائر';
const String kPotSampleFr = 'Salle des fêtes El-Bahdja Alger';
const String kPotSampleEn = 'El-Bahdja Wedding Hall Algiers';
const int kPotSampleAmountDzd = 250000;
const String kPotSampleCreatedAtUtc = '2026-10-29T12:00:00Z';

/// Standard 16-byte plaintext SQLite file header (`"SQLite format 3\x00"`).
final Uint8List kStandardSqliteHeaderBytes = Uint8List.fromList(const <int>[
  0x53, 0x51, 0x4c, 0x69, 0x74, 0x65, 0x20, 0x66, // "SQLite f"
  0x6f, 0x72, 0x6d, 0x61, 0x74, 0x20, 0x33, 0x00, // "ormat 3\0"
]);

/// Orchestrates the 4 mandatory SQLite encryption Proof-of-Technology checks
/// across Android (`API 24+`) and Windows (`x64`) (`FR-001`..`FR-010`).
final class SqliteEncryptionPotSuite {
  const SqliteEncryptionPotSuite._();

  /// Executes all 4 PoT checks in an isolated temporary directory and returns
  /// a structured [PotVerificationReport].
  static Future<PotVerificationReport> runAllChecks({
    Directory? parentTempDir,
  }) async {
    final stopwatch = Stopwatch()..start();
    final tempDir = (parentTempDir ?? Directory.systemTemp)
        .createTempSync('walimapp_sqlite_pot_');

    final keyA = EncryptionKeyMaterial.fromHex(kPotTestKeyHexA);
    final keyB = EncryptionKeyMaterial.fromHex(kPotTestKeyHexB);

    var sqliteVersion = 'unknown';
    var activeCipher = 'unknown';
    var lifecycleRoundtripPassed = false;
    var rawFileEncryptedPassed = false;
    var wrongKeyRejectedNotadbPassed = false;
    var failClosedGuardPassed = false;
    String? errorDetail;

    try {
      final dbFile = File(p.join(tempDir.path, 'pot_probe.db'));
      final walFile = File('${dbFile.path}-wal');
      final recordId = const Uuid().v4();

      // -----------------------------------------------------------------------
      // Check 1 (US1 / FR-007): Create -> Write -> Close -> Reopen -> Read
      // -----------------------------------------------------------------------
      final conn1 = EncryptedSqliteOpener.openPotDatabase(
        dbFile: dbFile,
        keyMaterial: keyA,
      );
      sqliteVersion = conn1.sqliteVersion;
      activeCipher = conn1.activeCipher;

      final expectedRecord = PotProbeRecord(
        id: recordId,
        sentinelText: kPotSentinelText,
        localeSampleAr: kPotSampleAr,
        localeSampleFr: kPotSampleFr,
        localeSampleEn: kPotSampleEn,
        amountDzd: kPotSampleAmountDzd,
        createdAtUtc: kPotSampleCreatedAtUtc,
      );

      await conn1.database.insertProbeRecord(expectedRecord);

      // Inspect active WAL file while connection is still open (if WAL exists),
      // then checkpoint/close so pages are flushed to the main .db file.
      var walEncryptedWhileOpen = true;
      if (walFile.existsSync() && walFile.lengthSync() > 0) {
        walEncryptedWhileOpen = verifyFileContainsNoPlaintext(
          walFile,
          requireMinimumLength: false,
        );
      }

      await conn1.close();

      final conn2 = EncryptedSqliteOpener.openPotDatabase(
        dbFile: dbFile,
        keyMaterial: keyA,
      );
      final integrityAfterReopen = await conn2.database.runIntegrityCheck();
      final fetchedRecord = await conn2.database.getProbeRecordById(recordId);
      await conn2.close();

      lifecycleRoundtripPassed =
          activeCipher == kExpectedSqlite3McCipher &&
          integrityAfterReopen.toLowerCase() == 'ok' &&
          fetchedRecord != null &&
          fetchedRecord.id == expectedRecord.id &&
          fetchedRecord.sentinelText == expectedRecord.sentinelText &&
          fetchedRecord.localeSampleAr == expectedRecord.localeSampleAr &&
          fetchedRecord.localeSampleFr == expectedRecord.localeSampleFr &&
          fetchedRecord.localeSampleEn == expectedRecord.localeSampleEn &&
          fetchedRecord.amountDzd == expectedRecord.amountDzd &&
          fetchedRecord.createdAtUtc == expectedRecord.createdAtUtc;

      // -----------------------------------------------------------------------
      // Check 2 (US2 / FR-008 / SC-002): Raw On-Disk Ciphertext Inspection
      // -----------------------------------------------------------------------
      final dbEncryptedOnDisk = verifyFileContainsNoPlaintext(
        dbFile,
        requireMinimumLength: true,
      );
      final walEncryptedAfterClose = !walFile.existsSync() ||
          walFile.lengthSync() == 0 ||
          verifyFileContainsNoPlaintext(walFile, requireMinimumLength: false);

      rawFileEncryptedPassed =
          walEncryptedWhileOpen && dbEncryptedOnDisk && walEncryptedAfterClose;

      // -----------------------------------------------------------------------
      // Check 3 (US3 / FR-009 / SC-003): Wrong-Key & Unkeyed Rejection (26)
      // -----------------------------------------------------------------------
      final wrongKeyRejected = verifyWrongKeyRejectedWithNotADb(
        dbFile: dbFile,
        wrongKey: keyB,
      );
      final unkeyedRejected = verifyUnkeyedRejectedWithNotADb(dbFile: dbFile);

      // Verify that rejected access attempts did not corrupt the encrypted file.
      final conn3 = EncryptedSqliteOpener.openPotDatabase(
        dbFile: dbFile,
        keyMaterial: keyA,
      );
      final integrityAfterRejection = await conn3.database.runIntegrityCheck();
      final recordAfterRejection =
          await conn3.database.getProbeRecordById(recordId);
      await conn3.close();

      wrongKeyRejectedNotadbPassed =
          wrongKeyRejected &&
          unkeyedRejected &&
          integrityAfterRejection.toLowerCase() == 'ok' &&
          recordAfterRejection == expectedRecord;

      // -----------------------------------------------------------------------
      // Check 4 (US1 / FR-003 / FR-004): Unconditional Fail-Closed Guard
      // -----------------------------------------------------------------------
      final mismatchDbFile = File(p.join(tempDir.path, 'pot_mismatch.db'));
      failClosedGuardPassed = verifyFailClosedGuards(
        mismatchDbFile: mismatchDbFile,
        validKey: keyA,
      );
    } on Object catch (e, st) {
      errorDetail = '$e\n$st';
    } finally {
      keyA.dispose();
      keyB.dispose();
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } on Object {
        // Ignore cleanup errors on Windows file locks if any.
      }
      stopwatch.stop();
    }

    return PotVerificationReport(
      platform: detectPlatformName(),
      buildMode: detectBuildModeName(),
      sqliteVersion: sqliteVersion,
      activeCipher: activeCipher,
      lifecycleRoundtripPassed: lifecycleRoundtripPassed,
      rawFileEncryptedPassed: rawFileEncryptedPassed,
      wrongKeyRejectedNotadbPassed: wrongKeyRejectedNotadbPassed,
      failClosedGuardPassed: failClosedGuardPassed,
      durationMs: stopwatch.elapsedMilliseconds,
      errorDetail: errorDetail,
    );
  }

  /// Inspects raw bytes of [file] and returns `true` if and only if:
  /// 1. When [requireMinimumLength] is `true`, `bytes.length >= 100`.
  /// 2. The file does not begin with `"SQLite format 3\x00"`.
  /// 3. None of the forbidden plaintext UTF-8 byte sequences appear anywhere
  ///    in the file (`FR-008`, `SC-002`).
  static bool verifyFileContainsNoPlaintext(
    File file, {
    required bool requireMinimumLength,
  }) {
    if (!file.existsSync()) {
      return false;
    }
    final bytes = file.readAsBytesSync();
    if (requireMinimumLength && bytes.length < 100) {
      return false;
    }
    if (bytes.length >= kStandardSqliteHeaderBytes.length &&
        _startsWithBytes(bytes, kStandardSqliteHeaderBytes)) {
      return false;
    }

    const forbiddenStrings = <String>[
      'SQLite format 3',
      'pot_probe_records',
      kPotSentinelText,
      kPotSampleAr,
      kPotSampleFr,
      kPotSampleEn,
    ];

    for (final probe in forbiddenStrings) {
      final needle = Uint8List.fromList(utf8.encode(probe));
      if (containsSubsequence(bytes, needle)) {
        return false;
      }
    }
    return true;
  }

  /// Verifies that opening [dbFile] with [wrongKey] throws [SqliteException]
  /// with primary result code `26` (`SQLITE_NOTADB`).
  static bool verifyWrongKeyRejectedWithNotADb({
    required File dbFile,
    required EncryptionKeyMaterial wrongKey,
  }) {
    try {
      final (rawDb, _) = EncryptedSqliteOpener.openRawVerifiedDatabase(
        dbFile: dbFile,
        keyMaterial: wrongKey,
      );
      rawDb.close();
      return false;
    } on SqliteException catch (e) {
      return (e.extendedResultCode & 0xFF) == SqlError.SQLITE_NOTADB;
    }
  }

  /// Verifies that opening and reading [dbFile] without a key throws
  /// [SqliteException] with primary result code `26` (`SQLITE_NOTADB`).
  static bool verifyUnkeyedRejectedWithNotADb({required File dbFile}) {
    try {
      EncryptedSqliteOpener.probeUnkeyedReadAndDispose(dbFile);
      return false;
    } on SqliteException catch (e) {
      return (e.extendedResultCode & 0xFF) == SqlError.SQLITE_NOTADB;
    }
  }

  /// Verifies that:
  /// 1. Pre-key cipher mismatch throws an unconditional [StateError] even in
  ///    `profile` and `release` modes (`FR-003`).
  /// 2. Malformed key strings (`""`, `"1234"`, 63-hex, 64-non-hex) throw
  ///    [ArgumentError] before touching SQLite (`FR-004`).
  /// 3. Using a disposed [EncryptionKeyMaterial] throws [StateError].
  static bool verifyFailClosedGuards({
    required File mismatchDbFile,
    required EncryptionKeyMaterial validKey,
  }) {
    var cipherMismatchThrewStateError = false;
    try {
      final (rawDb, _) = EncryptedSqliteOpener.openRawVerifiedDatabase(
        dbFile: mismatchDbFile,
        keyMaterial: validKey,
        expectedCipherOverride: 'aes256cbc',
      );
      rawDb.close();
    } on StateError {
      cipherMismatchThrewStateError = true;
    }

    if (!cipherMismatchThrewStateError) {
      return false;
    }

    const malformedInputs = <String>[
      '',
      '1234',
      '0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f2', // 63 chars
      'zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz', // 64 non-hex
    ];

    for (final badHex in malformedInputs) {
      var threwArgumentError = false;
      try {
        EncryptionKeyMaterial.fromHex(badHex);
      } on ArgumentError {
        threwArgumentError = true;
      }
      if (!threwArgumentError) {
        return false;
      }
    }

    final disposableKey = EncryptionKeyMaterial.fromHex(kPotTestKeyHexA);
    disposableKey.dispose();
    var disposedThrewStateError = false;
    try {
      disposableKey.toSqliteBlobLiteral();
    } on StateError {
      disposedThrewStateError = true;
    }

    return disposedThrewStateError;
  }

  /// Searches [haystack] for the exact contiguous byte sequence [needle].
  static bool containsSubsequence(Uint8List haystack, Uint8List needle) {
    if (needle.isEmpty) {
      return true;
    }
    if (haystack.length < needle.length) {
      return false;
    }
    final limit = haystack.length - needle.length;
    final firstByte = needle[0];
    for (var i = 0; i <= limit; i++) {
      if (haystack[i] != firstByte) {
        continue;
      }
      var match = true;
      for (var j = 1; j < needle.length; j++) {
        if (haystack[i + j] != needle[j]) {
          match = false;
          break;
        }
      }
      if (match) {
        return true;
      }
    }
    return false;
  }

  static bool _startsWithBytes(Uint8List bytes, Uint8List prefix) {
    for (var i = 0; i < prefix.length; i++) {
      if (bytes[i] != prefix[i]) {
        return false;
      }
    }
    return true;
  }

  static String detectPlatformName() {
    if (Platform.isAndroid) {
      return 'android';
    }
    if (Platform.isWindows) {
      return 'windows';
    }
    return Platform.operatingSystem;
  }

  static String detectBuildModeName() {
    if (kReleaseMode) {
      return 'release';
    }
    if (kProfileMode) {
      return 'profile';
    }
    return 'debug';
  }
}
