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
flutter build ios --release --no-codesign --dart-define=COUPON_KEEPER_PRO_PRODUCT_ID=<store-product-id>
```

## 내부 테스트 준비 메모

- Google Play 내부 테스트 전 `COUPON_KEEPER_PRO_PRODUCT_ID`를 Play Console의 non-consumable 상품 ID와 맞춘다.
- App Store Connect 내부 테스트 전 같은 dart-define을 App Store Connect의 product ID와 맞춘다.
- 실제 구매/복원 승인은 각 스토어의 sandbox tester 또는 내부 tester 계정으로 확인한다.
- 현재 로컬 Mac에서 Android release appbundle과 iOS release no-codesign build가 모두 통과한다.

## iOS 빌드 환경 이력

현재 환경:

- macOS Tahoe 26.5
- Xcode 26.5 (17F42)
- Flutter 3.44.0
- iOS platform/runtime 26.5

최종 검증:

```bash
flutter build ios --release --no-codesign --dart-define=COUPON_KEEPER_PRO_PRODUCT_ID=coupon_keeper_pro
```

결과:

```text
Built build/ios/iphoneos/Runner.app
```

참고: iOS production picker는 `PHPicker`와 `UTType`을 사용하므로 Runner deployment target은 iOS 14.0이다.

이전 blocker:

재현 명령:

```bash
flutter build ios --release --no-codesign --dart-define=COUPON_KEEPER_PRO_PRODUCT_ID=coupon_keeper_pro
```

실패 증상:

```text
Error (Xcode): Failed to launch AssetCatalogSimulatorAgent via CoreSimulator spawn
```

추가 진단:

```bash
xcodebuild -runFirstLaunch
xcrun simctl spawn <booted-device-udid> /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Xcode/Overlays/AssetCatalogSimulatorAgent
```

- `xcodebuild -runFirstLaunch`는 성공했지만 iOS build 실패는 그대로 재현된다.
- 직접 spawn도 `com.apple.CoreSimulator.LaunchdSimError Code=153`로 실패한다.
- 시스템 로그의 핵심 원인은 AMFI library validation 거부다.

```text
dynamic: com.apple.dt.AssetCatalogSimulatorAgent disallowed without library validation
code signature validation failed fatally
```

판단:

- 앱 코드, Flutter doctor, Android toolchain 문제는 아니다.
- Apple Xcode 지원 매트릭스 기준으로 macOS 26.x에는 Xcode 26.x 계열이 필요하다. 현재 Xcode 16.1은 macOS 14.5~15.x 세대 도구라 macOS 26.5의 AMFI 정책과 맞지 않는 것으로 판단한다.
- 근거: Apple Developer의 [Xcode support matrix](https://developer.apple.com/support/xcode/)와 [Xcode 16.1 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-16_1-release-notes).

다음 조치:

1. Xcode를 현재 macOS 26.5와 호환되는 Xcode 26.x 계열로 업데이트한다.
2. `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`가 새 Xcode를 가리키는지 확인한다.
3. `xcodebuild -runFirstLaunch`를 다시 실행한다.
4. iOS no-codesign release build를 재시도한다.

확인한 업데이트 경로:

```bash
mas outdated
```

위 명령은 App Store의 Xcode 업데이트를 `16.1 -> 26.5`로 표시한다.

```bash
mas upgrade 497799835
```

위 명령은 Xcode 업데이트를 시작할 수 있지만 현재 자동 실행에서는 관리자 비밀번호 입력이 필요한 `sudo` 단계에서 멈춘다.

```text
sudo: a terminal is required to read the password
sudo: a password is required
```

`xcodes install 26.5`도 확인했지만 Apple ID/비밀번호가 필요해 자동 설치가 진행되지 않는다.

이 경로로 Xcode 26.5 업데이트가 완료됐다.

추가 우회 검토:

```bash
flutter build ios --release --no-codesign --dart-define=COUPON_KEEPER_PRO_PRODUCT_ID=coupon_keeper_pro --config-only
xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOLS=NO \
  ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS=NO \
  build
```

결과:

- Swift asset symbol 생성을 꺼도 `CompileAssetCatalog` 단계가 동일하게 실패한다.
- 따라서 blocker는 asset symbol 확장 생성이 아니라 Xcode 16.1 `actool`이 `Assets.xcassets`를 컴파일할 때 CoreSimulator helper를 실행하지 못하는 문제다.
