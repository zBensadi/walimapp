## Summary

- **Phase & Sprint / Slice:** `e.g., Phase 1 — Sprint 1.1`
- **Spec Kit Feature Path:** `specs/<NNN-feature-name>/`
- **Related Requirement IDs:** `REQ-...`
- **Related Decision IDs:** `ADR-... / DEC-...`

## Changes Included

- 

## Constitution & Architecture Compliance Checklist

- [ ] **Review Gates Respected:** Both Spec Kit Gate 1 (`spec.md`) and Gate 2 (`plan.md` / `tasks.md` / `/speckit-analyze`) were approved by the Product Owner before implementation.
- [ ] **Shared Android & Windows Codebase:** Domain, Drift/SQLite, sync, auth, and business rules are shared in `apps/owner`; adaptive layouts (`< 600dp` Android touch vs `>= 600dp` Windows desktop) and platform adapters are respected.
- [ ] **Data Safety & Immutable Ledger:** No `UPDATE` or `DELETE` paths introduced on recorded `payments`; all monetary values use integer `DZD` (`BIGINT`).
- [ ] **Booking Integrity:** `booking_requests` remain strictly separate from `reservations`; `pending_sync` is a client overlay and does not overwrite reservation domain status.
- [ ] **69-Wilaya & Bilingual Support:** Location logic uses the data-driven 69-Wilaya schema; UI/PDF changes support both `ar-DZ` (RTL) and `fr-DZ` (LTR) with Western numerals (`0-9`).
- [ ] **Server-Side Security:** Multi-tenant (`organization_id`, `venue_id`) and role permissions are enforced on the server, not only in the client UI.
- [ ] **Zero Secrets Committed:** Verified no `.env`, private keys (`*.pem`, `*.key`), `.walimlic`, `.walimbak`, or local SQLite `.db` files are staged.

## Verification & Test Outcomes

- [ ] Static analysis passed (`flutter analyze` / `phpstan` / `pint`)
- [ ] Automated unit & integration tests passed (`flutter test` / `php artisan test`)
- [ ] `/speckit-converge` executed with 0 unresolved tasks
