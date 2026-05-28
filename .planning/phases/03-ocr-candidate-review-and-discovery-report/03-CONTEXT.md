# Phase 3: OCR Candidate Review and Discovery Report - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 3 turns the Phase 2 guided scan completion shell into a real OCR candidate review flow. The app takes only the images/files the user selected, runs on-device OCR through iOS Vision or Android ML Kit, parses pass candidates, shows a first scan discovery report, and lets the user review candidates one by one before saving, rejecting, or manually registering a pass.

This phase does not add broad background photo/library scanning, server sync, cloud OCR, reminder scheduling, Pro gating, Wallet detail usage flows, barcode image decoding, source cleanup, or automatic source deletion. It may save confirmed passes into the existing pass repository contract so Phase 4 can display them in Wallet.

</domain>

<decisions>
## Implementation Decisions

### Discovery Report First Impression

- **D-01:** The first discovery report should use a savings-outcome tone. When confident values exist, lead with the amount the user can protect from expiring instead of only saying that candidates were found.
- **D-02:** Savings totals must be conservative. Only high-confidence value parses are included in the protected-value total. Low-confidence values stay on individual candidate cards as fields that need confirmation.
- **D-03:** If no high-confidence value exists, the report falls back to candidate confirmation language rather than showing an estimated or invented amount.
- **D-04:** The report's "expiring soon" count uses a 7-day threshold, matching the free D-7 reminder value planned for Phase 5.
- **D-05:** The primary action from the report is `후보 검토 시작`, which moves directly into one-by-one candidate review.

### OCR Candidate Confidence and Save Rules

- **D-06:** OCR results are candidates, not saved passes. The app must never auto-save a pass from OCR alone.
- **D-07:** A candidate is considered save-ready only after the user confirms a title or brand plus an expiry date. Estimated value is useful but not required for saving.
- **D-08:** When OCR finds multiple possible expiry dates or an expiry date has low confidence, the UI shows date candidates and asks the user to choose one instead of silently locking the top guess.
- **D-09:** Phase 3 barcode handling is limited to barcode-like numeric text candidates found in OCR output. Image barcode decoding is deferred.
- **D-10:** The save action is disabled until the required fields are confirmed: title or brand, plus expiry date.

### Candidate Review and Editing Flow

- **D-11:** Candidate review is one card at a time. Each card includes an image preview, editable title, brand, expiry, value, and any barcode text candidate.
- **D-12:** The original image appears as a top preview on the candidate card, with a tap-to-expand affordance for checking the OCR result against the source image.
- **D-13:** Rejecting a false positive immediately advances to the next candidate. Phase 3 does not collect rejection reasons.
- **D-14:** After saving a candidate, the flow continues to the next candidate until the batch is done. It should not jump to Wallet after each save.

### OCR Failure and Manual Registration

- **D-15:** If OCR finds no candidates, show a calm empty result plus a manual registration CTA. This is a recovery path, not an error.
- **D-16:** Manual registration uses the same minimum required fields as OCR confirmation: title or brand, plus expiry date.
- **D-17:** Manual registration is available from the no-candidate result and from the candidate review flow. It is not added to the Scan start screen or Wallet empty state in this phase.
- **D-18:** When manual registration starts from a selected image, the pass should keep that image through the app-internal image copy flow so the user can still use the coupon in-store and survive source deletion.

### Privacy, Trust, and Platform Boundaries

- **D-19:** OCR must be on-device only. Do not introduce network OCR, login, server upload, analytics of image/OCR contents, or cloud backup.
- **D-20:** OCR and parser code should be testable with deterministic fake OCR results. Native adapters are required for iOS and Android, but app logic and UI tests should not depend on real platform OCR output.
- **D-21:** Scan fingerprints should be marked only for items that complete the OCR/candidate processing path, preserving Phase 2's duplicate-skip trust model.

### the agent's Discretion

The planner and executor may choose exact class names, state-management primitives, parser thresholds, confidence score scales, date parsing implementation details, and widget decomposition as long as the decisions above are satisfied. The implementation should prefer existing `domain`, `application`, `data`, `platform`, and `presentation` layering.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project and Requirements

- `.planning/PROJECT.md` — Defines local-only privacy, guided scan-first UX, Flutter plus native platform channel architecture, OCR provider direction, and pass-centric model.
- `.planning/REQUIREMENTS.md` — Defines Phase 3 requirements `SCAN-05` and `OCR-01..06`.
- `.planning/ROADMAP.md` — Defines Phase 3 goal and success criteria.
- `.planning/STATE.md` — Records current workflow state and environment blockers.
- `AGENTS.md` — Defines repository workflow rules, Korean documentation, app directory boundaries, and branch/commit/push expectations.

### Prior Phase Decisions

- `.planning/phases/01-app-foundation-and-local-pass-model/01-CONTEXT.md` — Locks pass model fields, repository contracts, image copy store contract, and quiet wallet utility direction.
- `.planning/phases/01-app-foundation-and-local-pass-model/01-UI-SPEC.md` — Defines Today/Wallet/Scan shell roles and base mobile UI quality bar.
- `.planning/phases/02-guided-scan-intake/02-CONTEXT.md` — Locks selected-items-only scanning, duplicate skip handling, progress shell, and Phase 3 handoff boundary.
- `.planning/phases/02-guided-scan-intake/02-UI-SPEC.md` — Defines the guided scan start/progress/completion surfaces that Phase 3 will extend.
- `.planning/phases/02-guided-scan-intake/02-SUMMARY.md` — Summarizes the shipped guided scan implementation, duplicate skip behavior, and UAT status.

### Product and Architecture Docs

- `docs/coupon-wallet-design.md` — Contains accepted product direction, first scan emotional arc, discovery report idea, and local privacy constraints.
- `.planning/research/STACK.md` — Recommends Flutter platform channels and platform-native OCR direction.
- `.planning/research/PITFALLS.md` — Warns against broad photo access, treating automated results as truth, and privacy-risky shortcuts.
- `.planning/research/SUMMARY.md` — Summarizes guided scan, discovery report, and local-only differentiators.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `lib/application/guided_scan_controller.dart` — Current scan coordinator emits selected-source progress/completion states and should become the handoff point for OCR candidate discovery.
- `lib/domain/scan_item.dart` and `lib/domain/scan_source.dart` — Existing selected item/source contracts preserve the selected-items-only privacy boundary.
- `lib/data/scan_fingerprint_cache.dart` and `lib/data/in_memory_scan_fingerprint_cache.dart` — Existing duplicate-skip contract should continue to protect repeated selections.
- `lib/domain/pass.dart`, `lib/domain/pass_confidence.dart`, and `lib/domain/pass_source_metadata.dart` — Existing pass model already supports OCR text, confidence, source metadata, image copy path, expiry, value, brand, and `needsReview`.
- `lib/data/pass_repository.dart` and `lib/data/in_memory_pass_repository.dart` — Existing repository contract is the save target for confirmed passes.
- `lib/platform/image_copy_store.dart` and `lib/platform/fake_image_copy_store.dart` — Existing app-internal image copy contract should be used for confirmed OCR and manual passes.
- `lib/presentation/screens/scan_screen.dart` — Current Phase 2 completion state has `후보 확인 준비`; Phase 3 should replace that disabled shell with the real report/review flow.
- `lib/presentation/widgets/empty_state.dart` and `lib/presentation/theme/app_theme.dart` — Existing empty state and theme patterns should be reused for no-candidate and manual registration entry states.

### Established Patterns

- Pure domain/application/data code stays free of Flutter UI imports.
- Platform features are represented by interfaces and fake adapters first, then native channel implementations.
- User-facing copy is Korean and should remain calm, trust-building, and specific.
- Widget tests cover user-visible flows; pure Dart tests cover parser/domain/application behavior.
- The app avoids fake coupon brands, fake saved passes, and fake protected-value totals before real OCR/user-confirmed data exists.

### Integration Points

- Phase 2 selected items need to feed a Phase 3 discovery controller/service that runs image copy, OCR recognition, parsing, report aggregation, candidate review, rejection, manual registration, and confirmed pass save.
- The Scan tab should remain the main entry point for source selection and OCR candidate review.
- Confirmed passes should be saved through `PassRepository`; Wallet display and pass detail expansion remain Phase 4 responsibilities.
- Native OCR adapters attach under `lib/platform` and the existing Android/iOS app entry points, while tests use fake OCR recognizers.

</code_context>

<specifics>
## Specific Ideas

- The discovery report should feel like "놓칠 뻔한 금액을 찾았다" when value confidence is high, but never exaggerate uncertain OCR.
- Candidate review should feel focused and mobile-friendly: one card, one source image preview, one save/reject decision at a time.
- OCR failure should not strand the user. The app should offer a direct manual registration recovery path using the selected image.
- Date ambiguity should be resolved by user choice rather than hidden automatic selection.

</specifics>

<deferred>
## Deferred Ideas

- Image barcode decoding with a dedicated barcode scanner library is deferred beyond Phase 3.
- Manual registration from the Scan start screen or Wallet empty state is deferred; Phase 3 keeps it contextual to OCR failure and candidate review.
- Rejection reasons, correction learning, automatic photo/library scanning, and Pro wider scan are deferred to future phases.

</deferred>

---

*Phase: 3-OCR Candidate Review and Discovery Report*
*Context gathered: 2026-05-28*
