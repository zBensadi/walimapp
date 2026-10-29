<!--
Sync Impact Report (WalimApp Constitution v1.0.0)
- Version change: template -> 1.0.0 (initial ratification)
- Added Principles:
  - I. Data Safety & Financial Ledger Immutability (NON-NEGOTIABLE)
  - II. Genuine Local Independence & Perpetual Ownership (NON-NEGOTIABLE)
  - III. Shared Android & Windows Offline-First Client
  - IV. Server-Enforced Authorization, Tenant Isolation & Booking Integrity (NON-NEGOTIABLE)
  - V. Testable Requirements & Automated Verification
  - VI. Human Review Gates & Incremental Phased Delivery (NON-NEGOTIABLE)
  - VII. Solo-Developer Operational Simplicity
- Added Sections:
  - Architectural & Domain Constraints
  - Spec-Driven Development Workflow & Quality Gates
  - Governance
- Follow-up TODOs: None (all template placeholders resolved; open product questions tracked in docs/decision-register.md).
-->

# WalimApp Constitution

## Core Principles

### I. Data Safety & Financial Ledger Immutability (NON-NEGOTIABLE)

Customer records, confirmed reservations, contracts, and financial history MUST never be silently overwritten, lost, or duplicated during local usage, backup restoration, Local-to-Connect migration, or multi-device synchronization.

- **Append-Only Financial Ledger**: Confirmed `payments` rows are immutable. Editing or deleting a recorded payment row in SQLite or PostgreSQL is strictly forbidden; corrections MUST be recorded as explicit `refund` or `adjustment` entries referencing `parent_payment_id` with a mandatory `reason`.
- **Idempotent Sync**: Every mutating synchronization operation MUST carry a client-generated `operation_id` (UUIDv7) and be deduplicated by the server before execution.
- **Non-Destructive Staged Migration**: Local-to-Connect migration MUST upload an immutable snapshot to server staging tables, validate foreign-key integrity, slot overlaps, and per-reservation financial checksums on the server, and commit in a single database transaction before the local client marks the venue as migrated.
- **Verified Backups**: Encrypted local backups (`.walimbak`) MUST be verified inside a temporary SQLite file (`PRAGMA integrity_check`) before replacing the active database, which MUST first be preserved as a `.pre_restore` safety copy.

**Rationale**: Wedding venues manage high-value events and cash/installment deposits in Algerian Dinar (`DZD`). Silent financial drift or lost reservation records destroy owner trust and create severe legal and financial liability.

### II. Genuine Local Independence & Perpetual Ownership (NON-NEGOTIABLE)

**WalimApp Local** MUST operate indefinitely on both Android smartphones and Windows desktops using local SQLite storage without requiring internet connectivity, cloud accounts, central servers, or LAN synchronization.

- **No Network Dependency in Local Mode**: Core venue management workflows (calendar, reservations, customers, payments, expenses, Arabic/French PDF contracts and receipts, and local backups) MUST execute 100% offline against local Drift/SQLite tables.
- **Perpetual License Integrity**: Expiry of an optional annual maintenance/update window (`updates_until`) MUST NEVER disable, degrade, watermark, or lock any feature of a purchased and activated WalimApp Local version, nor restrict access to local data.
- **Honest Local Semantics**: Local-only installations are single-device systems and MUST NOT claim multi-device synchronization without an active WalimApp Connect subscription.

**Rationale**: Many Algerian wedding halls operate in environments with intermittent connectivity or prefer perpetual software ownership without mandatory recurring cloud fees.

### III. Shared Android & Windows Offline-First Client

WalimApp MUST use a single shared Flutter codebase (`apps/owner`) targeting both Android smartphones and Windows desktops.

- **Single Owner Codebase**: Domain models, value objects, Drift/SQLite repositories, synchronization outbox logic, authentication, permissions, and reservation/financial use cases MUST be shared across Android and Windows. Creating separate mobile and desktop codebases or duplicating business rules is forbidden.
- **Adaptive UX by Form Factor**: Presentations MUST adapt via responsive layout breakpoints (`< 600dp` touch-first phone layout with bottom navigation and bottom sheets on Android; `>= 600dp` / `>= 1024px` desktop layout with `NavigationRail`, master-detail split panes, and keyboard shortcuts on Windows).
- **Thin Platform Adapters**: Platform-specific differences (device identity, secure credential storage, backup file picking, PDF printing/sharing, single-instance lock) MUST be isolated behind narrow adapter interfaces.

**Rationale**: Algerian venue owners and managers frequently work from Android smartphones on-site while reception or accounting staff use Windows PCs at the office. A single codebase eliminates double maintenance for a solo developer.

### IV. Server-Enforced Authorization, Tenant Isolation & Booking Integrity (NON-NEGOTIABLE)

Client UI checks are convenience only; the Laravel backend and PostgreSQL database are the ultimate authority for multi-tenant isolation, role permissions, and central booking conflicts.

- **Strict Tenant Isolation**: Every tenant-owned table in PostgreSQL MUST carry `organization_id` (and `venue_id` where venue-scoped). Every API query, sync delta pull, and mutation MUST enforce organization and venue membership on the server.
- **Venue-Scoped Multi-User Access**: In WalimApp Connect, each employee or manager authenticates with an individual user account on their own authorized device and receives a venue-scoped role (`owner`, `manager`, `receptionist`, `accountant`, `viewer`). Financial totals and sensitive actions MUST be filtered server-side and excluded from unauthorized sync payloads.
- **Separation of Booking Requests and Reservations**: Public marketplace inquiries MUST be stored in `booking_requests` (`pending`, `approved`, `rejected`, `expired`, `cancelled_by_requester`) and MUST NEVER be inserted directly into `reservations` or block slots until an authorized owner/manager explicitly approves them.
- **Database-Level Double-Booking Prevention**: Confirmed and tentative reservations MUST be protected against double-booking at the PostgreSQL engine level using a `btree_gist` exclusion constraint on `(hall_id, tsrange(starts_at_local, ends_at_local, '[)'))`.
- **Distinct Client Sync State**: Unsynchronized local edits MUST be represented as a client-side `pending_sync` overlay derived from `sync_outbox`, never conflated with the domain reservation `status`.

**Rationale**: Multi-user mobile/desktop sync and public marketplace requests introduce race conditions that only server-side authorization and database-level constraints can safely arbitrate.

### V. Testable Requirements & Automated Verification

Every functional and non-functional requirement MUST be phrased so it can be verified by an automated test or a deterministic acceptance check.

- **Mandatory Coverage of Critical Invariants**: Automated tests MUST cover slot-overlap detection (including overnight slots crossing midnight), `booking_requests` approval races, append-only payment ledger rules, idempotent `operation_id` replay, Local-to-Connect staged migration validation, tenant isolation boundaries, and Ed25519 license verification.
- **Bilingual & Formatting Verification**: User-facing features and PDF documents MUST be tested in both Arabic (`ar-DZ`, RTL) and French (`fr-DZ`, LTR), enforcing Western Arabic numerals (`0-9`) and integer Dinar (`DZD` / `د.ج`) formatting.

**Rationale**: An AI-assisted solo developer relies on deterministic automated tests to prevent regressions across phases.

### VI. Human Review Gates & Incremental Phased Delivery (NON-NEGOTIABLE)

Development proceeds strictly feature-by-feature and phase-by-phase with mandatory Product Owner review gates.

- **No Unattended Stage Jumping**: Generating a specification, clarification, plan, or task list MUST NEVER automatically trigger code implementation. The agent MUST stop at designated review gates (`spec.md` approval and `plan.md`/`tasks.md` approval) and wait for explicit Product Owner sign-off.
- **Respect Delivery Phase Boundaries**:
  - **Phase 1**: WalimApp Local MVP (shared Android + Windows codebase).
  - **Phase 2**: WalimApp Connect backend, multi-user/multi-device sync, permissions, and Local-to-Connect migration.
  - **Phase 3**: Public SSR marketplace (`ar-DZ` / `fr-DZ`, 69 Wilayas) and owner-approved online booking requests.
  - **Phase 4**: Self-serve advertising expansion, provider self-service portal, and 360° virtual tours.
- **Deferred Feature Discipline**: Phase 4 features (360° virtual tours, provider self-registration) MUST NOT delay or complicate Phases 1–3.

**Rationale**: Review gates with the Product Owner prevent architectural drift and wasted implementation effort.

### VII. Solo-Developer Operational Simplicity

Every architectural and infrastructure choice MUST be justifiable for a single developer maintaining the system in production.

- **Single Deployable Backend**: The central backend MUST be a single Laravel 12 modular monolith backed by PostgreSQL 17 and Filament v4. Microservices, Kubernetes, separate Node.js SSR servers, Event Sourcing / CQRS frameworks, and custom CRDT engines are strictly forbidden.
- **No Unnecessary Infrastructure**: Database-backed queues, cache, and locks in PostgreSQL are the default; Redis or external search clusters MUST NOT be introduced without a demonstrated production bottleneck.
- **Clean-Slate Codebase**: Do not import or reuse third-party application repositories. Use only well-maintained, license-compatible framework and utility packages.

**Rationale**: Operational complexity is the primary failure mode for solo-developer SaaS and desktop/mobile products.

## Architectural & Domain Constraints

- **Stack Baseline**:
  - **Owner App (Local & Connect)**: Flutter (stable 3.27+) + Dart 3.6+, targeting Android (API 24+) and Windows Desktop (x64), with local SQLite via `drift` + `sqlite3_flutter_libs`.
  - **Central Backend & Admin**: PHP 8.4 + Laravel 12.x modular monolith, PostgreSQL 17 (`btree_gist`, `pg_trgm`), Filament v4.x (Livewire 3) for Super-Admin, and server-side-rendered Laravel Blade + Tailwind CSS + Alpine.js for the public SEO marketplace.
- **Algeria 69-Wilaya Reference Standard**: Location tables (`wilayas`, `communes`) MUST be data-driven and seeded with all **69 official Algerian Wilayas** (including the 2019 and late-2025 administrative expansions) with bilingual Arabic and French names and URL slugs. Hard-coding `1..58` constraints is forbidden.
- **Algerian Data Protection Compliance**: Personal data handling MUST comply with Algerian Law **18-07** and Law **25-11** (ANPDP notification, explicit consent on public forms, data minimization, encryption at rest and in transit, and cross-border transfer evaluation before selecting non-Algerian production hosting).

## Spec-Driven Development Workflow & Quality Gates

Every feature slice after Phase 0 MUST follow the 11-step Spec Kit workflow exposed by the Antigravity (`agy`) integration:

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

This Constitution is the supreme technical and process governance document for WalimApp. In the event of a conflict between this Constitution and any feature specification, plan, task list, or historical architecture draft under `reference/architecture-drafts/`, this Constitution and the canonical files under `docs/` prevail.

- **Amendment Procedure**: Any amendment to this Constitution requires an explicit proposal documenting the rationale, impact on existing phases, and updated `docs/decision-register.md` entry, followed by explicit Product Owner approval.
- **Versioning Policy**: `CONSTITUTION_VERSION` follows Semantic Versioning (`MAJOR.MINOR.PATCH`):
  - `MAJOR`: Removal or backward-incompatible redefinition of a core principle or governance gate.
  - `MINOR`: Addition of a new principle, architectural constraint, or mandatory workflow gate.
  - `PATCH`: Wording clarifications, formatting improvements, or non-semantic refinements.
- **Compliance Review**: Every `/speckit-plan`, `/speckit-analyze`, and pull request review MUST explicitly verify compliance with Principles I–VII. Any proposed deviation MUST be rejected unless the Constitution is formally amended first.

**Version**: 1.0.0 | **Ratified**: 2026-10-29 | **Last Amended**: 2026-10-29
