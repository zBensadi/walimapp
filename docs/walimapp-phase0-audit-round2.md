# WalimApp Phase 0 — Independent Review of Corrected Baseline (Round 2)

**Review date:** 2026-10-29  
**Scope:** The latest uploaded Phase 0 review bundle: product requirements, consolidated architecture, architecture review, decision register, roadmap, AI development workflow, constitution, AGENTS, README, and original requirements input.  
**Recommendation:** **Conditionally approve after a focused correction round. Do not start Phase 1 specification yet.** The baseline is materially improved, but several consequential implementation contradictions remain.

## Executive summary

The revised documents correctly establish the major product boundaries: one Flutter codebase for Android and Windows; single-device Local versus synchronized Connect; separate `booking_requests` and `reservations`; a private GitHub repository; phased Spec Kit gates; staged migration; and explicit handling of booking conflicts.

I found these items that should be fixed before implementation:

1. The constitution says it is **ratified**, even though the Phase 0 documents are still awaiting product-owner approval.
2. The SQLCipher dependency recipe is stale/ambiguous for the current `sqlite3`/Drift 3.x ecosystem.
3. The local `payments` table is defined as impossible to delete, while Connect role downgrade/revocation requires deleting restricted cached payment data.
4. The sync protocol does not fully specify filtered-delta cursor advancement, and its operation-idempotency description checks for an existing operation before rechecking current mutation/read authorization.
5. Migration describes object-storage promotion as part of one PostgreSQL transaction and does not adequately handle a commit that succeeds server-side but whose response is lost.
6. Local payment actor attribution is not reconciled with the single-device Local model's missing individual user/profile model.
7. DEC-01's recommended sequencing is still the full Local-first plan even though the product owner identified a multi-phone shared calendar as a central market need; its alternative leaves the later ordering of Local Sprint 1.4 unclear.
8. DEC-02 uses a five-hall cap as the default, although hall licensing/pricing has not been validated and the options do not separate venue count from hall count.

These items do **not** justify another complete architecture. Ask Gemini Argon to correct the specified existing files only, then consider Sonnet's independent audit of that corrected revision.

---

## P0 — Resolve before starting the first Spec Kit feature

### P0-1. Constitution claims Product Owner ratification prematurely

**Affected:** `.specify/memory/constitution.md` (version footer), `README.md`, `docs/architecture.md`, `docs/roadmap.md`.

The constitution footer says `Ratified: 2026-10-29`, and the architecture calls itself a canonical baseline. However, the workflow and roadmap say Phase 0 is waiting for Product Owner review/approval. The product owner has not yet explicitly approved the baseline.

**Risk:** Agents may treat a draft as a formally approved governance authority, contradicting the mandatory human approval gate.

**Correction:** Mark the constitution and baseline as `Draft for Product Owner Review` (or equivalent); remove the ratification date until the owner explicitly approves. After approval, make a separate approval/ratification commit. No need to weaken the constitution's proposed rules.

### P0-2. Resolve DEC-01 and clarify the roadmap sequencing before Sprint 1.1

**Affected:** `docs/decision-register.md` DEC-01; `docs/roadmap.md` Sections 1–3; `docs/product-requirements.md` phase summary.

The current recommended default completes all four Local sprints before Connect. But the Product Owner's market discovery says many venue owners work from phones and multiple family members need the same shared calendar. That makes multi-user Connect a core value proposition, not merely an advanced feature.

Option B says Phase 2 may be pulled forward after Phase 1 Sprints 1.1–1.3, but does not clearly state when Sprint 1.4 (backup/licensing/productization) resumes, whether the single-device APK is an internal pilot or a paid release, or what the first sellable release is.

**Recommended correction:** Keep the Local database/domain foundation and core offline booking/ledger slices first, then pull the Connect shared-calendar slice forward after that foundation is stable. Explicitly mark the Android single-device build as a pilot, not the promised multi-user solution; show where Local backup/licence productization occurs relative to Connect. Rework the milestones so this sequencing is clear rather than describing phases as a strict waterfall.

**Product-owner approval required:** Adopt DEC-01 Option B with the clarified schedule, or consciously choose Option A knowing it delays the shared-team workflow.

### P0-3. DEC-02 couples two different licensing decisions and prematurely defaults to five halls

**Affected:** `docs/decision-register.md` DEC-02; `docs/architecture.md` §8.1 license payload; `docs/product-requirements.md` §1.1.

The decision asks whether Local supports one venue or multiple venues, but its proposed default also hardcodes `max_halls = 5`. The license example includes `max_halls: 5`. There is no validated pricing rationale for this cap, and physical-venue count and hall count are separate commercial decisions.

**Correction:** Define the baseline as one physical venue per Local license with multiple halls, and do not impose a five-hall cap in the data model unless the product owner confirms a commercial reason. If a commercial limit is later chosen, make it configurable in the signed entitlement and validate it consistently. Add a separate option if a limit is truly intended.

**Product-owner approval required:** Confirm one physical venue per Local licence. The five-hall cap should remain unapproved until pricing is validated.

---

## P1 — Fix before the affected implementation slice

### P1-1. SQLCipher dependency instructions are outdated/ambiguous

**Affected:** `docs/architecture.md` §2.1 and §10.2; `docs/product-requirements.md` NFR-04; `.specify/memory/constitution.md` Stack Baseline; `AGENTS.md`.

The docs prescribe `sqlcipher_flutter_libs` alongside a broad `Drift 2.22+` range and current stable Flutter/Dart. Current upstream guidance says that after moving to `package:sqlite3` 3.x, `sqlcipher_flutter_libs` should no longer be used; package `0.7.0+eol` is marked as no longer functional. Drift 2.32.0 also moved to sqlite3 3.x and its encryption documentation describes selecting SQLCipher through the sqlite3 build hook.

This does not mean SQLCipher itself is unsuitable; it means the exact packaging recipe in the canonical docs can be wrong depending on the versions chosen.

**Correction:** Replace the blanket `sqlcipher_flutter_libs` prescription with a verified, version-specific choice. Prefer the supported current `package:sqlite3` SQLCipher build-hook path if it resolves and builds for both Android and Windows; otherwise explicitly pin a compatible older Drift/sqlite3/lib set and document its support rationale. Add a tiny early proof-of-technology test that opens the DB with a key, verifies a wrong key fails, verifies the file is not readable as plaintext SQLite, and builds/runs on both targets. Pin the exact compatible package versions and check the SQLCipher licensing/notice obligations at Sprint 1.1.

Official references:
- https://pub.dev/packages/sqlcipher_flutter_libs
- https://github.com/simolus3/sqlite3.dart/blob/main/UPGRADING_TO_V3.md
- https://github.com/simolus3/drift/blob/develop/docs/content/platforms/encryption.md

### P1-2. Financial immutability conflicts with required local cache purging

**Affected:** `docs/architecture.md` §§5.4, 6.2, 10.1; `docs/product-requirements.md` REQ-CON-03/04; `.specify/memory/constitution.md` Principles I and IV; `docs/roadmap.md` Phase 2 acceptance tests.

The documents require unconditional local SQLite `BEFORE UPDATE OR DELETE ON payments` triggers, but also require a downgraded/revoked staff device to delete/purge local `payments` rows on the next reconnection. An ordinary `DELETE FROM payments ...` will be rejected by the same trigger. The current architecture does not define a compatible purge mechanism.

**Correction:** Explicitly separate the immutability guarantee for authoritative financial ledger entries from secure removal of data a device is no longer authorized to retain. Choose and document a safe mechanism before implementing Connect—for example, per-venue encrypted storage/key separation with crypto-erasure, or a controlled full venue-cache rebuild/replacement that cannot accidentally delete authoritative server records and safely preserves/reconciles local outbox operations. Do not simply weaken the append-only trigger without documenting its security/data-integrity implications. Add tests for role downgrade and device revocation on a populated DB.

### P1-3. Sync delta cursor semantics under permission filtering are incomplete

**Affected:** `docs/architecture.md` §6.2; `docs/product-requirements.md` REQ-CON-04/08; `docs/decision-register.md` ADR-010; Constitution Principle IV.

The server omits financial `sync_change_log` entries for users without finance permission, but the specification does not fully state which sequence value the response advances to when all or some entries are filtered. If the client advances only to the last returned event, a run of filtered events can cause repeated pulls or a stalled cursor. If it advances to the global latest sequence without respecting pagination boundaries, it could skip allowed events.

**Correction:** Specify a precise response cursor/high-water-mark contract: the cursor advances through the range actually scanned, including intentionally filtered entries, but never beyond unscanned pages. Define behavior for an empty visible result, page limits, change-log retention, full snapshots after permission changes, and stale cursors. Add tests where a non-financial user receives only filtered events, receives mixed allowed/filtered events, and changes roles while pagination is in progress.

### P1-4. Idempotency replay must not bypass current authorization

**Affected:** `docs/architecture.md` §6.1 and API/sync security details; `docs/decision-register.md` ADR-010.

The push sequence says to check `sync_processed_operations` first and immediately return the saved result when the `operation_id` already exists, before verifying current venue membership and financial permissions. If the membership has been revoked or downgraded since the original operation, the saved `result_json` could disclose data or action results to a caller who no longer has permission. The operation ID also needs to be bound to the original payload so that reusing an ID with a different payload is not treated as a valid retry.

**Correction:** Recheck current authentication, venue membership, and authorization before returning any stored operation result. Persist a canonical payload hash alongside the idempotency key; an identical retry returns an appropriately authorized result, while the same ID with a different hash is rejected and audited. Document transaction boundaries for idempotency reservation, mutation, change-log entry, and result persistence.

### P1-5. Migration cannot atomically commit PostgreSQL rows and object-storage moves

**Affected:** `docs/architecture.md` §7; `docs/product-requirements.md` REQ-CON-11/12/13; `docs/decision-register.md` ADR-011; roadmap Phase 2 Sprint 2.4.

The migration text says live rows are inserted, staged S3/R2 document keys are promoted to permanent tenant paths, and change-log entries are written "in a single transaction." A PostgreSQL transaction cannot roll back arbitrary object-storage copy/move operations. In addition, if the database transaction commits but the HTTP response is lost, the client might unlock Local mode while the server has already promoted the migration, unless commit retry/status behavior is idempotent.

**Correction:** Keep staging objects immutable and make the database transaction switch authoritative metadata/references, or define an idempotent object-promotion saga with retries and orphan cleanup. Persist migration-session states (including `committed`) and the resulting initial cursor/receipt so a retry after a lost response returns the existing result rather than repeating promotion. On ambiguous client failure, query migration-session state before unlocking Local mode. Add failure-injection tests for object copy failures, DB commit failure, and response loss after a successful commit.

### P1-6. Local payment actor attribution is not modeled

**Affected:** `docs/architecture.md` §§5.4 and 8.1; `docs/product-requirements.md` REQ-LOC-13 and REQ-CON-01; `docs/decision-register.md` ADR-009/ADR-013.

The `payments` model requires `recorded_by_user_id`/actor attribution for audit and adjustments, but WalimApp Local is single-device and the proposed Local Owner PIN only gates sensitive screens; it does not establish a local user/profile identity. The migration mapping from a Local actor to Connect membership is therefore unspecified.

**Correction:** Define a local actor identity independent of server users (at minimum a default Local Owner actor; optionally named local profiles if per-person attribution is required). Define how Local actor IDs and audit history map during Local-to-Connect migration. Do not invent Connect user IDs before the account exists. Ensure adjustment reasons and actors survive migration.

### P1-7. Migration's object manifest should explicitly cover all binary assets

**Affected:** `docs/architecture.md` §7; `docs/product-requirements.md` REQ-CON-11/12.

The migration text calls out generated PDFs and the venue logo, but the formal manifest description is centered on `generated_documents`; the media/logo manifest and verification obligations are not consistently enumerated. Before implementation, the complete manifest must represent every asset that Local can create/store, with bytes, type, ownership, and checksum.

**Correction:** Explicitly manifest venue logos and every document/media binary separately from relational rows; define absent-file, duplicate-file, corrupt-file, and retry semantics. If arbitrary local media is not part of Phase 1, state that clearly.

### P1-8. Verify platform storage wording and cryptographic build behavior

**Affected:** `docs/architecture.md` §4.3 and §10.2; NFR-04.

The text describes Windows DPAPI as part of an "OS hardware-backed keystore." DPAPI is OS-protected storage but is not inherently equivalent to a hardware-backed Android Keystore/TEE. Also, the SQLCipher runtime must fail closed if the selected native library is not actually SQLCipher; it must not silently create an unencrypted database.

**Correction:** Use accurate platform-specific language (OS-protected credentials; hardware-backed only when the OS confirms it). Require a runtime cipher-capability check before creating/opening any database and a release test that confirms SQLCipher is active on Android and Windows. Document key loss/recovery behavior.

### P1-9. Local licensing signer must define its hardware-key interface before it is built

**Affected:** `docs/architecture.md` §8.1; `docs/product-requirements.md` REQ-LOC-22; roadmap Sprint 1.4.

The CLI plan suggests a hardware token, OS keystore, or encrypted vault and says the private key is "passed at signing time." These are not interchangeable: hardware tokens/OS key stores may offer signing APIs without exporting private key bytes. The CLI cannot simultaneously assume key export and claim a non-exportable key.

**Correction:** Keep the implementation choice open until Sprint 1.4, but require the issuer interface to support either an explicit sign operation backed by a non-exportable key or a documented secure offline key file/vault. Do not export private key material by default. Test key custody, signature verification, transfer/audit records, and recovery before issuing customer licences.

---

## P2 — Safe to resolve during the relevant feature specification

### P2-1. Arabic PDF shaping/printing must be proven early

**Affected:** `docs/architecture.md` §§4.3/tech stack; `docs/product-requirements.md` REQ-LOC-17/19; roadmap Sprint 1.3.

The architecture assumes `pdf`/`printing` will reliably render Arabic RTL contracts and receipts on Android and Windows. Keep this as a required proof-of-technology, not a guarantee. Before implementing full templates, create a minimal bilingual PDF sample with Arabic joined letter shaping, punctuation, dates, Western digits, mixed Arabic/Latin fields, wrapping, pagination and printing/sharing on both platforms. If the chosen PDF renderer cannot do this correctly, choose a tested shaping approach before building the document system.

### P2-2. The Wilaya/commune data claim is plausible, but the actual dataset is not in Phase 0

**Affected:** `docs/product-requirements.md` REQ-LOC-04/REQ-MKT-02; `docs/architecture.md` §5.1; ADR-005.

The revised documents correctly target 69 Wilayas and 1,541 communes. The official 2026 territorial-law announcement confirms those counts. However, the actual promised `data/algeria_69_wilayas_communes_v1.json` is not included in this documentation bundle and does not yet appear to have been quality-checked as a deliverable.

**Correction:** Before using it in Phase 1, obtain the actual authoritative list, check codes/names/commune parentage and language variants, record source/version/checksum, and review redistribution rights. Do not fabricate missing commune names from memory or a random third-party list.

### P2-3. Clarify Local license limits as entitlements, not schema constraints

**Affected:** `docs/architecture.md` §8.1; `docs/decision-register.md` DEC-02.

Avoid hard-coding `max_halls = 5` into the domain schema or seed data. If approved later, it should be a signed licence entitlement enforced by domain policy, not a limit that forces schema redesign. The Local schema should support a venue's actual hall count.

### P2-4. Keep external notifications and legal jurisdiction as production gates

**Affected:** `docs/architecture.md` §10.1/§10.2; `docs/decision-register.md` DEC-10/11.

The use of FCM and object storage is described, but product-owner approval and legal review remain outstanding. Keep zero-PII push payloads, define offline fallback, and don't configure a production third-party processor or hosting region until the appropriate review/authorization is completed.

---

## Product-owner decisions to record

1. **DEC-01:** I recommend Option B, with clarified sequencing: build the offline client foundation and core calendar/ledger; deliver the multi-user Connect calendar earlier because it addresses the observed family/team workflow; complete Local packaging/licensing/backups at a clearly identified point. A single-device pilot is not the same as the first full commercial release.
2. **DEC-02:** I recommend one physical venue per Local licence, with multiple halls and **no arbitrary five-hall cap until a pricing decision supports one**. Decide a licensed cap later if needed.
3. **DEC-06:** Option A (owner passphrase plus independent printable recovery key; no vendor escrow) is a defensible default, but the owner must understand that loss of both credentials makes backups unrecoverable. This can remain open until Sprint 1.4.
4. **DEC-04:** Decide whether Local truly needs a local Owner PIN before the sensitive settings/reports feature is implemented; it need not block the base project shell.

---

## Official technical references checked

- SQLCipher Flutter libraries package status: https://pub.dev/packages/sqlcipher_flutter_libs
- sqlite3 3.x upgrade guidance: https://github.com/simolus3/sqlite3.dart/blob/main/UPGRADING_TO_V3.md
- Drift encryption documentation: https://github.com/simolus3/drift/blob/develop/docs/content/platforms/encryption.md
- Current Flutter release changelog/security release: https://github.com/flutter/flutter/blob/master/CHANGELOG.md
- Algerian new territorial division announcement (69 Wilayas and 1,541 communes): https://www.aps.dz/algerie/actualite-nationale/mnn28aig-%D8%B5%D8%AF%D9%88%D8%B1-%D8%A7%D9%84%D9%82%D8%A7%D9%86%D9%88%D9%86-%D8%A7%D9%84%D9%85%D8%AA%D8%B9%D9%84%D9%82-%D8%A8%D8%A7%D9%84%D8%AA%D9%86%D8%B8%D9%8A%D9%85-%D8%A7%D9%84%D8%A5%D9%82%D9%84%D9%8A%D9%85%D9%8A-%D8%A7%D9%84%D8%AC%D8%AF%D9%8A%D8%AF-%D9%84%D9%84%D8%AC%D8%B2%D8%A7%D8%A6%D8%B1

## Final decision

**Do not start `/speckit-specify` yet.** Ask Gemini Argon for one targeted Phase 0.2 correction round against P0/P1 findings, update only the existing canonical documents, leave code untouched, and produce a findings-to-resolution report. Then run Claude Sonnet's independent audit against that corrected revision (not the old architecture draft). After the final review, approve Phase 0 and start the first small specification.
