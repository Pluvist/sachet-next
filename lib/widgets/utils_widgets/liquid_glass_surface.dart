import 'dart:ui';
import 'package:flutter/material.dart';

/// Original Flutter glass surface. Blur stays clipped to the capsule and is
/// constant during navigation; only its small foreground indicator animates.
class LiquidGlassSurface extends StatelessWidget {
  const LiquidGlassSurface({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: DecoratedBox(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: dark
                            ? [
                                Colors.white.withOpacity(.12),
                                const Color(0xff191919).withOpacity(.78),
                                Colors.white.withOpacity(.06)
                              ]
                            : [
                                Colors.white.withOpacity(.9),
                                Colors.white.withOpacity(.62),
                                Colors.white.withOpacity(.8)
                              ],
                        stops: const [0, .6, 1]),
                    border: Border.all(
                        color: dark
                            ? Colors.white.withOpacity(.24)
                            : Colors.grey.withOpacity(.2),
                        width: .6)),
                child: child)));
  }
}
