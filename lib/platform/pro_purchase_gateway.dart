import '../domain/pro_entitlement.dart';

class ProPurchaseResult {
  const ProPurchaseResult({required this.isPro, required this.source});

  final bool isPro;
  final ProEntitlementSource source;
}

abstract class ProPurchaseGateway {
  Future<ProPurchaseResult> purchasePro();
  Future<ProPurchaseResult> restorePro();
}
