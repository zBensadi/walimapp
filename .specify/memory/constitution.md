<!--
Sync Impact Report (WalimApp Constitution v1.1.0 — Phase 0 Post-Audit Revision)
- Version change: 1.0.0 -> 1.1.0 (Phase 0 independent audit refinements)
- Modified Principles & Sections:
  - I. Data Safety & Financial Ledger Immutability: Clarified unconditional UPDATE/DELETE prohibition on all columns of `payments`, integer whole-DZD (`*_dzd BIGINT`) standard, WAL-safe `VACUUM INTO` backups with independent DEK/KEK encryption (never derived from license keys), and full document/template preservation in staged migration.
  - II. Genuine Local Independence & Perpetual Ownership: Clarified that WalimApp Local is a single-device offline edition, and Phase 1 includes a secure offline operator CLI (`tools/license-issuer`) for signing `.walimlic` files outside the client repo.
  - III. Shared Android & Windows Offline-First Client: Clarified that shared multi-user/multi-device calendar synchronization across phones and PCs is delivered by WalimApp Connect (Phase 2) atop the Phase 1 shared codebase foundation.
  - IV. Server-Enforced Authorization, Tenant Isolation & Booking Integrity: Added monotonic local `outbox_seq`, per-venue serialized `venue_sync_state` cursor, permission-hash cursor reset on role change, and realistic offline revocation bounds (Offline Access Lease TTL + wipe on next reconnection).
  - Architectural & Domain Constraints: Updated stack baseline with verified Composer compatibility matrix (Laravel 12/Filament v4 vs. Laravel 13/Filament v5 evaluated at Phase 2 gate; current Flutter stable 3.44+/3.47+ pinned at Phase 1 start), SQLCipher encryption at rest, and ANPDP legal review gate.
-->

# WalimApp Constitution

## Core Principles

### I. Data Safety & Financial Ledger Immutability (NON-NEGOTIABLE)

Customer records, confirmed reservations, contracts, generated documents, and financial history MUST never be silently overwritten, lost, or duplicated during local usage, backup restoration, Local-to-Connect migration, or multi-device synchronization.

- **Canonical Integer Whole-DZD Money**: All monetary values across SQLite, PostgreSQL, DTOs, checksums, and PDFs MUST be stored and calculated as integer **whole Algerian Dinars (`BIGINT` `DZD`, column suffix `*_dzd`)**. Floating-point types (`FLOAT`, `DOUBLE`) and mixed centime/whole-Dinar representations are strictly forbidden.
- **Unconditionally Append-Only Financial Ledger**: Recorded `payments` rows are completely immutable. Database triggers (`BEFORE UPDATE OR DELETE ON payments`) in both SQLite and PostgreSQL MUST reject **all** `UPDATE` and `DELETE` operations on **every column** of `payments`. Corrections to any field (amount, method, date, or note) MUST be recorded by inserting a new `refund` or `adjustment` row referencing `parent_payment_id` with a mandatory `reason` and actor attribution.
- **Idempotent & Causally Ordered Sync**: Every mutating synchronization operation MUST carry a client-generated `operation_id` (UUIDv7), be ordered locally by a strictly monotonic `outbox_seq` (never client wall-clock timestamps), enforce parent-before-child dependency blocking, and be deduplicated by the server before execution.
- **Non-Destructive Staged Migration (Data + Documents)**: Local-to-Connect migration MUST upload a complete snapshot (including `contract_templates`, `generated_documents` metadata, and binary PDF/media files verified by SHA-256 checksum) to server staging tables/storage, validate entity counts, foreign-key integrity, slot overlaps, and per-reservation financial checksums on the server, and promote in a single database transaction before the local client marks the venue as migrated.
- **WAL-Safe Verified Backups with Independent Keys**: Local backups (`.walimbak`) MUST be created from a consistent SQLite snapshot (`VACUUM INTO`) and verified (`PRAGMA integrity_check`) before replacing the active database (preserving a `.pre_restore` copy). Backup encryption keys (DEK/KEK) MUST be cryptographically independent of license keys (`DEC-06`).

**Rationale**: Wedding venues manage high-value events and installment deposits in Algerian Dinar (`DZD`). Silent financial drift, partial updates, or lost reservation/contract records destroy owner trust and create severe legal and financial liability.

### II. Genuine Local Independence & Perpetual Ownership (NON-NEGOTIABLE)

**WalimApp Local** is a **single-device offline edition** that MUST operate indefinitely on an Android smartphone or a Windows desktop PC using local SQLite storage without requiring internet connectivity, cloud accounts, central servers, or LAN synchronization.

- **No Network Dependency in Local Mode**: Core single-device venue management workflows (calendar, reservations, customers, payments, expenses, Arabic/French PDF contracts and receipts, and local backups) MUST execute 100% offline against local SQLCipher/Drift tables.
- **Perpetual License Integrity**: Expiry of an optional annual maintenance/update window (`updates_until`) MUST NEVER disable, degrade, watermark, or lock any feature of a purchased and activated WalimApp Local version, nor restrict access to local data.
- **Secure Offline License Issuance**: Private Ed25519 signing keys MUST NEVER be placed in the Flutter client or repository. Phase 1 licenses are signed offline via a dedicated operator tool (`tools/license-issuer`) using an externalized private key and recorded in an operator ledger prior to Phase 2 Super-Admin import.
- **Honest Single-Device Local Semantics**: Local-only installations are independent single-device systems and MUST NOT claim multi-device or multi-user calendar synchronization without upgrading to WalimApp Connect.

**Rationale**: Many Algerian wedding halls operate in environments with intermittent connectivity or prefer perpetual single-device software ownership, while multi-device teams require Connect's server-arbitrated synchronization.

### III. Shared Android & Windows Offline-First Client

WalimApp MUST use a single shared Flutter codebase (`apps/owner`) targeting both Android smartphones and Windows desktops across both the Local (single-device) and Connect (multi-device synced) editions.

- **Single Owner Codebase**: Domain models, value objects, Drift/SQLCipher repositories, synchronization outbox logic, authentication, permissions, and reservation/financial use cases MUST be shared across Android and Windows. Creating separate mobile and desktop codebases or duplicating business rules is forbidden.
- **Adaptive UX by Form Factor**: Presentations MUST adapt via responsive layout breakpoints (`< 600dp` touch-first phone layout with bottom navigation and bottom sheets on Android; `>= 600dp` / `>= 1024px` desktop layout with `NavigationRail`, master-detail split panes, and keyboard shortcuts on Windows).
- **Thin Platform Adapters**: Platform-specific differences (device identity, secure credential storage, backup file picking, PDF printing/sharing, single-instance lock) MUST be isolated behind narrow adapter interfaces (`lib/platform/`).

**Rationale**: Algerian venue owners and managers frequently work from Android smartphones on-site while reception or accounting staff use Windows PCs at the office. A single codebase eliminates double maintenance for a solo developer.

### IV. Server-Enforced Authorization, Tenant Isolation & Booking Integrity (NON-NEGOTIABLE)

Client UI checks are convenience only; the Laravel backend and PostgreSQL database are the ultimate authority for multi-tenant isolation, role permissions, and central booking conflicts.

- **Strict Tenant Isolation**: Every tenant-owned table in PostgreSQL MUST carry `organization_id` (and `venue_id` where venue-scoped). Every API query, sync delta pull, and mutation MUST enforce organization and venue membership on the server.
- **Venue-Scoped Multi-User Access & Safe Sync Filtering**: In WalimApp Connect, each employee or manager authenticates with an individual user account on their own authorized device and receives a venue-scoped role (`owner`, `manager`, `receptionist`, `accountant`, `viewer`). Financial totals and sensitive actions MUST be filtered server-side. Role changes MUST trigger a `permissions_hash` cursor reset/re-sync so upgraded users receive historical financial data and downgraded/revoked users purge restricted cached records upon reconnection.
- **Separation of Booking Requests and Reservations**: Public marketplace inquiries MUST be stored in `booking_requests` (`pending`, `approved`, `rejected`, `expired`, `cancelled_by_requester`) and MUST NEVER be inserted directly into `reservations` or block slots until an authorized owner/manager explicitly approves them.
- **Database-Level Double-Booking Prevention**: Confirmed and tentative reservations MUST be protected against double-booking at the PostgreSQL engine level using a `btree_gist` exclusion constraint on `(hall_id, tsrange(starts_at_local, ends_at_local, '[)'))`.
- **Distinct Client Sync State**: Unsynchronized local edits MUST be represented as a client-side `pending_sync` overlay derived from `sync_outbox`, never conflated with the domain reservation `status`.

**Rationale**: Multi-user mobile/desktop sync and public marketplace requests introduce race conditions that only server-side authorization, commit-serialized sequence cursors, and database-level exclusion constraints can safely arbitrate.

### V. Testable Requirements & Automated Verification

Every functional and non-functional requirement MUST be phrased so it can be verified by an automated test or a deterministic acceptance check.

- **Mandatory Coverage of Critical Invariants**: Automated tests MUST cover slot-overlap detection (including overnight slots crossing midnight), `booking_requests` approval races, unconditional append-only payment trigger enforcement on all columns, idempotent `operation_id` replay, monotonic `outbox_seq` dependency ordering, permission-change cursor reset, Local-to-Connect staged migration validation (including document checksums), tenant isolation boundaries, and Ed25519 license verification.
- **Bilingual & Formatting Verification**: User-facing features and PDF documents MUST be tested in both Arabic (`ar-DZ`, RTL) and French (`fr-DZ`, LTR), enforcing Western Arabic numerals (`0-9`) and integer whole Dinar (`DZD` / `د.ج`) formatting.

**Rationale**: An AI-assisted solo developer relies on deterministic automated tests to prevent regressions across phases.

### VI. Human Review Gates & Incremental Phased Delivery (NON-NEGOTIABLE)

Development proceeds strictly feature-by-feature and phase-by-phase with mandatory Product Owner review gates.

- **No Unattended Stage Jumping**: Generating a specification, clarification, plan, or task list MUST NEVER automatically trigger code implementation. The agent MUST stop at designated review gates (`spec.md` approval and `plan.md`/`tasks.md` approval) and wait for explicit Product Owner sign-off.
- **Decision Gates Scoped to Dependent Slices**: Unresolved product decisions (`DEC-*`) MUST be resolved before specifying or implementing the specific sprint slice that depends on them, without artificially blocking unrelated earlier foundation work.
- **Respect Delivery Phase Boundaries**:
  - **Phase 1**: **WalimApp Local MVP** — single-device offline edition on the shared Android + Windows Flutter codebase, plus offline operator license-signing CLI.
  - **Phase 2**: **WalimApp Connect** — central backend, shared multi-user/multi-device synchronized calendar across Android phones and Windows PCs, venue-scoped permissions, and staged Local-to-Connect migration.
  - **Phase 3**: **Public Marketplace & Online Booking Requests** — SSR marketplace (`ar-DZ` / `fr-DZ`, 69 Wilayas) and owner-approved online booking requests.
  - **Phase 4**: **Expansion** — self-serve advertising expansion, provider self-service portal, and 360° virtual tours.
- **Deferred Feature Discipline**: Phase 4 features (360° virtual tours, provider self-registration) MUST NOT delay or complicate Phases 1–3.

**Rationale**: Review gates with the Product Owner prevent architectural drift and wasted implementation effort.

### VII. Solo-Developer Operational Simplicity

Every architectural and infrastructure choice MUST be justifiable for a single developer maintaining the system in production.

- **Single Deployable Backend**: The central backend MUST be a single Laravel modular monolith backed by PostgreSQL 17 and Filament. Microservices, Kubernetes, separate Node.js SSR servers, Event Sourcing / CQRS frameworks, and custom CRDT engines are strictly forbidden.
- **No Unnecessary Infrastructure**: Database-backed queues, cache, and locks in PostgreSQL are the default; Redis or external search clusters MUST NOT be introduced without a demonstrated production bottleneck.
- **Clean-Slate Codebase**: Do not import or reuse third-party application repositories. Use only well-maintained, license-compatible framework and utility packages verified via lockfile resolution.

**Rationale**: Operational complexity is the primary failure mode for solo-developer SaaS and desktop/mobile products.

## Architectural & Domain Constraints

- **Stack Baseline & Version Governance**:
  - **Owner App (Local & Connect)**: Current stable Flutter SDK (`3.44+` / `3.47+`, Dart `3.12+` / `3.13+`, pinned in `pubspec.lock` at Phase 1 Sprint 1.1 start), targeting Android (`API 24+`) and Windows Desktop (`x64`), with local encrypted SQLite via `drift` + `sqlcipher_flutter_libs`.
  - **Central Backend & Admin (Phase 2)**: PHP 8.4 + Laravel modular monolith, PostgreSQL 17 (`btree_gist`, `pg_trgm`), Filament for Super-Admin, and server-side-rendered Laravel Blade + Tailwind CSS + Alpine.js for the public SEO marketplace. Both **Track 1 (`Laravel 13.x + Filament v5.x + Livewire v4.x + Tailwind v4.1+`, recommended for longer security support through March 2028)** and **Track 2 (`Laravel 12.x + Filament v4.x + Livewire v3.x`, security support through Feb 2027)** are verified via Composer dry-run resolution and finalized at the Phase 2 Sprint 2.1 planning gate (see [`docs/architecture.md`](../../docs/architecture.md)).
- **Algeria 69-Wilaya Reference Standard**: Location tables (`wilayas`, `communes`) MUST be data-driven and seeded from an authoritative, versioned official dataset covering all **69 official Algerian Wilayas** with bilingual Arabic and French names and URL slugs. Hard-coding `1..58` constraints is forbidden.
- **Algerian Data Protection Compliance (Law 18-07 & Law 25-11)**: Technical privacy capabilities (consent recording, SQLCipher/TLS encryption, optional NIN/CNI minimization, erasure/anonymization tools) MUST be built in, while formal legal compliance, ANPDP declaration, and production hosting jurisdiction (`DEC-10`) are gated on review by qualified Algerian legal counsel before production launch.

## Spec-Driven Development Workflow & Quality Gates

Every feature slice after Phase 0 MUST follow the 11-step Spec Kit workflow exposed by the Antigravity (`agy`) integration (detailed in [`docs/ai-development-workflow.md`](../../docs/ai-development-workflow.md)):

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

This Constitution is the supreme technical and process governance document for WalimApp. In the event of a conflict between this Constitution and any feature specification, plan, task list, or historical architecture draft under [`reference/architecture-drafts/`](../../reference/architecture-drafts/), this Constitution and the canonical files under [`docs/`](../../docs/) prevail.

- **Amendment Procedure**: Any amendment to this Constitution requires an explicit proposal documenting the rationale, impact on existing phases, and updated [`docs/decision-register.md`](../../docs/decision-register.md) entry, followed by explicit Product Owner approval.
- **Versioning Policy**: `CONSTITUTION_VERSION` follows Semantic Versioning (`MAJOR.MINOR.PATCH`):
  - `MAJOR`: Removal or backward-incompatible redefinition of a core principle or governance gate.
  - `MINOR`: Addition of a new principle, architectural constraint, or mandatory workflow gate.
  - `PATCH`: Wording clarifications, formatting improvements, or non-semantic refinements.
- **Compliance Review**: Every `/speckit-plan`, `/speckit-analyze`, and pull request review MUST explicitly verify compliance with Principles I–VII. Any proposed deviation MUST be rejected unless the Constitution is formally amended first.

**Version**: 1.1.0 | **Ratified**: 2026-10-29 | **Last Amended**: 2026-10-29
