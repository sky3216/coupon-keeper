---
phase: 03-ocr-candidate-review-and-discovery-report
plan: "03-02"
subsystem: application
tags: [discovery-session, review, manual-registration, image-copy]
requires:
  - phase: 03-01
    provides: OCR candidate parser and discovery report
provides:
  - candidate discovery lifecycle
  - explicit save and reject commands
  - contextual manual registration save path
affects: [scan-ui, wallet]
tech-stack:
  added: []
  patterns: [explicit-save-only, app-internal-image-copy]
key-files:
  created:
    - lib/application/candidate_discovery_controller.dart
  modified:
    - lib/presentation/app/coupon_keeper_app.dart
    - lib/presentation/shell/app_shell.dart
key-decisions:
  - "후보 발견은 저장소를 쓰지 않고 명시적 저장 액션만 Pass를 생성한다."
  - "직접 등록도 선택 이미지의 platformSourceRef를 앱 내부 사본으로 복사한다."
requirements-completed: [SCAN-05, OCR-03, OCR-04, OCR-05, OCR-06]
duration: 12min
completed: 2026-05-31
---

# Phase 3 Plan 02: Candidate Discovery Session Summary

**OCR 후보를 자동 저장하지 않고 사용자 확인 뒤에만 이미지 사본과 Pass를 만드는 발견 세션**

## Accomplishments

- guided scan processor에 주입 가능한 후보 발견 컨트롤러를 추가했다.
- 저장, 거절, 직접 등록을 분리하고 저장 준비 조건을 애플리케이션 계층에서 강제했다.
- 앱 셸과 Scan 화면이 발견 컨트롤러를 주입받을 수 있게 연결했다.

## Task Commits

1. **Tasks 1-3: candidate discovery lifecycle and injection points** - `71817fb` (feat)

## Deviations from Plan

- `₩4,500` 표기가 `원` 글자 없이도 파싱되도록 Wave 1 파서 정규식을 보완했다.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Scan UI는 controller 상태만 소비해 report, review, manual recovery를 렌더링할 수 있다.

## Self-Check: PASSED

- `flutter test test/application/candidate_discovery_controller_test.dart test/application/guided_scan_controller_test.dart test/presentation/app_shell_test.dart`
- `flutter analyze`

---
*Phase: 03-ocr-candidate-review-and-discovery-report*
*Completed: 2026-05-31*
