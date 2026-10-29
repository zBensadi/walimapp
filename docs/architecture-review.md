# WalimApp — Architecture Review & Consolidation Analysis

**Status:** Phase 0 Baseline Artifact (For Product-Owner Review)  
**Date:** 2026-10-29  
**Sources Evaluated:**
- [`reference/architecture-drafts/architecture-opus.md`](../reference/architecture-drafts/architecture-opus.md) (*Opus Draft*)
- [`reference/architecture-drafts/architecture-sonnet.md`](../reference/architecture-drafts/architecture-sonnet.md) (*Sonnet Draft*)
- [`reference/architecture-drafts/architecture-gemini-argon.md`](../reference/architecture-drafts/architecture-gemini-argon.md) (*Argon Draft*)
- [`docs/product-requirements.md`](./product-requirements.md) (*Canonical PRD*)

---

## 1. Executive Summary of the Review

All three architecture drafts converge on the core macro-architecture required by the PRD:
1. **One shared Flutter owner application** using local **SQLite (via Drift)** for offline-first persistence across both **WalimApp Local** and **WalimApp Connect**, with Connect capabilities unlocked via entitlements rather than maintaining separate codebases.
2. **Client-generated UUIDv7 primary keys**, integer minor-unit money (`DZD` centimes), and an **append-only financial ledger** from Day 1 so Local-to-Connect migration preserves record identities without foreign-key rewriting.
3. **One Laravel modular monolith** backed by **one PostgreSQL database**, serving the Connect REST API, the **server-rendered (Blade + Livewire + Alpine.js)** bilingual public marketplace, and the **Filament** super-admin panel—without microservices, Kubernetes, or mandatory Redis.

However, a rigorous line-by-line inspection uncovered **material contradictions between the drafts**, **one truncated draft**, **an outdated 58-Wilaya assumption**, **unsafe migration and sync patterns in one draft**, and a **new cross-platform requirement (shared Flutter owner app for both Android smartphones and Windows desktop)** that none of the three drafts originally addressed.

This document records those findings, reconciles the contradictions, strips away solo-developer overengineering, and establishes full traceability to the canonical baseline in [`docs/architecture.md`](./architecture.md) and [`docs/decision-register.md`](./decision-register.md).

---

## 2. High-Level Comparison of the Three Drafts

| Dimension | `architecture-opus.md` (Opus) | `architecture-sonnet.md` (Sonnet) | `architecture-gemini-argon.md` (Argon) | Consolidated Baseline Decision |
| :--- | :--- | :--- | :--- | :--- |
| **Document Completeness** | **Truncated at line 1909 (§16.5).** Missing §17 (Security), §18 (Ops/Backups), §19 (Testing), §20 (ADRs), §21 (Risks), §22 (Roadmap), and §23 (Questions `Q-01`..`Q-35`). | **Complete** (2,120 lines, §1–§23 + Appendix A). Explicit PRD interpretation table (`I-1`..`I-5`). | **Complete** (1,904 lines, §1–§23). Concrete SQL DDL, Mermaid diagrams, and Algeria context. | Combine Sonnet's completeness and rigorous invariants with Opus's sync/staging precision and Argon's concrete schemas. |
| **Owner App Target Platforms** | Windows desktop first; mobile deferred. | Windows desktop first; mobile deferred (`OD-08`). | Windows desktop first; mobile mentioned only for future customer app. | **Updated per New Requirement:** Single shared Flutter codebase targeting **both Android smartphones and Windows desktop** from Phase 1. |
| **Algerian Wilaya Reference Data** | Warns **not** to hard-code 58 Wilayas (`§8.5`: divisions changed 48→58 and may change again). | Recommends seeding from current official list (`§15.2`). | **Error:** Hard-codes `1..58 (58 Algerian Wilayas)` in `VENUES` schema (`§8.1`), seeders (`§7.3`), and search (`§15.3`). | **Support the 69-Wilaya structure** via data-driven `wilayas` and `communes` reference tables keyed by official code. Never hard-code `CHECK (wilaya_code <= 58)`. |
| **Booking Requests vs. Reservations** | **Separate entities:** `booking_requests` (public intake) vs. `reservations` (operational). Approval atomically creates a `reservation`. | **Separate entities:** `booking_requests` vs. `reservations` (`ADR-011`, `I-2`). | **Combined in one table:** Stores public inquiries inside `reservations` with `status = 'pending_owner_approval'`. | **Separate `booking_requests` from `reservations`** (Opus/Sonnet). Prevents unverified web spam from polluting CRM customers and reservation ledgers. |
| **`pending_sync` Semantics** | **Client-side overlay** derived from unacknowledged `outbox_ops`; never stored as a server status (`§12.1`). | **Client-side overlay** (`I-1`, `§12.2`); server statuses are `confirmed`, `cancelled`, `needs_review`. | Stored as a primary `reservations.status` column value in both SQLite and PostgreSQL (`§8.1`, `§12.1`). | **`pending_sync` is a client-side sync state (`sync_state`)**, not a server business status. A `confirmed` reservation can simultaneously have a `pending_sync` local edit. |
| **Slot Granularity & Overlap Constraint** | Per-hall configurable `hall_slots` + separate `hall_allocations` table with `tstzrange` GiST exclusion and denormalized `is_blocking` flag. | Venue-defined `booking_slots` + `starts_at_local`/`ends_at_local` directly on `reservations` with `tsrange` GiST exclusion where `status = 'confirmed'`. | Fixed `slot_type` enum (`full_day`, `afternoon`, `evening`) mapped to hard-coded hours in a generated `tsrange` column on `reservations`. | **Configurable per-hall slots** (`hall_slots`) + half-open range `[starts_at_local, ends_at_local)` directly on `reservations` (Sonnet) with PostgreSQL `btree_gist` exclusion constraint. Avoids Opus's denormalized `is_blocking` drift risk and Argon's hard-coded hours. |
| **Sync Pull Ordering** | Dedicated `sync_changes` table ordered by per-org `org_sync_counters` row locked with `SELECT ... FOR UPDATE` (`§11.5`, `§11.7`). | Dedicated `sync_change_log` ordered by `org_sync_state.last_seq` updated late in the transaction (`§11.6`, `ADR-023`). | `server_seq` column stamped on each domain table without an explicit commit-serialization lock or unified change-log table. | **Dedicated `sync_change_log` + per-organization sequence row locked at commit** (Opus/Sonnet). Prevents out-of-order commits from causing pull clients to skip records, and supports tombstones/scope purges cleanly. |
| **Local-to-Connect Migration** | **Staged upload** (`migration_staging_records`) → server validation → single-TX commit → client finalize. Local DB untouched until commit. | **Staged upload** → validate → promote → verify → activate (`§13.3`). Local DB untouched until verified. | **Direct live upsert** (`INSERT ... ON CONFLICT DO UPDATE` into live tables) and mutates local SQLite `organization_id`/`venue_id` *before* upload (`§13.1`, `§13.3`). | **Staged, non-destructive migration** (Opus/Sonnet). Never mutate the local SQLite DB or write to live server tables before full manifest validation succeeds. |
| **Framework & Package Compatibility** | Laravel 12.x, PHP 8.4+, Filament v4, PostgreSQL 17/18. | Current supported Laravel, PostgreSQL, Filament (versions unpinned). | Laravel 11/12 + **Filament v3** + Livewire 3 + PostgreSQL 16/17. | **Pin compatible versions:** Laravel 12.x + PHP 8.4 + **Filament v4.x** + Livewire 3.x + PostgreSQL 17. (See §4.3 below). |

---

## 3. Requirements Coverage, Gaps & Contradictions

### 3.1 Requirements Properly Covered Across Drafts
- **WalimApp Local offline autonomy:** 100% offline SQLite via Drift, no LAN sync, no mandatory cloud telemetry or heartbeat (`PRD §3`).
- **Perpetual Local licensing:** Ed25519-signed offline license files where update entitlement compares `app_build_release_date <= maintenance_until` rather than the wall clock, and checks entitlement *before* running SQLite schema migrations (`PRD §3, §9`).
- **Immutable financial ledger:** Append-only `financial_transactions` with explicit reversal/void entries (`reverses_transaction_id`), eliminating silent edits and sync lost-update bugs (`PRD §3, §4`).
- **Server-side multi-tenancy & RBAC:** Explicit `TenantContext` derived from authenticated membership (never request payload), venue-scoped employee permissions, composite tenant foreign keys `(organization_id, id)`, and separate `admin` authentication guard with mandatory 2FA and append-only `audit_logs` (`PRD §2, §8, §11`).
- **Public marketplace & advertising:** Server-rendered Blade + Livewire + Alpine.js with `/ar` (RTL) and `/fr` (LTR) routes, Schema.org JSON-LD, availability freshness window, WhatsApp click-to-chat (`wa.me`), staff-curated initial provider directory, and sponsored placements that collapse cleanly when empty (`PRD §6`).
- **360° Virtual Tours deferred to Phase 4:** Equirectangular 2:1 panoramas with scenes, hotspots, moderation, and lazy-loaded WebGL viewer (Pannellum), explicitly decoupled from Phases 1–3 (`PRD §7, §12`).

### 3.2 Missing or Contradicted Requirements Identified

1. **Contradiction — 69 Wilayas vs. 58 Wilayas:**
   - **Requirement:** The reference data must support Algeria's **69-Wilaya structure** (following the elevation of 11 additional delegated wilayas after the 58-wilaya reorganization).
   - **Draft Contradiction:** `architecture-gemini-argon.md` hard-coded `58 Algerian Wilayas` (`1..58`) in schema comments, seeders, and marketplace filters.
   - **Correction:** The `wilayas` and `communes` tables are data-driven reference tables seeded with all **69 official Algerian Wilayas** (codes `01`–`69`), with no hard-coded upper-bound constraint (`<= 58`), and updateable via sync/migrations.

2. **Gap — Shared Flutter Codebase for Android Smartphones and Windows Desktop:**
   - **Requirement:** WalimApp must use **one shared Flutter codebase** targeting both **Android smartphones** and **Windows desktop** for venue owners and employees (both Local and Connect modes), with adaptive UI and multi-user Connect sync across individually authenticated devices.
   - **Draft Gap:** All three drafts designed the owner client exclusively for Windows desktop in Phase 1, treating mobile either as a distant owner companion (`Sonnet OD-08`) or a customer-only app (`Opus §5.8`, `Argon §22.2`).
   - **Correction:** Elevate Android to a first-class owner platform alongside Windows in `docs/architecture.md`, `docs/product-requirements.md`, and `docs/roadmap.md`, defining adaptive UI breakpoints and clean platform-abstraction interfaces for file storage, backups, printing/sharing, secure credential storage, and device identity.

3. **Contradiction — `booking_requests` vs. `reservations` Table Separation:**
   - **Requirement:** Booking requests must be distinct from actual reservations. Requests remain pending until an owner decides. Booking approval must validate availability and never silently overwrite a confirmed reservation (`PRD §5`).
   - **Draft Contradiction:** `architecture-gemini-argon.md` merged public booking requests into the `reservations` table (`status = 'pending_owner_approval'`).
   - **Correction:** Adopt the Opus/Sonnet model: `booking_requests` is a separate server-owned table (pulled to Connect clients). Approving a `booking_request` runs an atomic server transaction that validates availability against the PostgreSQL exclusion constraint, creates or links the `customer`, inserts a `confirmed` `reservation`, and marks the request `approved`.

4. **Contradiction — Connect Subscription Expiry Behavior on the Owner Device:**
   - **Requirement:** Expiration must be handled gracefully. Appropriate data preservation and export access must be provided. Existing Local data must remain available if Connect access expires (`PRD §9`).
   - **Draft Contradiction:**
     - *Opus (`§14.6`, `Q-21`):* If an organization subscribed to Connect *without* also owning a perpetual Local license, local editing is disabled (read-only + export only) when Connect expires; only organizations holding a Local license can continue local editing.
     - *Sonnet (`§14.4`) & Argon (`§14.2`):* When Connect expires, the device reverts to offline Local editing mode regardless, pausing only cloud sync, multi-device coordination, public listing visibility, and online booking requests.
   - **Resolution:** Recorded in [`docs/decision-register.md`](./decision-register.md) (`DEC-07`) for Product-Owner confirmation before Phase 2. The architecture supports both via the capability resolver (`local_edit_on_connect_expiry`), with the provisional default that **any organization that migrated from Local retains full Local editing forever**, while Connect-only subscribers get full read/export/print access and a configurable policy for new offline writes.

---

## 4. Technical Errors & Risky Assumptions Found in Drafts

### 4.1 Truncated Specification in `architecture-opus.md`
- **Issue:** `architecture-opus.md` terminates mid-document at line 1909 (`### 16.5 Backup of media`). Every cross-reference in Opus to `§17`–`§23`, `ADR-001`–`ADR-014`, `R-01`–`R-12`, and `Q-01`–`Q-35` points to non-existent sections in that file.
- **Mitigation:** Reconstructed and reconciled all security, operational, testing, ADR, risk, roadmap, and open-question items using `architecture-sonnet.md`, `architecture-gemini-argon.md`, and the inline design rules in `architecture-opus.md` §1–§16.

### 4.2 Unsafe In-Place Migration in `architecture-gemini-argon.md`
- **Issue:** `architecture-gemini-argon.md` (`§13.1`, `§13.3`) proposes:
  1. Running `UPDATE ... SET organization_id = :serverOrgId` and remapping `venue_id` inside the user's live local SQLite database *before* uploading Wave 1.
  2. Uploading chunks directly into live PostgreSQL tables via `INSERT ... ON CONFLICT DO UPDATE`.
- **Why this is dangerous:** If the migration fails validation in Wave 4 (e.g., due to a data constraint or abandoned upgrade), the owner's local SQLite database has already been mutated and live server tables contain half-migrated records.
- **Correction:** Adopt the **non-destructive staged migration protocol** (Opus §13 / Sonnet §13):
  - Upload chunks into `migration_staging_records` on the server.
  - Perform server-side validation, ID mapping (if merging into an existing server venue), overlap checks, and financial sum verification in staging.
  - Promote staged records to live PostgreSQL tables in a single atomic transaction.
  - Mutate local SQLite sync metadata (`organization_id`, `sync_state = 'synced'`, `last_pulled_seq`) **only after** the server confirms the commit.

### 4.3 Framework, Database & Package Version Compatibility
- **Filament vs. Laravel Version:** `architecture-gemini-argon.md` specifies `Laravel 11/12` with `Filament v3`. Filament v4 is the current release aligned with Laravel 12.x. We standardize on **Laravel 12.x + PHP 8.4 + Filament v4.x + Livewire 3.x**.
- **PostgreSQL `uuidv7()` Function:** `architecture-opus.md` (`§9.1`) notes that PostgreSQL 18 provides native `uuidv7()`. Because many managed and VPS Linux distributions ship PostgreSQL 16 or 17 by default, **UUIDv7 generation must be performed in application code** (Dart `uuid` package on the client; Laravel/Ramsey `Uuid::uuid7()` on the server) and stored in standard PostgreSQL `uuid` columns. This works identically on PostgreSQL 16, 17, and 18.
- **Android Hardware Fingerprinting Restriction:** All three drafts assume hardware identifiers (`MachineGuid` / SMBIOS UUID) can be read for license binding. On **Android 10+ (API 29+)**, apps cannot read non-resettable hardware serials or IMEI without privileged carrier permissions.
  - **Correction:** On Windows, use salted `SHA-256(MachineGuid)`. On Android, use a salted hash of `Settings.Secure.ANDROID_ID` (which is scoped per app-signing key, user, and device install) combined with an hardware-backed Android Keystore keypair created on activation. Because an OS factory reset changes this ID, the 14-day reactivation grace and self-service/support license transfer flow (§14) applies uniformly to both platforms.

### 4.4 Denormalized `is_blocking` Flag in `architecture-opus.md`
- **Issue:** Opus (`§9.5`) separates `hall_allocations` from `reservations` and puts `is_blocking boolean` on `hall_allocations`, requiring a nightly job to check whether `hall_allocations.is_blocking` drifted from `reservations.status`.
- **Correction:** For our initial domain (where a reservation books a specific `hall_id` for a date and slot/time range `[starts_at_local, ends_at_local)`), storing `hall_id`, `event_date`, `slot_id`, `starts_at_local`, and `ends_at_local` directly on `reservations` with a partial GiST exclusion constraint:
  ```sql
  EXCLUDE USING gist (
      hall_id WITH =,
      tsrange(starts_at_local, ends_at_local, '[)') WITH &&
  ) WHERE (status IN ('confirmed', 'tentative') AND deleted_at IS NULL)
  ```
  makes drift between reservation status and calendar blocking **mathematically impossible** without needing a separate allocation table or consistency cron job. Whole-venue multi-hall bookings (if enabled by the owner) are modeled cleanly either as linked per-hall reservations under a shared `booking_group_id` or deferred until needed.

### 4.5 PostgreSQL Row-Level Security (RLS) Trade-Off
- **Issue:** `architecture-gemini-argon.md` (`§17.1`) mandates PostgreSQL RLS (`SET LOCAL app.current_organization_id`) from Day 1 alongside Eloquent global scopes, explicit `TenantContext`, and composite foreign keys. `architecture-opus.md` and `architecture-sonnet.md` (`ADR-006`) warn that RLS with shared connection pools, background queue workers, and Filament admin queries frequently causes subtle bugs for a solo developer when composite tenant foreign keys `(organization_id, id)` and explicit `TenantContext` queries are already enforced and tested.
- **Correction:** Enforce **explicit `TenantContext` injection + composite tenant foreign keys `(organization_id, id)` + automated cross-tenant route/operation matrix tests** in Phase 2. Keep PostgreSQL RLS optional/deferred unless required by an external audit.

---

## 5. Overengineering Risks for a Solo Developer (And What We Cut)

| Proposed in One or More Drafts | Why It Is Overengineering for a Solo Developer | Consolidated Baseline Rule |
| :--- | :--- | :--- |
| **Separate `change_journal` AND `outbox_ops` AND `reservation_status_history` on the client** (Opus §11.3) | Writing three separate audit/outbox tables on every local SQLite mutation duplicates storage and code. | Keep `reservation_status_history` (user-visible business requirement) and `sync_outbox` (active in Connect; optional/lightweight in Local). Do not build a redundant generic local `change_journal` in Phase 1. |
| **Multi-resolution cubemap tile pyramids (`libvips` 8K tiling) for initial Virtual Tours** (Opus §16.4, Sonnet §16.6, Argon §16.3) | Building custom cubemap tile-slicing pipelines adds heavy media worker complexity. | In Phase 4 MVP, use single optimized equirectangular WebP images (`preview.webp` 1024×512 + `full.webp` 4096×2048) with lazy-loaded Pannellum. Add multi-res tiling only if 8K panoramas prove slow in production. |
| **Full deterministic multi-device chaos sync simulator before shipping M2** (Sonnet §19.5) | Writing a custom randomized multi-client network simulator from scratch can take weeks of engineering on its own. | Write targeted, deterministic **scenario integration tests** covering all 12 concurrency/sync collision cases (`S1`–`S12`), idempotent replay, out-of-order dependency blocking, and commit-order delta pulls against real PostgreSQL. |
| **Custom rotating refresh-token family tree alongside Laravel Sanctum** (Opus §10.3, Sonnet §10.3) | Sanctum already provides hashed, device-scoped, revocable bearer tokens with expiration. Rolling custom refresh-token reuse-detection state machines adds auth edge cases during intermittent connectivity. | Use **device-bound Laravel Sanctum tokens** (1 per registered `device_id`) stored in OS-protected secure storage (Android Keystore / Windows DPAPI) + signed **Connect entitlement lease tokens** (30-day offline validity). Add refresh rotation only if short-lived access tokens are required later. |
| **Separate `hall_allocations` table + nightly drift detector** (Opus §9.5) | Extra join and synchronization surface for every calendar query. | Put `hall_id`, `slot_id`, `starts_at_local`, `ends_at_local` directly on `reservations` (and `availability_blocks` or `kind = 'block'`) with a single PostgreSQL `EXCLUDE USING gist` constraint. |

---

## 6. Impact of the Shared Android + Windows Flutter Requirement

Making **Android smartphones** and **Windows desktop** co-equal first-class targets in a single Flutter codebase is a major strategic advantage for the Algerian market (where many venue owners and managers live on their Android phones and WhatsApp, while receptionists or larger venues use a Windows PC).

### 6.1 Architectural Adjustments Required
1. **Single Flutter Application (`apps/owner`):**
   - Shares 100% of `domain/`, `application/`, `data/` (Drift SQLite, DAOs, migrations, transactional outbox), `sync/`, `licensing/`, and `l10n/` (`ar-DZ` RTL and `fr-DZ` LTR).
   - Uses adaptive layout shells (`LayoutBuilder` / `MediaQuery` breakpoints):
     - **Compact (`< 600dp`, Android phones):** Bottom navigation bar, single-column master-detail push navigation, agenda/day-focused touch calendar, bottom-sheet quick actions, 1-tap phone dialer and WhatsApp deep-link launcher.
     - **Medium/Expanded (`>= 600dp` / `>= 1024px`, tablets & Windows desktop):** Navigation rail / sidebar, multi-column split views (calendar + reservation inspector side-by-side), dense data tables, keyboard shortcuts, and desktop print preview.
2. **Platform Abstraction Interfaces (`core/platform/`):**
   - `DeviceIdentityProvider`: Windows `MachineGuid` hash vs. Android `ANDROID_ID` + Keystore-bound installation key.
   - `SecureCredentialStore`: Windows DPAPI Credential Locker vs. Android Keystore (`EncryptedSharedPreferences`).
   - `BackupStorageAdapter`: Windows file-system folder picker + automatic rolling backups on exit vs. Android Storage Access Framework (SAF) / system `Share` sheet (allowing 1-tap backup export to Google Drive, WhatsApp self-chat, or USB OTG) + automatic rolling backups on app backgrounding (`AppLifecycleState.paused`).
   - `DocumentOutputAdapter`: Windows native print spooler + file save vs. Android PDF preview + system Print/Share intent (enabling owners to send a generated PDF contract or receipt directly to the client via WhatsApp).
   - `AppInstanceGuard`: Windows named mutex (prevents two app windows corrupting SQLite) vs. Android single-task activity launch mode.
3. **Multi-User Connect Synchronization:**
   - Multiple authenticated users in the same organization (e.g., the Owner on an Android smartphone, a Manager on another Android phone, and a Receptionist on the venue's Windows PC) each register their own `device_id`.
   - Every device maintains its own offline-first SQLite replica, pushes intents via `/api/v1/sync/push`, and pulls organization deltas via `/api/v1/sync/pull` filtered by the authenticated user's venue scope and role permissions.

---

## 7. Traceability Matrix (Requirements & Drafts → Canonical Baseline)

| Trace ID | Requirement / Topic | PRD Ref | Opus Ref | Sonnet Ref | Argon Ref | Canonical Resolution & Target Document |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TR-01** | Four product components (Local, Connect, Marketplace, Super-Admin) | §1 | §1, §4 | §1, §4 | §1, §4 | Two deployables: 1 Flutter app (Android + Windows, Local + Connect modes) + 1 Laravel modular monolith (`docs/architecture.md §2`). |
| **TR-02** | Shared Flutter codebase for Android & Windows | Prompt Add. Req | §5.5 (Win only) | §5.2.4 (Win only) | §5.2.D (Win only) | Unified Flutter codebase with responsive breakpoints and 5 platform adapters (`docs/architecture.md §3`, `docs/roadmap.md`). |
| **TR-03** | Local 100% offline independence & SQLite storage | §3 | §2.1, §5.6 | §4.4, §5.2.5 | §3.1, §11.1 | Drift + SQLite3 (`WAL`, `foreign_keys=ON`); zero runtime cloud calls in Local mode (`docs/architecture.md §3, §7`). |
| **TR-04** | Perpetual Local license & maintenance expiry safety | §3, §9 | §14.1–14.5 | §14.2, ADR-015 | §14.1, ADR-007 | Ed25519 offline `.walimlic` files; `build_release_date <= maintenance_until`; license check runs *before* DB schema migration (`docs/architecture.md §9`). |
| **TR-05** | UUIDv7 identity & non-destructive Local-to-Connect migration | §3, §4 | §9.1, §13 | §8.4, §13 | §9.1, §13 | Client-generated UUIDv7s from Phase 1; staged server upload → validate → single-TX promote → finalize (`docs/architecture.md §5, §8`). |
| **TR-06** | Separate `booking_requests` from `reservations` | §5 | §8.3, §12.1 | §3.4 I-2, §12.2 | Contradicted (§8.1) | Separate `booking_requests` table; approval atomically creates a `confirmed` `reservation` (`docs/architecture.md §5, §6`). |
| **TR-07** | `pending_sync` vs. server-authoritative `confirmed` bookings | §4, §5 | §12.1–12.5 | §3.4 I-1, §12.4 | §12.1–12.5 | `pending_sync` is a client-side overlay (`sync_state`); PostgreSQL `btree_gist` exclusion constraint enforces no overlapping `confirmed` bookings (`docs/architecture.md §6, §7`). |
| **TR-08** | Configurable booking slots (Full day, Afternoon, Evening, Overnight) | §5 | §8.2, §9.5 | §8.2, §9.2 | §9.3 (Fixed enum) | Per-hall configurable `hall_slots` + half-open `[starts_at_local, ends_at_local)` timestamp range on `reservations` (`docs/architecture.md §5, §6`). |
| **TR-09** | Idempotent sync push & commit-ordered delta pull | §4 | §11.3–11.9 | §11.4–11.8 | §11.2–11.5 | Transactional `sync_outbox` + server `sync_operations` idempotency log + `sync_change_log` serialized via `org_sync_state` row lock (`docs/architecture.md §7`). |
| **TR-10** | Immutable financial ledger & integer centimes | §3, §4 | §9.2, P4 | §8.3, ADR-014 | §9.2, ADR-008 | `amount_minor BIGINT` (DZD centimes); append-only `financial_transactions` with explicit reversal entries (`docs/architecture.md §5`). |
| **TR-11** | Multi-tenancy, venue-scoped RBAC & audited Super-Admin | §2, §4, §8, §11 | §10.4–10.5 | §10.4, §17.2 | §10.4, §17.1 | Server-enforced `TenantContext`, composite FKs `(organization_id, id)`, venue scopes, separate Filament `admin` guard + 2FA + append-only `audit_logs` (`docs/architecture.md §4, §11`). |
| **TR-12** | 69-Wilaya reference data & bilingual `ar-DZ`/`fr-DZ` localization | §6, §11, Prompt | §8.5, §15.5 | §15.2, §15.11 | Contradicted (58) | Seeded 69-Wilaya reference table; full Arabic RTL & French LTR with Western digits (`0-9`) across Flutter, PDF, and Web (`docs/architecture.md §5, §10`). |
| **TR-13** | Public marketplace SSR, availability freshness & sponsored ads | §6 | §15.1–15.7 | §15.1–15.9 | §15.1–15.5 | Laravel Blade + Livewire 3 + Alpine.js; availability shown only when sync is fresh; labeled sponsored slots collapse when empty (`docs/architecture.md §10`). |
| **TR-14** | 360° panoramic virtual tours (Phase 4 non-blocking) | §7, §12 | §16.4 | §16.6 | §16.3 | Equirectangular 2:1 panoramas, scene/hotspot graph, moderation, lazy-loaded Pannellum WebGL viewer in Phase 4 (`docs/architecture.md §10.4`). |
| **TR-15** | Algerian Law 18-07 / 25-11 privacy, hosting & backups | §11 | §9.8 | §17.3, §18.2 | §17.6, §18.5 | Cloud-agnostic Linux + PostgreSQL + S3 stack; hosting jurisdiction gated on legal review (`DEC-08`); encrypted backups with restore drills (`docs/architecture.md §11, §12`). |
