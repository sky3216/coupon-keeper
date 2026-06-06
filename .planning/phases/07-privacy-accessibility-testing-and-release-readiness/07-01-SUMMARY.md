---
phase: 7
plan: 07-01
status: partial-completed-ios-env-blocked
completed_at: "2026-06-06T13:21:50.000+09:00"
workflow: mvp-light
---

# 07-01 Summary: Privacy, accessibility, and release readiness

## 완료

- `docs/release-readiness.md`에 개인정보 경계, 접근성 기준, 내부 테스트 빌드 명령, 스토어 IAP 설정 메모를 정리했다.
- Android manifest와 iOS Info.plist가 광범위 미디어, 위치, 네트워크 권한을 선언하지 않는지 테스트로 고정했다.
- 쿠폰 상세 화면의 만료일, 예상 금액, 원본 상태, 바코드, 쿠폰 이미지, 사용 완료, 정리 후보, 원본 앱 열기 액션에 semantics label을 보강했다.
- 바코드 확대 화면이 독립적인 스크린리더 라벨을 제공하도록 정리했다.

## 검증

- `flutter analyze` 통과.
- `flutter test` 통과: 126/126.
- `flutter build apk --debug` 통과.
- Android emulator `emulator-5554`에 debug APK 설치와 앱 실행 통과.
- `flutter build appbundle --release --dart-define=COUPON_KEEPER_PRO_PRODUCT_ID=coupon_keeper_pro` 통과.

## 남은 blocker

- `flutter build ios --release --no-codesign --dart-define=COUPON_KEEPER_PRO_PRODUCT_ID=coupon_keeper_pro`는 실패했다.
- 실패 원인: Xcode/CoreSimulator가 `AssetCatalogSimulatorAgent`를 실행하지 못한다.
- 환경: macOS 26.5, Xcode 16.1.
- CoreSimulator service restart와 `xcodebuild -runFirstLaunch` 후에도 같은 오류가 재현됐다.
- 직접 `xcrun simctl spawn`으로 `AssetCatalogSimulatorAgent`를 실행해도 `com.apple.CoreSimulator.LaunchdSimError Code=153`가 재현된다.
- 시스템 로그에서 `dynamic: com.apple.dt.AssetCatalogSimulatorAgent disallowed without library validation`와 `code signature validation failed fatally`가 확인됐다.
- Apple Xcode 지원 매트릭스 기준으로 macOS 26.x에는 Xcode 26.x 계열이 필요하다. 다음 조치는 Xcode를 macOS 26.5와 호환되는 버전으로 업데이트한 뒤 iOS no-codesign release build를 재시도하는 것이다.
