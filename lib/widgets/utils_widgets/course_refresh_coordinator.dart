import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/providers/zhengfang_user_provider.dart';
import 'package:sachet/services/automatic_course_refresh.dart';

/// Refresh on cold start and return from background, never on a tab change.
class CourseRefreshCoordinator extends StatefulWidget {
  const CourseRefreshCoordinator({super.key, required this.child});
  final Widget child;
  @override
  State<CourseRefreshCoordinator> createState() =>
      _CourseRefreshCoordinatorState();
}

class _CourseRefreshCoordinatorState extends State<CourseRefreshCoordinator>
    with WidgetsBindingObserver {
  final _refresh = AutomaticCourseRefresh();
  bool _wasBackground = false;
  bool _loggedIn = false;
  ZhengFangUserProvider? _user;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<ZhengFangUserProvider>();
    if (_user == user) return;
    _user?.removeListener(_onUserChanged);
    _user = user;
    _loggedIn = user.isLogin;
    user.addListener(_onUserChanged);
  }

  void _onUserChanged() {
    final login = _user!.isLogin;
    if (login && !_loggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _run());
    }
    _loggedIn = login;
  }

  void _run() {
    if (!mounted) return;
    unawaited(_refresh
        .refresh(context.read<SettingsProvider>(), _user!,
            isAlive: () => mounted)
        .catchError((Object _) => false));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _wasBackground = true;
    } else if (state == AppLifecycleState.resumed && _wasBackground) {
      _wasBackground = false;
      _run();
    }
  }

  @override
  void dispose() {
    _user?.removeListener(_onUserChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
