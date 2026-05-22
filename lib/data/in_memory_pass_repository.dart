import '../domain/pass.dart';
import 'pass_repository.dart';

class InMemoryPassRepository implements PassRepository {
  final Map<String, Pass> _passes = {};

  @override
  Future<void> save(Pass pass) async {
    _passes[pass.id] = pass;
  }

  @override
  Future<void> update(Pass pass) async {
    _passes[pass.id] = pass;
  }

  @override
  Future<void> deleteById(String id) async {
    _passes.remove(id);
  }

  @override
  Future<Pass?> getById(String id) async {
    return _passes[id];
  }

  @override
  Future<List<Pass>> listAll() async {
    return _sorted(_passes.values);
  }

  @override
  Future<List<Pass>> listByStoredStatus(PassStatus status) async {
    return _sorted(_passes.values.where((pass) => pass.status == status));
  }

  @override
  Future<List<Pass>> listByEffectiveStatus(
    PassStatus status,
    DateTime today,
  ) async {
    return _sorted(
      _passes.values.where((pass) => pass.effectiveStatus(today) == status),
    );
  }

  @override
  Future<List<Pass>> listActive(DateTime today) {
    return listByEffectiveStatus(PassStatus.active, today);
  }

  @override
  Future<List<Pass>> listUsed() {
    return listByStoredStatus(PassStatus.used);
  }

  @override
  Future<List<Pass>> listExpired(DateTime today) {
    return listByEffectiveStatus(PassStatus.expired, today);
  }

  @override
  Future<List<Pass>> listCleanupCandidates() {
    return listByStoredStatus(PassStatus.cleanupCandidate);
  }

  @override
  Future<List<Pass>> listNeedsReview() {
    return listByStoredStatus(PassStatus.needsReview);
  }

  List<Pass> _sorted(Iterable<Pass> passes) {
    return passes.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }
}
