import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sachet/widgets/homepage_widgets/course_status_icon.dart';
import 'package:sachet/widgets/utils_widgets/miuix_glyph.dart';

void main() {
  const ink = Color(0x403482ff);
  final icons = <String, Widget>{
    'course going': const CourseStatusIcon(completed: false, color: ink),
    'course complete': const CourseStatusIcon(completed: true, color: ink),
    for (final symbol in MiuixSymbol.values)
      symbol.name: MiuixGlyph(symbol, size: 200, color: ink),
  };
  for (final entry in icons.entries) {
    testWidgets('${entry.key} overlaps retain uniform silhouette opacity',
        (tester) async {
      const key = ValueKey('iconPixels');
      await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
              child: RepaintBoundary(
                  key: key,
                  child:
                      SizedBox(width: 200, height: 200, child: entry.value)))));
      await tester.pump();
      final boundary =
          tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes =
            (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
        var maximumAlpha = 0;
        for (var offset = 3; offset < bytes.lengthInBytes; offset += 4) {
          final alpha = bytes.getUint8(offset);
          if (alpha > maximumAlpha) maximumAlpha = alpha;
        }
        // Stroke intersections must not accumulate alpha above the group alpha.
        expect(maximumAlpha, inInclusiveRange(63, 65));
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox());
    });
  }
}
