import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sachet/constants/app_constants.dart';
import 'package:sachet/models/app_settings.dart';
import 'package:sachet/models/course_schedule.dart';
import 'package:sachet/utils/daily_course_status.dart';

/// Publishes the same resolved lessons as the homepage. Android only selects by
/// timestamp; it does not implement a second set of building/section rules.
Map<String, dynamic> buildCourseWidgetData(
    AppSettings settings, List<List<CourseSchedule>>? courses) {
  final semester = DateTime.tryParse(settings.semesterStartDate ?? '') ??
      constSemesterStartDate;
  final lessons = <Map<String, dynamic>>[];
  if (courses != null) {
    final weeks = courses
        .expand((slot) => slot)
        .expand((c) => c.weeks ?? [])
        .whereType<int>()
        .where((w) => w > 0 && w <= 60)
        .toSet();
    for (final week in weeks) {
      for (int day = 0; day < 7; day++) {
        final date = DateTime(
            semester.year, semester.month, semester.day + (week - 1) * 7 + day);
        final status = DailyCourseStatus.resolve(
            now: date,
            semesterStart: semester,
            courses: courses,
            overrides: settings.courseRoutineOverrides ?? {});
        for (final lesson in status.lessons) {
          final slot =
              courses.indexWhere((list) => list.contains(lesson.course));
          lessons.add({
            'title': lesson.course.title,
            'place': lesson.place,
            'start': lesson.start.millisecondsSinceEpoch,
            'end': lesson.end.millisecondsSinceEpoch,
            'group': '${date.toIso8601String()}:$slot',
          });
        }
      }
    }
  }
  lessons.sort((a, b) => (a['start'] as int).compareTo(b['start'] as int));
  return {
    'ready': courses != null,
    'liveActivityEnabled': (settings.isEnableCourseLiveActivity ?? true) &&
        settings.hasReadDisclaimer == true,
    'semester': semester.toIso8601String(),
    'themeMode': settings.themeMode ?? 0,
    'lessons': lessons
  };
}

String _encodeWidgetData(
        ({AppSettings settings, List<List<CourseSchedule>>? courses}) input) =>
    jsonEncode(buildCourseWidgetData(input.settings, input.courses));

class CourseWidgetBridge {
  static const channel = MethodChannel('xachet/course_widget');
  static int _generation = 0;
  static AppSettings? _settings;
  static String? _lastKey;
  static Timer? _scheduled;
  static void refreshIfSelected(String path) {
    final settings = _settings;
    if (settings != null && settings.classScheduleFilePath == path) {
      sync(settings, force: true);
    }
  }

  static Future<void> sync(AppSettings settings, {bool force = false}) async {
    _settings = settings;
    if (kIsWeb || !Platform.isAndroid) return;
    final snapshot = AppSettings.fromJson(settings.toJson());
    final key = jsonEncode([
      snapshot.classScheduleFilePath,
      snapshot.semesterStartDate,
      snapshot.courseRoutineOverrides,
      snapshot.themeMode,
      snapshot.isEnableCourseLiveActivity,
      snapshot.hasReadDisclaimer
    ]);
    if (!force && _lastKey == key) return;
    _lastKey = key;
    final generation = ++_generation;
    _scheduled?.cancel();
    _scheduled = Timer(const Duration(milliseconds: 180),
        () => _publish(snapshot, generation));
  }

  static Future<void> _publish(AppSettings snapshot, int generation) async {
    try {
      List<List<CourseSchedule>>? courses;
      final path = snapshot.classScheduleFilePath ?? '';
      if (path.isNotEmpty && await File(path).exists()) {
        final decoded = jsonDecode(await File(path).readAsString());
        if (decoded is List && decoded.length == 35) {
          courses = decoded
              .map((slot) => (slot as List)
                  .map((entry) =>
                      CourseSchedule.fromJson(Map<String, dynamic>.from(entry)))
                  .toList())
              .toList();
        }
      }
      if (generation != _generation) return;
      final data = await compute(
          _encodeWidgetData, (settings: snapshot, courses: courses));
      if (generation != _generation) return;
      await channel.invokeMethod<void>('sync', data);
    } catch (error) {
      if (generation == _generation) _lastKey = null;
      debugPrint('Course widget sync: $error');
    }
  }

  static Future<bool> pin({bool wide = false}) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      return await channel.invokeMethod<bool>(
              'pin', wide ? 'wide' : 'compact') ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
