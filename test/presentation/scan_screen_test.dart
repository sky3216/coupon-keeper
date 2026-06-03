import 'dart:async';

import 'package:coupon_keeper/application/candidate_discovery_controller.dart';
import 'package:coupon_keeper/application/guided_scan_controller.dart';
import 'package:coupon_keeper/application/pass_candidate_parser.dart';
import 'package:coupon_keeper/data/in_memory_pass_repository.dart';
import 'package:coupon_keeper/data/in_memory_scan_fingerprint_cache.dart';
import 'package:coupon_keeper/domain/ocr_text.dart';
import 'package:coupon_keeper/domain/pass.dart';
import 'package:coupon_keeper/domain/scan_item.dart';
import 'package:coupon_keeper/domain/scan_source.dart';
import 'package:coupon_keeper/platform/fake_image_copy_store.dart';
import 'package:coupon_keeper/platform/fake_ocr_text_recognizer.dart';
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
    expect(find.text('다운로드한 이미지를 직접 고릅니다.'), findsOneWidget);
    expect(find.text('폴더에서 찾기'), findsOneWidget);
    expect(find.text('직접 고른 폴더의 바로 안쪽 이미지만 확인해요.'), findsOneWidget);
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

  testWidgets(
    'partial success can retry failures without opening picker and show report',
    (tester) async {
      final good = _item('good', platformSourceRef: 'fixture://good');
      final bad = _item('bad', platformSourceRef: 'fixture://bad');
      final picker = FakeScanSourcePicker.downloads([good, bad]);
      final discovery = _discovery();
      final controller = GuidedScanController(
        picker: picker,
        fingerprintCache: InMemoryScanFingerprintCache(),
        processItem: (item) async {
          if (item.sourceToken == bad.sourceToken) {
            throw StateError('cannot process');
          }
          await discovery.processItem(item);
        },
      );
      await tester.pumpWidget(_scanScreen(controller, discovery: discovery));

      await tester.tap(find.text('다운로드/파일에서 찾기'));
      await tester.pumpAndSettle();

      expect(find.text('일부 항목만 확인했어요'), findsOneWidget);
      expect(find.text('확인한 항목 1개'), findsOneWidget);
      expect(find.text('확인하지 못한 항목 1개'), findsOneWidget);
      expect(find.text('남은 항목 다시 시도'), findsOneWidget);
      expect(find.text('확인한 후보 보기'), findsOneWidget);
      expect(find.text('다시 선택'), findsOneWidget);

      await tester.tap(find.text('남은 항목 다시 시도'));
      await tester.pumpAndSettle();

      expect(picker.requestedSources, [ScanSourceType.downloads]);
      expect(picker.retryRequests, isEmpty);
      expect(find.text('일부 항목만 확인했어요'), findsOneWidget);

      await tester.tap(find.text('확인한 후보 보기'));
      await tester.pumpAndSettle();

      expect(find.text('놓칠 수 있는 쿠폰을 찾았어요'), findsOneWidget);
      expect(find.text('찾은 후보 1개'), findsOneWidget);
    },
  );

  testWidgets('candidate save failure keeps review form visible', (
    tester,
  ) async {
    final repository = _FailingPassRepository();
    final discovery = _discovery(repository: repository);
    final controller = GuidedScanController(
      picker: FakeScanSourcePicker.downloads([
        _item('save-failure', platformSourceRef: 'fixture://save-failure'),
      ]),
      fingerprintCache: InMemoryScanFingerprintCache(),
      processItem: discovery.processItem,
    );
    await tester.pumpWidget(_scanScreen(controller, discovery: discovery));

    await tester.tap(find.text('다운로드/파일에서 찾기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('후보 검토 시작'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('2026.06.30'));
    await tester.tap(find.text('2026.06.30'));
    await tester.pump();
    await tester.ensureVisible(find.text('이 쿠폰 저장'));
    await tester.tap(find.text('이 쿠폰 저장'));
    await tester.pumpAndSettle();

    expect(find.text('저장하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(find.text('후보 1/1'), findsOneWidget);
    expect(find.text('쿠폰 확인을 마쳤어요'), findsNothing);
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

Widget _scanScreen(
  GuidedScanController controller, {
  CandidateDiscoveryController? discovery,
}) {
  return MaterialApp(
    home: Scaffold(
      body: ScanScreen(controller: controller, discoveryController: discovery),
    ),
  );
}

CandidateDiscoveryController _discovery({InMemoryPassRepository? repository}) {
  return CandidateDiscoveryController(
    recognizer: FakeOcrTextRecognizer.success(_ocr),
    parser: const PassCandidateParser(),
    imageCopyStore: FakeImageCopyStore(),
    passRepository: repository ?? InMemoryPassRepository(),
    now: () => DateTime(2026, 5, 31),
    nextId: () => 'pass-1',
  );
}

ScanItem _item(
  String token, {
  ScanSourceType sourceType = ScanSourceType.downloads,
  String? platformSourceRef,
}) {
  return ScanItem(
    sourceType: sourceType,
    sourceToken: token,
    platformSourceRef: platformSourceRef,
    displayName: '$token.jpg',
    byteSize: 1024,
    modifiedAt: DateTime(2026, 5, 24),
  );
}

class _FailingPassRepository extends InMemoryPassRepository {
  @override
  Future<void> save(Pass pass) async {
    throw StateError('repository failed');
  }
}

const _ocr = OcrTextResult(
  fullText: '무료 음료 쿠폰\n2026.06.30',
  blocks: [
    OcrTextBlock(
      text: '무료 음료 쿠폰\n2026.06.30',
      bounds: OcrBounds(left: 0, top: 0, width: 1, height: 1),
      confidence: 0.9,
      lines: [
        OcrTextLine(
          text: '무료 음료 쿠폰',
          bounds: OcrBounds(left: 0, top: 0, width: 1, height: 0.2),
          confidence: 0.9,
        ),
        OcrTextLine(
          text: '2026.06.30',
          bounds: OcrBounds(left: 0, top: 0.3, width: 1, height: 0.2),
          confidence: 0.9,
        ),
      ],
    ),
  ],
);
