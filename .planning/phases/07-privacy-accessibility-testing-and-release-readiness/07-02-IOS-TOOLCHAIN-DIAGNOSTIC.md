---
phase: 7
diagnostic: ios-toolchain
status: environment-blocked
captured_at: "2026-06-06T13:39:30.000+09:00"
workflow: mvp-light
---

# 07-02 Diagnostic: iOS toolchain blocker

## 요약

Coupon Keeper iOS release build는 앱 코드가 아니라 로컬 Xcode/CoreSimulator toolchain 호환성 문제로 막혀 있다.

## 현재 환경

- macOS Tahoe 26.5 (25F71)
- Xcode 16.1 (16B40)
- Flutter 3.44.0
- iOS runtimes: 17.5, 18.1

## 재현

```bash
flutter build ios --release --no-codesign --dart-define=COUPON_KEEPER_PRO_PRODUCT_ID=coupon_keeper_pro
```

결과:

```text
Error (Xcode): Failed to launch AssetCatalogSimulatorAgent via CoreSimulator spawn
```

직접 helper spawn 재현:

```bash
xcrun simctl boot 68F7C5E2-728D-4B69-8019-DD3D911DA0FB
xcrun simctl bootstatus 68F7C5E2-728D-4B69-8019-DD3D911DA0FB -b
xcrun simctl spawn 68F7C5E2-728D-4B69-8019-DD3D911DA0FB /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Xcode/Overlays/AssetCatalogSimulatorAgent
```

결과:

```text
Error Domain=com.apple.CoreSimulator.LaunchdSimError Code=153
Process spawn via launchd failed.
```

## 확인한 것

- `flutter doctor -v`는 Xcode, Android, network 모두 통과한다.
- `codesign --verify --deep --strict`는 `AssetCatalogSimulatorAgent`를 valid로 본다.
- Xcode quarantine xattr는 확인되지 않았다.
- `xcodebuild -runFirstLaunch`는 성공했지만 build 실패는 그대로 재현된다.
- CoreSimulator service restart 후에도 실패한다.

## 핵심 로그

```text
AMFI: When validating .../AssetCatalogSimulatorAgent:
dynamic: com.apple.dt.AssetCatalogSimulatorAgent disallowed without library validation
code signature validation failed fatally
proc ... load code signature error 4 for file "AssetCatalogSimulatorAgent"
```

## 판단

Apple Xcode 지원 매트릭스 기준으로 현재 macOS 26.x에는 Xcode 26.x 계열이 필요하다. 현재 설치된 Xcode 16.1은 macOS 14.5~15.x 세대 도구라 macOS 26.5의 AMFI/library validation 정책에서 simulator helper 실행이 막히는 것으로 판단한다.

근거:

- Apple Developer Xcode support matrix: https://developer.apple.com/support/xcode/
- Xcode 16.1 release notes: https://developer.apple.com/documentation/xcode-release-notes/xcode-16_1-release-notes

## 다음 조치

1. Xcode를 macOS 26.5와 호환되는 Xcode 26.x 계열로 업데이트한다.
2. `xcode-select -p`가 새 Xcode의 Developer 경로를 가리키는지 확인한다.
3. `xcodebuild -runFirstLaunch`를 실행한다.
4. 아래 명령을 재시도한다.

```bash
flutter build ios --release --no-codesign --dart-define=COUPON_KEEPER_PRO_PRODUCT_ID=coupon_keeper_pro
```
