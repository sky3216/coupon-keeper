---
phase: 4
plan: 04-02
status: completed
completed_at: "2026-06-05T23:32:00.000+09:00"
workflow: mvp-light
---

# 04-02 Summary: 바코드/이미지 확대와 정리 후보 전환

## 완료

- pass 상세 화면의 쿠폰 이미지 패널에 확대 버튼을 추가했다.
- `file://` 앱 내부 이미지 사본이 있으면 상세 이미지 패널에서 실제 이미지를 표시하도록 연결했다.
- 바코드 패널에 확대 버튼과 전체 화면 확대 화면을 추가했다.
- 사용 완료된 pass를 `cleanupCandidate` 상태로 전환하는 `WalletController.markCleanupCandidate`를 추가했다.
- Wallet 목록과 상세 화면에서 `정리 후보` 상태칩을 표시하도록 추가했다.
- 저장된 쿠폰 상세에서 이미지 확대, 바코드 확대, 사용 완료, 정리 후보 전환까지 이어지는 widget 테스트를 확장했다.

## 검증

- `flutter analyze` 통과.
- `flutter test` 94/94 통과.
- `flutter build apk --debug` 통과.
- Android emulator smoke 통과: `emulator-5554`에서 사용 완료 필터, 상세 화면, 바코드 확대, 정리 후보 전환을 확인했다.

## 남은 Phase 4 작업

- 정리 후보 목록에서 원본 정리 handoff를 제공한다.
- 원본 누락 상태의 복구/대체 행동을 구체화한다.
