import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Android manifest avoids broad media, network, and location permissions',
    () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();

      expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
      expect(manifest, isNot(contains('android.permission.INTERNET')));
      expect(
        manifest,
        isNot(contains('android.permission.READ_EXTERNAL_STORAGE')),
      );
      expect(manifest, isNot(contains('android.permission.READ_MEDIA_IMAGES')));
      expect(
        manifest,
        isNot(contains('android.permission.ACCESS_FINE_LOCATION')),
      );
      expect(
        manifest,
        isNot(contains('android.permission.ACCESS_COARSE_LOCATION')),
      );
    },
  );

  test(
    'iOS plist avoids broad photo library, network, and location usage keys',
    () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();

      expect(plist, isNot(contains('NSPhotoLibraryUsageDescription')));
      expect(plist, isNot(contains('NSPhotoLibraryAddUsageDescription')));
      expect(plist, isNot(contains('NSLocationWhenInUseUsageDescription')));
      expect(
        plist,
        isNot(contains('NSLocationAlwaysAndWhenInUseUsageDescription')),
      );
      expect(plist, isNot(contains('NSAppTransportSecurity')));
    },
  );
}
