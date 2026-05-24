import 'package:coupon_keeper/domain/pass.dart';
import 'package:coupon_keeper/domain/pass_confidence.dart';
import 'package:coupon_keeper/domain/pass_source_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pass.effectiveStatus', () {
    test('active future expiry stays active', () {
      final pass = _pass(expiry: DateTime(2026, 6, 1));

      expect(pass.effectiveStatus(DateTime(2026, 5, 22)), PassStatus.active);
    });

    test('active past expiry becomes expired', () {
      final pass = _pass(expiry: DateTime(2026, 5, 1));

      expect(pass.effectiveStatus(DateTime(2026, 5, 22)), PassStatus.expired);
    });

    test('explicit states are not overwritten by past expiry', () {
      final today = DateTime(2026, 5, 22);
      final expiry = DateTime(2026, 5, 1);

      expect(
        _pass(status: PassStatus.used, expiry: expiry).effectiveStatus(today),
        PassStatus.used,
      );
      expect(
        _pass(
          status: PassStatus.cleanupCandidate,
          expiry: expiry,
        ).effectiveStatus(today),
        PassStatus.cleanupCandidate,
      );
      expect(
        _pass(
          status: PassStatus.needsReview,
          expiry: expiry,
        ).effectiveStatus(today),
        PassStatus.needsReview,
      );
    });

    test('stores pass fields required by PASS-01', () {
      final pass = _pass();

      expect(pass.id, 'pass-1');
      expect(pass.type, PassType.coupon);
      expect(pass.title, 'Coffee coupon');
      expect(pass.brand, 'Local Cafe');
      expect(pass.estimatedValue, 4500);
      expect(pass.expiry, DateTime(2026, 6, 1));
      expect(pass.status, PassStatus.active);
      expect(pass.sourceMetadata.originalUri, 'fixture://downloads/coupon.jpg');
      expect(pass.imageCopyPath, 'app://copies/pass-1.jpg');
      expect(pass.ocrText, 'Coffee coupon 4500');
      expect(pass.confidence.overall, 0.91);
      expect(pass.createdAt, DateTime(2026, 5, 20));
      expect(pass.updatedAt, DateTime(2026, 5, 21));
    });
  });
}

Pass _pass({PassStatus status = PassStatus.active, DateTime? expiry}) {
  return Pass(
    id: 'pass-1',
    type: PassType.coupon,
    title: 'Coffee coupon',
    brand: 'Local Cafe',
    estimatedValue: 4500,
    expiry: expiry ?? DateTime(2026, 6, 1),
    status: status,
    sourceMetadata: PassSourceMetadata(
      originalUri: 'fixture://downloads/coupon.jpg',
      platformSourceType: 'download',
      fingerprint: 'sha256-fixture',
      importedAt: DateTime(2026, 5, 20),
      isAvailable: true,
    ),
    imageCopyPath: 'app://copies/pass-1.jpg',
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
