import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/nav_destination.dart';
import 'package:sachet/providers/screen_nav_provider.dart';
import 'package:sachet/utils/home_design.dart';
import 'package:sachet/widgets/utils_widgets/miuix_glyph.dart';

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
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scaler = MediaQuery.textScalerOf(context);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);
    final labelStyle = TextStyle(
        fontSize: 14,
        height: 1.2,
        fontWeight: FontWeight.w500,
        color: colors.onSurface);
    var longest = 0.0;
    for (final destination in destinations) {
      final text = TextPainter(
          text: TextSpan(text: destination.label, style: labelStyle),
          textDirection: Directionality.of(context),
          textScaler: scaler)
        ..layout();
      longest = math.max(longest, text.width);
      text.dispose();
    }
    final height = math.max(64.0, scaler.scale(14) * 1.3 + 36);
    final mask = dark ? Colors.black : Colors.white;
    return Stack(children: [
      Positioned.fill(
          child: IgnorePointer(
              child: DecoratedBox(
        key: const ValueKey('floatingNavBottomMask'),
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [mask.withOpacity(0), mask.withOpacity(.94), mask],
                stops: const [0, .75, 1])),
      ))),
      Padding(
        padding: const EdgeInsets.only(top: 24),
        child: SafeArea(
          top: false,
          minimum: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              routeNames[currentPageIndex] == '/home'
                  ? HomeDesign.navBottom
                  : 16),
          child: Center(
            heightFactor: 1,
            child: LayoutBuilder(builder: (context, constraints) {
              final width = ((longest + 48) * destinations.length + 16)
                  .clamp(math.min(256, constraints.maxWidth),
                      math.min(400, constraints.maxWidth))
                  .toDouble();
              return Material(
                key: const ValueKey('floatingNavToolbar'),
                color: dark ? const Color(0xff191919) : Colors.white,
                shape: StadiumBorder(
                    side: BorderSide(
                        color: Colors.grey.withOpacity(dark ? .28 : .18),
                        width: .5)),
                elevation: 0,
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: width,
                  child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Row(children: [
                        for (var index = 0;
                            index < destinations.length;
                            index++)
                          Expanded(
                              child: Semantics(
                                  selected: index == currentPageIndex,
                                  button: true,
                                  label: destinations[index].label,
                                  child: Tooltip(
                                      message: destinations[index].label,
                                      excludeFromSemantics: true,
                                      child: SizedBox(
                                          height: height,
                                          child: AnimatedContainer(
                                            duration: duration,
                                            curve: Curves.easeOutCubic,
                                            decoration: ShapeDecoration(
                                                shape: const StadiumBorder(),
                                                color: index == currentPageIndex
                                                    ? colors
                                                        .surfaceContainerHigh
                                                    : Colors.transparent),
                                            child: Material(
                                                type: MaterialType.transparency,
                                                child: InkWell(
                                                  customBorder:
                                                      const StadiumBorder(),
                                                  onTap: () {
                                                    if (index !=
                                                        currentPageIndex) {
                                                      context
                                                          .read<
                                                              ScreenNavProvider>()
                                                          .setCurrentPage(
                                                              routeNames[
                                                                  index]);
                                                    }
                                                  },
                                                  child: Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8),
                                                      child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            MiuixGlyph(
                                                                routeNames[index] ==
                                                                        '/home'
                                                                    ? MiuixSymbol
                                                                        .home
                                                                    : routeNames[index] ==
                                                                            '/profile'
                                                                        ? MiuixSymbol
                                                                            .person
                                                                        : MiuixSymbol
                                                                            .calendar,
                                                                size: 26,
                                                                color: index ==
                                                                        currentPageIndex
                                                                    ? colors
                                                                        .onSurface
                                                                    : colors
                                                                        .onSurfaceVariant),
                                                            const SizedBox(
                                                                height: 3),
                                                            FittedBox(
                                                                fit: BoxFit
                                                                    .scaleDown,
                                                                child: Text(
                                                                    destinations[
                                                                            index]
                                                                        .label,
                                                                    maxLines: 1,
                                                                    softWrap:
                                                                        false,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .clip,
                                                                    style: labelStyle.copyWith(
                                                                        color: index ==
                                                                                currentPageIndex
                                                                            ? colors.onSurface
                                                                            : colors.onSurfaceVariant))),
                                                          ])),
                                                )),
                                          ))))),
                      ])),
                ),
              );
            }),
          ),
        ),
      ),
    ]);
  }
}
