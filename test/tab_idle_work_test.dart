import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sachet/widgets/utils_widgets/idle_frame_work.dart';
import 'package:sachet/widgets/utils_widgets/retained_tab_body.dart';
import 'package:sachet/widgets/utils_widgets/nexio_bottom_tabs.dart';

class _Page extends StatefulWidget {
  const _Page(this.label, this.onInit);
  final String label;
  final VoidCallback onInit;
  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) => Text(widget.label);
}

void main() {
  testWidgets(
      'Idle work coalesces and waits for animation without blocking frames',
      (tester) async {
    final controller = AnimationController(
        vsync: tester, duration: const Duration(seconds: 1));
    final work = IdleFrameWork();
    var calls = 0;
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    controller.repeat();
    for (var i = 0; i < 8; i++) {
      work.schedule(() => calls++);
    }
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(calls, 0);
    controller.stop();
    await tester.pump();
    expect(calls, 1);
    work.schedule(() => calls++);
    work.cancel();
    await tester.pump();
    expect(calls, 1);
    controller.dispose();
  });
  testWidgets('Other page prepares before switching and is not remounted',
      (tester) async {
    var first = 0, second = 0;
    final selected = ValueNotifier(0);
    final children = [
      _Page('Home', () => first++),
      _Page('Classes', () => second++)
    ];
    await tester.pumpWidget(MaterialApp(
        home: ValueListenableBuilder<int>(
            valueListenable: selected,
            builder: (_, value, __) =>
                RetainedTabBody(index: value, children: children))));
    await tester.pumpAndSettle();
    expect(first, 1);
    expect(second, 1);
    expect(find.text('Classes'), findsNothing);
    expect(
        TickerMode.of(
            tester.element(find.text('Classes', skipOffstage: false))),
        isFalse);
    for (var i = 0; i < 20; i++) {
      selected.value = i % 2;
      await tester.pumpAndSettle();
    }
    expect(first, 1);
    expect(second, 1);
    await tester.pumpWidget(const SizedBox());
    selected.dispose();
  });
  testWidgets('Glass background is reused across selection changes',
      (tester) async {
    final selected = ValueNotifier(0);
    await tester.pumpWidget(MaterialApp(
        home: Center(
            child: SizedBox(
                width: 270,
                child: ValueListenableBuilder<int>(
                    valueListenable: selected,
                    builder: (_, value, __) => NexioBottomTabs(
                        height: 44,
                        selected: value,
                        onSelected: (i) => selected.value = i,
                        children: const [Text('Home'), Text('Classes')]))))));
    await tester.pumpAndSettle();
    final background =
        tester.widget(find.byKey(const ValueKey('nexioFixedBackdrop')));
    await tester.tap(find.text('Classes'));
    await tester.pumpAndSettle();
    expect(selected.value, 1);
    expect(
        identical(background,
            tester.widget(find.byKey(const ValueKey('nexioFixedBackdrop')))),
        isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    selected.dispose();
  });
}
