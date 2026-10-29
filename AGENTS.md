# AGENTS.md — Persistent Instructions for AI Coding Agents

Welcome to the **WalimApp** repository. You are operating as the lead software architect and implementation agent for a solo-developer project building an Algeria-first wedding venue management application and public marketplace.

**Read and obey these rules on every session before modifying any file.**

---

## 1. Source of Truth Hierarchy

When inspecting the repository, follow this strict order of authority:

1. **[`.specify/memory/constitution.md`](file:///c:/proj/walimapp/.specify/memory/constitution.md)** — Supreme governance and non-negotiable engineering principles.
2. **[`docs/product-requirements.md`](file:///c:/proj/walimapp/docs/product-requirements.md)** — Canonical functional and non-functional requirements by component and delivery phase.
3. **[`docs/architecture.md`](file:///c:/proj/walimapp/docs/architecture.md)** — Consolidated architectural baseline (shared Android/Windows Flutter client + Laravel 12/PostgreSQL 17/Filament v4 backend).
4. **[`docs/decision-register.md`](file:///c:/proj/walimapp/docs/decision-register.md)** — Confirmed ADRs (`ADR-001`..`ADR-015`) and unresolved product decisions (`DEC-01`..`DEC-16`) with provisional defaults.
5. **[`docs/roadmap.md`](file:///c:/proj/walimapp/docs/roadmap.md)** — Phase order, candidate sprints, and measurable acceptance gates.
6. **[`docs/ai-development-workflow.md`](file:///c:/proj/walimapp/docs/ai-development-workflow.md)** — Mandatory 11-step Spec Kit workflow and review gates.

> [!CAUTION]
> **Historical Drafts Warning:** The files under [`reference/architecture-drafts/`](file:///c:/proj/walimapp/reference/architecture-drafts) (`architecture-opus.md`, `architecture-sonnet.md`, `architecture-gemini-argon.md`, `product-requirements-initial.md`) are **read-only historical inputs preserved from Phase 0**.
> - **NEVER** modify, overwrite, or delete them.
> - **NEVER** copy their superseded assumptions (such as the outdated 58-Wilaya limit, storing `booking_requests` inside `reservations`, mutating SQLite IDs before migration, or pairing Laravel 12 with Filament v3). Refer to [`docs/architecture-review.md`](file:///c:/proj/walimapp/docs/architecture-review.md) for the full reconciliation record.

---

## 2. Non-Negotiable Architectural & Domain Guardrails

1. **Shared Android & Windows Flutter Codebase (`apps/owner`):**
   - Build a **single** Flutter application targeting both **Android (`API 24+`)** and **Windows (`x64`)**.
   - Share all domain models, Drift/SQLite tables, outbox sync logic, authentication, permissions, and reservation/calendar use cases.
   - Use adaptive layouts (`< 600dp` touch-first phone UI vs `>= 600dp` / `>= 1024px` desktop `NavigationRail` + split view) and isolate OS differences behind the 5 thin platform adapters in `lib/platform/`.
2. **Genuine Local Independence & Perpetual License:**
   - **WalimApp Local** must work indefinitely 100% offline using local Drift/SQLite.
   - Expiry of `updates_until` in a `.walimlic` license only prevents activating newer builds compiled after that date; it must **never** lock, degrade, or disable an activated build or user data.
   - Expiry of a **WalimApp Connect** subscription pauses cloud sync and public marketplace features while keeping offline local SQLite read/write/print functionality 100% intact.
3. **Algeria 69-Wilaya Standard:**
   - Always use the data-driven **69-Wilaya** reference structure (`wilayas.code` `'01'`..`'69'`). Never hard-code `1..58`.
4. **Bilingual `ar-DZ` (RTL) & `fr-DZ` (LTR) with Western Numerals:**
   - Support Arabic (RTL) and French (LTR) in all UI and generated PDF contracts/receipts from Day 1.
   - Always format numbers, dates, and integer `DZD` (`د.ج`) amounts using **Western Arabic digits (`0-9`)**.
5. **Booking Requests vs. Reservations:**
   - Public marketplace inquiries belong in `booking_requests` (`pending`, `approved`, `rejected`, `expired`, `cancelled_by_requester`) and **never** block slots until an owner approves them in an atomic transaction creating a `reservations` row.
   - Reservation domain statuses are `confirmed`, `tentative`, `cancelled`, and `needs_review`.
   - `pending_sync` is a **client-side sync overlay** derived from `sync_outbox`, never a replacement for the reservation's domain `status`.
   - Active reservations (`confirmed`, `tentative`) are guarded against double-booking by PostgreSQL's `btree_gist` exclusion constraint on `(hall_id, tsrange(starts_at_local, ends_at_local, '[)'))`.
6. **Immutable Financial Ledger:**
   - All monetary values are integer Algerian Dinars (`BIGINT` `DZD`). Never use `FLOAT`/`DOUBLE`.
   - Recorded `payments` rows are **append-only**. Never update or delete a payment row; require explicit `refund` or `adjustment` entries referencing `parent_payment_id` with a mandatory `reason`.
7. **Server-Side Multi-Tenant Authorization:**
   - Every Connect user authenticates individually on their own device and holds a venue-scoped role (`venue_memberships`).
   - Enforce organization, venue, and financial-visibility permissions on the Laravel server (`POST /api/v1/sync/push` and `GET /api/v1/sync/pull`), never only in the Flutter UI.
8. **Solo-Developer Operational Simplicity:**
   - Backend is a single **Laravel 12 + PHP 8.4 + PostgreSQL 17 + Filament v4 + Blade/Tailwind/Alpine SSR** modular monolith.
   - Do not introduce microservices, Kubernetes, separate Node.js SSR servers, Event Sourcing, CRDT frameworks, or mandatory Redis without explicit approval.

---

## 3. Mandatory Spec Kit Workflow & Stop Gates

Never jump straight into writing application code. For each feature slice, use the Antigravity Spec Kit skills in [`.agents/skills/`](file:///c:/proj/walimapp/.agents/skills):

1. `/speckit-specify`
2. `/speckit-clarify`
3. **STOP — Review Gate 1:** Wait for Product Owner review (with ChatGPT) and explicit approval of `spec.md`.
4. `/speckit-plan`
5. `/speckit-checklist`
6. `/speckit-tasks`
7. `/speckit-analyze`
8. **STOP — Review Gate 2:** Wait for Product Owner review and explicit approval of `plan.md`, `checklists/`, `tasks.md`, and analysis before writing code.
9. `/speckit-implement` (scoped strictly to the approved feature/slice).
10. Automated tests, static analysis, code review, and `/speckit-converge`.
11. Targeted audit (if needed), fixes, final verification, and atomic Git commit.

---

## 4. Security & Git Rules

- **Private Repository Only:** Never change the GitHub repository visibility from `private` to `public`.
- **Zero Secrets in Git:** Never commit `.env` files, Ed25519 private keys (`*.pem`, `*.key`), `.walimlic` customer licenses, `.walimbak` archives, or local SQLite `.db`/`.sqlite` files.
- **No Fabricated Verification:** Never claim a command, test, migration, commit, or push succeeded without actually executing it and inspecting its output.
