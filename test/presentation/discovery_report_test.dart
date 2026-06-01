import 'package:coupon_keeper/domain/discovery_report.dart';
import 'package:coupon_keeper/presentation/widgets/discovery_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows protected value and report counts when verified', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const DiscoveryReport(
          candidateCount: 2,
          expiringSoonCount: 1,
          possiblyExpiredCount: 1,
          protectedValue: 4500,
        ),
      ),
    );

    expect(find.text('놓칠 수 있는 쿠폰을 찾았어요'), findsOneWidget);
    expect(find.text('보호할 수 있는 금액'), findsOneWidget);
    expect(find.text('4500원'), findsOneWidget);
    expect(find.text('찾은 후보 2개'), findsOneWidget);
    expect(find.text('7일 안에 만료 1개'), findsOneWidget);
    expect(find.text('이미 만료되었을 수 있음 1개'), findsOneWidget);
  });

  testWidgets('hides invented total when no protected value qualifies', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const DiscoveryReport(
          candidateCount: 1,
          expiringSoonCount: 0,
          possiblyExpiredCount: 0,
          protectedValue: null,
        ),
      ),
    );

    expect(find.text('금액은 후보를 확인하면서 정확하게 입력할 수 있어요.'), findsOneWidget);
    expect(find.textContaining('원'), findsNothing);
  });
}

Widget _app(DiscoveryReport report) {
  return MaterialApp(
    home: Scaffold(
      body: DiscoveryReportView(
        report: report,
        onBeginReview: () {},
        onReset: () {},
      ),
    ),
  );
}
