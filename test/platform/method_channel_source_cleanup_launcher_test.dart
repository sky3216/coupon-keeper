import 'package:coupon_keeper/platform/method_channel_source_cleanup_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(MethodChannelSourceCleanupLauncher.channelName);

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('sends original uri to source cleanup channel', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return true;
        });

    final opened = await MethodChannelSourceCleanupLauncher().openSource(
      'content://downloads/coupon.jpg',
    );

    expect(opened, isTrue);
    expect(
      calls.single.method,
      MethodChannelSourceCleanupLauncher.openSourceMethod,
    );
    expect(calls.single.arguments, {
      'originalUri': 'content://downloads/coupon.jpg',
    });
  });

  test('treats null platform response as not opened', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => null);

    final opened = await MethodChannelSourceCleanupLauncher().openSource(
      'fixture://missing',
    );

    expect(opened, isFalse);
  });
}
