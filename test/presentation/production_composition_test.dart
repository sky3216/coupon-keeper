import 'dart:io';

import 'package:coupon_keeper/application/coupon_keeper_dependencies.dart';
import 'package:coupon_keeper/application/guided_scan_controller.dart';
import 'package:coupon_keeper/data/in_memory_scan_fingerprint_cache.dart';
import 'package:coupon_keeper/data/sqlite_pass_repository.dart';
import 'package:coupon_keeper/data/sqlite_scan_fingerprint_cache.dart';
import 'package:coupon_keeper/platform/fake_scan_source_picker.dart';
import 'package:coupon_keeper/platform/local_image_copy_store.dart';
import 'package:coupon_keeper/platform/method_channel_ocr_text_recognizer.dart';
import 'package:coupon_keeper/platform/method_channel_reminder_scheduler.dart';
import 'package:coupon_keeper/platform/method_channel_scan_source_picker.dart';
import 'package:coupon_keeper/presentation/app/coupon_keeper_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production dependencies use real local adapters', () async {
    final dependencies = await CouponKeeperDependencies.production(
      now: () => DateTime(2026, 6, 3),
      nextId: () => 'pass-1',
    );
    addTearDown(dependencies.dispose);

    expect(dependencies.scanPicker, isA<MethodChannelScanSourcePicker>());
    expect(
      dependencies.ocrTextRecognizer,
      isA<MethodChannelOcrTextRecognizer>(),
    );
    expect(dependencies.passRepository, isA<SqlitePassRepository>());
    expect(dependencies.fingerprintCache, isA<SqliteScanFingerprintCache>());
    expect(dependencies.imageCopyStore, isA<LocalImageCopyStore>());
    expect(
      dependencies.reminderScheduler,
      isA<MethodChannelReminderScheduler>(),
    );
  });

  test('widget tests can still inject deterministic fake controllers', () {
    final fakeController = GuidedScanController(
      picker: FakeScanSourcePicker.downloads(const []),
      fingerprintCache: InMemoryScanFingerprintCache(),
    );

    expect(
      CouponKeeperApp(scanController: fakeController),
      isA<CouponKeeperApp>(),
    );
  });

  test('default app path rejects demo fake and in-memory imports', () {
    final guardedFiles = [
      'lib/presentation/screens/scan_screen.dart',
      'lib/presentation/app/coupon_keeper_app.dart',
      'lib/presentation/shell/app_shell.dart',
      'lib/application/coupon_keeper_dependencies.dart',
    ];
    final forbiddenImports = [
      'phase_two_demo_scan_source_picker.dart',
      'fake_ocr_text_recognizer.dart',
      'fake_image_copy_store.dart',
      'in_memory_pass_repository.dart',
      'in_memory_scan_fingerprint_cache.dart',
    ];

    for (final path in guardedFiles) {
      final text = File(path).readAsStringSync();
      for (final import in forbiddenImports) {
        expect(text, isNot(contains(import)), reason: '$path imports $import');
      }
    }
  });
}
