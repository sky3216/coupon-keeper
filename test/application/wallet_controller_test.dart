import 'package:coupon_keeper/application/reminder_engine.dart';
import 'package:coupon_keeper/application/wallet_controller.dart';
import 'package:coupon_keeper/data/in_memory_pass_repository.dart';
import 'package:coupon_keeper/domain/pass.dart';
import 'package:coupon_keeper/domain/pass_confidence.dart';
import 'package:coupon_keeper/domain/pass_source_metadata.dart';
import 'package:coupon_keeper/platform/reminder_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('marking a pass used cancels its scheduled reminders', () async {
    final repository = InMemoryPassRepository();
    final pass = _pass(id: 'pass-1');
    await repository.save(pass);
    final scheduler = _RecordingReminderScheduler();
    final controller = WalletController(
      repository: repository,
      reminderEngine: ReminderEngine(
        passRepository: repository,
        scheduler: scheduler,
        now: () => DateTime(2026, 6, 20),
      ),
      now: () => DateTime(2026, 6, 21),
    );

    await controller.markUsed(pass);

    expect(scheduler.cancelledPasses, ['pass-1']);
    expect((await repository.getById('pass-1'))?.status, PassStatus.used);
  });

  test('moving a pass to cleanup candidates cancels reminders', () async {
    final repository = InMemoryPassRepository();
    final pass = _pass(id: 'pass-2', status: PassStatus.used);
    await repository.save(pass);
    final scheduler = _RecordingReminderScheduler();
    final controller = WalletController(
      repository: repository,
      reminderEngine: ReminderEngine(
        passRepository: repository,
        scheduler: scheduler,
        now: () => DateTime(2026, 6, 20),
      ),
      now: () => DateTime(2026, 6, 21),
    );

    await controller.markCleanupCandidate(pass);

    expect(scheduler.cancelledPasses, ['pass-2']);
    expect(
      (await repository.getById('pass-2'))?.status,
      PassStatus.cleanupCandidate,
    );
  });
}

class _RecordingReminderScheduler implements ReminderScheduler {
  final cancelledPasses = <String>[];

  @override
  Future<bool> requestAuthorization() async => true;

  @override
  Future<void> schedule(ReminderRequest request) async {}

  @override
  Future<void> cancelForPass(String passId) async {
    cancelledPasses.add(passId);
  }

  @override
  Future<void> cancelAll() async {}
}

Pass _pass({required String id, PassStatus status = PassStatus.active}) {
  final now = DateTime(2026, 6, 1);
  return Pass(
    id: id,
    type: PassType.coupon,
    title: '무료 음료 쿠폰',
    brand: 'Cafe',
    estimatedValue: 4500,
    expiry: DateTime(2026, 6, 30),
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
