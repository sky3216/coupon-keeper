import '../domain/scan_item.dart';
import '../domain/scan_source.dart';
import 'scan_source_picker.dart';

class FakeScanSourcePicker implements ScanSourcePicker {
  FakeScanSourcePicker._(this._result, {ScanSourcePickResult? retryResult})
    : _retryResult = retryResult ?? _result;

  factory FakeScanSourcePicker.photos(
    Iterable<ScanItem> items, {
    ScanSourcePickResult? retryResult,
  }) {
    return FakeScanSourcePicker._(
      ScanSourcePickResult.selected(items),
      retryResult: retryResult,
    );
  }

  factory FakeScanSourcePicker.downloads(
    Iterable<ScanItem> items, {
    ScanSourcePickResult? retryResult,
  }) {
    return FakeScanSourcePicker._(
      ScanSourcePickResult.selected(items),
      retryResult: retryResult,
    );
  }

  factory FakeScanSourcePicker.folder(
    Iterable<ScanItem> items, {
    ScanSourcePickResult? retryResult,
  }) {
    return FakeScanSourcePicker._(
      ScanSourcePickResult.selected(items),
      retryResult: retryResult,
    );
  }

  factory FakeScanSourcePicker.selectedWithFailures({
    required Iterable<ScanItem> items,
    required Iterable<RetryableSourceFailure> failures,
    ScanSourcePickResult? retryResult,
  }) {
    return FakeScanSourcePicker._(
      ScanSourcePickResult.selected(items, retryableFailures: failures),
      retryResult: retryResult,
    );
  }

  factory FakeScanSourcePicker.cancelled() {
    return FakeScanSourcePicker._(const ScanSourcePickResult.cancelled());
  }

  factory FakeScanSourcePicker.accessDenied() {
    return FakeScanSourcePicker._(const ScanSourcePickResult.accessDenied());
  }

  factory FakeScanSourcePicker.fileUnavailable() {
    return FakeScanSourcePicker._(const ScanSourcePickResult.fileUnavailable());
  }

  final ScanSourcePickResult _result;
  final ScanSourcePickResult _retryResult;
  final List<ScanSourceType> requestedSources = [];
  final List<List<String>> retryRequests = [];
  final List<String> releasedItemRefs = [];
  final List<String> releasedFailureHandles = [];

  @override
  Future<ScanSourcePickResult> pick(ScanSourceType sourceType) async {
    requestedSources.add(sourceType);
    return _result;
  }

  @override
  Future<ScanSourcePickResult> retryFailures(
    Iterable<RetryableSourceFailure> failures,
  ) async {
    retryRequests.add(failures.map((failure) => failure.handle).toList());
    return _retryResult;
  }

  @override
  Future<void> release({
    Iterable<ScanItem> items = const [],
    Iterable<RetryableSourceFailure> failures = const [],
  }) async {
    releasedItemRefs.addAll(items.map((item) => item.platformSourceRef ?? ''));
    releasedFailureHandles.addAll(failures.map((failure) => failure.handle));
  }
}
