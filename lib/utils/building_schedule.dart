import 'dart:convert';
import 'package:sachet/models/course_schedule.dart';

enum BuildingRoutine { normal, staggered }

enum TimeRailMode { auto, dual, normal, staggered }

class LessonTime {
  const LessonTime(this.start, this.end);
  final int start;
  final int end;
  String get label => '${formatMinute(start)}–${formatMinute(end)}';
}

String formatMinute(int minute) =>
    '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';

/// School's staggered timetable. Minutes since midnight; no seasonal offset.
class BuildingSchedule {
  static const starts = [
    480,
    535,
    620,
    675,
    840,
    895,
    980,
    1035,
    1155,
    1210,
    1265
  ];
  static const ends = [
    525,
    580,
    665,
    720,
    885,
    940,
    1025,
    1080,
    1200,
    1255,
    1310
  ];
  static BuildingRoutine identify(String? place) {
    final clean = (place ?? '').replaceAll(RegExp(r'\s+'), '');
    return clean.contains('逸夫楼') || clean.contains('信息科技大楼')
        ? BuildingRoutine.staggered
        : BuildingRoutine.normal;
  }

  static LessonTime lesson(int section, BuildingRoutine routine) {
    if (section < 1 || section > 11) throw RangeError.range(section, 1, 11);
    final offset =
        routine == BuildingRoutine.staggered && section <= 8 ? 10 : 0;
    return LessonTime(starts[section - 1] + offset, ends[section - 1] + offset);
  }

  static LessonTime course(
      int firstSection, int length, BuildingRoutine routine) {
    final first = firstSection.clamp(1, 11);
    final last = (first + length.clamp(1, 11) - 1).clamp(first, 11);
    return LessonTime(lesson(first, routine).start, lesson(last, routine).end);
  }

  static String overrideKey(CourseSchedule course, int item) => jsonEncode([
        item,
        course.title ?? '',
        course.place ?? '',
        course.instructor ?? '',
        course.length ?? 2,
      ]);
  static BuildingRoutine resolve(
      CourseSchedule course, int item, Map<String, String> overrides) {
    final value = overrides[overrideKey(course, item)];
    if (value == 'normal') return BuildingRoutine.normal;
    if (value == 'staggered') return BuildingRoutine.staggered;
    return identify(course.place);
  }

  static Set<BuildingRoutine> visibleRoutines(
      TimeRailMode mode, Iterable<BuildingRoutine> active) {
    switch (mode) {
      case TimeRailMode.dual:
        return BuildingRoutine.values.toSet();
      case TimeRailMode.normal:
        return {BuildingRoutine.normal};
      case TimeRailMode.staggered:
        return {BuildingRoutine.staggered};
      case TimeRailMode.auto:
        final result = active.toSet();
        return result.isEmpty ? {BuildingRoutine.normal} : result;
    }
  }
}

/// Keep teaching time proportional; compress only intervals with no lessons
/// in either routine. Crossing courses use the same monotonic mapping.
class SchoolTimeAxis {
  const SchoolTimeAxis(this.sectionHeight);
  final double sectionHeight;
  static const breaks = [(start: 730, end: 840), (start: 1090, end: 1155)];
  double y(int minute) {
    double elapsed = (minute - 480).toDouble();
    for (final gap in breaks) {
      final passed = (minute - gap.start).clamp(0, gap.end - gap.start);
      elapsed -= passed * (1 - 20 / (gap.end - gap.start));
    }
    return elapsed * sectionHeight / 45;
  }

  // Exaggerate the daytime stagger visually without changing lesson times.
  // Fade through the compressed evening break to preserve a monotonic rail.
  double displayY(int minute, BuildingRoutine routine) {
    if (routine == BuildingRoutine.normal) return y(minute);
    final remaining = 1 - (minute - 1090).clamp(0, 65) / 65;
    return y(minute) + 5 * remaining * sectionHeight / 45;
  }

  double displayCourseHeight(LessonTime time, BuildingRoutine routine) =>
      displayY(time.end, routine) - displayY(time.start, routine);
  double get height => y(1310);
  double courseHeight(LessonTime time) => y(time.end) - y(time.start);
}
