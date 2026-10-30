# Tasks: WalimApp Owner App Foundation

**Input**: Design documents from [`./`](./) (`002-owner-app-foundation`)
**Prerequisites**: [`plan.md`](./plan.md) (required), [`spec.md`](./spec.md) (required for user stories), [`data-model.md`](./data-model.md), [`contracts/owner-preferences.schema.json`](./contracts/owner-preferences.schema.json), [`research.md`](./research.md), [`quickstart.md`](./quickstart.md)

**Tests**: Automated unit tests (`test/unit/locale_preferences_test.dart`, `test/unit/western_numeral_formatter_test.dart`), widget tests (`test/widget/owner_app_shell_test.dart`), and regression tests (`test/database/sqlite_encryption_pot_test.dart`) are **mandatory** for this feature per `spec.md` (`SC-001`..`SC-005`).

**Organization**: Tasks are grouped by Setup, Foundational prerequisites, the three user stories (`US1`, `US2`, `US3`) in priority order, and Final Polish & Multi-Platform Verification.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`)
- Exact repository-relative file paths are included in every task description

## Path Conventions

- **Flutter Client (`apps/owner`)**:
  - `apps/owner/pubspec.yaml`
  - `apps/owner/l10n.yaml`
  - `apps/owner/lib/l10n/`
  - `apps/owner/lib/core/`
  - `apps/owner/lib/domain/`
  - `apps/owner/lib/application/`
  - `apps/owner/lib/data/`
  - `apps/owner/lib/platform/`
  - `apps/owner/lib/presentation/`
  - `apps/owner/test/unit/`
  - `apps/owner/test/widget/`

---

## Phase 1: Setup (Localization Infrastructure & Configuration)

**Purpose**: Configure Flutter standard `gen-l10n` localization and author the trilingual `.arb` string catalogs (`ar`, `fr`, `en`).

- [X] T001 Configure `apps/owner/pubspec.yaml` with `flutter_localizations: { sdk: flutter }`, `intl: any`, and `flutter: generate: true` to enable Flutter's standard localization code generation (`FR-007`)
- [X] T002 Create `apps/owner/l10n.yaml` with `arb-dir: lib/l10n`, `template-arb-file: app_en.arb`, `output-localization-file: app_localizations.dart`, and `nullable-getter: false` (`FR-007`)
- [X] T003 [P] Create English ARB catalog in `apps/owner/lib/l10n/app_en.arb` defining localized strings for all 5 destinations with both concise navigation labels (`dashboardNav`, `calendarNav`, `venuesNav`, `financeNav`, `settingsNav`) and full workspace titles/placeholders/settings options (`FR-004`, `FR-005`, `FR-007`)
- [X] T004 [P] Create French ARB catalog in `apps/owner/lib/l10n/app_fr.arb` with complete French translations matching all keys in `app_en.arb` (`FR-004`, `FR-005`, `FR-007`)
- [X] T005 [P] Create Arabic ARB catalog in `apps/owner/lib/l10n/app_ar.arb` with complete Arabic translations matching all keys in `app_en.arb` (`FR-004`, `FR-005`, `FR-007`)
- [X] T006 Run `flutter gen-l10n` in `apps/owner/` to generate `AppLocalizations` classes and verify `0` syntax or missing translation errors (`FR-007`)

---

## Phase 2: Foundational (Core Entities, Theme, Formatting & Preference Contracts)

**Purpose**: Implement pure-Dart domain models, cross-cutting formatting utilities, presentation theme tokens, and preference repository contracts required before user story widgets.

**⚠️ CRITICAL**: The `lib/domain/` layer must remain pure Dart with **zero Flutter UI imports** (`dart:ui` or `package:flutter`).

- [X] T007 [P] Implement pure-Dart `SupportedAppLanguage` enum in `apps/owner/lib/domain/locale/supported_app_language.dart` (`ar`, `fr`, `en`) exposing `bool get isRtl` (`true` for `'ar'`, `false` for `'fr'` and `'en'`), `tryFromCode(String?)` normalization, and `resolveInitial({String? storedCode, String? osLanguageCode})` with deterministic `'fr'` fallback and zero Flutter UI imports (`FR-001`, `FR-008`, `FR-009`)
- [X] T008 [P] Implement pure-Dart `AppLocalePreference` value object in `apps/owner/lib/domain/locale/app_locale_preference.dart` managing independent `uiLanguage` (`language_pref`) and `defaultDocumentLanguage` (`default_doc_lang`) with `copyWithUiLanguage`, `copyWithDefaultDocumentLanguage`, and per-field corruption fallback matching `specs/002-owner-app-foundation/contracts/owner-preferences.schema.json` (`FR-009`)
- [X] T009 [P] Implement pure-Dart `OwnerNavDestination` enum in `apps/owner/lib/domain/navigation/owner_nav_destination.dart` enumerating `dashboard`, `calendar`, `venues`, `finance`, and `settings` with zero Flutter UI imports (`FR-001`, `FR-004`)
- [X] T010 [P] Define abstract `AppPreferencesRepository` interface in `apps/owner/lib/domain/repositories/app_preferences_repository.dart` declaring `Future<AppLocalePreference> loadPreferences({required String osLanguageCode})` and `Future<void> savePreferences(AppLocalePreference preferences)` (`FR-001`, `FR-009`)
- [X] T011 [P] Implement `WesternNumeralFormatter` in `apps/owner/lib/core/formatting/western_numeral_formatter.dart` converting integers, ISO-8601 dates, and currency values (`int amountDzd`) to Western Arabic digits (`0-9`, normalizing any `٠-٩` or `۰-۹` code points to ASCII `0-9`) (`FR-010`)
- [X] T012 [P] Implement visual theme tokens in `apps/owner/lib/presentation/theme/owner_theme.dart` defining color schemes (hospitality warm primary and neutral tones with WCAG AA contrast), typography scale for Latin and Arabic scripts, and directional spacing/radius constants (`FR-001`, `FR-011`)
- [X] T013 [P] Implement `OwnerPlatformEnvironment` in `apps/owner/lib/platform/owner_platform_environment.dart` providing simple host platform (`android`/`windows`), build mode (`debug`/`profile`/`release`), and app version diagnostics with zero licensing or edition checks (`FR-004`, `FR-012`)

**Checkpoint**: Core domain entities compile as pure Dart with zero Flutter UI imports, theme tokens are established in `presentation/theme/`, and formatting utilities enforce Western digits `0-9`.

---

## Phase 3: User Story 1 - Trilingual First Launch, Independent Language Preferences & Persistence (Priority: P1) 🎯 MVP

**Goal**: Support instant runtime switching between Arabic (`ar` RTL), French (`fr` LTR), and English (`en` LTR), maintain independent preferences for UI language (`language_pref`) and default document language (`default_doc_lang`), persist both atomically to disk, and restore both independently on subsequent launches.

**Independent Test**: Launch the application with no saved preferences (verifying deterministic initial resolution for both `language_pref` and `default_doc_lang`), switch UI and default document languages independently in the interface (verifying immediate UI translation, `RTL`/`LTR` layout mirroring, Western Arabic digits `0-9`, and non-interference between the two settings), and restart the application to verify that both preferences persist independently across sessions (`SC-001`, `SC-002`).

### Tests for User Story 1

- [X] T014 [P] [US1] Write unit tests in `apps/owner/test/unit/locale_preferences_test.dart` covering initial language resolution (OS match for `ar`/`fr`/`en`, deterministic `'fr'` fallback for unsupported OS locales), independent preference persistence (e.g., `language_pref = 'ar'` while `default_doc_lang = 'fr'`), atomic file writes, per-field corruption recovery, and simulated preference storage read/write failures (verifying that read failures fall back gracefully to OS/'fr' defaults, write failures do not throw unhandled exceptions or revert in-memory state, and language switching remains functional in memory) (`FR-009`, `SC-001`, `SC-002`)
- [X] T015 [P] [US1] Write unit tests in `apps/owner/test/unit/western_numeral_formatter_test.dart` validating Western Arabic digits `0-9` across `ar`, `fr`, and `en` for integer whole-DZD amounts, dates, and number conversions (`FR-010`, `SC-004`)

### Implementation for User Story 1

- [X] T016 [US1] Implement `FileAppPreferencesRepository` in `apps/owner/lib/data/preferences/file_app_preferences_repository.dart` persisting `owner_preferences.json` atomically via `path_provider` support directory matching `contracts/owner-preferences.schema.json`, implementing graceful failure handling: catch filesystem/IO and deserialization exceptions on read (falling back gracefully to deterministic OS/'fr' defaults) and catch storage/write exceptions on save without crashing callers, preserving independent `language_pref` and `default_doc_lang` behavior (`FR-009`, `SC-002`)
- [X] T017 [P] [US1] Implement `InMemoryAppPreferencesRepository` in `apps/owner/lib/data/preferences/in_memory_app_preferences_repository.dart` for deterministic unit and widget testing (`FR-009`)
- [X] T018 [US1] Implement `AppLocaleController` in `apps/owner/lib/application/app_locale_controller.dart` as a `ChangeNotifier` managing `AppLocalePreference` with independent `setUiLanguage` and `setDefaultDocumentLanguage` methods that immediately update in-memory state, notify listeners, and persist asynchronously, handling persistence failures gracefully so write errors never crash the application or revert current in-memory preferences (`FR-009`, `SC-001`)
- [X] T019 [US1] Implement `LanguageSelectorCard` widget in `apps/owner/lib/presentation/widgets/language_selector_card.dart` providing a trilingual toggle selector (`العربية`, `Français`, `English`) reusable for UI language and document language selection (`FR-004`, `FR-009`)
- [X] T020 [US1] Implement `SettingsScreen` in `apps/owner/lib/presentation/screens/settings_screen.dart` with independent selectors for UI language (`language_pref`) and default document language (`default_doc_lang`), displaying simple build diagnostics from `OwnerPlatformEnvironment` (`FR-004`, `FR-009`)

**Checkpoint**: User Story 1 unit tests pass (`flutter test test/unit/locale_preferences_test.dart test/unit/western_numeral_formatter_test.dart`). Independent preference persistence, graceful storage failure handling, and Western numeral formatting verified.

---

## Phase 4: User Story 2 - Adaptive Navigation Shell & Module Placeholders on Phone and Desktop (Priority: P1)

**Goal**: Provide a responsive adaptive navigation shell presenting a compact bottom `NavigationBar` on screens `< 600dp` (usable down to `360dp` at `1.3x` text scale in `ar` and `fr`) and a persistent leading-edge `NavigationRail` on screens `>= 600dp` and `>= 1024dp`, with a welcoming Dashboard and structured placeholders for Calendar, Venues & Halls, and Finance.

**Independent Test**: Render the application shell at compact mobile widths (`< 600dp`, including `360x800` at `1.0x` and `1.3x` text scale and `390x844`) and desktop widths (`>= 600dp` and `>= 1024dp`, e.g., `1280x800`), switch across all five top-level navigation destinations in both `LTR` (`fr`, `en`) and `RTL` (`ar`) modes, and resize/rotate the viewport to verify layout adaptation and destination state preservation (`SC-003`).

### Implementation for User Story 2

- [X] T021 [P] [US2] Implement `AdaptiveLayoutSize` enum and classifier in `apps/owner/lib/presentation/shell/adaptive_layout_size.dart` mapping viewport width to `compact` (`< 600dp`), `medium` (`600..1023dp`), and `expanded` (`>= 1024dp`) (`FR-005`)
- [X] T022 [P] [US2] Implement `OwnerShellController` in `apps/owner/lib/application/owner_shell_controller.dart` maintaining the active `OwnerNavDestination` across layout resizing and language changes (`FR-006`)
- [X] T023 [P] [US2] Implement `DashboardScreen` in `apps/owner/lib/presentation/screens/dashboard_screen.dart` showing application build/environment status (platform + build mode, without license/edition checks), active `language_pref`, active `default_doc_lang`, Western numeral formatted sample amount, and quick navigation actions (`FR-004`, `FR-010`)
- [X] T024 [P] [US2] Implement reusable `ModulePlaceholderScreen` in `apps/owner/lib/presentation/screens/module_placeholder_screen.dart` rendering localized structured placeholder cards for `calendar`, `venues`, and `finance` destinations (`FR-004`)
- [X] T025 [US2] Implement `OwnerAdaptiveShell` in `apps/owner/lib/presentation/shell/owner_adaptive_shell.dart` hosting the 5 destinations in a bottom `NavigationBar` with clamped label text scaling for `< 600dp` (usable down to `360dp` at `1.3x` text scale) and leading-edge `NavigationRail` for `>= 600dp` / `>= 1024dp`, mapping `SupportedAppLanguage.isRtl` to leading/trailing edge (`FR-004`, `FR-005`, `FR-006`, `FR-008`)
- [X] T026 [US2] Implement `WalimAppOwnerApp` in `apps/owner/lib/presentation/app.dart` configuring `MaterialApp` with `AppLocalizations.delegates`, dynamic `locale`, `supportedLocales`, theme from `OwnerTheme`, and `Directionality` derived from `localeController.currentPreference.uiLanguage.isRtl` (`FR-003`, `FR-007`, `FR-008`)

### Tests for User Story 2

- [X] T027 [US2] Write widget tests in `apps/owner/test/widget/owner_app_shell_test.dart` verifying all 5 destinations render with `0` `RenderFlex` overflow errors across `360x800` (`1.0x` and `1.3x` text scale), `390x844`, `768x1024`, and `1280x800`, testing RTL/LTR mirroring, independent language switching, and destination preservation across resize (`FR-005`, `FR-006`, `SC-001`, `SC-002`, `SC-003`)

**Checkpoint**: User Stories 1 and 2 functional. Adaptive shell renders cleanly across mobile, tablet, and desktop breakpoints without layout overflows.

---

## Phase 5: User Story 3 - Maintainable Layered Architecture & Encrypted Database Readiness (Priority: P2)

**Goal**: Ensure the project cleanly separates presentation, application, pure-Dart domain, data, and platform layers, while preserving the verified fail-closed encrypted SQLite opener (`sqlite3mc` `chacha20`) as a reusable factory service ready for future domain repositories without introducing any production business tables.

**Independent Test**: Inspect module boundaries (verifying pure Dart in domain and presentation theme placement), run `flutter analyze` (`0` issues), run the automated unit and widget test suites, and verify that both `lib/main.dart` and `lib/main_pot.dart` compile and pass their checks without regression (`FR-001`, `FR-002`).

### Implementation for User Story 3

- [X] T028 [P] [US3] Implement `EncryptedDatabaseFactory` in `apps/owner/lib/data/database/encrypted_database_factory.dart` wrapping the verified `EncryptedSqliteOpener` from Feature 001 for future production per-venue databases with zero business tables created (`FR-001`, `FR-002`)
- [X] T029 [US3] Update `apps/owner/lib/main.dart` production entrypoint to initialize preferences repository (gracefully catching storage initialization errors so the app launches with in-memory fallback preferences if storage is unavailable) and launch `WalimAppOwnerApp` while keeping `apps/owner/lib/main_pot.dart` intact and standalone (`FR-002`, `FR-003`)

### Tests for User Story 3

- [X] T030 [US3] Run `flutter test test/database/sqlite_encryption_pot_test.dart` in `apps/owner/` to verify zero regression in the Feature 001 fail-closed `sqlite3mc` (`chacha20`) test suite (`FR-002`)

**Checkpoint**: All three user stories implemented. Pure-Dart domain boundaries intact, `EncryptedDatabaseFactory` ready for future repositories, and Feature 001 PoT regression test passes.

---

## Phase 6: Polish & Multi-Platform Verification

**Purpose**: Execute static analysis, run full automated test suites, and perform end-to-end runtime validation on Windows `x64` and the connected physical Android device.

- [X] T031 Run `flutter analyze` in `apps/owner/` and verify `0` errors, warnings, or lints (`SC-005`)
- [X] T032 Run `flutter test` across all unit, widget, and PoT regression test suites in `apps/owner/` and verify 100% pass rate (`SC-005`)
- [X] T033 Execute Windows `x64` desktop runtime verification via `flutter run -d windows` in `apps/owner/`, testing trilingual switching, independent document language preference persistence, and adaptive layout (`SC-001`..`SC-005`)
- [X] T034 Execute Android runtime verification on connected physical device `641e3fb1` (Redmi Note 9 Pro Max, Android 12, `API 31`) via `flutter run -d 641e3fb1`, verifying the application on the physical device's native dimensions and configured text scaling: compact bottom navigation usability across all 5 destinations, Arabic RTL / French LTR / English LTR switching, smooth touch interaction, and independent preference persistence across application restarts (`SC-001`..`SC-005`)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately (`T001` $\rightarrow$ `T002` $\rightarrow$ `T003`..`T005` in parallel $\rightarrow$ `T006`).
- **Foundational (Phase 2)**: Depends on Setup (`T001`..`T006`) — blocks all user stories (`T007`..`T013` can run in parallel `[P]`).
- **User Story 1 (Phase 3, P1)**: Depends on Phase 2. Tests `T014`, `T015` written first $\rightarrow$ Data repositories `T016`, `T017` $\rightarrow$ Controller `T018` $\rightarrow$ Widgets `T019`, `T020`.
- **User Story 2 (Phase 4, P1)**: Depends on Phase 2 and Phase 3 (`AppLocaleController` / `SettingsScreen`). Shell components `T021`..`T024` $\rightarrow$ Shell `T025` $\rightarrow$ App root `T026` $\rightarrow$ Widget tests `T027`.
- **User Story 3 (Phase 5, P2)**: Depends on Phase 3 and Phase 4. `EncryptedDatabaseFactory` `T028` $\rightarrow$ Main entrypoint `T029` $\rightarrow$ Regression test `T030`.
- **Polish & Multi-Platform Verification (Phase 6)**: Depends on all user stories (`T031` $\rightarrow$ `T032` $\rightarrow$ `T033` Windows $\rightarrow$ `T034` Android device `641e3fb1`).

### User Story Dependencies

- **User Story 1 (P1)**: Foundational MVP delivering trilingual localization, independent UI vs. document language persistence, and Western Arabic numerals.
- **User Story 2 (P1)**: Mounts the trilingual app into the responsive adaptive shell across compact (<600dp) and desktop (>=600dp) viewports.
- **User Story 3 (P2)**: Formalizes production entrypoint and database factory readiness, proving zero regression on Feature 001.

### Parallel Opportunities

- **Phase 1**: `T003` (`app_en.arb`), `T004` (`app_fr.arb`), and `T005` (`app_ar.arb`) can be authored in parallel.
- **Phase 2**: `T007` (`supported_app_language.dart`), `T008` (`app_locale_preference.dart`), `T009` (`owner_nav_destination.dart`), `T010` (`app_preferences_repository.dart`), `T011` (`western_numeral_formatter.dart`), `T012` (`owner_theme.dart`), and `T013` (`owner_platform_environment.dart`) touch distinct files and can run in parallel.
- **Phase 3**: `T014` and `T015` tests can run in parallel; `T016` and `T017` repositories can be implemented in parallel.
- **Phase 4**: `T021`, `T022`, `T023`, `T024` touch distinct files and can be authored in parallel before `T025`.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (`flutter gen-l10n`, `.arb` catalogs).
2. Complete Phase 2: Foundational (pure-Dart domain enums, theme, formatting, repository contract).
3. Complete Phase 3: User Story 1 (tests, atomic preference repository, controller, settings screen).
4. **STOP and VALIDATE**: Test User Story 1 independently (`flutter test test/unit/`).

### Incremental Delivery

1. Complete Setup + Foundational $\rightarrow$ Pure-Dart domain & trilingual infrastructure ready.
2. Add User Story 1 $\rightarrow$ Trilingual preferences & Western numerals testable independently (MVP).
3. Add User Story 2 $\rightarrow$ Adaptive navigation shell & module placeholders testable independently.
4. Add User Story 3 $\rightarrow$ Production entrypoint & `EncryptedDatabaseFactory` verified with zero regression on Feature 001.
5. Polish & Verification $\rightarrow$ Dual-platform validation on Windows desktop and physical Android device `641e3fb1`.
