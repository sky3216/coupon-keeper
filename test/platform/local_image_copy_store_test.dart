import 'dart:io';

import 'package:coupon_keeper/data/coupon_keeper_database.dart';
import 'package:coupon_keeper/data/sqlite_image_copy_registry.dart';
import 'package:coupon_keeper/platform/local_image_copy_store.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('copies original bytes under generated internal filenames', () async {
    final fixture = await _ImageFixture.create();
    addTearDown(fixture.dispose);
    final source = await fixture.writeSource('coupon-original.jpg', [
      1,
      2,
      3,
      4,
      5,
      255,
    ]);
    final store = fixture.store(ids: ['copy-one']);

    final result = await store.copyIntoAppStorage(
      source.uri.toString(),
      fingerprint: 'sha256:one',
    );
    final copied = File.fromUri(Uri.parse(result.path));

    expect(result.created, isTrue);
    expect(await copied.readAsBytes(), await source.readAsBytes());
    expect(p.basename(copied.path), 'copy-one.image');
    expect(copied.path, isNot(contains('coupon-original')));
    expect(copied.path, isNot(contains(source.path)));
  });

  test('reuses existing copy for the same fingerprint', () async {
    final fixture = await _ImageFixture.create();
    addTearDown(fixture.dispose);
    final source = await fixture.writeSource('coupon.jpg', [10, 20, 30]);
    final store = fixture.store(ids: ['copy-one', 'copy-two']);

    final first = await store.copyIntoAppStorage(
      source.uri.toString(),
      fingerprint: 'sha256:same',
    );
    final second = await store.copyIntoAppStorage(
      source.uri.toString(),
      fingerprint: 'sha256:same',
    );

    expect(first.path, second.path);
    expect(first.created, isTrue);
    expect(second.created, isFalse);
  });

  test('repairs stale registry rows and resolves deletion', () async {
    final fixture = await _ImageFixture.create();
    addTearDown(fixture.dispose);
    final source = await fixture.writeSource('coupon.jpg', [7, 8, 9]);
    final store = fixture.store(ids: ['copy-one', 'copy-two']);

    final first = await store.copyIntoAppStorage(
      source.uri.toString(),
      fingerprint: 'sha256:stale',
    );
    await File.fromUri(Uri.parse(first.path)).delete();

    final repaired = await store.copyIntoAppStorage(
      source.uri.toString(),
      fingerprint: 'sha256:stale',
    );
    expect(repaired.created, isTrue);
    expect(repaired.path, isNot(first.path));

    expect(await store.resolveImagePath(repaired.path), repaired.path);
    await store.deleteCopy(repaired.path);
    expect(await store.resolveImagePath(repaired.path), isNull);
  });
}

class _ImageFixture {
  const _ImageFixture({
    required this.root,
    required this.database,
    required this.registry,
  });

  final Directory root;
  final CouponKeeperDatabase database;
  final SqliteImageCopyRegistry registry;

  static Future<_ImageFixture> create() async {
    final root = await Directory.systemTemp.createTemp('coupon-keeper-copy-');
    final database = CouponKeeperDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: () async => p.join(root.path, 'copy_test.db'),
    );
    final registry = SqliteImageCopyRegistry(database);
    return _ImageFixture(root: root, database: database, registry: registry);
  }

  LocalImageCopyStore store({required List<String> ids}) {
    var index = 0;
    return LocalImageCopyStore(
      registry: registry,
      supportDirectory: () async => Directory(p.join(root.path, 'support')),
      nextId: () => ids[index++],
    );
  }

  Future<File> writeSource(String basename, List<int> bytes) async {
    final file = File(p.join(root.path, basename));
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> dispose() async {
    await database.close();
    await root.delete(recursive: true);
  }
}
