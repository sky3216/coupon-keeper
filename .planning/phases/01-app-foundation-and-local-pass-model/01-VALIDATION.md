---
phase: 1
slug: app-foundation-and-local-pass-model
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-21
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter test (`flutter_test`) plus pure Dart unit tests |
| **Config file** | `pubspec.yaml` created in Wave 0 |
| **Quick run command** | `flutter test test/domain test/data` |
| **Full suite command** | `flutter analyze && flutter test` |
| **Estimated runtime** | ~60 seconds after Flutter SDK is installed |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/domain test/data` once domain/data test files exist.
- **After every plan wave:** Run `flutter analyze && flutter test`.
- **Before `$gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** 90 seconds after Flutter SDK is installed.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 0 | SHELL-01 | T-01-01 | No server/login/cloud dependency introduced | scaffold/analyze | `flutter analyze` | ❌ W0 | ⬜ pending |
| 01-01-02 | 01 | 1 | PASS-01 | T-01-02 | No real user paths or coupon images in fixtures | unit | `flutter test test/domain/pass_test.dart` | ❌ W0 | ⬜ pending |
| 01-01-03 | 01 | 1 | PASS-02 | T-01-03 | Source missing state does not expose real file paths | unit | `flutter test test/data/in_memory_pass_repository_test.dart` | ❌ W0 | ⬜ pending |
| 01-01-04 | 01 | 1 | PASS-03 | — | Effective expiry and explicit states are deterministic | unit | `flutter test test/domain/pass_test.dart test/data/in_memory_pass_repository_test.dart` | ❌ W0 | ⬜ pending |
| 01-02-01 | 02 | 2 | SHELL-02 | — | Navigation has accessible labels | widget | `flutter test test/presentation/app_shell_test.dart` | ❌ W0 | ⬜ pending |
| 01-02-02 | 02 | 2 | SHELL-03 | — | Empty states use product copy, not placeholders | widget | `flutter test test/presentation/app_shell_test.dart` | ❌ W0 | ⬜ pending |
| 01-02-03 | 02 | 2 | SHELL-04 | — | Primary actions meet small-screen/tap-target constraints | widget | `flutter test test/presentation/app_shell_test.dart test/presentation/status_chip_test.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `pubspec.yaml` — Flutter project dependencies and test infrastructure.
- [ ] `test/domain/pass_test.dart` — stubs for PASS-01 and PASS-03.
- [ ] `test/data/in_memory_pass_repository_test.dart` — stubs for PASS-02 and repository contract behavior.
- [ ] `test/presentation/app_shell_test.dart` — stubs for SHELL-01, SHELL-02, SHELL-03, SHELL-04.
- [ ] `test/presentation/status_chip_test.dart` — stubs for status chip text/semantics/tap-target checks.
- [ ] Flutter SDK available on PATH; if absent, execution must install/configure Flutter before verification commands can run.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| App launches on iOS simulator and Android emulator | SHELL-01 | Requires local Flutter SDK plus platform tooling/device availability | Run `flutter run` on one iOS simulator and one Android emulator after automated tests pass. Record any platform-specific blocker in SUMMARY.md. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s after Flutter SDK is installed
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
