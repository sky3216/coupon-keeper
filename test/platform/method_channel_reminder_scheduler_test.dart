import 'package:coupon_keeper/platform/method_channel_reminder_scheduler.dart';
import 'package:coupon_keeper/platform/reminder_scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(MethodChannelReminderScheduler.channelName);

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('requests notification authorization from reminder channel', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return true;
        });

    final allowed = await MethodChannelReminderScheduler()
        .requestAuthorization();

    expect(allowed, isTrue);
    expect(
      calls.single.method,
      MethodChannelReminderScheduler.requestAuthorizationMethod,
    );
  });

  test(
    'sends schedule and cancellation payloads to reminder channel',
    () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return null;
          });
      final scheduler = MethodChannelReminderScheduler();

      await scheduler.schedule(
        ReminderRequest(
          id: 'pass-1:d-day',
          passId: 'pass-1',
          title: 'Coupon Keeper',
          body: '무료 음료 쿠폰 오늘 만료돼요.',
          triggerAt: DateTime(2026, 6, 30, 9),
        ),
      );
      await scheduler.cancelForPass('pass-1');
      await scheduler.cancelAll();

      expect(calls[0].method, MethodChannelReminderScheduler.scheduleMethod);
      expect(calls[0].arguments, {
        'id': 'pass-1:d-day',
        'passId': 'pass-1',
        'title': 'Coupon Keeper',
        'body': '무료 음료 쿠폰 오늘 만료돼요.',
        'triggerAtMillis': DateTime(2026, 6, 30, 9).millisecondsSinceEpoch,
      });
      expect(
        calls[1].method,
        MethodChannelReminderScheduler.cancelForPassMethod,
      );
      expect(calls[1].arguments, {'passId': 'pass-1'});
      expect(calls[2].method, MethodChannelReminderScheduler.cancelAllMethod);
    },
  );
}
