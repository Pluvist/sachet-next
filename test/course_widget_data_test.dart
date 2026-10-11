import 'package:flutter_test/flutter_test.dart';
import 'package:sachet/models/app_settings.dart';
import 'package:sachet/models/course_schedule.dart';
import 'package:sachet/services/course_widget_bridge.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/utils/building_schedule.dart';
import 'package:sachet/utils/daily_course_status.dart';

void main() {
  test(
      'Widget payload matches homepage lesson boundaries for all semester days',
      () {
    final settings = AppSettings.fromJson(
        {...defaultAppSettingsConfig, 'semesterStartDate': '2026-10-05'});
    final courses = List.generate(35, (_) => <CourseSchedule>[]);
    final late =
        CourseSchedule(title: '数学', place: '逸夫楼 201', length: 2, weeks: [1, 3]);
    courses[0] = [late];
    courses[4] = [
      CourseSchedule(title: '晚课', place: '信息科技大楼', length: 3, weeks: [1])
    ];
    courses[5] = [
      CourseSchedule(title: '物理', place: '', length: 2, weeks: [1])
    ];
    final payload = buildCourseWidgetData(settings, courses);
    final lessons = payload['lessons'] as List<Map<String, dynamic>>;
    expect(lessons, hasLength(9));
    for (int day = 0; day < 21; day++) {
      final date = DateTime(2026, 10, 5 + day);
      final expected = DailyCourseStatus.resolve(
          now: date,
          semesterStart: DateTime(2026, 10, 5),
          courses: courses,
          overrides: {});
      final actual = lessons
          .where((l) =>
              DateTime.fromMillisecondsSinceEpoch(l['start'])
                      .difference(date)
                      .inMinutes >=
                  0 &&
              DateTime.fromMillisecondsSinceEpoch(l['start'])
                      .difference(date)
                      .inMinutes <
                  1440)
          .toList();
      expect(actual.length, expected.lessons.length);
      for (int i = 0; i < actual.length; i++) {
        expect(actual[i]['start'],
            expected.lessons[i].start.millisecondsSinceEpoch);
        expect(
            actual[i]['end'], expected.lessons[i].end.millisecondsSinceEpoch);
        expect(actual[i]['place'], expected.lessons[i].place);
      }
    }
    expect(lessons.first['group'], lessons[1]['group']);
    settings.courseRoutineOverrides = {
      BuildingSchedule.overrideKey(late, 0): 'normal'
    };
    final corrected =
        buildCourseWidgetData(settings, courses)['lessons'] as List;
    expect(
        DateTime.fromMillisecondsSinceEpoch(corrected.first['start']).hour, 8);
    expect(DateTime.fromMillisecondsSinceEpoch(corrected.first['start']).minute,
        0);
    expect(buildCourseWidgetData(settings, null)['ready'], false);
    expect(
        buildCourseWidgetData(
            settings, List.generate(35, (_) => <CourseSchedule>[]))['ready'],
        true);
  });
}
