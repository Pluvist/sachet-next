import 'package:flutter/material.dart';
import 'package:sachet/utils/building_schedule.dart';

class SchoolTimeRail extends StatelessWidget {
  const SchoolTimeRail({super.key, required this.axis, required this.routines});
  final SchoolTimeAxis axis;
  final Set<BuildingRoutine> routines;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ordered = BuildingRoutine.values.where(routines.contains).toList();
    return LayoutBuilder(builder: (context, constraints) {
      final columnWidth = constraints.maxWidth / ordered.length;
      final labels = <Widget>[];
      for (int section = 1; section <= 11; section++) {
        final merged = section >= 9 && ordered.length == 2;
        for (int column = 0; column < (merged ? 1 : ordered.length); column++) {
          final routine = ordered[column];
          final time = BuildingSchedule.lesson(section, routine);
          final left = merged ? 0.0 : columnWidth * column;
          final width = merged ? constraints.maxWidth : columnWidth;
          final color = routine == BuildingRoutine.staggered && !merged
              ? colors.primary
              : colors.onSurfaceVariant;
          Widget label(String text, String edge) => Padding(
                key: ValueKey('rail-${routine.name}-$section-$edge'),
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: FittedBox(
                    alignment: Alignment.center,
                    fit: BoxFit.scaleDown,
                    child: Text(text,
                        style:
                            TextStyle(fontSize: 10, height: 1, color: color))),
              );
          labels.add(Positioned(
              left: left,
              width: width,
              top: axis.displayY(time.start, routine),
              height: 12,
              child: label(formatMinute(time.start), 'start')));
          labels.add(Positioned(
              left: left,
              width: width,
              top: axis.displayY(time.end, routine) - 12,
              height: 12,
              child: label(formatMinute(time.end), 'end')));
          labels.add(Positioned(
              left: left,
              width: width,
              top: (axis.displayY(time.start, routine) +
                          axis.displayY(time.end, routine)) /
                      2 -
                  8,
              height: 16,
              child: Center(
                  child: Text('$section',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color)))));
        }
      }
      return SizedBox(height: axis.height, child: Stack(children: labels));
    });
  }
}

class SchoolTimeGrid extends StatelessWidget {
  const SchoolTimeGrid(
      {super.key,
      required this.axis,
      required this.showStaggered,
      required this.child});
  final SchoolTimeAxis axis;
  final bool showStaggered;
  final Widget child;
  @override
  Widget build(BuildContext context) => CustomPaint(
      painter: _TimeGridPainter(
          axis, showStaggered, Theme.of(context).colorScheme.outlineVariant),
      child: child);
}

class _TimeGridPainter extends CustomPainter {
  const _TimeGridPainter(this.axis, this.showStaggered, this.color);
  final SchoolTimeAxis axis;
  final bool showStaggered;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;
    for (int section = 1; section <= 11; section++) {
      final y = axis
          .y(BuildingSchedule.lesson(section, BuildingRoutine.normal).start);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (final section in [2, 4, 6, 8, 10]) {
      final y =
          axis.y(BuildingSchedule.lesson(section, BuildingRoutine.normal).end);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      if (showStaggered && section <= 8) {
        final shifted = axis.displayY(
            BuildingSchedule.lesson(section, BuildingRoutine.staggered).end,
            BuildingRoutine.staggered);
        paint.color = color.withOpacity(0.6);
        for (double x = 0; x < size.width; x += size.width / 7) {
          canvas.drawLine(Offset(x, shifted), Offset(x + 8, shifted), paint);
        }
        paint.color = color;
      }
    }
  }

  @override
  bool shouldRepaint(_TimeGridPainter old) =>
      old.axis.sectionHeight != axis.sectionHeight ||
      old.showStaggered != showStaggered ||
      old.color != color;
}
