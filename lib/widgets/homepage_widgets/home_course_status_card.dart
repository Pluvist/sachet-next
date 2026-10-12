import 'package:sachet/widgets/utils_widgets/miuix_components.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/course_schedule.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/utils/daily_course_status.dart';
import 'package:sachet/utils/home_design.dart';
import 'package:sachet/widgets/homepage_widgets/course_status_icon.dart';

class HomeCourseStatusCard extends StatefulWidget {
  const HomeCourseStatusCard({super.key, this.loadCourses, this.now});
  final Future<List<List<CourseSchedule>>?> Function()? loadCourses;
  final DateTime Function()? now;
  @override
  State<HomeCourseStatusCard> createState() => _HomeCourseStatusCardState();
}

class _HomeCourseStatusCardState extends State<HomeCourseStatusCard>
    with WidgetsBindingObserver {
  String? _source;
  List<List<CourseSchedule>>? _courses;
  bool _loading = false;
  bool _failed = false;
  bool _foreground = true;
  bool _visible = true;
  int? _revision;
  int _generation = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = context.watch<SettingsProvider>();
    _visible = TickerMode.of(context);
    final source = settings.classScheduleFilePath;
    if (_source != source || _revision != settings.courseRevision) {
      _source = source;
      _revision = settings.courseRevision;
      _load();
    }
    _updateTimer();
  }

  void _updateTimer() {
    _timer?.cancel();
    _timer = null;
    if (_visible && _foreground && _courses != null && !_loading) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  void _load() {
    _timer?.cancel();
    final generation = ++_generation;
    _failed = false;
    if ((_source ?? '').isEmpty && widget.loadCourses == null) {
      _courses = null;
      _loading = false;
      return;
    }
    _loading = true;
    final settings = context.read<SettingsProvider>();
    Future<List<List<CourseSchedule>>?> read() async {
      if (widget.loadCourses != null) return widget.loadCourses!();
      return (await settings.loadCourseScheduleData()).courseScheduleItemsList;
    }

    read().then((courses) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _courses = courses;
        _loading = false;
      });
      _updateTimer();
    }).catchError((Object _) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _courses = null;
        _loading = false;
        _failed = true;
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _updateTimer();
    if (_foreground && mounted) setState(() {});
  }

  @override
  void dispose() {
    _generation++;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colors = Theme.of(context).colorScheme;
    final now = widget.now?.call() ?? DateTime.now();
    String title;
    String place = '';
    String countdown = '';
    String hint = '';
    bool? completed;
    if (_loading) {
      title = '正在读取课表';
    } else if (_failed) {
      title = '课表读取失败';
      hint = '请检查或重新导入课表';
    } else if (_courses == null) {
      title = '请先导入课表';
      hint = '导入后显示上课状态';
    } else {
      final status = DailyCourseStatus.resolve(
          now: now,
          semesterStart: SettingsProvider.semesterStartDateDateTime,
          courses: _courses!,
          overrides: settings.courseRoutineOverrides);
      if (status.current != null) {
        completed = false;
        title = status.current!.course.title!;
        place = status.current!.place;
        countdown =
            '剩余 ${lessonCountdown(status.current!.end.difference(now))}';
        hint = status.next == null
            ? '今天没有下一节课啦'
            : '下一节：${status.next!.course.title} · ${status.next!.place}';
      } else if (status.next != null) {
        completed = false;
        title = status.next!.course.title!;
        place = status.next!.place;
        hint =
            '下一节 · ${status.next!.start.hour.toString().padLeft(2, '0')}:${status.next!.start.minute.toString().padLeft(2, '0')} 上课';
      } else {
        completed = true;
        title = status.lessons.isEmpty ? '今日无课喵~' : '今日课程已结束喵~';
      }
    }
    Widget line(String text, double size, {FontWeight? weight}) => Tooltip(
        message: text,
        child: Text(text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: size, fontWeight: weight, color: colors.onSurface)));
    return MiuixCard(
      key: const ValueKey('homeCourseStatusCard'),
      elevation: 0,
      color: colors.surfaceContainerLow,
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: HomeDesign.heroHeight),
        child: Stack(
          children: [
            if (completed == true)
              Positioned(
                right: -20,
                bottom: -26,
                width: 112,
                height: 112,
                child: CourseStatusIcon(
                  key: const ValueKey('courseStatusCompletedIcon'),
                  completed: true,
                  color: Color.alphaBlend(colors.onSurface.withOpacity(0.22),
                      colors.surfaceContainerLow),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(children: [
                Expanded(
                    child: Padding(
                  padding: EdgeInsets.only(right: completed == true ? 40 : 0),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        line(title, HomeDesign.heroSize,
                            weight: FontWeight.bold),
                        if (place.isNotEmpty || countdown.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(children: [
                            Expanded(child: line(place, 12)),
                            if (countdown.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Flexible(child: line(countdown, 12))
                            ],
                          ]),
                        ],
                        if (hint.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          line(hint, 10)
                        ],
                      ]),
                )),
                if (completed == false) ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: CourseStatusIcon(
                        key: const ValueKey('courseStatusGoingIcon'),
                        completed: false,
                        color: colors.onSurface),
                  ),
                ],
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
