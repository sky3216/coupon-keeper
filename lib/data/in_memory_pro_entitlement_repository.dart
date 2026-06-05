import '../domain/pro_entitlement.dart';
import 'pro_entitlement_repository.dart';

class InMemoryProEntitlementRepository implements ProEntitlementRepository {
  ProEntitlement? _entitlement;

  @override
  Future<ProEntitlement?> load() async => _entitlement;

  @override
  Future<void> save(ProEntitlement entitlement) async {
    _entitlement = entitlement;
  }
}
