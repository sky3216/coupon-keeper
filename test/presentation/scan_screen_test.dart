import 'dart:async';

import 'package:coupon_keeper/application/guided_scan_controller.dart';
import 'package:coupon_keeper/data/in_memory_scan_fingerprint_cache.dart';
import 'package:coupon_keeper/domain/scan_item.dart';
import 'package:coupon_keeper/domain/scan_source.dart';
import 'package:coupon_keeper/platform/fake_scan_source_picker.dart';
import 'package:coupon_keeper/presentation/screens/scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('idle scan surface shows guided source choices', (tester) async {
    final picker = FakeScanSourcePicker.photos([
      _item('photo-1', sourceType: ScanSourceType.photos),
    ]);
    await tester.pumpWidget(
      _scanScreen(
        GuidedScanController(
          picker: picker,
          fingerprintCache: InMemoryScanFingerprintCache(),
        ),
      ),
    );

    expect(find.text('어디에서 쿠폰을 찾을까요?'), findsOneWidget);
    expect(find.text('선택한 사진과 파일만 기기 안에서 확인합니다.'), findsOneWidget);
    expect(find.text('사진에서 찾기'), findsOneWidget);
    expect(find.text('사진 앱에서 직접 고른 항목만 확인해요.'), findsOneWidget);
    expect(find.text('다운로드/파일에서 찾기'), findsOneWidget);
    expect(find.text('다운로드한 이미지나 폴더를 직접 고릅니다.'), findsOneWidget);
    expect(find.text('전체 사진첩이나 폴더를 조용히 훑지 않아요.'), findsOneWidget);
    expect(find.textContaining('전체 사진첩 스캔'), findsNothing);

    await tester.tap(find.text('사진에서 찾기'));
    await tester.pumpAndSettle();

    expect(picker.requestedSources, [ScanSourceType.photos]);
  });

  testWidgets('progress view shows counts, duplicate summary, and cancels', (
    tester,
  ) async {
    final duplicate = _item('duplicate');
    final fresh = _item('fresh');
    final cache = InMemoryScanFingerprintCache();
    await cache.markSeen(duplicate);
    final gate = Completer<void>();
    final controller = GuidedScanController(
      picker: FakeScanSourcePicker.downloads([duplicate, fresh]),
      fingerprintCache: cache,
      processItem: (_) => gate.future,
    );
    await tester.pumpWidget(_scanScreen(controller));

    await tester.tap(find.text('다운로드/파일에서 찾기'));
    await tester.pump();

    expect(find.text('선택한 항목을 확인하고 있어요'), findsOneWidget);
    expect(find.text('0/2 처리 중'), findsOneWidget);
    expect(find.text('후보 확인 준비 중'), findsOneWidget);
    expect(find.text('이미 확인한 항목 1개는 건너뛰었어요'), findsOneWidget);
    expect(find.text('취소'), findsOneWidget);
    expect(find.textContaining('후보 1개'), findsNothing);

    await tester.tap(find.text('취소'));
    gate.complete();
    await tester.pumpAndSettle();

    expect(find.text('스캔을 멈췄어요'), findsOneWidget);
    expect(find.text('다시 선택'), findsOneWidget);
    expect(find.text('Scan 처음으로'), findsOneWidget);
  });

  testWidgets('empty, error, and completion states use approved copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      _scanScreen(
        GuidedScanController(
          picker: FakeScanSourcePicker.downloads(const []),
          fingerprintCache: InMemoryScanFingerprintCache(),
        ),
      ),
    );
    await tester.tap(find.text('다운로드/파일에서 찾기'));
    await tester.pumpAndSettle();
    expect(find.text('이번 선택에서는 쿠폰을 찾지 못했어요'), findsOneWidget);
    expect(find.text('다시 선택'), findsOneWidget);

    await tester.pumpWidget(
      _scanScreen(
        GuidedScanController(
          picker: FakeScanSourcePicker.accessDenied(),
          fingerprintCache: InMemoryScanFingerprintCache(),
        ),
      ),
    );
    await tester.tap(find.text('사진에서 찾기'));
    await tester.pumpAndSettle();
    expect(find.text('선택한 항목을 열 수 없어요'), findsOneWidget);

    await tester.pumpWidget(
      _scanScreen(
        GuidedScanController(
          picker: FakeScanSourcePicker.fileUnavailable(),
          fingerprintCache: InMemoryScanFingerprintCache(),
        ),
      ),
    );
    await tester.tap(find.text('다운로드/파일에서 찾기'));
    await tester.pumpAndSettle();
    expect(find.text('파일을 찾을 수 없어요'), findsOneWidget);

    await tester.pumpWidget(
      _scanScreen(
        GuidedScanController(
          picker: FakeScanSourcePicker.downloads([_item('bad')]),
          fingerprintCache: InMemoryScanFingerprintCache(),
          processItem: (_) => throw StateError('cannot process'),
        ),
      ),
    );
    await tester.tap(find.text('다운로드/파일에서 찾기'));
    await tester.pumpAndSettle();
    expect(find.text('일부 항목을 확인하지 못했어요'), findsOneWidget);

    await tester.pumpWidget(
      _scanScreen(
        GuidedScanController(
          picker: FakeScanSourcePicker.downloads([_item('done')]),
          fingerprintCache: InMemoryScanFingerprintCache(),
        ),
      ),
    );
    await tester.tap(find.text('다운로드/파일에서 찾기'));
    await tester.pumpAndSettle();
    expect(find.text('선택한 항목 확인을 마쳤어요'), findsOneWidget);
    expect(find.text('확인한 항목 1개'), findsOneWidget);
    expect(find.textContaining('발견'), findsNothing);
    expect(find.textContaining('원 보호'), findsNothing);
  });

  testWidgets('scan source and cancel actions fit on 320x568', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final gate = Completer<void>();
    final controller = GuidedScanController(
      picker: FakeScanSourcePicker.downloads([_item('small')]),
      fingerprintCache: InMemoryScanFingerprintCache(),
      processItem: (_) => gate.future,
    );
    await tester.pumpWidget(_scanScreen(controller));

    await tester.ensureVisible(find.text('다운로드/파일에서 찾기'));
    await tester.tap(find.text('다운로드/파일에서 찾기'));
    await tester.pump();

    await tester.ensureVisible(find.text('취소'));
    await tester.tap(find.text('취소'));
    gate.complete();
    await tester.pumpAndSettle();

    expect(find.text('스캔을 멈췄어요'), findsOneWidget);
  });
}

Widget _scanScreen(GuidedScanController controller) {
  return MaterialApp(home: Scaffold(body: ScanScreen(controller: controller)));
}

ScanItem _item(String token, {ScanSourceType sourceType = ScanSourceType.downloads}) {
  return ScanItem(
    sourceType: sourceType,
    sourceToken: token,
    displayName: '$token.jpg',
    byteSize: 1024,
    modifiedAt: DateTime(2026, 5, 24),
  );
}
