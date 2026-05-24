---
phase: 2-guided-scan-intake
plan: "02-01"
subsystem: application
tags: [flutter, dart, scan, fingerprint-cache, fake-adapter]
requires:
  - phase: 1-app-foundation-and-local-pass-model
    provides: Flutter project structure and platform contract patterns.
provides:
  - Guided scan source and item domain values.
  - Scan fingerprint cache contract and in-memory implementation.
  - Fake-driven scan source picker and guided scan controller.
affects: [phase-2-guided-scan-ui, phase-3-ocr-candidate-review]
tech-stack:
  added: []
  patterns:
    - Pure Dart domain/application contracts with fake platform adapters.
    - Stream-based guided scan state machine.
key-files:
  created:
    - lib/domain/scan_source.dart
    - lib/domain/scan_item.dart
    - lib/domain/scan_progress.dart
    - lib/data/scan_fingerprint_cache.dart
    - lib/data/in_memory_scan_fingerprint_cache.dart
    - lib/platform/scan_source_picker.dart
    - lib/platform/fake_scan_source_picker.dart
    - lib/application/guided_scan_controller.dart
    - test/domain/scan_item_test.dart
    - test/data/scan_fingerprint_cache_test.dart
    - test/application/guided_scan_controller_test.dart
  modified: []
key-decisions:
  - "Use adapter-provided source tokens instead of raw absolute file paths for scan fingerprints."
  - "Keep Phase 2 picker behavior fake-driven behind ScanSourcePicker so UI/tests do not depend on native picker packages."
  - "Use a pure Dart Stream-based controller state machine for idle/selecting/running/cancelled/error/completed states."
patterns-established:
  - "Scan contracts live in domain/data/platform/application layers before presentation consumes them."
  - "Fingerprint cache is async-friendly so SQLite persistence can replace in-memory storage later."
requirements-completed: [SCAN-02, SCAN-03, SCAN-04]
duration: 35 min
completed: 2026-05-24
---

# Phase 2 Plan 02-01: Guided Scan Domain, Adapters, and Controller Summary

**Selected-item scan contracts with duplicate skipping, cancellation, and fake picker outcomes**

## Performance

- **Duration:** 35 min
- **Started:** 2026-05-24T03:20:00Z
- **Completed:** 2026-05-24T03:55:00Z
- **Tasks:** 3
- **Files modified:** 11

## Accomplishments

- Added `ScanSourceType` and `ScanItem` domain values for photos and downloads/files, with stable fingerprint inputs that avoid display names and raw absolute paths.
- Added `ScanFingerprintCache` and `InMemoryScanFingerprintCache` to prove repeat selections are skipped without native file access.
- Added `ScanSourcePicker`, `FakeScanSourcePicker`, and `GuidedScanController` to model selecting, running, cancelling, duplicate skipping, picker failures, and processing failures.

## Task Commits

1. **Task 02-01-01: Create scan source and item domain values** - `1a35fc3`
2. **Task 02-01-02: Add fingerprint cache contract and in-memory implementation** - `807ecaf`
3. **Task 02-01-03: Add source picker interface, fake picker, and guided scan controller** - `077065f`

## Files Created/Modified

- `lib/domain/scan_source.dart` - Source enum and Korean UI labels/supporting copy for photos and downloads/files.
- `lib/domain/scan_item.dart` - Selected item value with source token, display name, metadata, and fingerprint input.
- `lib/domain/scan_progress.dart` - Guided scan status, failure variants, and immutable state.
- `lib/data/scan_fingerprint_cache.dart` - Async cache contract and batch result.
- `lib/data/in_memory_scan_fingerprint_cache.dart` - Testable in-memory fingerprint store.
- `lib/platform/scan_source_picker.dart` - Platform picker abstraction and result variants.
- `lib/platform/fake_scan_source_picker.dart` - Deterministic fake picker for tests.
- `lib/application/guided_scan_controller.dart` - Stream-based controller for scan intake state transitions.
- `test/domain/scan_item_test.dart` - Domain source and fingerprint tests.
- `test/data/scan_fingerprint_cache_test.dart` - Duplicate skip and storage safety tests.
- `test/application/guided_scan_controller_test.dart` - Progress, cancellation, duplicate, and failure tests.

## Decisions Made

- Source tokens are adapter-provided stable identifiers. The domain rejects obvious raw absolute paths such as `/Users/...` and `file:///...`.
- The controller does not create OCR text, pass records, candidate cards, or discovery report numbers.
- Successfully processed items are marked in the fingerprint cache; duplicate, cancelled, and failed items are not newly marked.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Non-interactive shell did not expose `flutter` from `.zshrc`; verification used `/Users/sora/Documents/MobileApps/tools/flutter/bin/flutter`.
- Flutter commands require sandbox escalation because the tool writes telemetry/session data under `/Users/sora/.dart-tool`.
- `flutter analyze` flagged constructor initialization style; the controller constructor was adjusted and analyze passed.

## Verification

- `flutter test test/domain/scan_item_test.dart` - passed.
- `flutter test test/data/scan_fingerprint_cache_test.dart` - passed.
- `flutter test test/application/guided_scan_controller_test.dart` - passed.
- `flutter test test/domain/scan_item_test.dart test/data/scan_fingerprint_cache_test.dart test/application/guided_scan_controller_test.dart` - 12 tests passed.
- `flutter analyze` - no issues found.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Wave 2 can consume `GuidedScanController`, `GuidedScanState`, source labels, and fake picker outcomes to build the Scan UI states without inventing new business rules.

---
*Phase: 2-guided-scan-intake*
*Completed: 2026-05-24*
