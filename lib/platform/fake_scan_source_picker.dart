import '../domain/scan_item.dart';
import '../domain/scan_source.dart';
import 'scan_source_picker.dart';

class FakeScanSourcePicker implements ScanSourcePicker {
  FakeScanSourcePicker._(this._result);

  factory FakeScanSourcePicker.photos(Iterable<ScanItem> items) {
    return FakeScanSourcePicker._(ScanSourcePickResult.selected(items));
  }

  factory FakeScanSourcePicker.downloads(Iterable<ScanItem> items) {
    return FakeScanSourcePicker._(ScanSourcePickResult.selected(items));
  }

  factory FakeScanSourcePicker.folder(Iterable<ScanItem> items) {
    return FakeScanSourcePicker._(ScanSourcePickResult.selected(items));
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
    return _result;
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
