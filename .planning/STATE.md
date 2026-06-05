---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
current_phase: 4
status: phase-4-barcode-cleanup-slice-complete
last_updated: "2026-06-05T23:32:00.000+09:00"
progress:
  total_phases: 8
  completed_phases: 3
  total_plans: 15
  completed_plans: 15
  percent: 38
---

# State: Coupon Keeper

**Initialized:** 2026-05-21
**Current Phase:** 4
**Workflow Mode:** YOLO
**Granularity:** MVP Light
**Execution:** Parallel where workstreams are independent

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-21)

**Core value:** 사용자가 잊고 있던 현금성 쿠폰 이미지를 찾아 만료 전에 쓰게 만든다.
**Current focus:** Phase 4 Wallet, Detail, and Cleanup Flow — next slice: source cleanup handoff and missing-source recovery

## Phase Status

| Phase | Status | Progress |
|-------|--------|----------|
| 1. App Foundation and Local Pass Model | UAT Pass, iOS Env Follow-up | 100% implementation, 6/6 UAT checks passed on Android |
| 2. Guided Scan Intake | UAT Pass | 5/5 plans complete; 6/6 UAT checks passed on Android; `flutter analyze` passed; `flutter test` passed 37/37 |
| 3. OCR Candidate Review and Discovery Report | UAT Pass, Security Pass, Nyquist Pass, iOS Env Follow-up | 4/4 plans complete; Android conversational UAT passed 7/7; security threats closed 12/12; 7/7 requirements covered; `flutter analyze` passed; `flutter test` passed 67/67 |
| 3.1. Close gap: production local adapter wiring | UAT Pass, Security Pass | 3/3 plans complete; Android conversational UAT passed 6/6 after fixing single-expiry review readiness; security threats closed 9/9; `flutter analyze` passed; `flutter test` passed 93/93; Android debug APK build passed |
| 4. Wallet, Detail, and Cleanup Flow | In Progress | Wallet list/detail/use-complete complete; barcode/image expansion and cleanup candidate state complete; `flutter analyze`, `flutter test` 94/94, Android debug APK build, and emulator smoke passed |
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

## Environment Notes

- Android toolchain blocker was remediated: cmdline-tools installed, SDK licenses accepted, Android SDK 36/build tools available, Flutter/sdkmanager PATH added to `/Users/sora/.zshrc`, the full Pixel_8_API_33 AVD data partition was wiped, and Coupon Keeper passed visual UAT on `emulator-5554`.
- iOS simulator launch remains blocked outside app code on macOS 26.5 with Xcode 16.1: Xcode/CoreSimulator fails to spawn `AssetCatalogSimulatorAgent`, and system logs show AMFI library validation/code signature rejection for the Xcode tool binary.

## MVP Light Workflow

Coupon Keeper는 MVP 완성 속도를 높이기 위해 기본 GSD 운영을 가볍게 전환했다.

기본 흐름:

1. 다음으로 가치가 큰 phase 또는 gap을 고른다.
2. 필요한 컨텍스트만 짧게 확인한다.
3. 구현, `flutter analyze`, 관련 테스트, Android debug build/UAT를 진행한다.
4. 작업 단위가 완료되면 커밋하고 현재 브랜치를 push한다.

조건부로만 실행:

- `$gsd-secure-phase`: 권한, 저장소, 결제, 로그인, 네트워크, 개인정보 경계가 바뀔 때.
- `$gsd-validate-phase`: milestone 종료 전, 또는 테스트/요구사항 커버리지 gap이 의심될 때.
- `$gsd-ui-phase`: 새 주요 화면이나 큰 UX 방향이 생길 때.

## Next Command

Phase 4의 다음 MVP Light 조각으로 정리 후보의 원본 정리 handoff와 원본 누락 복구 상태를 진행한다. iOS 실행 확인은 Xcode/CoreSimulator 업데이트 또는 재설치 후 별도로 진행한다.

## Decisions

- [Phase 2]: Phase 2 guided scan context captured with agent-selected defaults — User chose Agent가 결정; decisions are recorded in .planning/phases/02-guided-scan-intake/02-CONTEXT.md
- [Phase 2]: Phase 2 UI-SPEC approved — Guided scan intake UI contract created in .planning/phases/02-guided-scan-intake/02-UI-SPEC.md
- [Phase 2]: Phase 2 execution plan approved — Research, validation, pattern map, and plans 02-01 through 02-03 are ready for execution.
- [Phase 2]: Phase 2 implementation complete — Guided scan intake code and tests are complete; final automated verification passed with 35 Flutter tests.
- [Phase 2]: UAT Test 3 gap fixed — Default ScanScreen now uses a Phase 2 demo picker and observable processing delay so source selection shows the progress shell before completion; final automated verification passed with 36 Flutter tests.
- [Phase 2]: UAT Test 4 duplicate gap diagnosed — Repeated default source selection currently shows `확인한 항목 1개` instead of duplicate skip feedback because the demo picker generates a new source token per pick; gap closure plan 02-05 is ready.
- [Phase 2]: UAT Test 4 duplicate gap fixed — Default demo picker now uses stable source tokens and duplicate-only selections remain visible long enough to show skip feedback; final automated verification passed with 37 Flutter tests.
- [Phase 2]: Phase 2 UAT passed — Guided scan intake passed 6/6 conversational UAT checks on Android emulator; remaining iOS launch verification is an environment blocker, not app code.
- [Phase 3]: Phase 3 context captured — OCR candidate review decisions are recorded in .planning/phases/03-ocr-candidate-review-and-discovery-report/03-CONTEXT.md
- [Phase 3]: Phase 3 UI-SPEC approved — Discovery report, one-by-one candidate review, expiry choice chips, full-screen image viewer, and contextual manual registration are locked in .planning/phases/03-ocr-candidate-review-and-discovery-report/03-UI-SPEC.md
- [Phase 3]: Phase 3 execution plan approved — Research, pattern map, validation strategy, and plans 03-01 through 03-04 are ready for execution.
- [Phase 3]: Phase 3 implementation complete — OCR candidate discovery, on-device OCR adapters, discovery report, one-by-one review, direct registration, and batch completion are implemented; automated verification passed with 65 Flutter tests and an Android debug APK launch.
- [Phase 3]: Phase 3 Android UAT passed — Discovery report, one-by-one review, full-screen image viewer, candidate save, reject, manual registration, and no-candidate recovery evidence passed 7/7 checks; iOS smoke remains an environment follow-up.
- [Phase 3]: Phase 3 security verified — All 12 plan-time threats are mitigated with `threats_open: 0`; OCR remains selected-source-only and on-device, candidates remain review-only, and confirmed/manual saves preserve app-internal image copies.
- [Phase 3]: Phase 3 Nyquist validation verified — All 13 tasks and 7 requirements have automated evidence; added 320x568 reachability tests for discovery report actions and no-candidate manual registration controls; full suite passed 67/67.
- [Milestone v1.0]: Early milestone audit found gaps — Phase 4~7 remain planned work, and the default Phase 1~3 Scan path still needs production local picker, MethodChannel OCR, SQLite repository, and app-internal image copy wiring before Phase 4.
- [Phase 3.1]: Phase 3.1 production adapter context captured — Real photo multi-select, image-file multi-select plus explicit bounded folder selection, original-byte reusable app-internal copies, and failed-item-only retry are locked in 03.1-CONTEXT.md. — Close milestone audit wiring gaps before Phase 4 without expanding into Wallet UI or broad library scanning.
- [Phase 3.1]: Phase 3.1 execution plan approved — 3 plans in 2 waves cover SQLite persistence, reusable original-byte app-internal copies, native photo/file/folder staging, failed-item-only retry, and real production default composition.
- [Phase 3.1]: Phase 3.1 implementation complete — SQLite persistence, reusable original-byte app-internal image copies, native selected-source staging, failed-item-only retry, and real production default composition are implemented; automated verification passed with `flutter analyze`, `flutter test` 92/92, and Android debug APK build.
- [Phase 3.1]: Phase 3.1 Android UAT passed — Conversational UAT passed 6/6 after adding single recognized-expiry auto-confirmation for review readiness; final automated verification passed with `flutter analyze`, `flutter test` 93/93, and Android debug APK build.
- [Phase 3.1]: Phase 3.1 security verified — All 9 plan-time threats are mitigated with `threats_open: 0`; selected-source boundaries, local-only persistence, durable image copies, failed-item retry, and production composition are verified.
- [Workflow]: MVP Light adopted — Default workflow now skips research, plan-check, Nyquist validation, code review, and security enforcement unless the current change specifically needs those gates; Phase 4 proceeds with short planning, implementation, automated verification, Android UAT, commit, and push.
- [Phase 4]: Wallet/detail/use-complete first slice completed — Saved passes now appear in Wallet from the shared repository, detail opens with image panel, pass metadata, barcode panel, and a use-complete action, and used passes move to the used filter; `flutter analyze`, `flutter test` 94/94, Android debug APK build, and emulator smoke passed.
- [Phase 4]: Barcode/image expansion and cleanup candidate slice completed — Detail now opens coupon image and barcode expansion screens, `file://` image copies render in detail, used passes can move to `cleanupCandidate`, and `정리 후보` appears in Wallet/detail state; `flutter analyze`, `flutter test` 94/94, Android debug APK build, and emulator smoke passed.

## Accumulated Context

### Roadmap Evolution

- Phase 03.1 inserted after Phase 3: Close gap: production local adapter wiring (URGENT)
