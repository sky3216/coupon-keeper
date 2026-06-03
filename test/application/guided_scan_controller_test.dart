import 'dart:async';

import 'package:coupon_keeper/application/guided_scan_controller.dart';
import 'package:coupon_keeper/data/in_memory_scan_fingerprint_cache.dart';
import 'package:coupon_keeper/domain/scan_item.dart';
import 'package:coupon_keeper/domain/scan_source.dart';
import 'package:coupon_keeper/platform/fake_scan_source_picker.dart';
import 'package:coupon_keeper/platform/scan_source_picker.dart';
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

    test(
      'cancels before remaining items and does not mark them scanned',
      () async {
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
      },
    );

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

    test('retry processes failed items only without picking again', () async {
      final successful = _item('successful');
      final failedThenRecovered = _item('failed-then-recovered');
      final cache = InMemoryScanFingerprintCache();
      final picker = FakeScanSourcePicker.downloads([
        successful,
        failedThenRecovered,
      ]);
      final processedTokens = <String>[];
      var failuresLeft = 1;
      final controller = GuidedScanController(
        picker: picker,
        fingerprintCache: cache,
        processItem: (item) async {
          processedTokens.add(item.sourceToken);
          if (item.sourceToken == failedThenRecovered.sourceToken &&
              failuresLeft > 0) {
            failuresLeft -= 1;
            throw StateError('temporary failure');
          }
        },
      );

      await controller.start(ScanSourceType.downloads);

      expect(controller.state.status, GuidedScanStatus.partial);
      expect(controller.state.processedCount, 1);
      expect(controller.state.failedCount, 1);
      expect(await cache.hasSeen(successful), isTrue);
      expect(await cache.hasSeen(failedThenRecovered), isFalse);

      await controller.retryFailed();

      expect(controller.state.status, GuidedScanStatus.completed);
      expect(processedTokens, [
        successful.sourceToken,
        failedThenRecovered.sourceToken,
        failedThenRecovered.sourceToken,
      ]);
      expect(picker.requestedSources, [ScanSourceType.downloads]);
      expect(picker.retryRequests, isEmpty);
      expect(await cache.hasSeen(failedThenRecovered), isTrue);
    });

    test('retry can recover retained source failures', () async {
      final recovered = _item('recovered');
      const failure = RetryableSourceFailure(
        handle: 'folder-child-1',
        displayName: 'coupon.jpg',
      );
      final picker = FakeScanSourcePicker.selectedWithFailures(
        items: const [],
        failures: const [failure],
        retryResult: ScanSourcePickResult.selected([recovered]),
      );
      final cache = InMemoryScanFingerprintCache();
      final processedTokens = <String>[];
      final controller = GuidedScanController(
        picker: picker,
        fingerprintCache: cache,
        processItem: (item) async {
          processedTokens.add(item.sourceToken);
        },
      );

      await controller.start(ScanSourceType.folder);
      await controller.retryFailed();

      expect(controller.state.status, GuidedScanStatus.completed);
      expect(processedTokens, [recovered.sourceToken]);
      expect(picker.requestedSources, [ScanSourceType.folder]);
      expect(picker.retryRequests, [
        ['folder-child-1'],
      ]);
      expect(await cache.hasSeen(recovered), isTrue);
    });

    test('reset and dispose release staged refs and failure handles', () async {
      final item = _item('retained', platformSourceRef: 'file://retained');
      const failure = RetryableSourceFailure(
        handle: 'retry-handle',
        displayName: 'missing.jpg',
      );
      final resetPicker = FakeScanSourcePicker.selectedWithFailures(
        items: [item],
        failures: const [failure],
      );
      final resetController = GuidedScanController(
        picker: resetPicker,
        fingerprintCache: InMemoryScanFingerprintCache(),
        processItem: (_) => throw StateError('keeps retryable'),
      );

      await resetController.start(ScanSourceType.folder);
      resetController.reset();

      expect(resetPicker.releasedItemRefs, ['file://retained']);
      expect(resetPicker.releasedFailureHandles, ['retry-handle']);

      final disposePicker = FakeScanSourcePicker.selectedWithFailures(
        items: [item],
        failures: const [failure],
      );
      final disposeController = GuidedScanController(
        picker: disposePicker,
        fingerprintCache: InMemoryScanFingerprintCache(),
        processItem: (_) => throw StateError('keeps retryable'),
      );

      await disposeController.start(ScanSourceType.folder);
      await disposeController.dispose();

      expect(disposePicker.releasedItemRefs, ['file://retained']);
      expect(disposePicker.releasedFailureHandles, ['retry-handle']);
    });
  });
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
