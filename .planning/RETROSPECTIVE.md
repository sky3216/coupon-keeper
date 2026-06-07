# Retrospective: Coupon Keeper

## Milestone: v1.0 — MVP

**Shipped:** 2026-06-07
**Phases:** 8 including inserted Phase 3.1
**Plans/slices:** 23 completed summaries

### What Was Built

- Local-only Flutter coupon wallet with `Today`, `Wallet`, and `Scan`.
- Selected-source guided scan with progress, cancellation, duplicate skipping, partial retry, and no broad-library scanning.
- On-device OCR candidate flow using Android ML Kit and iOS Vision, with review/edit/reject/manual registration before save.
- SQLite pass storage, fingerprint cache, app-internal original-byte image copies, and source-missing recovery.
- Wallet filters, pass detail, image/barcode expansion, used/cleanup candidate states, and source cleanup handoff.
- Local reminder engine for free/Pro rules plus native notification adapters.
- Official `in_app_purchase` Pro purchase/restore gateway and local entitlement cache.
- Privacy/accessibility/release readiness verification for internal iOS/Android distribution.

### What Worked

- The guided scan-first privacy model kept permission scope clear while still allowing real source picking later.
- Phase 3.1 was a useful correction point: it closed demo-adapter and persistence gaps before Wallet work depended on them.
- MVP Light reduced ceremony for Phase 4~7 while still preserving `flutter analyze`, `flutter test`, Android build/run, and release build evidence.
- User screenshots during UAT caught real UX readiness gaps that widget tests alone had missed.

### What Was Inefficient

- Early strict milestone audit ran before Phase 4~7 existed, then had to be superseded by a later audit.
- Some GSD tooling counted completed MVP Light UAT artifacts as open items because their shape differed from strict workflow expectations.
- iOS environment repair took multiple diagnostic passes before the actual Xcode/runtime/deployment-target alignment was complete.

### Patterns Established

- Keep production dependencies in `CouponKeeperDependencies.production()` and assert the default path avoids fake/demo adapters.
- Store selected-source data as app-internal copies and opaque fingerprints; avoid raw path reliance.
- Treat OCR output as candidate evidence, not truth.
- Separate app-code release readiness from store-console operations.

### Key Lessons

- MVP speed is better served by vertical slices with strong automated checks than by full heavyweight gates on every slice.
- UAT copy should describe what the current build can actually show; otherwise users will rightly challenge mismatches.
- Local-only product claims need manifest/static tests, not just documentation.
- Tooling false positives should be recorded, but product completion should be decided from concrete evidence.

### Cost Observations

- Model mix and session count were not instrumented in repo-local artifacts.
- The largest time cost came from environment repair and repeated UAT gap closure, not from core Flutter implementation.

## Cross-Milestone Trends

| Trend | v1.0 Observation | Watch Next |
|-------|------------------|------------|
| Privacy scope | Selected-source-only worked well | Be careful with any Pro auto-scan expansion |
| Verification | 126 Flutter tests plus release builds give strong app-code confidence | Add real store sandbox purchase/restore verification |
| Workflow | MVP Light improved velocity | Keep only gates that map to current risk |
