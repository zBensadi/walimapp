# Feature Specification: WalimApp Owner App Foundation

**Feature Branch**: `002-owner-app-foundation`

**Created**: 2026-10-30

**Status**: Draft

**Input**: User description: "Establish the shared WalimApp Owner application foundation (`002-owner-app-foundation`) for WalimApp Local and WalimApp Connect across Android phones and Windows desktops, including clean layered project structure, adaptive navigation shell with module placeholders, trilingual localization (`ar` RTL, `fr` LTR, `en` LTR) with persistent language preference and Western numerals (`0-9`), professional wedding-venue visual foundation, and automated unit/widget/device verification."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Trilingual First Launch, Independent Language Preferences & Persistence (Priority: P1)

A wedding venue owner or manager in Algeria opens the WalimApp Owner application on an Android phone or Windows PC and immediately experiences the interface in their preferred UI language (`language_pref`: Arabic `ar` with right-to-left layout, French `fr` with left-to-right layout, or English `en` with left-to-right layout), can independently choose their default document language (`default_doc_lang`: `ar`, `fr`, or `en`) for future generated contracts and receipts, can switch either preference at runtime without restarting the application, and finds both preferences automatically and independently restored on subsequent launches.

**Why this priority**: Trilingual support (`ar` RTL, `fr` LTR, `en` LTR), independent UI vs. document language preferences, and persistent locale directionality govern every screen, navigation control, typography scale, and number format across the entire application. Establishing and verifying them first prevents costly retrofits in all subsequent domain slices.

**Independent Test**: Launch the application with no saved preferences (verifying deterministic initial resolution for both `language_pref` and `default_doc_lang`), switch UI and default document languages independently in the interface (verifying immediate UI translation, `RTL`/`LTR` layout mirroring, Western Arabic digits `0-9`, and non-interference between the two settings), and restart the application to verify that both preferences persist independently across sessions.

**Acceptance Scenarios**:

1. **Given** the application is launched for the first time with no saved preferences, **When** the device or operating system locale matches `ar`, `fr`, or `en`, **Then** both the UI language (`language_pref`) and default document language (`default_doc_lang`) initialize in that matching language; **When** the device or operating system locale is any other language, **Then** both preferences initialize deterministically in French (`fr`).
2. **Given** the application is running in French (`LTR`) or English (`LTR`), **When** the user selects Arabic (`ar`) as the UI language (`language_pref`), **Then** all visible navigation labels, headings, and placeholder messages switch immediately to Arabic, the interface layout mirrors to right-to-left (`RTL`), and any displayed numbers or dates remain formatted with Western Arabic digits (`0-9`).
3. **Given** the user has selected a UI language (`language_pref`) and a default document language (`default_doc_lang`), **When** the application is closed and relaunched, **Then** the application starts directly with both previously selected preferences and the corresponding UI text direction restored without requiring the user to reselect them.
4. **Given** the user selects Arabic (`ar`) as the UI language (`language_pref`) and selects French (`fr`) as the default document language (`default_doc_lang`), **When** either preference is modified or the application is closed and relaunched, **Then** the application interface renders in Arabic (`RTL`) while the saved default document language remains French (`fr`), changing one preference never alters the other, and both persist independently across application restarts.

---

### User Story 2 - Adaptive Navigation Shell & Module Placeholders on Phone and Desktop (Priority: P1)

A venue owner or staff member navigates between the top-level sections of the WalimApp Owner application on either an Android smartphone or a Windows desktop PC, experiencing a touch-friendly bottom navigation bar on compact screens (`< 600dp`) and a persistent side navigation rail on wider tablet/desktop windows (`>= 600dp`), with a welcoming Home/Dashboard view and clear placeholder views for upcoming business modules.

**Why this priority**: The shared Android and Windows codebase requires a single adaptive application shell that adapts cleanly to screen width, orientation changes, and `RTL`/`LTR` directionality before any domain screens are mounted inside it.

**Independent Test**: Render the application shell at compact mobile widths (`< 600dp`, including `360x800` at `1.3x` text scale and `390x844`) and desktop widths (`>= 600dp` and `>= 1024dp`, e.g., `1280x800`), switch across all five top-level navigation destinations in both `LTR` (`fr`, `en`) and `RTL` (`ar`) modes, and resize/rotate the viewport to verify layout adaptation and state preservation.

**Acceptance Scenarios**:

1. **Given** the application viewport width is less than `600dp` (including a `360dp`-wide Android phone in portrait with system text scaling up to `1.3x`), **When** the main shell renders in Arabic (`ar`), French (`fr`), or English (`en`), **Then** all five top-level destinations are presented and usable in a bottom navigation bar (`NavigationBar`) with touch-friendly targets (`>= 48x48dp`), using concise localized navigation labels where needed while displaying the full localized destination title in the workspace.
2. **Given** the application viewport width is `600dp` or greater (such as a Windows desktop window or landscape tablet), **When** the main shell renders, **Then** top-level navigation is presented as a side navigation rail (`NavigationRail`) positioned on the leading edge (`left` in `LTR` for French/English, `right` in `RTL` for Arabic), expanding destination labels when width is `>= 1024dp`.
3. **Given** the user is on the Home/Dashboard destination, **When** they select any of the top-level destinations (**Dashboard**, **Calendar**, **Venues & Halls**, **Finance**, or **Settings**), **Then** the active destination indicator updates immediately and the workspace displays the corresponding full localized destination title and view or structured module placeholder without navigation errors.
4. **Given** the user is viewing a specific top-level destination (such as **Venues & Halls** or **Settings**), **When** the window is resized across the `600dp` or `1024dp` breakpoint or the device orientation changes, **Then** the currently selected destination and active language preferences remain preserved.

---

### User Story 3 - Maintainable Layered Architecture & Encrypted Database Readiness (Priority: P2)

As the solo developer building WalimApp Local and WalimApp Connect, the project structure cleanly separates presentation, application state/use-cases, domain models/contracts, data-access repositories, and platform adapters, while preserving the verified fail-closed encrypted SQLite opener (`sqlite3mc` `chacha20`) so future domain slices can plug in repositories without restructuring the application.

**Why this priority**: Establishing strict architectural boundaries and keeping the Sprint 1.1 SQLite encryption Proof of Technology intact as a regression-testable module ensures every subsequent feature slice can be added incrementally with zero architectural churn.

**Independent Test**: Inspect the module boundaries, run static analysis (`flutter analyze`) with zero warnings/errors, run the automated unit and widget test suites (`flutter test`), and verify that both the main owner application entrypoint (`lib/main.dart`) and the standalone encryption PoT runner (`lib/main_pot.dart`) compile and pass their checks.

**Acceptance Scenarios**:

1. **Given** the `apps/owner` codebase, **When** presentation widgets are inspected, **Then** they depend only on application/domain abstractions and localization resources—never directly invoking raw SQLite connections or platform-specific file system APIs.
2. **Given** the verified encrypted SQLite connection infrastructure from Feature `001`, **When** the foundation architecture is initialized, **Then** the reusable fail-closed encrypted database opener remains available for future production repositories and the standalone `lib/main_pot.dart` verification suite continues to pass all 4 encryption checks without regression.

---

### Edge Cases

- **Unsupported or corrupted stored language code**: If local preference storage contains an unrecognized or corrupted language code (e.g., `'de'` or empty string) for either `language_pref` or `default_doc_lang`, the application must fall back deterministically for that specific preference to the OS locale (if in `{ar, fr, en}`) or French (`fr`) without throwing an unhandled exception or resetting the other valid preference, and overwrite the invalid value on the next preference save.
- **Preference storage read/write failure**: If local preference persistence is temporarily unavailable on startup or during a preference change, the application must still launch and allow in-memory runtime switching of both `language_pref` and `default_doc_lang` without crashing.
- **Rapid window resizing and orientation changes**: Resizing a Windows desktop window rapidly across `< 600dp`, `600dp–1023dp`, and `>= 1024dp` or rotating an Android phone between portrait and landscape must not reset the selected navigation destination, lose the active language preferences, or trigger layout overflow errors (`RenderFlex overflowed`).
- **Narrow mobile screens with long localized labels**: All five navigation destinations must remain usable below `600dp`—including on `360dp`-wide Android phone viewports in Arabic (`ar`) and French (`fr`) with system text scaling up to `1.3x`—by using concise localized labels in the compact navigation bar (without clipping or horizontal overflow) while rendering the full localized destination title in the workspace.
- **Mixed-directionality text and numeral formatting**: Numerals, dates, and currency samples displayed inside Arabic (`RTL`) views must always use Western Arabic digits (`0-9`, never Eastern Arabic-Indic `٠-٩`).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001 (Layered Project Structure)**: The `apps/owner` codebase MUST be organized into explicit, maintainable layers separating **Presentation** (shell, screens, shared widgets, theme), **Application** (controllers/state management and use-case coordinators), **Domain** (core value objects, entities, and repository interfaces), **Data** (encrypted database connection factory and local preference storage implementations), and **Platform** (thin OS adapters).
- **FR-002 (Encrypted SQLite Infrastructure Readiness)**: The foundation MUST retain the verified fail-closed `sqlite3mc` (`chacha20`, `legacy = 0`) connection opener as a reusable data-layer service ready for future domain repositories, while keeping the isolated `lib/main_pot.dart` PoT runner functional and introducing **zero** production business tables (`venues`, `halls`, `reservations`, `payments`, etc.) in this slice.
- **FR-003 (Production Entrypoint)**: `apps/owner/lib/main.dart` MUST launch the WalimApp Owner application shell (`WalimAppOwnerApp`), initializing localization and persisted user preferences (`language_pref` and `default_doc_lang`) before rendering the initial frame.
- **FR-004 (Top-Level Navigation Destinations)**: The application shell MUST provide five localized top-level navigation destinations, each defining a concise localized navigation label (for compact bars) and a full localized workspace title:
  1. **Dashboard** (`dashboard`) — foundational home overview displaying a simple application environment/build status indicator (such as host platform and build mode, with zero dependency on subscription or license verification), active UI language (`language_pref`), current default document language (`default_doc_lang`), and quick access to language/settings.
  2. **Calendar** (`calendar`) — structured placeholder for future hall availability and reservation management.
  3. **Venues & Halls** (`venues`) — structured placeholder for future venue and hall setup.
  4. **Finance** (`finance`) — structured placeholder for future whole-DZD payment ledger and receipts.
  5. **Settings** (`settings`) — functional foundation settings screen providing independent runtime UI language selection (`language_pref`: `العربية`, `Français`, `English`), independent default document language selection (`default_doc_lang`: `العربية`, `Français`, `English`), and simple application build/platform diagnostics.
- **FR-005 (Adaptive Navigation Layout)**: The navigation shell MUST adapt automatically based on viewport width:
  - **Compact (`< 600dp`)**: Render a bottom `NavigationBar` with touch targets of at least `48x48dp` where all five destinations remain usable down to `360dp` width in Arabic (`ar`), French (`fr`), and English (`en`) with system text scaling up to `1.3x`, using concise localized navigation labels where necessary while showing the full localized destination title in the workspace.
  - **Medium (`600dp` to `< 1024dp`)**: Render a leading-edge `NavigationRail` with compact icon+label destinations alongside the primary workspace pane.
  - **Expanded (`>= 1024dp`)**: Render an expanded leading-edge `NavigationRail` (or extended labels) with a constrained, centered or multi-column-ready workspace container suitable for Windows desktop monitors.
- **FR-006 (Navigation State Preservation)**: Switching between Compact, Medium, and Expanded layouts (via window resize on Windows or device rotation on Android) or changing `language_pref` / `default_doc_lang` at runtime MUST preserve the currently selected top-level navigation destination.
- **FR-007 (Trilingual Localization & Zero Hardcoded Strings)**: All user-facing text in the application shell, dashboard, module placeholders, and settings screen MUST be localized in **Arabic (`ar`)**, **French (`fr`)**, and **English (`en`)** using Flutter's standard localization generation (`flutter_localizations` + `.arb` resource files), with zero hardcoded user-facing interface strings in widget code.
- **FR-008 (Bidirectional RTL/LTR Layout)**: Selecting Arabic (`ar`) as the UI language (`language_pref`) MUST configure the application tree with `TextDirection.rtl` so that the navigation rail, app bar actions, icons with directional meaning, padding (`EdgeInsetsDirectional`), and text alignment mirror to right-to-left; selecting French (`fr`) or English (`en`) as `language_pref` MUST configure `TextDirection.ltr`.
- **FR-009 (Independent UI & Document Language Preferences, Initial Resolution & Runtime Persistence)**:
  - The system MUST manage and persist two independent language preferences: the UI language (`language_pref` in `{'ar', 'fr', 'en'}`) and the default document language (`default_doc_lang` in `{'ar', 'fr', 'en'}`).
  - On startup, each preference MUST be resolved independently: if a valid persisted value (`'ar'`, `'fr'`, or `'en'`) exists for that preference, the application MUST use it; if no persisted value exists (or the stored value for that preference is invalid), the application MUST initialize it from the device/OS primary language code if in `{'ar', 'fr', 'en'}`, falling back deterministically to **French (`'fr'`)** otherwise.
  - Changing `language_pref` in the UI MUST update the entire interface locale and `RTL`/`LTR` directionality immediately at runtime and persist `language_pref` locally **without** altering `default_doc_lang`.
  - Changing `default_doc_lang` in Settings MUST persist `default_doc_lang` locally and update its displayed selection immediately **without** altering `language_pref` or the active UI locale.
- **FR-010 (Western Arabic Numerals `0-9`)**: All numbers, dates, and integer whole-DZD (`د.ج` / `DZD`) sample values displayed in the UI across all three locales (`ar`, `fr`, `en`) MUST be formatted using **Western Arabic digits (`0-9`)**.
- **FR-011 (Visual Design Tokens & Professional Theme)**: The application MUST define reusable theme tokens for color palette (warm hospitality-appropriate primary and neutral tones with WCAG AA contrast), typography scale (supporting both Latin and Arabic script legibility), and spacing/radius constants, avoiding heavy custom graphics or premature visual complexity.
- **FR-012 (Strict Scope Exclusions)**: This feature MUST NOT implement booking requests, reservation scheduling, calendar availability logic, customer/supplier records, payments/accounting, user authentication/RBAC, cloud synchronization, Local/Connect edition detection, `.walimlic` license or subscription verification, `.walimbak` backups, or public marketplace/admin screens.

### Key Entities *(include if feature involves data)*

- **`AppLocalePreference`**: Represents the user's two independent persisted localization settings—`uiLanguageCode` (`language_pref` in `{'ar', 'fr', 'en'}`) and `defaultDocumentLanguageCode` (`default_doc_lang` in `{'ar', 'fr', 'en'}`)—along with independent deterministic fallback resolution from the host OS locale.
- **`OwnerNavDestination`**: Enumerates the five top-level application shell destinations (`dashboard`, `calendar`, `venues`, `finance`, `settings`), mapping each to its concise localized navigation label, full localized workspace title, icon, and workspace view.
- **`AdaptiveLayoutSize`**: Classifies the current viewport width into `compact` (`< 600dp`), `medium` (`600dp..1023dp`), or `expanded` (`>= 1024dp`) to drive navigation shell chrome and content padding.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001 (Instant Runtime Language & Directionality Switch)**: Users can switch the UI language (`language_pref`) between Arabic (`ar` RTL), French (`fr` LTR), and English (`en` LTR) and independently switch the default document language (`default_doc_lang`) without interference, with 100% of visible shell, dashboard, placeholder, and settings text updating within a single frame (`< 100 ms` perceived delay) and without restarting the application.
- **SC-002 (100% Independent Preference Persistence Across Launches)**: Relaunching the application on both Windows desktop and the physical Android device restores both the previously selected UI language (`language_pref`) and the independently selected default document language (`default_doc_lang`)—including mixed configurations such as `language_pref = 'ar'` and `default_doc_lang = 'fr'`—in 100% of test runs.
- **SC-003 (Zero Layout Overflows Across Breakpoints, Scripts & Text Scaling)**: Rendering all 5 navigation destinations across all 3 languages (`ar`, `fr`, `en`) at representative mobile (`360x800` at `1.0x` and `1.3x` text scale, `390x844`), tablet (`768x1024`), and desktop (`1280x800`) viewport sizes keeps all 5 destinations usable and produces `0` layout overflow errors (`RenderFlex overflowed`).
- **SC-004 (Western Digit Compliance)**: 100% of numeric, date, and whole-DZD values rendered by the foundation shell and locale formatting utilities use Western Arabic digits (`0-9`) across `ar`, `fr`, and `en`.
- **SC-005 (Static Analysis, Automated Tests & Dual-Platform Verification)**: `flutter analyze` reports `0` issues, 100% of unit and widget tests for independent `language_pref` / `default_doc_lang` resolution, persistence, RTL/LTR directionality, and adaptive navigation pass, and the application runs and is verified on both Windows `x64` and the physical Android (`API 24+`) device.

## Assumptions

- Local user preferences (`language_pref` and `default_doc_lang`) for the application shell are stored as two independent keys in lightweight local preference storage (abstracted behind a repository interface so they can be backed by in-memory storage in unit/widget tests and local file/platform preferences at runtime) prior to opening a specific venue's encrypted `.db` file.
- When no saved preference exists for `language_pref` or `default_doc_lang` and the host OS language is neither Arabic (`ar`), French (`fr`), nor English (`en`), French (`fr`) serves as the deterministic default initial language for that unset preference.
- The Dashboard environment status badge reports only host platform and build-mode diagnostics (e.g., `Android • Debug` or `Windows • Release`) and does not inspect or imply WalimApp Local vs. WalimApp Connect edition or license state.
- The existing `lib/main_pot.dart` entrypoint and `lib/database/pot/` classes from Feature `001-sqlite-encryption-pot` are preserved untouched so encryption verification can be re-executed at any time.
