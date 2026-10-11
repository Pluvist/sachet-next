import 'package:flutter/material.dart';
import 'package:sachet/widgets/settingspage_widgets/settings_section_title.dart';

/// Rounded preference groups, separated by the existing section headings.
class MiuixSettingsList extends StatelessWidget {
  const MiuixSettingsList(
      {super.key, required this.children, this.physics, this.padding});
  final List<Widget> children;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  bool _isHeading(Widget child) =>
      child is SettingsSectionTitle ||
      (child is Padding && child.child is SettingsSectionTitle);

  @override
  Widget build(BuildContext context) {
    if (!Theme.of(context).useMaterial3) {
      return ListView(physics: physics, padding: padding, children: children);
    }
    final result = <Widget>[];
    final group = <Widget>[];
    void flush() {
      if (group.isEmpty) return;
      result.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(children: List<Widget>.of(group)),
        ),
      ));
      group.clear();
    }

    for (final child in children) {
      if (_isHeading(child) || child is Divider || child is Card) {
        flush();
        if (child is! Divider) result.add(child);
      } else {
        group.add(child);
      }
    }
    flush();
    return ListView(
      physics: physics ?? const BouncingScrollPhysics(),
      padding: padding ?? const EdgeInsets.only(bottom: 110),
      children: result,
    );
  }
}
