import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Pre-implementation experiment: keep expensive tab state, build pages lazily,
// and only commit a completed refresh. No application code is changed here.
class Probe extends StatefulWidget {
  const Probe(this.index, this.created, {super.key});
  final int index;
  final List<int> created;
  @override
  State<Probe> createState() => ProbeState();
}

class ProbeState extends State<Probe> {
  int value = 0;
  @override
  void initState() {
    super.initState();
    widget.created[widget.index]++;
  }

  @override
  Widget build(BuildContext context) => TextButton(
      onPressed: () => setState(() => value++),
      child: Text('${widget.index}:$value'));
}

void main() {
  testWidgets('Simulation: 40 tab changes preserve state and initialize once',
      (tester) async {
    final created = [0, 0];
    final visited = <int>{};
    final index = ValueNotifier(0);
    await tester.pumpWidget(MaterialApp(
        home: ValueListenableBuilder<int>(
            valueListenable: index,
            builder: (_, active, __) {
              visited.add(active);
              return Stack(children: [
                for (int i = 0; i < 2; i++)
                  Offstage(
                      offstage: i != active,
                      child: TickerMode(
                          enabled: i == active,
                          child: visited.contains(i)
                              ? Probe(i, created)
                              : const SizedBox())),
              ]);
            })));
    await tester.tap(find.text('0:0'));
    await tester.pump();
    for (int i = 0; i < 40; i++) {
      index.value = (i + 1) % 2;
      await tester.pump();
    }
    expect(created, [1, 1]);
    expect(find.text('0:1'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    index.dispose();
  });

  testWidgets('Simulation: fast paging creates fewer than all 20 weeks',
      (tester) async {
    final created = List.filled(20, 0);
    final controller = PageController();
    await tester.pumpWidget(MaterialApp(
        home: PageView.builder(
            controller: controller,
            itemCount: 20,
            allowImplicitScrolling: true,
            itemBuilder: (_, i) => Probe(i, created))));
    for (int i = 1; i <= 6; i++) {
      controller.jumpToPage(i);
      await tester.pump();
    }
    expect(created.where((n) => n > 0).length, lessThan(20));
    expect(controller.page, 6);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  test('Simulation: cache remains readable during failed background refresh',
      () async {
    String cache = 'previous valid timetable';
    final network = Completer<String>();
    final refresh = network.future
        .then((data) => cache = data, onError: (Object _) => cache);
    expect(cache, 'previous valid timetable');
    network.completeError(StateError('offline'));
    await refresh;
    expect(cache, 'previous valid timetable');
  });
}
