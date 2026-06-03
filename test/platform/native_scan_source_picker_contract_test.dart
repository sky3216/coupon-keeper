import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Android uses system pickers, direct children, and no broad storage permission',
    () {
      final activity = File(
        'android/app/src/main/kotlin/com/example/coupon_keeper/MainActivity.kt',
      ).readAsStringSync();
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();

      expect(activity, contains('coupon_keeper/source_picker'));
      expect(activity, contains('PickMultipleVisualMedia'));
      expect(activity, contains('Intent.ACTION_OPEN_DOCUMENT'));
      expect(activity, contains('Intent.ACTION_OPEN_DOCUMENT_TREE'));
      expect(
        activity,
        contains('DocumentsContract.buildChildDocumentsUriUsingTree'),
      );
      expect(activity, contains('DocumentsContract.buildDocumentUriUsingTree'));
      expect(activity, isNot(contains('walkTopDown')));
      expect(activity, isNot(contains('listFiles')));
      expect(activity, contains('MessageDigest.getInstance("SHA-256")'));
      expect(activity, contains('coupon-keeper-selected'));
      expect(manifest, isNot(contains('READ_MEDIA_IMAGES')));
      expect(manifest, isNot(contains('READ_EXTERNAL_STORAGE')));
      expect(manifest, isNot(contains('MANAGE_EXTERNAL_STORAGE')));
    },
  );

  test('iOS uses Photos, Files, folders, and scoped access balancing', () {
    final appDelegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();

    expect(appDelegate, contains('coupon_keeper/source_picker'));
    expect(appDelegate, contains('PHPickerViewController'));
    expect(appDelegate, contains('selectionLimit = 0'));
    expect(appDelegate, contains('UIDocumentPickerViewController'));
    expect(appDelegate, contains('allowsMultipleSelection = true'));
    expect(appDelegate, contains('.image'));
    expect(appDelegate, contains('.folder'));
    expect(appDelegate, contains('startAccessingSecurityScopedResource()'));
    expect(appDelegate, contains('stopAccessingSecurityScopedResource()'));
    expect(appDelegate, contains('NSFileCoordinator'));
    expect(appDelegate, contains('contentsOfDirectory'));
    expect(appDelegate, isNot(contains('enumerator(at:')));
    expect(appDelegate, contains('SHA256.hash'));
    expect(appDelegate, contains('coupon-keeper-selected'));
    expect(appDelegate, contains('coupon_keeper/ocr'));
  });
}
