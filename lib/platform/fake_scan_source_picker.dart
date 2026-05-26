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

  @override
  Future<ScanSourcePickResult> pick(ScanSourceType sourceType) async {
    requestedSources.add(sourceType);
    return _result;
  }
}
