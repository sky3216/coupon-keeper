# Walking Skeleton — Coupon Keeper

**Phase:** 1
**Generated:** 2026-05-21

## Capability Proven End-to-End

A first-time user can launch the Flutter app, see the Today/Wallet/Scan shell, tap the Today scan CTA, land on Scan, while the app has a real local pass repository contract proven by in-memory read/write tests.

## Architectural Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Framework | Flutter Material 3 | The product needs one shared mobile UI across iOS and Android while keeping native features behind platform channels. |
| Data layer | `PassRepository` contract plus in-memory implementation in Phase 1; SQLite implementation deferred | Phase 1 must lock pass semantics and repository behavior without taking on SQLite migration/file-system complexity before scan intake. |
| Auth | None | MVP is local-only with no login, account, server sync, or cloud backup. |
| Deployment target | Local Flutter run/test commands; store/internal distribution deferred | Phase 1 proves local app launch and tests. TestFlight/Google Play internal testing belongs to release readiness. |
| Directory layout | `lib/presentation`, `lib/application`, `lib/domain`, `lib/data`, `lib/platform` | Matches `AGENTS.md` and keeps screens, use cases, pure domain, repositories, and native adapters separated. |

## Stack Touched in Phase 1

- [ ] Project scaffold (Flutter framework, build, lint, test runner)
- [ ] Routing/navigation — `Today`, `Wallet`, `Scan` bottom navigation
- [ ] Data layer — in-memory `PassRepository` read/write contract
- [ ] UI — Today CTA wired to Scan tab
- [ ] Local run/verification — `flutter analyze`, `flutter test`, and documented `flutter run`

## Out of Scope (Deferred to Later Slices)

- Real photo picker, file picker, folder access, or broad media permissions
- OCR, candidate discovery, and scan progress
- SQLite persistence and real app-internal image file copying
- Local notifications and reminder scheduling
- In-app purchase, Pro gate, and restore flows
- Pass detail barcode expansion and cleanup candidate workflow
- Server, login, sync, cloud backup, analytics SDK, or ad SDK

## Subsequent Slice Plan

Each later phase adds one vertical slice on top of this skeleton without altering its architectural decisions:

- Phase 2: guided scan intake from user-selected photos/downloads with cancellable progress
- Phase 3: OCR candidate review and first scan discovery report
- Phase 4: wallet list, pass detail, mark-used, and cleanup candidate flow
- Phase 5: local reminder engine
- Phase 6: Pro entitlement and contextual gates
- Phase 7: privacy, accessibility, testing, and release readiness
