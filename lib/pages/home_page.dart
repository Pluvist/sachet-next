import 'package:sachet/widgets/utils_widgets/source_expand_route.dart';
import 'package:sachet/widgets/utils_widgets/miuix_components.dart';
import 'package:flutter/material.dart';
import 'package:sachet/widgets/utils_widgets/miuix_glyph.dart';
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  final _profileExpansionKey = GlobalKey();
  final _linkExpansionKeys = <String, GlobalKey>{};
  @override
  void initState() {
    super.initState();
    final animate = AppGlobal.homeEntrancePending;
    AppGlobal.homeEntrancePending = false;
    _entrance = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1100),
        value: animate ? 0 : 1);
    if (animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (MediaQuery.disableAnimationsOf(context)) {
          _entrance.value = 1;
        } else {
          _entrance.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Widget _fly(int index, Widget child) =>
      HomeEntrance(animation: _entrance, index: index, child: child);

  Widget _buildFeatureCards(BuildContext context) {
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
    final columns = MediaQuery.textScalerOf(context).scale(15) > 22 ||
            MediaQuery.sizeOf(context).width < 350
        ? 1
        : HomeDesign.columns;
    return Column(
      children: [
        for (int start = 0; start < cards.length; start += columns) ...[
          if (start > 0) const SizedBox(height: HomeDesign.gap),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int column = 0;
                    column <
                        (cards.length - start < columns
                            ? cards.length - start
                            : columns);
                    column++) ...[
                  if (column > 0) const SizedBox(width: HomeDesign.gap),
                  Expanded(
                      child: start + column < cards.length
                          ? _fly(start + column + 3, cards[start + column])
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
            MiuixSliverAppBar(
              pinned: true,
              expandedHeight: HomeDesign.headingHeight,
              toolbarHeight: 56,
              actions: [
                Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _fly(0, Builder(builder: (sourceContext) {
                      final iconKey = _profileExpansionKey;
                      return IconButton(
                        key: const ValueKey('homeProfileButton'),
                        tooltip: '个人中心',
                        iconSize: 26,
                        icon: ExpansionAnchor(
                            key: iconKey,
                            child: const MiuixGlyph(MiuixSymbol.person)),
                        onPressed: () => expandPage(sourceContext,
                            const ProfilePage(openedFromHome: true),
                            sourceKey: iconKey, sourceRadius: 6),
                      );
                    }))),
              ],
              flexibleSpace: LayoutBuilder(builder: (context, constraints) {
                final top = MediaQuery.paddingOf(context).top;
                final progress = ((constraints.maxHeight - top - 56) /
                        (HomeDesign.headingHeight - 56))
                    .clamp(0.0, 1.0);
                return SafeArea(
                    bottom: false,
                    child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding:
                              EdgeInsets.fromLTRB(26, 0, 72, 14 + progress * 4),
                          child: MediaQuery.withClampedTextScaling(
                              maxScaleFactor: 1.4,
                              child: _fly(
                                  0,
                                  PageHeading(HomeDesign.title,
                                      fontSize: 20 +
                                          progress *
                                              (HomeDesign.headingSize - 20)))),
                        )));
              }),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    HomeDesign.padding, 8, HomeDesign.padding, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _fly(1, const HomeCourseStatusCard()),
                    const SizedBox(height: 10),
                    Padding(
                      padding: EdgeInsets.zero,
                      child: _buildFeatureCards(context),
                    ),
                    Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text('打开外部网站',
                            style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant))),
                    SizedBox(height: 6),
                    _fly(
                        12,
                        MiuixCard(
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Column(
                            children: List.generate(openLinkListTileList.length,
                                (index) {
                              return Column(
                                children: [
                                  _fly(index + 12,
                                      Builder(builder: (sourceContext) {
                                    final iconKey =
                                        _linkExpansionKeys.putIfAbsent(
                                            openLinkListTileList[index].link,
                                            () => GlobalKey());
                                    return MiuixListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 4,
                                      ),
                                      leading: Align(
                                        widthFactor: 1,
                                        alignment: Alignment.centerLeft,
                                        child: ExpansionAnchor(
                                            key: iconKey,
                                            child: Icon(
                                              openLinkListTileList[index].icon,
                                              color: primaryColor,
                                            )),
                                      ),
                                      title: Text(
                                        openLinkListTileList[index].title,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500),
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
                                      onTap: () => expandAction(
                                          sourceContext,
                                          () => openLink(
                                              openLinkListTileList[index].link),
                                          sourceKey: iconKey,
                                          sourceRadius: 6),
                                      onLongPress: () => copyToClipboard(
                                        context,
                                        openLinkListTileList[index].link,
                                        prefix: '链接',
                                      ),
                                    );
                                  })),
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
                        )),
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
