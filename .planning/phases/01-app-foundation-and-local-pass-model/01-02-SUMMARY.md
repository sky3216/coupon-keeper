---
phase: 01-app-foundation-and-local-pass-model
plan: "01-02"
subsystem: domain-data
tags: [dart, pass-model, repository, image-copy-store, unit-tests]
requires:
  - phase: 01-01
    provides: Flutter test infrastructure and project scaffold
provides:
  - Pass domain model with required fields and effective status rules
  - PassRepository contract and in-memory implementation
  - ImageCopyStore contract and fake deterministic implementation
affects: [phase-2-guided-scan-intake, phase-3-ocr-candidate-review, phase-4-wallet-detail-cleanup, phase-5-reminder-engine]
tech-stack:
  added: []
  patterns: [pure Dart domain model, async repository contract, official in-memory test double]
key-files:
  created:
    - lib/domain/pass.dart
    - lib/domain/pass_confidence.dart
    - lib/domain/pass_source_metadata.dart
    - lib/data/pass_repository.dart
    - lib/data/in_memory_pass_repository.dart
    - lib/platform/image_copy_store.dart
    - lib/platform/fake_image_copy_store.dart
    - test/domain/pass_test.dart
    - test/data/in_memory_pass_repository_test.dart
  modified: []
key-decisions:
  - "Effective expiry is a pure method that accepts DateTime today and never calls DateTime.now internally."
  - "The in-memory repository is the official contract test double until SQLite arrives."
  - "Image copy storage uses deterministic app://copies paths in Phase 1 and does not touch real files."
patterns-established:
  - "Date-sensitive pass queries accept an explicit DateTime."
  - "Source availability is modeled separately from app-internal image copy path."
requirements-completed: [PASS-01, PASS-02, PASS-03]
duration: 45min
completed: 2026-05-22
---

# Phase 1 Plan 01-02: Pass Model and Local Repository Contracts Summary

**Pure Dart pass model with field confidence, source metadata, effective status, repository contract, and in-memory test double**

## Performance

- **Duration:** 45 min
- **Started:** 2026-05-22T12:25:00Z
- **Completed:** 2026-05-22T13:11:56Z
- **Tasks:** 3
- **Files modified:** 85 total production/test files in shared production commit

## Accomplishments

- Added `Pass`, `PassType`, `PassStatus`, `PassConfidence`, and `PassSourceMetadata`.
- Implemented deterministic effective status behavior for active passes with past expiry.
- Added `PassRepository` and `InMemoryPassRepository` with status/effective-status queries.
- Added `ImageCopyStore` and `FakeImageCopyStore`, preserving source-missing metadata alongside app-internal image copy paths.

## Task Commits

All plan work was committed in the shared Phase 1 production commit:

1. **01-02-01: Add pure Dart pass model and status rules** - `a7d3d52`
2. **01-02-02: Add repository contract and in-memory implementation** - `a7d3d52`
3. **01-02-03: Add image copy store contract and fake implementation** - `a7d3d52`

## Files Created/Modified

- `lib/domain/pass.dart` - Pass model, enums, copy helper, and effective status logic.
- `lib/domain/pass_confidence.dart` - Field-level OCR confidence values.
- `lib/domain/pass_source_metadata.dart` - Original source reference, fingerprint, availability, and missing reason.
- `lib/data/pass_repository.dart` - Repository contract for CRUD and status queries.
- `lib/data/in_memory_pass_repository.dart` - Official in-memory implementation.
- `lib/platform/image_copy_store.dart` - Image copy store contract.
- `lib/platform/fake_image_copy_store.dart` - Deterministic fake store using `app://copies/`.
- `test/domain/pass_test.dart` - Domain status and field coverage.
- `test/data/in_memory_pass_repository_test.dart` - Repository and source-missing contract coverage.

## Decisions Made

- Used nullable `expiry`, `brand`, `estimatedValue`, `imageCopyPath`, and `ocrText` so OCR candidates and manually entered passes can be represented without fake values.
- Kept repository methods async so the same interface can later back SQLite without changing application call sites.
- Preserved explicit `used`, `cleanupCandidate`, and `needsReview` states even when expiry is in the past.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Self-Check: PASSED

- `flutter test test/domain/pass_test.dart` passed.
- `flutter test test/data/in_memory_pass_repository_test.dart` passed.
- `flutter analyze` passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `01-03`: the UI can now reuse pass/status language without introducing fake wallet data.

---
*Phase: 01-app-foundation-and-local-pass-model*
*Completed: 2026-05-22*
