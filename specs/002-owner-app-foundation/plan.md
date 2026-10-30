# Implementation Plan: WalimApp Owner App Foundation

**Branch**: `002-owner-app-foundation` | **Date**: 2026-10-30 | **Spec**: [`spec.md`](./spec.md)
**Input**: Feature specification from [`specs/002-owner-app-foundation/spec.md`](./spec.md)

## Summary

Establish the production-grade shared Android (`API 24+`) and Windows (`x64`) Flutter application foundation (`apps/owner`) for WalimApp Local and WalimApp Connect. This slice introduces a clean 5-layer architecture (`core`, `domain`, `application`, `data`, `platform`, `presentation`), Flutter `gen-l10n` trilingual localization (`ar` RTL, `fr` LTR, `en` LTR) with Western Arabic digits (`0-9`), independent persistence for UI language (`language_pref`) and default document language (`default_doc_lang`), a responsive adaptive navigation shell (`< 600dp` `NavigationBar` usable down to `360dp` at `1.3x` text scale vs. `>= 600dp` / `>= 1024dp` leading-edge `NavigationRail`) across five top-level destinations (**Dashboard**, **Calendar**, **Venues & Halls**, **Finance**, **Settings**), and a reusable `EncryptedDatabaseFactory` wrapping the verified fail-closed `sqlite3mc` (`chacha20`) opener from Feature `001` without introducing any production business tables or edition/license logic.

## Technical Context

**Language/Version**: Dart `3.12.2` / Flutter `3.44.8` (`channel stable`)
**Primary Dependencies**:
- `flutter` & `flutter_localizations` (`sdk: flutter`)
- `intl: any` (SDK-pinned localization & formatting support, configured via `l10n.yaml` + `flutter: generate: true`)
- Existing dependencies from Feature `001` (unchanged): `drift: ^2.35.0`, `sqlite3: ^3.5.2` (with `hooks.user_defines.sqlite3.source: sqlite3mc`), `path: ^1.9.0`, `path_provider: ^2.1.0`, `uuid: ^4.6.0`
- Zero new third-party state-management, routing, or native storage plugins required
**Storage**:
- Lightweight atomic JSON file (`owner_preferences.json` in `getApplicationSupportDirectory()`) behind `AppPreferencesRepository` for `language_pref` and `default_doc_lang`
- Reusable `EncryptedDatabaseFactory` delegating to the verified fail-closed `EncryptedSqliteOpener` (`sqlite3mc` `chacha20`, `legacy = 0`) for future per-venue databases (zero production tables created in this feature)
**Testing**:
- `flutter analyze` (`0` errors, warnings, or lints)
- `flutter test` (unit tests for `SupportedAppLanguage` / `AppLocalePreference` / `FileAppPreferencesRepository` / `WesternNumeralFormatter`; widget tests for `WalimAppOwnerApp` adaptive shell at `360x800 @ 1.0x & 1.3x`, `390x844`, `768x1024`, `1280x800`, `RTL`/`LTR` mirroring, independent `language_pref` & `default_doc_lang` switching, and existing `sqlite_encryption_pot_test.dart` regression suite)
**Target Platforms**: Android (`API 24+`, verified on physical device `641e3fb1` Redmi Note 9 Pro Max `API 31`) and Windows Desktop (`x64`)
**Project Type**: Cross-platform mobile + desktop application (`apps/owner`)
**Performance Goals**: Instant runtime language/directionality switch within a single frame (`< 100 ms` perceived delay, `SC-001`); `0` `RenderFlex` layout overflows across all 5 destinations, 3 locales, and breakpoints (`SC-003`)
**Constraints**:
- Strictly no booking, calendar, customer/supplier, payment, authentication, sync, `.walimlic` licensing, Local/Connect edition detection, or `.walimbak` backup features (`FR-012`)
- Preserve `lib/main_pot.dart` and `lib/database/pot/*` untouched (`FR-002`)
**Scale/Scope**: 5 top-level shell destinations (Dashboard + Settings active, Calendar + Venues & Halls + Finance structured placeholders), 3 languages (`ar`, `fr`, `en`), ~18 focused Dart/ARB source and test files.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Constitutional Principle (`v1.3.3`) | Evaluation | Gate Status |
|---|---|---|
| **I. Shared Android & Windows Flutter Codebase & Adaptive UI (`< 600dp` vs `>= 600dp` / `>= 1024px`)** | Single `apps/owner` codebase with adaptive `NavigationBar` (`< 600dp`) and `NavigationRail` (`>= 600dp`, extended at `>= 1024dp`), plus `lib/platform/` adapter boundary. | **PASS** |
| **II. Genuine Local Independence & Fail-Closed `sqlite3mc` (`chacha20`)** | Preserves `EncryptedSqliteOpener` (`PRAGMA cipher = 'chacha20'; PRAGMA legacy = 0;` + pre-key check) behind `EncryptedDatabaseFactory`; `100%` offline operation. | **PASS** |
| **IV. Trilingual Support (`ar-DZ` RTL, `fr-DZ` LTR, `en` LTR) & Western Numerals (`0-9`)** | Full `.arb` localization for `ar`, `fr`, `en`, automatic `RTL`/`LTR` directionality, independent `language_pref` and `default_doc_lang` persistence, and `WesternNumeralFormatter` enforcing ASCII digits `0-9`. | **PASS** |
| **VI. Canonical Whole-DZD Money** | Sample currency formatting in `WesternNumeralFormatter` uses integer whole `DZD` (`int amountDzd`), never floats or centimes. | **PASS** |
| **IX. Solo-Developer Operational Simplicity** | Uses built-in Flutter `ChangeNotifier` / `ListenableBuilder`, SDK `flutter_localizations`, and existing `path_provider` with zero extra third-party frameworks. | **PASS** |
| **Section 4. No Fabricated Verification** | Both Windows `x64` and physical Android device `641e3fb1` are connected and available for real execution. | **PASS** |

*Post-Phase 1 Design Re-Check*: **PASS** (`0` violations).

## Project Structure

### Documentation (this feature)

```text
specs/002-owner-app-foundation/
├── plan.md                                  # This file (/speckit-plan output)
├── research.md                              # Phase 0 research & technical decisions
├── data-model.md                            # Phase 1 domain & presentation entities
├── quickstart.md                            # Phase 1 build, test, and device verification guide
├── contracts/
│   └── owner-preferences.schema.json        # Local JSON contract for language_pref & default_doc_lang
└── checklists/
    └── requirements.md                      # Specification quality checklist
```

### Source Code (`apps/owner`)

```text
apps/owner/
├── pubspec.yaml                             # Add flutter_localizations, intl, and flutter: generate: true
├── l10n.yaml                                # Configure gen-l10n output (AppLocalizations)
├── lib/
│   ├── main.dart                            # Production entrypoint launching WalimAppOwnerApp (FR-003)
│   ├── main_pot.dart                        # Preserved untouched from Feature 001 (FR-002)
│   ├── l10n/
│   │   ├── app_en.arb                       # English (LTR) strings (concise nav + full titles)
│   │   ├── app_fr.arb                       # French (LTR) strings (concise nav + full titles)
│   │   └── app_ar.arb                       # Arabic (RTL) strings (concise nav + full titles)
│   ├── core/
│   │   └── formatting/
│   │       └── western_numeral_formatter.dart # Cross-cutting utility enforcing Western digits 0-9 (FR-010)
│   ├── domain/                              # Pure Dart only — zero Flutter UI imports (FR-001)
│   │   ├── locale/
│   │   │   ├── supported_app_language.dart  # Pure-Dart enum (ar, fr, en), bool isRtl, deterministic resolution
│   │   │   └── app_locale_preference.dart   # Independent language_pref & default_doc_lang value object
│   │   ├── navigation/
│   │   │   └── owner_nav_destination.dart   # Pure-Dart enum (dashboard, calendar, venues, finance, settings)
│   │   └── repositories/
│   │       └── app_preferences_repository.dart # Abstract repository interface for AppLocalePreference
│   ├── application/
│   │   ├── app_locale_controller.dart       # ChangeNotifier managing independent language_pref & default_doc_lang
│   │   └── owner_shell_controller.dart      # ChangeNotifier preserving active OwnerNavDestination across resizes
│   ├── data/
│   │   ├── database/
│   │   │   └── encrypted_database_factory.dart # Production-ready wrapper over EncryptedSqliteOpener (FR-002)
│   │   └── preferences/
│   │       ├── file_app_preferences_repository.dart      # Atomic JSON file persistence in app support dir
│   │       └── in_memory_app_preferences_repository.dart # Deterministic in-memory repo for tests
│   ├── database/
│   │   └── pot/                             # Preserved untouched from Feature 001 (FR-002)
│   ├── platform/
│   │   └── owner_platform_environment.dart  # Simple platform & build-mode info (no edition/license checks)
│   └── presentation/
│       ├── app.dart                         # WalimAppOwnerApp (MaterialApp, maps isRtl -> TextDirection, theme, delegates)
│       ├── theme/
│       │   └── owner_theme.dart             # Hospitality color tokens, typography scale, spacing (FR-001, FR-011)
│       ├── shell/
│       │   ├── adaptive_layout_size.dart    # Breakpoint classifier (<600 compact, 600..1023 medium, >=1024 expanded)
│       │   └── owner_adaptive_shell.dart    # Adaptive NavigationBar / NavigationRail + workspace container
│       ├── screens/
│       │   ├── dashboard_screen.dart        # Home overview with build status, language summary & quick actions
│       │   ├── module_placeholder_screen.dart # Reusable structured placeholder for Calendar, Venues, Finance
│       │   └── settings_screen.dart         # Independent UI & document language selectors + build diagnostics
│       └── widgets/
│           └── language_selector_card.dart  # Reusable trilingual selector widget (العربية, Français, English)
└── test/
    ├── database/
    │   └── sqlite_encryption_pot_test.dart  # Preserved untouched from Feature 001
    ├── unit/
    │   ├── locale_preferences_test.dart     # Tests OS resolution, 'fr' fallback, independent persistence & corruption recovery
    │   └── western_numeral_formatter_test.dart # Tests Western digits 0-9 across ar, fr, en for numbers/dates/DZD
    └── widget/
        └── owner_app_shell_test.dart        # Tests RTL/LTR, independent language switches, 360dp@1.3x, 768dp, 1280dp & resize state
```

**Structure Decision**: Single cross-platform Flutter project under `apps/owner/` using explicit layered directories (`core/` for cross-cutting formatting, pure-Dart `domain/` with zero Flutter UI imports, `application/`, `data/`, `platform/`, and `presentation/` including `presentation/theme/owner_theme.dart`) while keeping `lib/database/pot/` and `lib/main_pot.dart` intact for encryption regression verification.

## Complexity Tracking

No constitutional violations. Zero complexity exceptions required.
