import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/app_settings.dart';
import 'package:sachet/models/course_card_settings.dart';
import 'package:sachet/pages/home_page.dart';
import 'package:sachet/pages/profile_page.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/providers/screen_nav_provider.dart';
import 'package:sachet/providers/zhengfang_user_provider.dart';
import 'package:sachet/services/automatic_course_refresh.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/utils/expressive_theme.dart';
import 'package:sachet/utils/miuix_shapes.dart';
import 'package:sachet/widgets/homepage_widgets/card_widget.dart';
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
  setUp(() {
    AppGlobal.appSettings = AppSettings.fromJson(defaultAppSettingsConfig);
    AppGlobal.courseCardSettings = CourseCardSettings();
    AppGlobal.homeEntrancePending = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
            (_) async => null);
  });
  Future<void> app(WidgetTester tester, Widget home,
      {SettingsProvider? settings,
      _Refresh? refresh,
      GlobalKey<NavigatorState>? navigator}) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final body = MaterialApp(
        navigatorKey: navigator,
        theme: applyExpressiveTheme(ThemeData()),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: false),
            child: child!),
        home: home);
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(
              value: settings ?? SettingsProvider()),
          ChangeNotifierProvider(create: (_) => ZhengFangUserProvider()),
          ChangeNotifierProvider(create: (_) => ScreenNavProvider()),
        ],
        child: refresh == null
            ? body
            : CourseRefreshCoordinator(refresh: refresh, child: body)));
    await tester.pumpAndSettle();
  }

  testWidgets('Profile offers both compact and horizontal course widgets',
      (tester) async {
    await app(tester, const ProfilePage());
    await tester.tap(find.text('桌面课程小组件'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('widgetLayoutCompact')), findsOneWidget);
    expect(find.byKey(const ValueKey('widgetLayoutWide')), findsOneWidget);
    expect(find.text('4×2 横向课程概览'), findsOneWidget);
    Navigator.of(tester.element(find.text('选择小组件布局'))).pop();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile circle is 44dp and the entire circle expands',
      (tester) async {
    await app(tester, const HomePage());
    final button = find.byKey(const ValueKey('homeProfileButton'));
    final anchor =
        find.ancestor(of: button, matching: find.byType(ExpansionAnchor)).first;
    final source = tester.getRect(anchor);
    expect(source.size, const Size.square(44));
    final material = tester.widget<Material>(
        find.ancestor(of: button, matching: find.byType(Material)).first);
    expect(material.shape, isA<CircleBorder>());
    await tester.tap(button);
    await tester.pump();
    await tester.pump();
    final mask = tester
        .widget<ClipPath>(find.byKey(const ValueKey('sourceExpansionMask')));
    final clipper = mask.clipper! as ControlExpansionClipper;
    expect(clipper.source, source);
    expect(clipper.sourceRadius, 22);
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsOneWidget);
    Navigator.of(tester.element(find.byType(ProfilePage))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Feature card expansion uses card edges and actual panel radius',
      (tester) async {
    await app(tester, const HomePage());
    final feature = find.byType(CardWidget).first;
    final source = tester.getRect(feature);
    final sourceAnchor =
        find.descendant(of: feature, matching: find.byType(ExpansionAnchor));
    expect(tester.getRect(sourceAnchor), source);
    expect(source.width, greaterThan(150));
    expect(source.height, 76);
    await tester.tap(feature);
    await tester.pump();
    await tester.pump();
    final mask = tester
        .widget<ClipPath>(find.byKey(const ValueKey('sourceExpansionMask')));
    final clipper = mask.clipper! as ControlExpansionClipper;
    expect(clipper.source, source);
    expect(clipper.sourceRadius, MiuixRadii.panel);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Home shares the handoff clock; history and refresh change only at completion',
      (tester) async {
    final settings = _Settings();
    final refresh = _Refresh();
    final navigator = GlobalKey<NavigatorState>();
    final anchor = GlobalKey();
    await app(
        tester,
        Scaffold(
            body: Center(
                child: Builder(
                    builder: (context) => ExpansionAnchor(
                        key: anchor,
                        child: SizedBox.square(
                            dimension: 70,
                            child: TextButton(
                                onPressed: () {
                                  AppGlobal.homeEntrancePending = true;
                                  expandHomeAndRemoveHistory(
                                      context, const HomePage(),
                                      sourceKey: anchor,
                                      settings: const RouteSettings(
                                          name: '/navBarView'),
                                      onExpanded: settings.finish);
                                },
                                child: const Text('Finish guide'))))))),
        settings: settings,
        refresh: refresh,
        navigator: navigator);
    expect(refresh.calls, 0);
    await tester.tap(find.text('Finish guide'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final homeContext = tester.element(find.byType(HomePage));
    final route = ModalRoute.of(homeContext)! as SourceExpandRoute;
    expect(route.homeHandoff, true);
    expect(settings.finished, false);
    expect(refresh.calls, 0);
    for (final entry
        in tester.widgetList<HomeEntrance>(find.byType(HomeEntrance))) {
      expect(identical(entry.animation, route.expansionAnimation), true);
    }
    expect(route.expansionAnimation.value, inExclusiveRange(0.0, 1.0));
    await navigator.currentState!.maybePop();
    await tester.pump();
    expect(route.isCurrent, true);
    await tester.pumpAndSettle();
    expect(settings.finished, true);
    expect(refresh.calls, 1);
    expect(navigator.currentState!.canPop(), false);
    expect(find.text('Finish guide'), findsNothing);
    expect(route.expansionAnimation.value, 1);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    settings.dispose();
  });
}
