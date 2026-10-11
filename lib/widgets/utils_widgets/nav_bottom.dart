import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/nav_destination.dart';
import 'package:sachet/providers/screen_nav_provider.dart';
import 'package:sachet/utils/home_design.dart';

class NavBottom extends StatelessWidget {
  final List<NavDestination> destinations;
  final List<String> routeNames;
  final int currentPageIndex;

  /// Floating Material 3 navigation, with the original Material 2 fallback.
  const NavBottom({
    super.key,
    required this.destinations,
    required this.routeNames,
    required this.currentPageIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.useMaterial3) {
      return _buildFloatingToolbar(context);
    }
    return BottomNavigationBar(
      items: <BottomNavigationBarItem>[
        ...destinations.map(
          (NavDestination destination) {
            return BottomNavigationBarItem(
              icon: destination.icon,
              activeIcon: destination.selectedIcon,
              label: destination.label,
            );
          },
        ),
      ],
      currentIndex: currentPageIndex,
      type: BottomNavigationBarType.fixed,
      onTap: (int index) {
        if (index != currentPageIndex) {
          context.read<ScreenNavProvider>().setCurrentPage(routeNames[index]);
        }
      },
      showUnselectedLabels: false,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      landscapeLayout: BottomNavigationBarLandscapeLayout.linear,
    );
  }

  Widget _buildFloatingToolbar(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 300);
    final textScaler = MediaQuery.textScalerOf(context);
    final labelStyle = Theme.of(context).textTheme.labelLarge!.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: colors.onPrimary,
        );
    final itemHeight = (textScaler.scale(16) * 1.5 + 16).clamp(52.0, 120.0);

    final toolbar = SafeArea(
      top: false,
      minimum: EdgeInsets.fromLTRB(16, 8, 16,
          routeNames[currentPageIndex] == '/home' ? HomeDesign.navBottom : 16),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: LayoutBuilder(builder: (context, constraints) {
            final labelWidths = destinations.map((destination) {
              final painter = TextPainter(
                text: TextSpan(text: destination.label, style: labelStyle),
                textDirection: Directionality.of(context),
                textScaler: textScaler,
                maxLines: 1,
              )..layout();
              final width = painter.width;
              painter.dispose();
              return width;
            }).toList();
            final maxSelectedWidth =
                constraints.maxWidth - 16 - (destinations.length - 1) * 56;
            final selectedWidth = (52 + labelWidths[currentPageIndex] + 16)
                .clamp(52.0, maxSelectedWidth.clamp(52.0, double.infinity));

            return Material(
              key: const ValueKey('floatingNavToolbar'),
              color: dark
                  ? Color.lerp(colors.surfaceContainerLow, Colors.black,
                      HomeDesign.navDarken)!
                  : Colors.white,
              elevation: 3,
              shadowColor: colors.shadow.withOpacity(0.18),
              shape: StadiumBorder(
                side: BorderSide(
                  color: Colors.grey.withOpacity(dark ? 0.22 : 0.18),
                  width: 0.5,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int index = 0;
                        index < destinations.length;
                        index++) ...[
                      if (index > 0) const SizedBox(width: 4),
                      _FloatingNavItem(
                        destination: destinations[index],
                        selected: index == currentPageIndex,
                        width: index == currentPageIndex ? selectedWidth : 52,
                        height: itemHeight,
                        labelStyle: labelStyle,
                        labelWidth: labelWidths[index],
                        colors: colors,
                        duration: duration,
                        onTap: () {
                          if (index != currentPageIndex) {
                            context
                                .read<ScreenNavProvider>()
                                .setCurrentPage(routeNames[index]);
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
    final maskColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.black
        : Colors.white;
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              key: const ValueKey('floatingNavBottomMask'),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    maskColor.withOpacity(0),
                    maskColor.withOpacity(0.94),
                    maskColor,
                  ],
                  stops: const [0, 0.75, 1],
                ),
              ),
            ),
          ),
        ),
        Padding(padding: const EdgeInsets.only(top: 24), child: toolbar),
      ],
    );
  }
}

class _FloatingNavItem extends StatelessWidget {
  const _FloatingNavItem({
    required this.destination,
    required this.selected,
    required this.width,
    required this.height,
    required this.labelStyle,
    required this.labelWidth,
    required this.colors,
    required this.duration,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final double width;
  final double height;
  final TextStyle labelStyle;
  final double labelWidth;
  final ColorScheme colors;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      onTap: onTap,
      child: Tooltip(
        message: destination.label,
        excludeFromSemantics: true,
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOutCubic,
          width: width,
          height: height,
          decoration: ShapeDecoration(
            color: selected ? colors.primary : Colors.transparent,
            shape: const StadiumBorder(),
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              excludeFromSemantics: true,
              customBorder: const StadiumBorder(),
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    SizedBox(
                      width: 52,
                      child: IconTheme(
                        data: IconThemeData(
                          color: selected ? colors.onPrimary : colors.onSurface,
                          size: 24,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedOpacity(
                              opacity: selected ? 0 : 1,
                              duration: duration,
                              child: destination.icon,
                            ),
                            AnimatedOpacity(
                              opacity: selected ? 1 : 0,
                              duration: duration,
                              child: destination.selectedIcon,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRect(
                        // Keep glyph layout fixed while the visible window animates.
                        // Relayout at each intermediate width would insert ellipses.
                        child: OverflowBox(
                          alignment: AlignmentDirectional.centerStart,
                          minWidth: labelWidth + 16,
                          maxWidth: labelWidth + 16,
                          child: AnimatedOpacity(
                            opacity: selected ? 1 : 0,
                            duration: duration,
                            child: Padding(
                              padding:
                                  const EdgeInsetsDirectional.only(end: 16),
                              child: Text(
                                destination.label,
                                style: labelStyle,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.clip,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
