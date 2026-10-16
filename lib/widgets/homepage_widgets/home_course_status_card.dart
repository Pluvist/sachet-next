import 'package:sachet/widgets/utils_widgets/miuix_components.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/course_schedule.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/utils/daily_course_status.dart';
import 'package:sachet/utils/home_design.dart';
import 'package:sachet/pages/home_child_pages/free_classroom_page_zf.dart';
import 'package:sachet/widgets/utils_widgets/source_expand_route.dart';
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

  String _time(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final now = widget.now?.call() ?? DateTime.now();
    final status = _courses == null
        ? null
        : DailyCourseStatus.resolve(
            now: now,
            semesterStart: SettingsProvider.semesterStartDateDateTime,
            courses: _courses!,
            overrides: settings.courseRoutineOverrides);
    String title;
    String hint = '';
    String label = '今日课程';
    bool? completed;
    if (_loading) {
      title = '正在读取课表';
    } else if (_failed) {
      title = '课表读取失败';
      hint = '请检查或重新导入课表';
    } else if (status == null) {
      title = '请先导入课表';
      hint = '导入后显示上课状态';
    } else if (status.current != null) {
      title = status.current!.course.title!;
      label = '正在上课';
      completed = false;
    } else if (status.next != null) {
      completed = false;
      title = status.lessons.any((l) => !l.end.isAfter(now)) ? '课间休息' : '尚未上课';
      hint = '下一节 ${_time(status.next!.start)} 开始';
    } else {
      completed = true;
      title = status.lessons.isEmpty ? '今日无课喵~' : '今日课程已结束喵~';
      hint = status.lessons.isEmpty ? '好好享受今天吧' : '今天辛苦啦';
    }
    final current =
        _currentCard(context, status, now, label, title, hint, completed);
    final next = _nextCard(context, status);
    final classroom = _classroomCard(context);
    return LayoutBuilder(builder: (context, constraints) {
      final stacked = constraints.maxWidth < 290 ||
          MediaQuery.textScalerOf(context).scale(16) > 23;
      if (stacked) {
        return Column(
            key: const ValueKey('homeCourseOverview'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              current,
              const SizedBox(height: HomeDesign.gap),
              next,
              const SizedBox(height: HomeDesign.gap),
              classroom,
            ]);
      }
      return IntrinsicHeight(
          child: Row(
              key: const ValueKey('homeCourseOverview'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            Expanded(child: current),
            const SizedBox(width: HomeDesign.gap),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  Expanded(child: next),
                  const SizedBox(height: HomeDesign.gap),
                  Expanded(child: classroom),
                ])),
          ]));
    });
  }

  Widget _line(String text, double size, Color color,
          {int lines = 1, FontWeight weight = FontWeight.normal}) =>
      Tooltip(
          message: text,
          child: Text(text,
              maxLines: lines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: size,
                  height: 1.3,
                  fontWeight: weight,
                  color: color)));

  Widget _surface(
          {required Key key, required Color color, required Widget child}) =>
      MiuixCard(
          key: key,
          margin: EdgeInsets.zero,
          elevation: 0,
          color: color,
          clipBehavior: Clip.hardEdge,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HomeDesign.heroRadius)),
          child: child);

  Widget _currentCard(BuildContext context, DailyCourseStatus? status,
      DateTime now, String label, String title, String hint, bool? completed) {
    final colors = Theme.of(context).colorScheme;
    final ink = colors.onPrimaryContainer;
    final lesson = status?.current;
    return _surface(
        key: const ValueKey('homeCourseStatusCard'),
        color: colors.primaryContainer,
        child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: HomeDesign.heroHeight),
            child: Stack(children: [
              if (completed != null)
                Positioned(
                    right: -22,
                    bottom: -24,
                    width: 150,
                    height: 150,
                    child: CourseStatusIcon(
                        key: ValueKey(completed
                            ? 'courseStatusCompletedIcon'
                            : 'courseStatusGoingIcon'),
                        completed: completed,
                        color: ink.withOpacity(.14))),
              Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _line(label, 12, ink.withOpacity(.7),
                            weight: FontWeight.w600),
                        const SizedBox(height: 12),
                        _line(title, 22, ink,
                            lines: 3, weight: FontWeight.w700),
                        if (lesson != null) ...[
                          const SizedBox(height: 10),
                          _line(lesson.place, 13, ink, lines: 3),
                          const SizedBox(height: 6),
                          _line('${_time(lesson.start)}–${_time(lesson.end)}',
                              12, ink.withOpacity(.75)),
                          const SizedBox(height: 22),
                          FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                  lessonCountdown(lesson.end.difference(now)),
                                  key: const ValueKey('homeCourseCountdown'),
                                  style: TextStyle(
                                      fontSize: 27,
                                      fontWeight: FontWeight.w700,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                      color: ink))),
                        ] else ...[
                          const SizedBox(height: 12),
                          if (hint.isNotEmpty)
                            _line(hint, 12, ink.withOpacity(.75), lines: 3),
                          const SizedBox(height: 72),
                        ],
                      ])),
            ])));
  }

  Widget _nextCard(BuildContext context, DailyCourseStatus? status) {
    final colors = Theme.of(context).colorScheme;
    final next = status?.next;
    final hint = _loading
        ? '正在读取课表'
        : _failed
            ? '课表读取失败'
            : status == null
                ? '导入后显示下一节'
                : status.lessons.isEmpty
                    ? '今天没有课程'
                    : '今天没有下一节课啦';
    return _surface(
        key: const ValueKey('homeNextCourseCard'),
        color: colors.surfaceContainerLow,
        child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _line('下一节课', 12, colors.onSurfaceVariant,
                      weight: FontWeight.w600),
                  const SizedBox(height: 8),
                  _line(next?.course.title ?? '暂无下一节课', 17, colors.onSurface,
                      lines: 2, weight: FontWeight.w700),
                  const SizedBox(height: 6),
                  if (next != null) ...[
                    _line('${_time(next.start)}–${_time(next.end)}', 13,
                        colors.onSurfaceVariant),
                    const SizedBox(height: 5),
                    _line(next.place, 12, colors.onSurfaceVariant, lines: 2),
                  ] else
                    _line(hint, 12, colors.onSurfaceVariant, lines: 2),
                ])));
  }

  Widget _classroomCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Builder(
        builder: (sourceContext) => _surface(
            key: const ValueKey('homeHeroCard'),
            color: colors.surfaceContainerLow,
            child: InkWell(
                onTap: () => expandPage(sourceContext, FreeClassroomPageZF()),
                child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.meeting_room_rounded,
                              size: 30, color: colors.primary),
                          const SizedBox(height: 10),
                          _line('空闲教室', 18, colors.onSurface,
                              weight: FontWeight.w700),
                          const SizedBox(height: 4),
                          _line('快速查询自习室', 12, colors.onSurfaceVariant,
                              lines: 2),
                        ])))));
  }
}
