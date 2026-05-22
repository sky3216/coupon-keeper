import 'package:coupon_keeper/presentation/app/coupon_keeper_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('launches with Today selected and three destinations', (
    tester,
  ) async {
    await tester.pumpWidget(const CouponKeeperApp());

    expect(find.text('잊고 있던 쿠폰을 찾아볼까요?'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Wallet'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
  });

  testWidgets('Today CTA moves to Scan without invoking a picker', (
    tester,
  ) async {
    await tester.pumpWidget(const CouponKeeperApp());

    await tester.tap(find.text('숨어 있는 쿠폰 찾기'));
    await tester.pumpAndSettle();

    expect(find.text('선택한 항목에서 쿠폰을 찾습니다'), findsOneWidget);
    expect(find.text('스캔 준비'), findsOneWidget);
  });

  testWidgets('Wallet CTA moves to Scan', (tester) async {
    await tester.pumpWidget(const CouponKeeperApp());

    await tester.tap(find.text('Wallet'));
    await tester.pumpAndSettle();
    expect(find.text('아직 지갑이 비어 있어요'), findsOneWidget);
    expect(find.text('스캔 후 저장한 쿠폰과 바코드 패스가 이곳에 모입니다.'), findsOneWidget);

    await tester.tap(find.text('Scan으로 이동'));
    await tester.pumpAndSettle();
    expect(find.text('선택한 항목에서 쿠폰을 찾습니다'), findsOneWidget);
  });

  testWidgets('empty states use approved copy and no placeholders', (
    tester,
  ) async {
    await tester.pumpWidget(const CouponKeeperApp());

    expect(
      find.text('사진과 다운로드에 흩어진 쿠폰을 선택한 범위 안에서 찾아 지갑에 모아둘 수 있어요.'),
      findsOneWidget,
    );
    expect(find.text('선택한 항목만 기기 안에서 확인합니다.'), findsOneWidget);
    expect(find.text('TODO'), findsNothing);
    expect(find.text('Lorem ipsum'), findsNothing);
    expect(find.text('Coming soon'), findsNothing);
  });

  testWidgets('Today primary CTA remains visible on 320x568', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const CouponKeeperApp());

    final cta = find.text('숨어 있는 쿠폰 찾기');
    expect(cta, findsOneWidget);
    await tester.ensureVisible(cta);
    await tester.tap(cta);
    await tester.pumpAndSettle();
    expect(find.text('선택한 항목에서 쿠폰을 찾습니다'), findsOneWidget);
  });

  testWidgets('Wallet remains honestly empty by default', (tester) async {
    await tester.pumpWidget(const CouponKeeperApp());

    await tester.tap(find.text('Wallet'));
    await tester.pumpAndSettle();

    expect(find.text('아직 지갑이 비어 있어요'), findsOneWidget);
    expect(find.text('스타벅스'), findsNothing);
    expect(find.text('아메리카노'), findsNothing);
    expect(find.text('sample coupon'), findsNothing);
  });
}
