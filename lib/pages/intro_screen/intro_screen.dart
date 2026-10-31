// HyperCeiler provision layout and glow adaptation. AGPL-3.0.
// Copyright (C) 2023-2026 HyperCeiler Contributions; adaptation Pluvist.
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/enums/nav_type.dart';
import 'package:sachet/pages/home_page.dart';
import 'package:sachet/pages/with_navbar_view.dart';
import 'package:sachet/pages/intro_screen/agreement_page.dart';
import 'package:sachet/pages/intro_screen/background_setup_page.dart';
import 'package:sachet/providers/screen_nav_provider.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/widgets/utils_widgets/hyperceiler_glow.dart';
import 'package:sachet/widgets/utils_widgets/miuix_glyph.dart';
import 'package:sachet/widgets/utils_widgets/source_expand_route.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key, this.homeBuilder});
  final WidgetBuilder? homeBuilder;
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _arrowKey = GlobalKey();
  final _homeKey = GlobalKey();
  Widget? _preparedHome;
  Future<void>? _preparing;
  bool _homeHandedOff = false;
  bool _opening = false;

  Future<void> _prepareHome() => _preparing ??= _warmHome();
  Future<void> _warmHome() async {
    if (!mounted) return;
    final settings = context.read<SettingsProvider>();
    // Prepare the real retained subtree, not a throwaway copy of the page.
    context.read<ScreenNavProvider>().setCurrentPage('/home');
    AppGlobal.homeEntrancePending = true;
    final drawer =
        SettingsProvider.navigationType == NavType.navigationDrawer.type;
    setState(() => _preparedHome = widget.homeBuilder?.call(context) ??
        (drawer ? const HomePage() : const WithNavigationBarView()));
    // Disk/platform delays must not hold the finish transition hostage.
    unawaited(settings
        .loadCourseScheduleData()
        .then<void>((_) {}, onError: (Object _, StackTrace __) {}));
    if (mounted) await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _finish(BuildContext source, GlobalKey arrow) async {
    await _prepareHome();
    if (!mounted || !source.mounted || _homeHandedOff) return;
    final settings = context.read<SettingsProvider>();
    settings.setStartupPage('/home');
    AppGlobal.startupPage = '/home';
    AppGlobal.homeEntrancePending = false;
    final drawer =
        SettingsProvider.navigationType == NavType.navigationDrawer.type;
    final destination = KeyedSubtree(key: _homeKey, child: _preparedHome!);
    // Move the mounted home into the route in the same frame. Its providers,
    // cached futures, scroll positions and render objects survive the handoff.
    setState(() => _homeHandedOff = true);
    expandHomeAndRemoveHistory(source, destination,
        sourceKey: arrow,
        sourceColor: Theme.of(source).colorScheme.primary,
        settings: RouteSettings(name: drawer ? '/home' : '/navBarView'),
        onExpanded: settings.setHasReadDisclaimer);
  }

  Future<void> _next() async {
    if (_opening) return;
    setState(() => _opening = true);
    await expandPage<bool>(
        context,
        AgreementPage(
            afterAccount: (_) => BackgroundSetupPage(
                onPrepareHome: _prepareHome,
                completionBuilder: (_) =>
                    IntroCompletionPage(onFinish: _finish))),
        sourceKey: _arrowKey,
        sourceRadius: 35,
        sourceColor: Colors.black.withOpacity(.6));
    if (mounted) setState(() => _opening = false);
  }

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        if (_preparedHome != null && !_homeHandedOff)
          Offstage(
              offstage: true,
              child: ExcludeFocus(
                  child: TickerMode(
                      enabled: false,
                      child:
                          KeyedSubtree(key: _homeKey, child: _preparedHome!)))),
        _IntroScene(
            completed: false,
            opening: _opening,
            arrowKey: _arrowKey,
            onNext: _next),
      ]);
}

class IntroCompletionPage extends StatefulWidget {
  const IntroCompletionPage({super.key, required this.onFinish});
  final Future<void> Function(BuildContext, GlobalKey) onFinish;
  @override
  State<IntroCompletionPage> createState() => _IntroCompletionPageState();
}

class _IntroCompletionPageState extends State<IntroCompletionPage> {
  final _arrowKey = GlobalKey();
  bool _opening = false;
  Future<void> _finish() async {
    if (_opening) return;
    setState(() => _opening = true);
    await widget.onFinish(context, _arrowKey);
  }

  @override
  Widget build(BuildContext context) => _IntroScene(
      completed: true, opening: _opening, arrowKey: _arrowKey, onNext: _finish);
}

class _IntroScene extends StatelessWidget {
  const _IntroScene(
      {required this.completed,
      required this.opening,
      required this.arrowKey,
      required this.onNext});
  final bool completed, opening;
  final GlobalKey arrowKey;
  final VoidCallback onNext;
  @override
  Widget build(BuildContext context) => TickerMode(
      enabled: !opening,
      child: Scaffold(
          body: Stack(fit: StackFit.expand, children: [
        const Positioned.fill(child: IgnorePointer(child: HyperCeilerGlow())),
        SafeArea(
            child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 35),
                            child: Column(children: [
                              SizedBox(
                                  height: math.max(
                                      40, constraints.maxHeight * .27)),
                              if (completed)
                                const CompletionMark()
                              else
                                const SizedBox(height: 90),
                              const SizedBox(height: 24),
                              FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      child: Text(
                                          completed ? '设置完成' : 'Xachet',
                                          style: TextStyle(
                                              fontSize: completed ? 32 : 38,
                                              fontWeight: FontWeight.w700,
                                              height: 1.25,
                                              color: Colors.black)))),
                              const SizedBox(height: 8),
                              Text(completed ? '一切准备就绪' : '让每一天，井然有序',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black.withOpacity(.65))),
                              SizedBox(
                                  height: math.max(
                                      40, constraints.maxHeight * .22)),
                              Semantics(
                                  button: true,
                                  label: completed ? '开始使用' : '下一步',
                                  child: ExpansionAnchor(
                                      key: arrowKey,
                                      child: Material(
                                          color: completed
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Colors.black.withOpacity(.6),
                                          shape: const CircleBorder(),
                                          child: InkWell(
                                              key: ValueKey(completed
                                                  ? 'introFinish'
                                                  : 'introNext'),
                                              customBorder:
                                                  const CircleBorder(),
                                              onTap: opening ? null : onNext,
                                              child: const SizedBox.square(
                                                  dimension: 70,
                                                  child: Center(
                                                      child: MiuixGlyph(
                                                          MiuixSymbol.next,
                                                          size: 26,
                                                          color: Colors
                                                              .white))))))),
                              const SizedBox(height: 44),
                            ])))))),
      ])));
}

/// Original vector mark: an unfilled circle containing a rounded check.
class CompletionMark extends StatelessWidget {
  const CompletionMark({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.square(
      dimension: 90,
      child: CustomPaint(
          key: ValueKey('introCompletionMark'), painter: _CompletionPainter()));
}

class _CompletionPainter extends CustomPainter {
  const _CompletionPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 90, size.height / 90);
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawCircle(const Offset(45, 45), 35, paint);
    canvas.drawPath(
        Path()
          ..moveTo(27, 45)
          ..lineTo(40, 58)
          ..lineTo(64, 33),
        paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CompletionPainter oldDelegate) => false;
}
