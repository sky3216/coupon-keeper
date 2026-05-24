# Phase 2: Guided Scan Intake - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 2 turns the Phase 1 Scan shell into a guided intake flow. Users can start from Today or Scan, choose photos or download files/folders without broad first-launch scanning, see a cancellable batch progress surface, and have previously scanned files skipped by fingerprint.

This phase does not perform real OCR candidate extraction, discovery report UX, candidate editing/saving, reminder scheduling, Pro gating, or wallet detail behavior. It may produce scan job/result placeholders and test doubles so Phase 3 can attach OCR and discovery reporting cleanly.

</domain>

<decisions>
## Implementation Decisions

### Scan Entry and Source Selection

- **D-01:** The Scan tab becomes a guided start surface with two primary source choices: photos and downloads/files. The user should not see a broad "scan everything" affordance in MVP.
- **D-02:** Today and Wallet CTAs continue to route to the Scan tab first. They may highlight the guided intake start area, but they should not launch native pickers directly from another tab.
- **D-03:** Photos and downloads/files should be visually separated. Photos maps to the platform selected-photo picker path; downloads/files maps to a document/folder picker path such as Android Storage Access Framework and the iOS document picker/files flow.
- **D-04:** The copy must keep the Phase 1 trust promise: selected items only, processed on-device, no silent library scan.

### Batch Progress and Cancellation

- **D-05:** After source selection, show a dedicated scan progress view instead of leaving the user on the picker/start screen. The view should show processed count, total count, candidate count placeholder, duplicate skip count when nonzero, and a visible cancel action.
- **D-06:** Candidate count is allowed to be a placeholder or simulated count in Phase 2 because real OCR/candidate detection starts in Phase 3. It must be labeled honestly enough that no fake found coupons are implied.
- **D-07:** Cancel means stop scheduling/processing remaining selected items and return to a recoverable Scan state. Already processed/recorded fingerprints may remain recorded so the app does not reprocess the same files unnecessarily.
- **D-08:** The progress UI should support partial-success language from the start: some files can fail, be skipped, or remain unprocessed without making the whole scan feel broken.

### Duplicate and Fingerprint Handling

- **D-09:** Introduce a scan fingerprint cache contract in the application/data layer. It should be testable without native file access and should let Phase 2 prove `SCAN-04`.
- **D-10:** Duplicate files are skipped quietly during processing but summarized in the progress/result surface as `N개 이미 확인한 항목은 건너뛰었어요` or equivalent. Do not interrupt the user item-by-item.
- **D-11:** Fingerprint records should be scoped to the source file identity/content signature available from the platform adapter. The exact hash strategy is implementation discretion, but tests must prove repeat selections are skipped.

### Empty, Error, and Result Shell States

- **D-12:** If the selected batch produces no candidates, show a calm empty result state: `이번 선택에서는 쿠폰을 찾지 못했어요` plus actions to choose again and, if present as a shell affordance, manually add later. Do not treat no candidates as a failure.
- **D-13:** Separate user-cancelled, permission/access-denied, file-unavailable, and processing-failed states. Each state should offer a concrete recovery action such as choose again, retry remaining, or return to Scan.
- **D-14:** Phase 2 completion should hand off to a "ready for discovery report" shell, not the full Phase 3 report. If a completion summary exists, it should avoid fake brands, values, or coupon cards.

### Platform Adapter Boundaries

- **D-15:** Define platform-facing interfaces for media/file selection and scan item metadata, but keep UI and tests driven by fake adapters. The Flutter presentation layer should not depend directly on native picker packages or platform-channel details.
- **D-16:** Native channel implementation can be minimal or fake in Phase 2 if needed to keep planning bounded; however, the contracts must clearly support selected photos, downloads/files/folders, cancellation, file availability, and fingerprint inputs.

### the agent's Discretion

The user selected "Agent decides" for Phase 2 discussion. The planner may choose the exact state-management primitive, widget names, file layout under `lib/application`, and whether Phase 2 includes native platform-channel stubs or only Dart interfaces with fake adapters, as long as the decisions above and `SCAN-01..04` are satisfied.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project and Requirements

- `.planning/PROJECT.md` — Defines the local-only, guided scan-first product promise and MVP boundaries.
- `.planning/REQUIREMENTS.md` — Defines Phase 2 requirements `SCAN-01..04` and keeps `SCAN-05` in Phase 3.
- `.planning/ROADMAP.md` — Defines Phase 2 goal and success criteria.
- `.planning/STATE.md` — Records current phase status and the iOS environment blocker that should not be confused with app code defects.
- `AGENTS.md` — Defines repository workflow rules and branch/commit/push expectations.

### Prior Phase Decisions

- `.planning/phases/01-app-foundation-and-local-pass-model/01-CONTEXT.md` — Locks Today/Wallet/Scan roles, pass model direction, repository contracts, and Phase 2 handoff points.
- `.planning/phases/01-app-foundation-and-local-pass-model/01-UI-SPEC.md` — Defines the Scan tab as an action space and the quiet wallet utility visual direction.
- `.planning/phases/01-app-foundation-and-local-pass-model/01-UAT.md` — Confirms Phase 1 app shell and Scan tab pass on Android; notes iOS simulator environment follow-up.

### Product and Architecture Docs

- `docs/coupon-wallet-design.md` — Contains locked engineering decisions, proposed scan data flow, interaction states, and first scan emotional arc.
- `.planning/research/STACK.md` — Recommends Flutter platform channels, iOS PhotosPicker, Android selected photo access, Storage Access Framework, and integration tests.
- `.planning/research/PITFALLS.md` — Warns against broad photo access too early and treating automated results as truth.
- `.planning/research/SUMMARY.md` — Summarizes v1 table stakes and differentiators around guided scan, discovery report, and local privacy.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `lib/presentation/screens/scan_screen.dart` — Current Scan shell contains the Phase 2 entry copy and should be replaced or expanded into the guided intake start state.
- `lib/presentation/screens/today_screen.dart` and `lib/presentation/screens/wallet_screen.dart` — Existing CTAs route to Scan and should keep that behavior.
- `lib/presentation/shell/app_shell.dart` — Owns bottom navigation and can keep tab routing while Scan owns the intake flow.
- `lib/presentation/widgets/empty_state.dart` — Reusable for Scan start, empty result, permission/access error, and cancelled states.
- `lib/platform/image_copy_store.dart` and `lib/platform/fake_image_copy_store.dart` — Existing platform contract/test-double pattern should guide new media/file selection and fingerprint contracts.

### Established Patterns

- Flutter UI is organized by `presentation/screens`, `presentation/widgets`, and `presentation/shell`; pure contracts live outside presentation.
- Tests already use widget tests to prove navigation and copy, and pure Dart tests for repository/domain contracts.
- User-facing copy is Korean, file/folder names are English kebab-case, and no fake coupon cards/sample brands should appear before real user data.
- The app should preserve the local-only privacy promise and avoid broad first-launch permissions.

### Integration Points

- Scan start connects to source selection interfaces in `lib/platform` or `lib/application`.
- Batch scan state connects to an application-level coordinator/use case that can be driven by fake selected items in tests.
- Fingerprint cache connects to the existing pass/source metadata direction through `PassSourceMetadata.fingerprint`, but it should be a scan-level cache before saved passes exist.
- Phase 3 should be able to consume the selected/processed item records and attach OCR/candidate discovery without rewriting Phase 2 UI states.

</code_context>

<specifics>
## Specific Ideas

- Scan source choices should feel like user-controlled actions, not background surveillance.
- Duplicate skip feedback should be summarized, not interruptive.
- Empty result copy should be reassuring and actionable, not error-like.
- Progress should make an impatient first-time user feel the app is doing finite work: processed count, total count, cancel, and honest placeholder candidate count.

</specifics>

<deferred>
## Deferred Ideas

- Full first scan discovery report with found count, expiring-soon count, possibly expired count, and estimated protected value belongs to Phase 3 (`SCAN-05`).
- Pro wider auto-scan remains deferred to v2/Pro validation, not Phase 2.
- Manual pass registration may appear as a shell affordance if useful, but real manual registration belongs with candidate confirmation/detail flows.
- Apple Wallet/Google Wallet integration, location reminders, server receipt validation, ads, and on-device model improvements stay in TODO/v2 scope.

</deferred>

---

*Phase: 2-Guided Scan Intake*
*Context gathered: 2026-05-24*
