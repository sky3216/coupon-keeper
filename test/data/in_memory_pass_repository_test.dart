import 'package:coupon_keeper/data/in_memory_pass_repository.dart';
import 'package:coupon_keeper/domain/pass.dart';
import 'package:coupon_keeper/domain/pass_confidence.dart';
import 'package:coupon_keeper/domain/pass_source_metadata.dart';
import 'package:coupon_keeper/platform/fake_image_copy_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InMemoryPassRepository', () {
    test('round-trips every PASS-01 field', () async {
      final repository = InMemoryPassRepository();
      final pass = _pass(id: 'pass-1');

      await repository.save(pass);
      final saved = await repository.getById('pass-1');

      expect(saved, isNotNull);
      expect(saved!.id, pass.id);
      expect(saved.type, pass.type);
      expect(saved.title, pass.title);
      expect(saved.brand, pass.brand);
      expect(saved.estimatedValue, pass.estimatedValue);
      expect(saved.expiry, pass.expiry);
      expect(saved.status, pass.status);
      expect(saved.sourceMetadata.originalUri, pass.sourceMetadata.originalUri);
      expect(saved.sourceMetadata.fingerprint, pass.sourceMetadata.fingerprint);
      expect(saved.imageCopyPath, pass.imageCopyPath);
      expect(saved.ocrText, pass.ocrText);
      expect(saved.confidence.overall, pass.confidence.overall);
    });

    test('active past-expiry pass appears in expired results', () async {
      final repository = InMemoryPassRepository();
      final today = DateTime(2026, 5, 22);
      await repository.save(_pass(id: 'expired', expiry: DateTime(2026, 5, 1)));

      final expired = await repository.listExpired(today);
      final active = await repository.listActive(today);

      expect(expired.map((pass) => pass.id), contains('expired'));
      expect(active.map((pass) => pass.id), isNot(contains('expired')));
    });

    test(
      'used and cleanup candidates are not reclassified as active',
      () async {
        final repository = InMemoryPassRepository();
        final today = DateTime(2026, 5, 22);
        final past = DateTime(2026, 5, 1);

        await repository.save(
          _pass(id: 'used', status: PassStatus.used, expiry: past),
        );
        await repository.save(
          _pass(
            id: 'cleanup',
            status: PassStatus.cleanupCandidate,
            expiry: past,
          ),
        );

        final active = await repository.listActive(today);
        final used = await repository.listUsed();
        final cleanup = await repository.listCleanupCandidates();

        expect(active.map((pass) => pass.id), isNot(contains('used')));
        expect(active.map((pass) => pass.id), isNot(contains('cleanup')));
        expect(used.map((pass) => pass.id), contains('used'));
        expect(cleanup.map((pass) => pass.id), contains('cleanup'));
      },
    );

    test(
      'source unavailable metadata coexists with app image copy path',
      () async {
        final repository = InMemoryPassRepository();
        final store = FakeImageCopyStore();
        final imageCopyPath = await store.copyIntoAppStorage(
          'fixture://downloads/missing-source.jpg',
          id: 'missing-source',
        );
        final pass = _pass(
          id: 'missing-source',
          imageCopyPath: imageCopyPath,
          sourceMetadata: PassSourceMetadata(
            originalUri: 'fixture://downloads/missing-source.jpg',
            platformSourceType: 'download',
            fingerprint: 'sha256-missing-source',
            importedAt: DateTime(2026, 5, 20),
            isAvailable: false,
            missingReason: 'Original file was moved',
          ),
        );

        await repository.save(pass);
        final saved = await repository.getById('missing-source');

        expect(saved!.sourceMetadata.isAvailable, isFalse);
        expect(saved.sourceMetadata.missingReason, 'Original file was moved');
        expect(saved.imageCopyPath, startsWith('app://copies/'));
        expect(
          await store.resolveImagePath(saved.imageCopyPath!),
          imageCopyPath,
        );
      },
    );
  });
}

Pass _pass({
  required String id,
  PassStatus status = PassStatus.active,
  DateTime? expiry,
  String imageCopyPath = 'app://copies/pass.jpg',
  PassSourceMetadata? sourceMetadata,
}) {
  return Pass(
    id: id,
    type: PassType.coupon,
    title: 'Coffee coupon',
    brand: 'Local Cafe',
    estimatedValue: 4500,
    expiry: expiry ?? DateTime(2026, 6, 1),
    status: status,
    sourceMetadata:
        sourceMetadata ??
        PassSourceMetadata(
          originalUri: 'fixture://downloads/$id.jpg',
          platformSourceType: 'download',
          fingerprint: 'sha256-$id',
          importedAt: DateTime(2026, 5, 20),
          isAvailable: true,
        ),
    imageCopyPath: imageCopyPath,
    ocrText: 'Coffee coupon 4500',
    confidence: const PassConfidence(
      expiry: 0.8,
      value: 0.9,
      brand: 0.88,
      barcode: 0.7,
      overall: 0.91,
    ),
    createdAt: DateTime(2026, 5, 20),
    updatedAt: DateTime(2026, 5, 21),
  );
}
