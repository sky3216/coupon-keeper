---
phase: 5
plan: 05-01
status: completed
completed_at: "2026-06-05T23:58:21.000+09:00"
workflow: mvp-light
---

# 05-01 Summary: Reminder engine and local notification adapters

## 완료

- `ReminderEngine`을 추가해 active pass의 만료일 기준 알림 요청을 계산한다.
- 무료 tier는 D-7과 D-Day 알림을 예약한다.
- Pro tier 규칙은 D-7, D-3, D-1, D-Day, custom day-before offset을 지원한다.
- pass 저장 직후 해당 pass의 reminder를 재예약한다.
- pass를 used 또는 cleanup candidate로 이동하면 해당 pass의 reminder를 취소한다.
- 앱 시작 시 알림 권한을 요청하고 reminder 전체 재조정을 실행한다.
- 앱 resume 시 stale/missing reminder를 전체 재조정한다.
- Android `coupon_keeper/reminders` MethodChannel은 `POST_NOTIFICATIONS` 권한 요청, `AlarmManager` 예약, pass별 취소, 전체 취소를 제공한다.
- Android `ReminderReceiver`는 예약 시점에 local notification을 표시한다.
- iOS `coupon_keeper/reminders` MethodChannel은 `UNUserNotificationCenter` 권한 요청, 예약, pass별 취소, 전체 취소를 제공한다.

## 검증

- `flutter analyze` 통과.
- `flutter test` 통과: 110/110.
- `flutter build apk --debug` 통과.
- Android emulator `emulator-5554`에 debug APK 설치와 앱 실행 통과.

## 남은 참고

- Pro 결제/복원/entitlement cache와 gate UI는 Phase 6에서 다룬다.
- iOS 실행 검증은 현재 Xcode/CoreSimulator 환경 이슈가 해결된 뒤 별도로 진행한다.
