---
phase: 6
plan: 06-02
status: completed
completed_at: "2026-06-06T13:10:31.000+09:00"
workflow: mvp-light
---

# 06-02 Summary: Store purchase/restore integration

## 완료

- production composition에서 MethodChannel purchase skeleton을 제거하고 Flutter 공식 `in_app_purchase` 기반 gateway로 교체했다.
- 기본 Pro 상품 ID는 `COUPON_KEEPER_PRO_PRODUCT_ID` dart-define으로 바꿀 수 있고, 기본값은 `coupon_keeper_pro`로 둔다.
- purchase flow는 상품 조회, non-consumable 구매 시작, purchase stream 구독, pending completion 처리를 수행한다.
- restore flow는 복원 구매를 확인해 Pro entitlement를 unlock하고, 복원 항목이 없으면 free fallback으로 끝난다.
- Scan 저장 한도와 Wallet cleanup gate에서 같은 Pro gate sheet를 띄워 구매/복원/나중에 선택을 처리한다.
- 구매 또는 복원 성공 시 `ProEntitlementController`가 SQLite local entitlement cache에 Pro 상태를 저장한다.

## 검증

- `flutter analyze` 통과.
- `flutter test` 통과: 123/123.
- `flutter build apk --debug` 통과.
- Android emulator `emulator-5554`에 debug APK 설치와 앱 실행 통과.

## 남은 참고

- 실제 결제 승인까지의 E2E 검증은 App Store Connect/Google Play Console 상품 등록, 내부 테스터 계정, sandbox billing 환경이 필요하다.
- iOS 실행 검증은 현재 Xcode/CoreSimulator 환경 이슈가 해결된 뒤 별도로 진행한다.
