import 'dart:io';

import 'package:coupon_keeper/data/coupon_keeper_database.dart';
import 'package:coupon_keeper/data/sqlite_pass_repository.dart';
import 'package:coupon_keeper/domain/pass.dart';
import 'package:coupon_keeper/domain/pass_confidence.dart';
import 'package:coupon_keeper/domain/pass_source_metadata.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('round-trips every PASS-01 field after database reopen', () async {
    final fixture = await _SqliteFixture.create();
    addTearDown(fixture.dispose);
    final repository = SqlitePassRepository(fixture.database);
    final pass = _pass(id: 'pass-1');

    await repository.save(pass);
    await fixture.database.close();

    final reopened = CouponKeeperDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: () async => fixture.databasePath,
    );
    addTearDown(reopened.close);
    final saved = await SqlitePassRepository(reopened).getById('pass-1');

    expect(saved, isNotNull);
    expect(saved!.id, pass.id);
    expect(saved.type, pass.type);
    expect(saved.title, pass.title);
    expect(saved.brand, pass.brand);
    expect(saved.estimatedValue, pass.estimatedValue);
    expect(saved.expiry, pass.expiry);
    expect(saved.status, pass.status);
    expect(saved.sourceMetadata.originalUri, pass.sourceMetadata.originalUri);
    expect(saved.sourceMetadata.platformSourceType, 'downloads');
    expect(saved.sourceMetadata.fingerprint, pass.sourceMetadata.fingerprint);
    expect(saved.sourceMetadata.importedAt, pass.sourceMetadata.importedAt);
    expect(saved.sourceMetadata.isAvailable, isTrue);
    expect(saved.sourceMetadata.missingReason, isNull);
    expect(saved.imageCopyPath, pass.imageCopyPath);
    expect(saved.ocrText, pass.ocrText);
    expect(saved.confidence.expiry, pass.confidence.expiry);
    expect(saved.confidence.value, pass.confidence.value);
    expect(saved.confidence.brand, pass.confidence.brand);
    expect(saved.confidence.barcode, pass.confidence.barcode);
    expect(saved.confidence.overall, pass.confidence.overall);
    expect(saved.createdAt, pass.createdAt);
    expect(saved.updatedAt, pass.updatedAt);
  });

  test('queries stored and effective status with in-memory parity', () async {
    final fixture = await _SqliteFixture.create();
    addTearDown(fixture.dispose);
    final repository = SqlitePassRepository(fixture.database);
    final today = DateTime(2026, 6, 3);

    await repository.save(_pass(id: 'active', expiry: DateTime(2026, 6, 30)));
    await repository.save(_pass(id: 'expired', expiry: DateTime(2026, 5, 1)));
    await repository.save(
      _pass(id: 'used', status: PassStatus.used, expiry: DateTime(2026, 5, 1)),
    );
    await repository.save(
      _pass(id: 'cleanup', status: PassStatus.cleanupCandidate),
    );
    await repository.save(_pass(id: 'review', status: PassStatus.needsReview));

    expect((await repository.listActive(today)).map((pass) => pass.id), [
      'active',
    ]);
    expect((await repository.listExpired(today)).map((pass) => pass.id), [
      'expired',
    ]);
    expect((await repository.listUsed()).map((pass) => pass.id), ['used']);
    expect((await repository.listCleanupCandidates()).map((pass) => pass.id), [
      'cleanup',
    ]);
    expect((await repository.listNeedsReview()).map((pass) => pass.id), [
      'review',
    ]);
  });
}

class _SqliteFixture {
  const _SqliteFixture({required this.databasePath, required this.database});

  final String databasePath;
  final CouponKeeperDatabase database;

  static Future<_SqliteFixture> create() async {
    final dir = await Directory.systemTemp.createTemp('coupon-keeper-db-');
    final databasePath = p.join(dir.path, 'coupon_keeper_test.db');
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

Pass _pass({
  required String id,
  PassStatus status = PassStatus.active,
  DateTime? expiry,
}) {
  return Pass(
    id: id,
    type: PassType.coupon,
    title: 'Coffee coupon $id',
    brand: 'Local Cafe',
    estimatedValue: 4500,
    expiry: expiry ?? DateTime(2026, 6, 30),
    status: status,
    sourceMetadata: PassSourceMetadata(
      originalUri: 'file:///selected/$id.jpg',
      platformSourceType: 'downloads',
      fingerprint: 'downloads:sha256-$id:1024:2026',
      importedAt: DateTime(2026, 6, 1),
      isAvailable: true,
    ),
    imageCopyPath: 'file:///app/coupon-images/$id.image',
    ocrText: 'Coffee coupon $id 4500',
    confidence: const PassConfidence(
      expiry: 0.8,
      value: 0.9,
      brand: 0.88,
      barcode: 0.7,
      overall: 0.91,
    ),
    createdAt: DateTime(2026, 6, 1, 10),
    updatedAt: DateTime(2026, 6, 2, 11),
  );
}
