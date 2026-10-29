# AGENTS.md — Persistent Instructions for AI Coding Agents

Welcome to the **WalimApp** repository. You are operating as the lead software architect and implementation agent for a solo-developer project building an Algeria-first wedding venue management application and public marketplace.

**Read and obey these rules on every session before modifying any file.**

---

## 1. Source of Truth Hierarchy

When inspecting the repository, follow this strict order of authority:

1. **[`.specify/memory/constitution.md`](./.specify/memory/constitution.md)** — Supreme governance and non-negotiable engineering principles (`v1.3.3-draft`).
2. **[`docs/product-requirements.md`](./docs/product-requirements.md)** — Canonical functional and non-functional requirements by component and delivery phase (`v1.3.3-draft`).
3. **[`docs/architecture.md`](./docs/architecture.md)** — Consolidated architectural baseline (`v1.3.3-draft`: shared Android/Windows Flutter client + offline `tools/license-issuer` CLI + Laravel/PostgreSQL 17/Filament backend).
4. **[`docs/decision-register.md`](./docs/decision-register.md)** — Confirmed ADRs (`ADR-001`..`ADR-015`) and unresolved product decisions (`DEC-01`..`DEC-16`) with slice-scoped resolution gates (`v1.3.3-draft`).
5. **[`docs/roadmap.md`](./docs/roadmap.md)** — Value-First Interleaved delivery stages (`Stage 1A`, `Stage 2A`, `Stage 1B`, `Stage 2B`, `Phases 3–4`), candidate sprints, and measurable acceptance gates (`v1.3.3-draft`).
6. **[`docs/ai-development-workflow.md`](./docs/ai-development-workflow.md)** — Mandatory 11-step Spec Kit workflow and review gates (`v1.3.3-draft`).

> [!CAUTION]
> **Historical Drafts Warning:** The files under [`reference/architecture-drafts/`](./reference/architecture-drafts/) (`architecture-opus.md`, `architecture-sonnet.md`, `architecture-gemini-argon.md`, `product-requirements-initial.md`) are **read-only historical inputs preserved from Phase 0**.
> - **NEVER** modify, overwrite, or delete them.
> - **NEVER** copy their superseded assumptions (such as the outdated 58-Wilaya limit, storing `booking_requests` inside `reservations`, mutating SQLite IDs before migration, `amount_minor` centime units, `sqlcipher_flutter_libs` EOL package, or pairing Laravel 12 with Filament v3). Refer to [`docs/architecture-review.md`](./docs/architecture-review.md) for the full reconciliation record.

---

## 2. Non-Negotiable Architectural & Domain Guardrails

1. **Shared Android & Windows Flutter Codebase (`apps/owner`) & Value-First Interleaved Sequencing (`DEC-01`):**
   - Build a **single** Flutter application targeting both **Android (`API 24+`)** and **Windows (`x64`)**.
   - Share all domain models, encrypted Drift/SQLite tables (`drift: ^2.35.0` + `sqlite3: ^3.8.0` with `hooks.user_defines.sqlite3.source: sqlite3mc`, explicit pre-key `PRAGMA cipher = 'chacha20'; PRAGMA legacy = 0;` configuration, and a **fail-closed `SELECT sqlite3mc_config('cipher');` / `PRAGMA cipher;` == `'chacha20'` startup check across `debug`, `profile`, and `release` builds** verified by a Sprint 1.1 Android + Windows proof-of-technology test before building domain features), outbox sync logic, authentication, permissions, and reservation/calendar use cases.
   - Use adaptive layouts (`< 600dp` touch-first phone UI vs `>= 600dp` / `>= 1024px` desktop `NavigationRail` + split view) and isolate OS differences behind the 5 thin platform adapters in `lib/platform/`.
   - **Edition & Sequencing Boundary (`DEC-01`, `DEC-02`):** **WalimApp Local** is a **single-device offline edition** (`max_venues = 1`, `"max_halls": null` unlimited halls by default; no cross-device sharing). **WalimApp Connect** is the release that delivers the **shared multi-user calendar** across multiple Android phones and Windows PCs. Under `DEC-01` Option B (Recommended), Stage 1A (`Sprints 1.1–1.3`) builds the offline foundation and internal single-device Android pilot, and Stage 2A (`Sprints 2.1–2.3`) immediately ships **`WalimApp Connect v1.0`** as the first commercial release before Stage 1B (`Sprint 1.4` `WalimApp Local v1.0`).
2. **Genuine Local Independence, Perpetual License & Offline Issuance (`LicenseSigner`):**
   - **WalimApp Local** must work indefinitely 100% offline using local `sqlite3mc` encrypted SQLite (`chacha20`: `ChaCha20-Poly1305` 256-bit AEAD).
   - Expiry of `updates_until` in a `.walimlic` license only prevents activating newer builds compiled after that date; it must **never** lock, degrade, or disable an activated build or user data.
   - Offline `.walimlic` files are signed via the standalone operator CLI (`tools/license-issuer`) using the `LicenseSigner` interface and an externalized Ed25519 private key (never stored in the client or Git).
   - Expiry of a **WalimApp Connect** subscription pauses cloud sync and public marketplace features while keeping offline local SQLite read/write/print functionality 100% intact (reconciling `sync_outbox` upon renewal).
3. **Authoritative Algeria 69-Wilaya Standard:**
   - Always use the data-driven **69-Wilaya** and 1,541-commune reference structure (`wilayas.code` `'01'`..`'69'`) seeded from a versioned official JORADP/ONS dataset. Never hard-code `1..58`.
4. **Confirmed Trilingual Support (`ar-DZ` RTL, `fr-DZ` LTR, `en` LTR) with Western Numerals & Deterministic Fallback:**
   - Support **Arabic (`ar-DZ`, RTL)**, **French (`fr-DZ`, LTR)**, and **English (`en`, LTR)** across all three surfaces: the `apps/owner` Flutter application (UI and generated PDF contracts/receipts, including connected Arabic cursive shaping verified in Sprint 1.3), the public marketplace (`/ar/...`, `/fr/...`, `/en/...`), and the Filament Super-Admin (`/admin`).
   - Persist independent UI (`language_pref`) and default document (`default_doc_lang`) preferences. Require at least one language (`ar`, `fr`, or `en`) to publish a venue or provider listing, with optional per-language fields (`*_ar`, `*_fr`, `*_en`) and deterministic fallback (`en -> fr -> ar`, `fr -> ar -> en`, `ar -> fr -> en`) wrapped in `<bdi dir="rtl|ltr">` / `Directionality` containers.
   - Always format numbers, dates (`'YYYY-MM-DDTHH:mm:ss'`), and integer whole `DZD` (`د.ج`) amounts using **Western Arabic digits (`0-9`)**.
5. **Booking Requests vs. Reservations:**
   - Public marketplace inquiries belong in `booking_requests` (`pending`, `approved`, `rejected`, `expired`, `cancelled_by_requester`) and **never** block slots until an owner approves them in an atomic transaction creating a `reservations` row.
   - Reservation domain statuses are `confirmed`, `tentative`, `cancelled`, and `needs_review`.
   - `pending_sync` is a **client-side sync overlay** derived from `sync_outbox`, never a replacement for the reservation's domain `status`.
   - Active reservations (`confirmed`, `tentative`) are guarded against double-booking by PostgreSQL's `btree_gist` exclusion constraint on `(hall_id, tsrange(starts_at_local, ends_at_local, '[)'))`.
6. **Canonical Whole-DZD Money, Unconditionally Immutable Financial Ledger & Next-Online Per-Venue Crypto-Erasure:**
   - All monetary values across all tables, DTOs, checksums, and PDFs are **integer whole Algerian Dinars (`BIGINT` `DZD`, column suffix `*_dzd`)**. Never use `FLOAT`/`DOUBLE` or centimes (`amount_minor`).
   - Recorded `payments` rows are **unconditionally append-only**. SQLite and PostgreSQL `BEFORE UPDATE OR DELETE ON payments` triggers must reject **all** `UPDATE` and `DELETE` operations on **every column**; corrections require inserting an explicit `refund` or `adjustment` row referencing `parent_payment_id` with a mandatory `reason`.
   - Each venue is isolated in its own encrypted SQLite database file (`venues/<venue_id>.db`) keyed by `key_venue_<venue_id>`. Revoking a Connect device (`device_registrations.status = 'revoked'` -> `401 DEVICE_REVOKED`) or membership (`venue_memberships.is_active = false` -> `403 MEMBERSHIP_REVOKED`) takes effect **immediately on the server**; on the device's **next successful online check** (or on financial role downgrade `can_view_finance: true -> false`), the client deletes `key_venue_<venue_id>` and unlinks `venues/<venue_id>.db` (**cryptographic erasure**), never executing `DELETE FROM payments` and never promising immediate remote wiping of an offline device.
7. **Safe Synchronization, Filtered Cursor (`scanned_through_seq`), Binary Sync, Multi-Tenant RBAC, Atomic Device Tiers & Fail-Closed `OfflineAccessLease`:**
   - Local outbox operations are ordered by a strictly monotonic `outbox_seq` (never client timestamps) with parent-before-child dependency blocking and pre-push binary upload (`PUT /api/v1/sync/assets/{sha256_checksum}`) for `generated_documents` PDFs and `venues` logos.
   - `/api/v1/sync/push` enforces authentication, active device registration (`device_registrations.status = 'active'`), and active `venue_memberships` RBAC (`venue_memberships.is_active = true`) **before** checking `sync_processed_operations`, verifies `payload_sha256` (`422 IDEMPOTENCY_PAYLOAD_MISMATCH`), and strips financial fields from reservation updates submitted by non-financial roles (`is_financial_masked = true`).
   - `/api/v1/sync/pull` locks `venue_sync_state.last_seq` with `SELECT ... FOR UPDATE` at commit and returns `scanned_through_seq = MAX(seq)` of the scanned 200-row window so role-filtered clients advance cleanly past omitted financial pages, plus `permissions_hash` cursor reset on role change.
   - **Connect Subscription Tiers, Atomic Retry-Safe Device Limit Locking, Device Replacement & Price Protection (`ADR-013`, `DEC-07`):** Super-Admin configures `subscription_plans` (`Basic`: `1` active device; `Higher-Capacity`: up to `5` active devices at a higher price; configurable `name_ar`/`name_fr`/`name_en`, `price_dzd`, `billing_interval`, `max_active_devices`, `max_venues`, `max_users`). Individual user accounts (`users`) and RBAC (`venue_memberships.is_active`) remain mandatory on all plans (`max_active_devices` is **never** equated with a user-seat limit). Device registration and replacement serialize per organization via **`SELECT ... FOR UPDATE` on the active `subscriptions` row**, checking for an existing `active` registration with the same `device_installation_uuid` **first** (so legitimate retries, concurrent duplicate requests from the same device, and lost-response retries return `200 OK`, backed by partial unique index `uq_active_device_installation_per_org` on active `(organization_id, device_installation_uuid)`) before enforcing `effective_max_active_devices` and rejecting excess distinct devices with `409 DEVICE_LIMIT_REACHED`. Editing a plan template never silently changes `subscriptions.agreed_price_dzd` or active limits on existing subscriptions. Every Connect user is bounded offline by a **fail-closed 72h `OfflineAccessLease`** (using OS monotonic time only within the same `lease_boot_id`, **requiring online revalidation via `POST /api/v1/auth/lease/refresh` after any reboot rather than re-anchoring a lease offline via wall clock + `highest_observed_utc`**, and failing closed when rebooted offline, expired, rolled back, or unverifiable), with zero PII in push notification payloads.
8. **Provisional Backup Streaming Encryption Gate & Staged Migration Completeness:**
   - `.walimbak` backups must use a WAL-safe `VACUUM INTO` snapshot encrypted with an independent CSPRNG 256-bit `DEK` (`DEC-06`, with `header_sha256` bound as key-slot `AAD`)—**never derived from the license key**. Use **`libsodium` `crypto_secretstream_xchacha20poly1305` (via `sodium` / `sodium_libs`)** as the **preferred provisional candidate** over `64 KiB` chunks (`init_push`/`init_pull` using `libsodium`'s `24-byte` (`192-bit`) `secretstream_header` `N` to derive subkey `k = HChaCha20(DEK, header[0..16])` and initial 64-bit nonce state `n = header[16..24]` with internal 32-bit counter `i = 1`, encrypting each message under IETF `ChaCha20-Poly1305` with 12-byte nonce `i || n`, updating `n <- n ^ mac[0..8]` and `i <- (i + 1) & 0xffffffff`, automatically rekeying on counter wrap/`TAG_REKEY`/`TAG_FINAL`, and binding per-chunk `ad` and `CRYPTO_SECRETSTREAM_XCHACHA20POLY1305_TAG_FINAL = 0x03`—**without manual per-chunk nonce derivation**). Do **not** silently fall back to a homegrown fixed-chunk format if the `libsodium` cross-platform PoT in Sprint 1.4 fails; instead, trigger the **Pause-and-Audit Protocol** for a separate evaluation and Product Owner approval of a specifically named, vetted alternative. Keep the streaming backup design **provisional** until its integrity, nonce-uniqueness, staging-restore (`restore_staging.db.tmp`), and negative-test properties pass the mandatory Sprint 1.4 Proof-of-Technology gate.
   - Local-to-Connect staged migration must include all 12 relational entities (`local_actors`, `contract_templates`, `generated_documents`), upload binary assets via `migration_assets_manifest` directly to content-addressed S3/R2 paths *before* `Phase M3` commit (pure-PostgreSQL promotion), and recover idempotently from lost `/commit` HTTP responses via `committed_receipt_json`.
9. **Solo-Developer Operational Simplicity & Evidence-Based Stack:**
   - Backend is a single **PHP 8.4 + Laravel + PostgreSQL 17 (`17.x` GA) + Filament + Blade/Tailwind/Alpine SSR** modular monolith (with Track 1 `Laravel 13.x + Filament v5.x + Livewire v4.x + Tailwind v4.1+` recommended for Stage 2A and verified alongside the PostgreSQL 17 version/hosting compatibility gate at the start of Sprint 2.1; see [`docs/architecture.md §2.1, §2.2`](./docs/architecture.md)).
   - Do not introduce microservices, Kubernetes, separate Node.js SSR servers, Event Sourcing, CRDT frameworks, or mandatory Redis without explicit approval.

---

## 3. Mandatory Spec Kit Workflow & Stop Gates

Never jump straight into writing application code. For each feature slice, verify that any slice-blocking `DEC-*` in [`docs/decision-register.md`](./docs/decision-register.md) is settled, then use the Antigravity Spec Kit skills in [`.agents/skills/`](./.agents/skills/):

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

## 4. Security, Links & Git Rules

- **Private Repository Only:** Never change the GitHub repository visibility from `private` to `public`.
- **Repository-Relative Links in Markdown Files:** Inside committed repository `.md` files, always use repository-relative links (`./architecture.md`, `docs/architecture.md`, etc.) so links work on GitHub and any clone.
- **Zero Secrets in Git:** Never commit `.env` files, Ed25519 private keys (`*.pem`, `*.key`), `.walimlic` customer licenses, `issued-licenses.jsonl`, `.walimbak` archives, or local SQLite `.db`/`.sqlite` files.
- **No Fabricated Verification:** Never claim a command, test, migration, commit, or push succeeded without actually executing it and inspecting its output.
