import '../domain/scan_item.dart';

abstract class ScanFingerprintCache {
  Future<bool> hasSeen(ScanItem item);
  Future<void> markSeen(ScanItem item);
  Future<ScanFingerprintBatch> filterUnseen(Iterable<ScanItem> items);
}

class ScanFingerprintBatch {
  ScanFingerprintBatch({
    required Iterable<ScanItem> unseenItems,
    required this.duplicateCount,
  }) : unseenItems = List.unmodifiable(unseenItems);

  final List<ScanItem> unseenItems;
  final int duplicateCount;
}
