import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Android reminder channel schedules local notifications without network',
    () {
      final activity = File(
        'android/app/src/main/kotlin/com/example/coupon_keeper/MainActivity.kt',
      ).readAsStringSync();
      final receiver = File(
        'android/app/src/main/kotlin/com/example/coupon_keeper/ReminderReceiver.kt',
      ).readAsStringSync();
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();

      expect(activity, contains('coupon_keeper/reminders'));
      expect(activity, contains('requestAuthorization'));
      expect(activity, contains('AlarmManager.RTC_WAKEUP'));
      expect(activity, contains('cancelRemindersForPass'));
      expect(activity, contains('cancelAllReminders'));
      expect(receiver, contains('NotificationChannel'));
      expect(receiver, contains('Notification.Builder'));
      expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
      expect(manifest, contains('.ReminderReceiver'));
      expect('$activity\n$receiver', isNot(contains('http://')));
      expect('$activity\n$receiver', isNot(contains('https://')));
    },
  );

  test('iOS reminder channel uses local UNUserNotificationCenter requests', () {
    final appDelegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();

    expect(appDelegate, contains('coupon_keeper/reminders'));
    expect(appDelegate, contains('UNUserNotificationCenter.current()'));
    expect(appDelegate, contains('requestAuthorization'));
    expect(appDelegate, contains('UNNotificationRequest'));
    expect(appDelegate, contains('UNTimeIntervalNotificationTrigger'));
    expect(appDelegate, contains('removePendingNotificationRequests'));
    expect(appDelegate, isNot(contains('http://')));
    expect(appDelegate, isNot(contains('https://')));
  });
}
