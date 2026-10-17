import 'package:sachet/pages/intro_screen/background_setup_page.dart';
import 'package:sachet/widgets/utils_widgets/ios_page_route.dart';
import 'package:sachet/utils/miuix_shapes.dart';
import 'package:sachet/pages/settings_child_pages/course_live_activity_settings_page.dart';
import 'package:sachet/widgets/utils_widgets/miuix_components.dart';
import 'package:sachet/widgets/settingspage_widgets/miuix_settings_list.dart';
import 'package:flutter/material.dart';
import 'package:sachet/models/enums/nav_type.dart';
import 'package:sachet/models/user.dart';
import 'package:sachet/pages/utilspages/zhengfang_jwxt_login_page.dart';
import 'package:sachet/providers/zhengfang_user_provider.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/providers/screen_nav_provider.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/pages/settings_child_pages/dev_settings_page.dart';
import 'package:sachet/pages/settings_child_pages/theme_settings_page.dart';
import 'package:sachet/pages/settings_child_pages/advanced_settings_page.dart';
import 'package:sachet/pages/settings_child_pages/customize_settings_page.dart';
import 'package:sachet/utils/custom_route.dart';
import 'package:sachet/utils/utils_functions.dart';
import 'package:sachet/widgets/settingspage_widgets/nav_type_dropdownmenu.dart';
import 'package:sachet/widgets/settingspage_widgets/settings_section_title.dart';
import 'package:sachet/widgets/settingspage_widgets/startup_page_dropdownmenu.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _navType = SettingsProvider.navigationType;

  /// NavType 是否与进入页面时不一样了
  bool isNavTypeChanged = false;

  void changeNavType(String type) {
    setState(() {
      isNavTypeChanged = (_navType != type);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: !isNavTypeChanged,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        } else {
          if (SettingsProvider.navigationType ==
              NavType.navigationDrawer.type) {
            Navigator.pushNamedAndRemoveUntil(
                context, AppGlobal.startupPage, (Route route) => false);
            context
                .read<ScreenNavProvider>()
                .setCurrentPage(AppGlobal.startupPage);
          } else {
            Navigator.pushNamedAndRemoveUntil(
                context, '/navBarView', (Route route) => false);
          }
        }
      },
      child: Scaffold(
        appBar: MiuixAppBar(
          title: const Text('设置'),
          leading: IconButton(
              onPressed: () {
                if (_navType != SettingsProvider.navigationType) {
                  if (SettingsProvider.navigationType ==
                      NavType.navigationDrawer.type) {
                    Navigator.pushNamedAndRemoveUntil(
                        context, AppGlobal.startupPage, (Route route) => false);
                    context
                        .read<ScreenNavProvider>()
                        .setCurrentPage(AppGlobal.startupPage);
                  } else {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/navBarView', (Route route) => false);
                  }
                } else {
                  Navigator.pop(context);
                }
              },
              icon: Icon(Icons.arrow_back_outlined)),
        ),
        body: MiuixSettingsList(
          searchable: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
              child: SettingsSectionTitle(title: '账号设置'),
            ),

            /// 当前登录用户信息/未登录 卡片
            Selector<ZhengFangUserProvider, bool>(
                selector: (_, zhengfangUserProvider) =>
                    zhengfangUserProvider.isLogin,
                builder: (_, isLogin, __) {
                  if (isLogin) {
                    return _buildLoggedInCard(colorScheme, textTheme);
                  } else {
                    return _buildLoggedOutCard(colorScheme, textTheme);
                  }
                }),

            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
              child: SettingsSectionTitle(title: '软件设置'),
            ),

            // 主题设置
            MiuixListTile(
              leading: const Align(
                widthFactor: 1,
                alignment: Alignment.centerLeft,
                child: Icon(Icons.palette_outlined),
              ),
              title: const Text('应用主题'),
              subtitle: const Text('改变应用的主题颜色'),
              trailing: Icon(Icons.arrow_forward),
              onTap: () => Navigator.push(
                context,
                IOSPageRoute(
                  builder: (context) => const ThemeSettingsPage(),
                ),
              ),
            ),

            // 外观设置
            MiuixListTile(
              leading: const Align(
                widthFactor: 1,
                alignment: Alignment.centerLeft,
                // child: Icon(Icons.colorize_outlined),
                child: Icon(Icons.design_services_outlined),
              ),
              title: const Text('课表外观'),
              subtitle: const Text('定制课表外观'),
              trailing: Icon(Icons.arrow_forward),
              onTap: () => Navigator.push(
                context,
                IOSPageRoute(
                  builder: (context) => const CustomizeSettingsPage(),
                ),
              ),
            ),

            // 启动页设置
            const MiuixListTile(
              leading: Align(
                widthFactor: 1,
                alignment: Alignment.centerLeft,
                // child: Icon(Icons.home_outlined),
                // child: Icon(Icons.rocket_outlined),
                child: Icon(Icons.rocket_launch_outlined),
              ),
              title: Text('启动页'),
              subtitle: Text('设置应用启动时的首页'),
              trailing: StartupPageDropdownMenu(),
            ),

            // 应用导航方式设置
            MiuixListTile(
              leading: Align(
                widthFactor: 1,
                alignment: Alignment.centerLeft,
                child: Icon(Icons.explore_outlined),
              ),
              title: Text('导航方式'),
              subtitle: Text('设置应用导航方式'),
              trailing: NavTypeDropdownmenu(
                onChangeNavType: (type) {
                  changeNavType(type);
                },
              ),
            ),

            MiuixListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text('课程实时活动'),
                subtitle: const Text('课程状态与下课倒计时'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => Navigator.push(
                    context,
                    IOSPageRoute(
                        builder: (_) =>
                            const CourseLiveActivitySettingsPage()))),

            MiuixListTile(
                leading: const Icon(Icons.battery_saver_outlined),
                title: const Text('后台与桌面'),
                subtitle: const Text('后台运行、自启动和桌面课程小组件'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.push(context,
                    IOSPageRoute(builder: (_) => const BackgroundSetupPage()))),

            // 高级设置
            MiuixListTile(
              leading: const Align(
                widthFactor: 1,
                alignment: Alignment.centerLeft,
                // child: Icon(Icons.miscellaneous_services_outlined),
                child: Icon(Icons.settings_suggest_outlined),
              ),
              title: const Text('高级设置'),
              trailing: Icon(Icons.arrow_forward),
              onTap: () => Navigator.push(
                context,
                IOSPageRoute(
                  builder: (context) => const AdvancedSettingsPage(),
                ),
              ),
            ),

            // 开发者设置
            Selector<SettingsProvider, bool>(
                selector: (_, settingsProvider) =>
                    settingsProvider.isEnableDevMode,
                builder: (_, isEnableDevMode, __) {
                  if (isEnableDevMode) {
                    return MiuixListTile(
                      leading: const Align(
                        widthFactor: 1,
                        alignment: Alignment.centerLeft,
                        child: Icon(Icons.developer_mode_outlined),
                      ),
                      title: const Text('开发者设置'),
                      subtitle: const Text('For nerds'),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () => Navigator.push(
                        context,
                        fadeTransitionPageRoute(DevSettingsPage()),
                      ),
                    );
                  } else {
                    return SizedBox();
                  }
                }),
          ],
        ),
      ),
    );
  }

  /// 已登录卡片
  Widget _buildLoggedInCard(ColorScheme colorScheme, TextTheme textTheme) {
    return MiuixCard(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MiuixRadii.panel),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      color: colorScheme.primaryContainer.withOpacity(0.25),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Selector<ZhengFangUserProvider, User>(
                selector: (_, provider) => provider.user,
                builder: (_, user, __) {
                  final studentID = user.studentID;
                  final name = user.name;

                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        child: Icon(Icons.account_box),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('$name', style: textTheme.titleMedium),
                                const SizedBox(width: 8),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (studentID != null && studentID.isNotEmpty)
                              Text(
                                studentID,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => Navigator.push(
                      context,
                      IOSPageRoute(
                        builder: (context) => ZhengFangJwxtLoginPage(),
                      ),
                    ),
                    icon: const Icon(Icons.login_rounded, size: 16),
                    label: const Text('重新登录', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () async {
                    await showLogoutDialog(context);
                  },
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  label: const Text('退出登录', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 未登录卡片
  Widget _buildLoggedOutCard(ColorScheme colorScheme, TextTheme textTheme) {
    return MiuixCard(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MiuixRadii.panel),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      color: colorScheme.surfaceContainerLow,
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(MiuixRadii.control),
                  ),
                  child: Icon(
                    Icons.school_outlined,
                    color: colorScheme.onPrimaryContainer,
                    size: 22,
                    applyTextScaling: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('未登录', style: textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        '登录到教务系统以获取课表等教务信息',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  IOSPageRoute(
                    builder: (context) => ZhengFangJwxtLoginPage(),
                  ),
                ),
                icon: const Icon(Icons.login, size: 18, applyTextScaling: true),
                label: const Text('登录教务系统账号'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
