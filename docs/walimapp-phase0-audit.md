# WalimApp Phase 0 — Independent Review Findings

**Review status:** Phase 0 is promising, but **not approved for Phase 1 specification yet**. This is a document/architecture review, not a code or security audit.

**Reviewed:** `README.md`, `AGENTS.md`, `docs/product-requirements.md`, `docs/architecture.md`, `docs/architecture-review.md`, `docs/decision-register.md`, `docs/roadmap.md`, and `docs/ai-development-workflow.md` from `walimapp-phase0-review.zip`.

**Not available in the review ZIP:** `.specify/memory/constitution.md`, although the completion report says it exists and other documents refer to it. The ZIP also flattened the selected files, so repository-relative paths could not be checked from this archive. The constitution must be included in the next review bundle or reviewed directly in the repo.

## Overall judgement

The baseline is structurally strong: it captures the shared Flutter Android/Windows client, independent Local mode, individually authenticated Connect members, booking-request separation, a modular Laravel backend, server-enforced booking constraints, and staged migration. However, the document set overstates its consistency: the roadmap claims zero contradictions, but the reviewed files contain material mismatches and underspecified safety properties below.

Do not generate another architecture from scratch. Have Gemini 4 Argon correct these specific Phase 0 artifacts, then return the revised Markdown for review. Do not start `/speckit-specify` or application implementation until these blockers are resolved and the Product Owner approves the updated baseline.

---

## P0 — Resolve before approving the architecture baseline

### P0-1. Backup-key recovery design is unsafe as the default
**Files:** `docs/decision-register.md` DEC-06; `docs/product-requirements.md` REQ-LOC-20; `docs/architecture.md` backup/licensing sections.

DEC-06 defaults to deriving a backup-encryption key from the WalimApp license key/activation code, using Argon2id/HKDF, while Super-Admin can re-provide that input. This makes the licensing/recovery secret double as backup encryption material, and implies vendor recovery/decryption capability without a documented threat model, entropy requirements, key separation, customer consent, or key-custody policy. A KDF does not turn a guessable or widely re-issued secret into an independent high-entropy key.

**Required correction:** do not accept Option A as written. Keep DEC-06 open until Argon documents and compares at least:
- user-controlled backup passphrase or random recovery key stored separately from the backup;
- optional explicit recovery escrow using an independently generated random data-encryption key and a separate escrow/wrapping key, if customer support recovery is a deliberate product promise;
- consequences of losing the passphrase/recovery key and exactly who can decrypt the backup.

Separate license activation from backup encryption. State the chosen threat model and UX before implementing `.walimbak` encryption.

### P0-2. License issuance is not included in the Phase 1 plan
**Files:** `docs/architecture.md` §8.1; `docs/roadmap.md` Phase 1/Sprint 1.4; `docs/product-requirements.md` REQ-LOC-22/REQ-ADM-02.

The Phase 1 Local app includes Ed25519 license verification and is described as a perpetual-licensed product, but the private signing key is only held by the server/Super-Admin and the backend/admin platform is deferred to Phase 2. The current Phase 1 roadmap does not specify a secure license-issuance workflow/tool/operator process. Verification alone cannot issue valid licenses.

**Required correction:** choose one explicit path before selling Local:
1. a minimal, offline license-signing tool/process available in Phase 1, secured outside the client and repository; or
2. defer commercial Local activation/sales until the secure issuer is available in Phase 2.

Do not put the private key in the Flutter app, repository, or a customer-facing package. Specify how licenses are issued, backed up, revoked/transferred, and recovered when the device is replaced.

### P0-3. The shared-calendar requirement is not delivered by Phase 1 Local
**Files:** `docs/product-requirements.md` §1.1 and REQ-CON-01..05; `docs/roadmap.md` Phase 1/2.

The documents correctly state that Local is single-device and Connect is multi-user/multi-device. Therefore the early Android APK in Sprint 1.3 will **not** give a family/venue team a shared calendar across phones. That is acceptable for a single-device Local edition or technical pilot, but it does not satisfy the newly identified core team-use case.

**Required correction:** explicitly label Phase 1 as a single-device Local foundation/pilot, not the complete family-shared-calendar product. State that the first release intended to solve shared team scheduling is Connect (Phase 2), unless the Product Owner chooses to pull a minimal connected shared-calendar slice earlier. Preserve individual accounts and venue-scoped roles; do not solve this by sharing a single owner password.

### P0-4. Current technology versions are not genuinely validated
**Files:** `docs/architecture.md` §2; `docs/decision-register.md` ADR-002; `docs/roadmap.md`; `AGENTS.md`.

The baseline fixes Laravel 12 + Filament v4 + Livewire v3 and minimum Flutter 3.27/Dart 3.6. These were not validated by a dependency-resolution run in the reviewed Markdown, and the Flutter minimum is old relative to the current stable release line. As of this review, Laravel's official release table lists Laravel 13 (released March 17, 2026; security fixes through March 17, 2028) and Laravel 12 (security fixes through February 24, 2027). Filament v5 is released and uses Livewire v4/Tailwind v4.1, but package compatibility constraints must be verified rather than assumed; some current Filament v5 package constraints may still limit Laravel support.

Official references:
- Laravel support policy: https://laravel.com/framework/docs/releases
- Filament releases: https://github.com/filamentphp/filament/releases
- Filament v5 installation requirements: https://filamentphp.com/docs/5.x/introduction/installation
- Flutter stable release notes: https://docs.flutter.dev/release/release-notes

**Required correction:** since backend implementation is Phase 2, avoid prematurely pinning a possibly aging backend stack as permanently “validated.” Ask Argon to produce a compatibility matrix with evidence and actual Composer resolution for Laravel/PHP/Filament/Livewire/Tailwind and their needed plugins; select a supported combination at the Phase 2 planning gate. For Flutter, require the current stable SDK when implementation starts, then pin the exact SDK and package lockfile. If the baseline keeps Laravel 12/Filament v4, document why that pair is preferred and when its upgrade/support window will be revisited.

### P0-5. Financial unit terminology contradicts itself
**Files:** `docs/architecture-review.md` Executive Summary and TR-10; `docs/architecture.md` §5.4; `docs/decision-register.md` ADR-009; `docs/product-requirements.md` REQ-LOC-12 and NFR-05.

The PRD, architecture and ADR say amounts are integer **whole DZD** (`amount_dzd BIGINT`), while the architecture review describes “integer minor-unit money (DZD centimes)” and TR-10 names `amount_minor` / DZD centimes. These are different units and can produce a 100x error if implemented inconsistently.

**Required correction:** choose one canonical unit and use it consistently in every doc, DTO, checksum, database column, PDF and test. Based on the current PRD/architecture model, the provisional choice is integer whole DZD; if fractional DZD values are a real business requirement, explicitly choose centimes and specify conversion rules. Remove all contradictory terminology and traceability entries.

### P0-6. “Append-only payments” is not enforced by the described trigger
**Files:** `docs/architecture.md` §5.4; `docs/decision-register.md` ADR-009; `docs/product-requirements.md` REQ-LOC-13.

The architecture says the database trigger rejects updates only when `amount_dzd`, `reservation_id`, or `entry_type` changes (and rejects deletion). Other columns could still be updated, which conflicts with the declared rule that payment rows are immutable once recorded.

**Required correction:** if payments are truly append-only, triggers should reject *all* UPDATE and DELETE operations on payment rows (unless a narrowly specified migration/administrative escape hatch is necessary and audited). Corrections must use refund/adjustment rows with mandatory reason and actor attribution. Add tests proving that no column can be edited after insertion.

### P0-7. Local-to-Connect migration omits required documents/templates from the explicit migration manifest
**Files:** `docs/product-requirements.md` REQ-CON-11..13; `docs/architecture.md` §7.

REQ-CON-11 promises preservation of contract templates and generated documents. The explicit migration dependency order lists venue, halls, slots, customers, reservations, payments and expenses, but does not explicitly include contract templates, generated document metadata, or document binaries/checksums.

**Required correction:** add document/template metadata and a binary-file transfer/verification stage to the migration model, or define and justify exactly how these records are preserved separately. Include their counts, hashes and relationships in the migration manifest and acceptance tests. “100% financial checksum match” alone is not sufficient proof of full migration.

---

## P1 — Correct before implementation of the affected feature

### P1-1. Outbox ordering relies on client timestamps despite clock-skew warning
**File:** `docs/architecture.md` §6.1.

The sync worker sends operations ordered by `created_at`, even though WalimApp explicitly anticipates incorrect client clocks. Equal timestamps and clock skew can violate parent-before-child ordering or replay dependencies in an unexpected order.

**Required correction:** use a monotonically increasing local `outbox_seq` (or equivalent transactionally assigned local ordering), with explicit dependency blocking for parent/child operations. Timestamps can be retained for diagnostics, not correctness. Specify how a dependent operation behaves if its parent is rejected or conflicted.

### P1-2. Delta cursor semantics and role-filtered sync are underspecified
**Files:** `docs/architecture.md` §6.1–6.2; `docs/architecture-review.md` discussion of commit-ordered delta pull; `docs/product-requirements.md` REQ-CON-04.

The architecture describes a venue-scoped cursor (`last_pulled_seq` per `venue_id`) but does not state whether change-log `seq` is allocated per venue or organization, or how allocation is serialized with transaction commits. A plain database sequence can be allocated in one order and committed in another, creating skipped changes if a client advances past an uncommitted earlier event. Also, role-filtered pull omits payment/expense events and masks reservation price fields, but the client cursor can advance past omitted events; a later permission upgrade could then miss old financial records. Applying a partially masked reservation row to the same local canonical record could also erase fields locally.

**Required correction:** define one cursor scope (per-venue or per-organization) and its allocation/commit semantics; guarantee change-log records and domain changes commit atomically and no event can appear behind an already-advanced cursor. Define full re-sync/cursor reset on permission-scope changes or permission-aware projections. Do not apply masked partial rows as full-row overwrites. Test role upgrade/downgrade and membership revocation.

### P1-3. Permission revocation does not address already cached offline data
**Files:** `docs/architecture.md` §4.3 and §10; `docs/product-requirements.md` REQ-CON-03/04/10.

Remote token revocation prevents future online requests, but it cannot instantly delete data already cached on a device that is offline. The baseline promises immediate revocation and local offline data without defining this trade-off.

**Required correction:** document the threat model and realistic guarantee. Define what happens on the next reconnection after membership/device revocation, how sensitive local fields are protected at rest, whether the app disables access/purges data on confirmed revocation, and what offline limitations remain. Do not promise remote erasure of an offline device. Never put customer or financial details in push-notification payloads.

### P1-4. Local database encryption at rest is not reconciled with the privacy requirement
**Files:** `docs/architecture.md` §§4, 10; `docs/product-requirements.md` NFR-04.

The NFR refers to encryption at rest, but the client stack specifies ordinary SQLite/Drift; only `.walimbak` backups are explicitly encrypted. A local PIN hiding screens does not encrypt the database file.

**Required correction:** explicitly decide whether local database encryption is required (e.g. a supported SQLCipher approach) or document a risk-accepted alternative with device/OS protection assumptions. Verify Android and Windows package support, performance, key storage and recovery. Do not state that all personal data is encrypted at rest unless that is implemented and tested.

### P1-5. Android “automatic backup on app backgrounding” is not a reliable guarantee
**Files:** `docs/architecture-review.md` §6.1; `docs/architecture.md` §4.3; `docs/product-requirements.md` REQ-LOC-20.

An Android process can be paused or killed; it is not safe to assume the app can finish a backup asynchronously every time `AppLifecycleState.paused` occurs. A SAF-picked destination also depends on persisted URI permissions and available storage.

**Required correction:** define reliable on-device rolling backup behavior and a user-controlled export/reminder flow for off-device copies. Use a consistent SQLite snapshot that includes committed WAL contents; do not copy only the main database file while WAL is active. Treat background backup as best-effort unless a supported scheduling design is validated on real devices.

### P1-6. Phase gate blocks too much work on decisions not needed yet
**Files:** `docs/decision-register.md` DEC-01..06 resolution gates; `docs/roadmap.md` phase prerequisites.

The roadmap says all DEC-01..06 must be settled before Phase 1 starts, while the decision register gives later deadlines (DEC-03 before Sprint 1.2, DEC-05 before Sprint 1.3, DEC-06 before Sprint 1.4). This is an internal workflow contradiction and can delay harmless foundation work.

**Required correction:** resolve each product decision immediately before its dependent specification/implementation slice. Only decisions that change the initial foundation or schema must block Sprint 1.1. Do not allow an unresolved future backup/PDF detail to block unrelated foundation work; do not implement its affected feature until its decision is settled.

### P1-7. The architecture review's traceability matrix and money references must be regenerated
**Files:** `docs/architecture-review.md` §7 and cross-reference prose.

Several references are inconsistent with the canonical documents—for example TR-10 says centimes while the PRD/architecture use whole DZD, and some prose around trace IDs does not align with the later table's mapping. The claim of “zero contradictions” therefore is not justified yet.

**Required correction:** review all trace IDs and section references mechanically and make every `TR-*` entry point to the correct `REQ-*`, source-draft section, and canonical target. Update the Phase 0 acceptance statement after fixing and verifying the contradictions; do not mark it as complete just because the files were generated.

### P1-8. Repository documentation links are local-machine absolute paths
**Files:** `README.md`, `AGENTS.md`, `docs/*.md`.

Links such as `file:///c:/proj/walimapp/docs/architecture.md` only work on the original Windows path, not in GitHub's rendered Markdown or on another clone.

**Required correction:** use normal repository-relative Markdown links (`docs/architecture.md`, `../reference/...`, etc.) and verify them in the repository. Preserve the existing repo layout.

---

## P2 — Keep visible in backlog / refine during the next affected specification

1. **Performance acceptance:** `< 100ms` for calendar/search is not measurable as written. Define a test dataset, device class, warm/cold cache conditions, and a statistic (e.g., p95) before treating it as a release gate.
2. **Device-bound licensing:** Windows MachineGuid/BIOS/CPU fingerprints and Android ID/Keystore combinations may be brittle and add support burden. Prefer the least-complex device identity that satisfies a documented piracy/licence-transfer policy; handle Android restore/factory-reset and low-cost devices without hardware-backed Keystore support.
3. **Expired Connect renewal:** while subscription expiry leaves every local device writable, multiple devices may diverge and build outboxes during the period without sync. Specify the renewal reconciliation and conflict-resolution path before implementing subscription expiry.
4. **Legal claims:** make ANPDP/counsel review a release gate; treat specific legal interpretations, consent language, retention duties, hosting location and third-party push/storage providers as questions for qualified Algerian legal review. Don't claim compliance from the architecture text alone.
5. **Sensitive identifiers:** make customer NIN/CNI collection optional unless a validated business/legal need exists; define access, purpose, retention, backup and deletion/anonymization effects.
6. **69-Wilaya seed:** use an authoritative, versioned official dataset for Wilaya and commune names/codes. Do not assume that a hardcoded range alone proves the full locality list is accurate.

---

## Phase 0 decision on readiness

**Do not approve Phase 1 specification yet.** Ask Gemini 4 Argon to correct all P0 and P1 items in the existing canonical Markdown only, update the decision register/roadmap where needed, and report evidence for every compatibility or validation claim. No code and no `/speckit-specify` yet.

After the corrections, review the following owner decisions at the relevant feature gates:
- DEC-01: hybrid Android-first pilot but both platforms pass Phase 1 gate — acceptable as default.
- DEC-02: one venue per Local license, with configurable hall limit — confirm the commercial rule.
- DEC-03: expired tentative hold stays visibly blocked until the owner confirms/cancels — sensible default.
- DEC-04: local Owner PIN/restricted local profile — decide if needed for Local sharing on one device.
- DEC-05: selected Arabic/French or bilingual-header PDF templates — sensible default.
- DEC-06: do not accept the license-derived backup-key default; require a redesigned, explicitly chosen recovery model.

The Product Owner should then approve the revised baseline and constitution before Phase 1 begins.
