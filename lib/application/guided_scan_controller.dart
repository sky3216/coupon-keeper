import 'dart:async';

import '../data/scan_fingerprint_cache.dart';
import '../domain/scan_item.dart';
import '../domain/scan_progress.dart';
import '../domain/scan_source.dart';
import '../platform/scan_source_picker.dart';

export '../domain/scan_progress.dart';

typedef ScanItemProcessor = Future<void> Function(ScanItem item);

class GuidedScanController {
  GuidedScanController({
    required this.picker,
    required this.fingerprintCache,
    ScanItemProcessor? processItem,
    this.duplicateOnlyDelay = Duration.zero,
  }) : _processItem = processItem ?? _defaultProcessItem;

  final ScanSourcePicker picker;
  final ScanFingerprintCache fingerprintCache;
  final ScanItemProcessor _processItem;
  final Duration duplicateOnlyDelay;
  final StreamController<GuidedScanState> _states =
      StreamController<GuidedScanState>.broadcast();
  final List<ScanItem> _retainedItems = [];
  final List<ScanItem> _failedItems = [];
  final List<RetryableSourceFailure> _sourceFailures = [];

  GuidedScanState _state = const GuidedScanState.idle();
  var _cancelRequested = false;

  GuidedScanState get state => _state;
  Stream<GuidedScanState> get states => _states.stream;
  bool get canRetryFailed =>
      _failedItems.isNotEmpty || _sourceFailures.isNotEmpty;

  Future<void> start(ScanSourceType sourceType) async {
    _cancelRequested = false;
    _releaseRetainedResources();
    _emit(const GuidedScanState(status: GuidedScanStatus.selecting));

    final pickResult = await picker.pick(sourceType);
    switch (pickResult.status) {
      case ScanSourcePickStatus.cancelled:
        _emit(
          const GuidedScanState(
            status: GuidedScanStatus.cancelled,
            failure: ScanFailure.userCancelled,
          ),
        );
        return;
      case ScanSourcePickStatus.accessDenied:
        _emit(
          const GuidedScanState(
            status: GuidedScanStatus.accessDenied,
            failure: ScanFailure.accessDenied,
          ),
        );
        return;
      case ScanSourcePickStatus.fileUnavailable:
        _emit(
          const GuidedScanState(
            status: GuidedScanStatus.fileUnavailable,
            failure: ScanFailure.fileUnavailable,
          ),
        );
        return;
      case ScanSourcePickStatus.selected:
        _retainedItems.addAll(pickResult.items);
        _sourceFailures.addAll(pickResult.retryableFailures);
        await _processSelected(
          pickResult.items,
          sourceFailureCount: pickResult.retryableFailures.length,
        );
    }
  }

  Future<void> retryFailed() async {
    if (!canRetryFailed) {
      return;
    }
    _cancelRequested = false;
    final itemsToRetry = List<ScanItem>.from(_failedItems);
    final sourceFailuresToRetry = List<RetryableSourceFailure>.from(
      _sourceFailures,
    );
    final baseProcessedCount = _state.processedCount;
    _failedItems.clear();
    _sourceFailures.clear();

    _emit(
      GuidedScanState(
        status: GuidedScanStatus.running,
        totalCount:
            baseProcessedCount +
            itemsToRetry.length +
            sourceFailuresToRetry.length,
        processedCount: baseProcessedCount,
      ),
    );

    final retryResult = sourceFailuresToRetry.isEmpty
        ? ScanSourcePickResult.selected(const [])
        : await picker.retryFailures(sourceFailuresToRetry);
    if (retryResult.status != ScanSourcePickStatus.selected) {
      _failedItems.addAll(itemsToRetry);
      _sourceFailures.addAll(sourceFailuresToRetry);
      _emit(
        _state.copyWith(
          status: GuidedScanStatus.processingFailed,
          failedCount: _failedItems.length + _sourceFailures.length,
          failure: ScanFailure.processingFailed,
        ),
      );
      return;
    }

    _retainedItems.addAll(retryResult.items);
    _sourceFailures.addAll(retryResult.retryableFailures);
    await _processSelected(
      [...itemsToRetry, ...retryResult.items],
      sourceFailureCount: retryResult.retryableFailures.length,
      baseProcessedCount: baseProcessedCount,
    );
  }

  void cancel() {
    _cancelRequested = true;
  }

  void reset() {
    _cancelRequested = false;
    _releaseRetainedResources();
    _emit(const GuidedScanState.idle());
  }

  Future<void> dispose() async {
    _releaseRetainedResources();
    await _states.close();
  }

  Future<void> _processSelected(
    List<ScanItem> selectedItems, {
    int sourceFailureCount = 0,
    int baseProcessedCount = 0,
  }) async {
    if (selectedItems.isEmpty &&
        sourceFailureCount == 0 &&
        baseProcessedCount == 0) {
      _emit(const GuidedScanState(status: GuidedScanStatus.empty));
      return;
    }

    final batch = await fingerprintCache.filterUnseen(selectedItems);
    var processed = 0;
    var failed = 0;
    _emit(
      GuidedScanState(
        status: GuidedScanStatus.running,
        totalCount:
            baseProcessedCount + selectedItems.length + sourceFailureCount,
        processedCount: baseProcessedCount,
        duplicateSkipped: batch.duplicateCount,
      ),
    );

    if (batch.unseenItems.isEmpty &&
        batch.duplicateCount > 0 &&
        duplicateOnlyDelay > Duration.zero) {
      await Future<void>.delayed(duplicateOnlyDelay);
    }

    for (final item in batch.unseenItems) {
      if (_cancelRequested) {
        _emit(
          _state.copyWith(
            status: GuidedScanStatus.cancelled,
            processedCount: baseProcessedCount + processed,
            failedCount: failed,
            failure: ScanFailure.userCancelled,
          ),
        );
        return;
      }

      try {
        await _processItem(item);
      } catch (_) {
        failed += 1;
        _failedItems.add(item);
        _emit(
          _state.copyWith(
            status: GuidedScanStatus.running,
            processedCount: baseProcessedCount + processed,
            failedCount: failed + sourceFailureCount,
          ),
        );
        continue;
      }

      if (_cancelRequested) {
        _emit(
          _state.copyWith(
            status: GuidedScanStatus.cancelled,
            processedCount: baseProcessedCount + processed,
            failedCount: failed,
            failure: ScanFailure.userCancelled,
          ),
        );
        return;
      }

      await fingerprintCache.markSeen(item);
      processed += 1;
      _emit(
        _state.copyWith(
          status: GuidedScanStatus.running,
          processedCount: baseProcessedCount + processed,
          failedCount: failed + sourceFailureCount,
        ),
      );
    }

    final totalFailed = failed + sourceFailureCount;

    if (processed == 0 && totalFailed == 0) {
      _emit(
        _state.copyWith(
          status: GuidedScanStatus.completed,
          processedCount: baseProcessedCount,
          failedCount: failed,
        ),
      );
      return;
    }

    if (totalFailed > 0 && processed == 0 && baseProcessedCount == 0) {
      _emit(
        _state.copyWith(
          status: GuidedScanStatus.processingFailed,
          processedCount: processed,
          failedCount: totalFailed,
          failure: ScanFailure.processingFailed,
        ),
      );
      return;
    }

    if (totalFailed > 0) {
      _emit(
        _state.copyWith(
          status: GuidedScanStatus.partial,
          processedCount: baseProcessedCount + processed,
          failedCount: totalFailed,
          failure: ScanFailure.processingFailed,
        ),
      );
      return;
    }

    _emit(
      _state.copyWith(
        status: GuidedScanStatus.completed,
        processedCount: baseProcessedCount + processed,
        failedCount: failed,
      ),
    );
  }

  void _releaseRetainedResources() {
    if (_retainedItems.isNotEmpty || _sourceFailures.isNotEmpty) {
      unawaited(
        picker.release(items: _retainedItems, failures: _sourceFailures),
      );
    }
    _retainedItems.clear();
    _failedItems.clear();
    _sourceFailures.clear();
  }

  void _emit(GuidedScanState state) {
    _state = state;
    if (!_states.isClosed) {
      _states.add(state);
    }
  }

  static Future<void> _defaultProcessItem(ScanItem item) async {}
}
