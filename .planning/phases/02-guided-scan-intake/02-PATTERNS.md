---
phase: 2
slug: guided-scan-intake
status: approved
created: 2026-05-24
---

# Phase 2 Pattern Map

## 목적

Phase 2 구현자는 새 구조를 만들기 전에 Phase 1에서 이미 검증된 경계를 재사용한다. 새 파일은 아래 analog를 먼저 읽고 같은 책임 분리와 테스트 스타일을 따른다.

## Planned Files to Existing Patterns

| Planned File | Closest Existing Analog | Pattern to Reuse |
|--------------|-------------------------|------------------|
| `lib/domain/scan_source.dart` | `lib/domain/pass_source_metadata.dart` | Source metadata를 domain value로 작게 유지하고 platform 세부사항을 숨긴다. |
| `lib/domain/scan_item.dart` | `lib/domain/pass.dart` | Immutable value object, required fields, deterministic derived properties. |
| `lib/domain/scan_progress.dart` | `lib/domain/pass_confidence.dart` | UI가 분기하기 쉬운 explicit enum/value object를 둔다. |
| `lib/data/scan_fingerprint_cache.dart` | `lib/data/pass_repository.dart` | 추상 contract를 data layer에 두고 앱 계층은 interface에 의존한다. |
| `lib/data/in_memory_scan_fingerprint_cache.dart` | `lib/data/in_memory_pass_repository.dart` | 테스트 가능한 in-memory 구현과 defensive copy 패턴을 쓴다. |
| `lib/platform/scan_source_picker.dart` | `lib/platform/image_copy_store.dart` | platform capability는 abstract interface로 숨긴다. |
| `lib/platform/fake_scan_source_picker.dart` | `lib/platform/fake_image_copy_store.dart` | fake는 성공/실패/취소 결과를 deterministic하게 반환한다. |
| `lib/application/guided_scan_controller.dart` | No direct Phase 1 analog | Domain/data/platform을 조합하는 얇은 orchestration layer로 만들고 UI state를 직접 빌드하지 않는다. |
| `lib/presentation/screens/scan_screen.dart` | `lib/presentation/screens/today_screen.dart`, `lib/presentation/widgets/empty_state.dart` | 화면은 product copy와 actions를 담당하고 business decision은 controller에 위임한다. |
| `test/domain/scan_item_test.dart` | `test/domain/pass_test.dart` | 순수 domain behavior를 빠르게 검증한다. |
| `test/data/scan_fingerprint_cache_test.dart` | `test/data/in_memory_pass_repository_test.dart` | 저장소 contract와 edge case를 test-first로 고정한다. |
| `test/presentation/scan_screen_test.dart` | `test/presentation/app_shell_test.dart` | `CouponKeeperApp` 또는 focused widget pump로 user-visible copy와 tap flow를 검증한다. |

## Implementation Conventions

- Domain 파일은 Flutter import 없이 순수 Dart로 유지한다.
- Platform 파일은 native 세부사항을 설명하지 않고 앱이 필요한 결과 타입만 노출한다.
- Presentation은 `02-UI-SPEC.md` copy를 그대로 사용한다.
- Tests는 fake data를 만들 수 있지만 user-facing fake coupon card, fake protected value, fake discovery report는 만들지 않는다.
- Today/Wallet CTA navigation pattern은 `AppShell`의 `_selectScan` 흐름을 유지한다.

