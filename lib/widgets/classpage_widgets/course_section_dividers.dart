import 'package:flutter/material.dart';

/// Draw section boundaries behind the timetable without changing its layout.
class CourseSectionDividers extends StatelessWidget {
  const CourseSectionDividers({
    super.key,
    required this.sectionHeight,
    required this.child,
    this.firstSection = 1,
  });

  final double sectionHeight;
  final int firstSection;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SectionDividerPainter(
        sectionHeight: sectionHeight,
        firstSection: firstSection,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
      child: child,
    );
  }
}

class _SectionDividerPainter extends CustomPainter {
  const _SectionDividerPainter({
    required this.sectionHeight,
    required this.firstSection,
    required this.color,
  });

  final double sectionHeight;
  final int firstSection;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (int section = 2; section <= 10; section += 2) {
      final y = sectionHeight * (section - firstSection + 1);
      if (y <= 0) continue;
      if (y > size.height) break;
      canvas.drawLine(Offset(0, y - 0.5), Offset(size.width, y - 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_SectionDividerPainter oldDelegate) =>
      sectionHeight != oldDelegate.sectionHeight ||
      firstSection != oldDelegate.firstSection ||
      color != oldDelegate.color;
}
