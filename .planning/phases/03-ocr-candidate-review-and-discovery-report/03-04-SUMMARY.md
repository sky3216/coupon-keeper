---
phase: 03-ocr-candidate-review-and-discovery-report
plan: "03-04"
subsystem: ui
tags: [discovery-report, candidate-review, manual-registration, widget-tests]
requires:
  - phase: 03-02
    provides: candidate discovery controller
  - phase: 03-03
    provides: normalized native OCR adapters
provides:
  - Scan discovery report
  - one-by-one candidate review UI
  - full-screen source image viewer
  - contextual manual registration and batch completion
affects: [wallet, verify-work]
tech-stack:
  added: []
  patterns: [controller-driven-scan-ui, scroll-reachable-mobile-actions]
key-files:
  created:
    - lib/presentation/widgets/discovery_report.dart
    - lib/presentation/widgets/candidate_review_form.dart
    - lib/presentation/widgets/source_image_preview.dart
    - lib/presentation/widgets/manual_registration_form.dart
  modified:
    - lib/presentation/screens/scan_screen.dart
key-decisions:
  - "중복 선택만 남은 경우에는 발견 리포트를 만들지 않고 기존 건너뜀 요약을 유지한다."
  - "실제 file URI는 원본 이미지를 렌더링하고 fixture ref는 중립 이미지 아이콘으로 대체한다."
requirements-completed: [SCAN-05, OCR-03, OCR-04, OCR-05, OCR-06]
duration: 18min
completed: 2026-05-31
---

# Phase 3 Plan 04: OCR Candidate Review UI Summary

**발견 리포트에서 한 장씩 후보를 검토하고 직접 등록으로 복구할 수 있는 Scan 탭 경험**

## Accomplishments

- 확인된 금액만 표시하는 발견 리포트와 한 장씩 편집하는 후보 검토 폼을 추가했다.
- 날짜 후보 chip, 저장 준비 gate, 거절, 전체 화면 이미지 뷰어를 연결했다.
- OCR 결과가 비어도 선택 이미지를 유지한 직접 등록과 batch completion으로 이어지게 했다.
- 320x568 도달성, save/reject 흐름, 개인정보 회귀를 위젯 테스트로 고정했다.

## Task Commits

1. **Tasks 1-4: discovery report, review UI, manual recovery, regression tests** - `a4c8de8` (feat)

## Deviations from Plan

- 실제 네이티브 picker가 아직 Phase 3 범위 밖이므로 fixture ref는 중립 이미지 아이콘을 렌더링한다. file URI를 받으면 실제 이미지를 contain fit으로 표시한다.

## Issues Encountered

- 스크롤 아래쪽 날짜 chip과 저장 버튼을 위젯 테스트가 바로 탭해 실패했다. 실제 모바일 흐름처럼 `ensureVisible`을 사용해 도달성 검증으로 수정했다.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Android emulator에 최종 APK를 설치하고 앱 프로세스 실행을 확인했다.
- 실제 화면 UAT는 `$gsd-verify-work 3`에서 진행할 수 있다.

## Self-Check: PASSED

- flutter analyze
- flutter test (67 tests)
- flutter build apk --debug
- adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
- adb -s emulator-5554 shell am start -n com.example.coupon_keeper/.MainActivity

---
*Phase: 03-ocr-candidate-review-and-discovery-report*
*Completed: 2026-05-31*
