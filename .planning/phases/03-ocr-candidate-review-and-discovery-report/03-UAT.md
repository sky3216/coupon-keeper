---
status: complete
phase: 03-ocr-candidate-review-and-discovery-report
source:
  - .planning/phases/03-ocr-candidate-review-and-discovery-report/03-01-SUMMARY.md
  - .planning/phases/03-ocr-candidate-review-and-discovery-report/03-02-SUMMARY.md
  - .planning/phases/03-ocr-candidate-review-and-discovery-report/03-03-SUMMARY.md
  - .planning/phases/03-ocr-candidate-review-and-discovery-report/03-04-SUMMARY.md
started: 2026-05-31T09:32:48Z
updated: 2026-06-01T14:36:55Z
---

## Current Test

[testing complete]

## Tests

### 1. Discovery Report After Scan
expected: Scan 탭에서 `사진에서 찾기`를 누르고 잠시 기다리면 진행 화면 뒤에 발견 리포트가 나타납니다. 리포트에는 `놓칠 수 있는 쿠폰을 찾았어요`, `찾은 후보 1개`, `후보 검토 시작`, `다시 선택`이 보입니다. 데모 후보에는 신뢰할 수 있는 금액이 없으므로 가짜 보호 금액 대신 `금액은 후보를 확인하면서 정확하게 입력할 수 있어요.`가 보여야 합니다.
result: pass

### 2. One-by-One Candidate Review
expected: 발견 리포트에서 `후보 검토 시작`을 누르면 `후보 1/1` 진행 표시, 이미지 미리 보기, `제목`, `브랜드`, `만료일`, `금액` 편집 필드, 인식된 날짜 선택 영역, `이 쿠폰 저장`, `쿠폰 아님`, `직접 등록` 액션이 보입니다. 날짜를 확인하기 전 저장 버튼은 비활성 상태여야 합니다.
result: pass

### 3. Full-Screen Source Image Viewer
expected: 후보 검토 화면의 이미지 미리 보기를 누르면 어두운 배경의 전체 화면 이미지 보기가 열리고 닫기 아이콘이 보입니다. 닫으면 입력 중이던 후보 검토 화면으로 돌아옵니다.
result: pass

### 4. Save Candidate And Complete Batch
expected: 후보 검토 화면에서 인식된 날짜를 선택하고 `이 쿠폰 저장`을 누르면 `쿠폰 확인을 마쳤어요`, `저장한 쿠폰 1개`, `Wallet에서 보기`, `다시 스캔`이 보입니다. `Wallet에서 보기`를 누르면 Wallet 탭으로 이동합니다.
result: pass

### 5. Reject False Positive
expected: 다시 Scan 탭에서 다른 source인 `다운로드/파일에서 찾기`로 후보를 만든 뒤 `쿠폰 아님`을 누르면 완료 화면에 `건너뛴 후보 1개`가 보입니다. 저장한 쿠폰이 없으므로 기본 액션은 `다시 스캔`이어야 합니다.
result: pass

### 6. Manual Registration From Review
expected: 다시 후보 검토 화면으로 들어가 `직접 등록`을 누르면 `쿠폰 정보를 직접 입력해 주세요`, 이미지 미리 보기, `제목`, `브랜드`, `만료일`, 선택 입력인 `금액`, `쿠폰 저장`, `취소`가 보입니다. `취소`하면 후보 검토로 돌아오고, 다시 직접 등록해 필수 정보를 채워 저장하면 완료 화면으로 이동합니다.
result: pass

### 7. No-Candidate Recovery Automated Evidence
expected: OCR이 후보를 찾지 못하는 경로는 자동 위젯 테스트에서 `이번 선택에서는 쿠폰 후보를 찾지 못했어요`, `직접 등록`, `다시 선택`과 직접 등록 저장 완료를 검증합니다. 기본 데모 recognizer는 항상 후보 하나를 만들기 때문에 실행 앱에서는 이 상태를 수동으로 유도하지 않습니다.
result: pass
evidence:
  - "`flutter test test/presentation/manual_registration_test.dart test/application/candidate_discovery_controller_test.dart` passed 8/8"

## Summary

total: 7
passed: 7
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none yet]

## Environment Follow-up

- truth: "Xcode/CoreSimulator 복구 후 iOS simulator에서도 Vision OCR 채널 smoke를 실행한다."
  status: environment_blocked
  reason: "macOS 26.5와 Xcode 16.1 환경에서 AssetCatalogSimulatorAgent 실행이 거부되는 기존 blocker가 남아 있다."
  severity: blocker
  test: platform-launch-ios
  root_cause: "Xcode/CoreSimulator 도구 바이너리의 AMFI library validation 및 code signature 거부이며 Phase 3 앱 코드 결함으로 분류하지 않는다."
  missing:
    - "Xcode/CoreSimulator를 업데이트하거나 재설치한다."
    - "환경 복구 후 iOS simulator Vision OCR smoke를 다시 실행한다."
