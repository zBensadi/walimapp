# Implementation Plan: SQLite Encryption Proof of Technology — Android and Windows

**Branch**: `001-sqlite-encryption-pot` | **Date**: 2026-10-29 | **Spec**: [`specs/001-sqlite-encryption-pot/spec.md`](./spec.md)

**Input**: Feature specification from [`specs/001-sqlite-encryption-pot/spec.md`](./spec.md)

---

## Summary

Prove that the canonical WalimApp encrypted SQLite stack (`drift: ^2.35.0` + `sqlite3: ^3.8.0` configured with the `hooks.user_defines.sqlite3.source: sqlite3mc` Dart Native Assets build hook) works across **all six platform/build-mode combinations** (**Windows `x64`** and **Android `API 24+`** in **`debug`**, **`profile`**, and **`release`** modes) before building any production domain tables or features.

The Proof-of-Technology (PoT) harness enforces strict pre-key cipher selection (`PRAGMA cipher = 'chacha20'; PRAGMA legacy = 0;` before `PRAGMA key`), verifies at runtime without relying on `assert` that `SELECT sqlite3mc_config('cipher');` / `PRAGMA cipher;` equals `'chacha20'` (failing closed with a fatal `StateError` otherwise), validates full encrypted create-write-close-reopen-read persistence of trilingual (`ar-DZ`, `fr-DZ`, `en`) and integer whole-Dinar (`DZD`) probe data, inspects raw `.db` and `-wal` file bytes on disk to confirm zero plaintext leakage, and verifies deterministic `SQLITE_NOTADB` (`result code 26`) rejection on wrong-key or unkeyed access attempts.

---

## Technical Context

**Language/Version**: Flutter `3.44.8` (`channel stable`), Dart `3.12.2` (`enable-native-assets` enabled)

**Primary Dependencies**:
- `drift: ^2.35.0` (`2.35.3` latest verified on `pub.dev`)
- `sqlite3: ^3.8.0` (`3.8.0` latest verified on `pub.dev`, configured with `hooks.user_defines.sqlite3.source: sqlite3mc`)
- `path: ^1.9.0`, `path_provider: ^2.1.0`, `uuid: ^4.6.0`
- Dev: `drift_dev: ^2.35.0`, `build_runner: ^2.17.0`, `flutter_test`, `integration_test`, `flutter_lints: ^6.0.0`

**Storage**: Local encrypted SQLite via `SQLite3MultipleCiphers` (`sqlite3mc`) using explicit `chacha20` (`sqleet` ChaCha20-Poly1305 256-bit AEAD, `PRAGMA legacy = 0`) and `WAL` journal mode.

**Testing**: `flutter test` (unit/VM test runner), `integration_test` (Windows `x64` and Android `API 24+`), and a dedicated build-mode smoke runner (`lib/main_pot.dart`) executable across `--debug`, `--profile`, and `--release`.

**Target Platform**: Android (`minSdk = 24` / `API 24+`) and Windows Desktop (`x64`).

**Project Type**: Shared mobile + desktop Flutter application (`apps/owner`) — isolated Proof-of-Technology slice.

**Performance Goals**: Record full PoT suite execution duration (`duration_ms`) in `PotVerificationReport` against the `< 2,000 ms` (`SC-004`) benchmark as a passive measurement; do not add premature optimization work solely to meet it.

**Constraints**: Offline-capable (100% local execution), fail-closed (`StateError` if active cipher `!= 'chacha20'`), zero plaintext fallback, zero production domain tables in this slice.

**Scale/Scope**: Single isolated Drift probe table (`pot_probe_records`) and 4 deterministic verification checks executed across 6 platform/build-mode combinations.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle / Constraint ([`.specify/memory/constitution.md`](../../.specify/memory/constitution.md)) | Pre-Design Status | Post-Design Status | Verification Evidence |
| :--- | :--- | :--- | :--- |
| **I. Data Safety & Financial Ledger Immutability** | **PASS** | **PASS** | Uses integer `amount_dzd` (`INTEGER`) in `pot_probe_records`; enforces `chacha20` AEAD encryption at rest. |
| **II. Genuine Local Independence** | **PASS** | **PASS** | Executes 100% offline with zero network calls. |
| **III. Shared Android & Windows Offline-First Client** | **PASS** | **PASS** | Single shared `apps/owner` Flutter project targeting Android (`API 24+`) and Windows (`x64`). |
| **IV. Server-Enforced Authorization & Tenant Isolation** | **N/A (Scoped Out)** | **N/A (Scoped Out)** | Local SQLite PoT only; no backend/sync in Sprint 1.1. |
| **V. Testable Requirements & Automated Verification** | **PASS** | **PASS** | Explicit pre-key `PRAGMA cipher = 'chacha20'; PRAGMA legacy = 0;`, unconditional `StateError` check across `debug`/`profile`/`release`, raw byte inspection, and `SQLITE_NOTADB` (`26`) tests. |
| **VI. Human Review Gates & Incremental Phased Delivery** | **PASS** | **PASS** | `DEC-01` & `DEC-02` confirmed; Review Gate 1 approved; stopping at Review Gate 2 before any code is written. |
| **VII. Solo-Developer Operational Simplicity** | **PASS** | **PASS** | Uses standard `sqlite3: ^3.8.0` native build hooks without custom C++/CMake forks. |
| **Stack Baseline (`ADR-003`)** | **PASS** | **PASS** | `drift: ^2.35.0` + `sqlite3: ^3.8.0` (`hooks.user_defines.sqlite3.source: sqlite3mc`), Android `API 24+`, Windows `x64`. |

---

## Project Structure

### Documentation (this feature)

```text
specs/001-sqlite-encryption-pot/
├── spec.md                                      # Approved Feature Specification (Review Gate 1)
├── plan.md                                      # This file (/speckit-plan output)
├── research.md                                  # Phase 0 research & local toolchain audit
├── data-model.md                                # Phase 1 PoT entities & Drift probe table
├── quickstart.md                                # Phase 1 commands for all 6 platform/build-mode runs
├── contracts/
│   └── pot-verification-report.schema.json      # Deterministic JSON report schema for PoT runs
└── checklists/
    └── requirements.md                          # Spec quality checklist (16/16 passing)
```

### Source Code (proposed minimum files in repository root for `/speckit-implement`)

```text
apps/owner/
├── pubspec.yaml                                         # Flutter app manifest + drift/sqlite3 + hooks.user_defines.sqlite3.source: sqlite3mc
├── analysis_options.yaml                                # Strict flutter_lints configuration
├── android/                                             # Standard Flutter Android runner configured with minSdk = 24
│   └── app/build.gradle.kts                             # Ensures minSdk = 24 and NDK 28.2.13676358 compatibility
├── windows/                                             # Standard Flutter Windows x64 C++ runner
├── lib/
│   ├── main.dart                                        # Default app entrypoint delegating to PoT diagnostic view in Sprint 1.1 PoT
│   ├── main_pot.dart                                    # Dedicated PoT smoke runner for --debug, --profile, and --release builds
│   └── database/
│       └── pot/
│           ├── encryption_key_material.dart             # 64-hex-char (256-bit) key validator, x'...' formatter & buffer zeroing
│           ├── encrypted_sqlite_opener.dart             # Pre-key PRAGMA cipher='chacha20'; PRAGMA legacy=0; PRAGMA key; + fail-closed StateError guard
│           ├── pot_database.dart                        # Isolated Drift database with PotProbeRecords table
│           ├── pot_database.g.dart                      # Generated by drift_dev / build_runner
│           ├── pot_verification_report.dart             # Structured JSON/console report model + duration_ms measurement
│           └── sqlite_encryption_pot_suite.dart         # Executes the 4 mandatory PoT checks (lifecycle, raw bytes, SQLITE_NOTADB, fail-closed guard)
├── test/
│   └── database/
│       └── sqlite_encryption_pot_test.dart              # Automated unit/VM test suite covering FR-001..FR-009 & edge cases
└── integration_test/
    └── sqlite_encryption_pot_integration_test.dart      # Cross-platform integration test for Windows x64 & Android API 24+
```

**Structure Decision**: Create the canonical `apps/owner` Flutter workspace (Android + Windows platforms only) containing strictly the isolated `lib/database/pot/` Proof-of-Technology modules, `lib/main_pot.dart` build-mode runner, and the two test suites (`test/` and `integration_test/`). Zero production domain tables or UI features are created in this slice.

---

## Test Strategy for the Six Platform / Build-Mode Combinations

All six combinations execute the same `SqliteEncryptionPotSuite.runAllChecks(...)` in `lib/database/pot/sqlite_encryption_pot_suite.dart` and emit `POT_REPORT_JSON:<json>` validated against [`contracts/pot-verification-report.schema.json`](./contracts/pot-verification-report.schema.json):

1. **Check 1 — Correct-Key Lifecycle & Cipher Verification (`FR-002`, `FR-003`, `FR-005`, `FR-007`)**:
   - Open fresh `.db` file with valid 64-hex Key A -> apply `PRAGMA cipher = 'chacha20'; PRAGMA legacy = 0; PRAGMA key = "x'...'";` -> verify `SELECT sqlite3mc_config('cipher');` == `'chacha20'` -> insert `PotProbeRecord` (Arabic, French, English text + integer `amount_dzd = 350000` + sentinel string) -> close DB -> reopen with Key A -> run `PRAGMA integrity_check;` -> assert read record matches inserted record.
2. **Check 2 — Raw On-Disk Byte Inspection (`FR-008`, `SC-002`)**:
   - Inspect raw bytes of `.db` (and `-wal` before close) -> assert first 16 bytes `!= "SQLite format 3\x00"` -> assert `0` occurrences of UTF-8 bytes for `"WALIMAPP_PLAINTEXT_SENTINEL_قاعة_الحفلات_2026"`, `"pot_probe_records"`, or `"Salle des Fêtes"`.
3. **Check 3 — Wrong-Key & Unkeyed Rejection (`FR-009`, `SC-003`)**:
   - Attempt to open & query (`SELECT count(*) FROM sqlite_master;`) the encrypted `.db` with distinct 64-hex Key B -> assert `SqliteException` with result code `26` (`SQLITE_NOTADB`) is thrown.
   - Attempt to open & query without applying a key -> assert `SqliteException` with result code `26` (`SQLITE_NOTADB`) is thrown.
   - Reopen with original Key A -> assert `PRAGMA integrity_check` returns `'ok'` and the probe row is intact.
4. **Check 4 — Unconditional Fail-Closed Runtime Guard (`FR-003`, `FR-004`, `SC-001`)**:
   - Verify malformed keys (empty, 62 hex chars, non-hex) throw `ArgumentError` before touching SQLite.
   - Verify simulated cipher mismatch / unexpected cipher throws `StateError` unconditionally in `debug`, `profile`, and `release` builds (proving no reliance on `assert`).

| Combination | Compilation Command (from `apps/owner`) | Runtime Execution Command & Target Prerequisite | Verification Signal |
| :--- | :--- | :--- | :--- |
| **1. Windows `x64` — `debug`** | `flutter build windows -t lib/main_pot.dart --debug` | `flutter test test/database/sqlite_encryption_pot_test.dart` & `flutter run -d windows -t lib/main_pot.dart --debug --dart-define=POT_AUTO_EXIT=true` (Local Windows `x64` host) | `POT_REPORT_JSON` with `"platform":"windows","build_mode":"debug","all_passed":true` |
| **2. Windows `x64` — `profile`** | `flutter build windows -t lib/main_pot.dart --profile` | `flutter run -d windows -t lib/main_pot.dart --profile --dart-define=POT_AUTO_EXIT=true` (Local Windows `x64` host) | `POT_REPORT_JSON` with `"platform":"windows","build_mode":"profile","all_passed":true` |
| **3. Windows `x64` — `release`** | `flutter build windows -t lib/main_pot.dart --release` | `flutter run -d windows -t lib/main_pot.dart --release --dart-define=POT_AUTO_EXIT=true` (Local Windows `x64` host) | `POT_REPORT_JSON` with `"platform":"windows","build_mode":"release","all_passed":true` |
| **4. Android `API 24+` — `debug`** | `flutter build apk -t lib/main_pot.dart --debug` *(requires `E-1`)* | `flutter run -d <android-emulator-or-device-id> -t lib/main_pot.dart --debug` *(Android `API 24+` Emulator OR physical device; requires `E-1` + `E-2a`/`E-2b`)* | `POT_REPORT_JSON` in `adb logcat` with `"platform":"android","build_mode":"debug","all_passed":true` |
| **5. Android `API 24+` — `profile`** | `flutter build apk -t lib/main_pot.dart --profile` *(requires `E-1`)* | `flutter run -d <physical-android-device-id> -t lib/main_pot.dart --profile` *(**Physical Android `API 24+` device required**; emulators do not support `--profile` runtime; requires `E-1` + `E-2b`)* | `POT_REPORT_JSON` in `adb logcat` with `"platform":"android","build_mode":"profile","all_passed":true` |
| **6. Android `API 24+` — `release`** | `flutter build apk -t lib/main_pot.dart --release` *(requires `E-1`)* | `flutter run -d <physical-android-device-id> -t lib/main_pot.dart --release` *(**Physical Android `API 24+` device required**; emulators do not support `--release` runtime; requires `E-1` + `E-2b`)* | `POT_REPORT_JSON` in `adb logcat` with `"platform":"android","build_mode":"release","all_passed":true` |

---

## Genuine Environment Blockers Surfaced (`flutter doctor -v` Audit on 2026-10-29)

1. **Windows `x64` Environment — ZERO Blockers**:
   - Flutter `3.44.8` (`stable`), Dart `3.12.2`, Visual Studio Community 2026 (`18.8.2`), and Windows 10 SDK (`10.0.26100.0`) are installed and ready. All 3 Windows `x64` build modes (`debug`, `profile`, `release`) can be compiled and executed immediately.
2. **Android `API 24+` Environment — Compilation vs. Runtime Execution Prerequisites**:
   - **Blocker `E-1` (Unaccepted Android SDK Licenses — Blocks Android Compilation)**: `flutter doctor -v` reports `! Some Android licenses not accepted.` Running `flutter doctor --android-licenses` is required before Gradle can compile the Android `debug`, `profile`, and `release` APKs. (Android SDK `36.0.0`, Build-Tools `36.0.0`, OpenJDK `21.0.10`, and Android NDK `28.2.13676358` are already installed.)
   - **Blocker `E-2a` (No Installed AVD System Image — Blocks Emulator-Based Android `debug` Runtime Execution)**: `emulator -list-avds` currently shows `0` configured AVDs (`system-images/` is not yet downloaded). An Android Emulator (`API 24+` AVD) or physical device is required to execute the Android `debug` runtime check.
   - **Blocker `E-2b` (No Connected Physical Android Device — Blocks Android `profile` and `release` Runtime Execution)**: `adb devices -l` currently shows `0` connected physical Android devices. Because Flutter restricts `--profile` and `--release` runtime execution to physical Android devices (emulators only support `debug` mode), **executing the Android `profile` and `release` runtime checks requires connecting a physical Android (`API 24+`) device**. Compilation of `--profile` and `--release` APKs can be verified once `E-1` is resolved, but runtime execution for Android `profile` and `release` MUST NOT be claimed as passed until executed on a physical Android device.

---

## Complexity Tracking

*No Constitution violations exist. This table is intentionally empty.*
