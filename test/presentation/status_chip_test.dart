import 'package:coupon_keeper/presentation/widgets/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders every required status chip label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Wrap(
          children: [
            StatusChip(kind: StatusChipKind.sevenDays),
            StatusChip(kind: StatusChipKind.todayExpiry),
            StatusChip(kind: StatusChipKind.expired),
            StatusChip(kind: StatusChipKind.used),
            StatusChip(kind: StatusChipKind.needsReview),
            StatusChip(kind: StatusChipKind.sourceMissing),
          ],
        ),
      ),
    );

    expect(find.text('D-7'), findsOneWidget);
    expect(find.text('오늘 만료'), findsOneWidget);
    expect(find.text('만료됨'), findsOneWidget);
    expect(find.text('사용 완료'), findsOneWidget);
    expect(find.text('확인 필요'), findsOneWidget);
    expect(find.text('원본 없음'), findsOneWidget);
  });

  testWidgets('exposes semantic labels for non-color-only meaning', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            StatusChip(kind: StatusChipKind.sevenDays),
            StatusChip(kind: StatusChipKind.sourceMissing),
          ],
        ),
      ),
    );

    expect(find.bySemanticsLabel('만료 7일 전'), findsOneWidget);
    expect(find.bySemanticsLabel('원본 파일을 찾을 수 없음'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('chip text remains present at 320px width', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Wrap(
          children: [
            StatusChip(kind: StatusChipKind.sevenDays),
            StatusChip(kind: StatusChipKind.todayExpiry),
            StatusChip(kind: StatusChipKind.expired),
            StatusChip(kind: StatusChipKind.used),
            StatusChip(kind: StatusChipKind.needsReview),
            StatusChip(kind: StatusChipKind.sourceMissing),
          ],
        ),
      ),
    );

    expect(find.text('D-7'), findsOneWidget);
    expect(find.text('오늘 만료'), findsOneWidget);
    expect(find.text('원본 없음'), findsOneWidget);
  });
}
