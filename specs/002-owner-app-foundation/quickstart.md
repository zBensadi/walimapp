# Quickstart & Verification Guide: WalimApp Owner App Foundation (`002-owner-app-foundation`)

**Date**: 2026-10-30
**Feature**: [`spec.md`](./spec.md)
**Data Model**: [`data-model.md`](./data-model.md)
**Preferences Contract**: [`contracts/owner-preferences.schema.json`](./contracts/owner-preferences.schema.json)

---

## 1. Prerequisites

- Flutter `3.44.8` (`channel stable`, Dart `3.12.2`) on Windows 10/11 `x64`.
- Physical Android device (`641e3fb1`, Redmi Note 9 Pro Max, Android 12, `API 31`) connected via `adb` for Android runtime verification.
- Working directory: `c:\proj\walimapp\apps\owner`.

---

## 2. Generate Localization & Run Static Analysis

```powershell
# Inside c:\proj\walimapp\apps\owner
flutter pub get
flutter gen-l10n
flutter analyze
```

**Expected Outcome**:
- `flutter gen-l10n` generates `AppLocalizations` (`ar`, `fr`, `en`) with `0` untranslated messages.
- `flutter analyze` exits with code `0` (`No issues found!`, `SC-005`).

---

## 3. Run Automated Unit & Widget Tests

```powershell
# Inside c:\proj\walimapp\apps\owner
flutter test
```

**Expected Outcome**:
- **Unit tests** (`test/unit/locale_preferences_test.dart`, `test/unit/western_numeral_formatter_test.dart`) pass:
  - Initial language resolution (`ar`, `fr`, `en` OS match; deterministic `'fr'` fallback for unsupported OS locales).
  - Independent `language_pref` and `default_doc_lang` updates and persistence (e.g., `language_pref = 'ar'`, `default_doc_lang = 'fr'`), plus per-field fallback when one stored value is corrupted.
  - Western Arabic digits (`0-9`) formatting across all three locales.
- **Widget tests** (`test/widget/owner_app_shell_test.dart`) pass:
  - Compact (`360x800` at `1.0x` and `1.3x` text scale, `390x844`), Medium (`768x1024`), and Expanded (`1280x800`) layouts render `NavigationBar` vs. `NavigationRail` with `0` `RenderFlex` overflow errors across all 5 destinations in `ar`, `fr`, and `en` (`SC-003`).
  - Switching `language_pref` to `ar` mirrors the shell to `TextDirection.rtl`; switching to `fr` or `en` sets `TextDirection.ltr` (`SC-001`).
  - Changing `language_pref` does not alter `default_doc_lang`, and changing `default_doc_lang` does not alter `language_pref` (`SC-001`, `SC-002`).
  - Window resize across `< 600dp`, `600..1023dp`, and `>= 1024dp` preserves the active `OwnerNavDestination` (`FR-006`).
- **SQLite Encryption PoT regression test** (`test/database/sqlite_encryption_pot_test.dart`) continues to pass (`FR-002`).

---

## 4. Runtime Verification on Windows Desktop (`x64`) & Physical Android Device (`641e3fb1`)

### Windows Desktop (`x64`)
```powershell
# Inside c:\proj\walimapp\apps\owner
flutter run -d windows
```
- Verify the expanded/medium `NavigationRail` shell, switch across all 5 destinations, switch UI language (`ar` RTL, `fr` LTR, `en` LTR) and default document language independently in Settings, and relaunch to confirm persistence.

### Physical Android Device (`641e3fb1`)
```powershell
# Inside c:\proj\walimapp\apps\owner
flutter build apk --debug
adb -s 641e3fb1 install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s 641e3fb1 shell am start -W -n com.walimapp.owner/.MainActivity
```
- Verify the compact `NavigationBar` on the physical phone screen, switch across all 5 destinations, verify `ar` (`RTL`), `fr` (`LTR`), and `en` (`LTR`) switching and independent `default_doc_lang` persistence across app restarts.
