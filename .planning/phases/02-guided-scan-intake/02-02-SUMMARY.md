---
phase: 2-guided-scan-intake
plan: "02-02"
subsystem: ui
tags: [flutter, widget-test, scan-ui, material3]
requires:
  - phase: 2-guided-scan-intake
    provides: Guided scan controller, source picker, and state contracts from plan 02-01.
provides:
  - Guided Scan tab source selection UI.
  - Progress, duplicate skip, cancel, empty, error, partial, and completion UI states.
  - Widget tests for Scan UI states and Today/Wallet CTA routing.
affects: [phase-2-flow-verification, phase-3-ocr-candidate-review]
tech-stack:
  added: []
  patterns:
    - Stateful Scan screen driven by an injected GuidedScanController.
    - Bordered action rows for source selection.
    - Summary shell states that avoid fake discovery report numbers.
key-files:
  created:
    - lib/presentation/widgets/scan_source_choice.dart
    - lib/presentation/widgets/scan_progress_summary.dart
    - test/presentation/scan_screen_test.dart
  modified:
    - .gitignore
    - lib/presentation/screens/scan_screen.dart
    - test/presentation/app_shell_test.dart
key-decisions:
  - "Scan owns source selection and state rendering; Today and Wallet only route to the Scan tab."
  - "Completion is a Phase 3 handoff shell, not a discovery report."
  - "Use injected controllers in widget tests so picker, progress, and error states stay deterministic."
patterns-established:
  - "Scan UI uses exact UI-SPEC Korean copy and widget tests guard the important text."
  - "320x568 widget test remains part of Scan UI acceptance."
requirements-completed: [SCAN-01, SCAN-02, SCAN-03]
duration: 45 min
completed: 2026-05-26
---

# Phase 2 Plan 02-02: Guided Scan UI States Summary

**Guided Scan tab UI with selected-source entry, cancellable progress, duplicate feedback, and recovery states**

## Performance

- **Duration:** 45 min
- **Started:** 2026-05-24T03:55:00Z
- **Completed:** 2026-05-26T15:20:00Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Replaced the static Scan placeholder with a guided start surface using `어디에서 쿠폰을 찾을까요?`, source choices for photos and downloads/files, and the selected-only trust line.
- Added progress UI with processed/total count, candidate placeholder, duplicate skipped summary, and cancel action.
- Added cancelled, empty, access denied, file unavailable, processing failed, partial, and completion shell states.
- Updated app shell widget tests so Today/Wallet CTAs continue to route to Scan instead of opening a picker directly.

## Task Commits

1. **Task 02-02-01: Replace Scan empty placeholder with guided source selection** - `35de6ca`
2. **Task 02-02-02: Render running progress, duplicate skip, and cancel states** - `cc13c53`
3. **Task 02-02-03: Render empty, error, completion, and small-screen coverage** - `235bf47`

## Files Created/Modified

- `lib/presentation/screens/scan_screen.dart` - Stateful guided scan UI connected to `GuidedScanController`.
- `lib/presentation/widgets/scan_source_choice.dart` - Equal-weight source action rows.
- `lib/presentation/widgets/scan_progress_summary.dart` - Progress count, placeholder, and duplicate summary widget.
- `test/presentation/scan_screen_test.dart` - Widget tests for idle/progress/cancel/result/error/small-screen states.
- `test/presentation/app_shell_test.dart` - CTA routing and copy regression updates.
- `.gitignore` - Ignores local `.codex-flutter-home/` fallback used during sandboxed analysis.

## Decisions Made

- The default production `ScanScreen` currently uses a fake empty picker until native picker wiring is introduced later; all Phase 2 user-visible states are test-driven through injected controllers.
- Result shell buttons remain recovery/handoff affordances only. They do not create saved passes, candidate cards, found counts, protected values, or discovery reports.
- `ScanScreen` handles controller replacement via `didUpdateWidget` so widget tests and future dependency injection can swap controllers safely.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Earlier escalated tool calls were temporarily blocked by Codex usage limits; verification resumed successfully on 2026-05-26.
- A widget lifecycle issue appeared when tests injected a new controller into the same `ScanScreen`; `didUpdateWidget` and stream subscription cleanup were added.
- `.codex-flutter-home/` was added to `.gitignore` because sandbox-safe Flutter analysis may need a repo-local HOME fallback.

## Verification

- `flutter test test/presentation/scan_screen_test.dart --plain-name idle` - passed.
- `flutter test test/presentation/scan_screen_test.dart --plain-name progress` - passed.
- `flutter test test/presentation/scan_screen_test.dart test/presentation/app_shell_test.dart` - 10 tests passed.
- `flutter analyze` - no issues found.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 02-03 can now add fake-driven end-to-end flow coverage and privacy/scope regression guards across the controller and Scan UI.

---
*Phase: 2-guided-scan-intake*
*Completed: 2026-05-26*
