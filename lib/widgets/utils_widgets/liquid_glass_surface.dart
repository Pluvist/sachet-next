import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:sachet/widgets/utils_widgets/glass_backdrop.dart';

class LiquidGlassSurface extends StatefulWidget {
  const LiquidGlassSurface(
      {super.key,
      required this.child,
      this.radius = 100,
      this.blur = 8,
      this.lensHeight = 24,
      this.lensAmount = 24,
      this.dispersion = 0,
      this.tint});
  final Widget child;
  final double radius, blur, lensHeight, lensAmount, dispersion;
  final Color? tint;
  @override
  State<LiquidGlassSurface> createState() => _LiquidGlassSurfaceState();
}

class _LiquidGlassSurfaceState extends State<LiquidGlassSurface> {
  static Future<ui.FragmentProgram?>? program;
  ui.FragmentShader? shader;
  final surfaceKey = GlobalKey();
  @override
  void initState() {
    super.initState();
    program ??= ui.FragmentProgram.fromAsset('assets/shaders/nexio_lens.frag')
        .then<ui.FragmentProgram?>((p) => p)
        .catchError((_) => null);
    program!.then((p) {
      if (mounted && p != null) setState(() => shader = p.fragmentShader());
    });
  }

  @override
  void dispose() {
    shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
        key: surfaceKey,
        borderRadius: BorderRadius.circular(widget.radius),
        child: BackdropFilter(
            filter:
                ui.ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
            child: ValueListenableBuilder<ui.Image?>(
                valueListenable: GlassBackdrop.image,
                builder: (context, image, _) => CustomPaint(
                    painter:
                        image != null && shader != null && widget.lensHeight > 0
                            ? _LensPainter(shader!, image, () {
                                final box = surfaceKey.currentContext
                                    ?.findRenderObject() as RenderBox?;
                                return box?.localToGlobal(Offset.zero) ??
                                    Offset.zero;
                              },
                                widget.radius,
                                widget.lensHeight,
                                widget.lensAmount,
                                widget.dispersion,
                                widget.blur)
                            : null,
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(widget.radius),
                            color: widget.tint ??
                                (dark
                                        ? const Color(0xff242424)
                                        : const Color(0xfffafafa))
                                    .withOpacity(.6),
                            border: Border.all(
                                color: (dark ? Colors.white : Colors.black)
                                    .withOpacity(dark ? .22 : .12),
                                width: .5)),
                        child: widget.child)))));
  }
}

class _LensPainter extends CustomPainter {
  _LensPainter(this.shader, this.image, this.getOrigin, this.radius,
      this.height, this.amount, this.dispersion, this.blur);
  final ui.FragmentShader shader;
  final ui.Image image;
  final Offset Function() getOrigin;
  final double radius, height, amount, dispersion, blur;
  @override
  void paint(Canvas canvas, Size size) {
    final origin = getOrigin() - GlassBackdrop.origin;
    final values = [
      size.width,
      size.height,
      origin.dx,
      origin.dy,
      image.width.toDouble(),
      image.height.toDouble(),
      radius.clamp(0, size.shortestSide / 2).toDouble(),
      height,
      amount,
      dispersion
    ];
    for (var i = 0; i < values.length; i++) {
      shader.setFloat(i, values[i]);
    }
    shader.setImageSampler(0, image);
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = shader
          ..imageFilter = ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur));
  }

  @override
  bool shouldRepaint(_LensPainter old) => true;
}
