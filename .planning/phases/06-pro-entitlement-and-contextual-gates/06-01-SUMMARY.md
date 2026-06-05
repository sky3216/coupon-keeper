---
phase: 6
plan: 06-01
status: completed
completed_at: "2026-06-06T00:09:08.000+09:00"
workflow: mvp-light
---

# 06-01 Summary: Entitlement core and contextual Pro gates

## 완료

- `ProEntitlement` domain model을 추가했다.
- `ProEntitlementRepository`와 in-memory/SQLite 구현을 추가했다.
- SQLite schema를 v2로 올리고 `pro_entitlement` local cache table을 추가했다.
- `ProPurchaseGateway`와 MethodChannel gateway skeleton을 추가했다.
- `ProEntitlementController`를 추가해 무료 active pass 5개 한도, cleanup candidate gate, custom reminder gate를 판단한다.
- candidate 저장 직전에 무료 6번째 active pass를 contextual Pro gate로 막는다.
- Wallet에서 cleanup candidate 이동 시 free 사용자는 contextual Pro gate 메시지를 본다.
- purchase/restore 결과는 entitlement cache에 저장되도록 controller 경계를 만들었다.

## 검증

- `flutter analyze` 통과.
- `flutter test` 통과: 118/118.
- `flutter build apk --debug` 통과.
- Android emulator `emulator-5554`에 debug APK 설치와 앱 실행 통과.

## 남은 참고

- PRO-03/PRO-04 실제 App Store/Google Play purchase/restore integration은 다음 Phase 6 조각으로 남긴다.
- 현재 MethodChannel gateway는 store SDK를 붙이기 위한 앱 내부 경계다.
- iOS 실행 검증은 현재 Xcode/CoreSimulator 환경 이슈가 해결된 뒤 별도로 진행한다.
