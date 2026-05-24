# Phase 2: Guided Scan Intake - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-24
**Phase:** 2-Guided Scan Intake
**Areas discussed:** Agent-directed defaults for Guided Scan Intake

---

## Phase 2 Gray Areas

| Option | Description | Selected |
|--------|-------------|----------|
| 선택 진입 방식 | Scan tab에서 사진/다운로드를 어떻게 고르게 할지, 버튼/메뉴/가이드 순서를 정한다. | |
| 스캔 진행 화면 | 처리 개수, 후보 개수 placeholder, 취소 버튼, 완료/부분완료 상태를 어떻게 보여줄지 정한다. | |
| 중복 처리 | 이미 스캔한 파일을 조용히 skip할지, 사용자에게 `N개 건너뜀`으로 알려줄지 정한다. | |
| 실패/빈 결과 처리 | 권한 거부, 접근 불가 파일, 후보 없음일 때 어떤 문구와 다음 행동을 줄지 정한다. | |
| Agent가 결정 | 기존 제품 방향에 맞춰 agent가 기본 결정을 잡고 `CONTEXT.md` 초안을 만든다. | ✓ |

**User's choice:** Agent가 결정
**Notes:** The user delegated Phase 2 implementation decisions to the agent. Decisions were derived from PROJECT.md, REQUIREMENTS.md, ROADMAP.md, Phase 1 context/UI spec/UAT, `docs/coupon-wallet-design.md`, and existing Scan shell code.

---

## the agent's Discretion

- Photos and downloads/files are separate guided choices rather than one broad scan action.
- Today and Wallet continue to route into Scan rather than opening native pickers directly.
- Batch progress shows processed/total counts, honest candidate placeholders, duplicate skip summary, and cancel.
- Duplicate handling is summarized after/beside progress, not surfaced item-by-item.
- Empty, permission/access, cancelled, and partial-failure states are distinct.
- Platform contracts and fake adapters should be planned before real OCR/candidate extraction.

## Deferred Ideas

- Phase 3 owns first scan discovery report and OCR candidate review.
- Wider Pro auto-scan remains a v2/Pro validation idea.
- Real manual pass registration is deferred beyond Phase 2 unless kept as a nonfunctional shell affordance.
