# Phase 0 Research: SQLite Encryption Proof of Technology (`001-sqlite-encryption-pot`)

- **Feature**: [`specs/001-sqlite-encryption-pot/spec.md`](./spec.md)
- **Date**: 2026-10-29

---

## 1. `sqlite3: ^3.8.0` Native Assets Build Hook & `sqlite3mc` Distribution

- **Decision**: Configure `pubspec.yaml` in `apps/owner` with:
  ```yaml
  dependencies:
    drift: ^2.35.0
    sqlite3: ^3.8.0
    path: ^1.9.0
    path_provider: ^2.1.0
    uuid: ^4.6.0
  dev_dependencies:
    drift_dev: ^2.35.0
    build_runner: ^2.17.0
    flutter_test:
      sdk: flutter
    integration_test:
      sdk: flutter
    flutter_lints: ^6.0.0

  hooks:
    user_defines:
      sqlite3:
        source: sqlite3mc
  ```
- **Rationale**: In `sqlite3` `3.x` (`3.8.0` verified on `pub.dev` on 2026-10-29), Dart's Native Assets (`hook/build.dart`) resolves `hooks.user_defines.sqlite3.source: sqlite3mc` automatically, bundling `SQLite3MultipleCiphers` for the target OS/architecture (`windows-x64` and `android-arm64`/`android-x64`) across `flutter test`, `flutter run`, and `flutter build` (`debug`, `profile`, `release`). This avoids the deprecated `sqlcipher_flutter_libs` (`0.7.0+eol`) plugin.
- **Alternatives Considered**:
  - `sqlcipher_flutter_libs`: Rejected (`0.7.0+eol`, superseded by `sqlite3` `3.x` build hooks).
  - Custom FFI CMake/Gradle build scripts: Rejected (`sqlite3: ^3.8.0` native assets hook handles symbol resolution and cross-platform bundling natively).

---

## 2. Explicit Pre-Key `chacha20` Configuration & Fail-Closed Runtime Verification

- **Decision**: Inside the `NativeDatabase` `setup` callback, execute statements in this exact sequence before any schema migration or user query:
  1. Validate the caller-supplied hex key is exactly 64 hexadecimal characters (`[0-9a-fA-F]{64}`, 256 bits); throw `ArgumentError` otherwise.
  2. Execute `PRAGMA cipher = 'chacha20';` and `PRAGMA legacy = 0;` **before** `PRAGMA key`.
  3. Execute `PRAGMA key = "x'<64-hex-chars>'";` and immediately zero any temporary mutable key `Uint8List` buffer.
  4. Query `SELECT sqlite3mc_config('cipher');` (with fallback check via `PRAGMA cipher;`) and verify with an unconditional runtime `if` guard (never `assert`) that the returned string equals `'chacha20'`. If it does not equal `'chacha20'` (e.g., `null` if standard unencrypted SQLite was linked by mistake, or another cipher name), close `rawDb` and throw `StateError('Fatal: sqlite3mc chacha20 cipher is not active')`.
  5. Execute `SELECT count(*) FROM sqlite_master;` to force immediate page 1 decryption/authentication (which throws `SqliteException` with `extendedResultCode`/`resultCode` `26` `SQLITE_NOTADB` when opened with a wrong key or unkeyed).
  6. Execute `PRAGMA foreign_keys = ON;`, `PRAGMA journal_mode = WAL;`, and `PRAGMA synchronous = NORMAL;`.
- **Rationale**: Standard unencrypted SQLite silently ignores unknown `PRAGMA` statements, and Dart strips `assert(...)` in `profile` and `release` builds. Querying `sqlite3mc_config('cipher')` + `sqlite_master` with an unconditional `if (...) throw StateError(...)` guarantees fail-closed behavior in `debug`, `profile`, and `release`.
- **Alternatives Considered**:
  - Relying on `sqlite3mc` default cipher without explicit `PRAGMA cipher = 'chacha20'`: Rejected per `ADR-003` and `REQ-LOC-20`.
  - Using `assert(activeCipher == 'chacha20')`: Rejected because `assert` is stripped in `profile` and `release` builds.

---

## 3. Proving All Six Platform / Build-Mode Combinations

- **Decision**: Provide two complementary test runners sharing the exact same `SqliteEncryptionPotSuite` library (`lib/database/pot/sqlite_encryption_pot_suite.dart`):
  1. **Standard Automated Test Runner (`test/database/sqlite_encryption_pot_test.dart` & `integration_test/sqlite_encryption_pot_integration_test.dart`)**: Runs under `flutter test` (Windows `x64` VM/native assets) and `flutter test integration_test/...` on Windows and Android.
  2. **Deterministic Build-Mode Smoke Runner (`lib/main_pot.dart`)**: Minimal entrypoint runnable and buildable in all 3 modes (`--debug`, `--profile`, `--release`) on both Windows (`x64`) and Android (`API 24+`). When launched with `--run-pot` (or on startup in the PoT harness app), it executes the full 4-check PoT suite (1: correct-key write/close/reopen/read round-trip; 2: raw file non-plaintext & header inspection; 3: wrong-key & unkeyed `SQLITE_NOTADB` code `26` rejection + subsequent valid reopen; 4: simulated cipher-mismatch fail-closed `StateError` guard), renders the pass/fail result on screen, prints a single-line `POT_REPORT_JSON:{...}` payload to stdout/logcat, and exits with code `0` (pass) or `1` (fail) when `--exit-after-pot` is passed on desktop.
- **Rationale**: `flutter test` alone only executes in `debug` VM mode. A dedicated `lib/main_pot.dart` entrypoint compiled with `--debug`, `--profile`, and `--release` proves that `sqlite3mc` native asset bundling and the unconditional fail-closed runtime guard work in AOT `profile` and `release` builds on both Windows `x64` and Android `API 24+`.
- **Performance Target Note**: The `< 2,000 ms` target (`SC-004`) is recorded as an **informational `duration_ms` measurement** in `PotVerificationReport` (not a hard acceptance gate that triggers optimization work in this PoT).

---

## 4. Local Environment Audit & Genuine Blockers Surfaced (2026-10-29)

| Check | Local Machine Status | Impact on 6 Platform/Build-Mode Combinations |
| :--- | :--- | :--- |
| **Flutter & Dart SDK** | Flutter `3.44.8` (`stable`), Dart `3.12.2`, `enable-native-assets` enabled | **Ready** |
| **Windows `x64` Toolchain** | Windows 10 64-bit (`22H2`), Visual Studio Community 2026 (`18.8.2`), Windows 10 SDK (`10.0.26100.0`), `windows-x64` device available | **Ready** for all 3 Windows build modes (`debug`, `profile`, `release` compilation and runtime execution) |
| **Android SDK & NDK** | Android SDK `36.0.0`, Platform `android-36.1`, Build-Tools `36.0.0`, NDK `28.2.13676358`, OpenJDK `21.0.10`, Emulator `37.1.11.0` | Installed |
| **Blocker `E-1`: Android SDK Licenses** | `flutter doctor -v` reports: `Some Android licenses not accepted.` | **Blocks Android APK compilation** (`flutter build apk --debug|--profile|--release`) until `flutter doctor --android-licenses` is accepted. |
| **Blocker `E-2a`: Android `debug` Runtime Target (AVD or Physical Device)** | `emulator -list-avds` / `system-images` shows `0` installed AVDs and `adb devices` shows `0` connected devices. | Once `E-1` is accepted, executing the **Android `debug` runtime check** requires either creating/launching an Android (`API 24+`) emulator AVD or connecting a physical Android device. |
| **Blocker `E-2b`: Android `profile` & `release` Runtime Target (Physical Device Required)** | `adb devices -l` shows `0` connected physical Android devices. | Because Flutter restricts `--profile` and `--release` runtime execution to **physical Android devices** (emulators only support `debug`), **executing the Android `profile` and `release` runtime checks requires a physical Android (`API 24+`) device**. APK compilation (`flutter build apk --profile` and `--release`) can be verified on the host once `E-1` is resolved, but runtime execution MUST NOT be claimed as passed until run on a physical device. |
