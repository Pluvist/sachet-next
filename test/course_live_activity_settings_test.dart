import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sachet/pages/settings_child_pages/course_live_activity_settings_page.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/services/course_widget_bridge.dart';
import 'package:sachet/utils/expressive_theme.dart';

class _Settings extends SettingsProvider {
  bool enabled = true;
  @override
  bool get isEnableCourseLiveActivity => enabled;
  @override
  void setEnableCourseLiveActivity(bool value) {
    enabled = value;
    notifyListeners();
  }
}

void main() {
  testWidgets(
      'Activity controls save opt-out and open the correct system permission screens',
      (tester) async {
    final calls = <MethodCall>[];
    var notificationsAllowed = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(CourseWidgetBridge.channel, (call) async {
      calls.add(call);
      if (call.method == 'liveStatus') {
        return {
          'supported': true,
          'notifications': notificationsAllowed,
          'promoted': true,
          'exactAlarms': true,
        };
      }
      return null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(CourseWidgetBridge.channel, null));
    final settings = _Settings();
    addTearDown(settings.dispose);
    await tester.pumpWidget(ChangeNotifierProvider<SettingsProvider>.value(
        value: settings,
        child: MaterialApp(
            theme: applyExpressiveTheme(ThemeData()),
            home: const CourseLiveActivitySettingsPage())));
    await tester.pumpAndSettle();
    expect(find.text('系统已允许实时活动'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(settings.enabled, false);
    expect(calls.where((c) => c.method == 'livePermission'), isEmpty);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(settings.enabled, true);
    expect(
        calls.lastWhere((c) => c.method == 'livePermission').arguments, false);
    await tester.tap(find.text('通知权限'));
    await tester.pumpAndSettle();
    expect(
        calls.lastWhere((c) => c.method == 'livePermission').arguments, isNull);
    await tester.tap(find.text('系统实时活动'));
    await tester.pumpAndSettle();
    expect(calls.lastWhere((c) => c.method == 'liveSettings').arguments,
        'promoted');
    await tester.ensureVisible(find.text('准时更新'));
    await tester.tap(find.text('准时更新'));
    await tester.pumpAndSettle();
    expect(
        calls.lastWhere((c) => c.method == 'liveSettings').arguments, 'exact');
    notificationsAllowed = false;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('允许通知后显示课程状态'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
