class ReminderRequest {
  const ReminderRequest({
    required this.id,
    required this.passId,
    required this.title,
    required this.body,
    required this.triggerAt,
  });

  final String id;
  final String passId;
  final String title;
  final String body;
  final DateTime triggerAt;

  Map<String, Object> toPlatformPayload() {
    return {
      'id': id,
      'passId': passId,
      'title': title,
      'body': body,
      'triggerAtMillis': triggerAt.millisecondsSinceEpoch,
    };
  }
}

abstract class ReminderScheduler {
  Future<bool> requestAuthorization();
  Future<void> schedule(ReminderRequest request);
  Future<void> cancelForPass(String passId);
  Future<void> cancelAll();
}
