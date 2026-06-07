# Roadmap: Coupon Keeper

**Created:** 2026-05-21
**Last updated:** 2026-06-07 after v1.0 milestone completion
**Core Value:** 사용자가 잊고 있던 현금성 쿠폰 이미지를 찾아 만료 전에 쓰게 만든다.

## Milestones

- ✅ **v1.0 MVP** — local-only coupon wallet with guided scan, OCR review, Wallet, reminders, Pro gates, and release-readiness verification. Shipped 2026-06-07. See `.planning/milestones/v1.0-ROADMAP.md`.
- 📋 **v1.1 Next** — not planned yet. Start with `$gsd-new-milestone`.

## Completed

<details>
<summary>✅ v1.0 MVP (Phases 1-7 plus inserted Phase 3.1) — SHIPPED 2026-06-07</summary>

- [x] Phase 1: App Foundation and Local Pass Model — app shell, pass model, repository contracts, reusable UI states
- [x] Phase 2: Guided Scan Intake — selected-source entry, progress/cancel, duplicate skipping, recovery states
- [x] Phase 3: OCR Candidate Review and Discovery Report — on-device OCR adapters, discovery report, review/edit/reject/manual registration
- [x] Phase 3.1: Close gap: production local adapter wiring — SQLite, durable image copies, native pickers, production default composition
- [x] Phase 4: Wallet, Detail, and Cleanup Flow — Wallet filters, detail, image/barcode expansion, used/cleanup/source-missing flows
- [x] Phase 5: Reminder Engine — free/Pro local reminder rules, save/status sync, launch/resume reconciliation
- [x] Phase 6: Pro Entitlement and Contextual Gates — official IAP gateway, purchase/restore, local entitlement cache, contextual gates
- [x] Phase 7: Privacy, Accessibility, Testing, and Release Readiness — privacy/accessibility checks, Android appbundle, iOS no-codesign release build

</details>

## Progress

| Milestone | Status | Requirements | Verification |
|-----------|--------|--------------|--------------|
| v1.0 MVP | Shipped | 44/44 complete | `flutter analyze`, `flutter test` 126/126, Android appbundle, iOS no-codesign build passed |

## Next

Run `$gsd-new-milestone` to define v1.1 requirements and roadmap. Candidate directions are tracked in `.planning/PROJECT.md` and the archived `.planning/milestones/v1.0-REQUIREMENTS.md`.
