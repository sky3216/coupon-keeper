import '../domain/scan_item.dart';
import 'scan_fingerprint_cache.dart';

class InMemoryScanFingerprintCache implements ScanFingerprintCache {
  final Set<String> _fingerprints = {};

  Set<String> get fingerprints => Set.unmodifiable(_fingerprints);

  @override
  Future<bool> hasSeen(ScanItem item) async {
    return _fingerprints.contains(item.fingerprintInput);
  }

  @override
  Future<void> markSeen(ScanItem item) async {
    _fingerprints.add(item.fingerprintInput);
  }

  @override
  Future<ScanFingerprintBatch> filterUnseen(Iterable<ScanItem> items) async {
    final seenInBatch = <String>{};
    final unseen = <ScanItem>[];
    var duplicateCount = 0;

    for (final item in items) {
      final fingerprint = item.fingerprintInput;
      if (_fingerprints.contains(fingerprint) ||
          seenInBatch.contains(fingerprint)) {
        duplicateCount += 1;
        continue;
      }

      seenInBatch.add(fingerprint);
      unseen.add(item);
    }

    return ScanFingerprintBatch(
      unseenItems: unseen,
      duplicateCount: duplicateCount,
    );
  }
}
