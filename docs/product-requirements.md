# WalimApp — Canonical Product Requirements

- **Status:** Baseline v1.0 (Phase 0 Consolidated)
- **Last Updated:** 2026-10-29
- **Primary Sources:** Initial Product Requirements (`reference/architecture-drafts/product-requirements-initial.md`), Phase 0 Architecture Consolidation Directives, and Shared Android/Windows Flutter Directive.
- **Related Documents:** [Architecture Baseline](file:///c:/proj/walimapp/docs/architecture.md), [Architecture Review](file:///c:/proj/walimapp/docs/architecture-review.md), [Decision Register](file:///c:/proj/walimapp/docs/decision-register.md), [Roadmap](file:///c:/proj/walimapp/docs/roadmap.md).

---

## 1. Product Vision & Algerian Market Context

**WalimApp** is an Algeria-first wedding venue (*Salle des Fêtes* / قاعة الحفلات) management application and public wedding marketplace. It serves three primary constituencies:

1. **Wedding Venue Owners, Managers, and Staff:** Need a fast, reliable, offline-capable operational system on **Android smartphones and Windows desktop PCs** to manage reservations, configurable booking slots, customer contracts, installment payments in Algerian Dinar (`DZD`), expenses, and financial reporting—with an optional cloud-connected tier for multi-device/multi-employee synchronization and online visibility.
2. **Families & Event Organizers (Public Customers):** Need a mobile-first, bilingual (Arabic RTL / French LTR), SEO-friendly public web directory to discover wedding venues and wedding service providers across all **69 Algerian Wilayas**, check reliable slot availability, submit online booking requests, and contact venues via phone or WhatsApp.
3. **Platform Administrator (Super-Admin):** Needs a centralized administrative back-office to manage organizations, venue owners, perpetual licenses, Connect subscriptions, marketplace listings, curated/self-serve wedding service providers, advertising placements, moderation, and audit logs.

### 1.1 Commercial Editions for Venue Owners

| Capability | WalimApp Local (Perpetual Edition) | WalimApp Connect (Connected Subscription Edition) |
| :--- | :--- | :--- |
| **Target Platforms** | Android Smartphone + Windows Desktop (shared Flutter codebase) | Android Smartphone + Windows Desktop (shared Flutter codebase) |
| **Internet Requirement** | **None.** Operates indefinitely 100% offline after activation. | **Offline-first SQLite** on every device with background cloud synchronization when online. |
| **Multi-User / Multi-Device** | Single-device installation (local user accounts/PINs on that device only; no cross-device sync). | Multiple individually authenticated users across multiple authorized Android and Windows devices sharing a synchronized calendar. |
| **Venue & Hall Scope** | Single venue (with 1 or more halls/spaces inside that venue) `[OPEN -> DEC-02]`. | Single-venue or multi-venue organizations with venue-scoped employee permissions. |
| **Public Marketplace & Online Booking Requests** | Not included (unless upgraded to Connect). | Included: public venue profile, slot availability publishing, and owner-approved online booking requests. |
| **Licensing & Expiry Behavior** | **One-time perpetual license** + optional annual maintenance/update window (`updates_until`). Expiry of maintenance **never** disables the purchased app version or locks local data. | Monthly or annual subscription. On expiry (after grace period `[OPEN -> DEC-09]`), cloud sync and public marketplace features pause, while **local offline access to all synced data remains permanently functional**. |

---

## 2. Requirements by Product Component

### 2.1 Component 1 — WalimApp Local (Shared Android & Windows Owner Client)

WalimApp Local is the foundational offline-first application built from a single Flutter codebase (`apps/owner`) targeting both **Android smartphones** (phone-first venue owners working on-site) and **Windows desktops** (office/reception PCs).

#### Venue, Hall & Slot Configuration (`REQ-LOC-01` .. `REQ-LOC-04`)
- **`REQ-LOC-01` (Venue & Hall Setup):** The owner can configure their venue profile (Arabic/French name, Wilaya, Commune, address, phone, WhatsApp, tax/registration identifiers, logo) and one or more bookable halls/spaces (`halls`) with guest capacity and base pricing.
- **`REQ-LOC-02` (Configurable Booking Slots):** Each hall supports owner-configurable booking slots (`hall_slots`), such as Full Day (*Journée complète* / يوم كامل), Afternoon (*Après-midi* / بعد الزوال), Evening/Night (*Soirée* / سهرة), or custom time windows, including overnight slots crossing midnight (e.g., `19:00` to `02:00` next day).
- **`REQ-LOC-03` (Seasonal & Day-of-Week Pricing):** Halls and slots support base prices in integer `DZD` (`د.ج`) with optional seasonal or weekend/weekday pricing rules and add-on service packages (`catering`, `coffee/tea`, `security`, `decor`, `valet`, etc.).
- **`REQ-LOC-04` (69-Wilaya Reference Data):** Built-in offline reference data includes all **69 official Algerian Wilayas** and their communes in Arabic and French.

#### Reservation Calendar & Double-Booking Prevention (`REQ-LOC-05` .. `REQ-LOC-09`)
- **`REQ-LOC-05` (Multi-View Calendar):** Fast offline calendar supporting Month, Week, Day, and Agenda/List views filtered by hall and reservation status, optimized for touch navigation on Android and mouse/keyboard split-view on Windows.
- **`REQ-LOC-06` (Reservation Lifecycle):** Reservations support explicit domain statuses:
  - `confirmed`: Active booking with signed contract / deposit that blocks the hall slot.
  - `tentative`: Optional short-term owner hold (*option*) with an optional expiry date that blocks the hall slot `[OPEN -> DEC-03]`.
  - `cancelled`: Cancelled booking recorded with a mandatory cancellation reason and timestamp; **does not** block the hall slot.
  - `needs_review`: Flagged during Local-to-Connect migration or multi-device sync conflict when two offline devices booked overlapping slots; requires explicit owner resolution.
- **`REQ-LOC-07` (Strict Overlap Prevention):** Creating or moving a `confirmed` or `tentative` reservation must validate `[starts_at_local, ends_at_local)` against all existing active reservations for the same `hall_id` and reject any overlap (including Full-Day vs. Half-Day overlaps on the same date).
- **`REQ-LOC-08` (Event Types & Notes):** Each reservation records the customer, hall, date, slot, agreed base price, selected add-on services, discount, computed total amount, guest count estimate, event type (wedding, engagement/Fatha, circumcision/Khitana, conference, other), and internal notes.
- **`REQ-LOC-09` (Instant Offline Search):** Search reservations and customers offline by customer name (Arabic or Latin script), phone number, reservation code, or event date in `< 100ms`.

#### Customer Management (`REQ-LOC-10` .. `REQ-LOC-11`)
- **`REQ-LOC-10` (Customer Directory):** Store customer profile (`full_name`, primary/secondary Algerian phone numbers, national ID / NIN or carte d'identité number for contract generation, Wilaya/address, notes).
- **`REQ-LOC-11` (Customer History):** View all current, past, and cancelled reservations, payments, and generated documents associated with a customer.

#### Financial Management, Installments & Expenses (`REQ-LOC-12` .. `REQ-LOC-16`)
- **`REQ-LOC-12` (Installment Payment Tracking):** Track deposits (*Arrhes / العربون*), intermediate installments (*Versements / الدفعات*), and final balance payments (*Solde / الباقي*) per reservation, with automatic calculation of `amount_paid` and `balance_due` in integer `DZD`.
- **`REQ-LOC-13` (Append-Only Payment Ledger):** Recorded payments are **immutable**. Once saved, a payment row cannot be silently edited or deleted. Corrections require recording an explicit `refund` or `adjustment` entry linked to `parent_payment_id` with a mandatory `reason` and actor attribution.
- **`REQ-LOC-14` (Payment Methods):** Support Algerian venue payment methods: Cash (*Espèces / نقدا*), CCP / BaridiMob, Bank Transfer (*Virement*), Check (*Chèque*), and CIB/Edahabia (record-only in Local mode).
- **`REQ-LOC-15` (Venue Expense Tracking):** Record operational expenses (`expenses`) categorized by utility, maintenance, staff/catering, municipal fees, or event-specific costs, optionally linked to a specific reservation.
- **`REQ-LOC-16` (Financial Summaries & Cashbook):** Provide daily/monthly/seasonal revenue, collected cash, outstanding receivables (`balance_due`), expenses, and net profit reports, plus CSV/PDF export.

#### Bilingual Documents & Printing (`REQ-LOC-17` .. `REQ-LOC-19`)
- **`REQ-LOC-17` (Offline PDF Generation):** Generate professional, printable **Reservation Contracts** (*Contrat de location / عقد كراء قاعة حفلات*), **Payment Receipts** (*Reçu de paiement / وصل دفع*), and **Booking Summaries** 100% offline in Arabic (RTL), French (LTR), or bilingual layout `[OPEN -> DEC-05]`.
- **`REQ-LOC-18` (Customizable Contract Clauses):** Allow the venue owner to configure custom house rules and contract terms (cancellation policy, overtime fees, damage deposit) printed on contracts.
- **`REQ-LOC-19` (Platform Output):** On Windows, support direct OS printing and saving to disk; on Android, support native print spooler and sharing PDF receipts/contracts via WhatsApp or local storage.

#### Local Backups, Restore & Perpetual Licensing (`REQ-LOC-20` .. `REQ-LOC-23`)
- **`REQ-LOC-20` (Encrypted Local Backups):** Create manual and automatic rolling local backups (`.walimbak`, AES-256-GCM encrypted SQLite snapshot + manifest) on Windows local/USB drives and Android user-selected storage (`Storage Access Framework`) `[OPEN -> DEC-06]`.
- **`REQ-LOC-21` (Safe Restore Verification):** Restoring a backup must verify the archive checksum and run `PRAGMA integrity_check` in a temporary file before replacing the live SQLite database, while keeping a `.pre_restore` backup of the replaced database.
- **`REQ-LOC-22` (Offline-Capable Perpetual License):** Activate WalimApp Local via an online license key or an offline signed `.walimlic` file verified via an embedded **Ed25519** public key.
- **`REQ-LOC-23` (Perpetual Guarantee):** Expiry of the optional maintenance date (`updates_until`) only prevents activating newly released major/feature versions compiled after `updates_until`; the activated version continues working indefinitely with zero feature degradation.

---

### 2.2 Component 2 — WalimApp Connect (Synchronization, Multi-User & Migration)

WalimApp Connect unlocks cloud capabilities inside the **exact same Android and Windows Flutter application** while preserving full offline-first SQLite operation on every device.

#### Multi-User, Multi-Device & Venue-Scoped Permissions (`REQ-CON-01` .. `REQ-CON-05`)
- **`REQ-CON-01` (Individual Authenticated Users):** Multiple users within the same organization authenticate individually (`email`/`phone` + password + device token) on their own authorized Android smartphones or Windows PCs.
- **`REQ-CON-02` (Shared Synchronized Calendar):** All authorized devices for a venue see a shared, synchronized reservation calendar, subject to each user's organization and venue permissions.
- **`REQ-CON-03` (Venue-Scoped RBAC):** Owners can assign employees to specific venues (or all venues in the organization) with granular roles (`owner`, `manager`, `receptionist`, `accountant`, `viewer`) `[OPEN -> DEC-04]`.
- **`REQ-CON-04` (Server-Enforced Financial Privacy):** Employees without financial view permissions (e.g., `viewer` or restricted `receptionist`) must not receive financial ledger entries or revenue aggregates from the sync API; the server strips unauthorized fields/entities before transmission.
- **`REQ-CON-05` (Multi-Venue Switching):** Owners managing multiple venues or halls across locations can switch active venues or view consolidated organization performance.

#### Offline-First Synchronization & Conflict Handling (`REQ-CON-06` .. `REQ-CON-10`)
- **`REQ-CON-06` (Idempotent Outbox Sync):** Local changes are written immediately to SQLite and queued in `sync_outbox` with a unique `operation_id` (UUIDv7). Retrying a batch over flaky mobile data (3G/4G/ADSL) is strictly idempotent.
- **`REQ-CON-07` (Client Sync State vs. Domain Status):** Reservations modified offline display a distinct client-side `pending_sync` indicator until acknowledged by the server, without altering the underlying reservation domain status (`confirmed`, `tentative`, `cancelled`).
- **`REQ-CON-08` (Deterministic Conflict Resolution):**
  - If two devices book overlapping slots while offline, the first device to sync wins the PostgreSQL `btree_gist` exclusion constraint; the second device's operation receives a structured `SLOT_CONFLICT` response and transitions that competing record to `status = 'needs_review'` with a high-priority owner alert—**never silently deleting or overwriting either booking**.
  - Financial payments are append-only and union-merged by `id` / `operation_id`.
- **`REQ-CON-09` (Public Listing & Availability Management):** From the Connect app (or web owner portal), the owner edits their public marketplace profile, photos, public pricing display rules, and controls whether public availability is published.
- **`REQ-CON-10` (Connect Subscription Expiry Behavior):** If a Connect subscription expires and passes its grace period, cloud sync and public marketplace booking requests pause, but every authorized Android and Windows device retains full offline read/write access to its local SQLite database.

#### Local-to-Connect Migration (`REQ-CON-11` .. `REQ-CON-13`)
- **`REQ-CON-11` (Full Historical Preservation):** Upgrading from WalimApp Local to WalimApp Connect preserves 100% of existing customers, halls, slots, reservations, payment ledger entries, expenses, contract templates, and generated documents.
- **`REQ-CON-12` (Non-Destructive Staged Upload):** Migration creates a local backup first, uploads records in resumable chunks to server staging tables (`migration_staging_records`), verifies foreign keys, slot overlaps, and per-reservation financial checksums on the server, and promotes the data in a single atomic transaction.
- **`REQ-CON-13` (Safe Interruption Recovery):** If power or internet fails mid-migration, the local SQLite database remains untouched in Local mode and the upload can resume from the last acknowledged chunk or be safely aborted.

---

### 2.3 Component 3 — Public Marketplace (SEO Web & Online Booking Requests)

The public marketplace is a fast, mobile-responsive, server-side-rendered (SSR) web application serving Algeria in **Arabic (`ar-DZ`, RTL)** and **French (`fr-DZ`, LTR)**.

#### Venue Discovery, Search & 69-Wilaya Filtering (`REQ-MKT-01` .. `REQ-MKT-06`)
- **`REQ-MKT-01` (Bilingual SSR & SEO):** Indexable SSR pages with clean localized URLs (`/ar/...`, `/fr/...`), `hreflang` tags, `LocalBusiness`/`EventVenue` JSON-LD structured data, OpenGraph tags, and dynamic XML sitemaps.
- **`REQ-MKT-02` (69-Wilaya & Commune Search):** Browse and filter venues across all **69 Algerian Wilayas** and their communes.
- **`REQ-MKT-03` (Capacity, Price, Date & Service Filters):** Filter venues by guest capacity (including separate men/women hall capacity where applicable), price range (`DZD`), available date/slot, and amenities (parking, catering, air conditioning, generator, bridal suite, accessibility).
- **`REQ-MKT-04` (Rich Venue Profile Pages):** Display verified venue descriptions (Arabic/French), photo galleries (`WebP`/`AVIF`), halls and slot definitions, transparent pricing policy (exact price, "starting from", or "on quote"), location map/directions, and direct contact actions (Phone call, WhatsApp deep-link with prefilled message).
- **`REQ-MKT-05` (Reliable Public Availability Calendar):** Display read-only slot availability (`Available` vs. `Booked/Unavailable`) derived from the venue's synced `confirmed` and `tentative` reservations—**never exposing private customer names, phone numbers, or contract amounts**.
- **`REQ-MKT-06` (Curated Wedding Service Provider Directory):** Provide a directory of non-venue wedding providers (caterers, photographers, decorators, traditional outfits/Negafa, pastry, DJs/orchestras, car rental) searchable by category and Wilaya (staff-curated in Phase 3; provider self-service in Phase 4).

#### Online Booking Requests (`REQ-MKT-07` .. `REQ-MKT-11`)
- **`REQ-MKT-07` (Strict Separation of Requests and Reservations):** Public visitors submit **Booking Requests** (`booking_requests`), **never** direct `reservations`. A booking request specifies the target venue, hall, requested date, requested slot, requester name, phone/WhatsApp, estimated guest count, event type, and optional message, plus anti-spam protection and Law 18-07 privacy consent.
- **`REQ-MKT-08` (Non-Blocking Pending State):** Pending booking requests (`status = 'pending'`) do **not** block the venue's calendar slot or prevent the owner from recording a walk-in booking. Multiple requests may be submitted for a popular date until the owner approves one.
- **`REQ-MKT-09` (Owner Review & Approval Workflow):** Venue owners/managers receive booking requests in WalimApp Connect (Android/Windows) and can contact the requester via phone/WhatsApp, then **Approve** or **Reject** the request.
- **`REQ-MKT-10` (Atomic Approval & Availability Validation):** Approving a `booking_request` validates in a single PostgreSQL transaction that the requested hall and slot are still free, creates or links the `customer`, inserts a `confirmed` (or `tentative`) `reservation` guarded by the `btree_gist` exclusion constraint, and marks the request `approved` (`resulting_reservation_id`). It must **never** silently overwrite an existing reservation.
- **`REQ-MKT-11` (Competing Request Handling):** When a slot becomes booked, any other `pending` booking requests for the same hall and overlapping time window are automatically flagged in the owner UI so the owner can reject them or offer an alternative date `[OPEN -> DEC-13]`.

---

### 2.4 Component 4 — Super-Admin Back-Office (Filament v4)

The Super-Admin interface provides centralized governance, commercial operations, and support.

- **`REQ-ADM-01` (Organization, Owner & Venue Management):** Create, inspect, suspend, or verify organizations, venue owners, venues, and halls; assist with onboarding and Local-to-Connect migrations.
- **`REQ-ADM-02` (Perpetual License Issuance & Device Transfers):** Generate and sign WalimApp Local perpetual licenses (`.walimlic`), manage maintenance windows (`updates_until`), view bound device fingerprints, and approve hardware/device transfer requests.
- **`REQ-ADM-03` (Connect Subscription & Billing Management):** Manage Connect subscription plans, trial periods, manual payment confirmations (bank transfer / CCP / BaridiMob / cash receipt) `[OPEN -> DEC-08]`, renewal dates, and grace periods.
- **`REQ-ADM-04` (Marketplace Moderation & Quality Control):** Review, approve, feature, or unpublish venue listings, photos, and provider profiles before or after publication.
- **`REQ-ADM-05` (Booking Request Support & Diagnostics):** View platform-wide `booking_requests` delivery status, sync health diagnostics, and conflict/migration logs to support venue owners.
- **`REQ-ADM-06` (Advertising & Featured Placements):** Manage featured venue badges, homepage/Wilaya banners, and sponsored placements with start/end dates and Wilaya targeting (admin-managed in Phase 3; expanded self-serve in Phase 4).
- **`REQ-ADM-07` (Immutable Platform Audit Log):** Record an append-only `audit_logs` trail of all administrative actions, license operations, subscription changes, permission modifications, and moderation decisions.

---

### 2.5 Phase 4 Expansion Capabilities (Deferred Until Phases 1–3 Are Complete)

To protect solo-developer delivery velocity, the following capabilities are explicitly scoped to **Phase 4** and must not delay WalimApp Local, Connect, or the initial Marketplace:

- **`REQ-PH4-01` (360° Virtual Tours):** Interactive 360° equirectangular panorama tours embedded on public venue profiles (`Pannellum`), with static tile/image storage on object storage (`S3`/`R2`) `[OPEN -> DEC-16]`.
- **`REQ-PH4-02` (Provider Self-Service Portal):** Self-registration, profile editing, portfolio upload, and lead analytics for non-venue wedding service providers, subject to Super-Admin moderation `[OPEN -> DEC-15]`.
- **`REQ-PH4-03` (Self-Serve Advertising & Analytics):** Owner/provider self-service campaign requests, impression/click/WhatsApp-lead attribution, and automated billing integration.

---

## 3. Cross-Cutting Non-Functional Requirements

| ID | Category | Requirement |
| :--- | :--- | :--- |
| **`NFR-01`** | **Localization & Numerals** | Full support for **Arabic (`ar-DZ`, RTL)** and **French (`fr-DZ`, LTR)** across all components from Day 1. All dates, prices, and phone numbers in both locales must render using **Western Arabic numerals (`0-9`)** and integer Algerian Dinar (`DZD` / `د.ج`). |
| **`NFR-02`** | **Shared Codebase** | One shared Flutter codebase (`apps/owner`) for Android (`API 24+`) and Windows (`x64`), sharing domain, data/SQLite, sync, auth, and business rules with adaptive touch/desktop UI. |
| **`NFR-03`** | **Offline Performance** | Local calendar navigation, reservation creation, and customer search must complete in `< 100ms` offline on a mid-range Android phone (4 GB RAM) and standard Windows office PC. |
| **`NFR-04`** | **Algerian Data Privacy** | Comply with Algerian **Law 18-07** and **Law 25-11** (data minimization, explicit consent on booking forms, encryption in transit/at rest, right to erasure/rectification, and ANPDP compliance review before production hosting selection `[OPEN -> DEC-10]`). |
| **`NFR-05`** | **Solo-Developer Maintainability** | Single Laravel 12 modular monolith + PostgreSQL 17 + Filament v4 backend deployment. No microservices, Kubernetes, or mandatory Redis without demonstrated production need. |
| **`NFR-06`** | **Backup & Recovery** | Encrypted daily automated PostgreSQL backups with tested point-in-time recovery (`RPO <= 24h`, `RTO <= 4h`) and verified `.walimbak` local client backups. |

---

## 4. Delivery Phase Summary

| Phase | Scope Summary | Prerequisite Gate |
| :--- | :--- | :--- |
| **Phase 0** | Architecture consolidation, requirements baseline, decision register, roadmap, Spec Kit (`agy`) constitution, and private Git repository setup. | Product Owner review & approval of Phase 0 artifacts. |
| **Phase 1** | **WalimApp Local MVP** (shared Flutter codebase for Android smartphones and Windows desktops: offline SQLite, configurable halls/slots, calendar, customers, append-only payments, expenses, bilingual PDF contracts/receipts, `.walimbak` backups, Ed25519 perpetual licensing). | Pre-Phase 1 decisions (`DEC-01`..`DEC-06`) resolved; Phase 1 Spec Kit specs/plans approved. |
| **Phase 2** | **WalimApp Connect** (Laravel 12 + PostgreSQL 17 + Filament v4 core, multi-tenant auth, venue-scoped RBAC, multi-user/multi-device outbox sync, conflict resolution, and staged Local-to-Connect migration). | Phase 1 acceptance gates passed; Pre-Phase 2 decisions (`DEC-07`..`DEC-11`) resolved. |
| **Phase 3** | **Public Marketplace & Online Booking Requests** (SSR Arabic/French venue directory across 69 Wilayas, availability calendar, `booking_requests` submission & owner approval flow, curated provider directory, basic admin ad placements). | Phase 2 acceptance gates passed; Pre-Phase 3 decisions (`DEC-12`..`DEC-14`) resolved. |
| **Phase 4** | **Expansion** (self-serve advertising & lead analytics, provider self-service registration portal, and 360° virtual tours). | Phase 3 live in production; Pre-Phase 4 decisions (`DEC-15`..`DEC-16`) resolved. |
