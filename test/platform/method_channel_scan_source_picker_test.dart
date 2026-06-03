import 'package:coupon_keeper/domain/scan_source.dart';
import 'package:coupon_keeper/platform/method_channel_scan_source_picker.dart';
import 'package:coupon_keeper/platform/scan_source_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(MethodChannelScanSourcePicker.channelName);

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('sends source type for photos, downloads, and folder', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return {'status': 'cancelled'};
        });

    final picker = MethodChannelScanSourcePicker();
    await picker.pick(ScanSourceType.photos);
    await picker.pick(ScanSourceType.downloads);
    await picker.pick(ScanSourceType.folder);

    expect(calls.map((call) => call.method), [
      MethodChannelScanSourcePicker.pickMethod,
      MethodChannelScanSourcePicker.pickMethod,
      MethodChannelScanSourcePicker.pickMethod,
    ]);
    expect(calls.map((call) => call.arguments['sourceType']), [
      'photos',
      'downloads',
      'folder',
    ]);
  });

  test('decodes selected items and retryable failures', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          return {
            'status': 'selected',
            'items': [
              {
                'sourceType': 'downloads',
                'sourceToken': 'sha256:abc123',
                'platformSourceRef': 'file:///tmp/staged-one.image',
                'displayName': 'coupon.jpg',
                'byteSize': 321,
                'modifiedAt': '2026-06-03T00:00:00.000',
              },
            ],
            'failures': [
              {'handle': 'retry-1', 'displayName': 'broken.jpg'},
            ],
          };
        });

    final result = await MethodChannelScanSourcePicker().pick(
      ScanSourceType.downloads,
    );

    expect(result.status, ScanSourcePickStatus.selected);
    expect(result.items.single.sourceType, ScanSourceType.downloads);
    expect(result.items.single.fingerprintInput, contains('sha256:abc123'));
    expect(
      result.items.single.platformSourceRef,
      'file:///tmp/staged-one.image',
    );
    expect(result.retryableFailures.single.handle, 'retry-1');
  });

  test('rejects raw absolute source tokens from native payload', () {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          return {
            'status': 'selected',
            'items': [
              {
                'sourceType': 'photos',
                'sourceToken': '/Users/sora/Pictures/coupon.jpg',
                'platformSourceRef': 'file:///tmp/staged-one.image',
                'displayName': 'coupon.jpg',
              },
            ],
          };
        });

    expect(
      () => MethodChannelScanSourcePicker().pick(ScanSourceType.photos),
      throwsArgumentError,
    );
  });

  test(
    'retries only retained failure handles and releases resources',
    () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            if (call.method == MethodChannelScanSourcePicker.releaseMethod) {
              return null;
            }
            return {'status': 'selected', 'items': <Object?>[]};
          });

      final picker = MethodChannelScanSourcePicker();
      await picker.retryFailures([
        const RetryableSourceFailure(handle: 'retry-1', displayName: 'bad.jpg'),
      ]);
      await picker.release(
        failures: [
          const RetryableSourceFailure(
            handle: 'retry-1',
            displayName: 'bad.jpg',
          ),
        ],
      );

      expect(calls.first.method, MethodChannelScanSourcePicker.retryMethod);
      expect(calls.first.arguments['handles'], ['retry-1']);
      expect(calls.last.method, MethodChannelScanSourcePicker.releaseMethod);
      expect(calls.last.arguments['handles'], ['retry-1']);
    },
  );
}
