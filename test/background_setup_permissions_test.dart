import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sachet/pages/intro_screen/background_setup_page.dart';
import 'package:sachet/services/course_widget_bridge.dart';

void main() {
  testWidgets(
      'Requests notifications then opens autostart and refreshes status',
      (tester) async {
    final calls = <String>[];
    var granted = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(CourseWidgetBridge.channel, (call) async {
      calls.add('${call.method}:${call.arguments}');
      switch (call.method) {
        case 'backgroundStatus':
          return {
            'batteryUnrestricted': granted,
            'autostartAvailable': true,
            'widgetCount': granted ? 1 : 0,
            'live': {
              'supported': true,
              'notifications': granted,
              'promoted': granted,
            }
          };
        case 'setupNotificationPermission':
          return false;
        case 'backgroundSettings':
          return true;
      }
      return null;
    });
    await tester.pumpWidget(const MaterialApp(home: BackgroundSetupPage()));
    await tester.pumpAndSettle();
    expect(calls.indexOf('setupNotificationPermission:null'),
        lessThan(calls.indexOf('backgroundSettings:autostart')));
    expect(find.text('请允许通知，以显示课程状态'), findsOneWidget);
    expect(find.text('请在系统中允许实时活动'), findsOneWidget);
    expect(find.text('请在系统设置中开启；系统不提供状态查询'), findsOneWidget);

    granted = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(find.text('已允许通知'), findsOneWidget);
    expect(find.text('已允许实时活动'), findsOneWidget);
    expect(find.text('系统电池优化已放行'), findsOneWidget);
    expect(find.text('桌面已添加课程小组件，可继续添加其他尺寸'), findsOneWidget);
    expect(calls.where((c) => c == 'backgroundSettings:autostart').length, 1);

    granted = false;
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('请允许通知，以显示课程状态'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
