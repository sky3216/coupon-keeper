import '../data/pass_repository.dart';
import '../domain/pass.dart';
import 'pro_entitlement_controller.dart';
import 'reminder_engine.dart';

enum WalletFilter { active, used, expired, cleanup }

class WalletState {
  const WalletState({
    this.active = const [],
    this.used = const [],
    this.expired = const [],
    this.cleanupCandidates = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Pass> active;
  final List<Pass> used;
  final List<Pass> expired;
  final List<Pass> cleanupCandidates;
  final bool isLoading;
  final String? errorMessage;

  List<Pass> passesFor(WalletFilter filter) {
    switch (filter) {
      case WalletFilter.active:
        return active;
      case WalletFilter.used:
        return used;
      case WalletFilter.expired:
        return expired;
      case WalletFilter.cleanup:
        return cleanupCandidates;
    }
  }
}

class WalletController {
  WalletController({
    required this.repository,
    this.reminderEngine,
    this.proEntitlementController,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final PassRepository repository;
  final ReminderEngine? reminderEngine;
  final ProEntitlementController? proEntitlementController;
  final DateTime Function() _now;

  WalletState _state = const WalletState();

  WalletState get state => _state;

  Future<WalletState> load() async {
    _state = const WalletState(isLoading: true);
    try {
      final today = _now();
      _state = WalletState(
        active: await repository.listActive(today),
        used: await repository.listUsed(),
        expired: await repository.listExpired(today),
        cleanupCandidates: await repository.listCleanupCandidates(),
      );
    } catch (_) {
      _state = const WalletState(errorMessage: '지갑을 불러오지 못했어요.');
    }
    return _state;
  }

  Future<WalletState> markUsed(Pass pass) async {
    final updated = pass.copyWith(status: PassStatus.used, updatedAt: _now());
    await repository.update(updated);
    await _cancelReminders(updated);
    return load();
  }

  Future<WalletState> markCleanupCandidate(Pass pass) async {
    await proEntitlementController?.ensureCleanupCandidateAllowed();
    final updated = pass.copyWith(
      status: PassStatus.cleanupCandidate,
      updatedAt: _now(),
    );
    await repository.update(updated);
    await _cancelReminders(updated);
    return load();
  }

  Future<void> _cancelReminders(Pass pass) async {
    final engine = reminderEngine;
    if (engine == null) {
      return;
    }
    try {
      await engine.cancelForPass(pass);
    } catch (_) {
      // Wallet state changes should stay usable if local notification cleanup fails.
    }
  }
}
