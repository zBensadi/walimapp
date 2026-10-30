# Tasks: SQLite Encryption Proof of Technology (Android & Windows)

**Input**: Design documents from [`./`](./) (`001-sqlite-encryption-pot`)
**Prerequisites**: [`plan.md`](./plan.md) (required), [`spec.md`](./spec.md) (required for user stories), [`research.md`](./research.md), [`data-model.md`](./data-model.md), [`contracts/pot-verification-report.schema.json`](./contracts/pot-verification-report.schema.json), [`quickstart.md`](./quickstart.md)

**Tests**: Automated unit tests (`test/database/sqlite_encryption_pot_test.dart`), cross-platform integration tests (`integration_test/sqlite_encryption_pot_integration_test.dart`), and a build-mode smoke runner (`lib/main_pot.dart`) are **mandatory** for this feature because the entire slice is a cryptographic and build-pipeline Proof of Technology (`FR-001`..`FR-012`, `SC-001`..`SC-005`).

**Organization**: Tasks are grouped by foundational setup and the three P1 user stories (`US1`, `US2`, `US3`) from [`spec.md`](./spec.md), followed by cross-platform compilation and runtime verification tasks.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`)
- Exact repository-relative file paths are included in every task description

## Path Conventions

- **Flutter Client (`apps/owner`)**:
  - `apps/owner/pubspec.yaml`
  - `apps/owner/lib/database/pot/`
  - `apps/owner/lib/main_pot.dart`
  - `apps/owner/test/database/`
  - `apps/owner/integration_test/`

---

## Verification Prerequisites & Environment Gate (`FR-010`, `FR-011`)

Before executing the platform verification tasks in **Phase 6** (`T017`–`T020`), note the strict distinction between **compilation** and **runtime execution**:

1. **Windows `x64` (`debug`, `profile`, `release` compilation + runtime — `T017`):**
   - **Status:** Ready on the current workstation (Flutter `3.44.8`, Visual Studio 2026 C++ workload, Windows 10 SDK `10.0.26100.0`).
2. **Android `API 24+` APK Compilation (`debug`, `profile`, `release` — `T018`):**
   - **Prerequisite (`Blocker E-1`):** Run `flutter doctor --android-licenses` and accept all pending Android SDK licenses so Gradle and NDK `28.2.13676358` can compile `flutter build apk -t lib/main_pot.dart --debug`, `--profile`, and `--release`.
3. **Android `API 24+` `debug` Runtime Execution (`T019`):**
   - **Prerequisite (`Blocker E-1` + `Blocker E-2a` or `E-2b`):** Can run on **either** a provisioned Android (`API 24+`) Emulator AVD (`sdkmanager --install "system-images;android-36.1;google_apis_playstore;x86_64"` + `avdmanager create avd`) **or** a connected physical Android (`API 24+`) device.
4. **Android `API 24+` `profile` & `release` Runtime Execution (`T020`):**
   - **Prerequisite (`Blocker E-1` + `Blocker E-2b` Physical Device Mandatory):** Flutter restricts `--profile` and `--release` runtime execution (`flutter run --profile` / `flutter run --release`) to **physical Android devices** (`API 24+`, USB debugging / Wireless ADB enabled in `adb devices`).
   - **Non-Fabrication Rule (`FR-011`):** **Never** mark `T018`, `T019`, or `T020` as completed (`[X]`) unless the corresponding command has been executed and its runtime output (`POT_REPORT_JSON` with `"all_passed":true`) inspected. APK compilation (`T018`) or emulator `debug` execution (`T019`) does **not** satisfy `T020`.
5. **Performance Target (`SC-004`):**
   - The `< 2,000 ms` total PoT execution duration (`duration_ms` in `PotVerificationReport`) is recorded as an **informational measurement**, not a hard acceptance gate that triggers optimization work in this PoT.

---

## Phase 1: Setup (`apps/owner` Minimal PoT Project Initialization)

**Purpose**: Scaffold the shared Android (`API 24+`) + Windows (`x64`) Flutter application in `apps/owner/` and configure the Dart Native Assets hook for `sqlite3mc`.

- [X] T001 Scaffold minimal Flutter project targeting Android and Windows only via `flutter create --platforms=android,windows --org com.walimapp apps/owner` in `apps/owner/pubspec.yaml`
- [X] T002 Configure `apps/owner/pubspec.yaml` with `drift: ^2.35.0`, `sqlite3: ^3.5.2` (resolved within `drift`'s `^3.4.0` range against Flutter `3.44.8` pinned `meta: 1.18.0`; `sqlite3 >=3.6.0` requires `meta: ^1.19.0`), `path: ^1.9.0`, `path_provider: ^2.1.0`, `uuid: ^4.6.0`, dev dependencies (`drift_dev: ^2.35.0`, `build_runner: ^2.15.0`, `flutter_test`, `integration_test`, `flutter_lints: ^6.0.0`), and the Dart Native Assets build hook `hooks.user_defines.sqlite3.source: sqlite3mc` (`FR-001`)
- [X] T003 [P] Configure Android `minSdk = 24` and `ndkVersion = "28.2.13676358"` in `apps/owner/android/app/build.gradle.kts` (or `apps/owner/android/app/build.gradle`) and strict analyzer rules in `apps/owner/analysis_options.yaml` (`SC-005`)

---

## Phase 2: Foundational (Core PoT Models, Key Validation & Isolated Drift Probe Schema)

**Purpose**: Create the core key material validator, structured verification report model, and isolated Drift probe schema required by all three user stories.

**⚠️ CRITICAL**: Complete this phase before starting User Story 1, 2, or 3.

- [X] T004 [P] Implement `EncryptionKeyMaterial` in `apps/owner/lib/database/pot/encryption_key_material.dart` enforcing exact 64-hex-character (`32-byte` / `256-bit`, `^[0-9a-fA-F]{64}$`) validation (throwing `ArgumentError` on empty, odd-length, non-hex, or `!= 32` decoded bytes before touching SQLite), `x'<64-lowercase-hex>'` SQLite literal formatting, and `.dispose()` zeroing of the internal `Uint8List` buffer (`FR-004`)
- [X] T005 [P] Implement `PotVerificationReport` in `apps/owner/lib/database/pot/pot_verification_report.dart` matching `specs/001-sqlite-encryption-pot/contracts/pot-verification-report.schema.json` (`platform`, `build_mode`, `sqlite_version`, `active_cipher`, `lifecycle_roundtrip_passed`, `raw_file_encrypted_passed`, `wrong_key_rejected_notadb_passed`, `fail_closed_guard_passed`, informational `duration_ms`, `all_passed`, and `POT_REPORT_JSON:<json>` serialization) (`FR-010`, `SC-004`)
- [X] T006 Define the isolated `PotProbeRecords` Drift table (`pot_probe_records`: `id TEXT PRIMARY KEY`, `sentinel_text TEXT NOT NULL`, `locale_sample_ar TEXT NOT NULL`, `locale_sample_fr TEXT NOT NULL`, `locale_sample_en TEXT NOT NULL`, `amount_dzd INTEGER NOT NULL`, `created_at_utc TEXT NOT NULL` — zero production domain tables) in `apps/owner/lib/database/pot/pot_database.dart` and generate `apps/owner/lib/database/pot/pot_database.g.dart` via `dart run build_runner build` (`FR-006`, `FR-012`)

**Checkpoint**: Key validation, report serialization, and generated Drift table code compile cleanly.

---

## Phase 3: User Story 1 — Fail-Closed Encrypted Database Lifecycle with Correct Key (Priority: P1) 🎯 MVP

**Goal**: Open a new or existing local SQLite database file configured with `sqlite3mc` (`chacha20` / `ChaCha20-Poly1305`, `legacy = 0`), unconditionally verify active cipher configuration at runtime across all build modes (failing closed with `StateError` on mismatch and `ArgumentError` on malformed keys), write trilingual (`ar-DZ`, `fr-DZ`, `en`) + whole-integer `amount_dzd` probe data, close, reopen with the same key, and read identical data back (`FR-002`..`FR-007`, `SC-001`).

**Independent Test**: Run `flutter test test/database/sqlite_encryption_pot_test.dart --plain-name "US1"` in `apps/owner/` to verify pre-key PRAGMA ordering, unconditional runtime cipher check (`StateError` on simulated mismatch), `ArgumentError` on malformed keys, and full create -> write -> close -> reopen -> `PRAGMA integrity_check` -> read round-trip.

### Tests for User Story 1

- [X] T007 [US1] Write unit tests for User Story 1 in `apps/owner/test/database/sqlite_encryption_pot_test.dart` covering explicit `PRAGMA cipher = 'chacha20'; PRAGMA legacy = 0;` configuration, pre-key runtime `SELECT sqlite3mc_config('cipher');` == `'chacha20'` and `SELECT sqlite3mc_config('chacha20', 'legacy');` == `0` verification **before** applying `PRAGMA key`, unconditional `StateError` on simulated pre-key cipher mismatch (`expectedCipherOverride: 'aes256cbc'`), `ArgumentError` on malformed keys (`""`, `"1234"`, 63-char hex, 64-char non-hex), and full create -> write trilingual `ar-DZ`/`fr-DZ`/`en` + integer `amount_dzd` (`250000`) probe row -> close -> reopen with same key -> `PRAGMA integrity_check` -> read equality (`FR-002`..`FR-007`, `SC-001`)

### Implementation for User Story 1

- [X] T008 [US1] Implement `EncryptedSqliteOpener` in `apps/owner/lib/database/pot/encrypted_sqlite_opener.dart` executing (1) `PRAGMA cipher = 'chacha20';` and `PRAGMA legacy = 0;`, (2) pre-key unconditional runtime verification (`SELECT sqlite3mc_config('cipher');` == `'chacha20'` and `SELECT sqlite3mc_config('chacha20', 'legacy');` == `0`, throwing `StateError` and disposing `rawDb` on mismatch or missing extension — never `assert`), (3) `PRAGMA key = "x'<64-hex>'";` only after pre-key verification, (4) schema-touching `SELECT count(*) FROM sqlite_master;`, and (5) post-key `PRAGMA foreign_keys = ON; PRAGMA journal_mode = WAL; PRAGMA synchronous = NORMAL;` (`FR-002`..`FR-005`)
- [X] T009 [US1] Implement Check 1 (correct-key create/write/close/reopen/read lifecycle with trilingual `ar-DZ`/`fr-DZ`/`en` strings and integer `amount_dzd`) and Check 4 (unconditional fail-closed `StateError` & `ArgumentError` guard verification) inside `SqliteEncryptionPotSuite` in `apps/owner/lib/database/pot/sqlite_encryption_pot_suite.dart` (`FR-003`, `FR-004`, `FR-007`)

**Checkpoint**: User Story 1 unit tests pass (`flutter test test/database/sqlite_encryption_pot_test.dart --plain-name "US1"`).

---

## Phase 4: User Story 2 — Raw File Ciphertext & Non-Plaintext Verification on Disk (Priority: P1)

**Goal**: Prove by direct raw-byte inspection of the on-disk `.db` file (and `-wal` file when present) that neither the standard unencrypted SQLite header (`"SQLite format 3\x00"`) nor any UTF-8 bytes of inserted sentinel strings (`"WALIMAPP_PLAINTEXT_SENTINEL_قاعة_الحفلات_2026"`, `"pot_probe_records"`, or trilingual sample strings) appear anywhere in plaintext (`FR-008`, `SC-002`).

**Independent Test**: Run `flutter test test/database/sqlite_encryption_pot_test.dart --plain-name "US2"` in `apps/owner/` to verify that raw byte inspection passes on an encrypted `.db` and fails if pointed at an unencrypted control `.db`.

### Tests for User Story 2

- [X] T010 [US2] Add raw on-disk byte inspection unit tests for User Story 2 in `apps/owner/test/database/sqlite_encryption_pot_test.dart` asserting that flushed/closed `.db` (and active `-wal`) files do not start with `"SQLite format 3\x00"` (`53 51 4c 69 74 65 20 66 6f 72 6d 61 74 20 33 00`) and contain `0` occurrences of UTF-8 bytes for `"WALIMAPP_PLAINTEXT_SENTINEL_قاعة_الحفلات_2026"`, `"pot_probe_records"`, or the inserted Arabic/French/English strings (`FR-008`, `SC-002`)

### Implementation for User Story 2

- [X] T011 [US2] Implement Check 2 (raw `.db` and `-wal` file header and UTF-8 sentinel substring scanner) in `apps/owner/lib/database/pot/sqlite_encryption_pot_suite.dart` (`FR-008`, `SC-002`)

**Checkpoint**: User Stories 1 and 2 unit tests pass (`flutter test test/database/sqlite_encryption_pot_test.dart --plain-name "US"`).

---

## Phase 5: User Story 3 — Wrong-Key & Unencrypted Access Rejection (`SQLITE_NOTADB`) (Priority: P1)

**Goal**: Prove that attempting to open an existing encrypted `.db` file with a different 256-bit key (`Key_B != Key_A`) or without providing a key fails immediately with `SqliteException` carrying SQLite extended result code `26` (`SQLITE_NOTADB`), without corrupting the file for subsequent reopen with the valid key `Key_A` (`FR-009`, `SC-003`).

**Independent Test**: Run `flutter test test/database/sqlite_encryption_pot_test.dart --plain-name "US3"` in `apps/owner/` to verify wrong-key and unkeyed `SQLITE_NOTADB` (`26`) rejection and clean recovery on valid-key reopen.

### Tests for User Story 3

- [X] T012 [US3] Add wrong-key and unkeyed access rejection unit tests for User Story 3 in `apps/owner/test/database/sqlite_encryption_pot_test.dart` asserting that opening an existing encrypted `.db` with a different 64-hex key or without a key throws `SqliteException` with result code `26` (`SQLITE_NOTADB`), and that reopening afterward with the original valid key passes `PRAGMA integrity_check` and returns intact data (`FR-009`, `SC-003`)

### Implementation for User Story 3

- [X] T013 [US3] Implement Check 3 (wrong-key and unkeyed `SQLITE_NOTADB` result code `26` verification + post-rejection valid-key reopen and `PRAGMA integrity_check`) in `apps/owner/lib/database/pot/sqlite_encryption_pot_suite.dart` (`FR-009`, `SC-003`)

**Checkpoint**: All unit tests (`US1`, `US2`, `US3`) in `apps/owner/test/database/sqlite_encryption_pot_test.dart` pass.

---

## Phase 6: Cross-Platform & Multi-Build-Mode Runners, Verification & Polish

**Purpose**: Wire the cross-platform smoke runner (`lib/main_pot.dart`) and integration test (`integration_test/sqlite_encryption_pot_integration_test.dart`), run static analysis, and execute the compilation and runtime checks across Windows `x64` and Android `API 24+`.

- [X] T014 [P] Implement the build-mode smoke runner entrypoint in `apps/owner/lib/main_pot.dart` (and update `apps/owner/lib/main.dart` to delegate to the PoT diagnostic view) that executes `SqliteEncryptionPotSuite.runAllChecks()`, records informational `duration_ms` (`SC-004`), prints `POT_REPORT_JSON:<json>`, renders a minimal diagnostic status card, and exits with code `0`/`1` when `--dart-define=POT_AUTO_EXIT=true` is set (`FR-010`)
- [X] T015 [P] Implement the cross-platform integration test in `apps/owner/integration_test/sqlite_encryption_pot_integration_test.dart` invoking `SqliteEncryptionPotSuite.runAllChecks()` and asserting `report.allPassed == true` (`FR-010`, `SC-004`)
- [X] T016 Run `flutter analyze` and `flutter test test/database/sqlite_encryption_pot_test.dart` in `apps/owner/`, verifying `0` analyzer errors/warnings (`SC-005`) and 100% unit test pass rate
- [X] T017 Execute Windows `x64` compilation and runtime verification across all 3 build modes (`--debug`, `--profile`, `--release`) in `apps/owner/` via `flutter run -d windows -t lib/main_pot.dart --debug|--profile|--release --dart-define=POT_AUTO_EXIT=true` (and `flutter test integration_test/sqlite_encryption_pot_integration_test.dart -d windows`), verifying `POT_REPORT_JSON` output with `"platform":"windows"` and `"all_passed":true` in all 3 modes (`FR-010`, `SC-001`..`SC-004`)
- [X] T018 Execute Android `API 24+` APK compilation verification across all 3 build modes (`flutter build apk -t lib/main_pot.dart --debug`, `--profile`, `--release`) in `apps/owner/`, producing `app-debug.apk` (`157.7 MB`), `app-profile.apk` (`66.0 MB`), and `app-release.apk` (`49.0 MB`) (`FR-001`, `FR-010`, `FR-011`)
- [X] T019 Execute Android `API 24+` `debug` runtime verification on physical device `641e3fb1` (`Redmi Note 9 Pro Max`, Android 12, API 31) via `app-debug.apk` (`lib/main_pot.dart`), verifying UI summary (`284 ms`) and `logcat` `POT_REPORT_JSON` output (`"platform":"android"`, `"build_mode":"debug"`, `"sqlite_version":"3.53.4"`, `"active_cipher":"chacha20"`, `"all_passed":true`, `duration_ms: 525`) (`FR-010`, `FR-011`, `SC-004`)
- [X] T020 Execute Android `API 24+` `profile` and `release` runtime verification on physical device `641e3fb1` (`Redmi Note 9 Pro Max`, Android 12, API 31) by installing and launching `app-profile.apk` (`duration_ms: 347`, `"all_passed":true`) and `app-release.apk` (`duration_ms: 222`, `"all_passed":true`) and capturing `POT_REPORT_JSON` from `adb logcat` (`FR-010`, `FR-011`, `SC-001`, `SC-004`)

---

## Dependencies & Execution Order

### Phase Dependencies

1. **Phase 1: Setup (`T001`–`T003`)**: Starts immediately upon Review Gate 3 approval. `T001` -> `T002` -> `T003`.
2. **Phase 2: Foundational (`T004`–`T006`)**: Depends on Phase 1 (`T002`). `T004` and `T005` can run in parallel (`[P]`); `T006` runs `build_runner` to generate `pot_database.g.dart`.
3. **Phase 3: User Story 1 (`T007`–`T009`)**: Depends on Phase 2 (`T004`–`T006`). Establishes `EncryptedSqliteOpener` and `SqliteEncryptionPotSuite` (Check 1 + Check 4).
4. **Phase 4: User Story 2 (`T010`–`T011`)**: Depends on Phase 3 (`T008`–`T009`) because it inspects the `.db` / `-wal` files created by `EncryptedSqliteOpener` and adds Check 2 to `SqliteEncryptionPotSuite`.
5. **Phase 5: User Story 3 (`T012`–`T013`)**: Depends on Phase 3 (`T008`–`T009`) and extends `SqliteEncryptionPotSuite` with Check 3 (`SQLITE_NOTADB` `26` verification).
6. **Phase 6: Cross-Platform Runners & Verification (`T014`–`T020`)**:
   - `T014` and `T015` depend on `T009`, `T011`, and `T013` and can be written in parallel (`[P]`).
   - `T016` (`flutter analyze` + unit tests) and `T017` (Windows `x64` `debug` / `profile` / `release` runtime verification) execute immediately on the current workstation.
   - `T018` (Android APK compilation for `debug` / `profile` / `release`) requires `Blocker E-1` (`flutter doctor --android-licenses`).
   - `T019` (Android `debug` runtime verification) requires `Blocker E-1` + either `Blocker E-2a` (Android Emulator AVD) or `Blocker E-2b` (physical Android device).
   - `T020` (Android `profile` & `release` runtime verification) requires `Blocker E-1` + `Blocker E-2b` (connected physical Android `API 24+` device).

### Parallel Opportunities

- **Phase 2**: `T004` (`encryption_key_material.dart`) and `T005` (`pot_verification_report.dart`) touch distinct files with zero mutual dependencies.
- **Phase 6**: `T014` (`lib/main_pot.dart`) and `T015` (`integration_test/sqlite_encryption_pot_integration_test.dart`) touch distinct files and can be implemented in parallel once `SqliteEncryptionPotSuite` (`T009`, `T011`, `T013`) is complete.
