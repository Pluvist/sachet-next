import 'package:flutter/material.dart';
import 'package:sachet/services/course_widget_bridge.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/widgets/utils_widgets/miuix_components.dart';

Future<void> showCourseWidgetPicker(BuildContext context) async {
  final wide = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
          title: const Text('选择小组件布局'),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            MiuixListTile(
                key: const ValueKey('widgetLayoutCompact'),
                leading: const Icon(Icons.widgets_outlined),
                title: const Text('2×2 今日课程'),
                subtitle: const Text('紧凑显示当前或下一节课程'),
                onTap: () => Navigator.pop(dialog, false)),
            MiuixListTile(
                key: const ValueKey('widgetLayoutWide'),
                leading: const Icon(Icons.view_week_outlined),
                title: const Text('4×2 横向课程概览'),
                subtitle: const Text('左侧当前课程，右侧下一节时间与地点'),
                onTap: () => Navigator.pop(dialog, true)),
          ])));
  if (wide == null || !context.mounted) return;
  await CourseWidgetBridge.sync(AppGlobal.appSettings);
  final supported = await CourseWidgetBridge.pin(wide: wide);
  if (!supported && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请长按桌面，在小组件列表中添加 Xachet')));
  }
}
