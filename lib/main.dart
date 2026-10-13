import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sachet/models/enums/nav_type.dart';
import 'package:sachet/pages/intro_screen/intro_screen.dart';
import 'package:sachet/pages/profile_page.dart';
import 'package:sachet/pages/with_navbar_view.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/providers/course_card_settings_provider.dart';
import 'package:sachet/providers/screen_nav_provider.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/providers/theme_provider.dart';
import 'package:sachet/providers/zhengfang_user_provider.dart';
import 'package:sachet/pages/class_page.dart';
import 'package:sachet/pages/home_page.dart';
import 'package:sachet/pages/settings_page.dart';
import 'package:sachet/pages/about_page.dart';
import 'package:sachet/services/check_update.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:sachet/utils/expressive_theme.dart';
import 'package:sachet/widgets/utils_widgets/course_refresh_coordinator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      ['Sachet'],
      await rootBundle.loadString('LICENSE-MIT'),
    );
    yield LicenseEntryWithLineBreaks(
        ['Sachet Next', 'NexioSchedule', 'HyperCeiler onboarding'],
        await rootBundle.loadString('LICENSE'));
    yield LicenseEntryWithLineBreaks([
      'Kyant Backdrop'
    ], await rootBundle.loadString('third_party/nexio/LICENSE-Apache-2.0.txt'));
    yield LicenseEntryWithLineBreaks(
      ['Noto Serif SC Titles'],
      await rootBundle.loadString('assets/fonts/NotoSerifSC-LICENSE.txt'),
    );
  });

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
  ));

  AppGlobal.init().then((e) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ZhengFangUserProvider()..init()),
        ChangeNotifierProvider(create: (_) => CourseCardSettingsProvider()),
        ChangeNotifierProvider(create: (_) => ScreenNavProvider()),
      ],
      child: CourseRefreshCoordinator(child: Builder(builder: (context) {
        // 强制初始化所有需要提前加载的 Provider
        context.read<ZhengFangUserProvider>();
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            final ThemeData theme = _buildThemeDataFromSeedColor(
              brightness: Brightness.light,
              themeProvider: themeProvider,
            );
            final ThemeData darkTheme = _buildThemeDataFromSeedColor(
              brightness: Brightness.dark,
              themeProvider: themeProvider,
            );
            return _buildMaterialApp(
              theme: theme,
              darkTheme: darkTheme,
              themeProvider: themeProvider,
            );
          },
        );
      })),
    );
  }

  // 构建 MaterialApp（复用）
  Widget _buildMaterialApp({
    required ThemeData theme,
    required ThemeData darkTheme,
    required ThemeProvider themeProvider,
  }) {
    return MaterialApp(
      title: 'Sachet Next',
      scaffoldMessengerKey: SnackbarGlobal.key,
      navigatorKey: NavigatorGlobal.navigatorKey,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('zh', 'CN'), // 中文
      ],
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.values[themeProvider.themeMode],
      theme: theme,
      darkTheme: darkTheme,
      initialRoute:
          // 如果没有阅读过声明，进入引导页
          AppGlobal.appSettings.hasReadDisclaimer != true
              ? '/intro'
              : SettingsProvider.navigationType == NavType.navigationDrawer.type
                  ? AppGlobal.appSettings.startupPage ?? '/class'
                  : '/navBarView',
      routes: {
        '/class': (context) => ClassPage(),
        '/home': (context) => HomePage(),
        '/settings': (context) => SettingsPage(),
        '/about': (context) => AboutPage(),
        '/profile': (context) => ProfilePage(),
        '/navBarView': (context) => WithNavigationBarView(),
        '/intro': (context) => IntroScreen(),
      },
    );
  }

  ThemeData _buildThemeDataFromSeedColor({
    required Brightness brightness,
    required ThemeProvider themeProvider,
  }) {
    return applyExpressiveTheme(
        ThemeData(
          colorSchemeSeed: themeProvider.themeColor,
          brightness: brightness,
          useMaterial3: true,
          pageTransitionsTheme: PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: themeProvider.transitionBuilder,
              TargetPlatform.iOS: themeProvider.transitionBuilder,
              TargetPlatform.macOS: themeProvider.transitionBuilder,
              TargetPlatform.linux: themeProvider.transitionBuilder,
              TargetPlatform.windows: themeProvider.transitionBuilder,
              TargetPlatform.fuchsia: themeProvider.transitionBuilder,
            },
          ),
        ),
        accent: themeProvider.themeColor);
  }
}
