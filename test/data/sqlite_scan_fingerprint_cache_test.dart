import 'dart:io';

import 'package:coupon_keeper/data/coupon_keeper_database.dart';
import 'package:coupon_keeper/data/sqlite_scan_fingerprint_cache.dart';
import 'package:coupon_keeper/domain/scan_item.dart';
import 'package:coupon_keeper/domain/scan_source.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('persists seen fingerprints after database reopen', () async {
    final fixture = await _SqliteFixture.create();
    addTearDown(fixture.dispose);
    final first = SqliteScanFingerprintCache(fixture.database);
    final item = _item('persisted');

    await first.markSeen(item);
    await fixture.database.close();

    final reopened = CouponKeeperDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: () async => fixture.databasePath,
    );
    addTearDown(reopened.close);

    expect(await SqliteScanFingerprintCache(reopened).hasSeen(item), isTrue);
  });

  test('filters persisted duplicates and same-batch duplicates', () async {
    final fixture = await _SqliteFixture.create();
    addTearDown(fixture.dispose);
    final cache = SqliteScanFingerprintCache(fixture.database);
    final persisted = _item('persisted');
    final fresh = _item('fresh');
    final repeated = _item('fresh');

    await cache.markSeen(persisted);
    final batch = await cache.filterUnseen([persisted, fresh, repeated]);

    expect(batch.unseenItems.map((item) => item.sourceToken), ['fresh']);
    expect(batch.duplicateCount, 2);
  });
}

class _SqliteFixture {
  const _SqliteFixture({required this.databasePath, required this.database});

  final String databasePath;
  final CouponKeeperDatabase database;

  static Future<_SqliteFixture> create() async {
    final dir = await Directory.systemTemp.createTemp('coupon-keeper-fp-');
    final databasePath = p.join(dir.path, 'fingerprint_test.db');
    final database = CouponKeeperDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: () async => databasePath,
    );
    return _SqliteFixture(databasePath: databasePath, database: database);
  }

  Future<void> dispose() async {
    await database.close();
    await Directory(p.dirname(databasePath)).delete(recursive: true);
  }
}

ScanItem _item(String token) {
  return ScanItem(
    sourceType: ScanSourceType.downloads,
    sourceToken: token,
    platformSourceRef: 'file:///selected/$token.jpg',
    displayName: '$token.jpg',
    byteSize: 1024,
    modifiedAt: DateTime(2026, 6, 1),
  );
}
