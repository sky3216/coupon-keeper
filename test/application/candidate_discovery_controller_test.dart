import 'package:coupon_keeper/application/candidate_discovery_controller.dart';
import 'package:coupon_keeper/application/guided_scan_controller.dart';
import 'package:coupon_keeper/application/pass_candidate_parser.dart';
import 'package:coupon_keeper/data/in_memory_pass_repository.dart';
import 'package:coupon_keeper/data/in_memory_scan_fingerprint_cache.dart';
import 'package:coupon_keeper/data/pass_repository.dart';
import 'package:coupon_keeper/domain/ocr_text.dart';
import 'package:coupon_keeper/domain/pass.dart';
import 'package:coupon_keeper/domain/scan_item.dart';
import 'package:coupon_keeper/domain/scan_source.dart';
import 'package:coupon_keeper/platform/fake_image_copy_store.dart';
import 'package:coupon_keeper/platform/fake_ocr_text_recognizer.dart';
import 'package:coupon_keeper/platform/fake_scan_source_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('discovery accumulates candidates without saving passes', () async {
    final fixture = _fixture(_ocr(['무료 음료 쿠폰', '2026.06.30', '4,500원']));

    await fixture.controller.processItem(_item);
    fixture.controller.finishDiscovery();

    expect(fixture.controller.status, CandidateDiscoveryStatus.reportReady);
    expect(fixture.controller.candidates, hasLength(1));
    expect(fixture.controller.report.candidateCount, 1);
    expect(fixture.controller.report.protectedValue, 4500);
    expect(await fixture.repository.listAll(), isEmpty);
  });

  test('empty OCR reaches calm no-candidate state', () async {
    final fixture = _fixture(const OcrTextResult.empty());

    await fixture.controller.processItem(_item);
    fixture.controller.finishDiscovery();

    expect(fixture.controller.status, CandidateDiscoveryStatus.noCandidates);
    expect(await fixture.repository.listAll(), isEmpty);
  });

  test(
    'OCR failure stays retryable through guided scan fingerprint cache',
    () async {
      final cache = InMemoryScanFingerprintCache();
      final discovery = CandidateDiscoveryController(
        recognizer: FakeOcrTextRecognizer.failure(),
        parser: const PassCandidateParser(),
        imageCopyStore: FakeImageCopyStore(),
        passRepository: InMemoryPassRepository(),
        now: () => DateTime(2026, 5, 31),
        nextId: () => 'pass-1',
      );
      final guided = GuidedScanController(
        picker: FakeScanSourcePicker.downloads([_item]),
        fingerprintCache: cache,
        processItem: discovery.processItem,
      );

      await guided.start(ScanSourceType.downloads);

      expect(guided.state.status, GuidedScanStatus.processingFailed);
      expect(await cache.hasSeen(_item), isFalse);
    },
  );

  test('explicit candidate save copies image and writes active pass', () async {
    final fixture = _fixture(_ocr(['무료 음료 쿠폰', '2026.06.30', '4,500원']));
    await fixture.controller.processItem(_item);
    fixture.controller.finishDiscovery();
    fixture.controller.beginReview();

    await expectLater(
      fixture.controller.saveCurrentCandidate(),
      throwsA(isA<StateError>()),
    );
    fixture.controller.updateCurrentCandidate(
      confirmedExpiry: DateTime(2026, 6, 30),
    );
    await fixture.controller.saveCurrentCandidate();

    final passes = await fixture.repository.listAll();
    expect(passes, hasLength(1));
    expect(passes.single.status.name, 'active');
    expect(passes.single.ocrText, contains('무료 음료 쿠폰'));
    expect(passes.single.sourceMetadata.fingerprint, _item.fingerprintInput);
    expect(fixture.imageCopyStore.copies.values, ['content://selected/coupon']);
    expect(fixture.controller.status, CandidateDiscoveryStatus.completed);
  });

  test('reject advances without repository or image copy write', () async {
    final fixture = _fixture(_ocr(['무료 음료 쿠폰', '2026.06.30']));
    await fixture.controller.processItem(_item);
    fixture.controller.finishDiscovery();
    fixture.controller.beginReview();

    fixture.controller.rejectCurrentCandidate();

    expect(await fixture.repository.listAll(), isEmpty);
    expect(fixture.imageCopyStore.copies, isEmpty);
    expect(fixture.controller.rejectedCount, 1);
    expect(fixture.controller.status, CandidateDiscoveryStatus.completed);
  });

  test(
    'copy failure leaves candidate retryable and repository empty',
    () async {
      final fixture = _fixture(_ocr(['무료 음료 쿠폰', '2026.06.30']));
      fixture.imageCopyStore.copyError = 'copy failed';
      await fixture.controller.processItem(_item);
      fixture.controller.finishDiscovery();
      fixture.controller.beginReview();
      fixture.controller.updateCurrentCandidate(
        confirmedExpiry: DateTime(2026, 6, 30),
      );

      await expectLater(
        fixture.controller.saveCurrentCandidate(),
        throwsA(isA<StateError>()),
      );

      expect(await fixture.repository.listAll(), isEmpty);
      expect(fixture.controller.savedCount, 0);
      expect(fixture.controller.status, CandidateDiscoveryStatus.reviewing);
      expect(fixture.controller.currentCandidate, isNotNull);
    },
  );

  test(
    'repository failure removes a newly created copy and keeps review active',
    () async {
      final repository = _FailingPassRepository();
      final imageCopyStore = FakeImageCopyStore();
      final controller = _controller(
        _ocr(['무료 음료 쿠폰', '2026.06.30']),
        repository: repository,
        imageCopyStore: imageCopyStore,
      );
      await controller.processItem(_item);
      controller.finishDiscovery();
      controller.beginReview();
      controller.updateCurrentCandidate(confirmedExpiry: DateTime(2026, 6, 30));

      await expectLater(
        controller.saveCurrentCandidate(),
        throwsA(isA<StateError>()),
      );

      expect(imageCopyStore.copies, isEmpty);
      expect(controller.savedCount, 0);
      expect(controller.status, CandidateDiscoveryStatus.reviewing);
    },
  );

  test('repository failure preserves a reused copy', () async {
    final repository = _FailingPassRepository();
    final imageCopyStore = FakeImageCopyStore();
    final existing = await imageCopyStore.copyIntoAppStorage(
      'content://selected/coupon',
      fingerprint: _item.fingerprintInput,
      id: 'existing-copy',
    );
    final controller = _controller(
      _ocr(['무료 음료 쿠폰', '2026.06.30']),
      repository: repository,
      imageCopyStore: imageCopyStore,
    );
    await controller.processItem(_item);
    controller.finishDiscovery();
    controller.beginReview();
    controller.updateCurrentCandidate(confirmedExpiry: DateTime(2026, 6, 30));

    await expectLater(
      controller.saveCurrentCandidate(),
      throwsA(isA<StateError>()),
    );

    expect(imageCopyStore.copies.keys, [existing.path]);
    expect(controller.status, CandidateDiscoveryStatus.reviewing);
  });

  test(
    'manual registration keeps selected image context and required gate',
    () async {
      final fixture = _fixture(const OcrTextResult.empty());
      await fixture.controller.processItem(_item);
      fixture.controller.finishDiscovery();
      fixture.controller.beginManualRegistration();

      expect(
        () => fixture.controller.saveManualRegistration(
          title: '',
          brand: null,
          expiry: null,
        ),
        throwsA(isA<StateError>()),
      );
      await fixture.controller.saveManualRegistration(
        title: '직접 등록 쿠폰',
        brand: null,
        expiry: DateTime(2026, 7, 1),
      );

      final passes = await fixture.repository.listAll();
      expect(passes.single.title, '직접 등록 쿠폰');
      expect(passes.single.ocrText, isNull);
      expect(fixture.controller.status, CandidateDiscoveryStatus.completed);
    },
  );

  test(
    'manual registration from review handles the current candidate',
    () async {
      final fixture = _fixture(_ocr(['무료 음료 쿠폰', '2026.06.30']));
      await fixture.controller.processItem(_item);
      fixture.controller.finishDiscovery();
      fixture.controller.beginReview();
      fixture.controller.beginManualRegistration();

      await fixture.controller.saveManualRegistration(
        title: '직접 보정한 쿠폰',
        brand: null,
        expiry: DateTime(2026, 6, 30),
      );

      expect(fixture.controller.status, CandidateDiscoveryStatus.completed);
      expect(fixture.controller.currentCandidate, isNull);
      expect(await fixture.repository.listAll(), hasLength(1));
    },
  );
}

_Fixture _fixture(OcrTextResult result) {
  final repository = InMemoryPassRepository();
  final imageCopyStore = FakeImageCopyStore();
  return _Fixture(
    repository: repository,
    imageCopyStore: imageCopyStore,
    controller: _controller(
      result,
      repository: repository,
      imageCopyStore: imageCopyStore,
    ),
  );
}

CandidateDiscoveryController _controller(
  OcrTextResult result, {
  required PassRepository repository,
  required FakeImageCopyStore imageCopyStore,
}) {
  return CandidateDiscoveryController(
    recognizer: FakeOcrTextRecognizer.success(result),
    parser: const PassCandidateParser(),
    imageCopyStore: imageCopyStore,
    passRepository: repository,
    now: () => DateTime(2026, 5, 31),
    nextId: () => 'pass-1',
  );
}

class _Fixture {
  const _Fixture({
    required this.controller,
    required this.repository,
    required this.imageCopyStore,
  });

  final CandidateDiscoveryController controller;
  final InMemoryPassRepository repository;
  final FakeImageCopyStore imageCopyStore;
}

final _item = ScanItem(
  sourceType: ScanSourceType.downloads,
  sourceToken: 'stable-token',
  platformSourceRef: 'content://selected/coupon',
  displayName: 'coupon.jpg',
);

class _FailingPassRepository extends InMemoryPassRepository {
  @override
  Future<void> save(Pass pass) async {
    throw StateError('repository failed');
  }
}

OcrTextResult _ocr(List<String> textLines) {
  final lines = textLines
      .map(
        (text) => OcrTextLine(
          text: text,
          bounds: const OcrBounds(left: 0, top: 0, width: 1, height: 0.1),
          confidence: 0.9,
        ),
      )
      .toList();
  return OcrTextResult(
    fullText: textLines.join('\n'),
    blocks: [
      OcrTextBlock(
        text: textLines.join('\n'),
        bounds: const OcrBounds(left: 0, top: 0, width: 1, height: 1),
        lines: lines,
        confidence: 0.9,
      ),
    ],
  );
}
