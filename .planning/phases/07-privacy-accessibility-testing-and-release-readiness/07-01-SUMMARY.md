---
phase: 7
plan: 07-01
status: completed
completed_at: "2026-06-07T22:11:27.000+09:00"
workflow: mvp-light
---

# 07-01 Summary: Privacy, accessibility, and release readiness

## 완료

- `docs/release-readiness.md`에 개인정보 경계, 접근성 기준, 내부 테스트 빌드 명령, 스토어 IAP 설정 메모를 정리했다.
- Android manifest와 iOS Info.plist가 광범위 미디어, 위치, 네트워크 권한을 선언하지 않는지 테스트로 고정했다.
- 쿠폰 상세 화면의 만료일, 예상 금액, 원본 상태, 바코드, 쿠폰 이미지, 사용 완료, 정리 후보, 원본 앱 열기 액션에 semantics label을 보강했다.
- 바코드 확대 화면이 독립적인 스크린리더 라벨을 제공하도록 정리했다.
- iOS production picker가 사용하는 `PHPicker`와 `UTType` availability에 맞춰 Runner deployment target을 iOS 14.0으로 올렸다.

## 검증

- `flutter analyze` 통과.
- `flutter test` 통과: 126/126.
- `flutter build apk --debug` 통과.
- Android emulator `emulator-5554`에 debug APK 설치와 앱 실행 통과.
- `flutter build appbundle --release --dart-define=COUPON_KEEPER_PRO_PRODUCT_ID=coupon_keeper_pro` 통과.
- Xcode 26.5, iOS 26.5 platform/runtime 환경에서 `flutter build ios --release --no-codesign --dart-define=COUPON_KEEPER_PRO_PRODUCT_ID=coupon_keeper_pro` 통과.

## 닫은 blocker

- Xcode 16.1/macOS 26.5 조합의 `AssetCatalogSimulatorAgent` 실패는 Xcode 26.5 업데이트로 해소됐다.
- Xcode 26.5 설치 직후 missing iOS platform/runtime 실패는 `xcodebuild -downloadPlatform iOS`로 iOS 26.5 runtime을 설치해 해소됐다.
- iOS 13 deployment target과 iOS 14 API(`PHPicker`, `UTType`) 불일치는 Runner deployment target을 14.0으로 올려 해소됐다.
