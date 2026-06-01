---
phase: 03
slug: ocr-candidate-review-and-discovery-report
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-01
---

# Phase 3 — Security

> OCR 후보 발견, 검토, 저장 흐름의 로컬 처리 경계와 계획 단계 threat model 완화를 검증했다.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Selected source → native OCR adapter | 사용자가 명시적으로 고른 이미지 참조만 네이티브 OCR에 전달한다. | transient `platformSourceRef`, selected image |
| Native OCR adapter → Dart domain | Android ML Kit와 iOS Vision 결과를 공통 Dart 값으로 정규화한다. | OCR text, confidence, normalized bounds |
| Candidate session → pass repository | OCR 후보는 세션에만 머물고 사용자 저장 동작 뒤에만 저장소를 쓴다. Phase 1 원본 유실 추적 계약에 따라 확정 저장 시 선택 source ref를 `originalUri`로 보존한다. | confirmed pass metadata, original source ref, OCR text, app-internal image copy |
| Candidate UI → user confirmation | 불확실한 필드는 사용자가 확인하고 만료일을 명시적으로 선택한다. | editable title, brand, expiry, value, barcode-like text |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-03-01 | Tampering | OCR domain boundary | mitigate | 네이티브 SDK 타입을 `OcrTextResult`, `OcrTextBlock`, `OcrTextLine` pure Dart 값으로 정규화한다. | closed |
| T-03-02 | Tampering | Coupon parser | mitigate | 복수 만료일 후보를 보존하고 `confirmedExpiry`가 없으면 저장할 수 없으며, 근거 없는 필드는 비워 둔다. | closed |
| T-03-03 | Tampering | Discovery report | mitigate | `highConfidenceValueThreshold = 0.8` 이상인 값만 보호 금액에 포함하고, 없으면 합계를 숨긴다. | closed |
| T-03-04 | Tampering | Candidate discovery session | mitigate | 후보 수집은 저장소를 쓰지 않으며 `saveCurrentCandidate()` 또는 직접 등록 저장에서만 Pass를 만든다. | closed |
| T-03-05 | Denial of Service | Guided scan retry boundary | mitigate | OCR 실패는 processor에서 throw되고 `markSeen()` 전에 실패 처리되어 같은 항목을 다시 시도할 수 있다. | closed |
| T-03-06 | Tampering | Confirmed/manual save | mitigate | 확인 저장과 직접 등록 저장 모두 `ImageCopyStore.copyIntoAppStorage()` 뒤에 Pass를 저장한다. | closed |
| T-03-07 | Denial of Service | Android OCR dependencies | mitigate | Android는 번들 `text-recognition`과 `text-recognition-korean` 의존성을 사용한다. | closed |
| T-03-08 | Tampering | Native channel schema | mitigate | Android와 iOS가 같은 block/line map을 반환하고 Dart decode 테스트가 transient source ref와 schema를 검증한다. | closed |
| T-03-09 | Denial of Service | iOS UIScene lifecycle | mitigate | iOS 채널을 `didInitializeImplicitFlutterEngine`에서 등록한다. | closed |
| T-03-10 | Tampering | Discovery report UI | mitigate | UI는 report 값을 그대로 렌더링하며 보호 금액이 없으면 숫자 합계 대신 안내 문구를 보여준다. | closed |
| T-03-11 | Tampering | Candidate review UI | mitigate | `candidate.isSaveReady`가 제목 또는 브랜드와 명시적 만료일 확인을 요구하고 저장 버튼 활성 상태와 연결된다. | closed |
| T-03-12 | Denial of Service | Small-screen review UI | mitigate | 검토 폼은 세로 스크롤, wrapping 날짜 chip, full-width action을 사용하고 320x568 도달성 테스트를 통과한다. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Verification Evidence

| Check | Result |
|-------|--------|
| Threat-linked domain, controller, channel, and widget tests | passed, 27/27 |
| Privacy static guard and discovery report UI tests | passed, 6/6 |
| `flutter analyze` | passed, no issues |
| Android release manifest broad media permission scan | passed |
| iOS plist broad photo permission scan | passed |
| Network/cloud/upload SDK scan | passed |

Android의 `INTERNET` 권한은 Flutter 개발 연결을 위한 `debug/profile` manifest에만 있으며 release용 `android/app/src/main/AndroidManifest.xml`에는 없다. Phase 3 OCR 구현은 서버 전송 없이 번들 ML Kit와 iOS Vision만 사용한다.

---

## Accepted Risks Log

No accepted risks.

---

## Environment Follow-up

- iOS simulator smoke는 macOS 26.5와 Xcode 16.1 환경에서 `AssetCatalogSimulatorAgent` 실행이 거부되는 기존 Xcode/CoreSimulator blocker로 남아 있다.
- iOS Vision 채널 소스와 계약은 검증했으며, 환경 복구 후 simulator smoke를 다시 실행한다.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-01 | 12 | 12 | 0 | Codex inline security audit |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-01
