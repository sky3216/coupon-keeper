import '../domain/pass.dart';

abstract class PassRepository {
  Future<void> save(Pass pass);
  Future<void> update(Pass pass);
  Future<void> deleteById(String id);
  Future<Pass?> getById(String id);
  Future<List<Pass>> listAll();
  Future<List<Pass>> listByStoredStatus(PassStatus status);
  Future<List<Pass>> listByEffectiveStatus(PassStatus status, DateTime today);
  Future<List<Pass>> listActive(DateTime today);
  Future<List<Pass>> listUsed();
  Future<List<Pass>> listExpired(DateTime today);
  Future<List<Pass>> listCleanupCandidates();
  Future<List<Pass>> listNeedsReview();
}
