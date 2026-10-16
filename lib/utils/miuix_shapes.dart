import 'package:flutter/material.dart';

/// Proportions of the reference's rounded panels, normalized to logical pixels.
/// Smaller controls share the same circular corner profile at a smaller radius.
abstract final class MiuixRadii {
  static const panel = 22.0;
  static const control = 18.0;
  static const small = 12.0;
  static const panelShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(panel)));
  static const controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(control)));
}
