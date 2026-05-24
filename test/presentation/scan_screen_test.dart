import 'package:coupon_keeper/application/guided_scan_controller.dart';
import 'package:coupon_keeper/data/in_memory_scan_fingerprint_cache.dart';
import 'package:coupon_keeper/domain/scan_item.dart';
import 'package:coupon_keeper/domain/scan_source.dart';
import 'package:coupon_keeper/platform/fake_scan_source_picker.dart';
import 'package:coupon_keeper/presentation/screens/scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('idle scan surface shows guided source choices', (tester) async {
    final picker = FakeScanSourcePicker.photos([
      _item('photo-1', sourceType: ScanSourceType.photos),
    ]);
    await tester.pumpWidget(
      _scanScreen(
        GuidedScanController(
          picker: picker,
          fingerprintCache: InMemoryScanFingerprintCache(),
        ),
      ),
    );

    expect(find.text('어디에서 쿠폰을 찾을까요?'), findsOneWidget);
    expect(find.text('선택한 사진과 파일만 기기 안에서 확인합니다.'), findsOneWidget);
    expect(find.text('사진에서 찾기'), findsOneWidget);
    expect(find.text('사진 앱에서 직접 고른 항목만 확인해요.'), findsOneWidget);
    expect(find.text('다운로드/파일에서 찾기'), findsOneWidget);
    expect(find.text('다운로드한 이미지나 폴더를 직접 고릅니다.'), findsOneWidget);
    expect(find.text('전체 사진첩이나 폴더를 조용히 훑지 않아요.'), findsOneWidget);
    expect(find.textContaining('전체 사진첩 스캔'), findsNothing);

    await tester.tap(find.text('사진에서 찾기'));
    await tester.pumpAndSettle();

    expect(picker.requestedSources, [ScanSourceType.photos]);
  });
}

Widget _scanScreen(GuidedScanController controller) {
  return MaterialApp(home: Scaffold(body: ScanScreen(controller: controller)));
}

ScanItem _item(String token, {ScanSourceType sourceType = ScanSourceType.downloads}) {
  return ScanItem(
    sourceType: sourceType,
    sourceToken: token,
    displayName: '$token.jpg',
    byteSize: 1024,
    modifiedAt: DateTime(2026, 5, 24),
  );
}
