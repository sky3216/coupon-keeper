import '../domain/pro_entitlement.dart';

abstract class ProEntitlementRepository {
  Future<ProEntitlement?> load();
  Future<void> save(ProEntitlement entitlement);
}
