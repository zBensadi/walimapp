# WalimApp — Canonical Product Requirements

- **Status:** Baseline v1.1 (Phase 0 Post-Audit Consolidated)
- **Last Updated:** 2026-10-29
- **Primary Sources:** Initial Product Requirements ([`reference/architecture-drafts/product-requirements-initial.md`](../reference/architecture-drafts/product-requirements-initial.md)), Phase 0 Architecture Consolidation Directives, Shared Android/Windows Flutter Directive, and Phase 0 Independent Audit Findings ([`docs/walimapp-phase0-audit.md`](./walimapp-phase0-audit.md)).
- **Related Documents:** [Architecture Baseline](./architecture.md), [Architecture Review](./architecture-review.md), [Decision Register](./decision-register.md), [Roadmap](./roadmap.md), [Project Constitution](../.specify/memory/constitution.md).

---

## 1. Product Vision & Algerian Market Context

**WalimApp** is an Algeria-first wedding venue (*Salle des Fêtes* / قاعة الحفلات) management application and public wedding marketplace. It serves three primary constituencies:

1. **Wedding Venue Owners, Managers, and Staff:** Need a fast, reliable, offline-capable operational system on **Android smartphones and Windows desktop PCs** to manage reservations, configurable booking slots, customer contracts, installment payments in integer whole Algerian Dinars (`DZD`), expenses, and financial reporting—starting with a **single-device offline edition (WalimApp Local in Phase 1)** and upgrading to a **multi-user, multi-device synchronized team edition (WalimApp Connect in Phase 2)**.
2. **Families & Event Organizers (Public Customers):** Need a mobile-first, bilingual (Arabic RTL / French LTR), SEO-friendly public web directory to discover wedding venues and wedding service providers across all **69 Algerian Wilayas**, check reliable slot availability, submit online booking requests, and contact venues via phone or WhatsApp.
3. **Platform Administrator (Super-Admin):** Needs a centralized administrative back-office to manage organizations, venue owners, perpetual licenses, Connect subscriptions, marketplace listings, curated/self-serve wedding service providers, advertising placements, moderation, and audit logs.

### 1.1 Commercial Editions for Venue Owners

| Capability | WalimApp Local (Perpetual Single-Device Edition — Phase 1) | WalimApp Connect (Connected Multi-Device Team Edition — Phase 2) |
| :--- | :--- | :--- |
| **Target Platforms** | Android Smartphone **or** Windows Desktop (shared Flutter codebase) | Android Smartphones **and** Windows Desktops (shared Flutter codebase) |
| **Internet Requirement** | **None.** Operates indefinitely 100% offline after activation. | **Offline-first SQLCipher/SQLite** on every device with background cloud synchronization when online. |
| **Multi-User / Multi-Device Scope** | **Single-device only.** An installation on one Android phone or one Windows PC is completely self-contained and **does not** synchronize with other phones or PCs. (Optional local Owner PIN hides sensitive financial reports on that single shared device `[OPEN -> DEC-04]`). | **Shared Multi-User, Multi-Device Calendar.** Multiple individually authenticated users (owner, managers, receptionists, accountants) across multiple authorized Android phones and Windows PCs share a synchronized calendar with venue-scoped permissions. |
| **Venue & Hall Scope** | Single physical venue with 1 or more bookable halls/spaces inside that venue `[OPEN -> DEC-02]`. | Single-venue or multi-venue organizations with venue-scoped employee permissions. |
| **Public Marketplace & Online Booking Requests** | Not included (unless upgraded to Connect). | Included: public venue profile, slot availability publishing, and owner-approved online booking requests (Phase 3). |
| **Licensing & Expiry Behavior** | **One-time perpetual license** + optional annual maintenance/update window (`updates_until`). Expiry of maintenance **never** disables the purchased app version or locks local data. Issued in Phase 1 via a standalone offline operator CLI (`tools/license-issuer`) and managed in Phase 2 via Super-Admin. | Monthly or annual subscription. On expiry (after grace period `[OPEN -> DEC-09]`), cloud sync and public marketplace features pause (`expired_local_fallback`), while **local offline access to all synced data remains permanently functional**. Upon renewal, queued local edits reconcile via the standard conflict-safe sync pipeline. |

---

## 2. Requirements by Product Component

### 2.1 Component 1 — WalimApp Local (Shared Android & Windows Single-Device Foundation)

WalimApp Local is the foundational **single-device offline edition** built from a single Flutter codebase (`apps/owner`) targeting both **Android smartphones** (for phone-first venue owners working on-site on a single device) and **Windows desktops** (for single-PC venue offices). *Note: Multi-device team calendar sharing is explicitly a Phase 2 WalimApp Connect capability.*

#### Venue, Hall & Slot Configuration (`REQ-LOC-01` .. `REQ-LOC-04`)
- **`REQ-LOC-01` (Venue & Hall Setup):** The owner can configure their venue profile (Arabic/French name, Wilaya, Commune, address, phone, WhatsApp, optional tax/registration identifiers, logo) and one or more bookable halls/spaces (`halls`) with guest capacity and base pricing.
- **`REQ-LOC-02` (Configurable Booking Slots):** Each hall supports owner-configurable booking slots (`hall_slots`), such as Full Day (*Journée complète* / يوم كامل), Afternoon (*Après-midi* / بعد الزوال), Evening/Night (*Soirée* / سهرة), or custom time windows, including overnight slots crossing midnight (e.g., `19:00` to `02:00` next day).
- **`REQ-LOC-03` (Seasonal & Day-of-Week Pricing):** Halls and slots support base prices in **integer whole Algerian Dinars (`BIGINT` `DZD` / `د.ج`)** with optional seasonal or weekend/weekday pricing rules and add-on service packages (`catering`, `coffee/tea`, `security`, `decor`, `valet`, etc.).
- **`REQ-LOC-04` (Authoritative 69-Wilaya Reference Data):** Built-in offline reference data is seeded from a versioned, checksummed dataset verified against official Algerian *Journal Officiel (JORADP)* / ONS administrative listings covering all **69 official Algerian Wilayas** and their 1,541 communes in Arabic and French.

#### Reservation Calendar & Double-Booking Prevention (`REQ-LOC-05` .. `REQ-LOC-09`)
- **`REQ-LOC-05` (Multi-View Calendar):** Fast offline calendar supporting Month, Week, Day, and Agenda/List views filtered by hall and reservation status, optimized for touch navigation on Android and mouse/keyboard split-view on Windows.
- **`REQ-LOC-06` (Reservation Lifecycle):** Reservations support explicit domain statuses:
  - `confirmed`: Active booking with signed contract / deposit that blocks the hall slot.
  - `tentative`: Optional short-term owner hold (*option*) with an optional expiry date (`hold_expires_at`) that blocks the hall slot `[OPEN -> DEC-03]`.
  - `cancelled`: Cancelled booking recorded with a mandatory cancellation reason and timestamp; **does not** block the hall slot.
  - `needs_review`: Flagged during Local-to-Connect migration or multi-device Connect sync conflict when two offline devices booked overlapping slots; requires explicit owner resolution.
- **`REQ-LOC-07` (Strict Overlap Prevention):** Creating or moving a `confirmed` or `tentative` reservation must validate `[starts_at_local, ends_at_local)` against all existing active reservations for the same `hall_id` and reject any overlap (including Full-Day vs. Half-Day overlaps on the same date and overnight slots crossing midnight).
- **`REQ-LOC-08` (Event Types & Notes):** Each reservation records the customer, hall, date, slot, agreed base price (`base_price_dzd`), selected add-on services (`services_total_dzd`), discount (`discount_dzd`), computed total amount (`total_price_dzd`), guest count estimate, event type (wedding, engagement/Fatha, circumcision/Khitana, conference, other), and internal notes.
- **`REQ-LOC-09` (Instant Offline Search):** Search reservations and customers offline by customer name (Arabic or Latin script), phone number, reservation code, or event date meeting the measurable target in `NFR-03` (`p95 < 100ms`).

#### Customer Management & Data Minimization (`REQ-LOC-10` .. `REQ-LOC-11`)
- **`REQ-LOC-10` (Customer Directory & Optional NIN/CNI):** Store customer profile (`full_name`, primary/secondary Algerian phone numbers, Wilaya/address, notes). Collecting a customer's national ID / CNI / NIN (`national_id_number`) is **strictly optional** (collapsed by default and used only if the venue prints formal legal ID fields on rental contracts), excluded from list views and search indexes, encrypted at rest in SQLCipher and `.walimbak`, and wiped upon customer anonymization.
- **`REQ-LOC-11` (Customer History):** View all current, past, and cancelled reservations, payments, and generated documents associated with a customer.

#### Financial Management, Installments & Expenses (`REQ-LOC-12` .. `REQ-LOC-16`)
- **`REQ-LOC-12` (Installment Payment Tracking in Whole DZD):** Track deposits (*Arrhes / العربون*), intermediate installments (*Versements / الدفعات*), and final balance payments (*Solde / الباقي*) per reservation, with automatic calculation of `amount_paid_dzd` and `balance_due_dzd` in **integer whole Algerian Dinars (`BIGINT` `DZD`)**.
- **`REQ-LOC-13` (Unconditionally Append-Only Payment Ledger):** Recorded payments are **completely immutable**. Once saved, a `payments` row cannot have **any** column updated or be deleted (enforced by database `BEFORE UPDATE OR DELETE` triggers in both SQLite and PostgreSQL). Corrections to amount, payment method, date, or metadata require recording an explicit `refund` or `adjustment` entry linked to `parent_payment_id` with a mandatory `reason` and actor attribution (`recorded_by_user_id`).
- **`REQ-LOC-14` (Payment Methods):** Support Algerian venue payment methods: Cash (*Espèces / نقدا*), CCP / BaridiMob, Bank Transfer (*Virement*), Check (*Chèque*), and CIB/Edahabia (record-only in Local mode).
- **`REQ-LOC-15` (Venue Expense Tracking):** Record operational expenses (`expenses`, in integer whole `DZD`) categorized by utility, maintenance, staff/catering, municipal fees, or event-specific costs, optionally linked to a specific reservation.
- **`REQ-LOC-16` (Financial Summaries & Cashbook):** Provide daily/monthly/seasonal revenue, collected cash, outstanding receivables (`balance_due_dzd`), expenses, and net profit reports, plus CSV/PDF export.

#### Bilingual Documents & Printing (`REQ-LOC-17` .. `REQ-LOC-19`)
- **`REQ-LOC-17` (Offline PDF Generation & Metadata Tracking):** Generate professional, printable **Reservation Contracts** (*Contrat de location / عقد كراء قاعة حفلات*), **Payment Receipts** (*Reçu de paiement / وصل دفع*), and **Booking Summaries** 100% offline in Arabic (RTL), French (LTR), or bilingual header layout `[OPEN -> DEC-05]`, recording each generated PDF's metadata and SHA-256 hash in `generated_documents`.
- **`REQ-LOC-18` (Customizable Contract Clauses):** Allow the venue owner to configure custom house rules and contract terms (`contract_templates`: cancellation policy, overtime fees, damage deposit) printed on contracts.
- **`REQ-LOC-19` (Platform Output):** On Windows, support direct OS printing and saving to disk; on Android, support native print spooler and sharing PDF receipts/contracts via WhatsApp or local storage.

#### Local Backups, Restore & Perpetual Licensing (`REQ-LOC-20` .. `REQ-LOC-23`)
- **`REQ-LOC-20` (WAL-Safe Encrypted Local Backups with Independent Keys):**
  - Create manual and deterministic foreground rolling local backups (`.walimbak`) using a consistent SQLite snapshot (`VACUUM INTO`) verified with `PRAGMA integrity_check` before encryption.
  - Encrypt `.walimbak` archives using `AES-256-GCM` with an independent random 256-bit Data Encryption Key (DEK) wrapped by a user-controlled passphrase and/or printable 256-bit Recovery Key—**never derived from the WalimApp license key** `[OPEN -> DEC-06]`.
  - Display a persistent in-app reminder banner whenever an off-device backup export (to Windows USB/external folder or Android SAF / Google Drive / WhatsApp share) is overdue (> 7 days or > 10 new bookings/payments).
- **`REQ-LOC-21` (Safe Restore Verification):** Restoring a `.walimbak` archive must verify the archive authentication tag/checksum and run `PRAGMA integrity_check` in a temporary SQLite file before replacing the live database, while preserving a `.pre_restore` safety copy of the replaced database.
- **`REQ-LOC-22` (Offline-Capable Perpetual License & Phase 1 Issuance Tool):**
  - Activate WalimApp Local via a signed `.walimlic` file verified offline via an embedded **Ed25519** public key.
  - Include a standalone offline operator CLI tool (`tools/license-issuer`, kept outside the client app and without private keys in Git) so the Product Owner can issue, log, and transfer `.walimlic` files in Phase 1 before the Phase 2 Filament Super-Admin backend is deployed.
- **`REQ-LOC-23` (Perpetual Guarantee):** Expiry of the optional maintenance date (`updates_until`) only prevents activating newly released major/feature versions compiled after `updates_until`; the activated version continues working indefinitely with zero feature degradation.

---

### 2.2 Component 2 — WalimApp Connect (Shared Multi-User Calendar, Sync & Migration)

WalimApp Connect unlocks cloud capabilities inside the **exact same Android and Windows Flutter application** while preserving full offline-first SQLCipher/SQLite operation on every device. **Connect is the release that delivers a shared multi-user calendar across multiple phones and PCs.**

#### Multi-User, Multi-Device & Venue-Scoped Permissions (`REQ-CON-01` .. `REQ-CON-05`)
- **`REQ-CON-01` (Individual Authenticated Users):** Multiple users within the same organization authenticate individually (`email`/`phone` + password + per-device token) on their own authorized Android smartphones or Windows PCs. Sharing a single owner password across staff devices is prohibited.
- **`REQ-CON-02` (Shared Synchronized Calendar):** All authorized devices for a venue see a shared, synchronized reservation calendar, subject to each user's organization and venue permissions.
- **`REQ-CON-03` (Venue-Scoped RBAC & Revocation Lifecycle):**
  - Owners can assign employees to specific venues (or all venues in the organization) with granular roles (`owner`, `manager`, `receptionist`, `accountant`, `viewer`).
  - When a user's membership or device is revoked on the server, all online API/sync requests are blocked immediately (`403`/`401`), the device's local cached venue data is automatically purged on its next reconnection, and offline staff access is bounded by a signed **Offline Access Lease TTL** (72 hours for non-owner staff).
- **`REQ-CON-04` (Server-Enforced Financial Privacy & Permission-Hash Re-Sync):**
  - Employees without financial view permissions (e.g., `viewer` or restricted `receptionist`) do not receive `payments` or `expenses` rows from the sync API, and reservation price columns are masked (`0` with `is_financial_masked = true`) so local storage never overwrites real prices.
  - Any role upgrade or downgrade changes the user's `permissions_hash`, triggering a clean cursor reset / re-sync so upgraded users backfill historical financial records and downgraded users purge restricted local tables.
- **`REQ-CON-05` (Multi-Venue Switching):** Owners managing multiple venues or halls across locations can switch active venues or view consolidated organization performance.

#### Offline-First Synchronization & Conflict Handling (`REQ-CON-06` .. `REQ-CON-10`)
- **`REQ-CON-06` (Idempotent, Monotonically Ordered Outbox Sync):** Local changes are written immediately to SQLCipher/SQLite and queued in `sync_outbox` with a unique `operation_id` (UUIDv7) and a strictly monotonic local `outbox_seq` (enforcing parent-before-child dependency ordering independent of device wall-clock skew). Retrying a batch over flaky mobile data (3G/4G/ADSL) is strictly idempotent.
- **`REQ-CON-07` (Client Sync State vs. Domain Status):** Reservations modified offline display a distinct client-side `pending_sync` indicator until acknowledged by the server, without altering the underlying reservation domain status (`confirmed`, `tentative`, `cancelled`, `needs_review`).
- **`REQ-CON-08` (Deterministic Conflict Resolution & Per-Venue Commit Cursor):**
  - Server delta pulls use a per-venue cursor (`venue_sync_state.last_seq`) locked with `SELECT ... FOR UPDATE` at transaction commit so no event can commit behind an already-advanced client cursor.
  - If two devices book overlapping slots while offline, the first device to sync wins the PostgreSQL `btree_gist` exclusion constraint; the second device's operation receives a structured `SLOT_CONFLICT` response and transitions that competing record to `status = 'needs_review'` with a high-priority owner alert—**never silently deleting or overwriting either booking**.
  - Financial payments are append-only and union-merged by `id` / `operation_id`.
- **`REQ-CON-09` (Public Listing & Availability Management):** From the Connect app, the owner edits their public marketplace profile, photos, public pricing display rules, and controls whether public availability is published.
- **`REQ-CON-10` (Connect Subscription Expiry & Renewal Reconciliation):** If a Connect subscription expires and passes its grace period (`[OPEN -> DEC-09]`), cloud sync and public marketplace booking requests pause (`expired_local_fallback`), while every authorized device retains offline access to its local database. If multiple devices record offline edits during expiry and the subscription is later renewed, their accumulated `sync_outbox` queues reconcile through the standard conflict-safe sync pipeline (converting any overlapping offline bookings to `needs_review`).

#### Local-to-Connect Migration (`REQ-CON-11` .. `REQ-CON-13`)
- **`REQ-CON-11` (Full Historical & Document Preservation):** Upgrading from WalimApp Local to WalimApp Connect preserves 100% of existing customers, halls, slots, service catalogs, contract templates (`contract_templates`), reservations, reservation status history, payment ledger entries, expenses, and generated PDF documents (`generated_documents` metadata + binary files).
- **`REQ-CON-12` (Non-Destructive Staged Upload + Binary Hash Verification):** Migration creates a local `.walimbak` backup first, uploads relational records in resumable chunks to `migration_staging_records`, uploads generated PDF/media binaries to staging object storage, and verifies entity counts, foreign keys, slot overlaps, per-reservation financial checksums, and binary `sha256_checksum` integrity on the server before promoting in a single atomic transaction.
- **`REQ-CON-13` (Safe Interruption Recovery):** If power or internet fails mid-migration, the local SQLite database remains untouched in Local mode and the upload can resume from the last acknowledged chunk/file or be safely aborted.

---

### 2.3 Component 3 — Public Marketplace (SEO Web & Online Booking Requests)

The public marketplace is a fast, mobile-responsive, server-side-rendered (SSR) web application serving Algeria in **Arabic (`ar-DZ`, RTL)** and **French (`fr-DZ`, LTR)**.

#### Venue Discovery, Search & 69-Wilaya Filtering (`REQ-MKT-01` .. `REQ-MKT-06`)
- **`REQ-MKT-01` (Bilingual SSR & SEO):** Indexable SSR pages with clean localized URLs (`/ar/...`, `/fr/...`), `hreflang` tags, `LocalBusiness`/`EventVenue` JSON-LD structured data, OpenGraph tags, and dynamic XML sitemaps.
- **`REQ-MKT-02` (69-Wilaya & Commune Search):** Browse and filter venues across all **69 Algerian Wilayas** and their communes.
- **`REQ-MKT-03` (Capacity, Price, Date & Service Filters):** Filter venues by guest capacity (including separate men/women hall capacity where applicable), price range (`DZD`), available date/slot, and amenities (parking, catering, air conditioning, generator, bridal suite, accessibility).
- **`REQ-MKT-04` (Rich Venue Profile Pages):** Display verified venue descriptions (Arabic/French), photo galleries (`WebP`/`AVIF`), halls and slot definitions, transparent pricing policy (exact price, "starting from", or "on quote" `[OPEN -> DEC-14]`), location map/directions, and direct contact actions (Phone call, WhatsApp deep-link with prefilled message).
- **`REQ-MKT-05` (Reliable Public Availability Calendar):** Display read-only slot availability (`Available` vs. `Booked/Unavailable`) derived from the venue's synced `confirmed` and `tentative` reservations (when venue sync is fresh)—**never exposing private customer names, phone numbers, or contract amounts**.
- **`REQ-MKT-06` (Curated Wedding Service Provider Directory):** Provide a directory of non-venue wedding providers (caterers, photographers, decorators, traditional outfits/Negafa, pastry, DJs/orchestras, car rental) searchable by category and Wilaya (staff-curated in Phase 3; provider self-service in Phase 4).

#### Online Booking Requests (`REQ-MKT-07` .. `REQ-MKT-11`)
- **`REQ-MKT-07` (Strict Separation of Requests and Reservations):** Public visitors submit **Booking Requests** (`booking_requests`), **never** direct `reservations`. A booking request specifies the target venue, hall, requested date, requested slot, requester name, phone/WhatsApp, estimated guest count, event type, and optional message, plus anti-spam protection (`[OPEN -> DEC-12]`) and Law 18-07 privacy consent recording.
- **`REQ-MKT-08` (Non-Blocking Pending State):** Pending booking requests (`status = 'pending'`) do **not** block the venue's calendar slot or prevent the owner from recording a walk-in booking. Multiple requests may be submitted for a popular date until the owner approves one.
- **`REQ-MKT-09` (Owner Review & Approval Workflow):** Venue owners/managers receive booking requests in WalimApp Connect (Android/Windows) and can contact the requester via phone/WhatsApp, then **Approve** or **Reject** the request.
- **`REQ-MKT-10` (Atomic Approval & Availability Validation):** Approving a `booking_request` validates in a single PostgreSQL transaction that the requested hall and slot are still free, creates or links the `customer`, inserts a `confirmed` (or `tentative`) `reservation` guarded by the `btree_gist` exclusion constraint, and marks the request `approved` (`resulting_reservation_id`). It must **never** silently overwrite an existing reservation.
- **`REQ-MKT-11` (Competing Request Handling):** When a slot becomes booked, any other `pending` booking requests for the same hall and overlapping time window are automatically flagged in the owner UI so the owner can reject them or offer an alternative date `[OPEN -> DEC-13]`.

---

### 2.4 Component 4 — Super-Admin Back-Office (Filament)

The Super-Admin interface provides centralized governance, commercial operations, and support.

- **`REQ-ADM-01` (Organization, Owner & Venue Management):** Create, inspect, suspend, or verify organizations, venue owners, venues, and halls; assist with onboarding and Local-to-Connect migrations.
- **`REQ-ADM-02` (Perpetual License Issuance, Import & Device Transfers):** Import the Phase 1 offline operator license ledger (`issued-licenses.jsonl`), generate and sign new WalimApp Local perpetual licenses (`.walimlic`), manage maintenance windows (`updates_until`), view bound installation fingerprints, and approve hardware/device transfer requests.
- **`REQ-ADM-03` (Connect Subscription & Billing Management):** Manage Connect subscription plans, trial periods, manual payment confirmations (bank transfer / CCP / BaridiMob / cash receipt) `[OPEN -> DEC-08]`, renewal dates, and grace periods.
- **`REQ-ADM-04` (Marketplace Moderation & Quality Control):** Review, approve, feature, or unpublish venue listings, photos, and provider profiles before or after publication.
- **`REQ-ADM-05` (Booking Request Support & Diagnostics):** View platform-wide `booking_requests` delivery status, sync health diagnostics, and conflict/migration logs to support venue owners.
- **`REQ-ADM-06` (Advertising & Featured Placements):** Manage featured venue badges, homepage/Wilaya banners, and sponsored placements with start/end dates and Wilaya targeting (admin-managed in Phase 3; expanded self-serve in Phase 4).
- **`REQ-ADM-07` (Immutable Platform Audit Log):** Record an append-only `audit_logs` trail of all administrative actions, license operations, subscription changes, permission modifications, and moderation decisions.

---

### 2.5 Phase 4 Expansion Capabilities (Deferred Until Phases 1–3 Are Complete)

To protect solo-developer delivery velocity, the following capabilities are explicitly scoped to **Phase 4** and must not delay WalimApp Local, Connect, or the initial Marketplace:

- **`REQ-PH4-01` (360° Virtual Tours):** Interactive 360° equirectangular panorama tours embedded on public venue profiles (`Pannellum`), with static image storage on object storage (`S3`/`R2`) `[OPEN -> DEC-16]`.
- **`REQ-PH4-02` (Provider Self-Service Portal):** Self-registration, profile editing, portfolio upload, and lead analytics for non-venue wedding service providers, subject to Super-Admin moderation `[OPEN -> DEC-15]`.
- **`REQ-PH4-03` (Self-Serve Advertising & Analytics):** Owner/provider self-service campaign requests, impression/click/WhatsApp-lead attribution, and automated billing integration.

---

## 3. Cross-Cutting Non-Functional Requirements

| ID | Category | Requirement |
| :--- | :--- | :--- |
| **`NFR-01`** | **Localization, Numerals & Whole DZD** | Full support for **Arabic (`ar-DZ`, RTL)** and **French (`fr-DZ`, LTR)** across all components from Day 1. All dates, prices, and phone numbers in both locales must render using **Western Arabic numerals (`0-9`)** and **integer whole Algerian Dinars (`BIGINT` `DZD` / `د.ج`)**. |
| **`NFR-02`** | **Shared Codebase** | One shared Flutter codebase (`apps/owner`) for Android (`API 24+`) and Windows (`x64`), sharing domain, data/SQLCipher, sync, auth, and business rules with adaptive touch/desktop UI. |
| **`NFR-03`** | **Measurable Offline Performance** | Local calendar month/week/day query + view-model projection, reservation overlap check, and customer search must achieve **`p95 < 100ms`** against a warm local SQLCipher/SQLite database seeded with **2,000 reservations, 1,500 customers, and 5,000 payment rows across 5 halls**, verified on a mid-range Android smartphone (Snapdragon 680 / Helio G99 class, 4 GB RAM) and standard Windows x64 PC. |
| **`NFR-04`** | **Encryption at Rest & Algerian Data Privacy** | Encrypt local client databases at rest using **SQLCipher (`sqlcipher_flutter_libs`)** with keys stored in OS hardware/secure storage, encrypt `.walimbak` backups with an independent DEK (`DEC-06`), and enforce TLS 1.2/1.3 in transit. Provide technical capabilities for Algerian **Law 18-07** and **Law 25-11** (data minimization with optional NIN/CNI, explicit consent capture on public forms, data export/anonymization tools, and zero PII in push payloads). Formal legal compliance, ANPDP declaration, and production hosting jurisdiction (`[OPEN -> DEC-10]`) are gated on review by qualified Algerian legal counsel before Phase 2/3 production launch. |
| **`NFR-05`** | **Solo-Developer Maintainability** | Single Laravel modular monolith + PostgreSQL 17 + Filament backend deployment (versions verified via Composer lock resolution at Phase 2 start). No microservices, Kubernetes, or mandatory Redis without demonstrated production need. |
| **`NFR-06`** | **Backup & Recovery** | Encrypted daily automated PostgreSQL backups with tested point-in-time recovery (`RPO <= 24h`, `RTO <= 4h`) and WAL-safe verified `.walimbak` local client backups. |

---

## 4. Delivery Phase Summary & Decision Gates

Each unresolved decision (`DEC-*`) blocks **only the specific sprint/feature slice that depends on it**, rather than blocking the entire phase upfront:

| Phase | Scope Summary | Slice-Scoped Decision Gates |
| :--- | :--- | :--- |
| **Phase 0** | Architecture consolidation, requirements baseline, decision register, roadmap, Spec Kit (`agy`) constitution, and private Git repository setup. | Product Owner review & approval of revised Phase 0 artifacts and Constitution. |
| **Phase 1** | **WalimApp Local MVP (Single-Device Edition on Shared Android & Windows Codebase):** Offline SQLCipher/SQLite, configurable halls/slots, calendar, customers, unconditionally append-only payments, expenses, bilingual PDF contracts/receipts, WAL-safe `.walimbak` backups, Ed25519 perpetual licensing + offline `tools/license-issuer` CLI. | • Before Sprint 1.1: `DEC-01`, `DEC-02`<br>• Before Sprint 1.2: `DEC-03`, `DEC-04`<br>• Before Sprint 1.3: `DEC-05`<br>• Before Sprint 1.4: `DEC-06` |
| **Phase 2** | **WalimApp Connect (Shared Multi-User/Multi-Device Calendar & Sync):** Central Laravel + PostgreSQL 17 + Filament backend, individual user auth, venue-scoped RBAC, monotonic outbox sync, per-venue commit cursor, conflict resolution, and staged Local-to-Connect migration (including documents). | • Before Sprint 2.1: Backend stack lock verification + `DEC-07`<br>• Before Sprint 2.2: `DEC-08`, `DEC-09`<br>• Before Sprint 2.3: `DEC-11`<br>• Before Production Launch: `DEC-10` (ANPDP/Legal review) |
| **Phase 3** | **Public Marketplace & Online Booking Requests:** SSR Arabic/French venue directory across 69 Wilayas, availability calendar, `booking_requests` submission & owner approval flow, curated provider directory, basic admin ad placements. | • Before Sprint 3.1: `DEC-12`, `DEC-14`<br>• Before Sprint 3.2: `DEC-13` |
| **Phase 4** | **Expansion:** Self-serve advertising & lead analytics, provider self-service registration portal, and 360° virtual tours. | • Before Sprint 4.1/4.2: `DEC-15`<br>• Before Sprint 4.3: `DEC-16` |
