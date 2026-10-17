import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sachet/utils/ios_motion.dart';
import 'package:sachet/widgets/utils_widgets/ios_page_route.dart';
import 'package:sachet/widgets/utils_widgets/source_expand_route.dart';

void main() {
  testWidgets(
      'Retargeting preserves position and incoming velocity instead of restarting',
      (tester) async {
    final controller = IOSRouteController(
        vsync: tester,
        duration: IOSMotion.duration,
        reverseDuration: IOSMotion.closingDuration);
    controller.forward();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final position = controller.value, velocity = controller.velocity;
    expect(velocity, greaterThan(0));
    controller.reverse();
    expect(controller.value, position);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    // Momentum initially continues forwards, then decelerates into the return.
    expect(controller.value, greaterThan(position));
    expect(
        (controller.value - position) / .001, closeTo(velocity, velocity * .2));
    await tester.pump(const Duration(milliseconds: 90));
    final returning = controller.value;
    expect(returning, lessThan(position));
    controller.forward();
    expect(controller.value, returning);
    await tester.pumpAndSettle();
    expect(controller.value, 1);
    controller.reverse();
    await tester.pumpAndSettle();
    expect(controller.value, 0);
    controller.dispose();
  });

  for (final external in [false, true]) {
    testWidgets(
        'Two controls can animate together; covered external action cancels: external=$external',
        (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      final left = GlobalKey(), right = GlobalKey();
      var calls = 0;
      await tester.pumpWidget(MaterialApp(
          navigatorKey: navigator,
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: false),
              child: child!),
          onGenerateRoute: (_) => IOSPageRoute<void>(
              builder: (context) => Scaffold(
                      body: Stack(children: [
                    Positioned(
                        left: 20,
                        bottom: 20,
                        child: ExpansionAnchor(
                            key: left,
                            child: SizedBox(
                                width: 100,
                                height: 60,
                                child: TextButton(
                                    onPressed: () {
                                      if (external) {
                                        expandAction(context, () => calls++,
                                            sourceKey: left);
                                      } else {
                                        expandPage(
                                            context,
                                            const Scaffold(
                                                body: Text('Left page')),
                                            sourceKey: left);
                                      }
                                    },
                                    child: const Text('Left'))))),
                    Positioned(
                        right: 20,
                        bottom: 20,
                        child: ExpansionAnchor(
                            key: right,
                            child: SizedBox(
                                width: 100,
                                height: 60,
                                child: TextButton(
                                    onPressed: () => expandPage(
                                        context,
                                        const Scaffold(
                                            body: Text('Right page')),
                                        sourceKey: right),
                                    child: const Text('Right'))))),
                  ])))));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Left'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      final first = navigator.currentState!.widget;
      expect(first, isNotNull);
      await tester.tap(find.text('Right'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      final clippers = tester
          .widgetList<ClipPath>(
              find.byKey(const ValueKey('sourceExpansionMask')))
          .toList();
      expect(clippers, hasLength(2));
      expect(
          clippers.every((clip) =>
              (clip.clipper! as ControlExpansionClipper).progress > 0),
          true);
      await tester.pumpAndSettle();
      expect(find.text('Right page'), findsOneWidget);
      expect(calls, 0);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      if (!external) {
        expect(find.text('Left page'), findsOneWidget);
        navigator.currentState!.pop();
        await tester.pumpAndSettle();
      }
      expect(find.text('Left'), findsOneWidget);
      expect(find.byKey(const ValueKey('sourceExpansionMask')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Destination back control works before the opening finishes',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => expandPage(context,
                        Scaffold(appBar: AppBar(title: const Text('Details')))),
                    child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    expect(
        tester
            .widget<ClipPath>(find.byKey(const ValueKey('sourceExpansionMask')))
            .clipper,
        isA<ControlExpansionClipper>());
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
    expect(find.byKey(const ValueKey('sourceExpansionMask')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
