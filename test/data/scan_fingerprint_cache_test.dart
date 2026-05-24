import 'package:coupon_keeper/data/in_memory_scan_fingerprint_cache.dart';
import 'package:coupon_keeper/domain/scan_item.dart';
import 'package:coupon_keeper/domain/scan_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InMemoryScanFingerprintCache', () {
    test('reports unseen items and seen items after mark', () async {
      final cache = InMemoryScanFingerprintCache();
      final item = _item(token: 'download-token-1');

      expect(await cache.hasSeen(item), isFalse);

      await cache.markSeen(item);

      expect(await cache.hasSeen(item), isTrue);
    });

    test('treats repeated fingerprint inputs as duplicates', () async {
      final cache = InMemoryScanFingerprintCache();
      final first = _item(token: 'same-token');
      final repeated = _item(token: 'same-token');
      final fresh = _item(token: 'fresh-token');

      await cache.markSeen(first);
      final batch = await cache.filterUnseen([repeated, fresh]);

      expect(batch.duplicateCount, 1);
      expect(batch.unseenItems, [fresh]);
    });

    test('does not conflate distinct source tokens', () async {
      final cache = InMemoryScanFingerprintCache();
      final first = _item(token: 'download-token-1');
      final second = _item(token: 'download-token-2');

      await cache.markSeen(first);
      final batch = await cache.filterUnseen([first, second]);

      expect(batch.duplicateCount, 1);
      expect(batch.unseenItems, [second]);
    });

    test('stores fingerprints only, not source names or OCR text', () async {
      final cache = InMemoryScanFingerprintCache();
      final item = _item(token: 'provider-token-123', displayName: 'coupon.jpg');

      await cache.markSeen(item);

      expect(cache.fingerprints, contains(item.fingerprintInput));
      expect(cache.fingerprints.join(' '), isNot(contains('coupon.jpg')));
      expect(cache.fingerprints.join(' '), isNot(contains('Coffee coupon OCR')));
    });
  });
}

ScanItem _item({
  required String token,
  String displayName = 'selected.jpg',
}) {
  return ScanItem(
    sourceType: ScanSourceType.downloads,
    sourceToken: token,
    displayName: displayName,
    byteSize: 1024,
    modifiedAt: DateTime(2026, 5, 24),
  );
}
