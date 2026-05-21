---
phase: 1
slug: app-foundation-and-local-pass-model
status: complete
created: 2026-05-21
sources:
  - https://docs.flutter.dev/reference/flutter-cli
  - https://docs.flutter.dev/reference/create-new-app
  - https://docs.flutter.dev/platform-integration/platform-channels
  - https://docs.flutter.dev/testing/overview
  - https://docs.flutter.dev/cookbook/testing/widget/introduction
  - https://docs.flutter.dev/ui/accessibility/ui-design-and-styling
  - https://api.flutter.dev/flutter/widgets/Semantics-class.html
  - https://dart.dev/effective-dart
---

# Phase 1 Research: App Foundation and Local Pass Model

## Research Goal

Phase 1 계획을 잘 세우기 위해 필요한 것은 "어떤 Flutter 앱 기반을 만들면 후속 scan/OCR/wallet/reminder phase가 흔들리지 않는가"다. 이 phase는 실제 사진 선택, OCR, SQLite persistence, 알림, 결제를 구현하지 않는다. 대신 실행 가능한 Flutter app shell, pass domain model, repository/image-copy contracts, in-memory test doubles, Today/Wallet/Scan UX surface를 만든다.

## Local Environment Finding

- 현재 저장소 루트에는 Flutter 프로젝트 파일이 없다. `lib/`, `test/`, `pubspec.yaml`, `ios/`, `android/`가 아직 없다.
- 현재 shell에서 `flutter --version`은 `command not found`다. 실행 phase의 첫 task는 Flutter SDK 설치 여부와 PATH를 확인해야 하며, 없으면 Flutter SDK 설치/경로 설정이 blocker다.
- Flutter 공식 CLI 문서는 `flutter create`, `flutter analyze`, `flutter test`, `flutter run lib/main.dart` 흐름을 기본 개발 루프로 제시한다.

## Stack and Scaffold Guidance

### Flutter project creation

- 새 앱은 기존 저장소 안에 직접 scaffold해야 한다. `coupon-keeper` 폴더 자체가 앱 저장소이므로 계획은 `flutter create .` 계열 명령을 전제로 하되, 실행자는 Flutter CLI가 현재 디렉터리 scaffold를 허용하는지 확인해야 한다.
- Dart/Flutter 프로젝트 이름은 pubspec의 package name 제약에 맞춰 `coupon_keeper`를 사용한다. 저장소 폴더명은 kebab-case지만 Dart package name은 snake_case가 안전하다.
- iOS/Android 동시 지원이 핵심이므로 scaffold 결과에는 `ios/`, `android/`, `lib/`, `test/`, `pubspec.yaml`, platform runner 파일이 포함되어야 한다.

### App architecture

Planned structure from `AGENTS.md` should be made real:

- `lib/presentation/` — screens, widgets, routing/tab shell, UI states.
- `lib/application/` — use cases that connect UI to repository contracts.
- `lib/domain/` — pure `Pass`, enums, value objects, status/expiry rules.
- `lib/data/` — repository interfaces/test doubles and later SQLite implementation boundary.
- `lib/platform/` — interfaces/adapters for image copy and future native channels.

Phase 1 should keep domain rules pure Dart so unit tests do not require Flutter bindings or platform plugins.

### Platform channels

Flutter platform channel docs show that Flutter side `MethodChannel` calls asynchronously into Android/iOS implementations. Phase 1 should not implement OCR/photo/file/notification channels yet, but it should leave platform-facing interfaces that later adapters can implement:

- media/file selection adapter: Phase 2
- OCR adapter: Phase 3
- local notification scheduler: Phase 5
- in-app purchase adapter: Phase 6

Do not couple `PassRepository` to platform channels. Keep platform adapters behind application-layer use cases.

## Domain Model Research

### Pass type

`PassType` should be an enum:

- `coupon`
- `exchange`
- `membership`
- `barcode`
- `other`

The UI can emphasize coupons/exchange passes, but the domain model should not be coupon-only.

### Pass status and expiry

`PassStatus` should be an enum:

- `active`
- `used`
- `expired`
- `cleanupCandidate`
- `needsReview`

Use a domain method or derived getter to resolve effective status:

- If stored status is `active` and `expiry` is before the current day, effective status is `expired`.
- Explicit user states such as `used`, `cleanupCandidate`, and `needsReview` should not be overwritten by time-based expiry calculation.
- Pass tests should inject a clock/date instead of relying on `DateTime.now()` directly.

### Required fields

The model must support PASS-01:

- id
- type
- title
- brand
- estimated value
- expiry
- status
- source metadata
- image copy path
- OCR text
- confidence

Recommended value objects:

- `PassSourceMetadata`: original URI/path, platform source type, fingerprint/hash, importedAt, availability, missing reason.
- `PassConfidence`: map-like field confidence for `expiry`, `value`, `brand`, `barcode`, `overall`.

Keep freeform extension fields out of the core model until a concrete downstream requirement appears.

## Repository and Storage Contracts

### PassRepository

Phase 1 should define a repository contract with these semantics:

- create/save pass
- update pass
- delete pass by id
- get pass by id
- list all passes
- list by effective status
- list active passes with expiry correction
- list used passes
- list expired passes
- list cleanup candidates
- list needs-review passes

The contract should make date-sensitive queries explicit. Either pass a `DateTime today` argument into status-filtering methods or inject a clock into the repository/application service. The plan should avoid hidden real-time dependencies in tests.

### In-memory implementation

Phase 1 should include an in-memory repository as the official test double. It must enforce the same effective-status semantics expected from future SQLite implementation:

- Saving and retrieving preserves all PASS-01 fields.
- Active pass with past expiry is returned by expired/effective-expired query.
- Used and cleanup candidate states are not reclassified by expiry.
- Source missing metadata is preserved.

### Image copy store contract

Define an image copy store interface but keep implementation fake/in-memory in Phase 1:

- `copyIntoAppStorage(sourceRef)`
- `resolveImagePath(imageCopyPath)`
- `deleteCopy(imageCopyPath)`

The contract should allow PASS-02 to be modeled: the saved pass can still point at an app-internal image copy even if the source is unavailable. Actual filesystem copying belongs in a later phase.

## UI Shell Research

### Navigation

Use a Material 3 bottom navigation surface for mobile. In current Flutter, `NavigationBar` with `NavigationDestination` is the Material 3 bottom navigation pattern. The app needs exactly three destinations:

- Today
- Wallet
- Scan

Phase 1 should include widget tests that tap each destination and verify the selected screen content changes.

### First-run states

Phase 1 empty states must be real product copy, not placeholders:

- Today: scan CTA centered on loss prevention. CTA navigates to Scan tab.
- Wallet: quiet result space. No fake pass cards; explain saved passes will appear here after scan/confirmation.
- Scan: action space prepared for Phase 2. Show guided scan start surface without invoking native pickers yet.

### State chips

Prepare reusable state chip widget(s) for:

- `D-7`
- `오늘 만료`
- `만료됨`
- `사용 완료`
- `확인 필요`
- `원본 없음`

Chips must not rely on color alone. Include text and, where useful, an icon or semantic label.

## Accessibility and Small-Screen Research

Flutter accessibility docs align with the project bar:

- Android recommends 48x48 dp tap targets; iOS recommends 44x44 pt tap targets.
- Small text should meet at least 4.5:1 contrast.
- Flutter exposes accessibility testing through guideline APIs.
- `Semantics` can add labels and combine/exclude semantic nodes.

Phase 1 should require:

- Primary CTA hit target at least 44 logical pixels high.
- Body text at least 16 logical pixels.
- No essential status is expressed by color alone.
- Bottom navigation destinations have accessible labels.
- Scan CTA and status chips have semantic labels.
- Widget tests include small-screen constraints, for example a 320x568 logical-size test surface.

## Testing Strategy

Flutter official testing guidance separates unit, widget, and integration tests:

- Unit tests: fast tests for pure Dart functions/classes.
- Widget tests: build widgets with `WidgetTester`, find text/widgets, simulate taps, and pump frames.
- Integration tests: highest confidence but slower and best reserved for full flows.

Phase 1 should prioritize unit and widget tests:

- Unit: pass effective status transitions, confidence model serialization/equality if implemented, repository contract behavior with in-memory repository.
- Widget: app launches, bottom navigation switches tabs, Today CTA moves to Scan tab, empty states show real copy, core status chips render text and semantics.
- Integration: optional in Phase 1 unless Flutter scaffold/run verification is easy. Do not block planning on device/emulator integration tests before app behavior exists.

Commands expected after Flutter is installed:

- `flutter pub get`
- `flutter analyze`
- `flutter test`

## Validation Architecture

Validation should prove each Phase 1 requirement with automated checks where practical:

- SHELL-01: `flutter test` can pump the app root without exceptions; manual `flutter run` remains optional until SDK/device availability is confirmed.
- SHELL-02: widget test taps Today/Wallet/Scan navigation and verifies selected screen labels.
- SHELL-03: widget tests assert first-run empty state copy and CTA presence; no placeholder text such as `TODO` or `Lorem ipsum`.
- SHELL-04: widget test sets a small viewport and verifies primary CTA remains present and tappable.
- PASS-01: unit tests create a pass with every required field and assert values are preserved.
- PASS-02: repository/image copy fake tests show pass remains viewable via image copy path when source availability is missing.
- PASS-03: unit/repository tests cover active, used, expired, cleanupCandidate, needsReview and effective expiry correction.

Recommended validation files:

- `test/domain/pass_test.dart`
- `test/data/in_memory_pass_repository_test.dart`
- `test/presentation/app_shell_test.dart`
- `test/presentation/status_chip_test.dart`

## Security and Privacy Considerations

Threat model for Phase 1 is modest but still relevant:

- No server, login, sync, cloud backup, analytics SDK, or ad SDK should be introduced.
- Do not request photo/download permissions in Phase 1.
- Do not include sample coupon images with real barcodes or personal data.
- Fake image copy paths should be deterministic test strings, not real user file paths.
- Future platform channels should be represented as interfaces only; no native permission prompts yet.

## Planning Recommendations

Plan as a walking skeleton because Phase 1 is `Mode: mvp` and no prior phase summaries exist:

1. Scaffold Flutter project and establish folder structure.
2. Build domain model and repository/image-copy contracts with in-memory implementations.
3. Build the app shell and reusable UI pieces against the in-memory/application layer.
4. Add tests and verification commands.

If the planning workflow requires UI-SPEC before PLAN.md, stop after this research and generate UI-SPEC next. The UI-SPEC should lock visual/interaction details for Today, Wallet, Scan, empty states, status chips, small-screen behavior, and semantics labels.

## Research Complete

The phase can be planned once UI-SPEC gate is satisfied or explicitly skipped.
