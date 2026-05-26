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
  }) : _processItem = processItem ?? _defaultProcessItem;

  final ScanSourcePicker picker;
  final ScanFingerprintCache fingerprintCache;
  final ScanItemProcessor _processItem;
  final StreamController<GuidedScanState> _states =
      StreamController<GuidedScanState>.broadcast();

  GuidedScanState _state = const GuidedScanState.idle();
  var _cancelRequested = false;

  GuidedScanState get state => _state;
  Stream<GuidedScanState> get states => _states.stream;

  Future<void> start(ScanSourceType sourceType) async {
    _cancelRequested = false;
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
        await _processSelected(pickResult.items);
    }
  }

  void cancel() {
    _cancelRequested = true;
  }

  void reset() {
    _cancelRequested = false;
    _emit(const GuidedScanState.idle());
  }

  Future<void> dispose() async {
    await _states.close();
  }

  Future<void> _processSelected(List<ScanItem> selectedItems) async {
    if (selectedItems.isEmpty) {
      _emit(const GuidedScanState(status: GuidedScanStatus.empty));
      return;
    }

    final batch = await fingerprintCache.filterUnseen(selectedItems);
    var processed = 0;
    var failed = 0;
    _emit(
      GuidedScanState(
        status: GuidedScanStatus.running,
        totalCount: selectedItems.length,
        duplicateSkipped: batch.duplicateCount,
      ),
    );

    for (final item in batch.unseenItems) {
      if (_cancelRequested) {
        _emit(
          _state.copyWith(
            status: GuidedScanStatus.cancelled,
            processedCount: processed,
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
        _emit(
          _state.copyWith(
            status: GuidedScanStatus.running,
            processedCount: processed,
            failedCount: failed,
          ),
        );
        continue;
      }

      if (_cancelRequested) {
        _emit(
          _state.copyWith(
            status: GuidedScanStatus.cancelled,
            processedCount: processed,
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
          processedCount: processed,
          failedCount: failed,
        ),
      );
    }

    if (processed == 0 && failed == 0) {
      _emit(
        _state.copyWith(
          status: GuidedScanStatus.completed,
          processedCount: processed,
          failedCount: failed,
        ),
      );
      return;
    }

    if (failed > 0 && processed == 0) {
      _emit(
        _state.copyWith(
          status: GuidedScanStatus.processingFailed,
          processedCount: processed,
          failedCount: failed,
          failure: ScanFailure.processingFailed,
        ),
      );
      return;
    }

    if (failed > 0) {
      _emit(
        _state.copyWith(
          status: GuidedScanStatus.partial,
          processedCount: processed,
          failedCount: failed,
          failure: ScanFailure.processingFailed,
        ),
      );
      return;
    }

    _emit(
      _state.copyWith(
        status: GuidedScanStatus.completed,
        processedCount: processed,
        failedCount: failed,
      ),
    );
  }

  void _emit(GuidedScanState state) {
    _state = state;
    if (!_states.isClosed) {
      _states.add(state);
    }
  }

  static Future<void> _defaultProcessItem(ScanItem item) async {}
}
