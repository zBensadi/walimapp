---
name: Bug Report / Audit Finding
about: Report a defect, data-integrity risk, sync conflict issue, or RTL/LTR regression
title: "[BUG] "
labels: ["bug"]
---

## 1. Component & Environment
- **Component:** `WalimApp Local | WalimApp Connect | Public Marketplace | Super-Admin`
- **Platform:** `Android (API/Device) | Windows (10/11) | Web Browser | Server`
- **Connectivity State:** `Offline | Online | Flaky / Reconnecting`
- **Locale:** `ar-DZ (RTL) | fr-DZ (LTR)`

## 2. Severity & Constitution Impact
- [ ] Impacts financial ledger (`payments` / `expenses`)
- [ ] Impacts slot overlap / double-booking prevention (`reservations` / `booking_requests`)
- [ ] Impacts Local-to-Connect migration or `.walimbak` backup/restore
- [ ] Impacts tenant isolation or employee RBAC
- [ ] Impacts perpetual license or offline operation

## 3. Steps to Reproduce
1. 
2. 
3. 

## 4. Expected vs. Actual Behavior
- **Expected:** 
- **Actual:** 

## 5. Regression Test Plan
Describe the automated unit/integration test that will prevent this bug from recurring.
