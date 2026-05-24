---
status: pass-with-environment-followup
phase: 01-app-foundation-and-local-pass-model
source:
  - 01-01-SUMMARY.md
  - 01-02-SUMMARY.md
  - 01-03-SUMMARY.md
started: 2026-05-22T13:20:05Z
updated: 2026-05-24T02:10:00Z
---

## Current Test

[complete - Android UAT pass; iOS simulator environment blocker remains]

## Tests

### 1. App Opens to Today
expected: When the app opens, the first screen is Today. You should see the heading `잊고 있던 쿠폰을 찾아볼까요?`, the primary action `숨어 있는 쿠폰 찾기`, and exactly three bottom tabs: `Today`, `Wallet`, and `Scan`.
result: pass
verified_on: "Android emulator Pixel_8_API_33 / emulator-5554"
notes: "App opens to Today, shows the expected heading, primary CTA, and Today/Wallet/Scan bottom tabs."

### 2. Today CTA Goes to Scan
expected: Tapping `숨어 있는 쿠폰 찾기` switches to the Scan tab and shows `선택한 항목에서 쿠폰을 찾습니다` and `스캔 준비`, without opening a photo picker, file picker, permission prompt, OCR flow, or progress screen.
result: pass
verified_on: "Android emulator Pixel_8_API_33 / emulator-5554"
notes: "CTA switches to Scan and shows the prepared scan shell without opening a picker, permission prompt, OCR flow, or progress screen."

### 3. Wallet Empty State Is Honest
expected: Tapping `Wallet` shows `아직 지갑이 비어 있어요`, explains that scanned passes will appear there, offers `Scan으로 이동`, and does not show fake coupon cards, sample brands, or made-up saved-pass data.
result: pass
verified_on: "Android emulator Pixel_8_API_33 / emulator-5554"
notes: "Wallet shows an honest empty state, explanatory copy, and `Scan으로 이동`; no fake coupon cards or sample saved-pass data appear."

### 4. Scan Tab Is a Prepared Action Space
expected: Tapping `Scan` shows `선택한 항목에서 쿠폰을 찾습니다`, explains that photos/download files will be selected in the next step, and keeps `스캔 준비` as a Phase 1 shell action instead of starting real scanning.
result: pass
verified_on: "Android emulator Pixel_8_API_33 / emulator-5554"
notes: "Scan shows the prepared action space and keeps `스캔 준비` disabled instead of starting real scanning."

### 5. Pass Storage Contract Is Ready
expected: The Phase 1 automated checks prove that a pass can keep type, title, brand, estimated value, expiry, status, source metadata, image copy path, OCR text, and confidence, including a source-missing state with an app-internal image copy path.
result: pass

### 6. Status Language and Small-Screen Accessibility Are Ready
expected: The Phase 1 UI foundation includes status chip labels `D-7`, `오늘 만료`, `만료됨`, `사용 완료`, `확인 필요`, and `원본 없음`; status meaning is not color-only; the Today CTA remains reachable on a 320x568 screen.
result: pass

## Summary

total: 6
passed: 6
issues: 0
pending: 0
skipped: 0
blocked: 0

## Environment Follow-up

- truth: "The app should also launch on the local iOS simulator once the developer environment is healthy."
  status: environment_blocked
  reason: "iOS simulator launch still fails on 2026-05-24 even after macOS moved to 26.5; Xcode remains 16.1."
  severity: blocker
  test: platform-launch-ios
  root_cause: "Manual diagnosis reproduced the iOS failure with `flutter run -d B8EFEC07-DC10-4C70-A210-94D66F030633`: Xcode build completes, then iOS launch fails with `Failed to launch AssetCatalogSimulatorAgent via CoreSimulator spawn` for `ios/Runner/Assets.xcassets`. System logs show AMFI rejecting `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Xcode/Overlays/AssetCatalogSimulatorAgent` with `disallowed without library validation` and `code signature validation failed fatally`, so this is a local Xcode/CoreSimulator toolchain blocker rather than a proven app-shell code defect. Android toolchain blockers were remediated by installing cmdline-tools, accepting SDK licenses, installing Android SDK 36/build tools, adding Flutter/sdkmanager to `.zshrc`, wiping a full `Pixel_8_API_33` AVD data partition, and successfully running visual UAT on `emulator-5554` on 2026-05-24."
  artifacts:
    - path: "ios/Runner/Assets.xcassets"
      issue: "Xcode/CoreSimulator fails while launching AssetCatalogSimulatorAgent; AMFI rejects the tool binary during code signature validation."
    - path: "android/"
      issue: "Android environment was repaired; after wiping a full Pixel_8_API_33 AVD data partition, app launch and visual UAT passed on `emulator-5554`."
  missing:
    - "Update or reinstall Xcode/CoreSimulator so `AssetCatalogSimulatorAgent` passes AMFI/library validation and iOS `flutter run` can launch."
    - "Re-run iOS simulator launch after Xcode/CoreSimulator is repaired."
  debug_session: "manual-diagnosis-2026-05-24"
