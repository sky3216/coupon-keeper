---
phase: 3
slug: ocr-candidate-review-and-discovery-report
status: complete
created: 2026-05-31
---

# Phase 3 Research: OCR Candidate Review and Discovery Report

## Research Goal

Phase 3를 계획하기 위해 필요한 기술 경계는 다음과 같다.

1. iOS Vision과 Android ML Kit Text Recognition v2 결과를 공통 Dart OCR block으로 정규화한다.
2. 한국 쿠폰에서 날짜, 금액, 브랜드, 바코드 숫자 후보를 규칙 기반으로 파싱한다.
3. OCR 결과를 자동 저장하지 않고 discovery report와 one-by-one review 후보로 유지한다.
4. Phase 2의 selected-items-only, duplicate skip, cancel 흐름을 유지하면서 Phase 3를 연결한다.

## Official Platform Findings

### Flutter Platform Channel

Flutter 공식 문서는 Dart `MethodChannel`, Android `MethodChannel`, iOS `FlutterMethodChannel`을 통해 비동기 메시지와 응답을 전달하도록 안내한다. Standard codec은 `Map`, `List`, `String`, 숫자, byte array 같은 JSON-like 값을 지원하므로 normalized OCR block을 직접 직렬화하기에 충분하다.

현재 iOS 프로젝트는 `FlutterImplicitEngineDelegate`와 `didInitializeImplicitFlutterEngine`을 이미 사용한다. Flutter 공식 문서도 `UISceneDelegate` lifecycle에서는 이 위치에서 channel을 만드는 방식을 안내한다. Android는 `MainActivity.configureFlutterEngine()`에서 channel을 등록하면 된다.

### Android ML Kit Text Recognition v2

Google 공식 문서 기준으로 ML Kit Text Recognition v2는 Korean script library를 제공하며, bundled model과 Google Play Services dynamic download model 중 선택할 수 있다.

| Option | Trade-off | Phase 3 Decision |
|--------|-----------|------------------|
| Bundled model | Script당 앱 크기가 약 4MB 늘지만 첫 실행부터 모델을 사용할 수 있다. | 사용 |
| Unbundled model | Script당 앱 크기 증가는 작지만 첫 사용 전 다운로드가 끝나지 않으면 결과가 없을 수 있다. | 사용하지 않음 |

첫 스캔에서 바로 가치가 보여야 하고 local-only 신뢰를 유지해야 하므로 bundled Korean + Latin recognizer를 사용한다. 공식 문서에 게시된 dependency는 `com.google.mlkit:text-recognition:16.0.1`과 `com.google.mlkit:text-recognition-korean:16.0.1`이다. ML Kit는 text block, line, element, bounding coordinates, confidence를 제공한다.

ML Kit Android 가이드는 API level 23 이상을 요구한다. 현재 Gradle은 `flutter.minSdkVersion`을 사용하므로 Phase 3 native wiring에서 `minSdk = 23`을 명시적으로 고정한다.

### iOS Vision

Apple 공식 문서 기준으로 `VNRecognizeTextRequest`는 image text recognition 요청이며 `VNRecognizedTextObservation` 결과를 반환한다. `topCandidates(_:)`는 confidence 순서의 text 후보를 제공하고, `VNRecognizedText`는 normalized confidence를 제공한다.

iOS adapter는 accuracy 우선으로 설정하고, 지원 언어를 runtime에서 확인한 뒤 가능한 경우 `ko-KR`, `en-US` 순서로 요청한다. 지원되지 않는 locale은 제외하고 기본 Vision fallback을 사용한다. 이 방식은 iOS 13 deployment target을 불필요하게 올리지 않는다.

## Recommended Architecture

```text
GuidedScanController
  -> CandidateDiscoverySession.processItem(ScanItem)
  -> OcrTextRecognizer.recognize(ScanItem)
  -> normalized OcrTextResult(blocks, lines, confidence, bounds)
  -> PassCandidateParser.parse(...)
  -> in-memory review candidates + DiscoveryReport
  -> user edits / rejects / manually registers
  -> ImageCopyStore.copyIntoAppStorage(...)
  -> PassRepository.save(Pass)
```

### Preserve the Phase 2 Contract

`GuidedScanController` already accepts an injected `ScanItemProcessor`. A Phase 3 discovery session can process each selected item through OCR and parsing. If OCR processing throws, the Phase 2 controller does not mark that fingerprint as seen. This preserves selected-items-only scanning, cancel behavior, and duplicate skip handling without rewriting the intake controller.

The default app path can keep a deterministic Phase 3 demo recognizer until native picker wiring is available. Widget tests must inject fakes. Native adapters still need real method-channel implementations and normalized result contract tests.

## Domain Contracts

### OCR Result

Add pure Dart values:

- `OcrTextResult`: full text, blocks
- `OcrTextBlock`: text, normalized bounding box, confidence, lines
- `OcrTextLine`: text, normalized bounding box, confidence
- `OcrBounds`: left, top, width, height in normalized `0..1` coordinates

Both native platforms must emit the same JSON-like schema. Missing confidence is allowed and normalized to nullable values.

### Candidate

Add a review-only `PassCandidate` that is not a saved `Pass`.

- source item
- OCR text
- candidate title
- candidate brand
- value candidates
- expiry candidates
- barcode numeric candidates
- per-field confidence
- selected/confirmed expiry
- editable title, brand, estimated value
- image copy path only after confirmed save/manual registration

`PassCandidate` can answer `isSaveReady`: title or brand is present and expiry was confirmed.

`ScanItem.sourceToken`은 fingerprint용 안정 토큰으로 유지한다. OCR과 image copy가 원본에 접근할 때는 별도의 transient `platformSourceRef`를 사용한다. Dart는 이 값을 저장하거나 fingerprint에 섞지 않고 platform adapter에 다시 전달만 한다. Android는 선택된 `content://` reference를 해석할 수 있고, iOS는 picker adapter가 만든 opaque reference를 native layer에서 해석할 수 있다.

### Parser Rules

Start with deterministic Korean coupon fixtures:

- Dates: `2026.06.30`, `2026-06-30`, `2026/06/30`, `2026년 6월 30일`
- Values: `4,500원`, `₩4,500`, `5000 원`
- Barcode text: long digit sequences with whitespace/hyphen normalization
- Brand/title: prioritize nearby label context and prominent OCR lines; do not invent missing values

Expiry ambiguity is preserved as multiple candidates. The UI, not the parser, asks the user to select the final date.

### Report Rules

`DiscoveryReport` derives:

- found candidate count
- D-7 expiring-soon count
- possibly-expired count
- protected value total from high-confidence values only

Low-confidence values must not contribute to protected value.

## Security and Privacy Notes

- OCR stays on-device. Do not add network clients, upload endpoints, analytics payloads containing image/OCR data, Firebase, or cloud SDKs.
- Dart receives normalized text and geometry only. Native file references stay opaque.
- Raw absolute file paths must not be stored as scan fingerprint tokens.
- Confirmed and manual passes use app-internal image copies.
- OCR candidates are never auto-saved.

## Validation Architecture

### Unit

- OCR schema normalization
- Korean date/value/barcode parser fixtures
- report aggregation and confidence threshold behavior
- candidate save readiness
- save/reject/manual registration orchestration

### Widget

- discovery report with and without protected value
- one-by-one candidate review
- date chips for ambiguous expiry
- disabled save until required fields confirmed
- reject advances without saving
- full-screen viewer preserves edits
- no-candidate manual registration
- 320x568 layout reachability

### Native Contract

- Dart method-channel adapter decodes normalized maps with `setMockMethodCallHandler`.
- Android build verifies ML Kit dependencies and API 23 floor.
- iOS source assertion verifies Vision channel registration in `didInitializeImplicitFlutterEngine`.
- Manual iOS smoke stays environment-blocked until Xcode/CoreSimulator is repaired.

## Sources

- [Flutter platform channels](https://docs.flutter.dev/platform-integration/platform-channels)
- [Google ML Kit Text Recognition v2 for Android](https://developers.google.com/ml-kit/vision/text-recognition/v2/android)
- [Google ML Kit Text Recognition v2 supported languages](https://developers.google.com/ml-kit/vision/text-recognition/v2/languages)
- [Apple VNRecognizeTextRequest](https://developer.apple.com/documentation/vision/vnrecognizetextrequest)
- [Apple VNRecognizedTextObservation](https://developer.apple.com/documentation/vision/vnrecognizedtextobservation)
- [Apple topCandidates(_:)](https://developer.apple.com/documentation/vision/vnrecognizedtextobservation/topcandidates(_:))

## RESEARCH COMPLETE

Phase 3는 기존 레이어를 유지하면서 pure Dart parser, fake-driven discovery orchestration, native OCR channel, Scan 탭 UI를 순서대로 구현할 수 있다.
