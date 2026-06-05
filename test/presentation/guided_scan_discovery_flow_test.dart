import 'package:coupon_keeper/application/candidate_discovery_controller.dart';
import 'package:coupon_keeper/application/guided_scan_controller.dart';
import 'package:coupon_keeper/application/pass_candidate_parser.dart';
import 'package:coupon_keeper/data/in_memory_pass_repository.dart';
import 'package:coupon_keeper/data/in_memory_scan_fingerprint_cache.dart';
import 'package:coupon_keeper/domain/ocr_text.dart';
import 'package:coupon_keeper/domain/scan_item.dart';
import 'package:coupon_keeper/domain/scan_source.dart';
import 'package:coupon_keeper/platform/fake_image_copy_store.dart';
import 'package:coupon_keeper/platform/fake_ocr_text_recognizer.dart';
import 'package:coupon_keeper/platform/fake_scan_source_picker.dart';
import 'package:coupon_keeper/presentation/app/coupon_keeper_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Today to report to explicit candidate save completes batch', (
    tester,
  ) async {
    final repository = InMemoryPassRepository();
    final discovery = CandidateDiscoveryController(
      recognizer: FakeOcrTextRecognizer.success(_ocr),
      parser: const PassCandidateParser(),
      imageCopyStore: FakeImageCopyStore(),
      passRepository: repository,
      now: () => DateTime(2026, 5, 31),
      nextId: () => 'pass-1',
    );
    final guided = GuidedScanController(
      picker: FakeScanSourcePicker.downloads([_item, _secondItem]),
      fingerprintCache: InMemoryScanFingerprintCache(),
      processItem: discovery.processItem,
    );
    await tester.pumpWidget(
      CouponKeeperApp(scanController: guided, discoveryController: discovery),
    );

    await tester.tap(find.text('숨어 있는 쿠폰 찾기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다운로드/파일에서 찾기'));
    await tester.pumpAndSettle();

    expect(find.text('놓칠 수 있는 쿠폰을 찾았어요'), findsOneWidget);
    expect(await repository.listAll(), isEmpty);

    await tester.tap(find.text('후보 검토 시작'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('2026.06.30'));
    await tester.tap(find.text('2026.06.30'));
    await tester.pump();
    await tester.ensureVisible(find.text('이 쿠폰 저장'));
    await tester.tap(find.text('이 쿠폰 저장'));
    await tester.pumpAndSettle();

    expect(find.text('후보 2/2'), findsOneWidget);
    await tester.ensureVisible(find.text('쿠폰 아님'));
    await tester.tap(find.text('쿠폰 아님'));
    await tester.pumpAndSettle();

    expect(find.text('쿠폰 확인을 마쳤어요'), findsOneWidget);
    expect(find.text('저장한 쿠폰 1개'), findsOneWidget);
    expect(find.text('건너뛴 후보 1개'), findsOneWidget);
    expect(await repository.listAll(), hasLength(1));
  });

  testWidgets('saved coupon is visible in Wallet and can be marked used', (
    tester,
  ) async {
    final repository = InMemoryPassRepository();
    final discovery = CandidateDiscoveryController(
      recognizer: FakeOcrTextRecognizer.success(_ocr),
      parser: const PassCandidateParser(),
      imageCopyStore: FakeImageCopyStore(),
      passRepository: repository,
      now: () => DateTime(2026, 5, 31),
      nextId: () => 'pass-1',
    );
    final guided = GuidedScanController(
      picker: FakeScanSourcePicker.downloads([_item]),
      fingerprintCache: InMemoryScanFingerprintCache(),
      processItem: discovery.processItem,
    );
    await tester.pumpWidget(
      CouponKeeperApp(scanController: guided, discoveryController: discovery),
    );

    await tester.tap(find.text('숨어 있는 쿠폰 찾기'));
    await tester.pumpAndSettle();
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

    await tester.tap(find.text('Wallet에서 보기'));
    await tester.pumpAndSettle();

    expect(find.text('무료 음료 쿠폰'), findsOneWidget);
    expect(find.text('2026.06.30까지'), findsOneWidget);

    await tester.tap(find.text('무료 음료 쿠폰'));
    await tester.pumpAndSettle();
    expect(find.text('이 쿠폰 사용 완료'), findsOneWidget);

    await tester.tap(find.text('이 쿠폰 사용 완료'));
    await tester.pumpAndSettle();

    expect(find.text('사용 완료'), findsOneWidget);
    expect((await repository.getById('pass-1'))?.status.name, 'used');
  });
}

final _item = ScanItem(
  sourceType: ScanSourceType.downloads,
  sourceToken: 'flow-item',
  platformSourceRef: 'fixture://flow-item',
  displayName: 'flow.jpg',
);

final _secondItem = ScanItem(
  sourceType: ScanSourceType.downloads,
  sourceToken: 'flow-item-2',
  platformSourceRef: 'fixture://flow-item-2',
  displayName: 'flow-2.jpg',
);

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
