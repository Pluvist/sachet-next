import 'package:sachet/widgets/utils_widgets/miuix_components.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/pages/settings_child_pages/palette_settings_page.dart';
import 'package:sachet/utils/utils_functions.dart';
import 'package:intl/intl.dart';
import '../settings_child_pages/customize_settings_page.dart';
import '../settings_child_pages/color_settings_page.dart';

class CourseSettingsPage extends StatelessWidget {
  const CourseSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MiuixAppBar(title: Text('课表设置')),
      body: ListView(
        children: [
          const MiuixListTile(
            leading: Icon(Icons.schedule_outlined),
            title: Text('时间栏'),
            subtitle: Text('始终显示：左侧普通作息、右侧错峰作息'),
          ),
          const MiuixListTile(
              title: Text('错峰作息'),
              subtitle:
                  Text('逸夫楼、信息科技大楼第 1–8 节晚 10 分钟；点击课程可纠正作息。午休与晚间休息压缩显示。')),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '日期设置',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          MiuixListTile(
            leading: const Align(
                widthFactor: 1,
                alignment: Alignment.centerLeft,
                child: Icon(Icons.edit_calendar_outlined)),
            title: const Text('学期开始日期'),
            subtitle: Selector<SettingsProvider, String>(
                selector: (_, settingsProvider) =>
                    SettingsProvider.semesterStartDate,
                builder: (_, semesterStartDate, __) {
                  return Text(
                    DateFormat('yyyy-MM-dd')
                        .format(SettingsProvider.semesterStartDateDateTime),
                  );
                }),
            onTap: () => selectSemesterStartDate(context),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '外观设置',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          // 课表外观
          MiuixListTile(
            leading: const Align(
              widthFactor: 1,
              alignment: Alignment.centerLeft,
              // child: Icon(Icons.colorize_outlined),
              child: Icon(Icons.design_services_outlined),
            ),
            title: const Text('课表外观'),
            subtitle: const Text('定制课程安排卡片外观'),
            trailing: Icon(Icons.arrow_forward_outlined),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) {
                    return const CustomizeSettingsPage();
                  },
                ),
              );
            },
          ),
          // 配色管理
          MiuixListTile(
            leading: const Align(
              widthFactor: 1,
              alignment: Alignment.centerLeft,
              // child: Icon(Icons.colorize_outlined),
              child: Icon(Icons.format_color_fill_outlined),
            ),
            title: const Text('配色调整'),
            subtitle: const Text('调整课程对应的颜色'),
            trailing: Icon(Icons.arrow_forward_outlined),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) {
                    return const ColorSettingsPage();
                  },
                ),
              );
            },
          ),
          // 配色管理
          MiuixListTile(
            leading: const Align(
              widthFactor: 1,
              alignment: Alignment.centerLeft,
              // child: Icon(Icons.colorize_outlined),
              child: Icon(Icons.palette_outlined),
            ),
            title: const Text('配色管理'),
            subtitle: const Text('修改、创建配色方案'),
            trailing: Icon(Icons.arrow_forward_outlined),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) {
                    return const PaletteSettingsPage();
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
