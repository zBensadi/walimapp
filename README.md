# WalimApp (وليمة آب)

**WalimApp** is an Algeria-first wedding venue (*Salle des Fêtes* / قاعة الحفلات) management platform and trilingual public wedding marketplace.

It combines an **offline-first owner & staff application** for **Android smartphones and Windows desktops** (built from a single shared Flutter codebase) with a **central Laravel + PostgreSQL 17 + Filament modular monolith** powering multi-device synchronization, Super-Admin operations, and a server-side-rendered (SSR) **Arabic (`ar-DZ` RTL), French (`fr-DZ` LTR), and English (`en` LTR)** public marketplace across all **69 Algerian Wilayas**.

---

## 1. Product Components & Interleaved Delivery Stages (`DEC-01`)

| Component | Description | Primary Stack | Delivery Stage (`DEC-01`) |
| :--- | :--- | :--- | :--- |
| **1. WalimApp Local** | **Single-device offline perpetual edition** for **Android smartphones** or **Windows desktops** (shared Flutter codebase, `max_venues = 1`, `"max_halls": null` unlimited halls by default, zero cross-device sharing). Manages halls, configurable booking slots, customer contracts, `local_actors` attribution, unconditionally append-only installment payments (integer whole `DZD`), expenses, trilingual (`ar-DZ` RTL, `fr-DZ` LTR, `en` LTR) PDF receipts/contracts, and WAL-safe 64 KiB streaming `AES-256-GCM` encrypted `.walimbak` local backups. Includes a standalone offline operator CLI (`tools/license-issuer`, `LicenseSigner`) for Ed25519 `.walimlic` signing. | Flutter (current stable), `drift: ^2.35.0` + `sqlite3: ^3.8.0` (`sqlite3mc` build hook, explicit pre-key `PRAGMA cipher = 'chacha20'; PRAGMA legacy = 0;` `ChaCha20-Poly1305` 256-bit AEAD at rest + fail-closed `PRAGMA cipher` check in `debug`/`profile`/`release`), Ed25519 offline licensing | **Stage 1A** *(Offline Core & Single-Device Android Pilot)* + **Stage 1B** *(`Local v1.0` Commercial Release)* |
| **2. WalimApp Connect** | **Shared multi-user, multi-device edition** inside the **same Android & Windows Flutter codebase**. Delivers the **shared synchronized reservation calendar** across individually authenticated users on Android phones and Windows PCs, Super-Admin-configurable subscription plans (`Basic`: `1` active device; `Higher-Capacity`: up to `5` active devices; decoupled from mandatory individual user accounts/RBAC, with snapshotted `agreed_price_dzd`), device replacement/revocation, binary PDF/logo sync, per-venue DB cryptographic erasure on revocation/downgrade, online booking request inbox, and non-destructive staged Local-to-Connect migration (preserving 12 relational entities + content-addressed PDF/logo binaries). | Shared Flutter App + PHP 8.4 / Laravel Sync API (`Sanctum`) + PostgreSQL 17 (`btree_gist`) | **Stage 2A** *(`Connect v1.0` First Commercial Release)* + **Stage 2B** *(Staged Migration)* |
| **3. Public Marketplace** | Mobile-responsive, SEO-friendly **Arabic (`ar-DZ`, RTL)**, **French (`fr-DZ`, LTR)**, and **English (`en`, LTR)** website (`/ar/...`, `/fr/...`, `/en/...`) covering all **69 Algerian Wilayas**, with optional per-language venue/provider content (`*_ar`, `*_fr`, `*_en`), deterministic fallback (`en -> fr -> ar`, `fr -> ar -> en`, `ar -> fr -> en`), capacity/price/service filters, privacy-safe slot availability, owner-approved online `booking_requests`, WhatsApp contact, and a wedding service provider directory. | Laravel Blade SSR + Tailwind CSS + Alpine.js + PostgreSQL 17 | **Phase 3** *(360° tours & provider self-service in Phase 4)* |
| **4. Super-Admin** | Trilingual (`ar`, `fr`, `en`) back-office for managing organizations, owners, perpetual `.walimlic` licenses (including import of the `issued-licenses.jsonl` operator ledger), Connect subscription plans (configurable names, whole-DZD prices, billing intervals, `max_active_devices` `1` vs `5`, `max_venues`, `max_users`) & active subscriptions, device replacement/revocation, marketplace moderation, curated/self-serve providers, advertising placements, and immutable audit logs. | Filament (Livewire) | **Stage 2A – Phase 4** |

---

## 2. Canonical Documentation Index (`v1.3-draft`)

Start here to navigate the project baseline established and audited in **Phase 0 / Phase 0.3**:

| Document | Purpose |
| :--- | :--- |
| **[`AGENTS.md`](./AGENTS.md)** | Persistent guardrails, source-of-truth hierarchy, and workflow rules for AI coding agents (`v1.3-draft`). |
| **[`.specify/memory/constitution.md`](./.specify/memory/constitution.md)** | **Project Constitution (`v1.3.0-draft` — Pending Product Owner Ratification):** Non-negotiable principles (data safety & whole-DZD append-only ledger + per-venue crypto-erasure, genuine single-device Local independence & unlimited halls by default, shared Android/Windows codebase & trilingual `ar-DZ`/`fr-DZ`/`en` parity, server-enforced authorization & Connect device-tier/price-snapshot rules, testable requirements, human review gates, solo-developer simplicity). |
| **[`docs/product-requirements.md`](./docs/product-requirements.md)** | **Canonical Product Requirements (`v1.3-draft`):** Functional (`REQ-*`) and non-functional (`NFR-*`) requirements organized by component and interleaved delivery stage, including confirmed trilingual support (`ar-DZ`, `fr-DZ`, `en`), Connect device tiers (`1` vs `5`), and `sqlite3mc` `chacha20` encryption. |
| **[`docs/architecture.md`](./docs/architecture.md)** | **Consolidated Architecture Baseline (`v1.3-draft`):** System boundaries, Composer-verified tech stack matrix, `sqlite3mc` explicit `chacha20` (`ChaCha20-Poly1305` 256-bit AEAD) pre-key configuration + `debug`/`profile`/`release` fail-closed check + Sprint 1.1 PoT, shared Android/Windows adaptive design & platform adapters, 69-Wilaya model, trilingual schemas & deterministic fallback, `local_actors`, `booking_requests` vs `reservations` separation, `btree_gist` exclusion constraint, Connect `subscription_plans` (`1` vs `5` active devices) & `device_registrations` & snapshotted `agreed_price_dzd`, monotonic `outbox_seq` + binary asset sync, auth-first `payload_sha256` idempotency, safe partial updates on masked rows, `scanned_through_seq` cursor, per-venue DB crypto-erasure, staged migration with content-addressed assets & lost-response recovery, `LicenseSigner` CLI, and Law 18-07/25-11 privacy safeguards. |
| **[`docs/architecture-review.md`](./docs/architecture-review.md)** | **Architecture Review & Traceability (`v1.3-draft`):** Detailed comparison of the 3 initial architecture drafts (`Opus`, `Sonnet`, `Gemini Argon`), contradictions resolved, Phase 0/0.2/0.3 audit fixes, solo-dev simplifications, and traceability matrix (`TR-01`..`TR-15`). |
| **[`docs/decision-register.md`](./docs/decision-register.md)** | **Decision Register (`v1.3-draft`):** Confirmed architectural decisions (`ADR-001`..`ADR-015`, including `ADR-003` explicit `sqlite3mc` `chacha20`, `ADR-013` Connect `1` vs `5` device tiers & price snapshots, and `ADR-014` confirmed trilingual `ar-DZ`/`fr-DZ`/`en`) and unresolved product-owner questions (`DEC-01`..`DEC-16`, including `DEC-05` trilingual PDF layout and `DEC-07` Connect initial tier pricing/caps) with slice-scoped resolution gates. |
| **[`docs/roadmap.md`](./docs/roadmap.md)** | **Delivery Roadmap (`v1.3-draft`):** Value-First Interleaved stages (`Stage 1A` -> `Stage 2A Connect v1.0` -> `Stage 1B Local v1.0` -> `Stage 2B` -> `Phases 3–4`), candidate sprints (including Sprint 1.1 `sqlite3mc` Android/Windows PoT and Sprint 2.2 device-tier/price-snapshot tests), slice-scoped dependencies, and measurable acceptance gates. |
| **[`docs/ai-development-workflow.md`](./docs/ai-development-workflow.md)** | **AI & Spec Kit Workflow (`v1.3-draft`):** How we execute the 11-step Spec Kit lifecycle (`/speckit-specify` through `/speckit-converge`), Product Owner + ChatGPT review gates, pause-and-audit protocol, testing, and Git conventions. |
| **[`docs/walimapp-phase0-audit.md`](./docs/walimapp-phase0-audit.md)** | **Phase 0 Round 1 Audit Report:** Initial independent review findings (`P0-1`..`P0-7`, `P1-1`..`P1-8`, `P2-1`..`P2-6`) addressed in `v1.1`. |
| **[`docs/walimapp-phase0-audit-round2.md`](./docs/walimapp-phase0-audit-round2.md)** | **Phase 0 Round 2 Audit Report:** Second-round independent audit findings (`P0-1`..`P0-3`, `P1-1`..`P1-9`, `P2-1`..`P2-3`) addressed alongside the Gemini 3.1 Pro review in `v1.2-draft`. |

---

## 3. Repository Layout

```text
walimapp/
├── .agents/skills/                  # Spec Kit Antigravity (agy) skills (/speckit-*)
├── .github/                         # Issue and Pull Request templates
├── .specify/                        # Spec Kit configuration, scripts, templates & constitution
│   └── memory/constitution.md       # Project Constitution v1.3.0-draft
├── docs/                            # Canonical project baseline documentation
│   ├── architecture.md
│   ├── architecture-review.md
│   ├── decision-register.md
│   ├── product-requirements.md
│   ├── roadmap.md
│   ├── ai-development-workflow.md
│   ├── walimapp-phase0-audit.md
│   └── walimapp-phase0-audit-round2.md
├── reference/
│   └── architecture-drafts/         # Preserved original drafts (read-only historical reference)
│       ├── architecture-opus.md
│       ├── architecture-sonnet.md
│       ├── architecture-gemini-argon.md
│       └── product-requirements-initial.md
├── AGENTS.md                        # Persistent AI coding agent instructions
└── README.md                        # Project overview and documentation index
```

*(Note: `apps/owner` and `tools/license-issuer` will be created in Stage 1A/1B, and `backend` in Stage 2A, after Phase 0.3 review and Spec Kit planning approval.)*

---

## 4. Working Method (Spec-Driven Development)

This project uses **GitHub Spec Kit** (`specify-cli`) integrated with **Google Antigravity (`agy`)**. Every feature slice follows an 11-step gated workflow (see [`docs/ai-development-workflow.md`](./docs/ai-development-workflow.md)):

1. `/speckit-specify` → 2. `/speckit-clarify` → **3. Product Owner Review Gate 1**
4. `/speckit-plan` → 5. `/speckit-checklist` → 6. `/speckit-tasks` → 7. `/speckit-analyze` → **8. Product Owner Review Gate 2**
9. `/speckit-implement` → 10. Automated Tests & `/speckit-converge` → 11. Audit, Verification & Git Commit.

---

## 5. License & Confidentiality

**Proprietary & Confidential.** All rights reserved. This repository must remain **private** at all times.
