---
phase: 3
slug: ocr-candidate-review-and-discovery-report
status: approved
shadcn_initialized: false
preset: none
created: 2026-05-30
---

# Phase 3 — UI Design Contract

> OCR Candidate Review and Discovery Report의 시각 및 상호작용 계약. Phase 3 CONTEXT와 Phase 1/2 디자인 시스템을 기준으로 작성하고 6개 UI 품질 차원을 검증했다.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | Flutter Material 3 |
| Preset | Not applicable |
| Component library | Flutter `material` widgets plus local reusable widgets |
| Icon library | Flutter Material Icons |
| Font | System default; Korean text must render legibly at 16px+ |

Phase 3는 Phase 1/2의 조용한 지갑 유틸리티 스타일을 유지한다. 발견 리포트에서는 실제로 보호할 수 있는 금액을 분명하게 보여주되, 금액을 추정하거나 과장하지 않는다. 후보 검토 화면은 편집 도구처럼 단정하고 반복 사용하기 쉬워야 한다. 마케팅 페이지처럼 보이는 장식, 중첩 카드, 큰 배너, gradient, decorative orb는 사용하지 않는다.

---

## Phase 3 Screen Contract

### App Shell Continuity

- `Today`, `Wallet`, `Scan` 세 개의 하단 destination을 그대로 유지한다.
- Discovery report, candidate review, no-candidate result, manual registration은 `Scan` 탭 안의 상태 전환으로 표현한다.
- 전체 화면 이미지 뷰어가 열린 동안에만 하단 navigation을 가릴 수 있다.
- Phase 3에서 새로운 top-level tab, Pro gate, Wallet 상세 화면, 정리 흐름을 추가하지 않는다.

### Discovery Report

Purpose: 첫 OCR 결과를 사용자가 신뢰할 수 있는 절약 성과와 검토 작업으로 연결한다.

Required structure:

1. 상단 상태 아이콘: `Icons.savings_outlined` 또는 동등한 Material icon
2. Heading: `놓칠 수 있는 쿠폰을 찾았어요`
3. High-confidence value가 하나 이상이면 compact display:
   - Eyebrow: `보호할 수 있는 금액`
   - Value: `{protectedValue}원`
4. High-confidence value가 없으면 fallback body:
   - `금액은 후보를 확인하면서 정확하게 입력할 수 있어요.`
5. Flat summary rows:
   - `찾은 후보 {candidateCount}개`
   - `7일 안에 만료 {expiringSoonCount}개` when nonzero
   - `이미 만료되었을 수 있음 {possiblyExpiredCount}개` when nonzero
6. Primary action: `후보 검토 시작`
7. Secondary action: `다시 선택`

Rules:

- 보호 금액은 high-confidence value만 합산한다.
- Low-confidence value는 보호 금액 합계에 포함하지 않는다.
- `{protectedValue}원`은 실제 OCR/parser 결과가 있을 때만 보인다. fake value나 sample value를 넣지 않는다.
- Display 금액은 보고서 안에서만 32px을 사용할 수 있다. Heading보다 시각적으로 먼저 읽히되 hero-scale marketing type은 사용하지 않는다.
- Summary rows는 각각 stable minimum height 44px의 flat surface로 만들고 중첩 카드로 감싸지 않는다.
- `possiblyExpiredCount`는 경고 텍스트와 아이콘으로 함께 표현한다. 색만으로 전달하지 않는다.

### Candidate Review

Purpose: OCR 결과를 pass로 자동 저장하지 않고, 사용자가 한 장씩 확인하고 수정한 뒤 저장하거나 거절한다.

Required structure:

1. 상단 compact progress area:
   - Label: `후보 {currentIndex}/{totalCount}`
   - Thin determinate progress bar
2. Source image preview:
   - Stable aspect ratio: `16:9`
   - Minimum height: 144px
   - Maximum height: 200px
   - Tap affordance icon: `Icons.zoom_in`
   - Semantic label: `선택한 쿠폰 이미지 확대해서 보기`
3. Editable fields:
   - `제목`
   - `브랜드`
   - `만료일`
   - `금액`
   - `바코드 후보` when OCR 숫자 후보 exists
4. Uncertainty indicator:
   - Chip label: `확인 필요`
   - Apply to fields with low confidence or ambiguous candidates
5. Expiry candidate choice:
   - Label: `인식된 날짜 중 하나를 선택해 주세요`
   - Horizontal wrapping choice chips such as `2026.06.30`, `2026.07.30`
6. Actions:
   - Primary: `이 쿠폰 저장`
   - Secondary destructive-neutral text action: `쿠폰 아님`
   - Low-emphasis contextual action: `직접 등록`

Rules:

- 한 화면에는 현재 candidate 하나만 편집 가능한 상태로 보인다.
- 후보 목록 페이지나 일괄 편집 폼을 Phase 3에 추가하지 않는다.
- Save button은 `제목` 또는 `브랜드` 중 하나와 사용자가 확인한 `만료일`이 있을 때만 활성화한다.
- Save disabled semantic label: `제목 또는 브랜드와 만료일을 확인하면 저장할 수 있습니다`.
- Estimated value는 optional이다. 값이 없어도 저장 가능하다.
- Barcode candidate는 OCR에서 찾은 숫자 텍스트만 보여준다. 이미지 barcode decoding UI를 추가하지 않는다.
- `쿠폰 아님`은 red filled button이 아니다. false positive를 버리는 low-emphasis text action으로 표현한다.
- 저장 또는 거절 후 다음 후보로 즉시 이동한다.
- 마지막 후보를 처리하면 batch completion state로 이동한다.
- Long Korean field labels and helper text wrap naturally. Horizontal scrolling은 날짜 chip row에만 허용하지 않고, `Wrap` 레이아웃으로 줄바꿈한다.

### Full-Screen Source Image Viewer

Purpose: OCR 결과를 원본 이미지와 정확하게 비교한다.

Required structure:

- Full-screen surface with dark neutral background.
- Top-right close icon: `Icons.close`
- Image uses contain fitting. 쿠폰 전체가 잘리지 않고 보인다.
- Optional zoom/pan gesture can be added with Flutter standard interaction if implementation cost is small.
- Semantic labels:
  - Viewer: `선택한 쿠폰 이미지 전체 화면`
  - Close: `이미지 확대 보기 닫기`

Rules:

- Viewer is opened only by tapping the candidate/manual-registration preview.
- Viewer close returns to the exact current form state without losing edited values.
- Do not crop the source image to decorative composition.

### No-Candidate Result

Purpose: OCR이 후보를 찾지 못해도 사용자가 막히지 않게 한다.

Required copy:

- Heading: `이번 선택에서는 쿠폰 후보를 찾지 못했어요`
- Body: `다른 사진을 선택하거나, 선택한 이미지로 직접 등록할 수 있어요.`
- Primary action: `직접 등록`
- Secondary action: `다시 선택`

Rules:

- Neutral empty state로 표현한다. 실패 또는 danger 상태처럼 보이면 안 된다.
- Phase 2의 disabled shell copy `수동 등록은 다음 단계에서`를 실제 CTA `직접 등록`으로 교체한다.
- Sample coupons, fake OCR suggestions, invented protected value를 보여주지 않는다.

### Manual Registration

Purpose: OCR 실패 또는 candidate review 중 사용자가 선택한 이미지를 기반으로 직접 pass를 등록한다.

Required structure:

1. Heading: `쿠폰 정보를 직접 입력해 주세요`
2. Source image preview:
   - Candidate review와 동일한 `16:9` preview 및 full-screen viewer affordance
3. Editable fields:
   - `제목`
   - `브랜드`
   - `만료일`
   - `금액` optional
4. Primary action: `쿠폰 저장`
5. Secondary action: `취소`

Rules:

- Manual registration은 no-candidate result와 candidate review에서만 진입한다.
- Scan start 또는 Wallet empty state에 manual registration CTA를 추가하지 않는다.
- 선택한 이미지는 app-internal copy 흐름에 연결한다.
- Save button은 `제목` 또는 `브랜드` 중 하나와 `만료일`이 있을 때만 활성화한다.
- Candidate review에서 진입했다가 취소하면 현재 candidate review 상태로 돌아간다.
- No-candidate result에서 진입했다가 취소하면 no-candidate result로 돌아간다.

### Batch Completion

Purpose: 한 batch의 저장/거절 결과를 조용히 마무리한다.

Required structure:

- Heading: `쿠폰 확인을 마쳤어요`
- Summary rows:
  - `저장한 쿠폰 {savedCount}개`
  - `건너뛴 후보 {rejectedCount}개` when nonzero
- Primary action: `Wallet에서 보기`
- Secondary action: `다시 스캔`

Rules:

- Wallet 이동은 candidate 하나를 저장할 때마다 하지 않고 batch completion에서만 제공한다.
- 저장한 pass가 없으면 primary action은 `다시 스캔`, secondary action은 생략할 수 있다.
- Phase 4 전이라 Wallet이 empty-only shell이면 저장 결과를 fake Wallet card로 만들지 않는다. Repository save와 navigation handoff만 유지한다.

---

## Spacing Scale

Declared values (must be multiples of 4):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon gaps, chip inner gaps |
| sm | 8px | Inline gaps, helper text spacing |
| md | 16px | Default screen padding, field gaps |
| lg | 24px | Section spacing, preview-to-form gap |
| xl | 32px | Report grouping, empty-state action separation |
| 2xl | 48px | Tall-screen major separation only |
| 3xl | 64px | Rare page-level breathing room |

Exceptions: none.

Layout constraints:

- Screen horizontal padding: 16px on 320px-wide screens, 20px on wider phones.
- Primary button: minimum height 48px.
- Secondary text action: minimum tap target 44px.
- Summary row: minimum height 44px.
- Candidate preview: `AspectRatio(16 / 9)` with 144px minimum and 200px maximum visual height.
- Form fields use full available width and never sit side-by-side on phone layouts.
- Date choice chips use wrapping rows. Do not create horizontal overflow on 320px screens.
- Bottom action area remains reachable with scroll view and safe-area padding when keyboard is open.
- Do not put UI cards inside other cards. The candidate preview may be framed; the form remains an unframed layout.

---

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 16px | 400 | 1.45 |
| Label | 13px | 600 | 1.30 |
| Meta | 14px | 400 | 1.35 |
| Section | 18px | 700 | 1.30 |
| Heading | 24px | 700 | 1.25 |
| Report Value | 32px | 700 | 1.15 |

Typography rules:

- Do not scale font size with viewport width.
- Letter spacing is 0.
- Body text is 16px or larger.
- Report Value is used only for verified protected value on the discovery report.
- Candidate field text and helper text remain readable at 320px width.
- Long text wraps rather than truncating essential field guidance.
- Avoid hero-scale type inside candidate review and manual registration surfaces.

---

## Color

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `#F7F6F2` | App background |
| Secondary (30%) | `#FFFFFF` | Bottom nav, preview frame, input surfaces |
| Text primary | `#171717` | Primary text |
| Text secondary | `#5F625D` | Body, helper, support text |
| Border | `#DAD8D0` | Dividers, input borders, preview border |
| Accent (10%) | `#1F7A5A` | Primary CTA, active progress, selected date chip |
| Accent soft | `#E5F3ED` | Selected chip, positive report surface |
| Warning | `#9A6500` | Expiring soon and confirm-needed text/icon |
| Warning soft | `#FFF3D7` | Confirm-needed chip and expiring summary |
| Danger | `#B3261E` | Already-expired warning text/icon only |
| Danger soft | `#FCE8E6` | Possibly-expired summary background |
| Neutral chip | `#EEEDE7` | Candidate count, neutral summary rows |
| Viewer background | `#171717` | Full-screen source image viewer |

Accent reserved for:

- Discovery report protected-value emphasis
- Primary CTA
- Candidate progress indicator
- Selected expiry-date chip
- Active bottom navigation destination

Color rules:

- Do not use purple/purple-blue gradients, decorative orbs, bokeh blobs, or one-note monochrome palettes.
- Status is never color-only. Warning, expired, uncertainty, and selection states always include text and optionally icons.
- Text/background contrast targets 4.5:1 or better for normal text.
- `Danger` is not used for candidate rejection. `쿠폰 아님` is a low-emphasis neutral action.

---

## Component Contracts

### Protected Value Display

- Eyebrow: `보호할 수 있는 금액`.
- Value format: `{protectedValue}원`.
- Value uses `Report Value` typography and `AppTheme.textPrimary`.
- Accent may appear as a small icon or soft background only.
- Render only when at least one high-confidence amount contributes to the total.

### Discovery Summary Row

- Stable minimum height: 44px.
- Border radius: 8px or less.
- Flat row with icon + label + count; no nested cards.
- Required rows:
  - `찾은 후보 {candidateCount}개`
  - `7일 안에 만료 {expiringSoonCount}개`
  - `이미 만료되었을 수 있음 {possiblyExpiredCount}개`

### Candidate Progress Header

- Label: `후보 {currentIndex}/{totalCount}`.
- Thin `LinearProgressIndicator`.
- Semantic label: `전체 후보 {totalCount}개 중 {currentIndex}번째 후보 검토 중`.
- Keep stable height as counts change.

### Source Image Preview

- Stable `16:9` aspect ratio.
- Border radius: 8px.
- Border: 1px `#DAD8D0`.
- Use actual selected image only; no decorative stock asset.
- Overlay a familiar zoom icon button with tooltip/semantic label.

### Candidate Field

- Full-width Material text field.
- Labels: `제목`, `브랜드`, `만료일`, `금액`, optional `바코드 후보`.
- Low-confidence fields include `확인 필요` text chip and helper copy.
- Numeric amount input may use number keyboard and normalize display to won format after edit.
- Barcode candidate is read-only or editable at executor discretion, but it must be clearly labeled as OCR-derived candidate text.

### Expiry Choice Chip

- Use Material choice chip or equivalent.
- Minimum tap target: 44px.
- Border radius: 8px or less.
- Date format: `yyyy.MM.dd`.
- Chips wrap onto additional lines.
- Selected chip uses accent soft background plus visible selected text/state semantics.

### Primary Button

- Height: at least 48px.
- Border radius: 8px.
- One primary action per screen.
- Candidate label: `이 쿠폰 저장`.
- Manual label: `쿠폰 저장`.
- Report label: `후보 검토 시작`.
- Disabled button exposes semantic disabled reason.

### Secondary and Rejection Actions

- Minimum tap target: 44px.
- Rejection label: `쿠폰 아님`.
- Manual-registration label: `직접 등록`.
- Selection retry label: `다시 선택`.
- Rejection action must not visually compete with save.

### Empty and Completion State

- Reuse `EmptyState` structure where possible.
- Empty/result body should be 1-2 short Korean sentences.
- No placeholder strings: `TODO`, `Lorem ipsum`, `Coming soon` are not allowed in user-facing copy.
- Completion summary uses flat rows and at most one primary action.

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Discovery heading | `놓칠 수 있는 쿠폰을 찾았어요` |
| Protected value eyebrow | `보호할 수 있는 금액` |
| Protected value fallback | `금액은 후보를 확인하면서 정확하게 입력할 수 있어요.` |
| Found candidates | `찾은 후보 {candidateCount}개` |
| Expiring soon | `7일 안에 만료 {expiringSoonCount}개` |
| Possibly expired | `이미 만료되었을 수 있음 {possiblyExpiredCount}개` |
| Start review | `후보 검토 시작` |
| Candidate progress | `후보 {currentIndex}/{totalCount}` |
| Uncertain field chip | `확인 필요` |
| Expiry candidates helper | `인식된 날짜 중 하나를 선택해 주세요` |
| Candidate save | `이 쿠폰 저장` |
| Candidate reject | `쿠폰 아님` |
| Manual registration entry | `직접 등록` |
| No-candidate heading | `이번 선택에서는 쿠폰 후보를 찾지 못했어요` |
| No-candidate body | `다른 사진을 선택하거나, 선택한 이미지로 직접 등록할 수 있어요.` |
| Manual heading | `쿠폰 정보를 직접 입력해 주세요` |
| Manual save | `쿠폰 저장` |
| Batch completion heading | `쿠폰 확인을 마쳤어요` |
| Saved count | `저장한 쿠폰 {savedCount}개` |
| Rejected count | `건너뛴 후보 {rejectedCount}개` |
| View wallet | `Wallet에서 보기` |
| Scan again | `다시 스캔` |
| Choose again | `다시 선택` |
| Close viewer | `이미지 확대 보기 닫기` |
| Destructive confirmation | Phase 3 has no destructive confirmation |

Copywriting rules:

- Savings language is factual. Do not show `약`, ranges, invented estimates, or sample monetary values.
- Do not frame OCR as always correct. Use candidate, confirmation, and selection language.
- Avoid OS jargon in visible copy.
- Keep trust language brief and concrete.
- Do not mention Pro, account, sync, cloud, location, cleanup, ads, or broad auto-scan in Phase 3 UI.

---

## Interaction Contracts

### Phase 2 Handoff

- Phase 2 `후보 확인 준비` completion shell becomes an enabled transition into Phase 3 discovery.
- Selected items only flow into OCR candidate discovery.
- Duplicate-only selections can remain in the Phase 2 neutral completion path.

### Discovery Report to Candidate Review

- Tapping `후보 검토 시작` opens the first candidate.
- Tapping `다시 선택` returns to Scan start.
- Report counts come from parsed candidates only.

### Candidate Review

- The user edits current candidate fields without auto-save.
- Tapping an expiry chip confirms that expiry date.
- Tapping `이 쿠폰 저장` saves the confirmed candidate and advances.
- Tapping `쿠폰 아님` rejects the false positive and advances without a reason prompt.
- Tapping `직접 등록` opens manual registration with the current selected image.

### Manual Registration

- Entry is available only from no-candidate result and candidate review.
- Save remains disabled until title or brand plus expiry exist.
- Save keeps the selected image through the app-internal copy flow.
- Cancel returns to the originating state without losing the surrounding review batch.

### Image Viewer

- Tapping source image preview opens the full-screen viewer.
- Closing viewer returns to current form state.
- Edited values remain intact after opening and closing viewer.

### Batch Completion

- After the final save or rejection, show batch completion summary.
- Tapping `Wallet에서 보기` selects Wallet.
- Tapping `다시 스캔` returns to Scan start.

### Small Screen and Keyboard

- At 320x568 logical size, report CTA, candidate progress, source preview, editable fields, and save/reject actions remain reachable by vertical scrolling.
- The active text field remains visible when the keyboard opens.
- Button labels wrap only when necessary and never overflow their parent.
- Date chips wrap without horizontal scrolling.

---

## Accessibility Contract

- Minimum touch target: 44px; primary buttons are at least 48px high.
- Body text: 16px or larger.
- Normal text contrast: target 4.5:1 or better.
- Amount, warning, expiry, uncertainty, and review progress are never color-only.
- Required semantics labels:
  - Protected value: `보호할 수 있는 금액 {protectedValue}원`
  - Candidate review progress: `전체 후보 {totalCount}개 중 {currentIndex}번째 후보 검토 중`
  - Source preview: `선택한 쿠폰 이미지 확대해서 보기`
  - Viewer close: `이미지 확대 보기 닫기`
  - Expiry candidate: `만료일 후보 {date}` plus selected state
  - Save disabled: `제목 또는 브랜드와 만료일을 확인하면 저장할 수 있습니다`
  - Reject: `현재 후보를 쿠폰 아님으로 처리하고 다음 후보로 이동`
  - Manual entry: `선택한 이미지로 쿠폰 직접 등록`
- Screen readers should hear the field label, uncertainty state, and helper text together.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | not applicable |
| third-party UI blocks | none | not allowed in Phase 3 |

Registry rules:

- Do not introduce shadcn, Radix, Base UI, web CSS libraries, or third-party Flutter UI kits.
- Use Flutter Material widgets and local reusable widgets.
- Icons come from Flutter Material Icons unless the Flutter project explicitly adds another icon package later.

---

## Verification Requirements

Planner must include widget tests or source assertions for:

- Discovery report shows high-confidence protected value only when eligible values exist.
- Discovery report fallback omits invented total when no high-confidence value exists.
- Report renders `찾은 후보`, conditional `7일 안에 만료`, and conditional `이미 만료되었을 수 있음` rows.
- `후보 검토 시작` opens one-by-one candidate review.
- Candidate review shows `후보 {currentIndex}/{totalCount}`, determinate progress, source preview, editable title, brand, expiry, value, and conditional barcode candidate.
- Multiple or uncertain expiry dates render wrapping choice chips and require user confirmation.
- Save remains disabled until title or brand plus confirmed expiry exist.
- Save advances to the next candidate and writes only after explicit user action.
- `쿠폰 아님` advances without saving and without a rejection-reason prompt.
- Source preview opens a full-screen contain-fit viewer and close restores edited form state.
- No-candidate result shows `직접 등록` and `다시 선택`.
- Manual registration keeps selected image context and uses the same required-field save gate.
- Batch completion appears only after the final candidate is handled.
- No user-facing `TODO`, `Lorem ipsum`, `Coming soon`, fake brand, fake coupon title, fake amount, or network/cloud OCR copy appears.
- A 320x568 widget test confirms report, candidate form, date chips, and actions remain reachable without overlap.
- `flutter analyze && flutter test` remains the full verification command once implementation is complete.

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-05-30
