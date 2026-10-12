import 'package:sachet/widgets/utils_widgets/miuix_components.dart';
import 'package:sachet/widgets/settingspage_widgets/miuix_settings_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sachet/pages/about_page.dart';
import 'package:sachet/pages/settings_page.dart';
import 'package:sachet/pages/utilspages/zhengfang_jwxt_login_page.dart';
import 'package:sachet/providers/screen_nav_provider.dart';
import 'package:sachet/providers/zhengfang_user_provider.dart';
import 'package:sachet/utils/utils_functions.dart';
import 'package:sachet/widgets/settingspage_widgets/settings_section_title.dart';
import 'package:sachet/widgets/utils_widgets/page_heading.dart';
import 'package:sachet/utils/home_design.dart';
import 'package:sachet/services/course_widget_bridge.dart';
import 'package:sachet/utils/app_global.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.openedFromHome = false});
  final bool openedFromHome;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.openedFromHome,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        context.read<ScreenNavProvider>().setCurrentPageToStartupPage();
      },
      child: Scaffold(
        appBar: MiuixAppBar(
          leading: widget.openedFromHome ? const BackButton() : null,
          toolbarHeight: HomeDesign.headingHeight,
          title: const ConfiguredPageHeading('我'),
        ),
        body: MiuixSettingsList(
          physics: const BouncingScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
              child: SettingsSectionTitle(title: '新教务系统'),
            ),

            // 正方教务系统
            Selector<ZhengFangUserProvider, ({String name, String id})>(
              selector: (_, zhengFangUserProvider) => (
                name: zhengFangUserProvider.user.name ?? '未登录',
                id: zhengFangUserProvider.user.studentID ?? '点击登录'
              ),
              builder: (_, data, __) {
                return MiuixListTile(
                  leading: Align(
                    widthFactor: 1,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16)),
                      child: Icon(Icons.person_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 30),
                    ),
                  ),
                  title: Text(data.name),
                  subtitle: data.id.isEmpty ? null : Text(data.id),
                  trailing: IconButton(
                    onPressed: () async {
                      await showLogoutDialog(context);
                    },
                    tooltip: '退出登录',
                    icon: Icon(Icons.logout_outlined),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ZhengFangJwxtLoginPage(),
                    ),
                  ),
                );
              },
            ),

            Divider(indent: 16, endIndent: 16),
            MiuixListTile(
              leading: const Icon(Icons.widgets_outlined),
              title: const Text('桌面课程小组件'),
              subtitle: const Text('在桌面显示当前或下一节课程'),
              onTap: () async {
                await CourseWidgetBridge.sync(AppGlobal.appSettings);
                final supported = await CourseWidgetBridge.pin();
                if (!supported && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('请长按桌面，在小组件列表中添加 Sachet Next'),
                  ));
                }
              },
            ),

            MiuixListTile(
              title: Text('设置'),
              subtitle: Text('主题、课表外观与偏好'),
              trailing: Icon(Icons.chevron_right_rounded),
              leading: Icon(Icons.settings_outlined),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => const SettingsPage(),
                ),
              ),
            ),
            MiuixListTile(
              title: Text('关于'),
              subtitle: Text('版本与应用信息'),
              trailing: Icon(Icons.chevron_right_rounded),
              leading: Icon(Icons.info_outline),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutPage()),
              ),
            )
          ],
        ),
      ),
    );
  }
}
