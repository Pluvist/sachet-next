import 'package:sachet/widgets/utils_widgets/glass_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/nav_destination.dart';
import 'package:sachet/pages/class_page.dart';
import 'package:sachet/pages/home_page.dart';
import 'package:sachet/pages/profile_page.dart';
import 'package:sachet/providers/screen_nav_provider.dart';
import 'package:sachet/widgets/utils_widgets/nav_bottom.dart';
import 'package:sachet/widgets/utils_widgets/nav_top.dart';
import 'package:sachet/widgets/utils_widgets/retained_tab_body.dart';

const List<String> _routeNames = ['/home', '/class'];

const List<NavDestination> _destinations = <NavDestination>[
  NavDestination(
      label: '主页',
      icon: Icon(Icons.apps_outlined),
      selectedIcon: Icon(Icons.apps_outlined),
      page: HomePage(),
      routeName: '/home'),
  NavDestination(
      label: '课程表',
      icon: Icon(Icons.calendar_month_outlined),
      selectedIcon: Icon(Icons.calendar_month),
      page: ClassPage(),
      routeName: '/class'),
];

/// Persistent navigation overlays the page without changing its viewport.
class WithNavigationBarView extends StatelessWidget {
  const WithNavigationBarView({super.key});

  @override
  Widget build(BuildContext context) {
    final currentPageIndex = _routeNames.indexOf(
        context.select<ScreenNavProvider, String>(
            (_) => ScreenNavProvider.currentPage));
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth > 600 ||
          constraints.maxWidth > constraints.maxHeight;
      return Scaffold(
        body: Stack(children: [
          Positioned.fill(
            child: Padding(
              padding:
                  EdgeInsets.only(top: wide && currentPageIndex >= 0 ? 60 : 0),
              child: NotificationListener<ScrollEndNotification>(
                onNotification: (_) {
                  GlassBackdrop.captureWhenIdle();
                  return false;
                },
                child: RepaintBoundary(
                  key: GlassBackdrop.key,
                  child: currentPageIndex < 0
                      ? const ProfilePage()
                      : RetainedTabBody(
                          index: currentPageIndex,
                          children: const [HomePage(), ClassPage()]),
                ),
              ),
            ),
          ),
          if (currentPageIndex >= 0)
            if (wide)
              Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: NavTop(
                      destinations: _destinations,
                      routeNames: _routeNames,
                      currentPageIndex: currentPageIndex))
            else
              Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: NavBottom(
                      destinations: _destinations,
                      routeNames: _routeNames,
                      currentPageIndex: currentPageIndex)),
        ]),
      );
    });
  }
}
