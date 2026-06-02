---
phase: 3
slug: ocr-candidate-review-and-discovery-report
status: verified
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-31
audited: 2026-06-01
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
| **Estimated runtime** | ~20 seconds for full Flutter verification; ~20 seconds for Android debug APK build |

## Sampling Rate

- **After every task commit:** Run the focused test command from the task.
- **After every plan wave:** Run `flutter analyze && flutter test`.
- **Before `$gsd-verify-work`:** Full suite must be green and Android manual smoke should be attempted.
- **Max feedback latency:** 180 seconds.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | OCR-01, OCR-03 | T-03-01 | Native output is normalized and transient source refs stay separate from fingerprints | unit | `flutter test test/domain/ocr_text_test.dart test/domain/pass_candidate_test.dart test/domain/scan_item_test.dart` | ✅ | ✅ green |
| 03-01-02 | 01 | 1 | OCR-02 | T-03-02 | Parser preserves uncertainty and never invents fields | unit | `flutter test test/application/pass_candidate_parser_test.dart` | ✅ | ✅ green |
| 03-01-03 | 01 | 1 | SCAN-05 | T-03-03 | Protected total includes high-confidence value only | unit | `flutter test test/domain/discovery_report_test.dart` | ✅ | ✅ green |
| 03-02-01 | 02 | 2 | SCAN-05, OCR-03 | T-03-04, T-03-05 | Candidate discovery stays review-only and OCR failures remain retryable | unit | `flutter test test/application/candidate_discovery_controller_test.dart test/application/guided_scan_controller_test.dart` | ✅ | ✅ green |
| 03-02-02 | 02 | 2 | OCR-03, OCR-04, OCR-05, OCR-06 | T-03-06 | Confirmed/manual save copies image, writes repository, and reject avoids writes | unit | `flutter test test/application/candidate_discovery_controller_test.dart` | ✅ | ✅ green |
| 03-02-03 | 02 | 2 | SCAN-05, OCR-03..06 | — | App shell exposes deterministic guided-scan and discovery injection points | widget | `flutter test test/presentation/app_shell_test.dart test/presentation/guided_scan_discovery_flow_test.dart` | ✅ | ✅ green |
| 03-03-01 | 03 | 2 | OCR-01 | T-03-08 | Dart adapter sends transient source ref and decodes normalized native channel schema | unit | `flutter test test/platform/method_channel_ocr_text_recognizer_test.dart` | ✅ | ✅ green |
| 03-03-02 | 03 | 2 | OCR-01 | T-03-07 | Android OCR is bundled, selected-source-only, and buildable | build/source | `flutter test test/platform/method_channel_ocr_text_recognizer_test.dart && flutter build apk --debug` | ✅ | ✅ green |
| 03-03-03 | 03 | 2 | OCR-01 | T-03-09 | iOS Vision channel registers in implicit engine lifecycle and emits normalized blocks | source/contract | `flutter test test/platform/method_channel_ocr_text_recognizer_test.dart && rg -n "VNRecognizeTextRequest|FlutterMethodChannel|coupon_keeper/ocr" ios/Runner/AppDelegate.swift` | ✅ | ✅ green |
| 03-04-01 | 04 | 3 | SCAN-05 | T-03-10 | Report omits invented totals and keeps CTAs reachable on 320x568 | widget | `flutter test test/presentation/discovery_report_test.dart test/presentation/scan_screen_test.dart test/presentation/guided_scan_flow_test.dart` | ✅ | ✅ green |
| 03-04-02 | 04 | 3 | OCR-03, OCR-04, OCR-05 | T-03-11, T-03-12 | One-by-one review gates save, preserves edits, and keeps actions reachable on 320x568 | widget | `flutter test test/presentation/candidate_review_test.dart` | ✅ | ✅ green |
| 03-04-03 | 04 | 3 | OCR-06 | T-03-06, T-03-12 | Empty OCR recovers through selected-image manual registration with reachable small-screen controls | widget | `flutter test test/presentation/manual_registration_test.dart` | ✅ | ✅ green |
| 03-04-04 | 04 | 3 | SCAN-05, OCR-03..06 | T-03-10, T-03-11, T-03-12 | Full fake flow remains local, reachable, and guarded against broad permission/upload regressions | widget/static | `flutter test test/presentation/guided_scan_discovery_flow_test.dart test/presentation/guided_scan_flow_test.dart && flutter analyze && flutter test` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

## Wave 0 Requirements

Existing Flutter infrastructure is sufficient. Each plan creates its focused test file before implementation:

- [x] `test/domain/ocr_text_test.dart`
- [x] `test/domain/pass_candidate_test.dart`
- [x] `test/domain/discovery_report_test.dart`
- [x] `test/application/pass_candidate_parser_test.dart`
- [x] `test/application/candidate_discovery_controller_test.dart`
- [x] `test/platform/method_channel_ocr_text_recognizer_test.dart`
- [x] `test/presentation/discovery_report_test.dart`
- [x] `test/presentation/candidate_review_test.dart`
- [x] `test/presentation/manual_registration_test.dart`
- [x] `test/presentation/guided_scan_discovery_flow_test.dart`

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Android OCR build and app smoke | OCR-01, SCAN-05 | Confirmed during Phase 3 execution and UAT | Debug APK built; Android UAT passed discovery report and one-by-one review on `emulator-5554`. |
| iOS OCR smoke | OCR-01 | Current Xcode/CoreSimulator issue remains outside app code | Repair/update Xcode/CoreSimulator first, then run iOS simulator smoke and record result separately. |

## Requirement Coverage

| Requirement | Automated Evidence | Status |
|-------------|--------------------|--------|
| SCAN-05 | Discovery report widget, scan handoff, fake-driven full flow | ✅ covered |
| OCR-01 | Normalized OCR domain, Dart MethodChannel decode tests, Android APK build, iOS Vision source assertion | ✅ covered |
| OCR-02 | Korean date, value, brand, and barcode-like text parser fixtures | ✅ covered |
| OCR-03 | Review-only candidates, empty repository before explicit save, privacy regression guard | ✅ covered |
| OCR-04 | Editable candidate fields, explicit expiry confirmation, viewer edit preservation | ✅ covered |
| OCR-05 | Reject advances without repository or image-copy write | ✅ covered |
| OCR-06 | Empty OCR manual recovery, required-field gate, cancel return, app-internal image copy | ✅ covered |

## Validation Audit 2026-06-01

| Metric | Count |
|--------|-------|
| Gaps found | 1 |
| Resolved | 1 |
| Escalated | 0 |
| Tasks verified | 13 |
| Requirements covered | 7 |

Resolved gap: added 320x568 reachability coverage for discovery report actions and no-candidate manual registration controls, including cancel return.

## Validation Sign-Off

- [x] All 13 tasks have focused automated verify commands.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 lists and resolves all new focused test files.
- [x] No watch-mode flags.
- [x] Feedback latency target is under 180 seconds.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** verified 2026-06-01
