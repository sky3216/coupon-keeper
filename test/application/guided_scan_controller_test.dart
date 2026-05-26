import 'dart:async';

import 'package:coupon_keeper/application/guided_scan_controller.dart';
import 'package:coupon_keeper/data/in_memory_scan_fingerprint_cache.dart';
import 'package:coupon_keeper/domain/scan_item.dart';
import 'package:coupon_keeper/domain/scan_source.dart';
import 'package:coupon_keeper/platform/fake_scan_source_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GuidedScanController', () {
    test('reports progress and marks successfully processed items', () async {
      final item = _item('photo-1', sourceType: ScanSourceType.photos);
      final cache = InMemoryScanFingerprintCache();
      final controller = GuidedScanController(
        picker: FakeScanSourcePicker.photos([item]),
        fingerprintCache: cache,
      );

      await controller.start(ScanSourceType.photos);

      expect(controller.state.status, GuidedScanStatus.completed);
      expect(controller.state.processedCount, 1);
      expect(controller.state.totalCount, 1);
      expect(controller.state.duplicateSkipped, 0);
      expect(await cache.hasSeen(item), isTrue);
    });

    test('skips cached duplicates and summarizes the skipped count', () async {
      final duplicate = _item('download-1');
      final fresh = _item('download-2');
      final cache = InMemoryScanFingerprintCache();
      await cache.markSeen(duplicate);
      final controller = GuidedScanController(
        picker: FakeScanSourcePicker.downloads([duplicate, fresh]),
        fingerprintCache: cache,
      );

      await controller.start(ScanSourceType.downloads);

      expect(controller.state.status, GuidedScanStatus.completed);
      expect(controller.state.processedCount, 1);
      expect(controller.state.totalCount, 2);
      expect(controller.state.duplicateSkipped, 1);
      expect(await cache.hasSeen(fresh), isTrue);
    });

    test('cancels before remaining items and does not mark them scanned', () async {
      final first = _item('first');
      final second = _item('second');
      final secondGate = Completer<void>();
      final cache = InMemoryScanFingerprintCache();
      late GuidedScanController controller;
      controller = GuidedScanController(
        picker: FakeScanSourcePicker.downloads([first, second]),
        fingerprintCache: cache,
        processItem: (item) async {
          if (item.sourceToken == 'second') {
            controller.cancel();
            await secondGate.future;
          }
        },
      );

      final scan = controller.start(ScanSourceType.downloads);
      await Future<void>.delayed(Duration.zero);
      secondGate.complete();
      await scan;

      expect(controller.state.status, GuidedScanStatus.cancelled);
      expect(controller.state.processedCount, 1);
      expect(await cache.hasSeen(first), isTrue);
      expect(await cache.hasSeen(second), isFalse);
    });

    test('separates picker cancellation and access failures', () async {
      final cancelled = GuidedScanController(
        picker: FakeScanSourcePicker.cancelled(),
        fingerprintCache: InMemoryScanFingerprintCache(),
      );
      final denied = GuidedScanController(
        picker: FakeScanSourcePicker.accessDenied(),
        fingerprintCache: InMemoryScanFingerprintCache(),
      );
      final unavailable = GuidedScanController(
        picker: FakeScanSourcePicker.fileUnavailable(),
        fingerprintCache: InMemoryScanFingerprintCache(),
      );

      await cancelled.start(ScanSourceType.photos);
      await denied.start(ScanSourceType.photos);
      await unavailable.start(ScanSourceType.downloads);

      expect(cancelled.state.status, GuidedScanStatus.cancelled);
      expect(denied.state.status, GuidedScanStatus.accessDenied);
      expect(unavailable.state.status, GuidedScanStatus.fileUnavailable);
    });

    test('reports processing failures without marking failed items', () async {
      final item = _item('bad-file');
      final cache = InMemoryScanFingerprintCache();
      final controller = GuidedScanController(
        picker: FakeScanSourcePicker.downloads([item]),
        fingerprintCache: cache,
        processItem: (_) => throw StateError('cannot process'),
      );

      await controller.start(ScanSourceType.downloads);

      expect(controller.state.status, GuidedScanStatus.processingFailed);
      expect(controller.state.failedCount, 1);
      expect(await cache.hasSeen(item), isFalse);
    });
  });
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
