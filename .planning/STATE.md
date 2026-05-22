---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
current_phase: Phase 1 — App Foundation and Local Pass Model
status: unknown
last_updated: "2026-05-21T13:23:22.760Z"
progress:
  total_phases: 7
  completed_phases: 0
  total_plans: 3
  completed_plans: 0
  percent: 0
---

# State: Coupon Keeper

**Initialized:** 2026-05-21
**Current Phase:** Phase 1 — App Foundation and Local Pass Model
**Workflow Mode:** YOLO
**Granularity:** Standard
**Execution:** Parallel where workstreams are independent

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-21)

**Core value:** 사용자가 잊고 있던 현금성 쿠폰 이미지를 찾아 만료 전에 쓰게 만든다.
**Current focus:** Create a launchable Flutter app shell, local pass model, and base UX structure.

## Phase Status

| Phase | Status | Progress |
|-------|--------|----------|
| 1. App Foundation and Local Pass Model | Pending | 0% |
| 2. Guided Scan Intake | Pending | 0% |
| 3. OCR Candidate Review and Discovery Report | Pending | 0% |
| 4. Wallet, Detail, and Cleanup Flow | Pending | 0% |
| 5. Reminder Engine | Pending | 0% |
| 6. Pro Entitlement and Contextual Gates | Pending | 0% |
| 7. Privacy, Accessibility, Testing, and Release Readiness | Pending | 0% |

## Recent Decisions

- Use guided scan-first permission model.
- Use Flutter with native platform channels.
- Use SQLite plus app-internal image copies.
- Use pass-centric domain model.
- Use Today-first IA with Wallet and Scan tabs.
- Free tier includes D-7 and D-Day reminders.
- Pro gate is contextual, not first-launch.

## Next Command

`$gsd-discuss-phase 1`
