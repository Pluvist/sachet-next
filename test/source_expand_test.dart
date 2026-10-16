import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:sachet/pages/intro_screen/intro_screen.dart';
import 'package:sachet/widgets/homepage_widgets/card_widget.dart';
import 'package:sachet/utils/expressive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/app_settings.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/providers/zhengfang_user_provider.dart';
import 'package:sachet/services/automatic_course_refresh.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/widgets/utils_widgets/course_refresh_coordinator.dart';
import 'package:sachet/widgets/utils_widgets/source_expand_route.dart';

class _Settings extends SettingsProvider {
  bool finished = false;
  @override
  bool get hasReadDisclaimer => finished;
  void finish() {
    finished = true;
    notifyListeners();
  }
}

class _User extends ZhengFangUserProvider {
  bool login = false;
  @override
  bool get isLogin => login;
  void signIn() {
    login = true;
    notifyListeners();
  }
}

class _Refresh extends AutomaticCourseRefresh {
  int calls = 0;
  @override
  Future<bool> refresh(SettingsProvider settings, ZhengFangUserProvider user,
      {required bool Function() isAlive}) async {
    calls++;
    return isAlive();
  }
}

void main() {
  test('Control contours remain bounded while every edge reaches the viewport',
      () {
    for (final size in [const Size(400, 850), const Size(1200, 600)]) {
      for (final source in [
        const Rect.fromLTWH(40, 490, 320, 76),
        const Rect.fromLTWH(320, 40, 44, 44),
        const Rect.fromLTWH(18, 200, 170, 260)
      ]) {
        final initial = ControlExpansionClipper(
            source: source, sourceRadius: 22, progress: 0);
        expect(initial.getClip(size).getBounds(), source);
        expect(initial.getClip(size).contains(source.topLeft), false);
        expect(ControlExpansionClipper.bounds(source, size, .5),
            Rect.lerp(source, Offset.zero & size, .5));
        for (final value in [0.0, .25, .5, .75, 1.0]) {
          final bounds = ControlExpansionClipper.bounds(source, size, value);
          expect(bounds.width, lessThanOrEqualTo(size.width));
          expect(bounds.height, lessThanOrEqualTo(size.height));
        }
        expect(
            ControlExpansionClipper(
                    source: source, sourceRadius: 22, progress: 1)
                .getClip(size)
                .getBounds(),
            Offset.zero & size);
      }
    }
  });
  testWidgets(
      'Control expands without scaling destination text; back restores source',
      (tester) async {
    final iconKey = GlobalKey();
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: false),
            child: child!),
        home: Scaffold(
            body: Center(
                child: Builder(
                    builder: (context) => TextButton(
                        onPressed: () => expandPage(context,
                            const Scaffold(body: Center(child: SizedBox(width: 200, height: 40, child: Text('Destination')))),
                            sourceKey: iconKey),
                        child: ExpansionAnchor(
                            key: iconKey,
                            child: const SizedBox(
                                width: 70,
                                height: 70,
                                child: Icon(Icons.arrow_forward)))))))));
    final source = tester.getRect(find.byKey(iconKey));
    await tester.tap(find.byType(TextButton));
    await tester.pump();
    await tester.pump();
    final mask = find.byKey(const ValueKey('sourceExpansionMask'));
    ControlExpansionClipper clipper() =>
        tester.widget<ClipPath>(mask).clipper! as ControlExpansionClipper;
    expect(clipper().source, source);
    expect(clipper().getClip(const Size(800, 600)).getBounds(), source);
    expect(find.byType(RawImage), findsOneWidget);
    final destination = tester.getRect(find.text('Destination'));
    expect(destination.size, const Size(200, 40));
    await tester.pump(const Duration(milliseconds: 120));
    expect(clipper().progress, greaterThan(.24));
    expect(tester.getRect(find.text('Destination')), destination);
    expect(
        ControlExpansionClipper.bounds(
                source, const Size(800, 600), clipper().progress)
            .center,
        Rect.lerp(source, const Rect.fromLTWH(0, 0, 800, 600),
                clipper().progress)!
            .center);
    await tester.pumpAndSettle();
    expect(find.text('Destination'), findsOneWidget);
    expect(find.byType(FittedBox), findsNothing);
    Navigator.of(tester.element(find.text('Destination'))).pop();
    await tester.pumpAndSettle();
    final opacity = find.descendant(
        of: find.byKey(iconKey), matching: find.byType(Opacity));
    expect(tester.widget<Opacity>(opacity).opacity, 1);
    expect(tester.takeException(), isNull);
  });
  for (final cancel in [false, true]) {
    testWidgets('External action waits for completion, cancel=$cancel',
        (tester) async {
      var calls = 0;
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(MaterialApp(
          navigatorKey: navigator,
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: false),
              child: child!),
          home: Scaffold(
              body: Builder(
                  builder: (context) => TextButton(
                      onPressed: () => expandAction(context, () => calls++),
                      child: const Text('Open'))))));
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(calls, 0);
      if (cancel) navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(calls, cancel ? 0 : 1);
      expect(find.text('Open'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
      'Reduced motion opens immediately without snapshot and returns normally',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!),
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () => expandPage(context,
                        const Scaffold(body: Text('Reduced destination'))),
                    child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Reduced destination'), findsOneWidget);
    expect(find.byType(RawImage), findsNothing);
    Navigator.of(tester.element(find.text('Reduced destination'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Welcome arrow and home feature reveal from their full control edges',
      (tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final output = Platform.environment['SACHET_EXPANSION_PREVIEW_DIR'];
    if (output != null) {
      await tester.runAsync(() async {
        final font = FontLoader('PreviewCJK')
          ..addFont(File('C:/Windows/Fonts/msyh.ttc')
              .readAsBytes()
              .then((bytes) => ByteData.sublistView(bytes)));
        await font.load();
      });
    }
    for (final welcome in [true, false]) {
      final root = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: root,
          child: MaterialApp(
              theme: applyExpressiveTheme(ThemeData(
                  brightness: Brightness.dark,
                  fontFamily: output == null ? null : 'PreviewCJK')),
              builder: (context, child) => MediaQuery(
                  data:
                      MediaQuery.of(context).copyWith(disableAnimations: false),
                  child: child!),
              home: welcome
                  ? const IntroScreen()
                  : const Scaffold(
                      body: Center(
                          child: SizedBox(
                              width: 320,
                              child: CardWidget(
                                  title: '培养方案',
                                  icon: Icons.school,
                                  page: Scaffold(
                                      body: Center(child: Text('培养方案'))))))))));
      await tester.pump(const Duration(seconds: 2));
      final anchor = find.byType(ExpansionAnchor);
      final originKey = tester.widget<ExpansionAnchor>(anchor).key!;
      final source = tester.getRect(anchor);
      expect(source.width, welcome ? 70 : 320);
      if (!welcome) expect(source.height, 76);
      Future<void> capture(String suffix) async {
        if (output == null) return;
        final boundary =
            root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(output).create(recursive: true);
          await File('$output/${welcome ? 'welcome' : 'home'}-$suffix.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await capture('before');
      await tester.tap(welcome
          ? find.byKey(const ValueKey('introNext'))
          : find.byType(CardWidget));
      await tester.pump();
      await tester.pump();
      final mask = tester
          .widget<ClipPath>(find.byKey(const ValueKey('sourceExpansionMask')));
      expect((mask.clipper! as ControlExpansionClipper).source, source);
      final originOpacity =
          find.descendant(of: find.byKey(originKey), matching: find.byType(Opacity));
      expect(tester.widget<Opacity>(originOpacity).opacity, 0);
      final raw = tester.widget<RawImage>(find.byType(RawImage));
      expect(raw.image!.width, welcome ? 70 : 320);
      if (output != null) {
        await tester.runAsync(() async {
          final data =
              await raw.image!.toByteData(format: ui.ImageByteFormat.png);
          await File('$output/${welcome ? 'welcome' : 'home'}-bitmap.png')
              .writeAsBytes(data!.buffer.asUint8List());
        });
      }
      await capture('000');
      var time = 0;
      for (final next in [40, 100, 200, 350, 500]) {
        await tester.pump(Duration(milliseconds: next - time));
        time = next;
        await capture('$next');
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }
  });
  testWidgets('Entrance uses nonlinear easing and reaches exact final geometry',
      (tester) async {
    final progress = ValueNotifier<double>(0);
    final animation = Animation<double>.fromValueListenable(progress);
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: false),
            child: child!),
        home: Center(
            child: HomeEntrance(
                animation: animation, index: 0, child: const Text('Card')))));
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);
    progress.value = .5;
    await tester.pump();
    expect(
        tester.widget<Opacity>(find.byType(Opacity)).opacity, greaterThan(.5));
    progress.value = 1;
    await tester.pump();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    expect(tester.takeException(), isNull);
    progress.dispose();
  });
  testWidgets(
      'Login during intro waits until completion to refresh in background',
      (tester) async {
    AppGlobal.appSettings = AppSettings.fromJson(defaultAppSettingsConfig);
    final settings = _Settings();
    final user = _User();
    final refresh = _Refresh();
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<ZhengFangUserProvider>.value(value: user)
        ],
        child: MaterialApp(
            home: CourseRefreshCoordinator(
                refresh: refresh, child: const Scaffold(body: Text('Home'))))));
    await tester.pump();
    expect(refresh.calls, 0);
    user.signIn();
    await tester.pump();
    expect(refresh.calls, 0);
    settings.finish();
    await tester.pumpAndSettle();
    expect(refresh.calls, 1);
    settings.notifyListeners();
    await tester.pump();
    expect(refresh.calls, 1);
    expect(find.text('Home'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    settings.dispose();
    user.dispose();
  });
}
