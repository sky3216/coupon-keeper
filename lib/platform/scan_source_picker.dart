import '../domain/scan_item.dart';
import '../domain/scan_source.dart';

abstract class ScanSourcePicker {
  Future<ScanSourcePickResult> pick(ScanSourceType sourceType);
}

enum ScanSourcePickStatus {
  selected,
  cancelled,
  accessDenied,
  fileUnavailable,
}

class ScanSourcePickResult {
  ScanSourcePickResult.selected(Iterable<ScanItem> items)
    : status = ScanSourcePickStatus.selected,
      items = List.unmodifiable(items);

  const ScanSourcePickResult.cancelled()
    : status = ScanSourcePickStatus.cancelled,
      items = const [];

  const ScanSourcePickResult.accessDenied()
    : status = ScanSourcePickStatus.accessDenied,
      items = const [];

  const ScanSourcePickResult.fileUnavailable()
    : status = ScanSourcePickStatus.fileUnavailable,
      items = const [];

  final ScanSourcePickStatus status;
  final List<ScanItem> items;
}
