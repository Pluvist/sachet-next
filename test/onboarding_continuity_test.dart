import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/app_settings.dart';
import 'package:sachet/models/course_card_settings.dart';
import 'package:sachet/pages/home_page.dart';
import 'package:sachet/pages/intro_screen/background_setup_page.dart';
import 'package:sachet/pages/intro_screen/intro_screen.dart';
import 'package:sachet/pages/settings_page.dart';
import 'package:sachet/providers/course_card_settings_provider.dart';
import 'package:sachet/providers/screen_nav_provider.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/providers/theme_provider.dart';
import 'package:sachet/providers/zhengfang_user_provider.dart';
import 'package:sachet/services/course_widget_bridge.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/utils/expressive_theme.dart';
import 'package:sachet/widgets/utils_widgets/source_expand_route.dart';

class _Settings extends SettingsProvider {
  final pending = Completer<CourseScheduleData>();
  bool delayDisk = false;
  int finished = 0;
  @override
  Future<CourseScheduleData> loadCourseScheduleData() => delayDisk
      ? pending.future
      : Future.value((
          courseScheduleItemsList: null,
          courseColorData: {},
          classSessionSummerDataList: [],
          classSessionWinterDataList: []
        ));
  @override
  void setStartupPage(String page) {
    AppGlobal.appSettings.startupPage = page;
  }

  @override
  void setHasReadDisclaimer() {
    finished++;
    AppGlobal.appSettings.hasReadDisclaimer = true;
  }
}

class _CountingHome extends StatefulWidget {
  const _CountingHome(this.onCreate);
  final VoidCallback onCreate;
  @override
  State<_CountingHome> createState() => _CountingHomeState();
}

class _CountingHomeState extends State<_CountingHome> {
  @override
  void initState() {
    super.initState();
    widget.onCreate();
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Text('Prepared home'));
}

void main() {
  final calls = <String>[];
  final previews = Platform.environment['SACHET_ONBOARDING_PREVIEW_DIR'];
  setUp(() {
    calls.clear();
    AppGlobal.appSettings = AppSettings.fromJson(defaultAppSettingsConfig);
    AppGlobal.courseCardSettings = CourseCardSettings();
    AppGlobal.homeEntrancePending = false;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (_) async => null);
    messenger.setMockMethodCallHandler(CourseWidgetBridge.channel,
        (call) async {
      calls.add('${call.method}:${call.arguments}');
      if (call.method == 'backgroundStatus') {
        return {'batteryUnrestricted': false, 'widgetCount': 0};
      }
      return true;
    });
  });
  Future<void> app(WidgetTester tester, Widget home, _Settings settings,
      {double scale = 1, ValueNotifier<bool>? reducedMotion}) async {
    if (previews != null) {
      await tester.runAsync(() async {
        await (FontLoader('PreviewCJK')
              ..addFont(File('C:/Windows/Fonts/msyh.ttc')
                  .readAsBytes()
                  .then((bytes) => ByteData.sublistView(bytes))))
            .load();
        await (FontLoader('MaterialIcons')
              ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
            .load();
      });
    }
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider(create: (_) => ScreenNavProvider()),
          ChangeNotifierProvider(create: (_) => ZhengFangUserProvider()),
          ChangeNotifierProvider(create: (_) => CourseCardSettingsProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: MaterialApp(
            theme: applyExpressiveTheme(ThemeData(
                brightness:
                    previews == null ? Brightness.light : Brightness.dark,
                fontFamily: previews == null ? null : 'PreviewCJK')),
            builder: (context, child) {
              Widget media(bool reduced) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                      disableAnimations: reduced,
                      textScaler: TextScaler.linear(scale)),
                  child: child!);
              return reducedMotion == null
                  ? media(true)
                  : ValueListenableBuilder<bool>(
                      valueListenable: reducedMotion,
                      builder: (_, value, __) => media(value));
            },
            home: home)));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String key) async {
    final control = find.byKey(ValueKey(key));
    await tester.ensureVisible(control);
    await tester.tap(control);
    await tester.pumpAndSettle();
  }

  Future<void> toSetup(WidgetTester tester) async {
    await tap(tester, 'introNext');
    await tap(tester, 'agreementConsent');
    await tap(tester, 'agreementContinue');
    await tap(tester, 'onboardLoginSkip');
  }

  Future<void> capture(WidgetTester tester, Type page, String name) async {
    if (previews == null) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(find
        .ancestor(of: find.byType(page), matching: find.byType(RepaintBoundary))
        .first);
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      await Directory(previews).create(recursive: true);
      await File('$previews/$name.png')
          .writeAsBytes(bytes.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets(
      'Home state is prepared once and transferred even if disk I/O is delayed',
      (tester) async {
    var creations = 0;
    final settings = _Settings()..delayDisk = true;
    await app(
        tester,
        IntroScreen(homeBuilder: (_) => _CountingHome(() => creations++)),
        settings);
    await toSetup(tester);
    await capture(tester, BackgroundSetupPage, 'background-and-widgets');
    expect(creations, 1);
    final state = tester.state(find.byType(_CountingHome, skipOffstage: false));
    expect(find.text('Prepared home'), findsNothing);
    await tap(tester, 'backgroundSetupContinue');
    await capture(tester, IntroCompletionPage, 'completion');
    expect(settings.finished, 0);
    await tap(tester, 'introFinish');
    expect(find.text('Prepared home'), findsOneWidget);
    expect(identical(tester.state(find.byType(_CountingHome)), state), true);
    expect(creations, 1);
    expect(settings.finished, 1);
    expect(settings.pending.isCompleted, false);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Production home, dock and cached state survive the same handoff',
      (tester) async {
    final settings = _Settings();
    await app(tester, const IntroScreen(), settings);
    await toSetup(tester);
    final home = tester.state(find.byType(HomePage, skipOffstage: false));
    await tap(tester, 'backgroundSetupContinue');
    await tap(tester, 'introFinish');
    expect(identical(tester.state(find.byType(HomePage)), home), true);
    expect(settings.finished, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'Preloaded home joins the visible handoff clock without restarting its entrance',
      (tester) async {
    final reduced = ValueNotifier(true);
    final settings = _Settings();
    await app(tester, const IntroScreen(), settings, reducedMotion: reduced);
    await toSetup(tester);
    final state = tester.state(find.byType(HomePage, skipOffstage: false));
    await tap(tester, 'backgroundSetupContinue');
    reduced.value = false;
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('introFinish')));
    await tester.tap(find.byKey(const ValueKey('introFinish')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(settings.finished, 0);
    expect(identical(tester.state(find.byType(HomePage)), state), true);
    final route = ModalRoute.of(tester.element(find.byType(HomePage)))!
        as SourceExpandRoute;
    for (final entrance
        in tester.widgetList<HomeEntrance>(find.byType(HomeEntrance))) {
      expect(identical(entrance.animation, route.expansionAnimation), true);
      expect(entrance.hasCurvedClock, true);
    }
    await tester.pumpAndSettle();
    expect(settings.finished, 1);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    reduced.dispose();
  });
  testWidgets(
      'Setup opens explicit settings actions, offers widgets, and allows skipping',
      (tester) async {
    await app(
        tester,
        BackgroundSetupPage(
            completionBuilder: (_) => const Scaffold(body: Text('Complete'))),
        _Settings(),
        scale: 2);
    await tap(tester, 'setupBackground');
    await tap(tester, 'setupAutostart');
    expect(calls, contains('backgroundSettings:battery'));
    expect(calls, contains('backgroundSettings:autostart'));
    await tap(tester, 'setupWidget');
    expect(find.text('2×2 今日课程'), findsOneWidget);
    expect(find.text('4×2 横向课程概览'), findsOneWidget);
    Navigator.of(tester.element(find.text('选择小组件布局'))).pop();
    await tester.pumpAndSettle();
    await tap(tester, 'backgroundSetupContinue');
    expect(find.text('Complete'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Retired experimental settings and legacy config keys are absent',
      (tester) async {
    final settings = AppSettings.fromJson({
      ...defaultAppSettingsConfig,
      'isEnableCourseNotification': true,
      'isSilentNotification': true
    });
    expect(settings.toJson().containsKey('isEnableCourseNotification'), false);
    expect(settings.toJson().containsKey('isSilentNotification'), false);
    await app(tester, const SettingsPage(), _Settings());
    expect(find.text('实验性功能'), findsNothing);
    expect(find.text('课程实时活动'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Completion graphic has an unfilled circle and a check',
      (tester) async {
    await tester
        .pumpWidget(const MaterialApp(home: Center(child: CompletionMark())));
    final painter = tester
        .widget<CustomPaint>(find.byKey(const ValueKey('introCompletionMark')))
        .painter!;
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      painter.paint(Canvas(recorder), const Size(90, 90));
      final picture = recorder.endRecording();
      final image = await picture.toImage(90, 90);
      final bytes = (await image.toByteData())!;
      int alpha(int x, int y) => bytes.getUint8((y * 90 + x) * 4 + 3);
      expect(alpha(45, 45), 0);
      expect(alpha(0, 0), 0);
      expect(alpha(45, 10), greaterThan(0));
      expect(alpha(40, 58), greaterThan(0));
      image.dispose();
      picture.dispose();
    });
  });
}
