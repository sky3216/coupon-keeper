enum ProEntitlementSource { localCache, purchase, restore }

class ProEntitlement {
  const ProEntitlement({
    required this.isPro,
    required this.source,
    required this.updatedAt,
  });

  final bool isPro;
  final ProEntitlementSource source;
  final DateTime updatedAt;

  static ProEntitlement free(DateTime now) {
    return ProEntitlement(
      isPro: false,
      source: ProEntitlementSource.localCache,
      updatedAt: now,
    );
  }
}
