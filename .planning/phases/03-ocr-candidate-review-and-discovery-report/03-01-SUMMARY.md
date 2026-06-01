---
phase: 03-ocr-candidate-review-and-discovery-report
plan: "03-01"
subsystem: domain
tags: [ocr, parser, candidates, discovery-report]
requires:
  - phase: 02-guided-scan-intake
    provides: selected-item ScanItem contract and duplicate fingerprint boundary
provides:
  - normalized pure Dart OCR values
  - review-only pass candidates with explicit save readiness
  - Korean coupon parser and conservative discovery report
affects: [candidate-discovery, native-ocr, scan-ui]
tech-stack:
  added: []
  patterns: [transient-platform-source-ref, normalized-ocr-boundary]
key-files:
  created:
    - lib/domain/ocr_text.dart
    - lib/domain/pass_candidate.dart
    - lib/domain/discovery_report.dart
    - lib/application/pass_candidate_parser.dart
  modified:
    - lib/domain/scan_item.dart
key-decisions:
  - "fingerprint sourceToken과 네이티브 입력 platformSourceRef를 분리한다."
  - "보호 금액은 value confidence 0.8 이상인 후보만 합산한다."
patterns-established:
  - "플랫폼 SDK 결과는 pure Dart OCR block으로 정규화한 뒤 파싱한다."
  - "OCR 후보는 Pass와 분리하고 명시적 확인 전에는 저장하지 않는다."
requirements-completed: [SCAN-05, OCR-01, OCR-02, OCR-03]
duration: 10min
completed: 2026-05-31
---

# Phase 3 Plan 01: OCR Candidate Foundation Summary

**안정 fingerprint와 임시 원본 참조를 분리한 OCR 후보 모델, 한국 쿠폰 파서, 보수적인 발견 리포트**

## Performance

- **Duration:** 10 min
- **Completed:** 2026-05-31T08:45:50Z
- **Tasks:** 3
- **Files modified:** 12

## Accomplishments

- OCR block, line, bounds를 Flutter SDK와 분리된 pure Dart 값으로 정규화했다.
- 날짜, 금액, 브랜드, 숫자 바코드 후보를 보존하는 한국 쿠폰 파서를 추가했다.
- 높은 신뢰도의 금액만 합산하고 D-7 및 만료 가능 항목을 세는 발견 리포트를 추가했다.

## Task Commits

1. **Tasks 1-3: OCR domain, parser, report foundation** - `28eaccd` (feat)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fake recognizer const constructor removed**
- **Found during:** Wave 1 plan verification
- **Issue:** 호출 기록 리스트를 가진 fake recognizer에 const 생성자가 있어 정적 분석이 실패했다.
- **Fix:** 기록 가능한 fake 계약을 유지하고 const 한정자만 제거했다.
- **Verification:** `flutter analyze`
- **Committed in:** `28eaccd`

**Total deviations:** 1 auto-fixed bug. **Impact:** 테스트 fake의 의도된 호출 기록 기능을 유지했다.

## Issues Encountered

- 샌드박스 환경에서 Flutter SDK 태그 확인과 홈 디렉터리 텔레메트리 접근이 차단되어 승인된 실행 경로로 테스트를 재실행했다.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 후보 발견 세션과 네이티브 OCR 어댑터가 공통 계약을 사용할 수 있다.
- `platformSourceRef`는 OCR/image copy 입력과 저장된 원본 추적 metadata에만 사용하고 fingerprint에는 섞지 않는 값으로 고정됐다.

## Self-Check: PASSED

- flutter test test/domain/scan_item_test.dart test/domain/ocr_text_test.dart test/domain/pass_candidate_test.dart test/application/pass_candidate_parser_test.dart test/domain/discovery_report_test.dart
- flutter analyze

---
*Phase: 03-ocr-candidate-review-and-discovery-report*
*Completed: 2026-05-31*
