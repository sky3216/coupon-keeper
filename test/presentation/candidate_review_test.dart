import 'package:coupon_keeper/domain/pass_candidate.dart';
import 'package:coupon_keeper/domain/pass_confidence.dart';
import 'package:coupon_keeper/domain/scan_item.dart';
import 'package:coupon_keeper/domain/scan_source.dart';
import 'package:coupon_keeper/presentation/widgets/candidate_review_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('requires expiry choice, opens viewer, and preserves edits', (
    tester,
  ) async {
    var candidate = _candidate;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return CandidateReviewForm(
                candidate: candidate,
                currentIndex: 1,
                totalCount: 1,
                onChanged:
                    ({
                      required title,
                      required brand,
                      required estimatedValue,
                      required confirmedExpiry,
                    }) {
                      setState(() {
                        candidate = candidate.copyWith(
                          title: title,
                          brand: brand,
                          estimatedValue: estimatedValue,
                          confirmedExpiry: confirmedExpiry,
                        );
                      });
                    },
                onSave: () async {},
                onReject: () {},
                onManualRegistration: () {},
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('후보 1/1'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.ensureVisible(find.text('2026.06.30'));
    await tester.tap(find.text('2026.06.30'));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );

    await tester.enterText(find.widgetWithText(TextField, '제목'), '수정한 쿠폰');
    final preview = find.bySemanticsLabel('선택한 쿠폰 이미지 확대해서 보기');
    await tester.ensureVisible(preview);
    await tester.tap(preview);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('선택한 쿠폰 이미지 전체 화면'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('수정한 쿠폰'), findsOneWidget);
  });

  testWidgets('keeps review actions reachable on 320x568', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CandidateReviewForm(
            candidate: _candidate,
            currentIndex: 1,
            totalCount: 1,
            onChanged:
                ({
                  required title,
                  required brand,
                  required estimatedValue,
                  required confirmedExpiry,
                }) {},
            onSave: () async {},
            onReject: () {},
            onManualRegistration: () {},
          ),
        ),
      ),
    );

    for (final label in ['2026.06.30', '이 쿠폰 저장', '쿠폰 아님', '직접 등록']) {
      await tester.ensureVisible(find.text(label));
      expect(find.text(label), findsOneWidget);
    }
  });
}

final _candidate = PassCandidate(
  source: ScanItem(
    sourceType: ScanSourceType.photos,
    sourceToken: 'asset-1',
    platformSourceRef: 'fixture://coupon',
    displayName: 'coupon.jpg',
  ),
  ocrText: '',
  title: '쿠폰',
  brand: null,
  estimatedValue: null,
  expiryCandidates: [ExpiryCandidate(date: DateTime(2026, 6, 30))],
  confirmedExpiry: null,
  barcodeNumericCandidates: const ['88012345678'],
  confidence: const PassConfidence(
    expiry: 0.7,
    value: 0,
    brand: 0,
    barcode: 0.7,
    overall: 0.7,
  ),
);
