import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:sachet/models/course_schedule.dart';
import 'package:sachet/models/enums/app_folder.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/providers/zhengfang_user_provider.dart';
import 'package:sachet/services/zhengfang_jwxt/auto_login_retry.dart';
import 'package:sachet/services/zhengfang_jwxt/class_schedule/class_schedule_service.dart';
import 'package:sachet/services/zhengfang_jwxt/class_schedule/fetch_class_schedule.dart';
import 'package:sachet/services/zhengfang_jwxt/class_schedule/parse_class_schedule.dart';
import 'package:sachet/utils/storage/path_provider_utils.dart';

/// One refresh at a time; a failed fetch never reaches the cache commit.
/// Callbacks also make failure, concurrency and account changes testable.
class CourseRefreshRunner<T> {
  Future<bool>? _pending;
  Future<bool> run({
    required Future<T> Function() fetch,
    required bool Function() stillCurrent,
    required Future<void> Function(T) commit,
    Duration timeout = const Duration(seconds: 45),
  }) {
    return _pending ??= _run(fetch, stillCurrent, commit, timeout);
  }

  Future<bool> _run(Future<T> Function() fetch, bool Function() stillCurrent,
      Future<void> Function(T) commit, Duration timeout) async {
    try {
      final data = await Future<T>.sync(fetch).timeout(timeout);
      if (!stillCurrent()) return false;
      await commit(data);
      return true;
    } catch (_) {
      // Offline/session/parse/storage errors retain the last selected cache.
      return false;
    } finally {
      _pending = null;
    }
  }
}

class RefreshedCourseData {
  const RefreshedCourseData(this.courses, this.semester, this.semesterStart);
  final List<List<CourseSchedule>> courses;
  final String semester;
  final String? semesterStart;
}

class AutomaticCourseRefresh {
  final _runner = CourseRefreshRunner<RefreshedCourseData>();

  Future<bool> refresh(SettingsProvider settings, ZhengFangUserProvider user,
      {required bool Function() isAlive}) async {
    await user.init();
    if (!isAlive() || !user.isLogin) return false;
    final account = user.user.studentID;
    final previousPath = settings.classScheduleFilePath;
    final previousColorPath = settings.courseColorFilePath;
    final previousDate = SettingsProvider.semesterStartDate;
    bool stillCurrent() =>
        isAlive() &&
        user.isLogin &&
        user.user.studentID == account &&
        settings.classScheduleFilePath == previousPath &&
        settings.courseColorFilePath == previousColorPath &&
        SettingsProvider.semesterStartDate == previousDate;
    final result = await _runner.run(
      stillCurrent: stillCurrent,
      fetch: () async {
        const service = ClassScheduleService();
        final term = await service.getClassScheduleSemesters(
            cookie: ZhengFangUserProvider.cookie, zhengFangUserProvider: user);
        if (term.$1 == null || term.$3 == null) {
          throw const FormatException('当前学期不存在');
        }
        final json = await withAutoLoginRetry(
            initialCookie: ZhengFangUserProvider.cookie,
            zhengFangUserProvider: user,
            action: (cookie) => fetchClassScheduleZF(
                cookie: cookie,
                semesterYear: term.$1!,
                semesterIndex: term.$3!));
        final courses = await compute(parseAutomaticCourses, json);
        final index = {'3': '1', '12': '2', '16': '3'}[term.$3];
        if (index == null) throw const FormatException('未知学期');
        final semester = '${term.$1}-${int.parse(term.$1!) + 1}-$index';
        String? start;
        // Same-semester refresh respects the user's manually adjusted date.
        if (previousPath.isEmpty ||
            !path.basename(previousPath).contains(semester)) {
          start = (await service.getSemesterStartDate(
                  cookie: ZhengFangUserProvider.cookie))
              .$1;
        }
        return RefreshedCourseData(courses, semester, start);
      },
      commit: (data) async {
        final existing =
            (await settings.loadCourseScheduleData()).courseScheduleItemsList;
        if (!stillCurrent()) return;
        if (jsonEncode(existing) == jsonEncode(data.courses) &&
            (data.semesterStart == null ||
                data.semesterStart == previousDate)) {
          return; // No new files, random colours or rebuilds for identical data.
        }
        final colors = Map<String, dynamic>.of(
            await CachedDataStorage.getDecodedMap(previousColorPath));
        final titles = data.courses
            .expand((slot) => slot)
            .map((course) => course.title)
            .whereType<String>()
            .toSet()
            .toList();
        final allocated = randomAllocateColorToCourse(courseTitleList: titles);
        for (final title in titles) {
          colors.putIfAbsent(title, () => allocated[title]);
        }
        final root = await CachedDataStorage.getPath();
        final suffix =
            '${data.semester}_${DateTime.now().microsecondsSinceEpoch}.json';
        final scheduleFile = File(path.join(
            root, AppFolder.classSchedule.name, 'class_schedule_auto_$suffix'));
        final colorFile = File(path.join(
            root, AppFolder.courseColor.name, 'course_color_auto_$suffix'));
        // Stage separate new files, leaving the previous good cache untouched.
        await writeAtomicCourseCache(scheduleFile, jsonEncode(data.courses));
        await writeAtomicCourseCache(colorFile, jsonEncode(colors));
        if (!stillCurrent()) return;
        await settings.applyRefreshedSchedule(
            schedulePath: scheduleFile.path,
            colorPath: colorFile.path,
            colors: colors,
            semesterStart: data.semesterStart);
        // Keep the previous snapshot as fallback; bound unattended cache growth.
        for (final folder in [scheduleFile.parent, colorFile.parent]) {
          final files = await folder
              .list()
              .where((entry) =>
                  entry is File &&
                  path.basename(entry.path).contains('_auto_') &&
                  entry.path.endsWith('.json'))
              .cast<File>()
              .toList();
          files.sort((a, b) => b.path.compareTo(a.path));
          for (final file in files.skip(2)) {
            if (file.path != settings.classScheduleFilePath &&
                file.path != settings.courseColorFilePath) {
              try {
                await file.delete();
              } catch (_) {/* Cache cleanup is optional. */}
            }
          }
        }
      },
    );
    debugPrint(
        'Automatic timetable check: ${result ? 'completed' : 'cache retained'}');
    return result;
  }
}

Future<List<List<CourseSchedule>>> parseAutomaticCourses(Map json) async {
  if (json['kbList'] is! List || json['xsxx'] is! Map) {
    throw const FormatException('无效课表响应');
  }
  // A legitimate empty term is distinct from a malformed/login response.
  if ((json['kbList'] as List).isEmpty) {
    return List.generate(35, (_) => <CourseSchedule>[]);
  }
  final parsed = await parseClassScheduleZF(json);
  final courses = (parsed as List<List<CourseSchedule>>);
  if (courses.length != 35) throw const FormatException('无效课表');
  for (final course in courses.expand((slot) => slot)) {
    if ((course.title ?? '').isEmpty ||
        (course.weeks ?? []).isEmpty ||
        (course.length ?? 0) < 1 ||
        (course.length ?? 0) > 11) {
      throw const FormatException('无效课程');
    }
  }
  return courses;
}

Future<void> writeAtomicCourseCache(File file, String data) async {
  await file.parent.create(recursive: true);
  final temporary = File('${file.path}.tmp');
  try {
    await temporary.writeAsString(data, flush: true);
    await temporary.rename(file.path);
  } finally {
    if (await temporary.exists()) await temporary.delete();
  }
}
