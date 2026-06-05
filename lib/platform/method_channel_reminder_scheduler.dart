import 'package:flutter/services.dart';

import 'reminder_scheduler.dart';

class MethodChannelReminderScheduler implements ReminderScheduler {
  MethodChannelReminderScheduler({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'coupon_keeper/reminders';
  static const String requestAuthorizationMethod = 'requestAuthorization';
  static const String scheduleMethod = 'schedule';
  static const String cancelForPassMethod = 'cancelForPass';
  static const String cancelAllMethod = 'cancelAll';

  final MethodChannel _channel;

  @override
  Future<bool> requestAuthorization() async {
    final allowed = await _channel.invokeMethod<bool>(
      requestAuthorizationMethod,
    );
    return allowed ?? false;
  }

  @override
  Future<void> schedule(ReminderRequest request) {
    return _channel.invokeMethod<void>(
      scheduleMethod,
      request.toPlatformPayload(),
    );
  }

  @override
  Future<void> cancelForPass(String passId) {
    return _channel.invokeMethod<void>(cancelForPassMethod, {'passId': passId});
  }

  @override
  Future<void> cancelAll() {
    return _channel.invokeMethod<void>(cancelAllMethod);
  }
}
