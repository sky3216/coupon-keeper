---
status: diagnosed
phase: 2-guided-scan-intake
source:
  - .planning/phases/02-guided-scan-intake/02-01-SUMMARY.md
  - .planning/phases/02-guided-scan-intake/02-02-SUMMARY.md
  - .planning/phases/02-guided-scan-intake/02-03-SUMMARY.md
  - .planning/phases/02-guided-scan-intake/02-SUMMARY.md
started: 2026-05-26T13:38:16Z
updated: 2026-05-26T14:05:00Z
---

## Current Test

[testing paused — gap found in test 3]

## Tests

### 1. Today CTA Opens Guided Scan Start
expected: 앱을 열면 Today 화면이 먼저 보입니다. `숨어 있는 쿠폰 찾기`를 누르면 native picker가 바로 열리지 않고 Scan 탭으로 이동합니다. Scan 탭에는 `어디에서 쿠폰을 찾을까요?`, `사진에서 찾기`, `다운로드/파일에서 찾기`가 보여야 합니다.
result: pass

### 2. Scan Start Shows Selected-Only Source Choices
expected: Scan 탭 시작 화면은 `선택한 사진과 파일만 기기 안에서 확인합니다.`와 `전체 사진첩이나 폴더를 조용히 훑지 않아요.`를 보여줍니다. 사진과 다운로드/파일 선택지는 같은 비중으로 보이고, 전체 사진첩/전체 폴더를 몰래 스캔하는 표현은 없어야 합니다.
result: pass

### 3. Progress and Cancel Are Clear
expected: 사용자가 source를 선택하면 진행 화면에 `선택한 항목을 확인하고 있어요`, `{processed}/{total} 처리 중`, `후보 확인 준비 중`, `취소`가 보입니다. 취소하면 `스캔을 멈췄어요`와 `다시 선택`, `Scan 처음으로`가 보여야 합니다.
result: issue
reported: "진행상태는 아직 나오지 않고 source 선택 화면 뒤에 `이번 선택에서는 쿠폰을 찾지 못했어요` empty 화면이 나온다."
severity: major

### 4. Duplicate Selection Is Skipped
expected: 이미 확인한 항목을 다시 선택하면 앱은 그 항목을 다시 처리하지 않고 `이미 확인한 항목 N개는 건너뛰었어요` 또는 완료 요약의 `건너뛴 항목 N개`로 알려줍니다. 저장된 쿠폰이나 후보 카드가 가짜로 생기면 안 됩니다.
result: [pending]

### 5. Empty, Error, and Completion States Are Honest
expected: 선택 결과가 비었을 때는 `이번 선택에서는 쿠폰을 찾지 못했어요`가 보이고, 접근 거부/파일 없음/처리 실패는 각각 다른 회복 문구를 보여줍니다. 완료 상태는 `선택한 항목 확인을 마쳤어요`와 Phase 3 준비 문구만 보여주며 발견 개수, 보호 금액, 저장/수정 화면을 보여주지 않습니다.
result: [pending]

### 6. Automated Verification Evidence Is Green
expected: Phase 2 자동 검증은 `flutter analyze` no issues, `flutter test` 35 tests passed 상태입니다. Android/iOS smoke는 booted device가 없으면 코드 실패가 아니라 환경상 blocked/skipped로 분리 기록됩니다.
result: [pending]

## Summary

total: 6
passed: 2
issues: 1
pending: 3
skipped: 0
blocked: 0

## Gaps

- truth: "사용자가 source를 선택하면 진행 화면에 `선택한 항목을 확인하고 있어요`, `{processed}/{total} 처리 중`, `후보 확인 준비 중`, `취소`가 보입니다. 취소하면 `스캔을 멈췄어요`와 `다시 선택`, `Scan 처음으로`가 보여야 합니다."
  status: failed
  reason: "User reported: 진행상태는 아직 나오지 않고 source 선택 화면 뒤에 `이번 선택에서는 쿠폰을 찾지 못했어요` empty 화면이 나온다."
  severity: major
  test: 3
  root_cause: "프로덕션 기본 ScanScreen이 `FakeScanSourcePicker.photos(const [])`를 사용한다. 따라서 사용자가 source를 탭하면 선택 항목이 0개로 처리되어 `GuidedScanController._processSelected`가 progress/running 상태 없이 바로 empty 상태를 emit한다. Widget tests는 injected controller로 progress를 검증했지만 실제 앱 기본 controller 경로는 progress를 보여줄 selected item/process delay가 없다."
  artifacts:
    - path: "lib/presentation/screens/scan_screen.dart"
      issue: "기본 controller가 빈 fake picker를 사용해 실제 앱에서 source 선택 시 empty 상태로 직행한다."
    - path: "test/presentation/guided_scan_flow_test.dart"
      issue: "앱 기본 controller 경로가 아니라 injected controller 경로만 progress/completion을 검증한다."
  missing:
    - "프로덕션 기본 ScanScreen 경로에서 Phase 2용 선택 어댑터가 selected item을 반환하거나, native picker 미구현 상태에서도 progress shell을 볼 수 있는 adapter를 제공해야 한다."
    - "기본 CouponKeeperApp/ScanScreen 경로로 source 선택 후 progress 화면이 먼저 나타나는 widget test가 필요하다."
  debug_session: ".planning/phases/02-guided-scan-intake/02-UAT.md"
