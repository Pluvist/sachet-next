import 'package:flutter/material.dart';

/// Vector artwork, kept crisp at any screen density and in either theme.
class CourseStatusIcon extends StatelessWidget {
  const CourseStatusIcon(
      {super.key, required this.completed, required this.color});
  final bool completed;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: IgnorePointer(
          child: CustomPaint(
            painter: _CourseStatusPainter(completed: completed, color: color),
          ),
        ),
      );
}

class _CourseStatusPainter extends CustomPainter {
  const _CourseStatusPainter({required this.completed, required this.color});
  final bool completed;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (completed) {
      canvas.drawCircle(const Offset(50, 50), 44, stroke);
      canvas.drawPath(
          Path()
            ..moveTo(27, 51)
            ..lineTo(43, 67)
            ..lineTo(75, 34),
          stroke);
    } else {
      // Open doorway and a forward-striding figure, based on the supplied sign.
      canvas.drawPath(
          Path()
            ..moveTo(29, 82)
            ..lineTo(29, 8)
            ..lineTo(85, 8)
            ..lineTo(85, 91)
            ..lineTo(68, 91),
          stroke..strokeWidth = 6);
      canvas.drawCircle(const Offset(60, 24), 8, fill);
      canvas.drawPath(
          Path()
            ..moveTo(38, 39)
            ..lineTo(58, 39)
            ..quadraticBezierTo(63, 39, 66, 44)
            ..lineTo(59, 64)
            ..lineTo(46, 62)
            ..lineTo(48, 47)
            ..lineTo(36, 47)
            ..close(),
          fill);
      stroke.strokeWidth = 9;
      canvas.drawPath(
          Path()
            ..moveTo(39, 43)
            ..lineTo(27, 60)
            ..moveTo(63, 44)
            ..lineTo(73, 57)
            ..lineTo(88, 57)
            ..moveTo(48, 59)
            ..lineTo(41, 76)
            ..lineTo(17, 76)
            ..moveTo(55, 62)
            ..lineTo(71, 85),
          stroke);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CourseStatusPainter oldDelegate) =>
      completed != oldDelegate.completed || color != oldDelegate.color;
}
