# WalimApp --- Product Requirements Document

**Status:** Initial draft for architecture design\
**Product:** WalimApp\
**Initial market:** Algeria\
**Development approach:** Clean-slate development, incremental delivery,
AI-assisted implementation

## 1. Product vision

WalimApp is a wedding venue management and discovery platform designed
for the Algerian market. It combines offline-capable management software
for wedding venue owners with an online marketplace where customers can
discover venues and related service providers.

The product consists of four components:

1.  **WalimApp Local:** Standalone offline-first owner application.
2.  **WalimApp Connect:** Connected owner application with
    synchronization and online services.
3.  **Public marketplace:** Website for discovering venues and related
    providers.
4.  **Super-admin platform:** Internal management and administration
    interface.

The Local edition must be commercially usable independently of the
online platform.

## 2. User types

-   Venue owners managing one or more wedding venues.
-   Venue employees with restricted permissions.
-   Customers searching for wedding venues and submitting booking
    requests.
-   Service providers such as decorators, caterers, florists,
    photographers, and car rental businesses.
-   WalimApp staff and administrators managing the platform.

The architecture must support multiple organizations and strict
separation of their data.

## 3. WalimApp Local

### Purpose

Provide wedding venue owners with a reliable management application that
works without an internet connection.

### Functional requirements

The application should support:

-   Managing venues and halls.
-   Managing customers and their contact details.
-   Creating, editing, and tracking reservations.
-   Viewing reservations through a calendar.
-   Recording deposits, outstanding balances, and relevant financial
    transactions.
-   Managing expenses and generating financial reports.
-   Creating, storing, and retrieving contracts and related documents.
-   Backing up and restoring application data.
-   Managing basic application settings.

### Offline requirements

-   The application must work without internet access.
-   Business data must be stored locally in SQLite.
-   The initial target is a Windows desktop application built with
    Flutter.
-   The application runs on one device; local-network synchronization is
    not required.
-   Cloud connectivity must not be required for ordinary Local
    operations.
-   Owners may continue using Local without subscribing to Connect.
-   The application must not publish the owner's venue or accept online
    booking requests in Local-only mode.

### Licensing requirements

-   Local is sold under a perpetual license.
-   Expiration of optional maintenance or updates must not disable the
    purchased version or destroy its data.
-   An offline license activation and recovery strategy is required.
-   The product should support a future upgrade to Connect without
    losing existing records.

## 4. WalimApp Connect

### Purpose

Provide owners with online services while preserving the offline-first
experience of the owner application.

### Functional requirements

Connect should support the Local management capabilities, plus:

-   Online venue profiles and public listings.
-   Publishing and updating venue information.
-   Managing services and venue availability.
-   Receiving and processing online booking requests.
-   Notifications about booking requests and relevant changes.
-   Synchronizing owner data with the central platform.
-   Managing multiple venues under an owner or organization.
-   Supporting employees with permissions scoped to their assigned
    organization and, where applicable, specific venues.

### Offline and synchronization requirements

-   SQLite remains the local persistence layer for the owner
    application.
-   A central backend and database maintain the authoritative shared
    online state.
-   Offline operations must be queued and synchronized when connectivity
    returns.
-   Synchronization must tolerate retries, duplicate submissions, and
    intermittent connectivity.
-   Records must have stable identifiers and appropriate synchronization
    metadata.
-   The system must detect and handle conflicting changes explicitly.
-   Synchronization must never blindly overwrite an existing confirmed
    reservation.
-   Failed or conflicting operations must be reported clearly and allow
    appropriate resolution.
-   Migration from Local to Connect must preserve customers,
    reservations, financial history, and available documents.

The precise conflict-resolution protocol and the treatment of offline
bookings must be designed before implementation.

## 5. Online booking workflow

Customers must be able to submit a booking request for a venue and date.

The initial booking lifecycle includes:

-   `pending_owner_approval`: A customer has submitted a request, and
    the owner has not yet decided.
-   `pending_sync`: An owner operation is waiting for server
    synchronization and validation.
-   `confirmed`: The booking has been approved and committed by the
    authoritative backend.
-   Rejected and cancelled states, with appropriate history, must also
    be supported.

Important rules:

-   Selecting an available date does not automatically confirm a
    reservation.
-   Online requests remain pending until the owner approves or rejects
    them.
-   The backend must validate availability and prevent conflicting
    confirmed bookings.
-   Concurrent requests and synchronization conflicts must be handled
    safely.
-   The system must define whether pending requests temporarily hold
    dates, whether holds expire, and how overlapping requests are
    presented to owners.

These unresolved booking rules must be explicitly identified during
architecture design rather than silently assumed.

## 6. Public marketplace

### Purpose

Enable customers to discover wedding venues and related services.

### Initial functionality

The public website should support:

-   Searching and filtering venues by Wilaya, date, price, capacity,
    location, and relevant services.
-   Viewing venue profiles, descriptions, photographs, contact
    information, and available facilities.
-   Displaying availability information where reliable data is
    available.
-   Submitting online booking requests.
-   Contacting venue owners, including through WhatsApp where
    appropriate.
-   Discovering related service providers.

The website should be designed for mobile responsiveness, Arabic and
French localization, and search-engine visibility.

### Service-provider directory

The initial directory may be curated by WalimApp staff.

Provider profiles may include:

-   Business or provider name.
-   Service category.
-   Wilaya and service area.
-   Description and photographs.
-   Contact information and social links.

Provider self-registration and profile editing can be introduced later.

### Sponsored listings and advertising

WalimApp should support paid promotional placements for providers.

Requirements include:

-   Featured listings and reserved banner placements.
-   Campaign records with advertiser, placement, start and end dates,
    pricing, and status.
-   Clear identification of sponsored content.
-   Administrative control over campaign creation and publication.
-   A design that accommodates advertising without displaying
    unattractive empty advertising blocks.

Google Ads integration is not a requirement for the initial advertising
model.

## 7. Virtual tours

The platform should eventually support interactive virtual tours of
wedding venues.

The initial approach should prioritize 360-degree panoramic tours rather
than requiring a full 3D digital twin.

Requirements:

-   Venue owners can capture or obtain their own panoramas and upload
    them remotely.
-   Owners can organize panoramas into scenes, such as the main hall,
    entrance, stage, or garden.
-   Scenes can be connected through interactive navigation points.
-   Owners can preview and submit tours for publication.
-   Published tours can be displayed on public venue profiles.
-   The system must validate supported media formats and manage storage
    and access appropriately.

A separate capture application is not required initially. Virtual tours
must not block the first marketplace release.

## 8. Super-admin platform

Authorized WalimApp staff must be able to manage:

-   Organizations, owners, employees, and venues.
-   Public listings and approval workflows.
-   Provider categories and directory entries.
-   Booking oversight and relevant support cases.
-   User roles and permissions.
-   Sponsored listings and advertising campaigns.
-   Local license issuance and Connect subscriptions.
-   Reports and platform configuration.

Sensitive administrative operations must be permission-controlled and
auditable. Broad administrative access must not mean that every staff
member automatically has unrestricted access.

## 9. Commercial model

### WalimApp Local

-   One-time purchase with a perpetual license.
-   Optional paid maintenance, support, and updates.
-   The purchased version remains usable after optional maintenance
    expires.

### WalimApp Connect

-   Recurring subscription, with monthly and annual options considered.
-   Subscription provides online services, synchronization, public
    listing, and online booking functionality.
-   Expiration must be handled gracefully.
-   Appropriate data preservation and export access must be provided.
-   Existing Local data must remain available if Connect access expires.

Pricing is not finalized and must be validated with prospective
customers.

## 10. Technology preferences and constraints

The preferred initial technology direction is:

-   Laravel for the central backend and REST API.
-   PostgreSQL for central data.
-   Filament for internal administration.
-   Flutter for the owner application and potentially a customer mobile
    application.
-   SQLite for the offline owner application.
-   A suitable SEO-friendly public website.

These are proposed preferences, not permission to ignore significant
technical issues. The architect should evaluate the choices and document
trade-offs.

Prefer a maintainable modular monolith over unnecessary microservices.
Do not introduce infrastructure such as Kubernetes, Redis, or other
operational dependencies without a demonstrated need.

## 11. Security, privacy, and localization

-   Enforce organization and venue access restrictions on the server for
    every protected operation.
-   Do not rely on frontend visibility or client-side checks as the
    authorization boundary.
-   Protect authentication credentials, financial records, personal
    information, and uploaded documents.
-   Record important security-sensitive administrative actions.
-   Support Arabic and French, including appropriate interface
    localization.
-   Evaluate applicable Algerian personal-data protection legislation
    and cross-border data-transfer requirements before choosing hosting
    and external service providers.
-   Define backup, restoration, data retention, and account/subscription
    expiry policies.

## 12. Delivery priorities

### First milestone: Local MVP

Build a reliable offline-capable owner application with the essential
reservation, customer, calendar, financial, document, and backup
workflows.

### Second milestone: Connect foundation

Add the backend, authentication, organization and venue permissions,
synchronization, and Local-to-Connect migration.

### Third milestone: Online marketplace

Introduce public venue profiles, search, booking requests, and owner
approval workflows.

### Fourth milestone: Expansion

Add provider self-service, advertising management improvements, virtual
tours, and further enhancements.

The exact order may be refined during architecture planning, but the
Local edition must not depend on completion of the entire platform.

## 13. Architecture deliverables

The architecture should document:

-   System boundaries and component responsibilities.
-   Domain model and database relationships.
-   API contracts and authentication strategy.
-   Offline storage and synchronization protocol.
-   Booking concurrency and conflict resolution.
-   Multi-tenancy and authorization.
-   Licensing, subscriptions, and migration.
-   Media storage and virtual tours.
-   Deployment, backup, recovery, monitoring, and testing.
-   Security risks, assumptions, unresolved decisions, and
    implementation phases.

Clearly distinguish confirmed product requirements from assumptions and
recommendations. Do not treat unresolved business decisions as settled
requirements.
