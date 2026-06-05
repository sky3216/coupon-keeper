import 'package:coupon_keeper/data/in_memory_pass_repository.dart';
import 'package:coupon_keeper/domain/pass.dart';
import 'package:coupon_keeper/domain/pass_confidence.dart';
import 'package:coupon_keeper/domain/pass_source_metadata.dart';
import 'package:coupon_keeper/platform/source_cleanup_launcher.dart';
import 'package:coupon_keeper/presentation/screens/wallet_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cleanup candidates explain source cleanup handoff', (
    tester,
  ) async {
    final repository = InMemoryPassRepository();
    final launcher = _RecordingSourceCleanupLauncher();
    await repository.save(
      _pass(
        id: 'cleanup-1',
        title: '정리할 쿠폰',
        status: PassStatus.cleanupCandidate,
      ),
    );

    await tester.pumpWidget(_app(repository, sourceCleanupLauncher: launcher));
    await tester.pumpAndSettle();

    await tester.tap(find.text('정리 후보 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('정리할 쿠폰'));
    await tester.pumpAndSettle();

    expect(find.text('정리 후보'), findsOneWidget);
    expect(find.text('원본 정리 안내'), findsOneWidget);

    await tester.ensureVisible(find.text('원본 정리 안내'));
    await tester.tap(find.text('원본 정리 안내'));
    await tester.pumpAndSettle();

    expect(find.text('원본은 자동으로 삭제하지 않아요'), findsOneWidget);
    expect(find.text('원본 앱이나 시스템 파일 화면에서 직접 정리해 주세요.'), findsOneWidget);

    await tester.tap(find.text('원본 앱 열기'));
    await tester.pumpAndSettle();

    expect(launcher.openedUris, ['fixture://cleanup-1']);
  });

  testWidgets('source missing pass stays recoverable through app copy', (
    tester,
  ) async {
    final repository = InMemoryPassRepository();
    await repository.save(
      _pass(
        id: 'missing-1',
        title: '원본 없는 쿠폰',
        sourceAvailable: false,
        imageCopyPath: 'file:///tmp/coupon-copy.jpg',
      ),
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('원본 없음'), findsOneWidget);
    await tester.tap(find.text('원본 없는 쿠폰'));
    await tester.pumpAndSettle();

    expect(find.text('원본 파일 확인 필요'), findsOneWidget);
    expect(find.text('앱 내부 사본으로 계속 사용할 수 있어요'), findsOneWidget);
  });
}

Widget _app(
  InMemoryPassRepository repository, {
  SourceCleanupLauncher? sourceCleanupLauncher,
}) {
  return MaterialApp(
    home: Scaffold(
      body: WalletScreen(
        onScanSelected: () {},
        passRepository: repository,
        sourceCleanupLauncher: sourceCleanupLauncher,
        isSelected: true,
      ),
    ),
  );
}

class _RecordingSourceCleanupLauncher implements SourceCleanupLauncher {
  final List<String> openedUris = [];

  @override
  Future<bool> openSource(String originalUri) async {
    openedUris.add(originalUri);
    return true;
  }
}

Pass _pass({
  required String id,
  required String title,
  PassStatus status = PassStatus.active,
  bool sourceAvailable = true,
  String? imageCopyPath = 'app://copies/pass.jpg',
}) {
  return Pass(
    id: id,
    type: PassType.coupon,
    title: title,
    brand: '테스트 브랜드',
    estimatedValue: 3000,
    expiry: DateTime(2026, 7, 31),
    status: status,
    sourceMetadata: PassSourceMetadata(
      originalUri: 'fixture://$id',
      platformSourceType: 'downloads',
      fingerprint: 'fingerprint-$id',
      importedAt: DateTime(2026, 6, 1),
      isAvailable: sourceAvailable,
      missingReason: sourceAvailable ? null : 'fixture missing',
    ),
    imageCopyPath: imageCopyPath,
    ocrText: title,
    confidence: const PassConfidence(
      expiry: 0.9,
      value: 0.8,
      brand: 0.7,
      barcode: 0.6,
      overall: 0.8,
    ),
    createdAt: DateTime(2026, 6, 1),
    updatedAt: DateTime(2026, 6, 1),
  );
}
