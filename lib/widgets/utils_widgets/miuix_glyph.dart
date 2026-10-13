import 'package:flutter/material.dart';

enum MiuixSymbol {
  home,
  calendar,
  person,
  search,
  settings,
  more,
  previous,
  next,
  refresh,
  swap,
  share,
  view,
  tune,
  check
}

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
      case MiuixSymbol.more:
        for (final y in [5.0, 12.0, 19.0]) {
          canvas.drawCircle(Offset(12, y), 1.6, Paint()..color = color);
        }
      case MiuixSymbol.previous:
      case MiuixSymbol.next:
        if (symbol == MiuixSymbol.next) {
          canvas.translate(24, 0);
          canvas.scale(-1, 1);
        }
        canvas.drawPath(
            Path()
              ..moveTo(15, 5)
              ..lineTo(8, 12)
              ..lineTo(15, 19),
            pen);
      case MiuixSymbol.refresh:
        canvas.drawArc(const Rect.fromLTWH(4, 4, 16, 16), .5, 5.2, false, pen);
        canvas.drawPath(
            Path()
              ..moveTo(15, 3)
              ..lineTo(20, 4)
              ..lineTo(19, 9),
            pen);
      case MiuixSymbol.swap:
        canvas.drawPath(
            Path()
              ..moveTo(3, 8)
              ..lineTo(21, 8)
              ..lineTo(17, 4)
              ..moveTo(21, 16)
              ..lineTo(3, 16)
              ..lineTo(7, 20),
            pen);
      case MiuixSymbol.share:
        canvas.drawPath(
            Path()
              ..moveTo(4, 12)
              ..lineTo(4, 20)
              ..lineTo(20, 20)
              ..lineTo(20, 12)
              ..moveTo(12, 15)
              ..lineTo(12, 3)
              ..moveTo(7, 8)
              ..lineTo(12, 3)
              ..lineTo(17, 8),
            pen);
      case MiuixSymbol.view:
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(3, 4, 18, 16), const Radius.circular(4)),
            pen);
        canvas.drawLine(const Offset(3, 10), const Offset(21, 10), pen);
        canvas.drawLine(const Offset(9, 10), const Offset(9, 20), pen);
        canvas.drawLine(const Offset(15, 10), const Offset(15, 20), pen);
      case MiuixSymbol.tune:
        for (var i = 0; i < 3; i++) {
          final y = 6.0 + i * 6;
          canvas.drawLine(Offset(3, y), Offset(21, y), pen);
          canvas.drawCircle(
              Offset(i == 1 ? 15 : 8, y), 2, Paint()..color = color);
        }
      case MiuixSymbol.check:
        canvas.drawPath(
            Path()
              ..moveTo(5, 12.5)
              ..lineTo(10, 17.5)
              ..lineTo(19, 7),
            pen);
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
