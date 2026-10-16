// HyperCeiler provision layout and glow adaptation. AGPL-3.0.
// Copyright (C) 2023-2026 HyperCeiler Contributions; adaptation Pluvist.
import 'dart:math' as math;
import 'package:sachet/providers/screen_nav_provider.dart';
import 'package:sachet/widgets/utils_widgets/source_expand_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/enums/nav_type.dart';
import 'package:sachet/pages/intro_screen/agreement_page.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/widgets/utils_widgets/hyperceiler_glow.dart';
import 'package:sachet/widgets/utils_widgets/miuix_glyph.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _arrowKey = GlobalKey();
  bool completed = false;
  bool opening = false;
  void _finish() {
    context.read<SettingsProvider>().setStartupPage('/home');
    AppGlobal.startupPage = '/home';
    AppGlobal.homeEntrancePending = true;
    context.read<ScreenNavProvider>().setCurrentPage('/home');
    context.read<SettingsProvider>().setHasReadDisclaimer();
    Navigator.of(context).pushNamedAndRemoveUntil(
        SettingsProvider.navigationType == NavType.navigationDrawer.type
            ? '/home'
            : '/navBarView',
        (_) => false);
  }

  Future<void> _next() async {
    if (opening) return;
    if (completed) {
      _finish();
      return;
    }
    setState(() => opening = true);
    final result = await expandPage<bool>(context, const AgreementPage(),
        sourceKey: _arrowKey,
        sourceRadius: 35,
        sourceColor: Colors.black.withOpacity(.6));
    if (!mounted) return;
    setState(() {
      opening = false;
      completed = result == true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const foreground = Colors.black;
    return Scaffold(
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
                                height:
                                    math.max(40, constraints.maxHeight * .27)),
                            if (completed)
                              const _IntroMark(completed: true)
                            else
                              const SizedBox(height: 90),
                            const SizedBox(height: 24),
                            FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    child: Text(
                                        completed ? '设置完成' : 'Sachet Next',
                                        style: TextStyle(
                                            fontSize: completed ? 32 : 38,
                                            fontWeight: FontWeight.w700,
                                            height: 1.25,
                                            color: foreground)))),
                            const SizedBox(height: 8),
                            Text(completed ? '一切准备就绪' : '让每一天，井然有序',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 14,
                                    color: foreground.withOpacity(.65))),
                            SizedBox(
                                height:
                                    math.max(40, constraints.maxHeight * .22)),
                            Semantics(
                                button: true,
                                label: completed ? '开始使用' : '下一步',
                                child: ExpansionAnchor(
                                    key: _arrowKey,
                                    child: Material(
                                        color: completed
                                            ? colors.primary
                                            : Colors.black.withOpacity(.6),
                                        shape: const CircleBorder(),
                                        child: InkWell(
                                            key: ValueKey(completed
                                                ? 'introFinish'
                                                : 'introNext'),
                                            customBorder: const CircleBorder(),
                                            onTap: opening ? null : _next,
                                            child: const SizedBox.square(
                                                dimension: 70,
                                                child: Center(
                                                    child: MiuixGlyph(
                                                        MiuixSymbol.next,
                                                        size: 26,
                                                        color:
                                                            Colors.white))))))),
                            const SizedBox(height: 44),
                          ])))))),
    ]));
  }
}

class _IntroMark extends StatelessWidget {
  const _IntroMark({required this.completed});
  final bool completed;
  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: BoxDecoration(
          color: Colors.black, borderRadius: BorderRadius.circular(25)),
      child: SizedBox.square(
          dimension: 90, child: CustomPaint(painter: _MarkPainter(completed))));
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.completed);
  final bool completed;
  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = Colors.white;
    if (completed) {
      canvas.drawPath(
          Path()
            ..moveTo(25, 46)
            ..lineTo(39, 60)
            ..lineTo(66, 32),
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round);
    } else {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(24, 32, 42, 42), const Radius.circular(14)),
          fill);
      canvas.drawPath(
          Path()
            ..moveTo(31, 17)
            ..lineTo(59, 17)
            ..lineTo(53, 31)
            ..lineTo(37, 31)
            ..close(),
          fill);
      canvas.drawPath(
          Path()
            ..moveTo(17, 48)
            ..quadraticBezierTo(20, 25, 45, 28)
            ..quadraticBezierTo(69, 25, 73, 48),
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.completed != completed;
}
