import 'package:sachet/utils/miuix_shapes.dart';
import 'package:flutter/material.dart';

/// Values approved in assets/json/HomeDesign.json, exported from the editor.
abstract final class HomeDesign {
  static const title = 'Sachet Next';
  static const headingSize = 34.0;
  static const headingFont = 'sans';
  static const headingHeight = 144.0;
  static const headingOffset = 0.0;
  static const padding = 18.0;
  static const gap = 13.0;
  static const columns = 2;
  static const cardHeight = 76.0;
  static const cardRadius = MiuixRadii.panel;
  static const cardSize = 15.0;
  static const iconSize = 29.0;
  static const iconRadius = 21.0;
  static const heroHeight = 260.0;
  static const heroRadius = MiuixRadii.panel;
  static const heroSize = 20.0;
  static const navDarken = 0.20;
  static const navBottom = 20.0;

  static ColorScheme colors(ColorScheme base) => base.copyWith(
        brightness: Brightness.dark,
        surface: const Color(0xff101619),
        onSurface: const Color(0xffe0e3e5),
        outline: const Color(0xff859296),
        primary: const Color(0xff8bd0ed),
        onPrimary: const Color(0xff003544),
        surfaceContainerLow: const Color(0xff171d20),
        secondaryContainer: const Color(0xff334c56),
        onSecondaryContainer: const Color(0xffcce5ef),
        primaryContainer: const Color(0xff004c61),
        onPrimaryContainer: const Color(0xffb5e5fa),
        outlineVariant: const Color(0xff3e484d),
      );

  static ThemeData theme(ThemeData base) {
    final palette = colors(base.colorScheme);
    return base.copyWith(
      brightness: Brightness.dark,
      colorScheme: palette,
      scaffoldBackgroundColor: palette.surface,
      textTheme: base.textTheme.apply(
        bodyColor: palette.onSurface,
        displayColor: palette.onSurface,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: palette.surface,
        foregroundColor: palette.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(
          color: palette.onSurface,
        ),
      ),
      cardTheme: base.cardTheme.copyWith(color: palette.surfaceContainerLow),
    );
  }
}
