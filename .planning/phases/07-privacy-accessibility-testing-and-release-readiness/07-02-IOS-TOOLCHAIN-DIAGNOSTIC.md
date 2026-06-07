---
phase: 7
diagnostic: ios-toolchain
status: resolved
captured_at: "2026-06-07T22:11:27.000+09:00"
workflow: mvp-light
---

# 07-02 Diagnostic: iOS toolchain blocker

## 요약

Coupon Keeper iOS release build는 Xcode 26.5, iOS 26.5 platform/runtime 설치, 그리고 iOS 14 deployment target 정렬 후 통과한다. 이 문서는 이전 blocker와 해결 경로를 남긴다.

## 현재 환경

- macOS Tahoe 26.5 (25F71)
- Xcode 26.5 (17F42)
- Flutter 3.44.0
- iOS runtimes: 17.5, 18.1, 26.5

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

완료된 조치:

1. Xcode를 macOS 26.5와 호환되는 Xcode 26.5로 업데이트했다.
2. Xcode license와 first launch 작업을 완료했다.
3. `xcodebuild -downloadPlatform iOS`로 iOS 26.5 platform/runtime을 설치했다.
4. Runner deployment target을 iOS 14.0으로 올려 `PHPicker`와 `UTType` usage availability와 맞췄다.
5. 아래 명령을 재시도해 통과했다.

```bash
flutter build ios --release --no-codesign --dart-define=COUPON_KEEPER_PRO_PRODUCT_ID=coupon_keeper_pro
```

## 업데이트 경로 확인

`mas` CLI를 설치해 App Store 업데이트 상태를 확인했다.

```bash
mas outdated
```

결과:

```text
497799835  Xcode  (16.1 -> 26.5)
```

업데이트 시도:

```bash
mas upgrade 497799835
```

결과:

```text
sudo: a terminal is required to read the password
sudo: a password is required
```

`xcodes install 26.5`도 시도했지만 Apple ID/비밀번호가 없어 설치가 시작되지 않았다.

```text
Apple ID: Missing username or a password. Please try again.
```

결론: Xcode 26.5 업데이트 경로는 확인됐고, 사용자 인증 후 업데이트가 완료됐다.

## 우회 시도: asset symbol generation 비활성화

다음 build setting override로 Swift asset symbol generation을 끄고 iOS device build를 직접 실행했다.

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

```text
CompileAssetCatalog ... ios/Runner/Assets.xcassets
error: Failed to launch AssetCatalogSimulatorAgent via CoreSimulator spawn
```

판단:

- `GeneratedAssetSymbols.h`와 `GeneratedAssetSymbols.swift`는 제거됐지만 `actool` 자체가 실패한다.
- 이 우회는 실패했다.
- 원인은 project-level asset symbol 설정이 아니라 Xcode 16.1 `actool`과 macOS 26.5/CoreSimulator helper 실행 호환성이다.

## 최종 해결

Xcode 26.5 업데이트 후 처음에는 iOS 26.5 platform/runtime이 없어 device destination을 찾지 못했다.

```text
iOS 26.5 is not installed. Please download and install the platform from Xcode > Settings > Components.
```

`xcodebuild -downloadPlatform iOS`로 iOS 26.5 Simulator/runtime을 설치한 뒤 destination 문제가 해소됐다.

그 다음 Swift compiler가 iOS 13 deployment target과 iOS 14 APIs(`PHPicker`, `UTType`) 불일치를 보고했다. Runner deployment target을 14.0으로 올려 앱의 실제 production picker API 요구사항과 맞췄다.

최종 통과 명령:

```bash
flutter build ios --release --no-codesign --dart-define=COUPON_KEEPER_PRO_PRODUCT_ID=coupon_keeper_pro
```
