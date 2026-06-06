# Coupon Keeper Release Readiness

## 개인정보 경계

- 계정 로그인, 서버 동기화, 클라우드 백업 기능은 MVP 코드에 없다.
- 쿠폰 이미지, OCR 텍스트, 바코드 후보, 만료일, 금액 후보는 기기 안에서 처리한다.
- Android manifest는 알림 권한만 선언하고, 인터넷, 위치, 광범위 미디어 읽기 권한을 선언하지 않는다.
- iOS Info.plist는 광범위 사진 라이브러리, 위치, 네트워크 예외 usage key를 선언하지 않는다.
- 스캔 입력은 사용자가 선택한 사진, 다운로드 이미지, 명시적으로 고른 폴더의 직접 하위 이미지로 제한한다.

## 접근성 기준

- 기본 테마 본문 텍스트는 16px 이상이다.
- 주요 버튼은 44px 이상 터치 영역을 유지한다.
- 상태 chip은 색상만으로 의미를 전달하지 않고 텍스트와 스크린리더 라벨을 함께 제공한다.
- 쿠폰 상세 화면은 만료일, 예상 금액, 원본 상태, 바코드, 쿠폰 이미지, 주요 액션에 명시적 semantics label을 제공한다.
- Pro gate, Scan, Wallet, Detail 흐름은 빈 상태, 진행 상태, 오류, 성공, 부분 성공 상태를 UI와 테스트로 가진다.

## 검증 명령

```bash
flutter analyze
flutter test
flutter build apk --debug
flutter build appbundle --release --dart-define=COUPON_KEEPER_PRO_PRODUCT_ID=<store-product-id>
flutter build ipa --release --no-codesign --dart-define=COUPON_KEEPER_PRO_PRODUCT_ID=<store-product-id>
```

## 내부 테스트 준비 메모

- Google Play 내부 테스트 전 `COUPON_KEEPER_PRO_PRODUCT_ID`를 Play Console의 non-consumable 상품 ID와 맞춘다.
- App Store Connect 내부 테스트 전 같은 dart-define을 App Store Connect의 product ID와 맞춘다.
- 실제 구매/복원 승인은 각 스토어의 sandbox tester 또는 내부 tester 계정으로 확인한다.
- 현재 로컬 Mac의 iOS 실행 검증은 Xcode/CoreSimulator 환경 이슈가 해결된 뒤 재시도한다.
