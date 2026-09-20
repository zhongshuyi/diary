import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:diary/application/daily_reminder_scheduler.dart';
import 'package:diary/domain/diary_settings.dart';

class LocalDailyReminderScheduler implements DailyReminderScheduler {
  LocalDailyReminderScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _notificationId = 41001;
  static const _channelId = 'daily_diary_reminder';
  static const _channelName = '每日记录提醒';
  static const _channelDescription = '每天一次、可随时关闭的日记提醒';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  @override
  Future<DailyReminderScheduleResult> schedule(
    DiaryReminderTime time, {
    required bool requestPermission,
  }) async {
    if (!_isSupported) return DailyReminderScheduleResult.unsupported;
    try {
      if (!await _ensureInitialized()) {
        return DailyReminderScheduleResult.failed;
      }
      if (!await _configureTimeZone()) {
        return DailyReminderScheduleResult.failed;
      }
      if (requestPermission && !await _requestPermission()) {
        return DailyReminderScheduleResult.permissionDenied;
      }

      await _plugin.cancel(id: _notificationId);
      await _plugin.zonedSchedule(
        id: _notificationId,
        title: '留一点给今天',
        body: '写下今天想留住的一点吧。',
        scheduledDate: _nextInstance(time),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return DailyReminderScheduleResult.scheduled;
    } on Object {
      return DailyReminderScheduleResult.failed;
    }
  }

  @override
  Future<DailyReminderScheduleResult> cancel() async {
    if (!_isSupported) return DailyReminderScheduleResult.unsupported;
    try {
      if (!await _ensureInitialized()) {
        return DailyReminderScheduleResult.failed;
      }
      await _plugin.cancel(id: _notificationId);
      return DailyReminderScheduleResult.cancelled;
    } on Object {
      return DailyReminderScheduleResult.failed;
    }
  }

  bool get _isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<bool> _ensureInitialized() async {
    if (_initialized) return true;
    final initialized = await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = initialized ?? false;
    return _initialized;
  }

  Future<bool> _configureTimeZone() async {
    try {
      tz.initializeTimeZones();
      final timeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZone.identifier));
      return true;
    } on Object {
      return false;
    }
  }

  Future<bool> _requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return (await android?.requestNotificationsPermission()) != false;
    }
    final iOS = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return (await iOS?.requestPermissions(
          alert: true,
          badge: false,
          sound: true,
        )) !=
        false;
  }

  tz.TZDateTime _nextInstance(DiaryReminderTime time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
