# Phase 1: App Foundation and Local Pass Model - Context

**Gathered:** 2026-05-21
**Status:** Ready for planning

<domain>
## Phase Boundary

이 phase는 Coupon Keeper의 실행 가능한 Flutter 앱 기반을 만든다. 범위는 Today/Wallet/Scan 하단 탭, 첫 실행 빈 상태, pass 중심 도메인 모델, 로컬 저장소 계약, 앱 내부 이미지 사본 저장소 계약, 그리고 후속 phase가 이어 붙을 수 있는 실사용 가능한 앱 셸까지다.

실제 사진/파일 선택, OCR, 후보 리뷰, SQLite 구현, 알림, 결제, 정리 후보 실행 흐름은 후속 phase의 책임이다.

</domain>

<decisions>
## Implementation Decisions

### 첫 실행 빈 상태와 탭별 역할

- **D-01:** Today 첫 화면은 스캔 CTA 중심으로 만든다. 첫 사용자는 앱 설명을 오래 읽기보다 숨은 쿠폰을 찾는 행동으로 바로 이어져야 한다.
- **D-02:** Wallet은 조용한 결과 공간, Scan은 행동 공간으로 구분한다. Wallet은 저장된 pass가 모이는 곳이고, Scan은 사용자가 guided scan을 시작하는 곳이다.
- **D-03:** Today의 빈 상태 문구와 화면 톤은 손실 방지형으로 잡는다. "사진 정리"보다 "잊고 있던 쿠폰을 찾아 손실을 막는다"는 가치가 먼저 보여야 한다.
- **D-04:** Phase 1에서 Today/Wallet의 스캔 CTA를 누르면 실제 스캔 플로우를 열지 않고 Scan 탭으로 이동한다. 실제 사진/파일 선택과 batch scan shell은 Phase 2에서 구현한다.

### Pass 모델의 최소 필드와 상태 의미

- **D-05:** `Pass.type`은 `coupon`, `exchange`, `membership`, `barcode`, `other`를 지원한다. MVP 화면은 쿠폰/교환권에 집중하되 내부 모델은 local pass finder 확장성을 갖춘다.
- **D-06:** `Pass.status`는 `active`, `used`, `expired`, `cleanupCandidate`, `needsReview`를 지원한다. OCR 후보 확인과 정리 후보 흐름까지 같은 수명주기 안에서 다룬다.
- **D-07:** 만료 상태는 저장된 status와 expiry 기반 계산 보정을 함께 사용한다. DB에 status를 저장하되, `active` pass라도 expiry가 지난 경우 도메인/조회 레이어에서 expired처럼 다룬다.
- **D-08:** OCR confidence는 단일 숫자가 아니라 필드별 confidence map으로 저장할 수 있게 한다. 최소 키는 `expiry`, `value`, `brand`, `barcode`, `overall`을 고려한다.

### 로컬 저장소 계약의 첫 모양

- **D-09:** `PassRepository` 계약은 CRUD, id 조회, 상태별 조회, 만료 보정 조회를 포함한다. Phase 1부터 Today/Wallet/Reminder가 의존할 조회 의미를 고정한다.
- **D-10:** 앱 내부 이미지 사본 저장소는 Phase 1에서 계약만 정의하고 fake/in-memory 구현을 제공한다. 실제 파일 복사와 플랫폼 경로 처리는 Phase 2 이후에 연결한다.
- **D-11:** In-memory repository를 공식 test double로 유지한다. SQLite 구현 전에도 domain/application/widget 테스트가 동일한 repository contract behavior를 검증할 수 있어야 한다.
- **D-12:** `source metadata`는 원본 URI/path, platform source type, fingerprint/hash, importedAt, availability, missing reason을 담을 수 있게 모델링한다.

### Phase 1 UI 품질 기준

- **D-13:** Phase 1 UI는 와이어프레임이 아니라 실사용 가능한 앱 셸이어야 한다. Today/Wallet/Scan 탭, 빈 상태, 주요 CTA, 기본 상태 칩/리스트 표면을 후속 phase가 재사용할 수 있게 만든다.
- **D-14:** 시각 톤은 조용한 지갑 유틸리티다. 매장 앞에서 빠르게 읽고 쓸 수 있는 차분하고 밀도 있는 모바일 도구처럼 느껴져야 한다.
- **D-15:** 상태 표현은 핵심 상태 칩 전체를 준비한다. `D-7`, `오늘 만료`, `만료됨`, `사용 완료`, `확인 필요`, `원본 없음` 같은 칩/라벨 패턴을 Phase 1에서 잡는다.
- **D-16:** 접근성은 처음부터 기준 통과를 목표로 한다. 44px 이상 터치 타깃, 16px 이상 본문, 4.5:1 이상 대비, 색 외 상태 표현, 주요 action/status screen reader label을 적용한다.

### the agent's Discretion

- Flutter 상태 관리, 폴더 배치, repository 구현 세부 방식, 디자인 토큰 이름, 테스트 파일 구조는 위 결정과 저장소 규칙을 지키는 범위에서 구현자가 codebase에 맞게 정한다.
- Phase 1에서 실제 스캔, OCR, 알림, 결제, SQLite persistence를 구현하지 않아도 된다. 단, 후속 phase가 붙을 수 있는 contract와 UI 연결점은 남겨야 한다.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project and GSD Source of Truth

- `.planning/PROJECT.md` — 제품 정의, 핵심 가치, 제약, key decisions를 정의한다.
- `.planning/REQUIREMENTS.md` — Phase 1 요구사항 `SHELL-01..04`, `PASS-01..03` 및 전체 traceability를 정의한다.
- `.planning/ROADMAP.md` — Phase 1 목표, success criteria, phase boundary를 정의한다.
- `.planning/STATE.md` — 현재 phase와 최근 결정 상태를 기록한다.
- `AGENTS.md` — 저장소 작업 규칙, planned app structure, quality bar를 정의한다.

### Product and Design Context

- `.planning/research/SUMMARY.md` — stack, table stakes, differentiators, watch-outs 요약을 제공한다.
- `docs/coupon-wallet-design.md` — 문제 정의, MVP scope, accepted decisions, engineering review architecture decisions를 담는다.
- `docs/ceo-plan-coupon-wallet.md` — MVP 범위 결정과 deferred/not-in-scope 판단을 담는다.
- `README.md` — 현재 저장소 상태, MVP 방향, planned structure를 요약한다.
- `TODO.md` — Phase 1에 folded되지 않은 후속 검토 항목을 담는다.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- 아직 Flutter 앱 코드가 없다. Phase 1 계획은 앱 스캐폴드와 `lib/` 구조를 새로 만드는 것을 포함해야 한다.

### Established Patterns

- 계획된 구조는 `lib/presentation`, `lib/application`, `lib/domain`, `lib/data`, `lib/platform`이다.
- 문서는 한국어로 작성하고, 파일명과 폴더명은 영어 kebab-case를 사용한다.
- 서버, 로그인, 클라우드 백업 없이 로컬-first MVP를 유지한다.

### Integration Points

- Phase 1에서 만드는 bottom navigation, domain model, repository contracts, image copy store contract, in-memory test doubles가 Phase 2-6의 연결점이다.
- Native platform channels는 Phase 2 이후 사진/파일 접근, OCR, 알림, 결제 어댑터로 붙는다.

</code_context>

<specifics>
## Specific Ideas

- Today는 첫 사용자가 "잊고 있던 쿠폰을 찾아볼까요?" 계열의 손실 방지형 CTA를 보고 Scan 탭으로 이동하는 흐름이어야 한다.
- Wallet은 데이터가 쌓이기 전까지 과한 예시 카드나 샘플 pass를 보여주지 않는다.
- Scan 탭은 Phase 2의 guided scan 시작 표면을 받을 준비가 되어 있어야 한다.
- 상태 칩은 색만으로 의미를 전달하지 않고 텍스트/아이콘/스크린리더 라벨을 함께 고려한다.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 1-App Foundation and Local Pass Model*
*Context gathered: 2026-05-21*
