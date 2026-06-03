import 'package:sqflite/sqflite.dart';

import 'coupon_keeper_database.dart';

class ImageCopyRegistration {
  const ImageCopyRegistration({
    required this.fingerprint,
    required this.path,
    required this.createdAt,
  });

  final String fingerprint;
  final String path;
  final DateTime createdAt;
}

class SqliteImageCopyRegistry {
  SqliteImageCopyRegistry(this._database, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final CouponKeeperDatabase _database;
  final DateTime Function() _now;

  Future<ImageCopyRegistration?> findByFingerprint(String fingerprint) async {
    final db = await _database.database;
    final rows = await db.query(
      'image_copies',
      where: 'fingerprint = ?',
      whereArgs: [fingerprint],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _fromRow(rows.single);
  }

  Future<void> save({required String fingerprint, required String path}) async {
    final db = await _database.database;
    await db.insert('image_copies', {
      'fingerprint': fingerprint,
      'path': path,
      'created_at': _now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteByPath(String path) async {
    final db = await _database.database;
    await db.delete('image_copies', where: 'path = ?', whereArgs: [path]);
  }

  Future<void> deleteByFingerprint(String fingerprint) async {
    final db = await _database.database;
    await db.delete(
      'image_copies',
      where: 'fingerprint = ?',
      whereArgs: [fingerprint],
    );
  }

  ImageCopyRegistration _fromRow(Map<String, Object?> row) {
    return ImageCopyRegistration(
      fingerprint: row['fingerprint']! as String,
      path: row['path']! as String,
      createdAt: DateTime.parse(row['created_at']! as String),
    );
  }
}
