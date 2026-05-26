---
phase: 2
slug: guided-scan-intake
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-24
---

# Phase 2 — Validation Strategy

> Phase 2 실행 중 빠르게 피드백을 얻기 위한 검증 계약이다.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter test (`flutter_test`) plus pure Dart unit tests |
| **Config file** | `pubspec.yaml` |
| **Quick run command** | `flutter test test/domain test/data test/application` |
| **Full suite command** | `flutter analyze && flutter test` |
| **Estimated runtime** | ~90 seconds on the configured Android/Flutter environment |

## Sampling Rate

- **After every task commit:** Run the relevant focused test command from the task.
- **After every plan wave:** Run `flutter analyze && flutter test`.
- **Before `$gsd-verify-work`:** Full suite must be green, and Android manual smoke test should be attempted.
- **Max feedback latency:** 120 seconds for automated checks.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | SCAN-02 | T-02-01 | Source model stores selected items only | unit | `flutter test test/domain/scan_item_test.dart` | ✅ | ✅ green |
| 02-01-02 | 01 | 1 | SCAN-04 | T-02-02 | Fingerprints avoid raw absolute paths | unit | `flutter test test/data/scan_fingerprint_cache_test.dart` | ✅ | ✅ green |
| 02-01-03 | 01 | 1 | SCAN-03, SCAN-04 | T-02-03 | Cancelled items are not marked scanned | unit | `flutter test test/application/guided_scan_controller_test.dart` | ✅ | ✅ green |
| 02-02-01 | 02 | 2 | SCAN-01, SCAN-02 | T-02-04 | Scan idle state does not request broad permission | widget | `flutter test test/presentation/scan_screen_test.dart` | ✅ | ✅ green |
| 02-02-02 | 02 | 2 | SCAN-03 | T-02-05 | Progress and cancel remain visible | widget | `flutter test test/presentation/scan_screen_test.dart` | ✅ | ✅ green |
| 02-02-03 | 02 | 2 | SCAN-03 | T-02-06 | Empty/error/completion states are explicit | widget | `flutter test test/presentation/scan_screen_test.dart` | ✅ | ✅ green |
| 02-03-01 | 03 | 3 | SCAN-01..04 | T-02-07 | End-to-end fake flow never opens native picker directly from Today | widget | `flutter test test/presentation/guided_scan_flow_test.dart` | ✅ | ✅ green |
| 02-03-02 | 03 | 3 | SCAN-02, SCAN-04 | T-02-08 | Static guard rejects broad-scan permissions/packages | unit/static | `flutter test test/presentation/guided_scan_flow_test.dart && flutter analyze` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

## Wave 0 Requirements

Existing infrastructure covers all phase requirements:

- [x] `pubspec.yaml` includes Flutter test infrastructure.
- [x] `test/domain`, `test/data`, and `test/presentation` already exist.
- [x] Android emulator path was verified in Phase 1 UAT.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Android smoke launch after Phase 2 | SCAN-01..04 | Confirms the Flutter app still opens on a real emulator and the Scan UI is reachable | Run `flutter run -d emulator-5554`, open Scan, tap source choices if native stubs are present, and record any blocker in `02-SUMMARY.md`. |
| iOS smoke launch | SCAN-01..04 | Current local Xcode/CoreSimulator issue is outside app code | Re-attempt only after Xcode/CoreSimulator is repaired; keep blocker separate from Phase 2 app verification. |

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or existing Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all MISSING references.
- [x] No watch-mode flags.
- [x] Feedback latency < 120s for automated checks.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** automated checks passed 2026-05-26; manual device smoke pending available devices.
