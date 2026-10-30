# Phase 1 Data Model: SQLite Encryption Proof of Technology (`001-sqlite-encryption-pot`)

- **Feature**: [`specs/001-sqlite-encryption-pot/spec.md`](./spec.md)
- **Date**: 2026-10-29
- **Scope**: Strictly isolated to the PoT encryption harness. Zero production domain tables (`venues`, `halls`, `reservations`, `payments`, etc.) are included in this slice (`FR-006`, `FR-012`).

---

## 1. Value Objects & Diagnostic Models (Dart)

### 1.1 `EncryptionKeyMaterial`
- **Purpose**: Encapsulates and validates the caller-supplied 256-bit (`32-byte` / `64-hex-char`) encryption key before any SQLite PRAGMA is executed (`FR-004`).
- **Fields & Invariants**:
  - `Uint8List _bytes`: Private 32-byte buffer decoded from 64 hexadecimal characters (`^[0-9a-fA-F]{64}$`).
  - `bool _isDisposed`: Tracks whether `_bytes.fillRange(0, _bytes.length, 0)` has been called.
- **Validation Rules**:
  - Rejects empty strings, odd lengths, non-hexadecimal characters, or any decoded byte length `!= 32` by throwing `ArgumentError` prior to opening SQLite.
  - Formats the SQLite literal `x'<64-lowercase-hex>'` for `PRAGMA key` and supports `.dispose()` to zero the byte buffer immediately after key application.

### 1.2 `PotVerificationReport`
- **Purpose**: Immutable diagnostic report capturing the execution of all PoT checks for a given `(platform, build_mode)` pair (`FR-010`, `SC-001`..`SC-004`).
- **Fields**:
  - `platform` (`String`): `'windows'` or `'android'` (or `Platform.operatingSystem`).
  - `buildMode` (`String`): `'debug'`, `'profile'`, or `'release'` (derived from `kReleaseMode` / `kProfileMode` / `kDebugMode`).
  - `sqliteVersion` (`String`): Output of `SELECT sqlite_version();`.
  - `activeCipher` (`String`): Verified output of `SELECT sqlite3mc_config('cipher');` / `PRAGMA cipher;` (expected `'chacha20'`).
  - `lifecycleRoundtripPassed` (`bool`): `true` when create -> insert trilingual + integer `amount_dzd` row -> close -> reopen with same key -> `PRAGMA integrity_check` -> read equality succeeds (`FR-007`).
  - `rawFileEncryptedPassed` (`bool`): `true` when raw `.db` (and `-wal` while active) byte inspection confirms the first 16 bytes `!= "SQLite format 3\x00"` and `0` occurrences of the UTF-8 sentinel string or `pot_probe_records` table name (`FR-008`).
  - `wrongKeyRejectedNotadbPassed` (`bool`): `true` when both wrong-key and unkeyed open attempts throw `SqliteException` with result code `26` (`SQLITE_NOTADB`) and subsequent reopen with the original valid key passes `PRAGMA integrity_check` (`FR-009`).
  - `failClosedGuardPassed` (`bool`): `true` when simulated cipher mismatch / invalid expected cipher throws `StateError` unconditionally across `debug`, `profile`, and `release` builds (`FR-003`).
  - `durationMs` (`int`): Measured wall-clock duration in milliseconds (recorded against the `< 2000 ms` `SC-004` benchmark).
  - `allPassed` (`bool`): Computed getter (`activeCipher == 'chacha20' && lifecycleRoundtripPassed && rawFileEncryptedPassed && wrongKeyRejectedNotadbPassed && failClosedGuardPassed`).

---

## 2. Drift / SQLite Probe Table (`pot_probe_records`)

| Column | Drift / SQLite Type | Nullable | Constraints & Purpose |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` (`TextColumn`) | `NOT NULL` | `PRIMARY KEY` — Client-generated UUIDv7 string (`ADR-004`). |
| `sentinel_text` | `TEXT` (`TextColumn`) | `NOT NULL` | High-entropy probe marker (`"WALIMAPP_PLAINTEXT_SENTINEL_قاعة_الحفلات_2026"`) scanned for absence in raw `.db`/`-wal` file bytes (`FR-008`). |
| `locale_sample_ar` | `TEXT` (`TextColumn`) | `NOT NULL` | Arabic (`ar-DZ` RTL) UTF-8 probe string (`"قاعة الأفراح الياسمين — الجزائر"`). |
| `locale_sample_fr` | `TEXT` (`TextColumn`) | `NOT NULL` | French (`fr-DZ` LTR) UTF-8 probe string (`"Salle des Fêtes El Yasmine — Alger"`). |
| `locale_sample_en` | `TEXT` (`TextColumn`) | `NOT NULL` | English (`en` LTR) UTF-8 probe string (`"El Yasmine Wedding Hall — Algiers"`). |
| `amount_dzd` | `INTEGER` (`IntColumn`) | `NOT NULL` | Integer whole Algerian Dinars (`DZD`, e.g., `350000`) (`ADR-009`). |
| `created_at_utc` | `TEXT` (`TextColumn`) | `NOT NULL` | ISO-8601 UTC timestamp string (`'YYYY-MM-DDTHH:mm:ssZ'`). |
