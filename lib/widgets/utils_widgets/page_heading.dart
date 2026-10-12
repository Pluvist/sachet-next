import 'package:flutter/material.dart';
import 'package:sachet/utils/home_design.dart';

/// Shared title typography for the home and profile pages.
class PageHeading extends StatelessWidget {
  const PageHeading(this.label, {super.key, this.fontSize});

  final String label;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final original = theme.appBarTheme.titleTextStyle ??
        theme.textTheme.titleLarge ??
        const TextStyle(fontSize: 22);
    return Text(
      label,
      style: original.copyWith(
        fontSize: fontSize ?? HomeDesign.headingSize,
        fontWeight: FontWeight.w400,
        fontFamily: HomeDesign.headingFont == 'serif'
            ? 'Noto Serif SC Titles'
            : original.fontFamily,
        fontFamilyFallback: HomeDesign.headingFont == 'serif'
            ? const ['Noto Serif SC Titles']
            : const [],
        height: 1,
      ),
    );
  }
}

/// Both app bars use the same independently adjustable vertical offset.
class ConfiguredPageHeading extends StatelessWidget {
  const ConfiguredPageHeading(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Transform.translate(
        offset: const Offset(0, HomeDesign.headingOffset),
        child: PageHeading(label),
      );
}
