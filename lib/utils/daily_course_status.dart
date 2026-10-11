import 'package:sachet/models/course_schedule.dart';
import 'package:sachet/utils/building_schedule.dart';

class TimedLesson {
  const TimedLesson(
      {required this.course,
      required this.section,
      required this.start,
      required this.end});
  final CourseSchedule course;
  final int section;
  final DateTime start;
  final DateTime end;
  String get place =>
      (course.place ?? '').trim().isEmpty ? '地点待确认' : course.place!.trim();
}

class DailyCourseStatus {
  const DailyCourseStatus({required this.lessons, this.current, this.next});
  final List<TimedLesson> lessons;
  final TimedLesson? current;
  final TimedLesson? next;

  factory DailyCourseStatus.resolve(
      {required DateTime now,
      required DateTime semesterStart,
      required List<List<CourseSchedule>> courses,
      required Map<String, String> overrides}) {
    final date = DateTime(now.year, now.month, now.day);
    final days = DateTime.utc(now.year, now.month, now.day)
        .difference(DateTime.utc(
            semesterStart.year, semesterStart.month, semesterStart.day))
        .inDays;
    if (days < 0) return const DailyCourseStatus(lessons: []);
    final week = days ~/ 7 + 1;
    final lessons = <TimedLesson>[];
    for (int slot = 0; slot < 5; slot++) {
      final item = (now.weekday - 1) * 5 + slot;
      if (item >= courses.length) continue;
      final index = courses[item].indexWhere((course) =>
          (course.title ?? '').trim().isNotEmpty &&
          (course.weeks ?? []).contains(week));
      if (index < 0) continue;
      final course = courses[item][index];
      final routine = BuildingSchedule.resolve(course, item, overrides);
      final first = slot * 2 + 1;
      final last =
          (first + (course.length ?? 2).clamp(1, 11) - 1).clamp(first, 11);
      for (int section = first; section <= last; section++) {
        final time = BuildingSchedule.lesson(section, routine);
        lessons.add(TimedLesson(
            course: course,
            section: section,
            start: date.add(Duration(minutes: time.start)),
            end: date.add(Duration(minutes: time.end))));
      }
    }
    lessons.sort((a, b) => a.start.compareTo(b.start));
    TimedLesson? current;
    TimedLesson? next;
    for (final lesson in lessons) {
      if (!now.isBefore(lesson.start) && now.isBefore(lesson.end)) {
        current = lesson;
        break;
      }
    }
    for (final lesson in lessons) {
      if (current == null
          ? lesson.start.isAfter(now)
          : !lesson.start.isBefore(current.end)) {
        next = lesson;
        break;
      }
    }
    return DailyCourseStatus(lessons: lessons, current: current, next: next);
  }
}

String lessonCountdown(Duration remaining) {
  final seconds = remaining.inSeconds.clamp(0, 86400);
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(seconds ~/ 3600)}:${two(seconds % 3600 ~/ 60)}:${two(seconds % 60)}';
}
