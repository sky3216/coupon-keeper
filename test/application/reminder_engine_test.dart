import 'package:coupon_keeper/application/reminder_engine.dart';
import 'package:coupon_keeper/data/in_memory_pass_repository.dart';
import 'package:coupon_keeper/domain/pass.dart';
import 'package:coupon_keeper/domain/pass_confidence.dart';
import 'package:coupon_keeper/domain/pass_source_metadata.dart';
import 'package:coupon_keeper/platform/reminder_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('free tier schedules future D-7 and D-Day reminders', () async {
    final repository = InMemoryPassRepository();
    await repository.save(_pass(expiry: DateTime(2026, 6, 30)));
    final scheduler = _RecordingReminderScheduler();
    final engine = ReminderEngine(
      passRepository: repository,
      scheduler: scheduler,
      now: () => DateTime(2026, 6, 20, 10),
    );

    await engine.reconcile(requestAuthorization: true);

    expect(scheduler.authorizationRequests, 1);
    expect(scheduler.cancelAllCount, 1);
    expect(scheduler.scheduled.map((request) => request.id), [
      'pass-1:d-7',
      'pass-1:d-day',
    ]);
    expect(scheduler.scheduled.map((request) => request.triggerAt), [
      DateTime(2026, 6, 23, 9),
      DateTime(2026, 6, 30, 9),
    ]);
  });

  test(
    'past offsets, used passes, expired passes, and missing expiry are skipped',
    () async {
      final repository = InMemoryPassRepository();
      await repository.save(_pass(id: 'soon', expiry: DateTime(2026, 6, 30)));
      await repository.save(
        _pass(
          id: 'used',
          status: PassStatus.used,
          expiry: DateTime(2026, 6, 30),
        ),
      );
      await repository.save(_pass(id: 'expired', expiry: DateTime(2026, 6, 1)));
      await repository.save(_pass(id: 'no-expiry', expiry: null));
      final scheduler = _RecordingReminderScheduler();
      final engine = ReminderEngine(
        passRepository: repository,
        scheduler: scheduler,
        now: () => DateTime(2026, 6, 24, 10),
      );

      await engine.reconcile();

      expect(scheduler.scheduled.map((request) => request.id), ['soon:d-day']);
    },
  );

  test('pro tier supports D-3, D-1, and custom reminder offsets', () {
    final engine = ReminderEngine(
      passRepository: InMemoryPassRepository(),
      scheduler: _RecordingReminderScheduler(),
      now: () => DateTime(2026, 6, 20, 10),
      tier: ReminderTier.pro,
      customDaysBefore: const [5],
    );

    final requests = engine.requestsFor(_pass(expiry: DateTime(2026, 6, 30)));

    expect(requests.map((request) => request.id), [
      'pass-1:d-7',
      'pass-1:d-5',
      'pass-1:d-3',
      'pass-1:d-1',
      'pass-1:d-day',
    ]);
  });

  test(
    'syncPass cancels old reminders before scheduling current pass reminders',
    () async {
      final scheduler = _RecordingReminderScheduler();
      final engine = ReminderEngine(
        passRepository: InMemoryPassRepository(),
        scheduler: scheduler,
        now: () => DateTime(2026, 6, 20, 10),
      );

      await engine.syncPass(_pass(expiry: DateTime(2026, 6, 30)));

      expect(scheduler.cancelledPasses, ['pass-1']);
      expect(scheduler.scheduled.map((request) => request.id), [
        'pass-1:d-7',
        'pass-1:d-day',
      ]);
    },
  );

  test(
    'reconcile leaves existing reminders unchanged when authorization is denied',
    () async {
      final repository = InMemoryPassRepository();
      await repository.save(_pass(expiry: DateTime(2026, 6, 30)));
      final scheduler = _RecordingReminderScheduler(allowed: false);
      final engine = ReminderEngine(
        passRepository: repository,
        scheduler: scheduler,
        now: () => DateTime(2026, 6, 20, 10),
      );

      await engine.reconcile(requestAuthorization: true);

      expect(scheduler.authorizationRequests, 1);
      expect(scheduler.cancelAllCount, 0);
      expect(scheduler.scheduled, isEmpty);
    },
  );
}

class _RecordingReminderScheduler implements ReminderScheduler {
  _RecordingReminderScheduler({this.allowed = true});

  final bool allowed;
  final scheduled = <ReminderRequest>[];
  final cancelledPasses = <String>[];
  var cancelAllCount = 0;
  var authorizationRequests = 0;

  @override
  Future<bool> requestAuthorization() async {
    authorizationRequests += 1;
    return allowed;
  }

  @override
  Future<void> schedule(ReminderRequest request) async {
    scheduled.add(request);
  }

  @override
  Future<void> cancelForPass(String passId) async {
    cancelledPasses.add(passId);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCount += 1;
  }
}

Pass _pass({
  String id = 'pass-1',
  PassStatus status = PassStatus.active,
  DateTime? expiry = _defaultExpiry,
}) {
  final now = DateTime(2026, 6, 1);
  return Pass(
    id: id,
    type: PassType.coupon,
    title: '무료 음료 쿠폰',
    brand: 'Cafe',
    estimatedValue: 4500,
    expiry: expiry,
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

const _defaultExpiry = null;
