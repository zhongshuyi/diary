import 'package:diary/domain/diary_settings.dart';

enum DailyReminderScheduleResult {
  scheduled,
  cancelled,
  permissionDenied,
  unsupported,
  failed,
}

extension DailyReminderScheduleResultX on DailyReminderScheduleResult {
  bool get isSuccess =>
      this == DailyReminderScheduleResult.scheduled ||
      this == DailyReminderScheduleResult.cancelled;
}

abstract interface class DailyReminderScheduler {
  Future<DailyReminderScheduleResult> schedule(
    DiaryReminderTime time, {
    required bool requestPermission,
  });

  Future<DailyReminderScheduleResult> cancel();
}

class NoopDailyReminderScheduler implements DailyReminderScheduler {
  const NoopDailyReminderScheduler();

  @override
  Future<DailyReminderScheduleResult> cancel() async =>
      DailyReminderScheduleResult.cancelled;

  @override
  Future<DailyReminderScheduleResult> schedule(
    DiaryReminderTime time, {
    required bool requestPermission,
  }) async => DailyReminderScheduleResult.scheduled;
}
