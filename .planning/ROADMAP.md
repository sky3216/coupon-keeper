# Roadmap: Coupon Keeper

**Created:** 2026-05-21
**Mode:** Vertical MVP
**Granularity:** Standard
**Core Value:** 사용자가 잊고 있던 현금성 쿠폰 이미지를 찾아 만료 전에 쓰게 만든다.

## Overview

| Phase | Name | Goal | Requirements |
|-------|------|------|--------------|
| 1 | App Foundation and Local Pass Model | Launchable Flutter shell with core model, local storage contracts, and base UX states | SHELL-01..04, PASS-01..03 |
| 2 | Guided Scan Intake | User can select photos/downloads and see a cancellable batch scan shell with duplicate skipping | SCAN-01..04 |
| 3 | OCR Candidate Review and Discovery Report | User sees found coupon candidates, edits extracted fields, rejects false positives, and saves passes | SCAN-05, OCR-01..06 |
| 03.1 | Close gap: production local adapter wiring | Default app path uses real selected-source pickers, on-device OCR, SQLite persistence, and durable image copies | PASS-01..02, SCAN-02..04, OCR-01, OCR-03, OCR-06 |
| 4 | Wallet, Detail, and Cleanup Flow | User can browse, use, expand, mark used, and review cleanup candidates | WALL-01..06, CLEAN-01..04 |
| 5 | Reminder Engine | Free and Pro reminder rules schedule and reconcile local notifications | REM-01..04 |
| 6 | Pro Entitlement and Contextual Gates | User can purchase/restore Pro and sees upgrade prompts only in value moments | PRO-01..05 |
| 7 | Privacy, Accessibility, Testing, and Release Readiness | MVP is test-covered, accessible, privacy-aligned, and ready for iOS/Android internal distribution | QUAL-01..07 |

## Phases

### Phase 1: App Foundation and Local Pass Model

**Goal:** Create the Flutter app skeleton, domain model, repository contracts, and Today/Wallet/Scan shell.
**Mode:** mvp

**Requirements:** SHELL-01, SHELL-02, SHELL-03, SHELL-04, PASS-01, PASS-02, PASS-03

**Success Criteria:**
1. App launches locally with Today, Wallet, and Scan bottom navigation.
2. Empty states explain the next action without placeholder text.
3. Pass model supports type, expiry, status, source metadata, image copy path, OCR text, and confidence.
4. Unit tests cover pass status transitions and repository contract behavior.
5. Small-screen layout keeps primary actions reachable and readable.

### Phase 2: Guided Scan Intake

**Goal:** Let the user start a guided scan, select photos/downloads, and watch cancellable batch progress.
**Mode:** mvp

**Requirements:** SCAN-01, SCAN-02, SCAN-03, SCAN-04

**Success Criteria:**
1. User can enter scan from Today or Scan tab.
2. User can choose photos and downloads through guided selection, without broad first-launch scan.
3. Scan progress shows processed count, candidate count placeholder, and cancel action.
4. Fingerprint cache skips duplicate files in tests.
5. Platform adapters can be mocked for integration tests.

### Phase 3: OCR Candidate Review and Discovery Report

**Goal:** Turn selected images into candidate passes, show a discovery report, and let users confirm, edit, reject, or manually add.
**Mode:** mvp

**Requirements:** SCAN-05, OCR-01, OCR-02, OCR-03, OCR-04, OCR-05, OCR-06

**Status:** Android conversational UAT passed (7/7); security verified (`threats_open: 0`); Nyquist validation verified; iOS environment follow-up remains.

**Success Criteria:**
1. Native OCR adapter returns normalized text blocks on iOS and Android, with test doubles available.
2. Parser extracts likely expiry, value, brand, and barcode candidates with confidence.
3. First scan report shows found count, expiring-soon count, possibly expired count, and estimated protected value when confident.
4. User can edit candidate fields before saving.
5. User can reject false positives or manually register a pass.

### Phase 03.1: Close gap: production local adapter wiring (INSERTED)

**Goal:** Replace the demo default Scan path with production local adapters before Phase 4.
**Requirements:** PASS-01, PASS-02, SCAN-02, SCAN-03, SCAN-04, OCR-01, OCR-03, OCR-06
**Depends on:** Phase 3
**Plans:** 3 plans

**Success Criteria:**
1. User can select multiple photos, multiple image files, or one explicit folder through native system UI without broad-library scanning.
2. Folder intake checks direct child images only, and OCR remains iOS Vision or Android ML Kit on device.
3. Confirmed passes, fingerprints, and original-byte app-internal image copies survive app restart.
4. Partial failures preserve successful candidates and retry failed items only.
5. Production default composition uses real local adapters while deterministic fakes remain injectable in tests.

Plans:

**Wave 1**

- [x] `03.1-01-PLAN.md` — SQLite local persistence and durable original-byte image copies
- [x] `03.1-02-PLAN.md` — Native selected-source picker with bounded staging and retry handles

**Wave 2** *(blocked on Wave 1 completion)*

- [x] `03.1-03-PLAN.md` — Failed-item-only retry and production default composition

Cross-cutting constraints:

- Preserve explicit selected-source boundaries: no broad library scan and no recursive folder traversal.
- Preserve explicit-save behavior: OCR candidates stay review-only until user confirmation.
- Preserve local durability: successful save requires SQLite write plus reusable original-byte app-internal image copy.
- Preserve testability: fake adapters remain injectable even after production defaults switch to real adapters.

### Phase 4: Wallet, Detail, and Cleanup Flow

**Goal:** Make saved passes usable at the store and prevent used-source clutter without auto-deletion.
**Mode:** mvp
**Status:** MVP Light complete as of 2026-06-05.

**Requirements:** WALL-01, WALL-02, WALL-03, WALL-04, WALL-05, WALL-06, CLEAN-01, CLEAN-02, CLEAN-03, CLEAN-04

**Success Criteria:**
1. Wallet lists active passes and filters used, expired, and cleanup candidates.
2. Pass detail shows large coupon image, barcode panel, expiry, status, and bottom action bar.
3. Barcode panel supports tap-to-expand mode.
4. User can mark a pass as used and see it move to used/cleanup candidate state.
5. Missing source files are shown as recoverable states, not silent failures.

### Phase 5: Reminder Engine

**Goal:** Schedule useful expiry reminders locally and keep them correct as passes change.
**Mode:** mvp
**Status:** MVP Light complete as of 2026-06-05.

**Requirements:** REM-01, REM-02, REM-03, REM-04

**Success Criteria:**
1. Free passes schedule D-7 and D-Day local notifications.
2. Pro reminder plan supports D-7, D-3, D-1, D-Day, and custom reminders.
3. Saving or editing expiry reschedules relevant notifications.
4. App launch/resume cancels stale reminders and repairs missing ones.
5. Unit tests cover used, expired, missing expiry, and Pro/free reminder branches.

### Phase 6: Pro Entitlement and Contextual Gates

**Goal:** Add one-time Pro purchase, restore, local entitlement cache, and contextual gates.
**Mode:** mvp

**Requirements:** PRO-01, PRO-02, PRO-03, PRO-04, PRO-05

**Success Criteria:**
1. Free user is blocked from saving a 6th active pass with a contextual Pro gate.
2. Pro gate appears for custom reminders, unlimited save affordance, and cleanup candidate entry.
3. In-app purchase and restore flows are wired through platform/store interfaces.
4. Local entitlement cache unlocks Pro features and keeps free features usable when store checks fail.
5. Widget/integration tests cover purchase success, restore failure, and free fallback.

### Phase 7: Privacy, Accessibility, Testing, and Release Readiness

**Goal:** Harden the MVP so it is private, accessible, test-covered, and ready for internal store distribution.
**Mode:** mvp

**Requirements:** QUAL-01, QUAL-02, QUAL-03, QUAL-04, QUAL-05, QUAL-06, QUAL-07

**Success Criteria:**
1. No server login, sync, or cloud backup exists in MVP code.
2. No photos, coupon images, OCR text, or location data leave the device.
3. Today, Scan, Wallet, Detail, Pro Gate, and Cleanup expose loading, empty, error, success, and partial-success states.
4. Accessibility checklist passes for touch targets, contrast, screen reader labels, and non-color-only state indicators.
5. Unit, widget, and integration tests cover core flows.
6. iOS and Android internal test builds can be produced with documented commands.

## Requirement Coverage

All 44 v1 requirements are mapped to exactly one phase.

---
*Roadmap created: 2026-05-21*
