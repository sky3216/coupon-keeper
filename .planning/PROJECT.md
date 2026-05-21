# Coupon Keeper

## What This Is

Coupon Keeper는 카카오톡 밖에 흩어진 쿠폰, 교환권, 멤버십 바코드 이미지를 사용자가 선택한 사진과 다운로드 범위에서 찾아주는 iOS/Android 로컬 쿠폰 지갑이다. 첫 버전은 한국의 20-40대, 특히 기프티콘과 교환권을 자주 받는 30대 직장인을 대상으로 한다. 사용자는 쿠폰 후보를 확인해 지갑에 저장하고, 만료 전에 알림을 받고, 매장 앞에서 바로 이미지를 꺼내 쓸 수 있다.

## Core Value

사용자가 잊고 있던 현금성 쿠폰 이미지를 찾아 만료 전에 쓰게 만든다.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] 사용자는 앱을 열고 `Today`, `Wallet`, `Scan` 흐름을 이해할 수 있다.
- [ ] 사용자는 사진 또는 다운로드 폴더에서 쿠폰/교환권 후보를 guided scan으로 찾을 수 있다.
- [ ] 사용자는 OCR 후보의 만료일, 금액, 브랜드를 확인하고 수정한 뒤 저장할 수 있다.
- [ ] 사용자는 저장된 쿠폰을 지갑에서 찾고, 상세 화면에서 이미지와 바코드를 크게 볼 수 있다.
- [ ] 사용자는 무료 버전에서 활성 쿠폰 5개까지 저장하고 D-7/D-Day 알림을 받을 수 있다.
- [ ] Pro 사용자는 무제한 쿠폰, D-7/D-3/D-1/D-Day, 커스텀 알림, 정리 후보 기능을 사용할 수 있다.
- [ ] 사용자는 사용 완료한 쿠폰을 정리 후보로 보내되, 원본 삭제는 직접 확인 후 시스템 UI에서 처리한다.
- [ ] 앱은 서버 없이 로컬에서 동작하고, 사진/쿠폰 이미지/위치 정보를 기기 밖으로 보내지 않는다.

### Out of Scope

- 서버 동기화와 계정 기반 백업 — 로컬-only 신뢰와 MVP 속도를 유지한다.
- 첫 실행부터 전체 사진첩/다운로드 폴더를 조용히 훑는 자동 스캔 — 권한 허들과 심사 리스크가 크다.
- Apple Wallet/Google Wallet 패스 생성 — 인증서, issuer 계정, API 제약 때문에 후속 검토로 둔다.
- 백그라운드 GPS 기반 매장 자동 탐지 — 위치 권한과 개인정보 메시지 충돌이 크다.
- 무료 버전 광고 수익화 — 광고 SDK는 로컬/개인정보 보호 메시지와 충돌한다.
- 서버 영수증 검증 — 서버 운영과 계정 문제가 생기므로 MVP에서는 로컬 entitlement 캐시로 시작한다.
- 자체 ML 분류 모델 — MVP는 온디바이스 OCR과 규칙 기반 후보화로 시작하고, 사용자 수정 데이터를 본 뒤 고도화한다.

## Context

- 문제 출발점은 사진 정리가 아니라 쿠폰 손실 방지다. 사용자는 카카오톡 외부 쿠폰을 다운로드 폴더와 사진첩에 흩어둔 채 잊고, 매장 앞에서 뒤늦게 찾거나 이미 만료된 것을 확인한다.
- 무료 한도는 활성 쿠폰 5개다. 무료에서도 D-7/D-Day 알림을 제공해 핵심 가치를 느끼게 하고, Pro는 무제한과 촘촘한 알림, 정리 후보, 멤버십/바코드 확장으로 차별화한다.
- 첫 실행 권한 모델은 guided scan이다. 사용자가 직접 선택한 사진/폴더만 스캔하고, 더 넓은 자동 스캔은 신뢰가 쌓인 뒤 Pro 확장으로 검토한다.
- 앱 프레임워크는 Flutter다. UI와 상태 관리는 Flutter로 만들고, 사진 접근, 파일 접근, OCR, 알림, 결제는 Swift/Kotlin 네이티브 채널 뒤에 숨긴다.
- 데이터 모델은 `coupon`이 아니라 `pass` 중심이다. 쿠폰, 교환권, 멤버십, 바코드 이미지를 같은 수명주기에서 다룬다.
- 디자인 방향은 `Today / Wallet / Scan` 하단 탭, 첫 스캔 발견 리포트, 조용한 지갑 목록, 큰 쿠폰 상세 화면이다.
- 고충실도 mockup은 gstack designer 인증 설정 전까지 보류한다. 현재 디자인 리뷰는 텍스트 기반 UX 계획까지 완료했다.

## Constraints

- **Tech stack**: Flutter + native platform channels — iOS/Android 동시 출시와 플랫폼별 OCR/권한 품질을 함께 잡는다.
- **Storage**: SQLite + 앱 내부 이미지 사본 — 원본 파일이 삭제되거나 권한이 바뀌어도 지갑은 유지되어야 한다.
- **Privacy**: 서버 없음, 로그인 없음, 클라우드 백업 없음 — 사진과 쿠폰 이미지가 기기 밖으로 나가지 않는 신뢰가 핵심이다.
- **OCR**: iOS Vision, Android ML Kit Text Recognition v2 — OpenAI API 같은 추가 AI 비용 없이 온디바이스 처리한다.
- **Notifications**: 로컬 알림 예약과 앱 실행 시 재조정 — 백그라운드 작업에 핵심 가치를 의존하지 않는다.
- **Payments**: App Store / Google Play 인앱결제 + 로컬 Pro 상태 캐시 — MVP에서는 서버 영수증 검증을 도입하지 않는다.
- **Accessibility**: 44px 이상 터치 타깃, 본문 16px 이상, 4.5:1 이상 대비, 색만으로 상태 표현 금지 — 매장 앞에서 한 손으로 빠르게 써야 한다.
- **Documentation**: 파일명과 폴더명은 영어 kebab-case, 문서 내용은 한국어 — workspace 규칙을 따른다.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Approach A, 쿠폰 지갑 MVP | 가장 빨리 유료 구매 이유를 검증할 수 있고 서버 없는 로컬 앱 제약에 맞는다. | — Pending |
| Guided scan-first 권한 모델 | 사용자 신뢰와 앱 심사 리스크를 낮추고, Pro 확장 자동 스캔 여지를 남긴다. | — Pending |
| Flutter + native platform channels | 공통 UI 생산성과 iOS/Android 네이티브 기능 품질의 균형이 좋다. | — Pending |
| SQLite + 앱 내부 이미지 사본 | 원본 사진/파일이 사라져도 쿠폰 지갑은 계속 열려야 한다. | — Pending |
| Pass 중심 데이터 모델 | 쿠폰 외 멤버십, 바코드, 교환권, 티켓으로 확장 가능해야 한다. | — Pending |
| 자동 등록이 아니라 자동 후보화 | OCR 오탐이 신뢰를 깨지 않도록 사용자가 확인하고 저장한다. | — Pending |
| 무료도 D-7/D-Day 알림 제공 | 알림이 핵심 가치이므로 무료에서도 충분히 쓸모 있어야 한다. | — Pending |
| Today-first IA | 반복 사용자는 만료 임박 쿠폰을 먼저 보고, 신규 사용자는 스캔 CTA를 본다. | — Pending |
| 맥락형 Pro 게이트 | 사용자가 가치를 경험하기 전에는 결제 화면을 띄우지 않는다. | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `$gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `$gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-05-21 after initialization*
