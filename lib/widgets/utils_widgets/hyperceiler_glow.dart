// HyperCeiler GlowPainter / glow.glsl port, AGPL-3.0.
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class HyperCeilerGlow extends StatefulWidget {
  const HyperCeilerGlow({super.key});
  @override
  State<HyperCeilerGlow> createState() => _HyperCeilerGlowState();
}

class _HyperCeilerGlowState extends State<HyperCeilerGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController time =
      AnimationController(vsync: this, duration: const Duration(seconds: 120));
  ui.FragmentShader? shader;
  static Future<ui.FragmentProgram>? program;
  @override
  void initState() {
    super.initState();
    program ??=
        ui.FragmentProgram.fromAsset('assets/shaders/hyperceiler_glow.frag');
    program!.then((p) {
      if (mounted) setState(() => shader = p.fragmentShader());
    }).catchError((Object _) {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      time.stop();
    } else if (!time.isAnimating) {
      time.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    time.dispose();
    shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
      child: AnimatedBuilder(
          animation: time,
          builder: (context, _) => CustomPaint(
              painter: _GlowPainter(
                  shader,
                  MediaQuery.disableAnimationsOf(context)
                      ? 3
                      : time.value * 120),
              size: Size.infinite)));
}

class _GlowPainter extends CustomPainter {
  _GlowPainter(this.shader, this.time);
  final ui.FragmentShader? shader;
  final double time;
  static const defaults = [
    0.0,
    0.0,
    0.0,
    0.82,
    0.49,
    0.3,
    1.0,
    0.3,
    0.86,
    0.47,
    1.0,
    0.961,
    0.157,
    0.157,
    0.604,
    0.659,
    0.961,
    0.302,
    0.29,
    0.843,
    1.3,
    0.4,
    0.25,
    1.0,
    0.25,
    1.0,
    1.0,
    0.4,
    1.0,
    0.1,
    0.9,
    1.0,
    0.0,
    1.4,
    0.0,
    0.3,
    0.3,
    1.0,
    0.04,
    0.25,
    0.0,
    0.6,
    0.2,
    0.3,
    0.0,
    1.0,
    0.0,
    0.0,
    0.0,
    0.0
  ];
  @override
  void paint(Canvas canvas, Size size) {
    if (shader == null) {
      canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..shader = const LinearGradient(colors: [
              Color(0xfff8b7ce),
              Color(0xffc9c8f5),
              Color(0xff7375df)
            ]).createShader(Offset.zero & size));
      return;
    }
    for (var i = 0; i < defaults.length; i++) {
      shader!.setFloat(i, defaults[i]);
    }
    shader!
      ..setFloat(0, time)
      ..setFloat(1, size.width)
      ..setFloat(2, size.height);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.time != time || old.shader != shader;
}
