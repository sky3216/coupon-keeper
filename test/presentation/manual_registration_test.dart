import 'package:coupon_keeper/application/candidate_discovery_controller.dart';
import 'package:coupon_keeper/application/guided_scan_controller.dart';
import 'package:coupon_keeper/application/pass_candidate_parser.dart';
import 'package:coupon_keeper/data/in_memory_pass_repository.dart';
import 'package:coupon_keeper/data/in_memory_scan_fingerprint_cache.dart';
import 'package:coupon_keeper/domain/scan_item.dart';
import 'package:coupon_keeper/domain/scan_source.dart';
import 'package:coupon_keeper/platform/fake_image_copy_store.dart';
import 'package:coupon_keeper/platform/fake_ocr_text_recognizer.dart';
import 'package:coupon_keeper/platform/fake_scan_source_picker.dart';
import 'package:coupon_keeper/presentation/screens/scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('empty OCR recovers through selected-image manual registration', (
    tester,
  ) async {
    final repository = InMemoryPassRepository();
    final discovery = CandidateDiscoveryController(
      recognizer: FakeOcrTextRecognizer.empty(),
      parser: const PassCandidateParser(),
      imageCopyStore: FakeImageCopyStore(),
      passRepository: repository,
      now: () => DateTime(2026, 5, 31),
      nextId: () => 'manual-1',
    );
    final guided = GuidedScanController(
      picker: FakeScanSourcePicker.downloads([_item]),
      fingerprintCache: InMemoryScanFingerprintCache(),
      processItem: discovery.processItem,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScanScreen(controller: guided, discoveryController: discovery),
        ),
      ),
    );

    await tester.tap(find.text('다운로드/파일에서 찾기'));
    await tester.pumpAndSettle();
    expect(find.text('이번 선택에서는 쿠폰 후보를 찾지 못했어요'), findsOneWidget);

    await tester.tap(find.text('직접 등록'));
    await tester.pumpAndSettle();
    expect(find.text('쿠폰 정보를 직접 입력해 주세요'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, '제목'), '직접 등록 쿠폰');
    await tester.enterText(find.widgetWithText(TextField, '만료일'), '2026.06.30');
    await tester.pump();
    await tester.ensureVisible(find.text('쿠폰 저장'));
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNotNull);
    await tester.tap(find.text('쿠폰 저장'));
    await tester.pumpAndSettle();

    expect(find.text('쿠폰 확인을 마쳤어요'), findsOneWidget);
    expect((await repository.listAll()).single.title, '직접 등록 쿠폰');
  });
}

final _item = ScanItem(
  sourceType: ScanSourceType.downloads,
  sourceToken: 'manual-item',
  platformSourceRef: 'fixture://manual-item',
  displayName: 'manual.jpg',
);
