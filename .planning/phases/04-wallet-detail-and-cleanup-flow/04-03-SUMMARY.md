---
phase: 4
plan: 04-03
status: completed
completed_at: "2026-06-05T23:47:02.000+09:00"
workflow: mvp-light
---

# 04-03 Summary: Source cleanup handoff and source-missing recovery

## 완료

- Cleanup 후보 상세 화면에 `원본 정리 안내`를 추가했다.
- 앱은 원본 사진이나 파일을 자동 삭제하지 않고, 원본 앱 또는 시스템 파일 화면으로 handoff만 시도한다.
- `SourceCleanupLauncher`와 `MethodChannelSourceCleanupLauncher`를 추가해 UI에서 native handoff를 주입 가능하게 만들었다.
- Android는 `coupon_keeper/source_cleanup` MethodChannel에서 `Intent.ACTION_VIEW`와 `FLAG_GRANT_READ_URI_PERMISSION`으로 원본 URI를 연다.
- iOS는 같은 채널에서 열 수 있는 URL을 `UIApplication.shared.open`으로 연다.
- 원본이 사라진 pass는 Wallet과 detail에서 `원본 없음`, `원본 파일 확인 필요`, `앱 내부 사본으로 계속 사용할 수 있어요` 상태를 보여주며 앱 내부 사본으로 계속 사용할 수 있다.

## 검증

- `flutter analyze` 통과.
- `flutter test` 통과: 98/98.
- `flutter build apk --debug` 통과.
- Android emulator `emulator-5554`에 debug APK 설치와 앱 실행 통과.

## 남은 참고

- iOS 실행 검증은 현재 Xcode/CoreSimulator 환경 이슈가 해결된 뒤 별도로 진행한다.
- Phase 5는 무료 D-7/D-Day reminder scheduling과 launch/resume reconciliation부터 MVP Light로 진행한다.
