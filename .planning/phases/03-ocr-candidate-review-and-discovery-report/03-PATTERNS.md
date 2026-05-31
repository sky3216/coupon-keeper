---
phase: 3
slug: ocr-candidate-review-and-discovery-report
status: complete
created: 2026-05-31
---

# Phase 3 Pattern Map

## 목적

Phase 3 구현자는 Phase 1의 pass 저장 계약과 Phase 2의 guided scan 경계를 재사용한다. OCR SDK 세부사항은 platform layer에 가두고, parser와 review flow는 fake로 빠르게 검증한다.

## Planned Files to Existing Patterns

| Planned File | Closest Existing Analog | Pattern to Reuse |
|--------------|-------------------------|------------------|
| `lib/domain/ocr_text.dart` | `lib/domain/pass_confidence.dart` | Flutter import 없는 작은 immutable value object. |
| `lib/domain/scan_item.dart` | Existing `ScanItem` | Fingerprint `sourceToken`과 transient `platformSourceRef` 책임을 분리한다. |
| `lib/domain/pass_candidate.dart` | `lib/domain/pass.dart` | 명시적인 필드, copy/update behavior, domain-derived readiness. |
| `lib/domain/discovery_report.dart` | `lib/domain/scan_progress.dart` | UI가 바로 소비할 수 있는 deterministic summary value. |
| `lib/application/pass_candidate_parser.dart` | New pure application service | OCR SDK import 없이 input/output만으로 test한다. |
| `lib/platform/ocr_text_recognizer.dart` | `lib/platform/image_copy_store.dart` | Platform capability를 abstract contract 뒤에 둔다. |
| `lib/platform/fake_ocr_text_recognizer.dart` | `lib/platform/fake_image_copy_store.dart` | deterministic success, empty, failure fixtures를 제공한다. |
| `lib/platform/method_channel_ocr_text_recognizer.dart` | No existing channel analog | Flutter `MethodChannel` decode만 담당하고 parsing/business logic을 넣지 않는다. |
| `lib/application/candidate_discovery_controller.dart` | `lib/application/guided_scan_controller.dart` | Domain/data/platform을 조합하는 얇은 orchestration layer. |
| `lib/presentation/screens/scan_screen.dart` | Existing `ScanScreen` | Start/progress/recovery state를 유지하고 Phase 3 report/review states를 추가한다. |
| `lib/presentation/widgets/discovery_report.dart` | `lib/presentation/widgets/scan_progress_summary.dart` | Stable summary rows, factual copy, state-based conditional rendering. |
| `lib/presentation/widgets/candidate_review_form.dart` | `lib/presentation/widgets/empty_state.dart` | Material widgets, 16px body, full-width actions, small-screen scroll behavior. |
| `android/app/src/main/kotlin/com/example/coupon_keeper/MainActivity.kt` | Flutter official MethodChannel example | `configureFlutterEngine()`에서 unique channel을 등록한다. |
| `ios/Runner/AppDelegate.swift` | Existing `FlutterImplicitEngineDelegate` setup | `didInitializeImplicitFlutterEngine()`에서 `FlutterMethodChannel`을 등록한다. |

## Existing Integration Points

### Scan Processing

`GuidedScanController`의 injected `ScanItemProcessor`가 Phase 3 연결점이다. `CandidateDiscoveryController.processItem`을 주입하면 OCR 성공 후에만 Phase 2 fingerprint cache가 item을 seen 처리한다.

### Pass Save

`PassRepository.save()`와 `ImageCopyStore.copyIntoAppStorage()`는 confirmed candidate와 manual registration의 저장 연결점이다. OCR 후보 자체는 repository에 저장하지 않는다.

### UI

`ScanScreen`은 현재 Phase 2 completion shell에서 disabled `후보 확인 준비`를 보여준다. Phase 3에서는 이 버튼을 실제 discovery report와 candidate review transition으로 바꾼다. `EmptyState`, `AppTheme`, `ScanProgressSummary`는 유지한다.

## Test Style

- Domain/application tests는 pure Dart fixture를 사용한다.
- Platform channel decode test는 Flutter mock method handler를 사용한다.
- Widget tests는 fake recognizer와 in-memory repository를 주입한다.
- Static privacy guard는 broad permission, network/cloud/upload SDK 문자열을 거부한다.
- 320x568 widget test는 `ensureVisible`과 tap으로 reachability를 검증한다.

## Planning Guardrails

- Native SDK result를 presentation에 직접 노출하지 않는다.
- OCR/image copy input은 fingerprint `sourceToken`이 아니라 transient `platformSourceRef`를 사용한다.
- OCR 결과를 `Pass`로 자동 저장하지 않는다.
- Unknown value를 fake value로 채우지 않는다.
- Barcode image decoding library를 추가하지 않는다.
- Scan start 또는 Wallet empty state에 manual registration CTA를 넓히지 않는다.
- iOS 환경 blocker와 app code defect를 섞지 않는다.
