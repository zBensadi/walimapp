# Feature Specification: SQLite Encryption Proof of Technology — Android and Windows

**Feature Branch**: `001-sqlite-encryption-pot`

**Created**: 2026-10-29

**Status**: Draft — Pending Product Owner Review (Review Gate 1)

**Input**: User description: "SQLite Encryption Proof of Technology — Android and Windows: Prove the chosen encrypted SQLite stack (`drift` + `sqlite3` with `sqlite3mc` native build-hook, explicit `chacha20` cipher selection and `PRAGMA legacy = 0` before applying key, fail-closed runtime cipher verification, Android API 24+ and Windows x64 across debug/profile/release builds, encrypted write/close/reopen/read lifecycle, raw file non-plaintext verification, and wrong-key `SQLITE_NOTADB` rejection) works before building production features."

**Traceability**: [`ADR-003`](../../docs/decision-register.md), [`REQ-LOC-20`](../../docs/product-requirements.md), [`NFR-02`](../../docs/product-requirements.md), [`NFR-04`](../../docs/product-requirements.md), [`docs/architecture.md §2.1, §10.2`](../../docs/architecture.md), [`docs/roadmap.md §2.1 (Sprint 1.1)`](../../docs/roadmap.md), [`.specify/memory/constitution.md (Principles I, II, III, V)`](../../.specify/memory/constitution.md).

---

## Clarifications

### Session 2026-10-29

- Q: Should this slice remain an isolated Proof-of-Technology harness without any domain tables (`venues`, `halls`, `reservations`, `payments`) or OS credential-store integration (`Android Keystore` / `Windows DPAPI`), using deterministic CSPRNG/test 256-bit keys supplied directly to the database opener? → A: Yes — keep this slice strictly isolated to the `sqlite3mc` + Drift encryption harness (`pot_probe_records` test table only) with caller-supplied 256-bit keys; OS key-store adapters and production domain tables belong to subsequent Sprint 1.1 slices after this PoT gate passes.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Fail-Closed Encrypted Database Lifecycle with Correct Key (Priority: P1)

As a **venue owner or developer operating WalimApp on Android (`API 24+`) or Windows (`x64`)**, I need the local database layer to explicitly configure `ChaCha20-Poly1305` (`chacha20`) encryption before applying the 256-bit database key, verify at runtime that `chacha20` encryption is active across `debug`, `profile`, and `release` builds, and persist and retrieve UTF-8/trilingual records across full close-and-reopen cycles—failing closed immediately if encryption is unavailable or misconfigured.

**Why this priority**: Every offline and synchronized workflow in WalimApp depends on local SQLite storage (`ADR-003`, `REQ-LOC-20`, `NFR-04`). Because `SQLite3MultipleCiphers` (`sqlite3mc`) defaults to `chacha20` (`sqleet` ChaCha20-Poly1305 AEAD) rather than AES-256—and because Dart `assert(...)` statements are stripped in `profile` and `release` builds—we must prove that explicit pre-key cipher selection and unconditional runtime cipher verification work on both target OSes and all three build modes before writing any domain schema or feature code.

**Independent Test**: Can be fully tested by running the automated PoT test suite and build-mode verification runner on Windows `x64` and Android `API 24+`, which creates a temporary database file using a valid 256-bit key, verifies active cipher state, inserts a trilingual (`ar-DZ`, `fr-DZ`, `en`) probe record with integer whole-Dinar (`DZD`) sample data, closes the connection, reopens the file with the same key, and asserts exact record equality.

**Acceptance Scenarios**:

1. **Given** a fresh database file path and a valid 32-byte (`64-hex-char`) encryption key on Android (`API 24+`) or Windows (`x64`), **When** the PoT harness opens the database via Drift/`sqlite3`, **Then** it executes `PRAGMA cipher = 'chacha20';` and `PRAGMA legacy = 0;` *before* `PRAGMA key = "x'<64-hex-chars>'";`, queries `SELECT sqlite3mc_config('cipher');` (or `PRAGMA cipher;`), confirms the returned value equals `'chacha20'`, and enables `PRAGMA journal_mode = WAL;` and `PRAGMA foreign_keys = ON;`.
2. **Given** an open encrypted database verified to be running `chacha20`, **When** a probe record containing Arabic (`ar-DZ`), French (`fr-DZ`), and English (`en`) text and an integer `amount_dzd` value is inserted, the database connection is completely closed (including any WAL checkpoint/flush), and a new connection is opened to the same file using the identical 256-bit key, **Then** the reopened database reads back the exact probe record without data loss or encoding corruption.
3. **Given** the PoT verification runner compiled in **`debug`**, **`profile`**, and **`release`** modes, **When** the runtime cipher check executes, **Then** the check runs unconditionally in all three build modes (never relying on `assert(...)`) and fails closed by throwing a fatal `StateError` if the active cipher does not equal `'chacha20'` or if an unsupported/misconfigured cipher name is forced.

---

### User Story 2 - Raw File Ciphertext & Non-Plaintext Verification on Disk (Priority: P1)

As a **venue owner protecting sensitive customer contracts and financial records on a phone or PC**, I need certainty that the `.db` (and any accompanying `-wal` / `-shm`) files written to disk contain no plaintext markers, table names, or customer strings when inspected directly as raw bytes outside the application.

**Why this priority**: Configuring a PRAGMA without inspecting the resulting on-disk bytes could mask a silent plaintext fallback (for example, if a standard unencrypted `sqlite3` binary were accidentally linked instead of `sqlite3mc`, where unknown PRAGMAs are silently ignored by standard SQLite). Inspecting the raw file bytes proves encryption at rest is genuinely active.

**Independent Test**: Can be independently tested by writing a known high-entropy sentinel string (e.g., `"WALIMAPP_PLAINTEXT_SENTINEL_قاعة_الحفلات_2026"`) into the encrypted database, flushing/closing the database, reading the raw bytes of the `.db` file (and `-wal` if present) directly from the filesystem, and asserting that neither the standard unencrypted SQLite file header (`"SQLite format 3\0"`) nor the UTF-8 byte sequence of the sentinel string appears anywhere in the raw file bytes.

**Acceptance Scenarios**:

1. **Given** an encrypted PoT database containing the sentinel string `"WALIMAPP_PLAINTEXT_SENTINEL_قاعة_الحفلات_2026"` that has been flushed and closed, **When** the test harness reads the raw bytes of the `.db` file directly from the filesystem, **Then** the first 16 bytes do **not** match the standard plaintext SQLite header (`53 51 4c 69 74 65 20 66 6f 72 6d 61 74 20 33 00` / `"SQLite format 3\0"`).
2. **Given** the same closed `.db` file (and any `-wal` / `-shm` companion files during an active WAL session before close), **When** the raw file bytes are scanned for the UTF-8 byte sequences of the sentinel string, table name (`pot_probe_records`), or column names, **Then** zero occurrences are found.

---

### User Story 3 - Wrong-Key & Unencrypted Access Rejection (`SQLITE_NOTADB`) (Priority: P1)

As a **security auditor and venue owner**, I need the database engine to deterministically reject any attempt to open an encrypted WalimApp database file with an incorrect key or without a key, raising an explicit `SQLITE_NOTADB` (`error code 26`) exception without corrupting the underlying encrypted file.

**Why this priority**: Verifies that authentication tags (`ChaCha20-Poly1305` AEAD page authentication) and key verification actually guard the database file against unauthorized access or wrong credentials, and that a failed open attempt leaves the encrypted file intact for a subsequent valid open.

**Independent Test**: Can be independently tested by closing a populated encrypted database, attempting to reopen and query it with a different 256-bit key (and with an empty/missing key), asserting that `SqliteException` with `SQLITE_NOTADB` (extended/primary result code `26`) is thrown, and then reopening the same file with the original correct key to confirm all data remains intact.

**Acceptance Scenarios**:

1. **Given** a valid, closed encrypted `.db` file created with Key A, **When** a new connection attempts to open and query (`SELECT count(*) FROM sqlite_master;`) the file using a different 32-byte Key B, **Then** the operation fails immediately with `SQLITE_NOTADB` (`result code 26`: *"file is not a database"* / authentication failure).
2. **Given** the same encrypted `.db` file created with Key A, **When** a connection attempts to open and query the file without applying a key (plaintext mode), **Then** the operation fails immediately with `SQLITE_NOTADB` (`result code 26`).
3. **Given** an encrypted `.db` file that has just rejected a wrong-key open attempt, **When** it is subsequently opened with the original valid Key A, **Then** the database opens cleanly, passes `PRAGMA integrity_check;`, and returns all previously stored probe records intact.

---

### Edge Cases

- **Standard SQLite Library Linked by Mistake (Silent PRAGMA No-Op Hazard)**: Standard unencrypted SQLite silently ignores unknown `PRAGMA cipher` and `PRAGMA key` statements without returning an error. The PoT startup sequence MUST detect this by checking that `SELECT sqlite3mc_config('cipher');` / `PRAGMA cipher;` returns `'chacha20'` and that the raw file header is not `"SQLite format 3\0"`, throwing a fatal `StateError` if standard unencrypted SQLite is loaded.
- **Wrong PRAGMA Ordering (`PRAGMA key` Executed Before `PRAGMA cipher`)**: In `sqlite3mc`, executing `PRAGMA cipher` and `PRAGMA legacy` *after* `PRAGMA key` does not configure the cipher parameters for the key just applied. The opener MUST enforce strict ordering (`PRAGMA cipher = 'chacha20';` -> `PRAGMA legacy = 0;` -> `PRAGMA key = "x'...'";`) and test that reversing or omitting the pre-key configuration is caught.
- **Malformed Encryption Key Input**: Passing an empty key, non-hex string, or a hex key whose length is not exactly 64 hex characters (`32 bytes` / `256 bits`) MUST be rejected by input validation with an `ArgumentError` before touching the filesystem.
- **WAL Uncheckpointed Data on Close**: In `WAL` mode, newly written pages reside in the `-wal` file until checkpointed. The PoT must verify both that `-wal` bytes are encrypted while the DB is open and that closing the Drift database cleanly checkpoints/retains encrypted data on reopen.
- **Release & Profile Build Optimization (`assert` Stripping)**: Dart strips `assert(...)` in `profile` and `release` builds. All cipher verification checks MUST use unconditional runtime `if (activeCipher != 'chacha20') throw StateError(...)` guards.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001 (Target Workspace & Stack)**: The PoT MUST be implemented inside the shared Flutter client workspace (`apps/owner`) targeting **Android (`minSdk 24` / `API 24+`)** and **Windows Desktop (`x64`)**, using `drift` (`^2.35.0`) and `sqlite3` (`^3.8.0`) configured in `pubspec.yaml` with the Dart Native Assets build hook:
  ```yaml
  hooks:
    user_defines:
      sqlite3:
        source: sqlite3mc
  ```
- **FR-002 (Strict Pre-Key Cipher Configuration)**: When opening or creating an encrypted SQLite database file, the database setup callback MUST execute the following statements in exact order before any schema migration or query runs:
  1. `PRAGMA cipher = 'chacha20';`
  2. `PRAGMA legacy = 0;`
  3. `PRAGMA key = "x'<64-hex-char-256-bit-key>'";`
- **FR-003 (Unconditional Fail-Closed Runtime Cipher Verification)**: Immediately after applying `PRAGMA key`, the opener MUST query the active `sqlite3mc` cipher configuration (`SELECT sqlite3mc_config('cipher');` with fallback/cross-check against `PRAGMA cipher;`) and verify via an unconditional runtime check (never `assert`) that the returned cipher equals `'chacha20'`. If the returned value is `null`, empty, or anything other than `'chacha20'`, the opener MUST close the handle and throw a fatal `StateError` before returning the database connection.
- **FR-004 (Key Format Validation)**: The opener MUST validate that the supplied encryption key is a 32-byte (`256-bit` / 64-hex-character) key before executing any SQLite PRAGMA, throwing an `ArgumentError` on empty, short, long, or non-hex key inputs, and zeroing temporary key byte buffers in memory after key application where supported by Dart `Uint8List`.
- **FR-005 (Post-Key Connection Pragmas & Schema Probe)**: After `FR-002` and `FR-003` succeed, the opener MUST execute a schema-touching verification query (`SELECT count(*) FROM sqlite_master;`) to force immediate page decryption/authentication, followed by `PRAGMA foreign_keys = ON;`, `PRAGMA journal_mode = WAL;`, and `PRAGMA synchronous = NORMAL;`.
- **FR-006 (Minimal PoT Probe Schema Only)**: The PoT harness MUST define only a minimal, isolated Drift probe table (`pot_probe_records` with `id TEXT PRIMARY KEY`, `sentinel_text TEXT NOT NULL`, `locale_sample_ar TEXT NOT NULL`, `locale_sample_fr TEXT NOT NULL`, `locale_sample_en TEXT NOT NULL`, `amount_dzd INTEGER NOT NULL`, and `created_at_utc TEXT NOT NULL`) to verify Drift code generation, integer whole-Dinar (`BIGINT`/`INTEGER` `DZD`) storage, and trilingual UTF-8 round-trip persistence.
- **FR-007 (Create, Write, Close, Reopen & Read Lifecycle)**: The PoT MUST verify that a database created on disk with a valid 256-bit key can insert rows into `pot_probe_records`, close the Drift/`sqlite3` connection cleanly, reopen the same file path with the same 256-bit key, pass `PRAGMA integrity_check;`, and read back identical row values.
- **FR-008 (Raw File Non-Plaintext Verification)**: The PoT test suite MUST inspect the raw on-disk `.db` file (and `-wal` file when active) as a byte array and assert that:
  1. The first 16 bytes do **not** equal the ASCII bytes `"SQLite format 3\x00"`.
  2. Known UTF-8 plaintext substrings written to `pot_probe_records` (including ASCII and Arabic UTF-8 sentinel strings and the table name `pot_probe_records`) do **not** appear anywhere in the raw file bytes.
- **FR-009 (Wrong-Key & Unkeyed Rejection with `SQLITE_NOTADB`)**: The PoT test suite MUST verify that opening an existing encrypted `.db` file with a different 256-bit key—or without applying a key—fails deterministically with `SqliteException` carrying result code `26` (`SQLITE_NOTADB`) upon reading the database header/schema, and that the file remains uncorrupted when subsequently reopened with the correct key.
- **FR-010 (Debug, Profile & Release Build Mode Verification — Compilation vs. Runtime Prerequisite)**: The PoT MUST include a reproducible verification entrypoint (automated unit/integration test + lightweight CLI/app smoke runner) that executes the full PoT verification suite (`FR-002` through `FR-009`) and prints a deterministic JSON/console verification report across **`debug`**, **`profile`**, and **`release`** builds on Windows (`x64`) and Android (`API 24+`). Verification MUST explicitly distinguish **APK compilation** (`flutter build apk --debug|--profile|--release`) from **runtime execution**: Android `debug` runtime execution may use either an Android Emulator (`API 24+` AVD) or a physical Android device, whereas **Android `profile` and `release` runtime execution require a physical Android (`API 24+`) device** (never claiming runtime pass without actual execution).
- **FR-011 (Documented Platform Limitations & Reproducible Instructions)**: The slice MUST document exact commands to reproduce the tests on Windows `x64` (`debug`, `profile`, `release` runtime), Android `API 24+` APK compilation (`debug`, `profile`, `release`), Android `debug` runtime (emulator or physical device), and Android `profile`/`release` runtime (physical device required), and explicitly document the platform security boundaries of this PoT (specifically that OS key storage via `Android Keystore` and `Windows DPAPI` is deferred to the next Sprint 1.1 slice, and that `Windows DPAPI` provides OS user-profile-scoped protection rather than a hardware TEE).
- **FR-012 (Strict Scope Isolation — Out of Scope)**: This slice MUST NOT implement any production domain tables (`venues`, `halls`, `hall_slots`, `reservations`, `customers`, `payments`, `expenses`, `local_actors`, `wilayas`, `communes`), UI navigation shells, booking calendars, PDF generation, `.walimbak` backups, `.walimlic` license verification, or Laravel backend code.

### Key Entities *(isolated to PoT harness)*

- **`EncryptionKeyMaterial`**: Value object representing a validated 256-bit (`32-byte` / `64-hex-char`) symmetric key used to key the `sqlite3mc` `chacha20` database, with disposal support to zero in-memory `Uint8List` buffers.
- **`PotProbeRecord`**: Minimal Drift entity (`pot_probe_records`) storing a UUIDv7 `id`, a high-entropy `sentinel_text` marker, trilingual sample strings (`locale_sample_ar`, `locale_sample_fr`, `locale_sample_en`), an integer `amount_dzd` value, and `created_at_utc`.
- **`PotVerificationReport`**: Structured result emitted by the PoT runner recording `platform` (`android` / `windows`), `build_mode` (`debug` / `profile` / `release`), `sqlite_version`, `active_cipher` (`'chacha20'`), `lifecycle_roundtrip_passed`, `raw_file_encrypted_passed`, `wrong_key_rejected_notadb_passed`, `fail_closed_guard_passed`, and informational execution duration in milliseconds (`duration_ms`).

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001 (100% Cipher Verification & Fail-Closed Enforcement Across Build Modes)**: `100%` of database connections opened through the PoT harness in `debug`, `profile`, and `release` builds report `active_cipher == 'chacha20'`, and `100%` of simulated misconfigurations (wrong cipher name or unencrypted SQLite fallback) throw a `StateError` before any user query executes.
- **SC-002 (Zero Plaintext Leakage on Disk)**: Raw byte scans of the on-disk `.db` and `-wal` files across all test runs find `0` occurrences of the `"SQLite format 3\0"` plaintext header and `0` occurrences of the inserted ASCII and Arabic UTF-8 sentinel strings.
- **SC-003 (100% Wrong-Key & Unkeyed Rejection)**: `100%` of attempts to open an encrypted PoT database with a wrong 256-bit key or without a key fail immediately with `SQLITE_NOTADB` (`error code 26`), and `100%` of subsequent reopens with the valid key pass `PRAGMA integrity_check` with zero data loss.
- **SC-004 (Cross-Platform Parity on Windows `x64` & Android `API 24+` + Informational Timing Measurement)**: The identical shared Dart/Drift PoT verification suite passes with zero code changes between Windows `x64` and Android (`API 24+`), and records wall-clock execution duration (`duration_ms`) in `PotVerificationReport` against a `< 2,000 ms` reference target as an **informational measurement** (not a hard acceptance gate that triggers optimization work in this PoT).
- **SC-005 (Zero Static Analysis Warnings)**: `dart analyze` / `flutter analyze` on `apps/owner` completes with `0` errors and `0` warnings.

---

## Documented Platform Limitations & Security Boundaries

1. **Key Custody in This PoT Slice**: This Proof-of-Technology slice validates the **SQLite/Drift native encryption engine (`sqlite3mc` `chacha20`)** using caller-supplied 256-bit keys in temporary test directories. Wrapping and persisting per-venue keys (`key_venue_<venue_id>`) inside `Android Keystore` (`EncryptedSharedPreferences`) and `Windows DPAPI` (`CredWriteW` / Credential Manager) is scoped to the `SecureCredentialStore` platform adapter slice immediately following this PoT gate.
2. **Windows DPAPI vs. Hardware TEE Boundary (`G-P2-2`)**: On Windows `x64`, `sqlite3mc` encrypts the `.db` file at rest against unauthorized disk inspection or file theft, while the database key (once wired to `SecureCredentialStore`) is protected by Windows DPAPI scoped to the logged-in Windows OS user account (not a hardware TEE).
3. **Android Compilation vs. Runtime Execution Boundary**: Compiling the `sqlite3` (`^3.8.0`) `sqlite3mc` C amalgamation via Dart Native Assets requires the Android NDK (`28.2.13676358`) for Android APK builds (`--debug`, `--profile`, `--release`) and Visual Studio C++ Build Tools for Windows `x64` builds. At runtime, Android `debug` mode can execute on an Android Emulator (`API 24+` AVD) or physical device, whereas **Android `profile` and `release` runtime verification require a physical Android (`API 24+`) device** because Flutter does not support `profile` or `release` runtime execution on Android x86_64 emulators.

---

## Assumptions

- The development machine has Flutter stable SDK, Visual Studio C++ build tools for Windows `x64`, and the Android SDK/NDK (`API 24+` target compatibility) available, or any missing local SDK component will be surfaced and verified during `/speckit-plan` / `/speckit-implement`.
- `drift: ^2.35.0` and `sqlite3: ^3.8.0` (with `hooks.user_defines.sqlite3.source: sqlite3mc`) remain the canonical packages per `ADR-003` and `docs/architecture.md §2.1, §10.2`.
- No UI design beyond a minimal diagnostic status screen / headless smoke runner is needed for `debug` / `profile` / `release` build-mode verification in this slice.
