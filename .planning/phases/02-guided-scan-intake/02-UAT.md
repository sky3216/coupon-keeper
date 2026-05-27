---
status: fixed-pending-user-retry
phase: 2-guided-scan-intake
source:
  - .planning/phases/02-guided-scan-intake/02-01-SUMMARY.md
  - .planning/phases/02-guided-scan-intake/02-02-SUMMARY.md
  - .planning/phases/02-guided-scan-intake/02-03-SUMMARY.md
  - .planning/phases/02-guided-scan-intake/02-SUMMARY.md
started: 2026-05-26T13:38:16Z
updated: 2026-05-27T14:57:29Z
---

## Current Test

[ready to retry test 4 - gap fixed in code, user confirmation pending]

## Tests

### 1. Today CTA Opens Guided Scan Start
expected: 앱을 열면 Today 화면이 먼저 보입니다. `숨어 있는 쿠폰 찾기`를 누르면 native picker가 바로 열리지 않고 Scan 탭으로 이동합니다. Scan 탭에는 `어디에서 쿠폰을 찾을까요?`, `사진에서 찾기`, `다운로드/파일에서 찾기`가 보여야 합니다.
result: pass

### 2. Scan Start Shows Selected-Only Source Choices
expected: Scan 탭 시작 화면은 `선택한 사진과 파일만 기기 안에서 확인합니다.`와 `전체 사진첩이나 폴더를 조용히 훑지 않아요.`를 보여줍니다. 사진과 다운로드/파일 선택지는 같은 비중으로 보이고, 전체 사진첩/전체 폴더를 몰래 스캔하는 표현은 없어야 합니다.
result: pass

### 3. Progress and Cancel Are Clear
expected: 사용자가 source를 선택하면 진행 화면에 `선택한 항목을 확인하고 있어요`, `{processed}/{total} 처리 중`, `후보 확인 준비 중`, `취소`가 보입니다. 취소하면 `스캔을 멈췄어요`와 `다시 선택`, `Scan 처음으로`가 보여야 합니다.
result: pass
reported: "진행상태는 아직 나오지 않고 source 선택 화면 뒤에 `이번 선택에서는 쿠폰을 찾지 못했어요` empty 화면이 나온다."
severity: major
fix: "`ScanScreen` 기본 경로가 `PhaseTwoDemoScanSourcePicker`와 800ms async 처리 지연을 사용하도록 수정되어 source 선택 직후 진행 화면을 먼저 표시한다."
evidence:
  - "`flutter test test/presentation/guided_scan_flow_test.dart --plain-name \"default app path\"` passed"
  - "`flutter test test/presentation/guided_scan_flow_test.dart test/presentation/scan_screen_test.dart` passed"
  - "`flutter analyze` passed"
  - "`flutter test` passed 36 tests"

### 4. Duplicate Selection Is Skipped
expected: 이미 확인한 항목을 다시 선택하면 앱은 그 항목을 다시 처리하지 않고 `이미 확인한 항목 N개는 건너뛰었어요` 또는 완료 요약의 `건너뛴 항목 N개`로 알려줍니다. 저장된 쿠폰이나 후보 카드가 가짜로 생기면 안 됩니다.
result: fixed-pending-retry
reported: "반복 선택 후 완료 화면에 `확인한 항목 1개`만 보이고 `건너뛴 항목 1개` 또는 duplicate skip 문구가 보이지 않는다."
severity: major
fix: "`PhaseTwoDemoScanSourcePicker`가 같은 source에 안정적인 demo token을 반환하도록 되돌리고, `GuidedScanController`에 duplicate-only 관찰 지연을 추가해 반복 선택 시 skip 문구와 completion summary가 보이도록 수정했다."
evidence:
  - "`flutter test test/presentation/guided_scan_flow_test.dart --plain-name \"default duplicate\"` passed"
  - "`flutter test test/presentation/guided_scan_flow_test.dart test/presentation/scan_screen_test.dart` passed"
  - "`flutter analyze` passed"
  - "`flutter test` passed 37 tests"

### 5. Empty, Error, and Completion States Are Honest
expected: 선택 결과가 비었을 때는 `이번 선택에서는 쿠폰을 찾지 못했어요`가 보이고, 접근 거부/파일 없음/처리 실패는 각각 다른 회복 문구를 보여줍니다. 완료 상태는 `선택한 항목 확인을 마쳤어요`와 Phase 3 준비 문구만 보여주며 발견 개수, 보호 금액, 저장/수정 화면을 보여주지 않습니다.
result: [pending]

### 6. Automated Verification Evidence Is Green
expected: Phase 2 자동 검증은 `flutter analyze` no issues, `flutter test` 37 tests passed 상태입니다. Android/iOS smoke는 booted device가 없으면 코드 실패가 아니라 환경상 blocked/skipped로 분리 기록됩니다.
result: [pending]

## Summary

total: 6
passed: 3
issues: 0
pending: 3
skipped: 0
blocked: 0
resolved_gaps: 2

## Gaps

- truth: "사용자가 source를 선택하면 진행 화면에 `선택한 항목을 확인하고 있어요`, `{processed}/{total} 처리 중`, `후보 확인 준비 중`, `취소`가 보입니다. 취소하면 `스캔을 멈췄어요`와 `다시 선택`, `Scan 처음으로`가 보여야 합니다."
  status: resolved-confirmed
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
  fix:
    - commit: "8b8ab76"
      change: "기본 앱 경로 진행 화면 회귀 테스트를 추가하고 실패를 재현했다."
    - commit: "98656c2"
      change: "기본 ScanScreen에 Phase 2 데모 picker와 처리 지연을 연결해 진행 화면이 먼저 보이도록 수정했다."
  verification:
    - "`flutter test test/presentation/guided_scan_flow_test.dart --plain-name \"default app path\"` passed"
    - "`flutter test test/presentation/guided_scan_flow_test.dart test/presentation/scan_screen_test.dart` passed"
    - "`flutter analyze` passed"
    - "`flutter test` passed 36 tests"
  debug_session: ".planning/phases/02-guided-scan-intake/02-UAT.md"

- truth: "이미 확인한 항목을 다시 선택하면 앱은 그 항목을 다시 처리하지 않고 `이미 확인한 항목 N개는 건너뛰었어요` 또는 완료 요약의 `건너뛴 항목 N개`로 알려줍니다. 저장된 쿠폰이나 후보 카드가 가짜로 생기면 안 됩니다."
  status: resolved-pending-user-retry
  reason: "User reported: 반복 선택 후 완료 화면에 `확인한 항목 1개`만 보이고 `건너뛴 항목 1개` 또는 duplicate skip 문구가 보이지 않는다."
  severity: major
  test: 4
  root_cause: "`PhaseTwoDemoScanSourcePicker`가 반복 수동 UAT에서 진행 화면을 보이게 하려고 선택마다 `phase-two-demo-{source}-{count}` 형태의 새 source token을 만든다. 이 때문에 기본 앱 경로에서는 같은 항목을 다시 고르는 상황이 만들어지지 않아 `InMemoryScanFingerprintCache.filterUnseen`이 duplicate로 판정할 수 없다. 기존 duplicate 테스트는 injected controller 경로만 검증하고, 실제 기본 앱 경로의 반복 선택 동작을 검증하지 않는다."
  artifacts:
    - path: "lib/platform/phase_two_demo_scan_source_picker.dart"
      issue: "선택마다 source token이 바뀌어 기본 앱 경로에서 duplicate skip이 불가능하다."
    - path: "lib/application/guided_scan_controller.dart"
      issue: "모든 항목이 duplicate인 경우 running 상태는 emit하지만 처리 지연 없이 completion으로 바로 넘어가 수동 UAT에서 duplicate progress가 관찰되기 어렵다."
    - path: "test/presentation/guided_scan_flow_test.dart"
      issue: "기본 CouponKeeperApp 경로에서 같은 source를 다시 선택했을 때 duplicate summary가 보이는지 검증하지 않는다."
  missing:
    - "기본 앱 경로에서도 같은 demo source를 다시 선택하면 duplicate skip summary가 보여야 한다."
    - "모든 항목이 duplicate인 선택도 진행 화면과 duplicate skip 문구가 관찰 가능해야 한다."
    - "기본 CouponKeeperApp 경로의 반복 선택 duplicate 회귀 테스트가 필요하다."
  fix:
    - commit: "8bd8ff7"
      change: "기본 CouponKeeperApp 경로에서 반복 source 선택 duplicate skip 회귀 테스트를 추가하고 실패를 재현했다."
    - commit: "dd1d158"
      change: "PhaseTwoDemoScanSourcePicker를 안정적인 demo token으로 되돌리고 duplicate-only progress 관찰 지연을 연결했다."
    - commit: "5c786e2"
      change: "duplicate-only 지연 설정을 analyzer 규칙에 맞게 정리했다."
  verification:
    - "`flutter test test/presentation/guided_scan_flow_test.dart --plain-name \"default duplicate\"` passed"
    - "`flutter test test/presentation/guided_scan_flow_test.dart test/presentation/scan_screen_test.dart` passed"
    - "`flutter analyze` passed"
    - "`flutter test` passed 37 tests"
  debug_session: ".planning/phases/02-guided-scan-intake/02-UAT.md"
