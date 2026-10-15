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
  testWidgets('Source page expands from tapped bounds and hides old page',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
                child: Builder(
                    builder: (context) => SizedBox(
                        width: 70,
                        height: 70,
                        child: TextButton(
                            onPressed: () => expandPage(context,
                                const Scaffold(body: Text('Destination'))),
                            child: const Text('Arrow'))))))));
    final source = tester.getRect(find.byType(TextButton));
    await tester.tap(find.text('Arrow'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    final reveal = find
        .ancestor(
            of: find.text('Destination'), matching: find.byType(ClipRRect))
        .first;
    expect(tester.getRect(reveal).width, closeTo(source.width, 8));
    await tester.pump(const Duration(milliseconds: 200));
    final middle = tester.getRect(reveal);
    expect(middle.width, greaterThan(source.width));
    expect(middle.width, lessThan(800));
    await tester.pumpAndSettle();
    expect(tester.getRect(reveal), const Rect.fromLTWH(0, 0, 800, 600));
    expect(find.text('Arrow'), findsNothing);
    Navigator.of(tester.element(find.text('Destination'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Arrow'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Entrance uses nonlinear easing and reaches exact final geometry',
      (tester) async {
    final progress = ValueNotifier<double>(0);
    final animation = Animation<double>.fromValueListenable(progress);
    await tester.pumpWidget(MaterialApp(
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
    await tester.pump();
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
