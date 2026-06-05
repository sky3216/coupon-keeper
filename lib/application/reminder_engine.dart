import '../data/pass_repository.dart';
import '../domain/pass.dart';
import '../platform/reminder_scheduler.dart';

enum ReminderTier { free, pro }

class ReminderEngine {
  ReminderEngine({
    required this.passRepository,
    required this.scheduler,
    required this.now,
    this.tier = ReminderTier.free,
    this.customDaysBefore = const [],
  });

  final PassRepository passRepository;
  final ReminderScheduler scheduler;
  final DateTime Function() now;
  final ReminderTier tier;
  final List<int> customDaysBefore;

  Future<void> reconcile({bool requestAuthorization = false}) async {
    if (requestAuthorization) {
      final allowed = await scheduler.requestAuthorization();
      if (!allowed) {
        return;
      }
    }

    await scheduler.cancelAll();
    final today = _dateOnly(now());
    final activePasses = await passRepository.listActive(today);
    for (final pass in activePasses) {
      for (final request in requestsFor(pass)) {
        await scheduler.schedule(request);
      }
    }
  }

  Future<void> syncPass(Pass pass) async {
    await scheduler.cancelForPass(pass.id);
    for (final request in requestsFor(pass)) {
      await scheduler.schedule(request);
    }
  }

  Future<void> cancelForPass(Pass pass) {
    return scheduler.cancelForPass(pass.id);
  }

  List<ReminderRequest> requestsFor(Pass pass) {
    final expiry = pass.expiry;
    if (expiry == null || pass.effectiveStatus(now()) != PassStatus.active) {
      return const [];
    }

    final offsets = _daysBeforeOffsets();
    return offsets
        .map((daysBefore) => _requestFor(pass, expiry, daysBefore))
        .where((request) => request.triggerAt.isAfter(now()))
        .toList(growable: false);
  }

  List<int> _daysBeforeOffsets() {
    final offsets = <int>{7, 0};
    if (tier == ReminderTier.pro) {
      offsets.addAll([3, 1]);
      offsets.addAll(customDaysBefore.where((days) => days >= 0));
    }
    return offsets.toList()..sort((a, b) => b.compareTo(a));
  }

  ReminderRequest _requestFor(Pass pass, DateTime expiry, int daysBefore) {
    final triggerDate = _dateOnly(expiry).subtract(Duration(days: daysBefore));
    final triggerAt = DateTime(
      triggerDate.year,
      triggerDate.month,
      triggerDate.day,
      9,
    );
    final ruleId = daysBefore == 0 ? 'd-day' : 'd-$daysBefore';
    return ReminderRequest(
      id: '${pass.id}:$ruleId',
      passId: pass.id,
      title: 'Coupon Keeper',
      body: daysBefore == 0
          ? '${pass.title} 오늘 만료돼요.'
          : '${pass.title} $daysBefore일 뒤 만료돼요.',
      triggerAt: triggerAt,
    );
  }
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
