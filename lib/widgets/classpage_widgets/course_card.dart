import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/utils/building_schedule.dart';
import 'package:sachet/widgets/classpage_widgets/course_timing_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:sachet/models/course_schedule.dart';
import 'package:sachet/providers/course_card_settings_provider.dart';
import 'package:sachet/utils/course_info_helper.dart';
import 'package:sachet/widgets/classpage_widgets/course_details_bottom_sheet.dart';
import 'package:sachet/widgets/settingspage_widgets/customize_settings_widgets/set_course_card_appearance.dart';
import 'package:provider/provider.dart';

import '../../utils/transform.dart';
import 'course_card_item.dart';

enum CourseCardVariant { normal, compact }

class CourseCard extends StatelessWidget {
  final double cardHeight;
  final double? displayHeight;
  final double? cardBorderRadius;
  final int weekCount;
  final int weekday;
  final int classCount; // classCount 节次（ 1~5 ）
  final List<CourseSchedule> courseScheduleItems;
  final Map? courseColorData;
  final CourseCardVariant variant;

  const CourseCard({
    super.key,
    required this.cardHeight,
    this.displayHeight,
    required this.weekCount,
    required this.weekday,
    required this.classCount,
    required this.courseScheduleItems,
    required this.courseColorData,
    this.cardBorderRadius,
    this.variant = CourseCardVariant.normal,
  });

  const CourseCard.compact({
    super.key,
    required this.cardHeight,
    this.displayHeight,
    required this.weekCount,
    required this.weekday,
    required this.classCount,
    required this.courseScheduleItems,
    required this.courseColorData,
    this.cardBorderRadius,
  }) : variant = CourseCardVariant.compact;

  void _showCourseDetails({
    required BuildContext context,
    required String courseTitle,
    required int weekday,
    required int classcount,
  }) {
    showModalBottomSheet(
      context: context,
      clipBehavior: Clip.hardEdge,
      isScrollControlled: true,
      showDragHandle: false,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      builder: (BuildContext context) {
        final List weeks = CourseInfoHelper.getWeeksOfCourse(
          title: courseTitle,
          courseScheduleItems: courseScheduleItems,
        );
        final List lengths = CourseInfoHelper.getLengths(
          title: courseTitle,
          courseScheduleItems: courseScheduleItems,
        );
        final List instructors = CourseInfoHelper.getInstructors(
          title: courseTitle,
          courseScheduleItems: courseScheduleItems,
        );
        final List places = CourseInfoHelper.getPlaces(
          title: courseTitle,
          courseScheduleItems: courseScheduleItems,
        );
        final List sectionsShowText = [];
        for (final e in lengths) {
          sectionsShowText.add(
            '${classCountToSection[classcount]}~${classCountToSection[classcount]! + e - 1}节次',
          );
        }

        return CourseDetailsBottomSheet(
          courseTitle: courseTitle,
          weekday: weekday,
          weeks: weeks,
          lengths: lengths,
          instructors: instructors,
          places: places,
          sectionsShowText: sectionsShowText,
          timingDetails: Column(children: [
            for (final course
                in courseScheduleItems.where((e) => e.title == courseTitle))
              CourseTimingEditor(
                  course: course, item: (weekday - 1) * 5 + classcount),
          ]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (courseScheduleItems.isEmpty) {
      return SizedBox();
    }

    int index = courseScheduleItems
        .indexWhere((element) => (element.weeks ?? []).contains(weekCount));

    if (index == -1) {
      return SizedBox();
    } else {
      CourseSchedule courseSchedule = courseScheduleItems[index];

      if (courseSchedule.title == null || courseSchedule.title == '') {
        return SizedBox();
      }

      final overrides =
          context.watch<SettingsProvider>().courseRoutineOverrides;
      final routine = BuildingSchedule.resolve(
          courseSchedule, (weekday - 1) * 5 + classCount, overrides);
      final outlineColor = routine == BuildingRoutine.staggered
          ? Theme.of(context).colorScheme.primary
          : null;
      final Widget courseCard;
      switch (variant) {
        case CourseCardVariant.normal:
          courseCard = CourseCardNormal(
              courseColorData: courseColorData,
              courseSchedule: courseSchedule,
              cardHeight: cardHeight,
              displayHeight: displayHeight,
              outlineColor: outlineColor,
              cardBorderRadius: cardBorderRadius,
              onTap: (_) {
                _showCourseDetails(
                  context: context,
                  courseTitle: courseSchedule.title ?? '',
                  weekday: weekday,
                  classcount: classCount,
                );
              });
          break;
        case CourseCardVariant.compact:
          courseCard = CourseCardCompact(
              courseColorData: courseColorData,
              courseSchedule: courseSchedule,
              cardHeight: cardHeight,
              displayHeight: displayHeight,
              outlineColor: outlineColor,
              cardBorderRadius: cardBorderRadius,
              onTap: (_) {
                _showCourseDetails(
                  context: context,
                  courseTitle: courseSchedule.title ?? '',
                  weekday: weekday,
                  classcount: classCount,
                );
              });
          break;
      }

      return courseCard;
    }
  }
}

// Use actual mapped duration in week view, section height in compact views.
class _CourseCardSlot extends StatelessWidget {
  const _CourseCardSlot({
    required this.height,
    required this.margin,
    required this.child,
  });

  final double height;
  final double margin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: double.infinity, height: height, child: child);
  }
}

class CourseCardNormal extends StatelessWidget {
  const CourseCardNormal({
    super.key,
    required this.courseSchedule,
    required this.courseColorData,
    this.cardHeight,
    this.displayHeight,
    this.cardBorderRadius,
    this.onTap,
    this.outlineColor,
  });
  final CourseSchedule courseSchedule;
  final Map? courseColorData;
  final double? cardHeight;
  final double? displayHeight;
  final double? cardBorderRadius;
  final Color? outlineColor;
  final Function? onTap;

  @override
  Widget build(BuildContext context) {
    // ignore: no_leading_underscores_for_local_identifiers
    double? _cardHeight = cardHeight;
    _cardHeight ??= context.select<CourseCardSettingsProvider, double>(
        (courseCardSettingsProvider) => courseCardSettingsProvider.cardHeight);

    // ignore: no_leading_underscores_for_local_identifiers
    double _cardBorderRadius = cardBorderRadius ??
        context.select<CourseCardSettingsProvider, double>(
            (courseCardSettingsProvider) =>
                courseCardSettingsProvider.cardBorderRadius);
    double cardMargin = context.select<CourseCardSettingsProvider, double>(
        (courseCardSettingsProvider) => courseCardSettingsProvider.cardMargin);

    return _CourseCardSlot(
      margin: cardMargin,
      height: displayHeight ?? _cardHeight * (courseSchedule.length ?? 2),
      child: Card(
        clipBehavior: Clip.hardEdge,
        // Card 在 Container 里的边距（在整体上表现为各个卡片间的间隙、间距）
        margin: EdgeInsets.all(cardMargin),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardBorderRadius),
          side: outlineColor == null
              ? BorderSide.none
              : BorderSide(color: outlineColor!, width: 1.5),
        ),
        color: (courseColorData?[courseSchedule.title]).toString().toColor() ??
            Colors.green.shade400,
        child: InkWell(
          onTap: () {
            var onTapFunc = onTap;
            if (onTapFunc != null) {
              onTapFunc(true);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
            child: SingleChildScrollView(
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 课程名称
                  CourseCardItem(
                    text: courseSchedule.title ?? '',
                    coursecardcategory: CourseItemCategory.title,
                  ),

                  // 上课地点
                  CourseCardItem(
                    text: courseSchedule.place ?? '',
                    coursecardcategory: CourseItemCategory.place,
                  ),

                  // 授课教师
                  CourseCardItem(
                    text: courseSchedule.instructor ?? '',
                    coursecardcategory: CourseItemCategory.instructor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CourseCardCompact extends StatelessWidget {
  const CourseCardCompact({
    super.key,
    required this.courseSchedule,
    required this.courseColorData,
    this.cardHeight,
    this.displayHeight,
    this.cardBorderRadius,
    this.onTap,
    this.outlineColor,
  });
  final CourseSchedule courseSchedule;
  final Map? courseColorData;
  final double? cardHeight;
  final double? displayHeight;
  final double? cardBorderRadius;
  final Color? outlineColor;
  final Function? onTap;

  @override
  Widget build(BuildContext context) {
    // ignore: no_leading_underscores_for_local_identifiers
    final double _cardHeight = cardHeight ?? 10;
    final courseCardSettings = context.watch<CourseCardSettingsProvider>();

    // ignore: no_leading_underscores_for_local_identifiers
    final double _cardBorderRadius = cardBorderRadius ??
        context.select<CourseCardSettingsProvider, double>(
            (courseCardSettingsProvider) =>
                courseCardSettingsProvider.cardBorderRadius);
    double cardMargin = 1.0;
    final originalHeight =
        displayHeight ?? _cardHeight * (courseSchedule.length ?? 2);
    final visibleHeight =
        (originalHeight - cardMargin * 2).clamp(0.0, originalHeight);
    return _CourseCardSlot(
      margin: cardMargin,
      height: displayHeight ?? _cardHeight * (courseSchedule.length ?? 2),
      child: Card(
        clipBehavior: Clip.hardEdge,
        margin: EdgeInsets.all(cardMargin),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardBorderRadius),
          side: outlineColor == null
              ? BorderSide.none
              : BorderSide(color: outlineColor!, width: 1.5),
        ),
        color: (courseColorData?[courseSchedule.title]).toString().toColor() ??
            Colors.green.shade400,
        child: InkWell(
          onTap: () {
            final onTapFunc = onTap;
            if (onTapFunc != null) {
              onTapFunc(true);
            }
          },
          child: Builder(builder: (context) {
            // Very dense month overviews use colour marks. A cropped sliver of
            // title text is unreadable; tapping the mark still opens details.
            if (visibleHeight < 12) return const SizedBox.expand();
            final maxLines = (visibleHeight / 11).floor().clamp(1, 100);
            return Padding(
              padding: EdgeInsets.only(top: maxLines > 1 ? 2.0 : 0.0),
              child: Text(
                courseSchedule.title ?? '',
                style: TextStyle(
                  fontWeight:
                      intToFontWeight(courseCardSettings.titleFontWeight),
                  fontSize: 10,
                  color: colorFromHex(courseCardSettings.titleTextColor),
                ),
                textAlign: TextAlign.center,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }),
        ),
      ),
    );
  }
}
