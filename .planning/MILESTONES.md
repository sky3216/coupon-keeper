# Milestones: Coupon Keeper

## v1.0 MVP (Shipped: 2026-06-07)

**Delivered:** 서버 없이 기기 안에서 쿠폰 이미지를 선택, OCR 후보 확인, 지갑 저장, 만료 알림, 사용/정리 후보, Pro gate까지 수행하는 iOS/Android 로컬 쿠폰 지갑 MVP.

**Phases completed:** 8 phases, 23 completed plan/slice summaries

**Key accomplishments:**

- Flutter 기반 `Today`, `Wallet`, `Scan` 앱 셸과 pass 중심 도메인 모델을 만들었다.
- guided scan-first 권한 모델로 사용자가 고른 사진, 파일, 명시적 폴더만 확인하도록 제한했다.
- Android ML Kit와 iOS Vision OCR을 MethodChannel 뒤에 연결하고, 후보는 자동 저장하지 않고 사용자 확인 뒤에 저장하도록 했다.
- SQLite, fingerprint cache, 앱 내부 원본 이미지 사본으로 저장된 pass가 앱 재시작과 원본 누락에도 유지되도록 했다.
- Wallet 목록, 상세, 이미지/바코드 확대, 사용 완료, 정리 후보, 원본 정리 handoff를 구현했다.
- 무료 D-7/D-Day와 Pro D-7/D-3/D-1/D-Day/custom 로컬 알림, 앱 시작/resume reconciliation을 구현했다.
- 공식 `in_app_purchase` 기반 Pro 구매/복원 gateway와 로컬 entitlement cache, 문맥형 Pro gate를 구현했다.
- 개인정보/접근성/release readiness 검증을 통과하고 Android appbundle 및 iOS no-codesign release build를 생성했다.

**Stats:**

- 8 phases including inserted Phase 3.1
- 44/44 v1 requirements satisfied
- 126/126 Flutter tests passing at milestone audit
- 12,018 lines across Dart/Kotlin/Swift source files
- Release artifacts verified: Android `app-release.aab`, iOS `Runner.app` no-codesign build

**Archives:**

- `.planning/milestones/v1.0-ROADMAP.md`
- `.planning/milestones/v1.0-REQUIREMENTS.md`
- `.planning/milestones/v1.0-MILESTONE-AUDIT.md`

**Known external release operations:**

- Configure App Store Connect and Google Play Console product IDs for `COUPON_KEEPER_PRO_PRODUCT_ID`.
- Configure signing/provisioning and internal tester accounts.
- Verify actual sandbox/internal purchase and restore flows after store setup.

**Open artifact audit note:** `gsd-sdk query audit-open` reported Phase 1 and Phase 2 UAT files even after both had `status: passed` and `open_scenario_count: 0`; these are recorded as false-positive close-audit items rather than product gaps.

**What's next:** Start v1.1 with `$gsd-new-milestone`, likely focused on internal distribution, real store-console validation, and post-MVP Pro expansion choices.

---
