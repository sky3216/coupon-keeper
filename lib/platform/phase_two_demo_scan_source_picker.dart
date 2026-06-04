import '../domain/scan_item.dart';
import '../domain/scan_source.dart';
import 'scan_source_picker.dart';

class PhaseTwoDemoScanSourcePicker implements ScanSourcePicker {
  const PhaseTwoDemoScanSourcePicker();

  @override
  Future<ScanSourcePickResult> pick(ScanSourceType sourceType) async {
    return ScanSourcePickResult.selected([_demoItem(sourceType)]);
  }

  @override
  Future<ScanSourcePickResult> retryFailures(
    Iterable<RetryableSourceFailure> failures,
  ) async {
    return const ScanSourcePickResult.fileUnavailable();
  }

  @override
  Future<void> release({
    Iterable<ScanItem> items = const [],
    Iterable<RetryableSourceFailure> failures = const [],
  }) async {}

  ScanItem _demoItem(ScanSourceType sourceType) {
    return ScanItem(
      sourceType: sourceType,
      sourceToken: 'phase-two-demo-${sourceType.name}',
      platformSourceRef: 'fixture://phase-two-demo-${sourceType.name}',
      displayName: sourceType == ScanSourceType.photos
          ? 'selected-photo.jpg'
          : sourceType == ScanSourceType.folder
          ? 'selected-folder-image.jpg'
          : 'selected-download.jpg',
      byteSize: 1024,
      modifiedAt: DateTime(2026, 5, 24),
    );
  }
}
