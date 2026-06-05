import 'dart:io';

import 'package:coupon_keeper/data/coupon_keeper_database.dart';
import 'package:coupon_keeper/data/sqlite_pro_entitlement_repository.dart';
import 'package:coupon_keeper/domain/pro_entitlement.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('persists local pro entitlement cache after database reopen', () async {
    final fixture = await _SqliteFixture.create();
    addTearDown(fixture.dispose);
    final repository = SqliteProEntitlementRepository(fixture.database);

    await repository.save(
      ProEntitlement(
        isPro: true,
        source: ProEntitlementSource.purchase,
        updatedAt: DateTime(2026, 6, 20),
      ),
    );
    await fixture.database.close();

    final reopened = CouponKeeperDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: () async => fixture.databasePath,
    );
    addTearDown(reopened.close);
    final saved = await SqliteProEntitlementRepository(reopened).load();

    expect(saved?.isPro, isTrue);
    expect(saved?.source, ProEntitlementSource.purchase);
    expect(saved?.updatedAt, DateTime(2026, 6, 20));
  });
}

class _SqliteFixture {
  const _SqliteFixture({required this.databasePath, required this.database});

  final String databasePath;
  final CouponKeeperDatabase database;

  static Future<_SqliteFixture> create() async {
    final dir = await Directory.systemTemp.createTemp('coupon-keeper-pro-');
    final databasePath = p.join(dir.path, 'pro_test.db');
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
