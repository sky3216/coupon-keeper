---
status: partial
phase: 01-app-foundation-and-local-pass-model
source:
  - 01-01-SUMMARY.md
  - 01-02-SUMMARY.md
  - 01-03-SUMMARY.md
started: 2026-05-22T13:20:05Z
updated: 2026-05-22T13:32:20Z
---

## Current Test

[testing paused - app launch blocker]

## Tests

### 1. App Opens to Today
expected: When the app opens, the first screen is Today. You should see the heading `잊고 있던 쿠폰을 찾아볼까요?`, the primary action `숨어 있는 쿠폰 찾기`, and exactly three bottom tabs: `Today`, `Wallet`, and `Scan`.
result: issue
reported: "앱이 열리지 않았고 시뮬레이터만 열렸어"
severity: blocker

### 2. Today CTA Goes to Scan
expected: Tapping `숨어 있는 쿠폰 찾기` switches to the Scan tab and shows `선택한 항목에서 쿠폰을 찾습니다` and `스캔 준비`, without opening a photo picker, file picker, permission prompt, OCR flow, or progress screen.
result: blocked
blocked_by: other
reason: "App launch is blocked on the simulator, so this in-app flow cannot be manually tested yet."

### 3. Wallet Empty State Is Honest
expected: Tapping `Wallet` shows `아직 지갑이 비어 있어요`, explains that scanned passes will appear there, offers `Scan으로 이동`, and does not show fake coupon cards, sample brands, or made-up saved-pass data.
result: blocked
blocked_by: other
reason: "App launch is blocked on the simulator, so Wallet cannot be manually inspected yet."

### 4. Scan Tab Is a Prepared Action Space
expected: Tapping `Scan` shows `선택한 항목에서 쿠폰을 찾습니다`, explains that photos/download files will be selected in the next step, and keeps `스캔 준비` as a Phase 1 shell action instead of starting real scanning.
result: blocked
blocked_by: other
reason: "App launch is blocked on the simulator, so the Scan tab cannot be manually inspected yet."

### 5. Pass Storage Contract Is Ready
expected: The Phase 1 automated checks prove that a pass can keep type, title, brand, estimated value, expiry, status, source metadata, image copy path, OCR text, and confidence, including a source-missing state with an app-internal image copy path.
result: pass

### 6. Status Language and Small-Screen Accessibility Are Ready
expected: The Phase 1 UI foundation includes status chip labels `D-7`, `오늘 만료`, `만료됨`, `사용 완료`, `확인 필요`, and `원본 없음`; status meaning is not color-only; the Today CTA remains reachable on a 320x568 screen.
result: pass

## Summary

total: 6
passed: 2
issues: 1
pending: 0
skipped: 0
blocked: 3

## Gaps

- truth: "When the app opens, the first screen is Today. You should see the heading `잊고 있던 쿠폰을 찾아볼까요?`, the primary action `숨어 있는 쿠폰 찾기`, and exactly three bottom tabs: `Today`, `Wallet`, and `Scan`."
  status: failed
  reason: "User reported: 앱이 열리지 않았고 시뮬레이터만 열렸어"
  severity: blocker
  test: 1
  root_cause: "Manual diagnosis reproduced the failure with `flutter run -d B8EFEC07-DC10-4C70-A210-94D66F030633`: Xcode build completes, then iOS launch fails with `Failed to launch AssetCatalogSimulatorAgent via CoreSimulator spawn` for `ios/Runner/Assets.xcassets`. `flutter doctor -v` reports Xcode installed, but Flutter/Dart are not on PATH. Android manual run is also blocked because the Android toolchain is missing cmdline-tools and license acceptance, and the launched emulator does not appear in `flutter devices --device-timeout 20`. Automated widget tests still pass, so the gap is currently a local simulator/toolchain launch blocker rather than a proven app-shell code defect."
  artifacts:
    - path: "ios/Runner/Assets.xcassets"
      issue: "Xcode/CoreSimulator fails while processing asset catalogs for simulator launch."
    - path: "android/"
      issue: "Android manual launch is blocked by missing SDK cmdline-tools/licenses and emulator visibility."
  missing:
    - "Add Flutter to PATH or use the local Flutter binary consistently."
    - "Repair Xcode/CoreSimulator asset catalog tooling or simulator runtime so `flutter run` can launch on iOS."
    - "Install Android SDK cmdline-tools, accept Android licenses, and confirm an Android emulator appears in `flutter devices`."
    - "Re-run `$gsd-verify-work 1` after local launch works."
  debug_session: "manual-diagnosis-2026-05-22"
