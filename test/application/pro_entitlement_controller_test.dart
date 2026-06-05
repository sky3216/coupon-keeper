import 'package:coupon_keeper/application/pro_entitlement_controller.dart';
import 'package:coupon_keeper/data/in_memory_pass_repository.dart';
import 'package:coupon_keeper/data/in_memory_pro_entitlement_repository.dart';
import 'package:coupon_keeper/domain/pass.dart';
import 'package:coupon_keeper/domain/pass_confidence.dart';
import 'package:coupon_keeper/domain/pass_source_metadata.dart';
import 'package:coupon_keeper/domain/pro_entitlement.dart';
import 'package:coupon_keeper/platform/pro_purchase_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'free user can save up to five active passes but not the sixth',
    () async {
      final repository = InMemoryPassRepository();
      for (var index = 0; index < 5; index += 1) {
        await repository.save(_pass(id: 'pass-$index'));
      }
      final controller = _controller(passRepository: repository);

      await expectLater(
        controller.ensureCanSaveActivePass(),
        throwsA(
          isA<ProGateException>().having(
            (error) => error.context,
            'context',
            ProGateContext.activePassLimit,
          ),
        ),
      );
    },
  );

  test(
    'expired and used passes do not count toward free active limit',
    () async {
      final repository = InMemoryPassRepository();
      for (var index = 0; index < 4; index += 1) {
        await repository.save(_pass(id: 'active-$index'));
      }
      await repository.save(
        _pass(
          id: 'used',
          status: PassStatus.used,
          expiry: DateTime(2026, 1, 1),
        ),
      );
      await repository.save(_pass(id: 'expired', expiry: DateTime(2026, 1, 1)));
      final controller = _controller(passRepository: repository);

      await controller.ensureCanSaveActivePass();
    },
  );

  test(
    'pro entitlement unlocks active limit, cleanup, and custom reminders',
    () async {
      final entitlementRepository = InMemoryProEntitlementRepository();
      await entitlementRepository.save(
        ProEntitlement(
          isPro: true,
          source: ProEntitlementSource.restore,
          updatedAt: DateTime(2026, 6, 1),
        ),
      );
      final controller = _controller(
        entitlementRepository: entitlementRepository,
      );

      await controller.ensureCanSaveActivePass();
      await controller.ensureCleanupCandidateAllowed();
      await controller.ensureCustomReminderAllowed();
    },
  );

  test('purchase and restore cache entitlement locally', () async {
    final entitlementRepository = InMemoryProEntitlementRepository();
    final gateway = _FakeProPurchaseGateway();
    final controller = _controller(
      entitlementRepository: entitlementRepository,
      gateway: gateway,
    );

    final purchased = await controller.purchasePro();
    final restored = await controller.restorePro();

    expect(purchased.isPro, isTrue);
    expect(purchased.source, ProEntitlementSource.purchase);
    expect(restored.isPro, isTrue);
    expect(restored.source, ProEntitlementSource.restore);
    expect((await entitlementRepository.load())?.isPro, isTrue);
  });
}

ProEntitlementController _controller({
  InMemoryPassRepository? passRepository,
  InMemoryProEntitlementRepository? entitlementRepository,
  ProPurchaseGateway? gateway,
}) {
  return ProEntitlementController(
    entitlementRepository:
        entitlementRepository ?? InMemoryProEntitlementRepository(),
    passRepository: passRepository ?? InMemoryPassRepository(),
    purchaseGateway: gateway ?? _FakeProPurchaseGateway(),
    now: () => DateTime(2026, 6, 20),
  );
}

class _FakeProPurchaseGateway implements ProPurchaseGateway {
  @override
  Future<ProPurchaseResult> purchasePro() async {
    return const ProPurchaseResult(
      isPro: true,
      source: ProEntitlementSource.purchase,
    );
  }

  @override
  Future<ProPurchaseResult> restorePro() async {
    return const ProPurchaseResult(
      isPro: true,
      source: ProEntitlementSource.restore,
    );
  }
}

Pass _pass({
  required String id,
  PassStatus status = PassStatus.active,
  DateTime? expiry,
}) {
  final now = DateTime(2026, 6, 1);
  return Pass(
    id: id,
    type: PassType.coupon,
    title: '무료 음료 쿠폰',
    brand: 'Cafe',
    estimatedValue: 4500,
    expiry: expiry ?? DateTime(2026, 6, 30),
    status: status,
    sourceMetadata: PassSourceMetadata(
      originalUri: 'content://selected/$id',
      platformSourceType: 'downloads',
      fingerprint: 'fingerprint-$id',
      importedAt: now,
      isAvailable: true,
    ),
    imageCopyPath: '/app/$id.image',
    ocrText: null,
    confidence: const PassConfidence(
      expiry: 0.9,
      value: 0.9,
      brand: 0.9,
      barcode: 0.1,
      overall: 0.8,
    ),
    createdAt: now,
    updatedAt: now,
  );
}
