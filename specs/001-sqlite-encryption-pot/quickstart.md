# Quickstart & Validation Guide: SQLite Encryption Proof of Technology (`001-sqlite-encryption-pot`)

- **Feature Spec**: [`specs/001-sqlite-encryption-pot/spec.md`](./spec.md)
- **Data Model**: [`specs/001-sqlite-encryption-pot/data-model.md`](./data-model.md)
- **Report Contract**: [`specs/001-sqlite-encryption-pot/contracts/pot-verification-report.schema.json`](./contracts/pot-verification-report.schema.json)

---

## 1. Environment Prerequisites

### 1.1 Windows `x64` (Verified Ready on Development Machine)
- Flutter `3.44.8` (`stable`), Dart `3.12.2` (`enable-native-assets` enabled).
- Visual Studio Community 2026 (`18.8.2`) with Desktop development with C++ and Windows 10 SDK (`10.0.26100.0`).

### 1.2 Android `API 24+` (Compilation vs. Runtime Execution Prerequisites)
1. **Accept Android SDK Licenses (`Blocker E-1` — Required for All Android APK Compilation)**:
   ```powershell
   flutter doctor --android-licenses
   ```
2. **Android `debug` Runtime Target (`Blocker E-2a` — Emulator OR Physical Device)**:
   - Android `debug` runtime verification can run on either an Android Emulator (`API 24+` AVD) or a physical Android device:
     ```powershell
     & "$env:LOCALAPPDATA\Android\sdk\cmdline-tools\latest\bin\sdkmanager.bat" "system-images;android-35;google_apis;x86_64"
     & "$env:LOCALAPPDATA\Android\sdk\cmdline-tools\latest\bin\avdmanager.bat" create avd -n walimapp_api35 -k "system-images;android-35;google_apis;x86_64" --device "pixel_6"
     flutter emulators --launch walimapp_api35
     ```
3. **Android `profile` & `release` Runtime Target (`Blocker E-2b` — Physical Android Device Required)**:
   - Flutter restricts `--profile` and `--release` runtime execution to **physical Android devices** (Android emulators only support `debug` runtime execution).
   - Enable USB/Wi-Fi Debugging on a physical Android (`API 24+`) smartphone, connect via `adb`, and verify `adb devices -l` lists a physical device before running the Android `profile` and `release` runtime checks. Do **not** claim Android `profile` or `release` runtime checks have passed if only APK compilation or emulator `debug` was executed.

---

## 2. Project Setup & Static Analysis Commands (inside `apps/owner`)

```powershell
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```
- **Expected Outcome**: `0` errors and `0` warnings (`SC-005`).

---

## 3. Automated Unit & Integration Test Commands

### 3.1 Windows `x64` VM / Native Assets Test Suite
```powershell
flutter test test/database/sqlite_encryption_pot_test.dart
```

### 3.2 Windows `x64` Integration Test
```powershell
flutter test integration_test/sqlite_encryption_pot_integration_test.dart -d windows
```

### 3.3 Android `API 24+` Integration Test (Requires `E-1` + `E-2a`/`E-2b`)
```powershell
flutter test integration_test/sqlite_encryption_pot_integration_test.dart -d <android-device-id>
```

---

## 4. Proving All Six Platform / Build-Mode Combinations (`debug`, `profile`, `release`)

Each runtime execution runs `lib/main_pot.dart`, executes the 4 mandatory checks (`lifecycle_roundtrip_passed`, `raw_file_encrypted_passed`, `wrong_key_rejected_notadb_passed`, `fail_closed_guard_passed`), records `duration_ms` as an **informational measurement** against the `< 2000 ms` reference (`SC-004`), and emits `POT_REPORT_JSON:{"platform":...,"all_passed":true}` conforming to [`contracts/pot-verification-report.schema.json`](./contracts/pot-verification-report.schema.json):

| # | Platform | Build Mode | Compilation Command (from `apps/owner`) | Runtime Execution Command & Target Prerequisite |
| :--- | :--- | :--- | :--- | :--- |
| **1** | **Windows (`x64`)** | **`debug`** | `flutter build windows -t lib/main_pot.dart --debug` | `flutter run -d windows -t lib/main_pot.dart --debug --dart-define=POT_AUTO_EXIT=true` *(Windows `x64` host)* |
| **2** | **Windows (`x64`)** | **`profile`** | `flutter build windows -t lib/main_pot.dart --profile` | `flutter run -d windows -t lib/main_pot.dart --profile --dart-define=POT_AUTO_EXIT=true` *(Windows `x64` host)* |
| **3** | **Windows (`x64`)** | **`release`** | `flutter build windows -t lib/main_pot.dart --release` | `flutter run -d windows -t lib/main_pot.dart --release --dart-define=POT_AUTO_EXIT=true` *(Windows `x64` host)* |
| **4** | **Android (`API 24+`)** | **`debug`** | `flutter build apk -t lib/main_pot.dart --debug` | `flutter run -d <android-emulator-or-device-id> -t lib/main_pot.dart --debug` *(Emulator OR physical device)* |
| **5** | **Android (`API 24+`)** | **`profile`** | `flutter build apk -t lib/main_pot.dart --profile` | `flutter run -d <physical-android-device-id> -t lib/main_pot.dart --profile` *(**Physical Android device required**)* |
| **6** | **Android (`API 24+`)** | **`release`** | `flutter build apk -t lib/main_pot.dart --release` | `flutter run -d <physical-android-device-id> -t lib/main_pot.dart --release` *(**Physical Android device required**)* |
