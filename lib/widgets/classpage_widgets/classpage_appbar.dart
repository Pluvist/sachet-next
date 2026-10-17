import 'package:sachet/widgets/utils_widgets/ios_page_route.dart';
import 'package:sachet/widgets/utils_widgets/liquid_dropdown_menu.dart';
import 'package:sachet/widgets/utils_widgets/miuix_glyph.dart';
import 'package:sachet/widgets/utils_widgets/miuix_popup.dart';
import 'package:sachet/widgets/utils_widgets/miuix_components.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/enums/app_folder.dart';
import 'package:sachet/utils/time_manager.dart';
import 'package:sachet/pages/class_child_pages/course_settings_page.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/providers/class_page_provider.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/widgets/classpage_widgets/export_class_schedule_dialog.dart';
import 'package:sachet/widgets/classpage_widgets/switch_actived_app_file_dialog.dart';
import 'package:sachet/widgets/classpage_widgets/update_class_schedule_zf_dialog.dart';
import 'package:path/path.dart' as path;

class ClassPageAppBar extends StatefulWidget implements PreferredSizeWidget {
  ClassPageAppBar({super.key})
      : preferredSize = Size.fromHeight(kToolbarHeight);

  @override
  final Size preferredSize;

  @override
  State<ClassPageAppBar> createState() => _ClassPageAppBarState();
}

class _ClassPageAppBarState extends State<ClassPageAppBar> {
  Future switchClassSchedules(BuildContext context) async {
    final String classScheduleFilePath =
        context.read<SettingsProvider>().classScheduleFilePath;
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) => SwitchActivedAppFileDialog(
        dialogTitle: '选择课表',
        fileDirectory: AppFolder.classSchedule.name,
        settingsFilePath: classScheduleFilePath,
      ),
    );

    if (!context.mounted) return;

    if (result is String) {
      context.read<SettingsProvider>().setClassScheduleFilePath(result);
    } else if (result == true) {
      // setState 只是为了「切换课表时编辑了当前课表文件的内容，且没有切换到其他课表」。
      // 这种情况下，使用的文件路径没有更新，不会触发 Provider 更新，所以需要刷新一下，重新读取修改后的文件。
      // TODO: 目前只是判断了是否编辑，没有判断是否编辑的文件和使用的课表文件是同一个文件。
      context.read<SettingsProvider>().invalidateCourseData();
    }
  }

  Future showUpdateClassScheduleDialog(BuildContext context) async {
    final bool? result = await showDialog(
      context: context,
      builder: (BuildContext context) => const UpdateClassScheduleZFDialog(),
    );
    if (!context.mounted) return;

    if (result == true) {
      context.read<ClassPageProvider>().pageController.jumpToPage(
            context.read<ClassPageProvider>().pageForWeek(
                weekCountOfToday(SettingsProvider.semesterStartDateDateTime)),
          );
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('注意'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '打开应用时会先显示缓存课表，并在后台自动更新。网络不可用时继续使用上次课表。',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 2),
                Text(
                  '如需立即同步以下变化，也可以手动重新获取：',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),
                Text(
                  '• 完成选课\n'
                  '• 完成体育选课\n'
                  '• 修改选课\n'
                  '• 教师在教务系统调课\n'
                  '• 进入新学期',
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('我知道了'),
            )
          ],
        ),
      );
    }
  }

  /// 去上一周
  void navToLastWeek(BuildContext context) {
    final classPageModel = context.read<ClassPageProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    // classPageModel.decrementCurrentWeekCount();
    // 第一个 -1 表示上一周，第二个 -1 是周次到 pagelist 序号的转换（第一周 => 第0页）
    context.read<ClassPageProvider>().pageController.animateToPage(
        (classPageModel.pageForWeek(classPageModel.currentWeekCount) - 1)
            .clamp(0, 20 ~/ classPageModel.weeksPerPage - 1),
        duration: Duration(milliseconds: settingsProvider.curveDuration),
        curve: curveTypes[settingsProvider.curveType] ?? Easing.standard);
  }

  /// 去下一周
  void navToNextWeek(BuildContext context) {
    final classPageModel = context.read<ClassPageProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    // classPageModel.incrementCurrentWeekCount();
    // +1 表示下一周，-1 是周次到 pagelist 序号的转换（第一周 => 第0页）
    context.read<ClassPageProvider>().pageController.animateToPage(
        (classPageModel.pageForWeek(classPageModel.currentWeekCount) + 1)
            .clamp(0, 20 ~/ classPageModel.weeksPerPage - 1),
        duration: Duration(milliseconds: settingsProvider.curveDuration),
        curve: curveTypes[settingsProvider.curveType] ?? Easing.standard);
  }

  /// 回到本周
  void navToThisWeek(BuildContext context) {
    final settingsProvider = context.read<SettingsProvider>();
    // context.read<ClassPageModel>().resetCurrentWeekCount();
    context.read<ClassPageProvider>().pageController.animateToPage(
        context.read<ClassPageProvider>().pageForWeek(
            weekCountOfToday(SettingsProvider.semesterStartDateDateTime)),
        duration: Duration(milliseconds: settingsProvider.curveDuration),
        curve: curveTypes[settingsProvider.curveType] ?? Easing.standard);
  }

  /// 回到本月
  void navToThisMonth(BuildContext context) {
    final settingsProvider = context.read<SettingsProvider>();

    context.read<ClassPageProvider>().animateToTodayMonth(
        duration: Duration(milliseconds: settingsProvider.curveDuration),
        curve: curveTypes[settingsProvider.curveType]);
  }

  /// 从获取课表默认保存的文件名提取当前学期
  ///
  /// e.g.
  ///
  /// "class_schedule_2025-2026-2_20260404155500" => "2025-2026-2"
  ///
  /// "class_schedule_2025-2026-1_20250825111641" => "2025-2026-1"
  String extractSemester(String filename) {
    final regex = RegExp(r'class_schedule_(\d{4}-\d{4}-\d+)');
    final match = regex.firstMatch(filename);

    if (match != null && match.groupCount >= 1) {
      return match.group(1)!;
    }

    // throw FormatException('无法从文件名 "$filename" 中提取学期信息');
    return filename;
  }

  @override
  Widget build(BuildContext context) {
    // Titles stay readable and non-interactive; month navigation uses swipes.
    final title = Selector<ClassPageProvider, ClassScheduleViewMode>(
        selector: (_, provider) => provider.currentViewMode,
        builder: (_, currentViewMode, __) {
          switch (currentViewMode) {
            case ClassScheduleViewMode.week:
              return FittedBox(
                fit: BoxFit.scaleDown,
                child: Selector<ClassPageProvider, int>(
                    selector: (_, provider) => provider.currentWeekCount,
                    builder: (_, currentWeekCount, __) => Text(
                          MediaQuery.orientationOf(context) ==
                                  Orientation.landscape
                              ? '第 ${(currentWeekCount - 1) ~/ 2 * 2 + 1}–${(currentWeekCount - 1) ~/ 2 * 2 + 2} 周'
                              : '第 $currentWeekCount 周',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500),
                        )),
              );
            case ClassScheduleViewMode.month:
              return FittedBox(
                fit: BoxFit.scaleDown,
                child: Selector<ClassPageProvider, String>(
                    selector: (_, provider) => provider.visibleMonthLabel,
                    builder: (_, label, __) =>
                        Text(label, style: const TextStyle(fontSize: 18))),
              );
            case ClassScheduleViewMode.semester:
              return Selector<SettingsProvider, String>(
                  selector: (_, provider) => provider.classScheduleFilePath,
                  builder: (_, classScheduleFilePath, __) {
                    final String currentSemester = extractSemester(
                      path.basenameWithoutExtension(classScheduleFilePath),
                    );
                    return Text(
                      currentSemester,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  });
          }
        });
    final actions = <Widget>[
      // 切换周/月视图
      Selector<ClassPageProvider, ClassScheduleViewMode>(
          selector: (_, provider) => provider.currentViewMode,
          builder: (_, currentViewMode, __) {
            return ViewModeToggle(
              currentViewMode: currentViewMode,
              onModeChanged: (mode) => context
                  .read<ClassPageProvider>()
                  .updateClassScheduleViewMode(mode),
            );
          }),

      // Weekly arrows remain available for large screens and desktop input.
      Selector<SettingsProvider, bool>(
          selector: (_, settingsProvider) =>
              settingsProvider.isShowPageTurnArrow,
          builder: (_, isShowPageTurnArrow, __) {
            // 是否显示翻页箭头
            if (isShowPageTurnArrow) {
              return Selector<ClassPageProvider, ClassScheduleViewMode>(
                  selector: (_, classPageProvider) =>
                      classPageProvider.currentViewMode,
                  builder: (_, currentViewMode, __) {
                    switch (currentViewMode) {
                      case ClassScheduleViewMode.week:
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const MiuixGlyph(MiuixSymbol.previous),
                              tooltip: MediaQuery.orientationOf(context) ==
                                      Orientation.landscape
                                  ? '前两周'
                                  : '上一周',
                              onPressed: () => navToLastWeek(context),
                            ),
                            IconButton(
                              icon: const MiuixGlyph(MiuixSymbol.next),
                              tooltip: MediaQuery.orientationOf(context) ==
                                      Orientation.landscape
                                  ? '后两周'
                                  : '下一周',
                              onPressed: () => navToNextWeek(context),
                            ),
                          ],
                        );
                      case ClassScheduleViewMode.month:
                      case ClassScheduleViewMode.semester:
                        return const SizedBox.shrink();
                    }
                  });
            } else {
              return SizedBox();
            }
          }),

      // 回到今天（回到本周/回到本月）
      Selector<ClassPageProvider, ClassScheduleViewMode>(
          selector: (_, provider) => provider.currentViewMode,
          builder: (_, currentViewMode, __) {
            switch (currentViewMode) {
              case ClassScheduleViewMode.week:
                return IconButton(
                  icon: const MiuixGlyph(MiuixSymbol.calendar),
                  tooltip: '回到本周',
                  onPressed: () => navToThisWeek(context),
                );
              case ClassScheduleViewMode.month:
                return IconButton(
                  icon: const MiuixGlyph(MiuixSymbol.calendar),
                  tooltip: '回到本月',
                  onPressed: () => navToThisMonth(context),
                );
              case ClassScheduleViewMode.semester:
                return const SizedBox.shrink();
            }
          }),

      // 更多操作：与周次/月份选择器一致，使用 NexioSchedule 的玻璃变形面板
      _MoreActionsMenu(
        onUpdateClassSchedule: () => showUpdateClassScheduleDialog(context),
        onSwitchClassSchedules: () => switchClassSchedules(context),
        onExportClassSchedule: () => showDialog(
          context: context,
          builder: (BuildContext context) => ExportClassScheduleDialog(),
        ),
        onOpenCourseSettings: () async {
          final semesterStartDate = SettingsProvider.semesterStartDate;
          await Navigator.of(context).push(IOSPageRoute(
            maintainState: false,
            builder: (BuildContext context) {
              return const CourseSettingsPage();
            },
          ));
          final newSmesterStartDate = SettingsProvider.semesterStartDate;
          if (semesterStartDate != newSmesterStartDate) {
            if (!context.mounted) {
              return;
            }
            context.read<ClassPageProvider>().updateMonthList();
            context
                .read<ClassPageProvider>()
                .animateToTodayMonth();
          }
        },
      ),
    ];
    return MiuixAppBar(
      compact: true,
      titleSpacing: 12.0,
      title: title,
      actions: actions,
    );
  }
}

/// 更多操作：玻璃按钮就地展开为菜单面板（NexioSchedule 右上角控件形式）。
class _MoreActionsMenu extends StatefulWidget {
  const _MoreActionsMenu({
    required this.onUpdateClassSchedule,
    required this.onSwitchClassSchedules,
    required this.onExportClassSchedule,
    required this.onOpenCourseSettings,
  });
  final VoidCallback onUpdateClassSchedule,
      onSwitchClassSchedules,
      onExportClassSchedule;
  final Future<void> Function() onOpenCourseSettings;

  @override
  State<_MoreActionsMenu> createState() => _MoreActionsMenuState();
}

class _MoreActionsMenuState extends State<_MoreActionsMenu> {
  static const _labels = ['更新课表', '切换课表', '导出课表', '课表设置'];
  static const _symbols = [
    MiuixSymbol.refresh,
    MiuixSymbol.swap,
    MiuixSymbol.share,
    MiuixSymbol.tune,
  ];

  bool _show = false;

  void _run(int index) {
    // 关闭面板后再打开对话框 / 页面，避免菜单留在下一层路由之上。
    setState(() => _show = false);
    switch (index) {
      case 0:
        widget.onUpdateClassSchedule();
      case 1:
        widget.onSwitchClassSchedules();
      case 2:
        widget.onExportClassSchedule();
      case 3:
        widget.onOpenCourseSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LiquidGlassDropdownMenu(
      show: _show,
      itemCount: _labels.length,
      entryLabels: _labels,
      icon: const MiuixGlyph(MiuixSymbol.more, size: 24),
      tooltip: '更多操作',
      semanticLabel: '更多操作',
      leadingBuilder: (index) => MiuixGlyph(_symbols[index],
          size: 22, color: colorScheme.onSurfaceVariant),
      onExpanded: () => setState(() => _show = true),
      onDismissed: () => setState(() => _show = false),
      onSelected: _run,
    );
  }
}

class ViewModeToggle extends StatelessWidget {
  final ClassScheduleViewMode currentViewMode;
  final ValueChanged<ClassScheduleViewMode> onModeChanged;

  /// 切换周/月视图
  const ViewModeToggle({
    super.key,
    required this.currentViewMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return MiuixPopup<ClassScheduleViewMode>(
          icon: const MiuixGlyph(MiuixSymbol.view),
          tooltip: '切换视图',
          itemBuilder: (context) => [
            // 切换到周视图
            PopupMenuItem(
              value: ClassScheduleViewMode.week,
              child: Row(children: [
                MiuixGlyph(
                  MiuixSymbol.view,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                const Text('周'),
              ]),
            ),
            // 切换到月视图
            PopupMenuItem(
              value: ClassScheduleViewMode.month,
              child: Row(children: [
                MiuixGlyph(
                  MiuixSymbol.calendar,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                const Text('月'),
              ]),
            ),
            // 切换到学期视图
            PopupMenuItem(
              value: ClassScheduleViewMode.semester,
              child: Row(children: [
                MiuixGlyph(
                  MiuixSymbol.view,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                const Text('学期'),
              ]),
            ),
          ],
          onSelected: onModeChanged,
        );
      },
    );
  }
}
