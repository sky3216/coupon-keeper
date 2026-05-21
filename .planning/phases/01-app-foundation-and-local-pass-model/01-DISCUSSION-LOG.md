# Phase 1: App Foundation and Local Pass Model - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-21
**Phase:** 1-App Foundation and Local Pass Model
**Areas discussed:** 첫 실행 빈 상태와 탭별 역할, Pass 모델의 최소 필드와 상태 의미, 로컬 저장소 계약의 첫 모양, Phase 1 UI 품질 기준

---

## 첫 실행 빈 상태와 탭별 역할

| Question | Options | Selected |
|----------|---------|----------|
| 첫 실행 직후 Today 탭의 빈 상태는 어떤 역할을 해야 할까요? | 스캔 CTA 중심 / 가치 설명 중심 / 요약 대시보드 중심 | 스캔 CTA 중심 |
| Wallet 탭과 Scan 탭의 빈 상태는 어떻게 나누는 게 좋을까요? | Wallet은 조용한 결과 공간, Scan은 행동 공간 / 두 탭 모두 스캔 CTA 강하게 노출 / Wallet에서도 예시 패스/샘플 UI 표시 | Wallet은 조용한 결과 공간, Scan은 행동 공간 |
| Today의 첫 CTA 문구/톤은 어느 쪽이 좋을까요? | 손실 방지형 / 정리 도우미형 / 프라이버시 신뢰형 | 손실 방지형 |
| Phase 1에서 CTA를 눌렀을 때 어떤 동작까지 있어야 할까요? | Scan 탭으로 이동 / 스캔 시작 화면 셸까지 열기 / Phase 1에서는 CTA를 비활성화 | Scan 탭으로 이동 |

**User's choice:** Today는 스캔 CTA 중심, Wallet은 결과 공간, Scan은 행동 공간. CTA는 Scan 탭 이동까지만 연결.
**Notes:** 실제 scan intake는 Phase 2로 유지한다.

---

## Pass 모델의 최소 필드와 상태 의미

| Question | Options | Selected |
|----------|---------|----------|
| Phase 1의 Pass.type 범위를 어디까지 열어둘까요? | coupon / exchange / membership / barcode / other; coupon / exchange / other; 단일 type 없이 title/brand만 사용 | coupon / exchange / membership / barcode / other |
| Phase 1에서 pass 상태는 어디까지 모델에 포함할까요? | active / used / expired / cleanupCandidate / needsReview; active / used / expired / cleanupCandidate; active / inactive만 시작 | active / used / expired / cleanupCandidate / needsReview |
| expired는 어떻게 다루는 게 좋을까요? | 저장 상태 + 계산 보정 / 순수 계산 상태 / 순수 저장 상태 | 저장 상태 + 계산 보정 |
| confidence는 Phase 1 모델에서 어떤 형태로 남기는 게 좋을까요? | 필드별 confidence map / overall confidence 하나만 / confidence는 OCR 후보 모델로 미룸 | 필드별 confidence map |

**User's choice:** 확장 가능한 pass type, 전체 수명주기 status, 저장 status와 expiry 계산 보정, 필드별 confidence map.
**Notes:** Phase 3 후보 확인과 Phase 4 정리 후보 흐름까지 모델이 받아낼 수 있어야 한다.

---

## 로컬 저장소 계약의 첫 모양

| Question | Options | Selected |
|----------|---------|----------|
| Phase 1의 PassRepository는 어떤 작업까지 계약으로 고정할까요? | CRUD + 상태별 조회 + 만료 보정 조회 / CRUD + 전체 목록만 / 읽기 전용 mock부터 | CRUD + 상태별 조회 + 만료 보정 조회 |
| Phase 1에서 앱 내부 이미지 사본 저장소는 어디까지 정의할까요? | 계약만 정의하고 구현은 fake/in-memory / 로컬 파일 복사 구현까지 작성 / Pass 모델의 문자열 필드만 두기 | 계약만 정의하고 구현은 fake/in-memory |
| Phase 1에서 저장소 테스트는 어떤 방식으로 잡을까요? | In-memory repository를 공식 test double로 유지 / SQLite 구현을 바로 만들고 테스트 / Mock만 사용 | In-memory repository를 공식 test double로 유지 |
| source metadata는 Phase 1에서 어떤 수준으로 모델링할까요? | 원본 참조 + fingerprint + availability / 원본 URI/path + importedAt만 / freeform map으로 시작 | 원본 참조 + fingerprint + availability |

**User's choice:** 저장소 계약은 후속 phase가 기대할 동작을 먼저 고정하고, 실제 파일/SQLite persistence는 뒤로 미룬다.
**Notes:** In-memory repository는 공식 test double로 유지한다.

---

## Phase 1 UI 품질 기준

| Question | Options | Selected |
|----------|---------|----------|
| Phase 1의 UI는 어느 정도까지 실제 화면처럼 만들어야 할까요? | 실사용 가능한 앱 셸 / 와이어프레임 수준 셸 / 디자인 시스템 먼저 | 실사용 가능한 앱 셸 |
| Coupon Keeper의 첫 UI 톤은 어느 쪽에 가까워야 할까요? | 조용한 지갑 유틸리티 / 따뜻한 소비 절약 앱 / 테크/프라이버시 중심 앱 | 조용한 지갑 유틸리티 |
| Phase 1에서 상태 칩/표현은 어디까지 준비할까요? | 핵심 상태 칩 전체 준비 / Phase 1 요구 상태만 준비 / 텍스트만 표시 | 핵심 상태 칩 전체 준비 |
| Phase 1에서 접근성 기준은 어떤 수준으로 적용할까요? | 처음부터 기준 통과를 목표 / 레이아웃 기준만 우선 / Phase 7에서 일괄 처리 | 처음부터 기준 통과를 목표 |

**User's choice:** Phase 1부터 실사용 가능한 앱 셸과 접근성 기준을 잡는다.
**Notes:** 시각 톤은 조용한 지갑 유틸리티다.

## the agent's Discretion

- Flutter 상태 관리, 폴더 배치, repository 구현 세부 방식, 디자인 토큰 이름, 테스트 파일 구조는 구현자가 저장소 규칙에 맞게 정한다.

## Deferred Ideas

- None.
