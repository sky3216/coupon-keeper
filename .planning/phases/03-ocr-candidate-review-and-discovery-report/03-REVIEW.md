---
phase: 03-ocr-candidate-review-and-discovery-report
status: clean
reviewed: 2026-05-31
---

# Phase 3 Code Review

## Result

Phase 3 변경 범위에서 미해결 버그, 개인정보 전송 경로, 광범위 사진 권한, 자동 저장 회귀를 찾지 못했다.

## Fixed During Review

### Candidate review manual registration advances after save

- **Severity:** high
- **Found in:** `lib/application/candidate_discovery_controller.dart`
- **Issue:** 후보 검토 중 `직접 등록`으로 저장한 뒤 같은 후보가 남아 중복 저장할 수 있었다.
- **Fix:** 직접 등록이 현재 후보를 대체한 경우 저장 후 `_advance()`를 호출한다.
- **Coverage:** `manual registration from review handles the current candidate`

## Residual Risk

- 실제 iOS simulator smoke는 기존 Xcode/CoreSimulator 환경 blocker 때문에 실행하지 못했다.
- 실제 사진 picker 연결은 후속 플랫폼 어댑터 작업에서 `platformSourceRef`를 공급해야 한다.
