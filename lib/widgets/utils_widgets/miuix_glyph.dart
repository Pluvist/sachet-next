import 'package:flutter/material.dart';

enum MiuixSymbol { home, calendar, person, search, settings }

/// Original stroke icons, independent of external font or bitmap assets.
class MiuixGlyph extends StatelessWidget {
  const MiuixGlyph(this.symbol, {super.key, this.size = 24, this.color});
  final MiuixSymbol symbol;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
          painter: _GlyphPainter(
              symbol,
              color ??
                  IconTheme.of(context).color ??
                  Theme.of(context).colorScheme.onSurface)));
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.symbol, this.color);
  final MiuixSymbol symbol;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (symbol) {
      case MiuixSymbol.home:
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(3, 3, 18, 18), const Radius.circular(4)),
            pen);
        canvas.drawLine(const Offset(3, 10), const Offset(21, 10), pen);
        canvas.drawLine(const Offset(10, 10), const Offset(10, 21), pen);
      case MiuixSymbol.calendar:
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(3, 5, 18, 16), const Radius.circular(3.5)),
            pen);
        canvas.drawLine(const Offset(7, 3), const Offset(7, 7), pen);
        canvas.drawLine(const Offset(17, 3), const Offset(17, 7), pen);
        canvas.drawLine(const Offset(3, 10), const Offset(21, 10), pen);
        for (final x in [7.0, 12.0, 17.0]) {
          canvas.drawCircle(Offset(x, 14), .8, Paint()..color = color);
          canvas.drawCircle(Offset(x, 18), .8, Paint()..color = color);
        }
      case MiuixSymbol.person:
        canvas.drawCircle(const Offset(12, 8), 4, pen);
        canvas.drawPath(
            Path()
              ..moveTo(3, 21)
              ..cubicTo(3, 12, 21, 12, 21, 21)
              ..close(),
            pen);
      case MiuixSymbol.search:
        canvas.drawCircle(const Offset(10, 10), 7, pen);
        canvas.drawLine(const Offset(15.5, 15.5), const Offset(21, 21), pen);
      case MiuixSymbol.settings:
        canvas.drawCircle(const Offset(12, 12), 7.5, pen);
        canvas.drawCircle(const Offset(12, 12), 3, pen);
        for (final delta in [
          const Offset(0, -10),
          const Offset(10, 0),
          const Offset(0, 10),
          const Offset(-10, 0)
        ]) {
          canvas.drawLine(const Offset(12, 12) + delta * .75,
              const Offset(12, 12) + delta, pen);
        }
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) =>
      oldDelegate.symbol != symbol || oldDelegate.color != color;
}
