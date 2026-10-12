import 'package:sachet/widgets/utils_widgets/miuix_components.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/enums/nav_type.dart';
import 'package:sachet/providers/screen_nav_provider.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/utils/app_global.dart';

class IntroNavTypeScreen extends StatefulWidget {
  /// 引导页：选择导航方式
  const IntroNavTypeScreen({super.key});

  @override
  State<IntroNavTypeScreen> createState() => _IntroNavTypeScreenState();
}

class _IntroNavTypeScreenState extends State<IntroNavTypeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context
        .read<ScreenNavProvider>()
        .setCurrentPage(AppGlobal.startupPage));
  }

  @override
  Widget build(BuildContext context) {
    String navigationType = context.select<SettingsProvider, String>(
        (settngsProvider) => SettingsProvider.navigationType);
    return CustomScrollView(
      slivers: [
        MiuixSliverAppBar(
          pinned: true,
          snap: false,
          floating: false,
          title: Text('选择导航方式'),
        ),
        SliverList.list(
          children: [
            SizedBox(height: 20),
            LayoutBuilder(builder: (context, constraints) {
              // 根据可用宽度决定卡片最大宽度
              final maxWidth = constraints.maxWidth > 600
                  ? constraints.maxWidth / 2.5 // 横屏/宽屏：宽卡片
                  : 180.0; // 竖屏/窄屏：窄卡片
              return Wrap(
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                spacing: 80,
                runSpacing: 20,
                children: [
                  // 抽屉导航栏预览
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildNavCard(
                      maxWidth: maxWidth,
                      title: '抽屉导航栏',
                      icon: Icons.menu,
                      preview: _buildNavDrawerPreview(),
                      isSelected:
                          navigationType == NavType.navigationDrawer.type,
                      onTap: () {
                        context
                            .read<SettingsProvider>()
                            .setNavigationType(NavType.navigationDrawer.type);
                      },
                    ),
                  ),
                  // 底部导航栏预览
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildNavCard(
                      maxWidth: maxWidth,
                      title: '底部导航栏',
                      icon: Icons.home,
                      preview: _buildBottomNavBarPreview(),
                      isSelected:
                          navigationType == NavType.bottomNavigationBar.type,
                      onTap: () {
                        context.read<SettingsProvider>().setNavigationType(
                            NavType.bottomNavigationBar.type);
                      },
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 80),
          ],
        ),
      ],
    );
  }

  Widget _buildNavCard({
    required double maxWidth,
    required String title,
    required IconData icon,
    required Widget preview,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 260,
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            minWidth: 160,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : null),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  child: preview,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 抽屉导航栏预览
  Widget _buildNavDrawerPreview() {
    final theme = Theme.of(context);

    return Row(
      children: [
        // 抽屉区域
        Container(
          color: theme.colorScheme.surface,
          width: 110,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildNavDrawerItem(
                  icon: Icons.calendar_month, label: '课程表', isSelected: true),
              _buildNavDrawerItem(
                  icon: Icons.apps_outlined, label: '主页', isSelected: false),
              _buildNavDrawerItem(
                  icon: Icons.settings_outlined,
                  label: '设置',
                  isSelected: false),
              _buildNavDrawerItem(
                  icon: Icons.info_outline, label: '关于', isSelected: false),
            ],
          ),
        ),

        // 分割线
        VerticalDivider(width: 1.0),

        // 主内容区域
        Expanded(
          child: Container(
            color: theme.colorScheme.surface.withOpacity(0.7),
            alignment: Alignment.center,
            child: const Text(
              '内容',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  /// 抽屉导航栏的一项
  Widget _buildNavDrawerItem({
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 12,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: isSelected ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }

  /// 底部导航栏预览
  Widget _buildBottomNavBarPreview() {
    final theme = Theme.of(context);

    return Column(
      children: [
        // 主内容区域
        Expanded(
          child: Container(
            color: theme.colorScheme.surface,
            alignment: Alignment.center,
            child: const Text(
              '内容',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ),

        Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
                padding: const EdgeInsets.all(5),
                decoration: ShapeDecoration(
                    shape: StadiumBorder(
                        side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                            width: .5)),
                    color: theme.colorScheme.surfaceContainerLow),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.apps_outlined, size: 20),
                                Text('主页', style: TextStyle(fontSize: 10))
                              ])),
                      Container(
                          padding: const EdgeInsets.all(8),
                          decoration: ShapeDecoration(
                              shape: StadiumBorder(),
                              color: theme.colorScheme.surfaceContainerHigh),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.calendar_month_outlined, size: 20),
                            Text('课程表', style: TextStyle(fontSize: 10))
                          ])),
                    ]))),
      ],
    );
  }
}
