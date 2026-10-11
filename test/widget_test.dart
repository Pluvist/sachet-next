import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sachet/utils/expressive_theme.dart';
import 'package:sachet/widgets/settingspage_widgets/miuix_settings_list.dart';
import 'package:sachet/widgets/settingspage_widgets/settings_section_title.dart';
import 'package:sachet/widgets/utils_widgets/miuix_press.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('Preference interaction and contrast in $brightness',
        (tester) async {
      var selected = false;
      var taps = 0;
      final theme = applyExpressiveTheme(ThemeData(
          useMaterial3: true,
          brightness: brightness,
          colorSchemeSeed: Colors.blue));
      await tester.pumpWidget(MaterialApp(
          theme: theme,
          home: Scaffold(
              body: StatefulBuilder(
                  builder: (context, setState) => MiuixSettingsList(children: [
                        const SettingsSectionTitle(title: '偏好'),
                        ListTile(
                            title: const Text('选项'),
                            trailing: Switch(
                                value: selected,
                                onChanged: (value) =>
                                    setState(() => selected = value))),
                        MiuixPress(
                            child: ListTile(
                                title: const Text('打开'), onTap: () => taps++)),
                      ])))));
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(selected, true);
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(theme.colorScheme.surface.computeLuminance(),
          brightness == Brightness.light ? greaterThan(0.8) : lessThan(0.05));
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Press cancellation and reduced motion preserve card interaction',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
                child: MiuixPress(
                    child: SizedBox(
                        width: 100,
                        height: 100,
                        child: TextButton(
                            onPressed: () {}, child: const Text('卡片'))))))));
    final gesture =
        await tester.startGesture(tester.getCenter(find.text('卡片')));
    await tester.pump(const Duration(milliseconds: 150));
    expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 0.97);
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!),
        home: Scaffold(
            body: MiuixPress(child: const SizedBox(width: 100, height: 100)))));
    final reducedGesture = await tester.startGesture(const Offset(50, 50));
    await tester.pump();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    await reducedGesture.up();
    expect(tester.takeException(), isNull);
  });
}
