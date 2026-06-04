import 'package:coupon_keeper/domain/scan_item.dart';
import 'package:coupon_keeper/domain/scan_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScanItem', () {
    test('represents photos, downloads, and folders separately', () {
      expect(ScanSourceType.photos.label, '사진');
      expect(ScanSourceType.downloads.label, '다운로드/파일');
      expect(ScanSourceType.folder.label, '폴더');
      expect(ScanSourceType.photos.supportingCopy, '사진 앱에서 직접 고른 항목만 확인해요.');
      expect(ScanSourceType.downloads.supportingCopy, '다운로드한 이미지를 직접 고릅니다.');
      expect(
        ScanSourceType.folder.supportingCopy,
        '직접 고른 폴더의 바로 안쪽 이미지만 확인해요.',
      );
    });

    test('builds a stable fingerprint input from selected item metadata', () {
      final modifiedAt = DateTime(2026, 5, 24, 12, 30);
      final item = ScanItem(
        sourceType: ScanSourceType.photos,
        sourceToken: 'ph-asset-123',
        displayName: 'coupon-photo.jpg',
        byteSize: 4096,
        modifiedAt: modifiedAt,
      );

      expect(item.fingerprintInput, contains('photos'));
      expect(item.fingerprintInput, contains('ph-asset-123'));
      expect(item.fingerprintInput, contains('4096'));
      expect(item.fingerprintInput, contains(modifiedAt.toIso8601String()));
      expect(item.fingerprintInput, isNot(contains('coupon-photo.jpg')));
    });

    test('does not require raw absolute file paths', () {
      expect(
        () => ScanItem(
          sourceType: ScanSourceType.downloads,
          sourceToken: '/Users/sora/Downloads/coupon.jpg',
          displayName: 'coupon.jpg',
        ),
        throwsArgumentError,
      );
      expect(
        () => ScanItem(
          sourceType: ScanSourceType.downloads,
          sourceToken: 'file:///Users/sora/Downloads/coupon.jpg',
          displayName: 'coupon.jpg',
        ),
        throwsArgumentError,
      );
    });

    test('keeps transient platform source ref out of fingerprint input', () {
      final first = ScanItem(
        sourceType: ScanSourceType.photos,
        sourceToken: 'ph-asset-123',
        displayName: 'coupon.jpg',
        platformSourceRef: 'content://picker/one',
      );
      final second = ScanItem(
        sourceType: ScanSourceType.photos,
        sourceToken: 'ph-asset-123',
        displayName: 'coupon.jpg',
        platformSourceRef: 'content://picker/two',
      );

      expect(first.fingerprintInput, second.fingerprintInput);
      expect(first.fingerprintInput, isNot(contains('content://')));
    });
  });
}
