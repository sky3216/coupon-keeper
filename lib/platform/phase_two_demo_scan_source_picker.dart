import '../domain/scan_item.dart';
import '../domain/scan_source.dart';
import 'scan_source_picker.dart';

class PhaseTwoDemoScanSourcePicker implements ScanSourcePicker {
  var _pickCount = 0;

  @override
  Future<ScanSourcePickResult> pick(ScanSourceType sourceType) async {
    _pickCount += 1;
    return ScanSourcePickResult.selected([_demoItem(sourceType)]);
  }

  ScanItem _demoItem(ScanSourceType sourceType) {
    return ScanItem(
      sourceType: sourceType,
      sourceToken: 'phase-two-demo-${sourceType.name}-$_pickCount',
      displayName: sourceType == ScanSourceType.photos
          ? 'selected-photo-$_pickCount.jpg'
          : 'selected-download-$_pickCount.jpg',
      byteSize: 1024,
      modifiedAt: DateTime(2026, 5, 24),
    );
  }
}
