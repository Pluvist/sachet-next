// Adapted from NexioSchedule ScheduleBottomBar.kt. AGPL-3.0-only.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/nav_destination.dart';
import 'package:sachet/providers/screen_nav_provider.dart';
import 'package:sachet/widgets/utils_widgets/glass_backdrop.dart';
import 'package:sachet/widgets/utils_widgets/miuix_glyph.dart';
import 'package:sachet/widgets/utils_widgets/nexio_bottom_tabs.dart';

const double kNavBottomHeight = 56;
const double kNavBottomWidthFactor = .42;
const double kNavBottomSelectorHeight = 48;
const double kNavBottomPadding = 4;

class NavBottom extends StatelessWidget {
  const NavBottom(
      {super.key,
      required this.destinations,
      required this.routeNames,
      required this.currentPageIndex});
  final List<NavDestination> destinations;
  final List<String> routeNames;
  final int currentPageIndex;
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => GlassBackdrop.captureWhenIdle());
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mask = dark ? Colors.black : Colors.white;
    final colors = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final width = MediaQuery.sizeOf(context).width *
        (destinations.length == 2 ? .42 : .63);
    return Stack(children: [
      Positioned.fill(
          child: IgnorePointer(
              child: DecoratedBox(
                  key: const ValueKey('floatingNavBottomMask'),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                        mask.withOpacity(0),
                        mask.withOpacity(.94),
                        mask
                      ],
                          stops: const [
                        0,
                        .75,
                        1
                      ]))))),
      Padding(
          padding: EdgeInsets.only(top: 24, bottom: bottom > 0 ? bottom : 24),
          child: Center(
              heightFactor: 1,
              child: SizedBox(
                  width: width,
                  child: NexioBottomTabs(
                    key: const ValueKey('floatingNavToolbar'),
                    selected: currentPageIndex,
                    onSelected: (i) {
                      if (i != currentPageIndex) {
                        context
                            .read<ScreenNavProvider>()
                            .setCurrentPage(routeNames[i]);
                      }
                    },
                    children: [
                      for (var i = 0; i < destinations.length; i++)
                        Tooltip(
                            message: destinations[i].label,
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  MiuixGlyph(
                                      routeNames[i] == '/home'
                                          ? MiuixSymbol.home
                                          : routeNames[i] == '/profile'
                                              ? MiuixSymbol.person
                                              : MiuixSymbol.calendar,
                                      size: 24,
                                      color: colors.onSurface.withOpacity(.8)),
                                  const SizedBox(height: 2),
                                  SizedBox(
                                      height: 16,
                                      child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(destinations[i].label,
                                              maxLines: 1,
                                              softWrap: false,
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: colors.onSurface
                                                      .withOpacity(.8))))),
                                ]))
                    ],
                  )))),
    ]);
  }
}
