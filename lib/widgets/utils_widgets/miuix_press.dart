import 'package:flutter/material.dart';

/// Pointer feedback without replacing the child's tap, long-press or semantics.
class MiuixPress extends StatefulWidget {
  const MiuixPress({super.key, required this.child});
  final Widget child;
  @override
  State<MiuixPress> createState() => _MiuixPressState();
}

class _MiuixPressState extends State<MiuixPress> {
  bool pressed = false;
  void _set(bool value) {
    if (pressed != value) setState(() => pressed = value);
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (_) => _set(true),
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        child: AnimatedScale(
          scale: pressed && !MediaQuery.disableAnimationsOf(context) ? 0.97 : 1,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      );
}
