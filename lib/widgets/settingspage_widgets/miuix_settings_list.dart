import 'package:flutter/material.dart';
import 'package:sachet/widgets/settingspage_widgets/settings_section_title.dart';
import 'package:sachet/widgets/utils_widgets/miuix_components.dart';
import 'package:sachet/widgets/utils_widgets/miuix_glyph.dart';

class MiuixSettingsList extends StatefulWidget {
  const MiuixSettingsList(
      {super.key,
      required this.children,
      this.physics,
      this.padding,
      this.searchable = false});
  final List<Widget> children;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final bool searchable;
  @override
  State<MiuixSettingsList> createState() => _MiuixSettingsListState();
}

class _MiuixSettingsListState extends State<MiuixSettingsList> {
  String _query = '';
  bool _isHeading(Widget child) =>
      child is SettingsSectionTitle ||
      (child is Padding && child.child is SettingsSectionTitle);
  String _text(Widget? child) {
    if (child is Text) return child.data ?? child.textSpan?.toPlainText() ?? '';
    if (child is SettingsSectionTitle) return child.title;
    if (child is MiuixListTile) {
      return '${_text(child.title)} ${_text(child.subtitle)}';
    }
    if (child is ListTile) {
      return '${_text(child.title)} ${_text(child.subtitle)}';
    }
    if (child is Padding) return _text(child.child);
    if (child is Column) return child.children.map(_text).join(' ');
    if (child is Row) return child.children.map(_text).join(' ');
    if (child is Offstage) return _text(child.child);
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final result = <Widget>[];
    final group = <Widget>[];
    if (widget.searchable) {
      result.add(Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: TextField(
            key: const ValueKey('miuixSettingsSearch'),
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
            decoration: InputDecoration(
                hintText: '搜索设置',
                prefixIcon: const Padding(
                    padding: EdgeInsets.all(14),
                    child: MiuixGlyph(MiuixSymbol.search, size: 20)),
                fillColor: colors.surfaceContainerLow,
                border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(28)),
                    borderSide: BorderSide.none),
                enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(28)),
                    borderSide: BorderSide.none)),
          )));
    }
    void flush() {
      if (group.isEmpty) return;
      result.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Material(
              color: colors.surfaceContainerLow,
              shape: miuixPanelShape,
              clipBehavior: Clip.antiAlias,
              child: Column(children: List<Widget>.of(group)))));
      group.clear();
    }

    var matched = 0;
    for (final child in widget.children) {
      if (_query.isNotEmpty && !_text(child).toLowerCase().contains(_query)) {
        continue;
      }
      matched++;
      if (_isHeading(child) ||
          child is Divider ||
          child is Card ||
          child is MiuixCard) {
        flush();
        if (child is! Divider) result.add(child);
      } else {
        group.add(child);
      }
    }
    flush();
    if (_query.isNotEmpty && matched == 0) {
      result.add(Padding(
          padding: const EdgeInsets.all(32),
          child: Text('没有匹配的设置',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant))));
    }
    return ListView(
        physics: widget.physics ?? const BouncingScrollPhysics(),
        padding: widget.padding ?? const EdgeInsets.only(bottom: 110),
        children: result);
  }
}
