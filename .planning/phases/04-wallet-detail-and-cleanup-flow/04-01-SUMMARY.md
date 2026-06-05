---
phase: 4
plan: 04-01
status: completed
completed_at: "2026-06-05T23:20:00.000+09:00"
workflow: mvp-light
---

# 04-01 Summary: Wallet 목록, 상세, 사용 완료 흐름

## 완료

- 공유 `PassRepository`에서 사용 가능, 사용 완료, 만료, 정리 후보 패스를 읽는 `WalletController`를 추가했다.
- Wallet 탭이 Scan 저장 흐름과 같은 production 또는 injected repository를 보도록 연결했다.
- 빈 상태만 있던 Wallet 화면을 실제 목록, 상태 필터, pass row, 필터별 빈 상태로 확장했다.
- pass 상세 화면에 큰 이미지 패널, 만료일, 금액, 원본 상태, 바코드 패널, 하단 사용 완료 액션을 추가했다.
- 사용 완료 액션이 pass 상태를 `used`로 업데이트하고 Wallet 상태를 갱신하도록 연결했다.
- 저장된 쿠폰이 Wallet에 보이고 사용 완료로 이동하는 widget 테스트를 추가했다.

## 검증

- `flutter analyze` 통과.
- `flutter test` 94/94 통과.
- `flutter build apk --debug` 통과.
- Android emulator smoke 통과: `emulator-5554`에서 앱 실행, Wallet 저장 쿠폰 목록 표시, 상세 진입, 사용 완료 상태 전환을 확인했다.

## 남은 Phase 4 작업

- 바코드/이미지 확대 모드를 더 강하게 연결한다.
- 정리 후보 리뷰와 원본 정리 handoff를 추가한다.
- 원본 누락 복구 상태를 더 구체화한다.
