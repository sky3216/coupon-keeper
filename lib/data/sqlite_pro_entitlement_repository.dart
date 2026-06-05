import 'package:sqflite/sqflite.dart';

import '../domain/pro_entitlement.dart';
import 'coupon_keeper_database.dart';
import 'pro_entitlement_repository.dart';

class SqliteProEntitlementRepository implements ProEntitlementRepository {
  SqliteProEntitlementRepository(this._database);

  final CouponKeeperDatabase _database;

  @override
  Future<ProEntitlement?> load() async {
    final db = await _database.database;
    final rows = await db.query('pro_entitlement', limit: 1);
    if (rows.isEmpty) {
      return null;
    }
    final row = rows.single;
    return ProEntitlement(
      isPro: (row['is_pro']! as int) == 1,
      source: ProEntitlementSource.values.byName(row['source']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
    );
  }

  @override
  Future<void> save(ProEntitlement entitlement) async {
    final db = await _database.database;
    await db.insert('pro_entitlement', {
      'id': 1,
      'is_pro': entitlement.isPro ? 1 : 0,
      'source': entitlement.source.name,
      'updated_at': entitlement.updatedAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
