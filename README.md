# WalimApp (وليمة آب)

**WalimApp** is an Algeria-first wedding venue (*Salle des Fêtes* / قاعة الحفلات) management platform and bilingual public wedding marketplace.

It combines an **offline-first owner & staff application** for **Android smartphones and Windows desktops** (built from a single shared Flutter codebase) with a **central Laravel 12 + PostgreSQL 17 + Filament v4 modular monolith** powering multi-device synchronization, Super-Admin operations, and a server-side-rendered (SSR) Arabic/French public marketplace across all **69 Algerian Wilayas**.

---

## 1. Product Components

| Component | Description | Primary Stack | Delivery Phase |
| :--- | :--- | :--- | :--- |
| **1. WalimApp Local** | Perpetual-license, 100% offline wedding venue management app for **Android smartphones** and **Windows desktops**. Manages halls, configurable booking slots, customer contracts, append-only installment payments (`DZD`), expenses, bilingual PDF receipts/contracts, and encrypted `.walimbak` local backups. | Flutter (Dart 3.6+), Drift / SQLite (WAL), Ed25519 offline licensing | **Phase 1** |
| **2. WalimApp Connect** | Cloud-connected tier inside the **same Android & Windows Flutter codebase**. Retains offline-first SQLite operation on every device while adding multi-user / multi-device synchronization, venue-scoped employee permissions, online booking request inbox, and non-destructive Local-to-Connect migration. | Shared Flutter App + Laravel 12 Sync API (`Sanctum`) + PostgreSQL 17 (`btree_gist`) | **Phase 2** |
| **3. Public Marketplace** | Mobile-responsive, SEO-friendly **Arabic (`ar-DZ`, RTL)** and **French (`fr-DZ`, LTR)** website covering all **69 Algerian Wilayas**, with capacity/price/service filters, privacy-safe slot availability, owner-approved online `booking_requests`, WhatsApp contact, and a wedding service provider directory. | Laravel 12 Blade SSR + Tailwind CSS + Alpine.js + PostgreSQL 17 | **Phase 3** *(360° tours & provider self-service in Phase 4)* |
| **4. Super-Admin** | Back-office for managing organizations, owners, perpetual `.walimlic` licenses, Connect subscriptions, marketplace moderation, curated/self-serve providers, advertising placements, and immutable audit logs. | Filament v4 (Livewire 3) | **Phases 2–4** |

---

## 2. Canonical Documentation Index

Start here to navigate the project baseline established in **Phase 0**:

| Document | Purpose |
| :--- | :--- |
| **[`AGENTS.md`](file:///c:/proj/walimapp/AGENTS.md)** | Persistent guardrails, source-of-truth hierarchy, and workflow rules for AI coding agents. |
| **[`.specify/memory/constitution.md`](file:///c:/proj/walimapp/.specify/memory/constitution.md)** | **Project Constitution (v1.0.0):** Non-negotiable principles (data safety, genuine Local independence, shared Android/Windows codebase, server-enforced authorization & booking constraints, testable requirements, human review gates, solo-developer simplicity). |
| **[`docs/product-requirements.md`](file:///c:/proj/walimapp/docs/product-requirements.md)** | **Canonical Product Requirements:** Functional (`REQ-*`) and non-functional (`NFR-*`) requirements organized by component and delivery phase (Phases 1–4). |
| **[`docs/architecture.md`](file:///c:/proj/walimapp/docs/architecture.md)** | **Consolidated Architecture Baseline:** System boundaries, validated tech stack, shared Android/Windows adaptive design & platform adapters, 69-Wilaya model, `booking_requests` vs `reservations` separation, `btree_gist` exclusion constraint, outbox sync, staged migration, licensing, and Law 18-07/25-11 privacy. |
| **[`docs/architecture-review.md`](file:///c:/proj/walimapp/docs/architecture-review.md)** | **Architecture Review & Traceability:** Detailed comparison of the 3 initial architecture drafts (`Opus`, `Sonnet`, `Gemini Argon`), contradictions resolved, technical fixes, solo-dev simplifications, and traceability matrix (`TR-01`..`TR-15`). |
| **[`docs/decision-register.md`](file:///c:/proj/walimapp/docs/decision-register.md)** | **Decision Register:** Confirmed architectural decisions (`ADR-001`..`ADR-015`) and unresolved product-owner questions (`DEC-01`..`DEC-16`) with provisional defaults and phase deadlines. |
| **[`docs/roadmap.md`](file:///c:/proj/walimapp/docs/roadmap.md)** | **Delivery Roadmap:** Phases 0–4, candidate sprints, phone-first Android + Windows release strategy, dependencies, and measurable acceptance gates. |
| **[`docs/ai-development-workflow.md`](file:///c:/proj/walimapp/docs/ai-development-workflow.md)** | **AI & Spec Kit Workflow:** How we execute the 11-step Spec Kit lifecycle (`/speckit-specify` through `/speckit-converge`), Product Owner + ChatGPT review gates, pause-and-audit protocol, testing, and Git conventions. |

---

## 3. Repository Layout

```text
walimapp/
├── .agents/skills/                  # Spec Kit Antigravity (agy) skills (/speckit-*)
├── .github/                         # Issue and Pull Request templates
├── .specify/                        # Spec Kit configuration, scripts, templates & constitution
│   └── memory/constitution.md       # Project Constitution v1.0.0
├── docs/                            # Canonical project baseline documentation
│   ├── architecture.md
│   ├── architecture-review.md
│   ├── decision-register.md
│   ├── product-requirements.md
│   ├── roadmap.md
│   └── ai-development-workflow.md
├── reference/
│   └── architecture-drafts/         # Preserved original drafts (read-only historical reference)
│       ├── architecture-opus.md
│       ├── architecture-sonnet.md
│       ├── architecture-gemini-argon.md
│       └── product-requirements-initial.md
├── AGENTS.md                        # Persistent AI coding agent instructions
└── README.md                        # Project overview and documentation index
```

*(Note: `apps/owner` and `backend` directories will be created in Phase 1 and Phase 2 respectively after Phase 0 review and Spec Kit planning approval.)*

---

## 4. Working Method (Spec-Driven Development)

This project uses **GitHub Spec Kit** (`specify-cli`) integrated with **Google Antigravity (`agy`)**. Every feature slice follows an 11-step gated workflow (see [`docs/ai-development-workflow.md`](file:///c:/proj/walimapp/docs/ai-development-workflow.md)):

1. `/speckit-specify` → 2. `/speckit-clarify` → **3. Product Owner Review Gate 1**
4. `/speckit-plan` → 5. `/speckit-checklist` → 6. `/speckit-tasks` → 7. `/speckit-analyze` → **8. Product Owner Review Gate 2**
9. `/speckit-implement` → 10. Automated Tests & `/speckit-converge` → 11. Audit, Verification & Git Commit.

---

## 5. License & Confidentiality

**Proprietary & Confidential.** All rights reserved. This repository must remain **private** at all times.
