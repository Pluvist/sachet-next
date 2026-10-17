import 'package:flutter/material.dart';

/// The top counterpart of the floating navigation's bottom fade. It remains
/// neutral even when a page uses a coloured surface, and never handles taps.
class TopEdgeMask extends StatelessWidget {
  const TopEdgeMask({super.key, this.decorationKey});

  final Key? decorationKey;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).brightness == Brightness.dark
        ? Colors.black
        : Colors.white;
    return IgnorePointer(
      child: DecoratedBox(
        key: decorationKey,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color, color.withOpacity(.94), color.withOpacity(0)],
            stops: const [0, .25, 1],
          ),
        ),
      ),
    );
  }
}

class FadingHeaderSurface extends StatelessWidget {
  const FadingHeaderSurface({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          const TopEdgeMask(decorationKey: ValueKey('pageTopMask')),
          if (child != null) child!,
        ],
      );
}
