---
phase: 3
slug: ocr-candidate-review-and-discovery-report
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-31
---

# Phase 3 — Validation Strategy

> OCR candidate discovery, review, and save 흐름을 빠르게 검증하기 위한 계약이다.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter test (`flutter_test`) plus pure Dart unit tests |
| **Config file** | `pubspec.yaml` |
| **Quick run command** | `flutter test test/domain test/application test/platform test/presentation` |
| **Full suite command** | `flutter analyze && flutter test` |
| **Estimated runtime** | ~150 seconds on the configured Android/Flutter environment |

## Sampling Rate

- **After every task commit:** Run the focused test command from the task.
- **After every plan wave:** Run `flutter analyze && flutter test`.
- **Before `$gsd-verify-work`:** Full suite must be green and Android manual smoke should be attempted.
- **Max feedback latency:** 180 seconds.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | OCR-01, OCR-03 | T-03-01 | Native output is normalized and transient source refs stay separate from fingerprints | unit | `flutter test test/domain/ocr_text_test.dart test/domain/pass_candidate_test.dart test/domain/scan_item_test.dart` | ❌ W0 | ⬜ pending |
| 03-01-02 | 01 | 1 | OCR-02 | T-03-02 | Parser preserves uncertainty and never invents fields | unit | `flutter test test/application/pass_candidate_parser_test.dart` | ❌ W0 | ⬜ pending |
| 03-01-03 | 01 | 1 | SCAN-05 | T-03-03 | Protected total includes high-confidence value only | unit | `flutter test test/domain/discovery_report_test.dart` | ❌ W0 | ⬜ pending |
| 03-02-01 | 02 | 2 | OCR-03, OCR-04, OCR-05, OCR-06 | T-03-04 | Candidates save only after explicit confirmation | unit | `flutter test test/application/candidate_discovery_controller_test.dart` | ❌ W0 | ⬜ pending |
| 03-02-02 | 02 | 2 | OCR-03, OCR-06 | T-03-05 | Confirmed/manual save copies image and writes repository | unit | `flutter test test/application/candidate_discovery_controller_test.dart` | ❌ W0 | ⬜ pending |
| 03-03-01 | 03 | 2 | OCR-01 | T-03-06 | Android OCR is bundled and on-device | build/source | `flutter test test/platform/method_channel_ocr_text_recognizer_test.dart && flutter build apk --debug` | ❌ W0 | ⬜ pending |
| 03-03-02 | 03 | 2 | OCR-01 | T-03-07 | iOS Vision channel emits normalized blocks | source/contract | `flutter test test/platform/method_channel_ocr_text_recognizer_test.dart && rg -n "VNRecognizeTextRequest|FlutterMethodChannel" ios/Runner/AppDelegate.swift` | ❌ W0 | ⬜ pending |
| 03-04-01 | 04 | 3 | SCAN-05 | T-03-08 | Report omits invented totals | widget | `flutter test test/presentation/discovery_report_test.dart` | ❌ W0 | ⬜ pending |
| 03-04-02 | 04 | 3 | OCR-03, OCR-04, OCR-05 | T-03-09 | One-by-one review gates save and reject | widget | `flutter test test/presentation/candidate_review_test.dart` | ❌ W0 | ⬜ pending |
| 03-04-03 | 04 | 3 | OCR-06 | T-03-10 | Empty OCR result recovers through manual registration | widget | `flutter test test/presentation/manual_registration_test.dart` | ❌ W0 | ⬜ pending |
| 03-04-04 | 04 | 3 | SCAN-05, OCR-03..06 | T-03-11 | Full fake flow remains local and reachable | widget/static | `flutter test test/presentation/guided_scan_discovery_flow_test.dart && flutter analyze` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

## Wave 0 Requirements

Existing Flutter infrastructure is sufficient. Each plan creates its focused test file before implementation:

- [ ] `test/domain/ocr_text_test.dart`
- [ ] `test/domain/pass_candidate_test.dart`
- [ ] `test/domain/discovery_report_test.dart`
- [ ] `test/application/pass_candidate_parser_test.dart`
- [ ] `test/application/candidate_discovery_controller_test.dart`
- [ ] `test/platform/method_channel_ocr_text_recognizer_test.dart`
- [ ] `test/presentation/discovery_report_test.dart`
- [ ] `test/presentation/candidate_review_test.dart`
- [ ] `test/presentation/manual_registration_test.dart`
- [ ] `test/presentation/guided_scan_discovery_flow_test.dart`

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Android OCR build and app smoke | OCR-01, SCAN-05 | Confirms Gradle dependency, native channel registration, and report UI on emulator | Run `flutter run -d emulator-5554`, open Scan, select demo source, verify report and one-by-one review. |
| iOS OCR smoke | OCR-01 | Current Xcode/CoreSimulator issue remains outside app code | Repair/update Xcode/CoreSimulator first, then run iOS simulator smoke and record result separately. |

## Validation Sign-Off

- [x] All tasks have focused automated verify commands.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 lists all new focused test files.
- [x] No watch-mode flags.
- [x] Feedback latency target is under 180 seconds.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved for execution planning 2026-05-31
