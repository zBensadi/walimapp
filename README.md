# WalimApp (وليمة آب)

**WalimApp** is an Algeria-first wedding venue (*Salle des Fêtes* / قاعة الحفلات) management platform and bilingual public wedding marketplace.

It combines an **offline-first owner & staff application** for **Android smartphones and Windows desktops** (built from a single shared Flutter codebase) with a **central Laravel + PostgreSQL 17 + Filament modular monolith** powering multi-device synchronization, Super-Admin operations, and a server-side-rendered (SSR) Arabic/French public marketplace across all **69 Algerian Wilayas**.

---

## 1. Product Components & Edition Positioning

| Component | Description | Primary Stack | Delivery Phase |
| :--- | :--- | :--- | :--- |
| **1. WalimApp Local** | **Single-device offline perpetual edition** for **Android smartphones** or **Windows desktops** (shared Flutter codebase, zero cross-device sharing). Manages halls, configurable booking slots, customer contracts, unconditionally append-only installment payments (integer whole `DZD`), expenses, bilingual PDF receipts/contracts, and WAL-safe encrypted `.walimbak` local backups. Includes a standalone offline operator CLI (`tools/license-issuer`) for Phase 1 Ed25519 `.walimlic` signing. | Flutter (current stable), Drift / SQLCipher (`AES-256` at rest), Ed25519 offline licensing | **Phase 1** |
| **2. WalimApp Connect** | **Shared multi-user, multi-device edition** inside the **same Android & Windows Flutter codebase**. Delivers the **shared synchronized reservation calendar** across multiple individually authenticated users on Android phones and Windows PCs, venue-scoped employee permissions, online booking request inbox, and non-destructive staged Local-to-Connect migration (preserving data, contract templates, and generated PDFs). | Shared Flutter App + PHP 8.4 / Laravel Sync API (`Sanctum`) + PostgreSQL 17 (`btree_gist`) | **Phase 2** |
| **3. Public Marketplace** | Mobile-responsive, SEO-friendly **Arabic (`ar-DZ`, RTL)** and **French (`fr-DZ`, LTR)** website covering all **69 Algerian Wilayas**, with capacity/price/service filters, privacy-safe slot availability, owner-approved online `booking_requests`, WhatsApp contact, and a wedding service provider directory. | Laravel Blade SSR + Tailwind CSS + Alpine.js + PostgreSQL 17 | **Phase 3** *(360° tours & provider self-service in Phase 4)* |
| **4. Super-Admin** | Back-office for managing organizations, owners, perpetual `.walimlic` licenses (including import of the Phase 1 operator ledger), Connect subscriptions, marketplace moderation, curated/self-serve providers, advertising placements, and immutable audit logs. | Filament (Livewire) | **Phases 2–4** |

---

## 2. Canonical Documentation Index

Start here to navigate the project baseline established and audited in **Phase 0**:

| Document | Purpose |
| :--- | :--- |
| **[`AGENTS.md`](./AGENTS.md)** | Persistent guardrails, source-of-truth hierarchy, and workflow rules for AI coding agents. |
| **[`.specify/memory/constitution.md`](./.specify/memory/constitution.md)** | **Project Constitution (`v1.1.0`):** Non-negotiable principles (data safety & whole-DZD append-only ledger, genuine single-device Local independence, shared Android/Windows codebase, server-enforced authorization & booking constraints, testable requirements, human review gates, solo-developer simplicity). |
| **[`docs/product-requirements.md`](./docs/product-requirements.md)** | **Canonical Product Requirements (`v1.1`):** Functional (`REQ-*`) and non-functional (`NFR-*`) requirements organized by component and delivery phase (Phases 1–4). |
| **[`docs/architecture.md`](./docs/architecture.md)** | **Consolidated Architecture Baseline (`v1.1`):** System boundaries, Composer-verified tech stack matrix, shared Android/Windows adaptive design & platform adapters, 69-Wilaya model, `booking_requests` vs `reservations` separation, `btree_gist` exclusion constraint, monotonic `outbox_seq` sync & commit-locked venue cursor, staged migration with document verification, offline licensing CLI, and Law 18-07/25-11 privacy safeguards. |
| **[`docs/architecture-review.md`](./docs/architecture-review.md)** | **Architecture Review & Traceability (`v1.1`):** Detailed comparison of the 3 initial architecture drafts (`Opus`, `Sonnet`, `Gemini Argon`), contradictions resolved, technical fixes, solo-dev simplifications, and regenerated traceability matrix (`TR-01`..`TR-15`). |
| **[`docs/decision-register.md`](./docs/decision-register.md)** | **Decision Register (`v1.1`):** Confirmed architectural decisions (`ADR-001`..`ADR-015`) and unresolved product-owner questions (`DEC-01`..`DEC-16`) with slice-scoped resolution gates and redesigned backup-key recovery options (`DEC-06`). |
| **[`docs/roadmap.md`](./docs/roadmap.md)** | **Delivery Roadmap (`v1.1`):** Phases 0–4, candidate sprints, single-device Local (Phase 1) vs. shared multi-user Connect calendar (Phase 2) positioning, slice-scoped dependencies, and measurable acceptance gates. |
| **[`docs/ai-development-workflow.md`](./docs/ai-development-workflow.md)** | **AI & Spec Kit Workflow (`v1.1`):** How we execute the 11-step Spec Kit lifecycle (`/speckit-specify` through `/speckit-converge`), Product Owner + ChatGPT review gates, pause-and-audit protocol, testing, and Git conventions. |
| **[`docs/walimapp-phase0-audit.md`](./docs/walimapp-phase0-audit.md)** | **Phase 0 Independent Audit Report:** The independent review findings (`P0-1`..`P0-7`, `P1-1`..`P1-8`, `P2-1`..`P2-6`) addressed in the `v1.1` baseline. |

---

## 3. Repository Layout

```text
walimapp/
├── .agents/skills/                  # Spec Kit Antigravity (agy) skills (/speckit-*)
├── .github/                         # Issue and Pull Request templates
├── .specify/                        # Spec Kit configuration, scripts, templates & constitution
│   └── memory/constitution.md       # Project Constitution v1.1.0
├── docs/                            # Canonical project baseline documentation
│   ├── architecture.md
│   ├── architecture-review.md
│   ├── decision-register.md
│   ├── product-requirements.md
│   ├── roadmap.md
│   ├── ai-development-workflow.md
│   └── walimapp-phase0-audit.md
├── reference/
│   └── architecture-drafts/         # Preserved original drafts (read-only historical reference)
│       ├── architecture-opus.md
│       ├── architecture-sonnet.md
│       ├── architecture-gemini-argon.md
│       └── product-requirements-initial.md
├── AGENTS.md                        # Persistent AI coding agent instructions
└── README.md                        # Project overview and documentation index
```

*(Note: `apps/owner` and `tools/license-issuer` will be created in Phase 1, and `backend` in Phase 2, after Phase 0 review and Spec Kit planning approval.)*

---

## 4. Working Method (Spec-Driven Development)

This project uses **GitHub Spec Kit** (`specify-cli`) integrated with **Google Antigravity (`agy`)**. Every feature slice follows an 11-step gated workflow (see [`docs/ai-development-workflow.md`](./docs/ai-development-workflow.md)):

1. `/speckit-specify` → 2. `/speckit-clarify` → **3. Product Owner Review Gate 1**
4. `/speckit-plan` → 5. `/speckit-checklist` → 6. `/speckit-tasks` → 7. `/speckit-analyze` → **8. Product Owner Review Gate 2**
9. `/speckit-implement` → 10. Automated Tests & `/speckit-converge` → 11. Audit, Verification & Git Commit.

---

## 5. License & Confidentiality

**Proprietary & Confidential.** All rights reserved. This repository must remain **private** at all times.
