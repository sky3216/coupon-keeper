---
phase: 03-ocr-candidate-review-and-discovery-report
plan: "03-03"
subsystem: platform
tags: [method-channel, ml-kit, vision, on-device-ocr]
requires:
  - phase: 03-01
    provides: normalized Dart OCR contract
provides:
  - Dart MethodChannel OCR adapter
  - Android bundled ML Kit Korean and Latin OCR
  - iOS Vision OCR channel registration
affects: [scan-ui, release-readiness]
tech-stack:
  added: [ml-kit-text-recognition, ml-kit-text-recognition-korean]
  patterns: [normalized-native-channel-schema, on-device-only-ocr]
key-files:
  created:
    - lib/platform/method_channel_ocr_text_recognizer.dart
  modified:
    - android/app/src/main/kotlin/com/example/coupon_keeper/MainActivity.kt
    - ios/Runner/AppDelegate.swift
key-decisions:
  - "Android minSdk는 Flutter 기본값과 23 중 큰 값을 사용해 Flutter 마이그레이터 이후에도 ML Kit 하한을 유지한다."
  - "iOS Vision 결과도 Android와 같은 block/line 맵으로 정규화한다."
requirements-completed: [OCR-01]
duration: 10min
completed: 2026-05-31
---

# Phase 3 Plan 03: On-device OCR Channels Summary

**서버 전송 없이 Android ML Kit와 iOS Vision 결과를 하나의 Dart OCR block 계약으로 전달하는 플랫폼 채널**

## Accomplishments

- Dart `coupon_keeper/ocr` 채널 어댑터와 typed failure를 추가했다.
- Android에 bundled Latin/Korean ML Kit 모델과 API 23 하한을 연결했다.
- iOS implicit engine lifecycle에서 Vision OCR 채널을 등록했다.

## Task Commits

1. **Tasks 1-3: Dart, Android, and iOS OCR channels** - `4b10d95` (feat)

## Deviations from Plan

- Flutter Gradle 마이그레이터가 `minSdk = 23` 리터럴을 되돌려 `maxOf(flutter.minSdkVersion, 23)`으로 고정했다. 동일한 API 23 하한을 유지하며 재빌드 후에도 보존된다.

## Issues Encountered

- iOS simulator smoke는 기존 Xcode/CoreSimulator 환경 blocker가 남아 있어 소스 assertion으로 검증했다.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Scan UI는 fake discovery controller로 안정적으로 검증하고, 실제 picker 연결 시 native OCR adapter를 사용할 수 있다.

## Self-Check: PASSED

- `flutter test test/platform/method_channel_ocr_text_recognizer_test.dart`
- `flutter build apk --debug`
- `rg -n "VNRecognizeTextRequest|FlutterMethodChannel|coupon_keeper/ocr" ios/Runner/AppDelegate.swift`
- `flutter analyze`

---
*Phase: 03-ocr-candidate-review-and-discovery-report*
*Completed: 2026-05-31*
