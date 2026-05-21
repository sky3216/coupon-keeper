# Coupon Keeper

Coupon Keeper는 카카오톡 밖에 흩어진 쿠폰, 교환권, 멤버십 바코드 이미지를 찾아 만료 전에 알려주는 iOS/Android 로컬 쿠폰 지갑이다.

첫 버전은 한국의 20-40대, 특히 기프티콘과 교환권을 자주 받는 직장인을 대상으로 한다. 사용자가 직접 선택한 사진과 다운로드 범위에서 쿠폰 후보를 찾고, OCR 결과를 확인한 뒤 지갑에 저장하며, 매장 앞에서 바로 쿠폰 이미지와 바코드를 꺼내 쓰게 만든다.

## Core Value

사용자가 잊고 있던 현금성 쿠폰 이미지를 찾아 만료 전에 쓰게 만든다.

## Current Status

현재는 구현 전 기획/계획 컨텍스트가 준비된 상태다.

- 제품/디자인 문서: `docs/coupon-wallet-design.md`
- CEO 리뷰 결과: `docs/ceo-plan-coupon-wallet.md`
- GSD 프로젝트 컨텍스트: `.planning/PROJECT.md`
- 요구사항: `.planning/REQUIREMENTS.md`
- 로드맵: `.planning/ROADMAP.md`
- 현재 상태: `.planning/STATE.md`
- 후속 과제: `TODO.md`

## MVP Direction

- Flutter 앱으로 iOS와 Android를 함께 지원한다.
- 사진/파일 접근, OCR, 알림, 결제는 Swift/Kotlin 네이티브 채널 뒤에 둔다.
- 서버, 로그인, 클라우드 백업 없이 로컬에서 동작한다.
- MVP는 guided scan-first다. 첫 실행부터 전체 사진첩이나 다운로드 폴더를 조용히 훑지 않는다.
- 무료 사용자는 활성 쿠폰 5개와 D-7/D-Day 알림을 사용할 수 있다.
- Pro는 무제한 쿠폰, 더 촘촘한 알림, 커스텀 알림, 정리 후보 기능을 제공한다.

## Planned Structure

```text
coupon-keeper/
  .planning/
  docs/
  lib/
    presentation/
    application/
    domain/
    data/
    platform/
  ios/
  android/
```

## Next Step

다음 GSD 명령:

```bash
$gsd-discuss-phase 1
```

Phase 1 목표는 Flutter 앱 스캐폴드, `Today / Wallet / Scan` 기본 네비게이션, pass 중심 도메인 모델, 로컬 저장소 계약을 만드는 것이다.

## Notes

- 문서 내용은 한국어로 작성한다.
- 파일명과 폴더명은 영어 kebab-case를 사용한다.
- 비밀값은 커밋하지 않는다.
