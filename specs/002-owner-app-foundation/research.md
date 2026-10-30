# Phase 0 Research: WalimApp Owner App Foundation (`002-owner-app-foundation`)

**Date**: 2026-10-30
**Feature**: [`spec.md`](./spec.md)

---

## 1. Localization Infrastructure (`ar` RTL, `fr` LTR, `en` LTR) & Western Numerals (`0-9`)

- **Decision**:
  - Enable Flutter's official `gen-l10n` code generation via `flutter_localizations: { sdk: flutter }`, `intl: any`, `flutter: generate: true` in `apps/owner/pubspec.yaml`, and `apps/owner/l10n.yaml` (`arb-dir: lib/l10n`, `template-arb-file: app_en.arb`, `output-localization-file: app_localizations.dart`, `nullable-getter: false`).
  - Provide three complete `.arb` catalogs: `lib/l10n/app_en.arb` (`en`), `lib/l10n/app_fr.arb` (`fr`), and `lib/l10n/app_ar.arb` (`ar`), defining both **concise navigation bar labels** (for `< 600dp` compact widths down to `360dp` at `1.3x` text scale) and **full workspace titles/descriptions** for all five top-level destinations.
  - Implement a dedicated `WesternNumeralFormatter` utility (`lib/core/formatting/western_numeral_formatter.dart`) that formats integers, ISO-like dates (`YYYY-MM-DD`), and whole-DZD currency strings (`250,000 DZD` / `250 000 DA` / `250,000 د.ج`) using exclusively Western Arabic digits (`0-9`), normalizing any Eastern Arabic-Indic (`٠-٩` / `U+0660..U+0669`) or Extended Arabic-Indic (`۰-۹` / `U+06F0..U+06F9`) code points to ASCII `0-9`.
- **Rationale**:
  - `flutter_localizations` is built into the Flutter SDK, automatically sets `Directionality` (`TextDirection.rtl` for `ar`, `TextDirection.ltr` for `fr`/`en`) on `MaterialApp`, and enforces compile-time type safety for every localized key (`FR-007`, `FR-008`).
  - Explicitly normalizing digits in `WesternNumeralFormatter` guarantees `100%` compliance with Constitution Principle IV and `FR-010` regardless of OS locale number-symbol defaults.
- **Alternatives Considered**:
  - *Third-party runtime JSON localization packages (`easy_localization`, etc.)*: Rejected to avoid unnecessary third-party dependencies and runtime asset-loading race conditions (`Constitution Principle IX`).

---

## 2. Independent `language_pref` & `default_doc_lang` Persistence (`FR-009`)

- **Decision**:
  - Define an abstract `AppPreferencesRepository` interface in `lib/domain/repositories/app_preferences_repository.dart` operating on the immutable `AppLocalePreference` value object (`uiLanguageCode` = `language_pref`, `defaultDocumentLanguageCode` = `default_doc_lang`).
  - Provide two implementations in `lib/data/preferences/`:
    1. `FileAppPreferencesRepository`: Persists `{ "language_pref": "ar|fr|en", "default_doc_lang": "ar|fr|en" }` as UTF-8 JSON inside the application support directory (`path_provider`'s `getApplicationSupportDirectory()`), writing atomically via a `.tmp` file rename and recovering gracefully if the file is missing, corrupted, or unreadable.
    2. `InMemoryAppPreferencesRepository`: Deterministic in-memory implementation for fast unit and widget tests.
  - Each preference (`language_pref` and `default_doc_lang`) is resolved and updated independently:
    - If a stored value is in `{'ar', 'fr', 'en'}`, use it.
    - Otherwise, inspect the host OS primary language code (`PlatformDispatcher.instance.locale.languageCode`); if in `{'ar', 'fr', 'en'}`, use it; otherwise fall back deterministically to `'fr'`.
    - Updating `language_pref` writes only `language_pref` and leaves `default_doc_lang` untouched; updating `default_doc_lang` writes only `default_doc_lang` and leaves `language_pref` untouched.
- **Rationale**:
  - Reuses `path_provider` (`2.1.6`, already in `apps/owner/pubspec.lock` from Feature `001`) with zero new native plugins (`shared_preferences` is not needed), works identically on Android (`API 24+`) and Windows (`x64`), and stores preferences outside any per-venue `.db` file (`FR-009`, `SC-002`).
- **Alternatives Considered**:
  - *Adding `shared_preferences` plugin*: Rejected because `path_provider` is already present in `pubspec.lock` and a tiny JSON file repository avoids adding another platform plugin while giving full control over atomic writes and corruption recovery.

---

## 3. Adaptive Navigation Shell & `360dp @ 1.3x` Compact Usability (`FR-004`, `FR-005`, `FR-006`)

- **Decision**:
  - Classify viewport width (`MediaQuery.sizeOf(context).width`) via `AdaptiveLayoutSize`:
    - `compact` (`< 600dp`): Bottom `NavigationBar` with 5 destinations, concise localized labels (`maxLines: 1`, `overflow: TextOverflow.ellipsis`), and minimum `48x48dp` touch targets.To prevent vertical or horizontal overflow inside `NavigationBar` at `360dp` width when the OS text scale is high, clamp the `NavigationBar` label text scaler to a readable maximum (`TextScaler.linear(scale.clamp(1.0, 1.3))`) while keeping workspace content scrollable.
    - `medium` (`600dp` to `< 1024dp`): Leading-edge `NavigationRail(extended: false, labelType: NavigationRailLabelType.all)` (`left` in `LTR`, `right` in `RTL`) + vertical `VerticalDivider` + primary workspace pane.
    - `expanded` (`>= 1024dp`): Leading-edge `NavigationRail(extended: true)` showing full localized destination labels alongside a centered/constrained workspace container (`maxWidth: 1200`).
  - Hold the selected `OwnerNavDestination` in `OwnerShellController` (or stateful shell state) above the layout-switching `LayoutBuilder` so resizing across `600dp`/`1024dp` or switching `language_pref` / `default_doc_lang` never resets the active destination (`FR-006`).
- **Rationale**:
  - Directly satisfies Constitution Principle I (`< 600dp` touch-first phone UI vs `>= 600dp` / `>= 1024px` desktop `NavigationRail`) and Product Owner Review Gate 1 requirements (`360dp` width in `ar`/`fr` at `1.3x` text scale with zero `RenderFlex` overflows).
- **Alternatives Considered**:
  - *Separate mobile and desktop route trees*: Rejected because switching between them on window resize would lose navigation state (`FR-006`).

---

## 4. Layered Architecture & Encrypted SQLite Readiness (`FR-001`, `FR-002`)

- **Decision**:
  - Structure `apps/owner/lib/` into:
    - `lib/core/` — cross-cutting formatting utilities (`formatting/western_numeral_formatter.dart`).
    - `lib/domain/` — pure Dart entities/value objects (`locale/`, `navigation/`) and repository contracts (`repositories/`) with **zero Flutter UI imports** (`SupportedAppLanguage` exposes `bool get isRtl`).
    - `lib/application/` — `AppLocaleController` and `OwnerShellController` (`ChangeNotifier`-based controllers using Flutter's built-in `ListenableBuilder`).
    - `lib/data/` — `preferences/` (`FileAppPreferencesRepository`, `InMemoryAppPreferencesRepository`) and `database/` (`EncryptedDatabaseFactory` wrapping the verified `EncryptedSqliteOpener` from Feature `001`).
    - `lib/platform/` — thin platform environment info adapter (`OwnerPlatformEnvironment`).
    - `lib/presentation/` — visual theme (`theme/owner_theme.dart`), adaptive shell (`shell/`), top-level destination screens (`screens/`), and reusable UI components (`widgets/`), mapping `SupportedAppLanguage.isRtl` to Flutter's `TextDirection`.
  - Preserve `lib/main_pot.dart` and `lib/database/pot/*` untouched so the Sprint 1.1 SQLite encryption PoT remains runnable at any time (`FR-002`).
- **Rationale**:
  - Enforces strict unidirectional dependencies (`Presentation -> Application -> Domain <- Data`) with a pure-Dart `Domain` layer and `Presentation`-scoped theming (`FR-001`) without introducing heavy third-party DI or state-management frameworks (`Constitution Principle IX`).
