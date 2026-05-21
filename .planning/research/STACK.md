# Research: Stack

**Generated:** 2026-05-21
**Project:** Coupon Keeper

## Recommendations

- **Flutter for shared UI** — Official Flutter docs support platform channels for calling platform APIs from Dart. This matches the chosen split: common UI/application layers in Flutter, photo/OCR/notification/payment adapters in Swift/Kotlin.
- **Flutter integration tests** — Flutter's `integration_test` package is the standard path for app-level flows. Use it for guided scan with mocked platform adapters, candidate confirmation, reminder scheduling, and Pro gate behavior.
- **iOS OCR** — Apple Vision provides image text recognition via `VNRecognizeTextRequest`; use native Swift adapter and return normalized text blocks to Dart.
- **iOS photo selection** — SwiftUI `PhotosPicker` grants access only to user-selected items without broad photo library authorization. This reinforces guided scan-first.
- **Android OCR** — ML Kit Text Recognition v2 supports on-device text extraction and includes Korean libraries. Use native Kotlin adapter for Android.
- **Android media selection** — Android Photo Picker and selected photo access emphasize user-selected items. For downloads/folders, use Storage Access Framework rather than requesting broad storage access.
- **In-app purchase** — Start with Flutter's official `in_app_purchase` package and local entitlement cache. Defer backend receipt validation until real refund/restore/fraud pain appears.

## Sources

- Flutter platform channels: https://docs.flutter.dev/platform-integration/platform-channels
- Flutter integration tests: https://docs.flutter.dev/testing/integration-tests
- Apple Vision text recognition: https://developer.apple.com/documentation/vision/recognizing-text-in-images
- Apple PhotosPicker: https://developer.apple.com/documentation/swiftui/view/photospicker%28ispresented%3Aselection%3Amaxselectioncount%3Aselectionbehavior%3Amatching%3Apreferreditemencoding%3Aphotolibrary%3A%29
- Android ML Kit Text Recognition v2: https://developers.google.com/ml-kit/vision/text-recognition/v2/android
- Android selected photos access: https://developer.android.google.cn/about/versions/14/changes/partial-photo-video-access
- Flutter in_app_purchase: https://pub.dev/packages/in_app_purchase

## Confidence

High for Flutter/native-channel split, guided media selection, and on-device OCR. Medium for direct `in_app_purchase` long-term maintenance because refund/restore edge cases may push the project toward a managed entitlement service after MVP.
