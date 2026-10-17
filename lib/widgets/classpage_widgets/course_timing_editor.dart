import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/course_schedule.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/utils/building_schedule.dart';

class CourseTimingEditor extends StatelessWidget {
  const CourseTimingEditor(
      {super.key, required this.course, required this.item});
  final CourseSchedule course;
  final int item;
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final routine =
        BuildingSchedule.resolve(course, item, settings.courseRoutineOverrides);
    final time = BuildingSchedule.course(
        (item % 5) * 2 + 1, course.length ?? 2, routine);
    final override = settings.courseRoutineOverrides[
            BuildingSchedule.overrideKey(course, item)] ??
        'auto';
    final place = (course.place ?? '').trim();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(time.label, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
            '${place.isEmpty ? '教学楼待确认' : place} · ${routine == BuildingRoutine.staggered ? '错峰作息' : '普通作息'}'),
        Text('适用周次：${(course.weeks ?? []).join('、')}',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: override,
          isExpanded: true,
          decoration: const InputDecoration(labelText: '课程作息'),
          items: const [
            DropdownMenuItem(value: 'auto', child: Text('自动识别教学楼')),
            DropdownMenuItem(value: 'normal', child: Text('普通作息')),
            DropdownMenuItem(value: 'staggered', child: Text('错峰作息')),
          ],
          onChanged: (value) {
            if (value != null) settings.setCourseRoutine(course, item, value);
          },
        ),
      ]),
    );
  }
}
