import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Retain an already-enabled reminder feature after automatic course updates.
/// This never requests permissions or changes the user's notification switch.
Future<void> refreshCourseNotifications(SettingsProvider settings) async {
  if (kIsWeb || !Platform.isAndroid || !settings.isEnableCourseNotification) {
    return;
  }
  final source = settings.classScheduleFilePath;
  bool current() =>
      settings.isEnableCourseNotification &&
      settings.classScheduleFilePath == source;
  try {
    final reminders = await settings.generateCourseScheduleReminders();
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification')));
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (await android?.areNotificationsEnabled() != true || !current()) return;
    final exact = await android?.canScheduleExactNotifications() ?? false;
    final pending = await plugin.pendingNotificationRequests();
    if (!current()) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    for (final request in pending.where((request) => request.id > 0)) {
      if (!current()) return;
      await plugin.cancel(request.id);
    }
    for (int i = 0; i < reminders.length; i++) {
      if (!current()) return;
      final lesson = reminders[i];
      final now = DateTime.now();
      if (!lesson.courseStartDateTime.isAfter(now)) continue;
      final before =
          lesson.courseStartDateTime.subtract(const Duration(minutes: 30));
      await plugin.zonedSchedule(
        i + 1,
        '${lesson.courseTitle} | ${lesson.coursePlace}',
        '${lesson.courseStartTimeStr} - ${lesson.courseEndTimeStr}',
        tz.TZDateTime.from(
            before.isAfter(now) ? before : now.add(const Duration(seconds: 1)),
            tz.local),
        NotificationDetails(
            android: AndroidNotificationDetails(
          'course_reminder',
          '上课提醒',
          channelDescription: '在上课前通过通知提醒',
          icon: 'ic_notification',
          importance: Importance.max,
          priority: Priority.high,
          timeoutAfter: lesson.courseDurationInMilliseconds +
              const Duration(minutes: 30).inMilliseconds,
          usesChronometer: true,
          chronometerCountDown: true,
          when: lesson.courseStartDateTime.millisecondsSinceEpoch,
          silent: settings.isSilentNotification,
        )),
        androidScheduleMode: exact
            ? AndroidScheduleMode.alarmClock
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  } catch (_) {
    // Device restrictions must not invalidate a successfully refreshed cache.
  }
}
