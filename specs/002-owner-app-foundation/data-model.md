# Phase 1 Data Model: WalimApp Owner App Foundation (`002-owner-app-foundation`)

**Date**: 2026-10-30
**Feature**: [`spec.md`](./spec.md)

> [!IMPORTANT]
> Per `FR-002` and `FR-012`, this slice introduces **zero** production SQLite business tables (`venues`, `halls`, `reservations`, `payments`, etc.). The entities below model the foundational localization preferences, adaptive navigation shell state, and runtime build diagnostics.

---

## 1. `SupportedAppLanguage` (Pure-Dart Domain Enum)

Represents the three canonically supported languages across the WalimApp Owner application (`Constitution Principle IV`, `FR-001`, `FR-007`..`FR-009`). This enum lives in `lib/domain/locale/` and has **zero Flutter UI imports** (`dart:ui` / `package:flutter`).

| Value | Code (`languageCode`) | Native Display Name | `isRtl` (`bool`) | Default Fallback Priority |
|---|---|---|---|---|
| `SupportedAppLanguage.ar` | `'ar'` | `'العربية'` | `true` | Matches OS `'ar'` |
| `SupportedAppLanguage.fr` | `'fr'` | `'Français'` | `false` | Matches OS `'fr'`, and serves as the **deterministic default fallback** when OS language is unsupported |
| `SupportedAppLanguage.en` | `'en'` | `'English'` | `false` | Matches OS `'en'` |

### Validation, Resolution & Presentation Mapping Rules
- **Pure-Dart Directionality Indicator**: Exposes `bool get isRtl` (`true` for `ar`, `false` for `fr` and `en`). The **Presentation layer** (`lib/presentation/`) maps `language.isRtl` to Flutter's `TextDirection` (`language.isRtl ? TextDirection.rtl : TextDirection.ltr`) and `Locale(language.languageCode)`.
- `SupportedAppLanguage.tryFromCode(String? rawCode)`:
  - Normalizes `rawCode` (`trim().toLowerCase()`, extracting primary subtag before `'-'` or `'_'` if present, e.g., `'fr-DZ'` $\rightarrow$ `'fr'`, `'ar_DZ'` $\rightarrow$ `'ar'`).
  - Returns `ar`, `fr`, or `en` when matched; returns `null` for any other input (`''`, `'de'`, `'es'`, corrupted strings).
- `SupportedAppLanguage.resolveInitial({String? storedCode, String? osLanguageCode})`:
  1. If `tryFromCode(storedCode)` is non-null, return it.
  2. Else if `tryFromCode(osLanguageCode)` is non-null, return it.
  3. Else return `SupportedAppLanguage.fr` (deterministic default fallback).

---

## 2. `AppLocalePreference` (Domain Value Object)

Represents the two **independent** persisted localization settings (`FR-009`, `SC-001`, `SC-002`).

| Field | Type | JSON Key | Description |
|---|---|---|---|
| `uiLanguage` | `SupportedAppLanguage` | `'language_pref'` | Active user interface language (`ar` RTL, `fr` LTR, or `en` LTR). |
| `defaultDocumentLanguage` | `SupportedAppLanguage` | `'default_doc_lang'` | Independent default language for future generated PDF contracts and payment receipts (`ar`, `fr`, or `en`). |

### Invariants & State Transitions
1. **Independence (`FR-009`)**:
   - `copyWithUiLanguage(SupportedAppLanguage newUiLanguage)` returns a new `AppLocalePreference(uiLanguage: newUiLanguage, defaultDocumentLanguage: defaultDocumentLanguage)`—never modifying `defaultDocumentLanguage`.
   - `copyWithDefaultDocumentLanguage(SupportedAppLanguage newDocLanguage)` returns a new `AppLocalePreference(uiLanguage: uiLanguage, defaultDocumentLanguage: newDocLanguage)`—never modifying `uiLanguage`.
2. **Independent Per-Field Fallback (`Edge Cases`, `FR-009`)**:
   - When deserializing from stored JSON (`fromJson(Map<String, Object?> json, {required String osLanguageCode})`), `uiLanguage` and `defaultDocumentLanguage` are resolved independently via `SupportedAppLanguage.resolveInitial`. If `language_pref` is valid (`'ar'`) and `default_doc_lang` is missing or corrupted (`'invalid'`), `uiLanguage` remains `ar` while only `defaultDocumentLanguage` falls back to OS/`fr`.

---

## 3. `OwnerNavDestination` (Pure-Dart Domain Enum)

Enumerates the five top-level navigation destinations in the WalimApp Owner shell (`FR-001`, `FR-004`). Defined as a pure-Dart enum in `lib/domain/navigation/` with zero Flutter UI imports.

| Enum Value | Stable ID | Index | Purpose in Feature `002` |
|---|---|---|---|
| `OwnerNavDestination.dashboard` | `'dashboard'` | `0` | Foundational home overview showing simple application environment/build status (platform + build mode), active `language_pref`, active `default_doc_lang`, Western numeral sample preview, and quick language/settings controls. |
| `OwnerNavDestination.calendar` | `'calendar'` | `1` | Structured module placeholder for future hall availability and reservation scheduling. |
| `OwnerNavDestination.venues` | `'venues'` | `2` | Structured module placeholder for future venue and hall configuration. |
| `OwnerNavDestination.finance` | `'finance'` | `3` | Structured module placeholder for future whole-DZD append-only payment ledger and receipts. |
| `OwnerNavDestination.settings` | `'settings'` | `4` | Functional foundation settings screen with independent selectors for `language_pref` and `default_doc_lang`, plus application environment/build diagnostics. |

### Presentation Label & Icon Mapping Contract (`FR-004`, `FR-005`)
- In the **Presentation layer** (`lib/presentation/`), each `OwnerNavDestination` is mapped to its Material icon (`IconData`) and two localized strings from `AppLocalizations`:
  - **Concise Navigation Label** (`navLabel*`): Short label designed to fit all 5 destinations inside a `360dp`-wide `NavigationBar` at `1.3x` text scale in `ar`, `fr`, and `en`.
  - **Full Workspace Title** (`workspaceTitle*`): Complete descriptive heading rendered in the screen's top bar and workspace header.

---

## 4. `AdaptiveLayoutSize` (Presentation Value Classification)

Classifies viewport width (`widthDp`) to drive adaptive navigation chrome (`FR-005`, `FR-006`).

| Classification | Viewport Width Condition | Navigation Component | Workspace Container Behavior |
|---|---|---|---|
| `AdaptiveLayoutSize.compact` | `widthDp < 600` | Bottom `NavigationBar` (`>= 48x48dp` targets, concise labels) | Full-width scrollable workspace with `16dp` directional horizontal padding |
| `AdaptiveLayoutSize.medium` | `600 <= widthDp < 1024` | Leading-edge `NavigationRail(extended: false, labelType: all)` | Scrollable workspace with `24dp` directional padding |
| `AdaptiveLayoutSize.expanded` | `widthDp >= 1024` | Leading-edge `NavigationRail(extended: true)` with full labels | Centered constrained workspace (`maxWidth: 1200dp`, `32dp` directional padding) |

---

## 5. `OwnerBuildEnvironmentInfo` (Platform Diagnostic Value Object)

Provides simple, license-free, edition-free runtime environment diagnostics for the Dashboard and Settings screens (`FR-004`, `FR-012`).

| Field | Type | Example Values | Description |
|---|---|---|---|
| `platformName` | `String` | `'android'`, `'windows'` | Host operating system identifier. |
| `buildModeName` | `String` | `'debug'`, `'profile'`, `'release'` | Active Flutter compilation mode. |
| `appVersion` | `String` | `'1.0.0+1'` | Application version string formatted with Western digits (`0-9`). |
