import 'package:uuid/uuid.dart';

import '../data/coupon_keeper_database.dart';
import '../data/sqlite_image_copy_registry.dart';
import '../data/sqlite_pass_repository.dart';
import '../data/sqlite_pro_entitlement_repository.dart';
import '../data/sqlite_scan_fingerprint_cache.dart';
import '../platform/iap_pro_purchase_gateway.dart';
import '../platform/local_image_copy_store.dart';
import '../platform/method_channel_ocr_text_recognizer.dart';
import '../platform/method_channel_reminder_scheduler.dart';
import '../platform/method_channel_scan_source_picker.dart';
import 'candidate_discovery_controller.dart';
import 'guided_scan_controller.dart';
import 'pass_candidate_parser.dart';
import 'pro_entitlement_controller.dart';
import 'reminder_engine.dart';

class CouponKeeperDependencies {
  CouponKeeperDependencies({
    required this.database,
    required this.passRepository,
    required this.fingerprintCache,
    required this.imageCopyRegistry,
    required this.proEntitlementRepository,
    required this.imageCopyStore,
    required this.scanPicker,
    required this.ocrTextRecognizer,
    required this.proPurchaseGateway,
    required this.proEntitlementController,
    required this.reminderScheduler,
    required this.reminderEngine,
    required this.parser,
    required this.discoveryController,
    required this.scanController,
  });

  final CouponKeeperDatabase database;
  final SqlitePassRepository passRepository;
  final SqliteScanFingerprintCache fingerprintCache;
  final SqliteImageCopyRegistry imageCopyRegistry;
  final SqliteProEntitlementRepository proEntitlementRepository;
  final LocalImageCopyStore imageCopyStore;
  final MethodChannelScanSourcePicker scanPicker;
  final MethodChannelOcrTextRecognizer ocrTextRecognizer;
  final IapProPurchaseGateway proPurchaseGateway;
  final ProEntitlementController proEntitlementController;
  final MethodChannelReminderScheduler reminderScheduler;
  final ReminderEngine reminderEngine;
  final PassCandidateParser parser;
  final CandidateDiscoveryController discoveryController;
  final GuidedScanController scanController;

  static Future<CouponKeeperDependencies> production({
    DateTime Function()? now,
    String Function()? nextId,
  }) async {
    final database = CouponKeeperDatabase();
    final passRepository = SqlitePassRepository(database);
    final fingerprintCache = SqliteScanFingerprintCache(database, now: now);
    final imageCopyRegistry = SqliteImageCopyRegistry(database, now: now);
    final proEntitlementRepository = SqliteProEntitlementRepository(database);
    final imageCopyStore = LocalImageCopyStore(registry: imageCopyRegistry);
    final scanPicker = MethodChannelScanSourcePicker();
    final ocrTextRecognizer = MethodChannelOcrTextRecognizer();
    final proPurchaseGateway = IapProPurchaseGateway();
    final reminderScheduler = MethodChannelReminderScheduler();
    const parser = PassCandidateParser();
    const uuid = Uuid();
    final passIdFactory = nextId ?? uuid.v4;
    final nowFactory = now ?? DateTime.now;
    final reminderEngine = ReminderEngine(
      passRepository: passRepository,
      scheduler: reminderScheduler,
      now: nowFactory,
    );
    final proEntitlementController = ProEntitlementController(
      entitlementRepository: proEntitlementRepository,
      passRepository: passRepository,
      purchaseGateway: proPurchaseGateway,
      now: nowFactory,
    );

    final discoveryController = CandidateDiscoveryController(
      recognizer: ocrTextRecognizer,
      parser: parser,
      imageCopyStore: imageCopyStore,
      passRepository: passRepository,
      now: nowFactory,
      nextId: passIdFactory,
      reminderEngine: reminderEngine,
      proEntitlementController: proEntitlementController,
    );
    final scanController = GuidedScanController(
      picker: scanPicker,
      fingerprintCache: fingerprintCache,
      processItem: discoveryController.processItem,
    );

    return CouponKeeperDependencies(
      database: database,
      passRepository: passRepository,
      fingerprintCache: fingerprintCache,
      imageCopyRegistry: imageCopyRegistry,
      proEntitlementRepository: proEntitlementRepository,
      imageCopyStore: imageCopyStore,
      scanPicker: scanPicker,
      ocrTextRecognizer: ocrTextRecognizer,
      proPurchaseGateway: proPurchaseGateway,
      proEntitlementController: proEntitlementController,
      reminderScheduler: reminderScheduler,
      reminderEngine: reminderEngine,
      parser: parser,
      discoveryController: discoveryController,
      scanController: scanController,
    );
  }

  Future<void> dispose() async {
    await scanController.dispose();
    await database.close();
  }
}
