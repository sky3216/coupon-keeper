---
phase: 2
slug: guided-scan-intake
status: approved
created: 2026-05-24
sources:
  - https://docs.flutter.dev/platform-integration/platform-channels
  - https://docs.flutter.dev/testing/integration-tests
  - https://developer.android.com/training/data-storage/shared/photo-picker
  - https://developer.android.com/training/data-storage/shared/documents-files
  - https://developer.apple.com/documentation/photokit/phpickerviewcontroller
  - https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller
---

# Phase 2 Research: Guided Scan Intake

## 목표

Phase 2는 실제 OCR이나 후보 판정이 아니라, 사용자가 직접 고른 사진/파일만 대상으로 삼는 guided scan intake를 만든다. 사용자는 Scan 탭 또는 Today CTA에서 Scan으로 들어오고, 사진 또는 다운로드/파일을 선택한 뒤, 취소 가능한 batch 진행 상태와 중복 건너뜀 결과를 본다.

## 공식 문서에서 확인한 플랫폼 경계

- Flutter는 플랫폼 채널로 Dart 코드와 iOS/Android host API를 연결할 수 있다. Phase 2에서는 채널 구현을 깊게 만들기보다 Dart 인터페이스를 먼저 고정하고, 실행은 fake adapter로 검증한다.
- Flutter integration test는 `integration_test` 패키지와 `flutter_test` 스타일 API로 앱 단위 흐름을 검증할 수 있다. 다만 Phase 2의 핵심 흐름은 native picker 대신 fake adapter로 widget/application test에서 빠르게 검증하는 편이 피드백이 빠르다.
- Android Photo Picker는 전체 미디어 권한을 요구하지 않고 사용자가 선택한 이미지/비디오에 접근하는 안전한 시스템 UI다. Phase 2의 사진 선택 원칙과 맞다.
- Android Storage Access Framework는 `ACTION_OPEN_DOCUMENT` 및 `ACTION_OPEN_DOCUMENT_TREE`로 사용자가 선택한 파일 또는 디렉터리에 접근하게 한다. Android 11 이상에는 일부 디렉터리 선택 제한이 있으므로 “Downloads 전체를 자동 스캔”이 아니라 사용자가 선택한 파일/폴더만 처리해야 한다.
- iOS `PHPickerViewController`는 Photos 라이브러리에서 사용자가 선택한 asset만 앱에 전달하는 picker다. 전체 사진첩 접근보다 Phase 2의 trust line과 잘 맞다.
- iOS `UIDocumentPickerViewController`는 앱 sandbox 밖의 문서 접근을 사용자가 선택하는 방식으로 열어준다. security-scoped URL 같은 네이티브 세부 사항은 플랫폼 adapter 내부에 숨겨야 한다.

## 아키텍처 방향

Phase 2의 구현은 Flutter/Dart 계층에서 먼저 완성한다.

- `lib/domain/scan_source.dart`: 사진, 다운로드/파일 같은 source type과 화면 표시용 label을 담는다.
- `lib/domain/scan_item.dart`: 사용자가 선택한 항목의 stable id, display name, source type, optional size/modified metadata를 담는다.
- `lib/domain/scan_progress.dart`: processed/total, duplicateSkipped, candidateCountKnown 여부, cancellable 상태, result/error 상태를 표현한다.
- `lib/platform/scan_source_picker.dart`: 사진 선택과 다운로드/파일 선택을 추상화한다.
- `lib/platform/fake_scan_source_picker.dart`: tests에서 선택 결과, 사용자 취소, 접근 거부, 파일 없음을 결정적으로 반환한다.
- `lib/data/scan_fingerprint_cache.dart`: 이미 확인한 항목을 fingerprint로 판정하고 mark한다.
- `lib/data/in_memory_scan_fingerprint_cache.dart`: Phase 2 테스트용 구현체다. 영속 저장은 Phase 3 이후 SQLite 계획과 함께 확정한다.
- `lib/application/guided_scan_controller.dart`: 선택 결과를 받아 중복을 건너뛰고, 처리 진행 상태를 순차적으로 갱신하고, 취소를 반영한다.
- `lib/presentation/screens/scan_screen.dart`: source 선택, 진행, 취소, empty, error, completion shell 상태를 표시한다.

## 데이터와 fingerprint 전략

Phase 2 fingerprint는 개인정보나 원본 파일 경로를 저장하지 않는 최소 키로 시작한다.

- fake/native adapter는 `sourceType`, provider-local id 또는 content uri token, display name, size, modified timestamp를 domain item으로 넘긴다.
- fingerprint cache는 원본 절대 경로 대신 adapter가 제공한 stable token을 사용한다.
- 같은 token이 다시 들어오면 조용히 skip하고, UI에는 `이미 확인한 항목 N개는 건너뛰었어요`만 표시한다.
- 취소된 항목은 mark하지 않는다. 처리가 시작되어 완료된 항목만 cache에 기록한다.

## UI 상태 모델

Scan 화면은 하나의 state machine으로 두되, user-facing copy는 `02-UI-SPEC.md`를 단일 진실로 삼는다.

- `idle`: `어디에서 쿠폰을 찾을까요?`, 사진/다운로드 선택 affordance, trust line.
- `selecting`: native picker가 열린 상태. fake test에서는 즉시 결과를 반환한다.
- `running`: `{processed}/{total} 처리 중`, `후보 확인 준비 중`, duplicate skipped line, cancel.
- `cancelled`: `스캔을 멈췄어요`, actions `다시 선택`, `Scan 처음으로`.
- `empty`: `이번 선택에서는 쿠폰을 찾지 못했어요`, action `다시 선택`.
- `accessDenied`: `선택한 항목에 접근할 수 없어요`.
- `fileUnavailable`: `파일을 열 수 없어요`.
- `processingFailed`: `선택한 항목을 확인하지 못했어요`.
- `completed`: `선택한 항목 확인을 마쳤어요`, Phase 3로 이어지는 shell copy만 표시한다.

## 범위 밖

- 실제 OCR, 후보 검출, discovery report 수치, pass 저장은 Phase 3로 미룬다.
- 첫 실행에서 전체 사진첩, 전체 Downloads, 전체 파일 시스템을 훑지 않는다.
- broad photo/storage permission을 요구하지 않는다.
- fake coupon count, fake protected value, sample coupon card를 만들지 않는다.
- Today나 Wallet에서 native picker를 직접 열지 않는다. 두 CTA는 Scan 탭으로 이동한다.

## 위험과 대응

| 위험 | 영향 | 대응 |
|------|------|------|
| Phase 2가 platform picker 구현까지 과도하게 확장됨 | 계획 지연, flaky 테스트 | Dart 인터페이스와 fake adapter를 먼저 고정하고 native 구현은 얇은 stub 또는 후속 작업으로 제한한다. |
| 후보 수 placeholder가 실제 발견처럼 보임 | 신뢰 하락 | `후보 확인 준비 중`처럼 Phase 3 이전 상태임을 명확히 쓴다. |
| 중복 cache가 취소된 항목을 기록함 | 사용자가 다시 선택해도 누락 | 처리 완료된 item만 mark하는 acceptance criteria를 둔다. |
| 접근 거부/파일 없음/처리 실패가 같은 에러로 보임 | 사용자가 원인을 이해하지 못함 | `ScanFailure` variant와 widget test를 분리한다. |
| 작은 화면에서 버튼/상태 문구가 밀림 | 모바일 사용성 저하 | 320x568 widget test를 Phase 2 필수 검증으로 둔다. |

## Validation Architecture

Phase 2의 Nyquist 검증은 native picker를 실제로 열지 않고도 core contract를 샘플링해야 한다. 검증은 unit, widget, fake-driven integration 성격의 widget test로 나눈다.

| Dimension | Requirement | Automated Evidence |
|-----------|-------------|--------------------|
| Scan entry | SCAN-01 | Today CTA가 Scan 탭으로 이동하고 Scan 화면 idle state를 보여주는 widget test |
| User-selected scope | SCAN-02 | source 선택 UI와 fake picker 호출 test, broad permission/native package 미도입 static check |
| Batch progress/cancel | SCAN-03 | controller progress unit test와 progress/cancel widget test |
| Duplicate skip | SCAN-04 | fingerprint cache unit test와 duplicate summary widget test |
| Error/empty states | QUAL-03 support | empty, access denied, file unavailable, processing failed widget test |
| Accessibility/mobile fit | QUAL-04 support | 320x568 widget test, semantic label spot check |

## 권장 실행 순서

1. Domain/application/platform contracts를 먼저 만든다.
2. Scan 화면을 fake controller와 연결하고 UI-SPEC copy를 정확히 반영한다.
3. fake picker 기반 flow test와 static guard를 추가해 broad scan/permission 회귀를 막는다.

