import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/nav_destination.dart';
import 'package:sachet/providers/screen_nav_provider.dart';
import 'package:sachet/utils/expressive_theme.dart';
import 'package:sachet/widgets/utils_widgets/nav_bottom.dart';

void main() {
  testWidgets('Labels keep full layout during expansion and rapid reversal',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const routes = ['/class', '/home', '/profile'];
    const labels = ['课程表', '主页', '我'];
    final destinations = List.generate(
        3,
        (index) => NavDestination(
              label: labels[index],
              icon: const Icon(Icons.circle_outlined),
              selectedIcon: const Icon(Icons.circle),
              page: const SizedBox(),
              routeName: routes[index],
            ));
    final navigation = ScreenNavProvider();

    for (final scale in [1.0, 2.0]) {
      navigation.setCurrentPage('/class');
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: navigation,
        child: MaterialApp(
          theme: applyExpressiveTheme(ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.green,
          )),
          home: MediaQuery(
            data: MediaQueryData(
                size: const Size(320, 640),
                textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              bottomNavigationBar: Consumer<ScreenNavProvider>(
                builder: (_, provider, __) => NavBottom(
                  destinations: destinations,
                  routeNames: routes,
                  currentPageIndex:
                      routes.indexOf(ScreenNavProvider.currentPage),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final fullWidths = {
        for (final label in labels)
          label: tester.getSize(find.text(label)).width,
      };
      void checkLabels() {
        for (final label in labels) {
          final paragraph =
              tester.renderObject<RenderParagraph>(find.text(label));
          expect(paragraph.didExceedMaxLines, isFalse,
              reason: '$label must not truncate at an intermediate width');
          expect(tester.getSize(find.text(label)).width, fullWidths[label],
              reason:
                  '$label layout must stay fixed while its window animates');
        }
        expect(tester.takeException(), isNull);
      }

      for (final route in ['/home', '/class', '/profile', '/class']) {
        navigation.setCurrentPage(route);
        await tester.pump();
        for (int frame = 0; frame < 16; frame++) {
          await tester.pump(const Duration(milliseconds: 20));
          checkLabels();
        }
      }
      for (final route in ['/home', '/profile', '/class', '/home', '/class']) {
        navigation.setCurrentPage(route);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 35));
        checkLabels();
      }
      await tester.pumpAndSettle();
      checkLabels();
    }
  });
}
