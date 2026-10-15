import 'package:sachet/widgets/utils_widgets/glass_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

class WithNavigationBarView extends StatefulWidget {
  /// 使用 NavigationBar 时的 View, 几个一级页面作为 body, 底部 bottomNavigationBar 用于导航
  const WithNavigationBarView({super.key});

  @override
  State<WithNavigationBarView> createState() => _WithNavigationBarViewState();
}

class _WithNavigationBarViewState extends State<WithNavigationBarView> {
  double? _scrollStartOffset;

  /// 水平滑动前，NavBottom 是否是可见的状态
  bool _wasNavBottomVisibleBeforeHorizontalScroll = true;

  bool _onScrollNotification(ScrollNotification notification,
      bool isWideScreenMode, int currentPageIndex) {
    if (isWideScreenMode) {
      return false;
    }

    // 课程表水平滑动翻页时隐藏 NavBottom, 翻页结束显示 NavBottom
    if (notification.metrics.axis == Axis.horizontal) {
      if (currentPageIndex == 1) {
        if (notification is ScrollStartNotification) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.read<ScreenNavProvider>().hideNavBottom();
          });
        } else if (notification is ScrollEndNotification) {
          if (_wasNavBottomVisibleBeforeHorizontalScroll) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.read<ScreenNavProvider>().showNavBottom();
            });
          }
        }
      }
      return false;
    }

    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }

    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse) {
        // 向下滚动立即隐藏 NavBottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.read<ScreenNavProvider>().hideNavBottom();
          _wasNavBottomVisibleBeforeHorizontalScroll = false;
        });
        _scrollStartOffset = null;
      } else if (notification.direction == ScrollDirection.forward) {
        // 开始向上滚动，记录起始位置
        _scrollStartOffset = notification.metrics.pixels;

        // 如果已经滚动到顶部，立即显示 NavBottom
        final bool isAtTop = notification.metrics.pixels <= 0;
        if (isAtTop) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.read<ScreenNavProvider>().showNavBottom();
            _wasNavBottomVisibleBeforeHorizontalScroll = true;
          });
          _scrollStartOffset = null;
        }
      }
    } else if (notification is ScrollUpdateNotification) {
      // 如果正在向上滚动
      if (notification.scrollDelta != null && notification.scrollDelta! < 0) {
        // 如果已经滚动到顶部，或者向上滚动距离超过 30px，则显示 NavBottom
        final bool isAtTop = notification.metrics.pixels <= 0;
        double distance = 0;
        if (_scrollStartOffset != null) {
          distance = _scrollStartOffset! - notification.metrics.pixels;
        }

        if (isAtTop || distance >= 30.0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.read<ScreenNavProvider>().showNavBottom();
            _wasNavBottomVisibleBeforeHorizontalScroll = true;
          });
          _scrollStartOffset = null;
        }
      }
    } else if (notification is ScrollEndNotification) {
      // 滚动结束时清理状态
      _scrollStartOffset = null;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => GlassBackdrop.capture());
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final int currentPageIndex = _routeNames.indexOf(
        context.select<ScreenNavProvider, String>(
            (screenNavProvider) => ScreenNavProvider.currentPage));
    return LayoutBuilder(builder: (context, BoxConstraints constraints) {
      final bool isWideScreenMode = constraints.maxWidth > 600 ||
          constraints.maxWidth > constraints.maxHeight;
      return Scaffold(
        // Let page content paint through the transparent space around the pill.
        extendBody: !isWideScreenMode && Theme.of(context).useMaterial3,
        body: Stack(children: [
          Positioned.fill(
              child: Padding(
                  padding: EdgeInsets.only(
                      top: isWideScreenMode && currentPageIndex >= 0 ? 72 : 0),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) => _onScrollNotification(
                        notification, isWideScreenMode, currentPageIndex),
                    child: RepaintBoundary(
                        key: GlassBackdrop.key,
                        child: currentPageIndex < 0
                            ? const ProfilePage()
                            : RetainedTabBody(
                                index: currentPageIndex,
                                children: const [HomePage(), ClassPage()])),
                  ))),
          if (isWideScreenMode && currentPageIndex >= 0)
            Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: NavTop(
                    destinations: _destinations,
                    routeNames: _routeNames,
                    currentPageIndex: currentPageIndex)),
        ]),
        bottomNavigationBar: !isWideScreenMode && currentPageIndex >= 0
            ? Selector<ScreenNavProvider, bool>(
                selector: (_, provider) => provider.isNavBottomVisible,
                builder: (_, isNavBottomVisible, __) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0.0,
                      end: isNavBottomVisible ? 1.0 : 0.0,
                    ),
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child: NavBottom(
                      destinations: _destinations,
                      routeNames: _routeNames,
                      currentPageIndex: currentPageIndex,
                    ),
                    builder: (context, value, child) {
                      return ClipRect(
                        child: Align(
                          alignment: Alignment.topCenter,
                          heightFactor: value,
                          child: FractionalTranslation(
                            translation: Offset(0, 1 - value),
                            child: child,
                          ),
                        ),
                      );
                    },
                  );
                })
            : null,
      );
    });
  }
}
