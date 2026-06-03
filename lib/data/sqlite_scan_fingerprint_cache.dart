import 'package:sqflite/sqflite.dart';

import '../domain/scan_item.dart';
import 'coupon_keeper_database.dart';
import 'scan_fingerprint_cache.dart';

class SqliteScanFingerprintCache implements ScanFingerprintCache {
  SqliteScanFingerprintCache(this._database, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final CouponKeeperDatabase _database;
  final DateTime Function() _now;

  @override
  Future<bool> hasSeen(ScanItem item) async {
    final db = await _database.database;
    final rows = await db.query(
      'scan_fingerprints',
      columns: ['fingerprint'],
      where: 'fingerprint = ?',
      whereArgs: [item.fingerprintInput],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  @override
  Future<void> markSeen(ScanItem item) async {
    final db = await _database.database;
    await db.insert('scan_fingerprints', {
      'fingerprint': item.fingerprintInput,
      'seen_at': _now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  @override
  Future<ScanFingerprintBatch> filterUnseen(Iterable<ScanItem> items) async {
    final seenInBatch = <String>{};
    final unseen = <ScanItem>[];
    var duplicateCount = 0;

    for (final item in items) {
      final fingerprint = item.fingerprintInput;
      if (seenInBatch.contains(fingerprint) || await hasSeen(item)) {
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
