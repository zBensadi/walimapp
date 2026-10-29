# WalimApp — Architecture Review & Consolidation Analysis

- **Status:** Phase 0 Baseline Artifact v1.1 (Post-Audit Consolidated)
- **Last Updated:** 2026-10-29
- **Sources Evaluated:**
  - [`reference/architecture-drafts/architecture-opus.md`](../reference/architecture-drafts/architecture-opus.md) (*Opus Draft*)
  - [`reference/architecture-drafts/architecture-sonnet.md`](../reference/architecture-drafts/architecture-sonnet.md) (*Sonnet Draft*)
  - [`reference/architecture-drafts/architecture-gemini-argon.md`](../reference/architecture-drafts/architecture-gemini-argon.md) (*Argon Draft*)
  - [`reference/architecture-drafts/product-requirements-initial.md`](../reference/architecture-drafts/product-requirements-initial.md) (*Initial PRD Input*)
- **Canonical Targets:** [Product Requirements](./product-requirements.md), [Architecture Baseline](./architecture.md), [Decision Register](./decision-register.md), [Roadmap](./roadmap.md), [Project Constitution](../.specify/memory/constitution.md).

---

## 1. Executive Summary of the Review

All three architecture drafts converge on the core macro-architecture required by the product context:
1. **One shared Flutter owner application** using local **encrypted SQLCipher/SQLite (via Drift)** for offline-first persistence across both **WalimApp Local** (Phase 1 single-device offline edition) and **WalimApp Connect** (Phase 2 multi-user, multi-device synchronized edition), with Connect capabilities unlocked via entitlements rather than maintaining separate codebases.
2. **Client-generated UUIDv7 primary keys**, **integer whole Algerian Dinars (`BIGINT` `DZD`, column suffix `*_dzd`)**, and an **unconditionally append-only financial ledger** from Day 1 so Local-to-Connect migration preserves record identities without foreign-key rewriting or 100x unit conversion errors.
3. **One Laravel modular monolith** backed by **one PostgreSQL 17 database**, serving the Connect REST/Sync API, the **server-rendered (Blade + Tailwind CSS + Alpine.js)** bilingual public marketplace, and the **Filament** super-admin panel—without microservices, Kubernetes, or mandatory Redis.

However, a rigorous line-by-line inspection and our Phase 0 independent audit ([`docs/walimapp-phase0-audit.md`](./walimapp-phase0-audit.md)) uncovered **material contradictions between the drafts**, **one truncated draft**, **an outdated 58-Wilaya assumption**, **unsafe migration and sync patterns in one draft**, **unit mismatches (centimes vs. whole DZD)**, and a **cross-platform requirement (shared Flutter owner app for both Android smartphones and Windows desktop)** that none of the three drafts originally addressed.

This document records those findings, reconciles the contradictions, strips away solo-developer overengineering, and establishes full mechanical traceability (`TR-01`..`TR-15`) to the canonical baseline in [`docs/architecture.md`](./architecture.md) and [`docs/decision-register.md`](./decision-register.md).

---

## 2. High-Level Comparison of the Three Drafts

| Dimension | `architecture-opus.md` (Opus) | `architecture-sonnet.md` (Sonnet) | `architecture-gemini-argon.md` (Argon) | Consolidated Baseline Decision (`docs/architecture.md`) |
| :--- | :--- | :--- | :--- | :--- |
| **Document Completeness** | **Truncated at line 1909 (`§16.5`).** Missing `§17` (Security), `§18` (Ops/Backups), `§19` (Testing), `§20` (ADRs), `§21` (Risks), `§22` (Roadmap), and `§23` (Questions `Q-01`..`Q-35`). | **Complete** (2,120 lines, `§1`–`§23` + Appendix A). Explicit PRD interpretation table (`I-1`..`I-5`). | **Complete** (1,904 lines, `§1`–`§23`). Concrete SQL DDL, Mermaid diagrams, and Algeria context. | Combine Sonnet's completeness and rigorous invariants with Opus's sync/staging precision and Argon's concrete schemas. |
| **Owner App Target Platforms & Edition Scope** | Windows desktop first; mobile deferred. | Windows desktop first; mobile deferred (`OD-08`). | Windows desktop first; mobile mentioned only for future customer app. | **Single shared Flutter codebase (`apps/owner`) targeting both Android smartphones and Windows desktop** (`ADR-001`). Phase 1 (`Local`) is a single-device offline edition; Phase 2 (`Connect`) delivers the shared multi-user calendar across phones and PCs. |
| **Algerian Wilaya Reference Data** | Warns **not** to hard-code 58 Wilayas (`§8.5`: divisions changed 48→58 and may change again). | Recommends seeding from current official list (`§15.2`). | **Error:** Hard-codes `1..58 (58 Algerian Wilayas)` in `VENUES` schema (`§8.1`), seeders (`§7.3`), and search (`§15.3`). | **Support the 69-Wilaya structure** (`ADR-005`) via data-driven `wilayas` and `communes` tables seeded from a versioned official JORADP/ONS dataset (`'01'`..`'69'`). Never hard-code `<= 58`. |
| **Booking Requests vs. Reservations** | **Separate entities:** `booking_requests` (public intake) vs. `reservations` (operational). Approval atomically creates a `reservation`. | **Separate entities:** `booking_requests` vs. `reservations` (`ADR-011`, `I-2`). | **Combined in one table:** Stores public inquiries inside `reservations` with `status = 'pending_owner_approval'`. | **Separate `booking_requests` from `reservations`** (`ADR-006`). Prevents unverified web inquiries from blocking slots or polluting CRM/reservation ledgers. |
| **`pending_sync` Semantics** | **Client-side overlay** derived from unacknowledged `outbox_ops`; never stored as a server status (`§12.1`). | **Client-side overlay** (`I-1`, `§12.2`); server statuses are `confirmed`, `cancelled`, `needs_review`. | Stored as a primary `reservations.status` column value in both SQLite and PostgreSQL (`§8.1`, `§12.1`). | **`pending_sync` is a client-side sync overlay (`has_pending_sync`)** derived from `sync_outbox` (`ADR-007`), never overwriting domain `reservations.status` (`confirmed`, `tentative`, `cancelled`, `needs_review`). |
| **Slot Granularity & Overlap Constraint** | Per-hall configurable `hall_slots` + separate `hall_allocations` table with `tstzrange` GiST exclusion and denormalized `is_blocking` flag. | Venue-defined `booking_slots` + `starts_at_local`/`ends_at_local` directly on `reservations` with `tsrange` GiST exclusion where `status = 'confirmed'`. | Fixed `slot_type` enum (`full_day`, `afternoon`, `evening`) mapped to hard-coded hours in a generated `tsrange` column on `reservations`. | **Configurable per-hall slots** (`hall_slots`, including overnight `spans_next_day`) + half-open range `[starts_at_local, ends_at_local)` directly on `reservations` with PostgreSQL `btree_gist` exclusion constraint (`ADR-008`). |
| **Financial Units & Append-Only Enforcement** | Uses `amount_minor` (centimes) and append-only ledger (`§9.2`). | Uses `amount_minor` (centimes) and append-only ledger (`§8.3`, `ADR-014`). | Uses integer DZD and append-only ledger (`§9.2`, `ADR-008`). | **Standardize on integer whole Algerian Dinars (`BIGINT` `DZD`, `*_dzd` suffix)** across all tables/DTOs/PDFs, and enforce an **unconditional `BEFORE UPDATE OR DELETE` trigger on all columns of `payments`** (`ADR-009`). |
| **Outbox Ordering & Sync Pull Cursor** | Client outbox + server `sync_changes` ordered by locked sequence row (`§11.5`, `§11.7`). | Client outbox + `sync_change_log` ordered by sequence row locked late in TX (`§11.6`, `ADR-023`). | `server_seq` stamped on domain tables without commit lock; outbox ordered by timestamp. | **Monotonic local `outbox_seq` + dependency blocking** on push; **per-venue `venue_sync_state.last_seq` locked with `SELECT ... FOR UPDATE` at commit + `permissions_hash` reset on role change** on pull (`ADR-010`, `docs/architecture.md §6`). |
| **Local-to-Connect Migration** | **Staged upload** (`migration_staging_records`) → server validation → single-TX commit → client finalize. | **Staged upload** → validate → promote → verify → activate (`§13.3`). | **Direct live upsert** (`INSERT ... ON CONFLICT DO UPDATE` into live tables) and mutates local SQLite IDs *before* upload (`§13.1`, `§13.3`). | **Staged, non-destructive migration including `contract_templates` and `generated_documents` binaries verified by `sha256_checksum`** (`ADR-011`, `docs/architecture.md §7`). |
| **Framework & Package Compatibility** | Laravel 12.x, PHP 8.4+, Filament v4, PostgreSQL 17/18. | Current supported Laravel, PostgreSQL, Filament (versions unpinned). | Laravel 11/12 + **Filament v3** + Livewire 3 + PostgreSQL 16/17. | **Evidence-based matrix verified via Composer dry-run** (`ADR-002`, `docs/architecture.md §2.2`): Track 1 (`PHP 8.4 + Laravel 13.x + Filament v5.x + Livewire v4.x + Tailwind v4.1+`, recommended for Phase 2) and Track 2 (`Laravel 12.x + Filament v4.x + Livewire v3.x`). |

---

## 3. Requirements Coverage, Gaps & Contradictions

### 3.1 Requirements Properly Covered Across Drafts
- **WalimApp Local offline autonomy:** 100% offline single-device operation using local SQLCipher/SQLite via Drift, no LAN sync, no mandatory cloud telemetry or heartbeat (`REQ-LOC-01`..`23`).
- **Perpetual Local licensing:** Ed25519-signed offline `.walimlic` files where update entitlement compares `APP_BUILD_DATE <= updates_until` rather than the wall clock, and checks entitlement *before* running SQLite schema migrations (`REQ-LOC-22`..`23`).
- **Immutable financial ledger:** Append-only `payments` with explicit `refund` / `adjustment` entries (`parent_payment_id` + mandatory `reason`), eliminating silent edits and sync lost-update bugs (`REQ-LOC-12`..`13`).
- **Server-side multi-tenancy & RBAC:** Explicit tenant scoping derived from authenticated membership (never request payload), venue-scoped employee permissions (`venue_memberships`), and Filament Super-Admin with append-only `audit_logs` (`REQ-CON-01`..`05`, `REQ-ADM-01`..`07`).
- **Public marketplace & advertising:** Server-rendered Blade + Tailwind CSS + Alpine.js with `/ar` (RTL) and `/fr` (LTR) routes, Schema.org JSON-LD, privacy-safe availability projection, WhatsApp click-to-chat (`wa.me`), staff-curated initial provider directory, and admin ad placements (`REQ-MKT-01`..`11`).
- **360° Virtual Tours deferred to Phase 4:** Equirectangular panoramas with lazy-loaded WebGL viewer (`Pannellum`), explicitly decoupled from Phases 1–3 (`REQ-PH4-01`).

### 3.2 Missing or Contradicted Requirements Identified & Resolved

1. **Contradiction — 69 Wilayas vs. 58 Wilayas:**
   - **Requirement:** Support Algeria's **69-Wilaya structure** (`REQ-LOC-04`, `REQ-MKT-02`).
   - **Draft Contradiction:** `architecture-gemini-argon.md` hard-coded `58 Algerian Wilayas` (`1..58`).
   - **Correction:** `wilayas` (`code VARCHAR(2)` `'01'`..`'69'`) and `communes` are seeded from a versioned, checksummed dataset verified against official Algerian *Journal Officiel (JORADP)* / ONS listings covering all **69 official Algerian Wilayas** and 1,541 communes (`ADR-005`).
2. **Gap — Shared Flutter Codebase for Android Smartphones & Windows Desktop + Edition Positioning:**
   - **Requirement:** One shared Flutter codebase targeting both **Android smartphones** and **Windows desktop**, plus shared multi-user calendar in Connect (`NFR-02`, `REQ-CON-01`..`02`).
   - **Draft Gap:** All three drafts targeted Windows desktop only in Phase 1.
   - **Correction:** Elevated Android (`API 24+`) and Windows (`x64`) to co-equal targets in `apps/owner` (`ADR-001`), while explicitly positioning **Phase 1 (`WalimApp Local`) as a single-device offline edition** and **Phase 2 (`WalimApp Connect`) as the release that delivers the shared multi-user synchronized calendar across phones and PCs** (`docs/product-requirements.md §1.1`, `docs/roadmap.md §1`).
3. **Contradiction — `booking_requests` vs. `reservations` Table Separation:**
   - **Requirement:** Booking requests must be distinct from actual reservations (`REQ-MKT-07`..`10`).
   - **Draft Contradiction:** `architecture-gemini-argon.md` stored public requests inside `reservations` (`status = 'pending_owner_approval'`).
   - **Correction:** Separate `booking_requests` table; owner approval executes an atomic PostgreSQL transaction validating slot availability via `btree_gist`, creating/linking the `customer`, and inserting a `confirmed` `reservation` (`ADR-006`).
4. **Contradiction — Money Units (Centimes vs. Whole DZD):**
   - **Draft Contradiction:** Opus and Sonnet proposed `amount_minor` (centimes), whereas Argon and Algerian wedding hall practice use whole Algerian Dinars (`DZD`). Mixing the two risks 100x calculation bugs.
   - **Correction:** Standardized every table, DTO, checksum, and PDF across all documents on **integer whole Algerian Dinars (`BIGINT` `DZD`, column suffix `*_dzd`)** (`ADR-009`).
5. **Contradiction — Connect Subscription Expiry & Renewal Reconciliation:**
   - **Draft Contradiction:** Opus proposed locking local editing on Connect expiry unless the customer also bought a perpetual Local license; Sonnet and Argon preserved local offline access and editing while pausing cloud sync and public marketplace features.
   - **Correction:** In `expired_local_fallback` (after the grace period in `DEC-09`), cloud sync and public marketplace booking requests pause while local offline access remains 100% functional. Local edits made during expiry queue in `sync_outbox` (`outbox_seq`) and reconcile through the conflict-safe sync pipeline upon subscription renewal (`docs/architecture.md §8.2`).

---

## 4. Technical Errors & Security Gaps Resolved

### 4.1 Truncated Specification in `architecture-opus.md`
- `architecture-opus.md` terminates mid-sentence at line 1909 (`### 16.5 Backup of media`), omitting `§17`–`§23`. All missing security, backup, testing, ADR, and open-question sections were reconstructed and cross-checked against `architecture-sonnet.md` and `architecture-gemini-argon.md`.

### 4.2 Unsafe In-Place Migration & Missing Document Verification
- `architecture-gemini-argon.md` (`§13.1`, `§13.3`) mutated local SQLite `organization_id`/`venue_id` before upload and upserted directly into live PostgreSQL tables. Furthermore, the initial migration list omitted contract templates and generated PDF binaries.
- **Correction (`ADR-011`, `docs/architecture.md §7`):** Staged migration uploads all 11 entity types (including `contract_templates` and `generated_documents` metadata) to `migration_staging_records`, uploads PDF/media binaries to staging S3/R2 verified by `sha256_checksum` and `byte_size`, validates counts/FKs/overlaps/financial checksums in a dry-run transaction, and promotes atomically before switching the client to Connect mode.

### 4.3 Evidence-Based Framework, Database & Crypto Validation
1. **Composer Dependency Solver Evidence (`docs/architecture.md §2.2`):**
   - Executed `composer update --dry-run` (with `platform.php = 8.4.0`) against Packagist metadata on 2026-10-29:
     - **Track 1 (Recommended for Phase 2):** `laravel/framework` `v13.39.0` (security support through `2028-03-17`) + `filament/filament` `v5.11.0` + `livewire/livewire` `v4.4.8` + `laravel/sanctum` `v4.3.3` + `Tailwind CSS v4.1+` resolves cleanly (`110 installs, 0 conflicts`).
     - **Track 2 (Fallback):** `laravel/framework` `v12.70.2` (security support ends `2027-02-24`) + `filament/filament` `v4.16.0` + `livewire/livewire` `v3.8.11` + `laravel/sanctum` `v4.3.3` also resolves cleanly (`110 installs, 0 conflicts`).
   - Rejected `architecture-gemini-argon.md`'s incompatible pairing of Laravel 12 with Filament v3.
2. **Client-Side UUIDv7 (`ADR-004`):** Generated in application code (`uuid` in Dart, `Ramsey\Uuid` in PHP) so PostgreSQL 17 is fully supported without requiring PostgreSQL 18's server-only `uuidv7()`.
3. **SQLCipher Encryption at Rest & Separated Backup Keys (`ADR-003`, `DEC-06`):**
   - Live client SQLite databases use `sqlcipher_flutter_libs` (`AES-256` encryption at rest) with keys stored in `Android Keystore` / `Windows DPAPI`.
   - `.walimbak` backups use an independent random 256-bit DEK (`AES-256-GCM`) wrapped by a user passphrase (`Argon2id`) and/or printable 256-bit Recovery Key—**never derived from the license key** (`DEC-06`).
4. **Phase 1 Offline License Issuance (`ADR-012`):** Added `tools/license-issuer` (standalone operator CLI with externalized Ed25519 private key and `issued-licenses.jsonl` ledger) so Phase 1 perpetual licenses can be issued and transferred securely before Phase 2's Filament backend exists.
5. **Unconditional `payments` Immutability Trigger (`ADR-009`):** Database triggers (`BEFORE UPDATE OR DELETE ON payments`) reject **all** `UPDATE` and `DELETE` operations on every column of `payments`.

### 4.4 Sync Ordering, Cursor Serialization & Role-Filter Safety
- **Monotonic Local Outbox (`docs/architecture.md §6.1`):** Replaced timestamp ordering (`created_at`) with `outbox_seq INTEGER PRIMARY KEY AUTOINCREMENT` and parent-before-child dependency blocking (`depends_on_outbox_seq`).
- **Commit-Serialized Venue Cursor (`docs/architecture.md §6.2`):** Server delta pulls use per-venue `venue_sync_state.last_seq` locked via `SELECT ... FOR UPDATE` immediately before commit, plus `permissions_hash` cursor reset on role upgrade/downgrade and `is_financial_masked` protection on masked reservation rows.

---

## 5. Overengineering Risks Cut for a Solo Developer

| Proposed in One or More Drafts | Why It Was Cut | Consolidated Baseline Rule |
| :--- | :--- | :--- |
| **Separate `change_journal` AND `outbox_ops` AND `reservation_status_history` on the client** (Opus `§11.3`) | Writing three separate audit/outbox tables on every local SQLite mutation duplicates storage and code. | Keep `reservation_status_history` (business audit) and `sync_outbox` (`outbox_seq`). |
| **Multi-resolution cubemap tile pyramids (`libvips` 8K tiling) for initial Virtual Tours** (Opus `§16.4`, Sonnet `§16.6`, Argon `§16.3`) | Building custom cubemap tile-slicing pipelines adds heavy media worker complexity. | In Phase 4 MVP, use optimized equirectangular WebP images on S3/R2 with click-to-load `Pannellum` (`ADR-015`). |
| **Full randomized chaos sync simulator before shipping Phase 2** (Sonnet `§19.5`) | Writing a custom network simulator from scratch takes weeks of engineering. | Write deterministic **scenario integration tests** covering slot conflicts, idempotent replay, `outbox_seq` dependency blocking, `permissions_hash` reset, and commit-serialized delta pulls against real PostgreSQL 17. |
| **Separate `hall_allocations` table + nightly drift detector** (Opus `§9.5`) | Extra join and denormalized `is_blocking` drift risk. | Store `hall_id`, `slot_id`, `starts_at_local`, `ends_at_local` directly on `reservations` guarded by PostgreSQL's partial `EXCLUDE USING gist` constraint (`ADR-008`). |

---

## 6. Impact of the Shared Android + Windows Flutter Requirement

### 6.1 Architectural Adjustments Incorporated
1. **Single Flutter Application (`apps/owner`):**
   - Shares ~90% of code (`core/`, `database/`, `features/`, `l10n/`) across Android (`API 24+`) and Windows (`x64`).
   - Uses `AdaptiveShell` (`< 600dp` touch-first phone UI with bottom navigation and bottom sheets; `>= 600dp` / `>= 1024px` desktop `NavigationRail`, split views, and keyboard shortcuts).
2. **Five Resilient Platform Adapters (`lib/platform/`, `docs/architecture.md §4.3`):**
   - `DeviceIdentityProvider`: Persistent random Installation UUID stored in `SecureCredentialStore` + salted hash of `MachineGuid` (Windows) or `Settings.Secure.ANDROID_ID` (Android, with software-keystore fallback on low-cost devices).
   - `SecureCredentialStore`: Windows DPAPI Credential Manager vs. Android Keystore (`EncryptedSharedPreferences`) storing the SQLCipher key and auth tokens.
   - `BackupStorageAdapter`: WAL-safe `VACUUM INTO` snapshot + `PRAGMA integrity_check` + `AES-256-GCM` encryption, executed deterministically in the foreground with a 7-day off-device export reminder banner (never relying solely on `AppLifecycleState.paused`).
   - `DocumentOutputAdapter`: Windows native print/save vs. Android Print Spooler and WhatsApp PDF share sheet.
   - `AppInstanceGuard`: Windows named mutex vs. Android single-task launch mode.
3. **Clear Phase 1 vs. Phase 2 Multi-Device Boundary:**
   - **Phase 1 (`WalimApp Local`)** runs on a single Android phone OR a single Windows PC offline.
   - **Phase 2 (`WalimApp Connect`)** links multiple individually authenticated users on multiple Android phones and Windows PCs into a shared, synchronized venue calendar.

---

## 7. Traceability Matrix (Requirements & Drafts → Canonical Baseline)

| Trace ID | Requirement / Topic | PRD Ref (`docs/product-requirements.md`) | Opus Ref | Sonnet Ref | Argon Ref | Canonical Resolution & Target Document |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`TR-01`** | Four product components & two-codebase + issuer CLI topology | `§1`, `§2.1`–`§2.4` | `§1`, `§4` | `§1`, `§4` | `§1`, `§4` | Shared Flutter app (`apps/owner`) + Phase 1 offline `tools/license-issuer` CLI + Phase 2 Laravel modular monolith (`docs/architecture.md §1, §3`, `ADR-002`). |
| **`TR-02`** | Shared Android & Windows Flutter codebase + single-device Local vs. multi-device Connect | `§1.1`, `NFR-02`, `REQ-CON-01`..`02` | `§5.5` (Win only) | `§5.2.4` (Win only) | `§5.2.D` (Win only) | Unified Flutter codebase with `< 600dp` / `>= 600dp` adaptive shell and 5 platform adapters (`docs/architecture.md §4`, `docs/roadmap.md §1`, `ADR-001`). |
| **`TR-03`** | Local 100% offline independence & SQLCipher encryption at rest | `REQ-LOC-01`..`23`, `NFR-03`, `NFR-04` | `§2.1`, `§5.6` | `§4.4`, `§5.2.5` | `§3.1`, `§11.1` | Drift + `sqlcipher_flutter_libs` (`WAL`, `AES-256`); zero runtime cloud dependency in Local mode (`docs/architecture.md §2.1, §10.2`, `ADR-003`). |
| **`TR-04`** | Perpetual Local license, Phase 1 offline issuer CLI & Connect expiry safety | `REQ-LOC-22`..`23`, `REQ-CON-10`, `REQ-ADM-02` | `§14.1`–`14.6` | `§14.2`, `§14.4`, `ADR-015` | `§14.1`–`14.2`, `ADR-007` | Ed25519 `.walimlic` signed by `tools/license-issuer` in Phase 1; `APP_BUILD_DATE <= updates_until`; Connect expiry falls back to local offline mode and reconciles outbox on renewal (`docs/architecture.md §8`, `ADR-012`, `DEC-09`). |
| **`TR-05`** | Client UUIDv7 identity & non-destructive staged migration (including documents) | `REQ-CON-11`..`13` | `§9.1`, `§13` | `§8.4`, `§13` | Contradicted (`§13.1`) | App-generated UUIDv7s; staged upload of 11 entity types + `generated_documents` binaries verified by `sha256_checksum` → dry-run validation → atomic promotion (`docs/architecture.md §2.1, §7`, `ADR-004`, `ADR-011`). |
| **`TR-06`** | Strict separation of `booking_requests` from `reservations` | `REQ-MKT-07`..`11` | `§8.3`, `§12.1` | `§3.4 I-2`, `§12.2` | Contradicted (`§8.1`) | Separate `booking_requests` table; owner approval atomically creates/links `customer` and inserts a `confirmed` `reservation` (`docs/architecture.md §5.3`, `ADR-006`). |
| **`TR-07`** | Orthogonal `pending_sync` client overlay vs. domain reservation status | `REQ-LOC-06`, `REQ-CON-07` | `§12.1`–`12.5` | `§3.4 I-1`, `§12.4` | Contradicted (`§8.1`) | `reservations.status` holds only `confirmed`, `tentative`, `cancelled`, `needs_review`; `has_pending_sync` is derived from `sync_outbox` (`docs/architecture.md §5.3`, `ADR-007`). |
| **`TR-08`** | Configurable hall booking slots & PostgreSQL `btree_gist` exclusion | `REQ-LOC-02`, `REQ-LOC-07`, `REQ-CON-08` | `§8.2`, `§9.5` | `§8.2`, `§9.2` | Contradicted (`§9.3`) | Per-hall `hall_slots` (including `spans_next_day`) + `[starts_at_local, ends_at_local)` on `reservations` with `EXCLUDE USING gist` (`docs/architecture.md §5.2, §5.3`, `ADR-008`). |
| **`TR-09`** | Monotonic `outbox_seq` push, per-venue commit-locked cursor & `permissions_hash` reset | `REQ-CON-04`, `REQ-CON-06`, `REQ-CON-08` | `§11.3`–`11.9` | `§11.4`–`11.8` | `§11.2`–`11.5` | Local `outbox_seq` + dependency blocking; server `sync_processed_operations` idempotency + `venue_sync_state.last_seq` locked with `FOR UPDATE` at commit + `permissions_hash` cursor reset (`docs/architecture.md §6`, `ADR-010`). |
| **`TR-10`** | Canonical integer whole-DZD money (`*_dzd BIGINT`) & unconditionally append-only `payments` | `REQ-LOC-12`..`16`, `NFR-01` | `§9.2` (centimes) | `§8.3` (centimes) | `§9.2` (whole DZD) | Whole Algerian Dinars (`BIGINT` `DZD`, `*_dzd` suffix); `BEFORE UPDATE OR DELETE ON payments` trigger rejects all updates/deletes on every column (`docs/architecture.md §5.2, §5.4`, `ADR-009`). |
| **`TR-11`** | Individual user accounts, venue-scoped RBAC, offline lease TTL & audited Super-Admin | `REQ-CON-01`..`05`, `REQ-ADM-01`..`07` | `§10.4`–`10.5` | `§10.4`, `§17.2` | `§10.4`, `§17.1` | Per-user/per-device Sanctum tokens, `venue_memberships`, 72h staff `OfflineAccessLease`, reconnection purge on revocation, zero PII in push pokes, append-only `audit_logs` (`docs/architecture.md §5.2, §10.1`, `ADR-013`). |
| **`TR-12`** | Authoritative 69-Wilaya reference data & bilingual `ar-DZ`/`fr-DZ` with Western digits | `REQ-LOC-04`, `REQ-MKT-01`..`02`, `NFR-01` | `§8.5`, `§15.5` | `§15.2`, `§15.11` | Contradicted (`58`) | Versioned official 69-Wilaya & 1,541-commune seed; Arabic RTL & French LTR with Western digits (`0-9`) (`docs/architecture.md §5.1`, `ADR-005`, `ADR-014`). |
| **`TR-13`** | Public marketplace SSR, privacy-safe availability & ad placements | `REQ-MKT-01`..`06`, `REQ-ADM-06` | `§15.1`–`15.7` | `§15.1`–`15.9` | `§15.1`–`15.5` | Laravel Blade + Tailwind CSS + Alpine.js SSR; zero-PII availability projection; Wilaya/category ad slots (`docs/architecture.md §9`, `ADR-002`). |
| **`TR-14`** | Phase 4 isolation for 360° virtual tours & provider self-service | `REQ-PH4-01`..`03` | `§16.4` | `§16.6` | `§16.3` | Deferred to Phase 4; static equirectangular panoramas on S3/R2 with click-to-load `Pannellum` viewer (`docs/architecture.md §9`, `ADR-015`, `DEC-15`, `DEC-16`). |
| **`TR-15`** | Algerian Law 18-07 / 25-11 privacy safeguards, ANPDP legal gate & WAL-safe `.walimbak` backups | `REQ-LOC-10`, `REQ-LOC-20`..`21`, `NFR-04`, `NFR-06` | `§9.8`, `§16.5` | `§17.3`, `§18.2` | `§17.6`, `§18.5` | Optional NIN/CNI, explicit consent, independent `.walimbak` DEK/KEK encryption (`DEC-06`), WAL-safe `VACUUM INTO` backups, and ANPDP legal counsel review gate before production (`docs/architecture.md §10.2, §10.3`, `DEC-10`). |
