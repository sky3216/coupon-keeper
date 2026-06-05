import '../data/pass_repository.dart';
import '../data/pro_entitlement_repository.dart';
import '../domain/pro_entitlement.dart';
import '../platform/pro_purchase_gateway.dart';

enum ProGateContext {
  activePassLimit,
  cleanupCandidate,
  customReminder,
  unlimitedSave,
}

class ProGateException implements Exception {
  const ProGateException(this.context, this.message);

  final ProGateContext context;
  final String message;
}

class ProEntitlementController {
  ProEntitlementController({
    required this.entitlementRepository,
    required this.passRepository,
    required this.purchaseGateway,
    required this.now,
    this.freeActivePassLimit = 5,
  });

  final ProEntitlementRepository entitlementRepository;
  final PassRepository passRepository;
  final ProPurchaseGateway purchaseGateway;
  final DateTime Function() now;
  final int freeActivePassLimit;

  Future<ProEntitlement> currentEntitlement() async {
    return await entitlementRepository.load() ?? ProEntitlement.free(now());
  }

  Future<void> ensureCanSaveActivePass() async {
    final entitlement = await currentEntitlement();
    if (entitlement.isPro) {
      return;
    }
    final active = await passRepository.listActive(now());
    if (active.length < freeActivePassLimit) {
      return;
    }
    throw const ProGateException(
      ProGateContext.activePassLimit,
      '무료 버전은 활성 쿠폰 5개까지 저장할 수 있어요. Pro로 더 보관할 수 있습니다.',
    );
  }

  Future<void> ensureCleanupCandidateAllowed() async {
    final entitlement = await currentEntitlement();
    if (entitlement.isPro) {
      return;
    }
    throw const ProGateException(
      ProGateContext.cleanupCandidate,
      '정리 후보 관리는 Pro에서 사용할 수 있어요.',
    );
  }

  Future<void> ensureCustomReminderAllowed() async {
    final entitlement = await currentEntitlement();
    if (entitlement.isPro) {
      return;
    }
    throw const ProGateException(
      ProGateContext.customReminder,
      '사용자 지정 알림은 Pro에서 사용할 수 있어요.',
    );
  }

  Future<ProEntitlement> purchasePro() {
    return _applyPurchaseResult(purchaseGateway.purchasePro());
  }

  Future<ProEntitlement> restorePro() {
    return _applyPurchaseResult(purchaseGateway.restorePro());
  }

  Future<ProEntitlement> _applyPurchaseResult(
    Future<ProPurchaseResult> pending,
  ) async {
    final result = await pending;
    final entitlement = ProEntitlement(
      isPro: result.isPro,
      source: result.source,
      updatedAt: now(),
    );
    await entitlementRepository.save(entitlement);
    return entitlement;
  }
}
