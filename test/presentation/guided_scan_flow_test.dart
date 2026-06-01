import 'dart:async';
import 'dart:io';

import 'package:coupon_keeper/application/guided_scan_controller.dart';
import 'package:coupon_keeper/data/in_memory_scan_fingerprint_cache.dart';
import 'package:coupon_keeper/domain/scan_item.dart';
import 'package:coupon_keeper/domain/scan_source.dart';
import 'package:coupon_keeper/platform/fake_scan_source_picker.dart';
import 'package:coupon_keeper/presentation/app/coupon_keeper_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('default app path shows progress after selecting downloads', (
    tester,
  ) async {
    await tester.pumpWidget(const CouponKeeperApp());

    expect(find.text('잊고 있던 쿠폰을 찾아볼까요?'), findsOneWidget);
    await tester.tap(find.text('숨어 있는 쿠폰 찾기'));
    await tester.pumpAndSettle();

    expect(find.text('어디에서 쿠폰을 찾을까요?'), findsOneWidget);
    await tester.tap(find.text('다운로드/파일에서 찾기'));
    await tester.pump();

    expect(find.text('선택한 항목을 확인하고 있어요'), findsOneWidget);
    expect(find.text('0/1 처리 중'), findsOneWidget);
    expect(find.text('후보 확인 준비 중'), findsOneWidget);
    expect(find.text('취소'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('놓칠 수 있는 쿠폰을 찾았어요'), findsOneWidget);
    expect(find.text('찾은 후보 1개'), findsOneWidget);
    expect(find.text('후보 검토 시작'), findsOneWidget);
  });

  testWidgets('default duplicate selection shows skip feedback', (
    tester,
  ) async {
    await tester.pumpWidget(const CouponKeeperApp());

    await tester.tap(find.text('숨어 있는 쿠폰 찾기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다운로드/파일에서 찾기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(find.text('놓칠 수 있는 쿠폰을 찾았어요'), findsOneWidget);
    expect(find.text('찾은 후보 1개'), findsOneWidget);

    await tester.tap(find.text('다시 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다운로드/파일에서 찾기'));
    await tester.pump();

    expect(find.text('선택한 항목을 확인하고 있어요'), findsOneWidget);
    expect(find.text('0/1 처리 중'), findsOneWidget);
    expect(find.text('후보 확인 준비 중'), findsOneWidget);
    expect(find.text('취소'), findsOneWidget);
    expect(find.text('이미 확인한 항목 1개는 건너뛰었어요'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('선택한 항목 확인을 마쳤어요'), findsOneWidget);
    expect(find.text('건너뛴 항목 1개'), findsOneWidget);
    expect(find.textContaining('보호할 수 있는 금액'), findsNothing);
  });

  testWidgets(
    'guided scan flow starts at Today, completes, and skips repeat selections',
    (tester) async {
      final selected = _item('repeat-download');
      final cache = InMemoryScanFingerprintCache();
      final progressGate = Completer<void>();
      var processCalls = 0;
      final controller = GuidedScanController(
        picker: FakeScanSourcePicker.downloads([selected]),
        fingerprintCache: cache,
        processItem: (_) async {
          processCalls += 1;
          if (!progressGate.isCompleted) {
            await progressGate.future;
          }
        },
      );

      await tester.pumpWidget(CouponKeeperApp(scanController: controller));

      expect(find.text('잊고 있던 쿠폰을 찾아볼까요?'), findsOneWidget);
      await tester.tap(find.text('숨어 있는 쿠폰 찾기'));
      await tester.pumpAndSettle();
      expect(find.text('어디에서 쿠폰을 찾을까요?'), findsOneWidget);

      await tester.tap(find.text('다운로드/파일에서 찾기'));
      await tester.pump();
      expect(find.text('선택한 항목을 확인하고 있어요'), findsOneWidget);
      expect(find.text('0/1 처리 중'), findsOneWidget);
      expect(find.text('후보 확인 준비 중'), findsOneWidget);

      progressGate.complete();
      await tester.pumpAndSettle();
      expect(find.text('선택한 항목 확인을 마쳤어요'), findsOneWidget);
      expect(find.text('확인한 항목 1개'), findsOneWidget);

      await tester.tap(find.text('다시 선택'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('다운로드/파일에서 찾기'));
      await tester.pumpAndSettle();

      expect(find.text('선택한 항목 확인을 마쳤어요'), findsOneWidget);
      expect(find.text('건너뛴 항목 1개'), findsOneWidget);
      expect(processCalls, 1);
      expect(find.textContaining('발견'), findsNothing);
      expect(find.textContaining('저장'), findsNothing);
      expect(find.textContaining('수정'), findsNothing);
      expect(find.textContaining('원 보호'), findsNothing);
    },
  );

  test(
    'privacy guard rejects broad scan, broad permissions, and upload scope',
    () {
      final forbiddenPatterns = <RegExp>[
        RegExp(r'READ_MEDIA_IMAGES'),
        RegExp(r'READ_EXTERNAL_STORAGE'),
        RegExp(r'NSPhotoLibraryUsageDescription'),
        RegExp(r'\bdio\s*:', caseSensitive: false),
        RegExp(r'firebase', caseSensitive: false),
        RegExp(r'전체\s*사진첩\s*스캔'),
        RegExp(r'자동\s*업로드'),
        RegExp(r'자동\s*저장'),
        RegExp(r'cloud', caseSensitive: false),
        RegExp(r'upload', caseSensitive: false),
      ];
      final guardedFiles = [
        'pubspec.yaml',
        'android/app/src/main/AndroidManifest.xml',
        'ios/Runner/Info.plist',
        'lib/presentation/screens/scan_screen.dart',
      ];

      for (final path in guardedFiles) {
        final file = File(path);
        if (!file.existsSync()) {
          continue;
        }
        final text = file.readAsStringSync();
        for (final pattern in forbiddenPatterns) {
          expect(
            pattern.hasMatch(text),
            isFalse,
            reason: '$path must not contain broad scan/upload scope: $pattern',
          );
        }
      }
    },
  );
}

ScanItem _item(String token) {
  return ScanItem(
    sourceType: ScanSourceType.downloads,
    sourceToken: token,
    displayName: '$token.jpg',
    byteSize: 1024,
    modifiedAt: DateTime(2026, 5, 24),
  );
}
