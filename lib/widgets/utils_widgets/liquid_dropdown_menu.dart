// Source port: NexioSchedule LiquidGlassDropdownMenu.kt, AGPL-3.0-only.
import 'package:flutter/material.dart';
import 'package:sachet/widgets/utils_widgets/miuix_popup.dart';

const double kLiquidDropdownButtonDiameter = 42;
const double kLiquidDropdownPanelWidth = 200;
const double kLiquidDropdownPanelRadius = 25;
const double kLiquidDropdownItemRadius = 17;
const double kLiquidDropdownEntryHeight = 45;
const double kLiquidDropdownPanelPadding = 8;
const double kLiquidDropdownShadowPadding = 24;
const double kLiquidDropdownPanelInset = 19;

/// Compatibility with existing course toolbar callbacks. The popup route uses
/// the measured trigger itself as anchor instead of a fixed viewport offset.
class LiquidGlassDropdownMenu extends StatelessWidget {
  const LiquidGlassDropdownMenu(
      {super.key,
      required this.show,
      required this.itemCount,
      required this.onSelected,
      this.onExpanded,
      this.onDismissed,
      this.icon,
      this.tooltip,
      this.semanticLabel,
      this.triggerIconSize = 23,
      this.entryLabels,
      this.leadingBuilder,
      this.trailingBuilder,
      this.maxPanelHeight = 336,
      this.panelTop,
      this.panelRight});
  final bool show;
  final int itemCount;
  final ValueChanged<int> onSelected;
  final VoidCallback? onExpanded, onDismissed;
  final Widget? icon;
  final String? tooltip, semanticLabel;
  final double triggerIconSize, maxPanelHeight;
  final double? panelTop, panelRight;
  final List<String>? entryLabels;
  final Widget? Function(int)? leadingBuilder, trailingBuilder;
  @override
  Widget build(BuildContext context) => Tooltip(
      message: tooltip ?? semanticLabel ?? '菜单',
      child: SizedBox.square(
          dimension: 42,
          key: const ValueKey('liquidDropdownTrigger'),
          child: MiuixPopup<int>(
              expanded: show,
              tooltip: null,
              icon: icon,
              onExpanded: onExpanded,
              onDismissed: onDismissed,
              onSelected: onSelected,
              itemBuilder: (context) => [
                    for (var i = 0; i < itemCount; i++)
                      PopupMenuItem<int>(
                          value: i,
                          child: Row(children: [
                            if (leadingBuilder?.call(i) != null) ...[
                              leadingBuilder!(i)!,
                              const SizedBox(width: 10)
                            ],
                            Expanded(
                                child: Text(
                                    entryLabels != null &&
                                            i < entryLabels!.length
                                        ? entryLabels![i]
                                        : '${i + 1}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)),
                            if (trailingBuilder?.call(i) != null) ...[
                              const SizedBox(width: 8),
                              trailingBuilder!(i)!
                            ],
                          ])),
                  ])));
}
