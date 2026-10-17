import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/nav_destination.dart';
import 'package:sachet/providers/screen_nav_provider.dart';
import 'package:sachet/widgets/utils_widgets/nexio_bottom_tabs.dart';
import 'package:sachet/widgets/utils_widgets/glass_backdrop.dart';
import 'package:sachet/widgets/utils_widgets/top_edge_mask.dart';

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
        .addPostFrameCallback((_) => GlassBackdrop.captureWhenIdle());
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
        height: MediaQuery.paddingOf(context).top + 84,
        child: Stack(children: [
          const Positioned.fill(
              child:
                  TopEdgeMask(decorationKey: ValueKey('floatingNavTopMask'))),
          SafeArea(
              bottom: false,
              child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                          width: math.min(
                              320,
                              math.max(
                                  200, MediaQuery.sizeOf(context).width * .30)),
                          child: NexioBottomTabs(
                              key: const ValueKey('floatingNavTopToolbar'),
                              height: 44,
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
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: colors.onSurface))))
                              ]))))),
        ]));
  }
}
