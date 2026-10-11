import 'package:flutter/material.dart';
import 'package:sachet/constants/url_constants.dart';
import 'package:sachet/models/enums/nav_type.dart';
import 'package:sachet/pages/home_child_pages/cultivation_plan_page/cultivation_plan_page_zf.dart';
import 'package:sachet/pages/home_child_pages/exam_time_page_zf.dart';
import 'package:sachet/pages/home_child_pages/gpa_page_zf.dart';
import 'package:sachet/pages/home_child_pages/grade_page_zf.dart';
import 'package:sachet/pages/home_child_pages/reserve_textbook_page/reserve_textbook_page_zf.dart';
import 'package:sachet/pages/home_child_pages/score_pdf_page_zf.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/providers/screen_nav_provider.dart';
import 'package:sachet/pages/home_child_pages/free_classroom_page_zf.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/utils/utils_functions.dart';
import 'package:sachet/widgets/homepage_widgets/card_widget.dart';
import 'package:sachet/widgets/utils_widgets/nav_drawer.dart';
import 'package:provider/provider.dart';
import 'package:sachet/widgets/utils_widgets/page_heading.dart';
import 'package:sachet/utils/home_design.dart';
import 'package:sachet/widgets/homepage_widgets/home_course_status_card.dart';
import 'package:sachet/pages/profile_page.dart';

class OpenLinkListTile {
  String title;
  String subtitle;
  IconData icon;
  String link;
  OpenLinkListTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.link,
  });
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget _buildFeatureCards() {
    final cards = <Widget>[
      CardWidget(
          title: '培养方案',
          icon: Icons.school_rounded,
          page: CultivationPlanPageZF()),
      CardWidget(
          title: '教材预订', icon: Icons.book, page: ReserveTextbookPageZF()),
      CardWidget(
          title: '考试时间', icon: Icons.schedule_rounded, page: ExamTimePageZF()),
      CardWidget(
          title: '成绩查询', icon: Icons.history_edu_outlined, page: GradePageZF()),
      CardWidget(
          title: '绩点排名', icon: Icons.leaderboard_rounded, page: GPAPageZF()),
      CardWidget(
          title: '成绩单',
          icon: Icons.description_rounded,
          page: ScorePdfPageZF()),
      CardWidget(
          title: '馆藏检索', icon: Icons.local_library, link: libraryLookUpUrl),
      const CardWidget(
          title: '大物实验',
          icon: Icons.science,
          link: collegePhysicsExperimentUrl),
      const CardWidget(
          title: '校园网认证', icon: Icons.wifi, link: campusNetworkAuthUrl),
    ];
    return Column(
      children: [
        for (int start = 0;
            start < cards.length;
            start += HomeDesign.columns) ...[
          if (start > 0) const SizedBox(height: HomeDesign.gap),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int column = 0; column < HomeDesign.columns; column++) ...[
                  if (column > 0) const SizedBox(width: HomeDesign.gap),
                  Expanded(
                      child: start + column < cards.length
                          ? cards[start + column]
                          : const SizedBox()),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    OpenLinkListTile campusNetworkSelfService = OpenLinkListTile(
      title: '校园网自助服务系统',
      subtitle: '踢出占线设备',
      // icon: Icons.wifi_protected_setup_outlined,
      icon: Icons.devices,
      link: campusNetworkSelfServiceUrl,
    );
    OpenLinkListTile xinXiMenHu = OpenLinkListTile(
      title: '信息门户',
      subtitle: xinXiMenHuBaseUrl,
      // Icons.explore
      // icon: Icons.public,
      icon: Icons.domain_outlined,
      link: xinXiMenHuBaseUrl,
    );
    OpenLinkListTile newJwxt = OpenLinkListTile(
      title: '新教务系统',
      subtitle: newJwxtBaseUrl,
      icon: Icons.public,
      link: newJwxtBaseUrl,
    );
    OpenLinkListTile jwxt = OpenLinkListTile(
      title: '旧教务系统',
      subtitle: jwxtBaseUrlHttps,
      icon: Icons.domain_outlined,
      link: jwxtBaseUrlHttps,
    );
    List<OpenLinkListTile> openLinkListTileList = [
      OpenLinkListTile(
          title: '湘大校历',
          subtitle: '查看学校校历',
          icon: Icons.date_range,
          link: xtuSchoolCalendarUrl),
      OpenLinkListTile(
          title: '湘大新闻',
          subtitle: '浏览校园新闻',
          icon: Icons.newspaper,
          link: xtuNewsUrl),
      OpenLinkListTile(
          title: '湘大邮箱',
          subtitle: '打开学校邮箱',
          icon: Icons.email,
          link: xtuMailUrl),
      campusNetworkSelfService,
      xinXiMenHu,
      newJwxt,
      jwxt,
    ];

    return PopScope(
      canPop: !TickerMode.of(context) || AppGlobal.startupPage == '/home',
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop || !TickerMode.of(context)) {
          return;
        }
        if (SettingsProvider.navigationType == NavType.navigationDrawer.type) {
          Navigator.of(context).pushReplacementNamed(AppGlobal.startupPage);
        }
        context.read<ScreenNavProvider>().setCurrentPageToStartupPage();
      },
      child: Scaffold(
        drawer: SettingsProvider.navigationType == NavType.navigationDrawer.type
            ? myNavDrawer
            : null,
        body: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              toolbarHeight: HomeDesign.headingHeight,
              title: const ConfiguredPageHeading(HomeDesign.title),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: HomeDesign.padding),
                  child: IconButton.filledTonal(
                    key: const ValueKey('homeProfileButton'),
                    tooltip: '个人中心',
                    iconSize: 28,
                    icon: const Icon(Icons.person_outline_rounded),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProfilePage(openedFromHome: true),
                      ),
                    ),
                  ),
                ),
              ],
              // floating: true, // 上滑隐藏，下滑立即出现
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    HomeDesign.padding, 8, HomeDesign.padding, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const HomeCourseStatusCard(),
                    const SizedBox(height: 10),
                    Card(
                      key: const ValueKey('homeHeroCard'),
                      elevation: 0,
                      shadowColor: primaryColor.withOpacity(0.4),
                      clipBehavior: Clip.hardEdge,
                      color: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FreeClassroomPageZF(),
                          ),
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                              minHeight: HomeDesign.heroHeight),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '空闲教室',
                                        style: TextStyle(
                                          fontSize: HomeDesign.heroSize,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onPrimary,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '快速查询自习室',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.onPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.meeting_room_rounded,
                                  size: 44,
                                  color: colorScheme.onPrimary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _buildFeatureCards(),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4.0, 24.0, 4.0, 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 4,
                            height: 16,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '打开外部网站',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 6),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Column(
                        children:
                            List.generate(openLinkListTileList.length, (index) {
                          return Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 4,
                                ),
                                leading: Align(
                                  widthFactor: 1,
                                  alignment: Alignment.centerLeft,
                                  child: Icon(
                                    openLinkListTileList[index].icon,
                                    color: primaryColor,
                                  ),
                                ),
                                title: Text(
                                  openLinkListTileList[index].title,
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  openLinkListTileList[index].subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                trailing: Icon(
                                  // Icons.chevron_right,
                                  Icons.chevron_right_rounded,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                onTap: () =>
                                    openLink(openLinkListTileList[index].link),
                                onLongPress: () => copyToClipboard(
                                  context,
                                  openLinkListTileList[index].link,
                                  prefix: '链接',
                                ),
                              ),
                              // 添加分割线，除了最后一个
                              if (index != openLinkListTileList.length - 1)
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  indent: 60,
                                  endIndent: 40,
                                  color: colorScheme.outlineVariant,
                                ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
