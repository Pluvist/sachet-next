import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sachet/utils/ios_motion.dart';
import 'package:sachet/widgets/utils_widgets/ios_page_route.dart';
import 'package:sachet/widgets/utils_widgets/source_expand_route.dart';

void main() {
  test('Spring is monotonic, settles smoothly, and preserves rounded windows',
      () {
    var previous = 0.0;
    for (var i = 0; i <= 100; i++) {
      final value = IOSMotion.opening.transform(i / 100);
      expect(value, inInclusiveRange(previous, 1));
      previous = value;
    }
    expect(IOSMotion.opening.transform(0), 0);
    expect(IOSMotion.opening.transform(1), 1);
    expect(IOSMotion.opening.transform(.95) - IOSMotion.opening.transform(.9),
        lessThan(.005));
    final clip = ControlExpansionClipper(
        source: const Rect.fromLTWH(20, 200, 160, 90),
        sourceRadius: 22,
        progress: .7);
    expect(clip.radius, IOSMotion.windowRadius);
    expect(
        clip
            .getClip(const Size(800, 600))
            .contains(clip.getClip(const Size(800, 600)).getBounds().topLeft),
        isFalse);
  });

  for (final reduced in [false, true]) {
    testWidgets(
        'Background follows expansion and restores on return; reduced=$reduced',
        (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      final previewRoot = GlobalKey();
      await tester.pumpWidget(MaterialApp(
          navigatorKey: navigator,
          builder: (context, child) => RepaintBoundary(
              key: previewRoot,
              child: MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(disableAnimations: reduced),
                  child: child!)),
          onGenerateRoute: (_) => IOSPageRoute<void>(
              builder: (_) => const Scaffold(
                  backgroundColor: Colors.white,
                  body: Center(child: Text('Root'))))));
      await tester.pumpAndSettle();
      final route = SourceExpandRoute<void>(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Destination'))),
          source: const Rect.fromLTWH(20, 200, 160, 90),
          reduceMotion: reduced);
      navigator.currentState!.push(route);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      if (!reduced) {
        final scale = tester
            .widget<Transform>(find.byKey(const ValueKey('routeDepthScale')))
            .transform
            .storage[0];
        final offset = tester
            .widget<Transform>(find.byKey(const ValueKey('routeDepthOffset')))
            .transform
            .storage[13];
        final dim = tester
            .widget<ColoredBox>(find.byKey(const ValueKey('routeDepthDim')))
            .color;
        expect(scale, inExclusiveRange(.955, 1));
        expect(offset, greaterThan(0));
        expect(dim.opacity, greaterThan(0));
        final folder = Platform.environment['SACHET_DEPTH_PREVIEW_DIR'];
        if (folder != null) {
          await tester.runAsync(() async {
            final boundary = previewRoot.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 1);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await Directory(folder).create(recursive: true);
            await File('$folder/expanding-100ms.png')
                .writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }
        final before = route.depthProgressAnimation.value;
        navigator.currentState!.pop();
        await tester.pump();
        expect(route.depthProgressAnimation.value, closeTo(before, .001));
        await tester.pump(const Duration(milliseconds: 30));
        expect(route.depthProgressAnimation.value, lessThan(before));
      } else {
        expect(route.depthProgressAnimation.value, 1);
        navigator.currentState!.pop();
      }
      await tester.pumpAndSettle();
      expect(find.text('Root'), findsOneWidget);
      expect(find.byKey(const ValueKey('routeDepthDim')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('An expanded page also recedes behind the next expansion',
      (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
        navigatorKey: navigator, home: const Scaffold(body: Text('Root'))));
    SourceExpandRoute<void> page(String name) => SourceExpandRoute<void>(
        source: const Rect.fromLTWH(20, 200, 160, 90),
        reduceMotion: false,
        builder: (_) => Scaffold(body: Text(name)));
    navigator.currentState!.push(page('First'));
    await tester.pumpAndSettle();
    navigator.currentState!.push(page('Second'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.byKey(const ValueKey('routeDepthDim')), findsOneWidget);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('First'), findsOneWidget);
    expect(find.byKey(const ValueKey('routeDepthDim')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
