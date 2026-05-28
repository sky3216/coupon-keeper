# Phase 3: OCR Candidate Review and Discovery Report - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-28
**Phase:** 3-OCR Candidate Review and Discovery Report
**Areas discussed:** Discovery report first impression, OCR candidate confidence and save rules, Candidate review and editing flow, OCR failure and manual registration

---

## Discovery Report First Impression

| Option | Description | Selected |
|--------|-------------|----------|
| 조용한 요약형 | 후보 수, 곧 만료, 확인 필요 같은 사실 중심 요약으로 신뢰를 우선한다. | |
| 절약 성과형 | 놓칠 뻔한 금액을 앞세워 첫 스캔의 성과감을 만든다. | ✓ |
| 검토 대기형 | 확인할 후보가 있다는 메시지를 먼저 보여주고 숫자는 보조로 둔다. | |

**User's choice:** 절약 성과형
**Notes:** 금액 confidence가 충분할 때만 보호한 금액을 크게 보여주고, 낮으면 확인할 후보 중심으로 fallback한다.

| Follow-up Option | Description | Selected |
|------------------|-------------|----------|
| 보수적 숨김 | 확실한 금액만 합산하고 불확실한 금액은 총액에 넣지 않는다. | ✓ |
| 추정치 표시 | 추정임을 밝히고 약 얼마인지 보여준다. | |
| 범위 표시 | 최소 확정 금액과 가능성을 나누어 보여준다. | |

**User's choice:** 보수적 숨김
**Notes:** Low-confidence value는 candidate field에서 확인 필요로 보여준다.

| Follow-up Option | Description | Selected |
|------------------|-------------|----------|
| 7일 이내 | 무료 D-7 reminder 가치와 연결되는 기준이다. | ✓ |
| 3일 이내 | 더 긴급한 항목만 보여준다. | |
| 14일 이내 | 더 넓게 잡아 후보를 많이 보여준다. | |

**User's choice:** 7일 이내
**Notes:** Discovery report의 expiring-soon 기준은 7일 이내다.

| Follow-up Option | Description | Selected |
|------------------|-------------|----------|
| 후보 검토 시작 | 리포트에서 바로 첫 후보 검토로 들어간다. | ✓ |
| 전체 후보 목록 보기 | 후보 리스트를 먼저 보고 사용자가 하나씩 고른다. | |
| 저장 가능한 것만 먼저 | confidence 높은 후보부터 저장하도록 유도한다. | |

**User's choice:** 후보 검토 시작
**Notes:** 첫 보고서의 primary action은 candidate review 시작이다.

---

## OCR Candidate Confidence and Save Rules

| Option | Description | Selected |
|--------|-------------|----------|
| 제목 + 만료일 우선 | 제목 또는 브랜드와 만료일이 있으면 저장 가능 후보로 둔다. | ✓ |
| 금액까지 필요 | 제목/브랜드, 만료일, 금액이 모두 있어야 저장 가능 후보로 둔다. | |
| 제목만 있어도 가능 | 제목/브랜드만 있어도 후보로 둔다. | |

**User's choice:** 제목 + 만료일 우선
**Notes:** 금액은 있으면 좋지만 필수는 아니다.

| Follow-up Option | Description | Selected |
|------------------|-------------|----------|
| 후보 날짜 선택 | 여러 날짜 후보 또는 낮은 confidence 날짜를 사용자에게 선택하게 한다. | ✓ |
| 가장 가능성 높은 날짜 자동 선택 | 하나를 기본값으로 넣고 사용자가 수정할 수 있게 한다. | |
| 만료일 비워두기 | 낮은 confidence면 저장 전 직접 입력하게 한다. | |

**User's choice:** 후보 날짜 선택
**Notes:** 날짜 오탐은 신뢰를 깨므로 사용자 선택을 요구한다.

| Follow-up Option | Description | Selected |
|------------------|-------------|----------|
| OCR 숫자 후보만 저장 | OCR 텍스트에서 긴 숫자열을 barcode candidate로 저장한다. | ✓ |
| 이미지 바코드 디코딩까지 시도 | 별도 barcode scanning 기능까지 붙인다. | |
| 바코드는 이번 단계에서 제외 | 제목/브랜드/만료일/금액만 다룬다. | |

**User's choice:** OCR 숫자 후보만 저장
**Notes:** 실제 이미지 barcode decoding은 후속 개선으로 남긴다.

| Follow-up Option | Description | Selected |
|------------------|-------------|----------|
| 필수값 확인 후 활성 | 제목 또는 브랜드, 만료일이 확인되어야 저장 버튼을 활성화한다. | ✓ |
| 항상 활성 | 누락된 값이 있어도 저장할 수 있다. | |
| 제목만 있으면 활성 | 만료일 없이도 저장할 수 있다. | |

**User's choice:** 필수값 확인 후 활성
**Notes:** OCR 후보는 pass로 자동 저장되지 않고, 사용자가 핵심 필드를 확인해야 저장할 수 있다.

---

## Candidate Review and Editing Flow

| Option | Description | Selected |
|--------|-------------|----------|
| 한 장씩 검토 | 카드 한 장에 이미지, OCR 필드, 수정/저장/거절을 보여준다. | ✓ |
| 후보 목록 + 상세 편집 | 리스트에서 후보를 고르고 상세로 들어간다. | |
| 한 화면 일괄 편집 | 모든 후보를 폼 목록으로 보여준다. | |

**User's choice:** 한 장씩 검토
**Notes:** 모바일에서 집중하기 좋은 one-by-one review flow로 결정했다.

| Follow-up Option | Description | Selected |
|------------------|-------------|----------|
| 상단 미리보기 + 확대 | 카드 위에 작게 보여주고 탭하면 크게 본다. | ✓ |
| 큰 이미지 중심 | 이미지를 크게 보여주고 필드는 아래에 둔다. | |
| 이미지는 보조 썸네일 | 작은 썸네일만 보여준다. | |

**User's choice:** 상단 미리보기 + 확대
**Notes:** 원본 확인과 편집 폼 가시성을 함께 유지한다.

| Follow-up Option | Description | Selected |
|------------------|-------------|----------|
| 즉시 다음 후보 | 거절하면 바로 다음 후보로 넘어간다. | ✓ |
| 거절 사유 선택 | 쿠폰 아님, 중복, 잘못 인식 등 사유를 받는다. | |
| 거절 후 되돌리기 스낵바 | 바로 다음으로 넘어가되 짧은 되돌리기 기회를 준다. | |

**User's choice:** 즉시 다음 후보
**Notes:** MVP에서는 rejection reason collection을 하지 않는다.

| Follow-up Option | Description | Selected |
|------------------|-------------|----------|
| 다음 후보 계속 검토 | 모든 후보를 처리할 때까지 같은 흐름에 머문다. | ✓ |
| Wallet으로 이동 | 저장 직후 지갑에 들어간 것을 확인한다. | |
| 저장 완료 화면 | 저장 성공을 크게 보여준다. | |

**User's choice:** 다음 후보 계속 검토
**Notes:** First scan cleanup flow를 끊지 않는다.

---

## OCR Failure and Manual Registration

| Option | Description | Selected |
|--------|-------------|----------|
| 빈 결과 + 수동 등록 CTA | OCR 실패 빈 상태 아래에 직접 등록을 제공한다. | ✓ |
| 바로 수동 등록 폼 | 사용자가 곧장 입력을 시작할 수 있다. | |
| 다시 선택만 제공 | 수동 등록은 숨긴다. | |

**User's choice:** 빈 결과 + 수동 등록 CTA
**Notes:** 실패를 부드럽게 회복하는 경로로 수동 등록을 제공한다.

| Follow-up Option | Description | Selected |
|------------------|-------------|----------|
| 제목/브랜드 + 만료일 | OCR 저장 기준과 같게 맞춘다. | ✓ |
| 제목만 | 가장 빠르게 저장할 수 있다. | |
| 이미지 + 제목 | 원본 이미지를 붙이고 제목만 입력한다. | |

**User's choice:** 제목/브랜드 + 만료일
**Notes:** 수동 등록도 알림과 지갑 가치를 유지해야 한다.

| Follow-up Option | Description | Selected |
|------------------|-------------|----------|
| 빈 결과와 후보 검토 화면 | OCR 실패 빈 결과와 후보 검토 중 직접 등록을 제공한다. | ✓ |
| Scan 시작 화면에도 항상 노출 | 스캔 없이 바로 등록할 수 있다. | |
| Wallet 빈 상태에도 노출 | 저장된 pass가 없을 때 Wallet에서 바로 등록할 수 있다. | |

**User's choice:** 빈 결과와 후보 검토 화면
**Notes:** Scan start와 Wallet empty state까지 넓히는 것은 후속 단계로 둔다.

| Follow-up Option | Description | Selected |
|------------------|-------------|----------|
| 선택한 이미지 연결 | OCR이 실패해도 선택했던 이미지를 수동 pass에 연결하고 앱 내부 사본으로 보관한다. | ✓ |
| 이미지 없이 텍스트만 등록 | 입력은 단순하지만 실사용 가치가 약하다. | |
| 이미지는 선택 사항 | 유연하지만 저장 기준과 UI 분기가 늘어난다. | |

**User's choice:** 선택한 이미지 연결
**Notes:** 원본 삭제와 매장 사용에 대비하기 위해 수동 pass도 이미지 사본을 유지한다.

---

## the agent's Discretion

- 정확한 class/widget/controller 이름
- OCR parser threshold와 confidence score scale
- Date parsing implementation details
- UI state management primitive and widget decomposition
- Native channel method naming, as long as the adapters remain fake-testable

## Deferred Ideas

- Dedicated image barcode decoding
- Manual registration from Scan start or Wallet empty state
- Rejection reason collection
- Correction learning from user edits
- Broad auto-scan and Pro wider scan
