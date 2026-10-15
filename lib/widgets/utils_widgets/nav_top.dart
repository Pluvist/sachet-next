import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/nav_destination.dart';
import 'package:sachet/providers/screen_nav_provider.dart';
import 'package:sachet/widgets/utils_widgets/nexio_bottom_tabs.dart';
import 'package:sachet/widgets/utils_widgets/glass_backdrop.dart';

class NavTop extends StatelessWidget {
  const NavTop(
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
        .addPostFrameCallback((_) => GlassBackdrop.capture());
    final mask = Theme.of(context).brightness == Brightness.dark
        ? Colors.black
        : Colors.white;
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
        height: MediaQuery.paddingOf(context).top + 96,
        child: Stack(children: [
          Positioned.fill(
              child: IgnorePointer(
                  child: DecoratedBox(
                      key: const ValueKey('floatingNavTopMask'),
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                            mask,
                            mask.withOpacity(.94),
                            mask.withOpacity(0)
                          ],
                              stops: const [
                            0,
                            .25,
                            1
                          ]))))),
          SafeArea(
              bottom: false,
              child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                          width: math.min(
                              440,
                              math.max(
                                  240, MediaQuery.sizeOf(context).width * .42)),
                          child: NexioBottomTabs(
                              key: const ValueKey('floatingNavTopToolbar'),
                              selected: currentPageIndex,
                              onSelected: (i) => context
                                  .read<ScreenNavProvider>()
                                  .setCurrentPage(routeNames[i]),
                              children: [
                                for (final destination in destinations)
                                  Tooltip(
                                      message: destination.label,
                                      child: Center(
                                          child: Text(destination.label,
                                              maxLines: 1,
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: colors.onSurface))))
                              ]))))),
        ]));
  }
}
