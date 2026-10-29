<!--
Sync Impact Report (WalimApp Constitution v1.3.0-draft — Phase 0.3 Revision)
- Version change: 1.2.0-draft -> 1.3.0-draft (Incorporates Phase 0.3 confirmed trilingual requirement, Connect subscription & device-limit rules, and explicit sqlite3mc cipher configuration/verification)
- Modified Principles & Sections:
  - II. Genuine Local Independence & Perpetual Ownership: Updated Local workflows to trilingual (`ar-DZ`, `fr-DZ`, `en`).
  - IV. Server-Enforced Authorization, Tenant Isolation & Booking Integrity: Added Connect subscription tier rules (`1` active device Basic vs. `up to 5` active devices Higher-Capacity), Super-Admin configurability, strict separation of `max_active_devices` from mandatory individual user accounts (`venue_memberships`), device replacement/revocation, and snapshotted `agreed_price_dzd` protection.
  - V. Testable Requirements & Automated Verification: Updated to trilingual (`ar-DZ` RTL, `fr-DZ` LTR, `en` LTR) and added the mandatory pre-feature Sprint 1.1 Android + Windows `sqlite3mc` cipher proof-of-technology test across debug, profile, and release builds.
  - Architectural & Domain Constraints: Corrected `sqlite3mc` cipher specification (`chacha20` ChaCha20-Poly1305 256-bit AEAD explicitly configured via `PRAGMA cipher = 'chacha20'; PRAGMA legacy = 0;` BEFORE `PRAGMA key` and verified across debug/profile/release builds) and updated localization to trilingual (`ar-DZ`, `fr-DZ`, `en`) with optional per-language content and deterministic fallback.
-->

# WalimApp Constitution (Draft — Pending Product Owner Ratification)

## Core Principles

### I. Data Safety & Financial Ledger Immutability (NON-NEGOTIABLE)

Customer records, confirmed reservations, contracts, generated documents, and financial history MUST never be silently overwritten, lost, or duplicated during local usage, backup restoration, Local-to-Connect migration, or multi-device synchronization.

- **Canonical Integer Whole-DZD Money**: All monetary values across SQLite, PostgreSQL, DTOs, checksums, and PDFs MUST be stored and calculated as integer **whole Algerian Dinars (`BIGINT` `DZD`, column suffix `*_dzd`)**. Floating-point types (`FLOAT`, `DOUBLE`) and mixed centime/whole-Dinar representations are strictly forbidden.
- **Unconditionally Append-Only Financial Ledger & Actor Attribution**: Recorded `payments` rows are completely immutable. Database triggers (`BEFORE UPDATE OR DELETE ON payments`) in both SQLite and PostgreSQL MUST reject **all** `UPDATE` and `DELETE` operations on **every column** of `payments`. Corrections to any field (amount, method, date, or note) MUST be recorded by inserting a new `refund` or `adjustment` row referencing `parent_payment_id` with a mandatory `reason` and persistent actor attribution (`recorded_by_actor_name` + `recorded_by_local_actor_id` in Local mode, plus `recorded_by_user_id` in Connect mode).
- **Idempotent, Authorized & Causally Ordered Sync**: Every mutating synchronization operation MUST carry a client-generated `operation_id` (UUIDv7) and `payload_sha256`, be ordered locally by a strictly monotonic `outbox_seq` (never client wall-clock timestamps), enforce parent-before-child dependency blocking (and binary-before-metadata upload for generated PDFs/logos), and verify current caller authentication and venue authorization on the server *before* returning any deduplicated idempotency result.
- **Non-Destructive Staged Migration (Relational Data + Content-Addressed Assets)**: Local-to-Connect migration MUST upload all relational entities (including `local_actors`, `contract_templates`, and `generated_documents` metadata) to server staging tables and upload all binary assets (`generated_documents` PDFs and `venue_logo`) to content-addressed object storage (`sha256_checksum`) *before* executing an atomic PostgreSQL promotion transaction with idempotent lost-response recovery.
- **WAL-Safe Streaming Backups with Independent Keys**: Local backups (`.walimbak`) MUST be created from a consistent SQLite snapshot (`VACUUM INTO`), verified (`PRAGMA integrity_check`), and encrypted via 64 KiB chunked streaming `AES-256-GCM` before replacing any active database (preserving a `.pre_restore` copy). Backup encryption keys (DEK/KEK) MUST be cryptographically independent of license keys (`DEC-06`).

**Rationale**: Wedding venues manage high-value events and installment deposits in Algerian Dinar (`DZD`). Silent financial drift, partial updates, or lost reservation/contract records destroy owner trust and create severe legal and financial liability.

### II. Genuine Local Independence & Perpetual Ownership (NON-NEGOTIABLE)

**WalimApp Local** is a **single-device offline edition** that MUST operate indefinitely on an Android smartphone or a Windows desktop PC using local encrypted SQLite storage without requiring internet connectivity, cloud accounts, central servers, or LAN synchronization.

- **No Network Dependency in Local Mode**: Core single-device venue management workflows (calendar, reservations, customers, payments, expenses, trilingual Arabic/French/English PDF contracts and receipts, and local backups) MUST execute 100% offline against local encrypted Drift/SQLite tables.
- **Perpetual License Integrity**: Expiry of an optional annual maintenance/update window (`updates_until`) MUST NEVER disable, degrade, watermark, or lock any feature of a purchased and activated WalimApp Local version, nor restrict access to local data.
- **Secure Offline License Issuance (`LicenseSigner`)**: Private Ed25519 signing keys MUST NEVER be placed in the Flutter client or repository. Standalone offline license signing (`tools/license-issuer`) MUST use a `LicenseSigner` abstraction that supports non-exportable hardware/OS-keystore signing operations as well as encrypted offline key vaults, recording every issued or transferred license in an operator ledger (`issued-licenses.jsonl`).
- **One Physical Venue with Unlimited Halls by Default**: A WalimApp Local license covers 1 physical venue with multiple bookable halls/spaces and imposes no arbitrary hall cap in the database schema (`max_halls` in `.walimlic` is nullable/unlimited unless a commercial tier explicitly sets it).
- **Honest Single-Device Local Semantics**: Local-only installations are independent single-device systems and MUST NOT claim multi-device or multi-user calendar synchronization without upgrading to WalimApp Connect.

**Rationale**: Many Algerian wedding halls operate in environments with intermittent connectivity or prefer perpetual single-device software ownership, while multi-device teams require Connect's server-arbitrated synchronization.

### III. Shared Android & Windows Offline-First Client

WalimApp MUST use a single shared Flutter codebase (`apps/owner`) targeting both Android smartphones and Windows desktops across both the Local (single-device) and Connect (multi-device synced) editions.

- **Single Owner Codebase**: Domain models, value objects, Drift/SQLite repositories, synchronization outbox logic, authentication, permissions, and reservation/financial use cases MUST be shared across Android and Windows. Creating separate mobile and desktop codebases or duplicating business rules is forbidden.
- **Adaptive UX by Form Factor**: Presentations MUST adapt via responsive layout breakpoints (`< 600dp` touch-first phone layout with bottom navigation and bottom sheets on Android; `>= 600dp` / `>= 1024px` desktop layout with `NavigationRail`, master-detail split panes, and keyboard shortcuts on Windows).
- **Thin Platform Adapters**: Platform-specific differences (device identity, OS-protected credential storage, backup file picking, PDF printing/sharing, single-instance lock) MUST be isolated behind narrow adapter interfaces (`lib/platform/`).

**Rationale**: Algerian venue owners and managers frequently work from Android smartphones on-site while reception or accounting staff use Windows PCs at the office. A single codebase eliminates double maintenance for a solo developer.

### IV. Server-Enforced Authorization, Tenant Isolation & Booking Integrity (NON-NEGOTIABLE)

Client UI checks are convenience only; the Laravel backend and PostgreSQL database are the ultimate authority for multi-tenant isolation, role permissions, subscription device limits, and central booking conflicts.

- **Strict Tenant Isolation**: Every tenant-owned table in PostgreSQL MUST carry `organization_id` (and `venue_id` where venue-scoped). Every API query, sync delta pull, idempotency replay, and mutation MUST enforce active organization and venue membership on the server.
- **Configurable Connect Device Tiers, Mandatory Individual Accounts & Grandfathered Pricing**:
  - WalimApp Connect supports Super-Admin-configurable subscription plans (starting with **Basic: `1` active device** and **Higher-Capacity: up to `5` active devices** at a higher price, with configurable plan names, whole-DZD prices, billing intervals, `max_active_devices`, `max_venues`, and optional `max_users`).
  - **Active Device Limit != User-Seat Limit**: Individual user accounts (`users`) and venue-scoped role-based permissions (`venue_memberships`: `owner`, `manager`, `receptionist`, `accountant`, `viewer`) are **always mandatory**, even on a 1-device Basic plan (where multiple staff members may sign in with their own accounts on the same registered device).
  - **Device Replacement/Revocation & Price Protection**: Owners and Super-Admins can revoke or replace a lost/retired device (`device_registrations`) to register a replacement within the active device limit. Active subscriptions snapshot `agreed_price_dzd`, billing interval, and entitlement limits so Super-Admin edits to plan templates never silently alter agreed prices on existing subscriptions.
- **Safe Sync Filtering & Per-Venue Crypto-Erasure**:
  - Financial totals and `payments`/`expenses` rows MUST be filtered server-side for non-financial roles (`is_financial_masked = true`), while the server strips/ignores masked financial columns on incoming non-financial reservation edits so legitimate operational updates (e.g., `guest_count`, `notes`) succeed.
  - Because `payments` rows are protected by an unconditional `BEFORE UPDATE OR DELETE` trigger, local cache purging upon membership/device revocation or role downgrade MUST operate by closing and cryptographically erasing/replacing the per-venue local database file (`venues/<venue_id>.db` + its `SecureCredentialStore` key) rather than issuing SQL `DELETE` statements against `payments`.
- **Separation of Booking Requests and Reservations**: Public marketplace inquiries MUST be stored in `booking_requests` (`pending`, `approved`, `rejected`, `expired`, `cancelled_by_requester`) and MUST NEVER be inserted directly into `reservations` or block slots until an authorized owner/manager explicitly approves them.
- **Database-Level Double-Booking Prevention**: Confirmed and tentative reservations MUST be protected against double-booking at the PostgreSQL engine level using a `btree_gist` exclusion constraint on `(hall_id, tsrange(starts_at_local, ends_at_local, '[)'))`.
- **Distinct Client Sync State**: Unsynchronized local edits MUST be represented as a client-side `pending_sync` overlay derived from `sync_outbox`, never conflated with the domain reservation `status`.

**Rationale**: Multi-user mobile/desktop sync and public marketplace requests introduce race conditions that only server-side authorization, commit-serialized sequence cursors, and database-level exclusion constraints can safely arbitrate.

### V. Testable Requirements & Automated Verification

Every functional and non-functional requirement MUST be phrased so it can be verified by an automated test or a deterministic acceptance check.

- **Mandatory Coverage of Critical Invariants**: Automated tests MUST cover explicit `sqlite3mc` cipher configuration and verification (`chacha20` verified before/after key application across debug, profile, and release builds, preceded by an Android + Windows proof-of-technology test in Sprint 1.1 before building domain features), slot-overlap detection (including overnight slots crossing midnight), `booking_requests` approval races, unconditional append-only payment trigger enforcement on all columns, auth-first idempotent `operation_id` + `payload_sha256` replay, monotonic `outbox_seq` dependency ordering, `scanned_through_seq` filtered cursor advancement, per-venue DB crypto-erasure on role downgrade/revocation, Connect `max_active_devices` enforcement and device replacement, Local-to-Connect staged migration validation (including content-addressed binary checksums and lost-response commit retry), tenant isolation boundaries, and Ed25519 license verification.
- **Trilingual & Formatting Verification**: User-facing features and PDF documents MUST be tested across **Arabic (`ar-DZ`, RTL, including an early Arabic shaping proof-of-technology)**, **French (`fr-DZ`, LTR)**, and **English (`en`, LTR)**, enforcing Western Arabic numerals (`0-9`), integer whole Dinar (`DZD` / `د.ج`) formatting, and deterministic per-language content fallback (`en -> fr -> ar`, `fr -> ar -> en`, `ar -> fr -> en`).

**Rationale**: An AI-assisted solo developer relies on deterministic automated tests to prevent regressions across phases.

### VI. Human Review Gates & Incremental Phased Delivery (NON-NEGOTIABLE)

Development proceeds strictly feature-by-feature and stage-by-stage with mandatory Product Owner review gates.

- **No Unattended Stage Jumping**: Generating a specification, clarification, plan, or task list MUST NEVER automatically trigger code implementation. The agent MUST stop at designated review gates (`spec.md` approval and `plan.md`/`tasks.md` approval) and wait for explicit Product Owner sign-off.
- **Decision Gates Scoped to Dependent Slices**: Unresolved product decisions (`DEC-*`) MUST be resolved before specifying or implementing the specific sprint slice that depends on them, without artificially blocking unrelated earlier foundation work.
- **Value-First Interleaved Delivery Stages (`DEC-01`)**:
  - **Stage 1A (Phase 1 Core Foundation & Single-Device Pilot — Sprints 1.1–1.3)**: Shared Android + Windows Flutter codebase, encrypted Drift/SQLite (`sqlite3mc` with explicit `chacha20` cipher PoT), 69-Wilaya seed, halls/slots/calendar, append-only `payments` ledger, and trilingual (`ar-DZ`, `fr-DZ`, `en`) UI & PDF contracts/receipts (delivering a single-device Android pilot).
  - **Stage 2A (Phase 2 Connect Shared Multi-User Calendar — Sprints 2.1–2.3)**: Central Laravel + PostgreSQL 17 + Filament backend (trilingual `ar`/`fr`/`en`), configurable Connect device plans (`1` active device Basic vs. `up to 5` active devices Higher-Capacity), individual user auth, venue-scoped RBAC, and multi-device sync across Android phones and Windows PCs (delivering the first commercial multi-user shared calendar release).
  - **Stage 1B (Phase 1 Local Commercial Productization — Sprint 1.4)**: Desktop split-view polish, streaming `.walimbak` backups (`DEC-06`), and `.walimlic` offline licensing (`tools/license-issuer` / Admin signer).
  - **Stage 2B (Phase 2 Staged Migration & Subscription Expiry — Sprint 2.4)**: Non-destructive Local-to-Connect migration (relational + content-addressed binary assets) and Connect expiry/renewal reconciliation.
  - **Phase 3**: **Public Marketplace & Online Booking Requests** (trilingual `ar-DZ` / `fr-DZ` / `en` SSR across 69 Wilayas with optional per-language listing content and fallback).
  - **Phase 4**: **Expansion** (self-serve advertising, provider self-service portal, and 360° virtual tours).
- **Deferred Feature Discipline**: Phase 4 features (360° virtual tours, provider self-registration) MUST NOT delay or complicate earlier stages.

**Rationale**: Interleaving the Connect shared-calendar slice immediately after the offline core foundation delivers the high-value multi-phone family/team calendar early while preserving 100% shared code and review discipline.

### VII. Solo-Developer Operational Simplicity

Every architectural and infrastructure choice MUST be justifiable for a single developer maintaining the system in production.

- **Single Deployable Backend**: The central backend MUST be a single Laravel modular monolith backed by PostgreSQL 17 and Filament. Microservices, Kubernetes, separate Node.js SSR servers, Event Sourcing / CQRS frameworks, and custom CRDT engines are strictly forbidden.
- **No Unnecessary Infrastructure**: Database-backed queues, cache, and locks in PostgreSQL are the default; Redis or external search clusters MUST NOT be introduced without a demonstrated production bottleneck.
- **Clean-Slate Codebase**: Do not import or reuse third-party application repositories. Use only well-maintained, license-compatible framework and utility packages verified via lockfile resolution.

**Rationale**: Operational complexity is the primary failure mode for solo-developer SaaS and desktop/mobile products.

## Architectural & Domain Constraints

- **Stack Baseline & Version Governance**:
  - **Owner App (Local & Connect)**: Current stable Flutter SDK (`3.44+` / `3.47+`, Dart `3.12+` / `3.13+`, pinned in `pubspec.lock` at Sprint 1.1 start), targeting Android (`API 24+`) and Windows Desktop (`x64`), with local encrypted SQLite via `drift` (`^2.35.0`) + `sqlite3` (`^3.8.0`) configured with Dart Native Assets build hooks (`hooks.user_defines.sqlite3.source: sqlite3mc` — SQLite3MultipleCiphers). Because `sqlite3mc`'s documented default cipher is `ChaCha20-Poly1305` (`chacha20`) rather than AES-256, the database setup callback MUST explicitly configure `PRAGMA cipher = 'chacha20'; PRAGMA legacy = 0;` **before** applying `PRAGMA key`, and MUST verify in `debug`, `profile`, and `release` builds that `SELECT sqlite3mc_config('cipher');` / `PRAGMA cipher;` equals `'chacha20'` (failing closed with a `StateError` otherwise), validated by a mandatory Android + Windows proof-of-technology test at the start of Sprint 1.1 before building features on top of it.
  - **Central Backend & Admin (Stage 2A+)**: PHP 8.4 + Laravel modular monolith, PostgreSQL 17 (`btree_gist`, `pg_trgm`), Filament for Super-Admin, and server-side-rendered Laravel Blade + Tailwind CSS + Alpine.js for the public SEO marketplace. Both **Track 1 (`Laravel 13.x + Filament v5.x + Livewire v4.x + Tailwind v4.1+`, recommended for longer security support through March 2028)** and **Track 2 (`Laravel 12.x + Filament v4.x + Livewire v3.x`, security support through Feb 2027)** are verified via Composer dry-run resolution and locked at the Sprint 2.1 planning gate (see [`docs/architecture.md`](../../docs/architecture.md)).
- **Trilingual Support (`ar-DZ` RTL, `fr-DZ` LTR, `en` LTR) & Algeria 69-Wilaya Standard**:
  - All three surfaces (`apps/owner`, public marketplace, and Filament Super-Admin) MUST support **Arabic (`ar-DZ`, RTL)**, **French (`fr-DZ`, LTR)**, and **English (`en`, LTR)** with Western Arabic numerals (`0-9`), per-user/venue/visitor language preferences, optional per-language venue/provider content (requiring at least one language), and deterministic fallback (`en -> fr -> ar`, `fr -> ar -> en`, `ar -> fr -> en`) isolated in `<bdi>` / `Directionality` containers.
  - Location tables (`wilayas`, `communes`) MUST be data-driven and seeded from an authoritative, versioned official dataset (verified in Sprint 1.1 before use) covering all **69 official Algerian Wilayas** and 1,541 communes with Arabic, French, and English names and URL slugs. Hard-coding `1..58` constraints is forbidden.
- **Algerian Data Protection Compliance (Law 18-07 & Law 25-11)**: Technical privacy capabilities (consent recording, `sqlite3mc`/TLS encryption, optional NIN/CNI minimization, erasure/anonymization tools) MUST be built in, while formal legal compliance, ANPDP declaration, and production hosting/processor jurisdiction (`DEC-10`, `DEC-11`) are gated on review by qualified Algerian legal counsel before production launch.

## Spec-Driven Development Workflow & Quality Gates

Every feature slice after Phase 0 approval MUST follow the 11-step Spec Kit workflow exposed by the Antigravity (`agy`) integration (detailed in [`docs/ai-development-workflow.md`](../../docs/ai-development-workflow.md)):

1. `/speckit-specify` — Draft the feature specification (`spec.md`).
2. `/speckit-clarify` — Resolve ambiguities and record clarifications.
3. **Gate 1 (Product Owner Review)** — Product Owner reviews `spec.md` (with ChatGPT review as desired); agent applies corrections and waits for explicit approval.
4. `/speckit-plan` — Produce the technical implementation plan (`plan.md`).
5. `/speckit-checklist` — Generate requirement and quality checklists.
6. `/speckit-tasks` — Decompose the plan into ordered, testable tasks (`tasks.md`).
7. `/speckit-analyze` — Run cross-artifact consistency analysis across `spec.md`, `plan.md`, `tasks.md`, and this Constitution.
8. **Gate 2 (Product Owner Review)** — Product Owner reviews and approves the plan, checklist, tasks, and analysis before any application code is written.
9. `/speckit-implement` — Execute implementation strictly scoped to the approved feature or slice.
10. **Verification & `/speckit-converge`** — Run automated tests, static analysis, code review, and `/speckit-converge` to verify task completion.
11. **Audit, Final Verification & Commit** — Perform targeted audit where warranted, resolve findings, verify clean test execution, and create an atomic Git commit.

If an architectural or security audit is needed at any step, the agent MUST pause the workflow, document the findings and proposed corrections, and resume only after Product Owner review.

## Governance

Once ratified by the Product Owner, this Constitution is the supreme technical and process governance document for WalimApp. In the event of a conflict between this Constitution and any feature specification, plan, task list, or historical architecture draft under [`reference/architecture-drafts/`](../../reference/architecture-drafts/), this Constitution and the canonical files under [`docs/`](../../docs/) prevail.

- **Ratification & Amendment Procedure**: This Constitution remains in `Draft — Pending Product Owner Ratification` status until the Product Owner explicitly approves Phase 0, at which point a ratification commit records the official `Ratified` date. Subsequent amendments require an explicit proposal documenting the rationale, impact on existing stages, and updated [`docs/decision-register.md`](../../docs/decision-register.md) entry, followed by explicit Product Owner approval.
- **Versioning Policy**: `CONSTITUTION_VERSION` follows Semantic Versioning (`MAJOR.MINOR.PATCH`):
  - `MAJOR`: Removal or backward-incompatible redefinition of a core principle or governance gate.
  - `MINOR`: Addition of a new principle, architectural constraint, or mandatory workflow gate.
  - `PATCH`: Wording clarifications, formatting improvements, or non-semantic refinements.
- **Compliance Review**: Every `/speckit-plan`, `/speckit-analyze`, and pull request review MUST explicitly verify compliance with Principles I–VII. Any proposed deviation MUST be rejected unless the Constitution is formally amended first.

**Version**: 1.3.0-draft | **Status**: Draft — Pending Product Owner Ratification | **Ratified**: Pending Product Owner Approval | **Last Amended**: 2026-10-29
