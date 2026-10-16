import 'package:sachet/utils/miuix_shapes.dart';
import 'package:flutter/material.dart';

/// A preference-style selector: a filled row and an anchored, rounded menu.
/// Values and callbacks use the same contract as the former dropdown fields.
class MiuixSelect<T> extends StatelessWidget {
  const MiuixSelect(
      {super.key,
      this.width,
      this.menuHeight,
      this.initialSelection,
      this.label,
      this.errorText,
      this.textStyle,
      this.inputDecorationTheme,
      this.menuStyle,
      this.requestFocusOnTap,
      this.expandedInsets,
      this.enabled = true,
      required this.dropdownMenuEntries,
      this.onSelected});
  final double? width, menuHeight;
  final T? initialSelection;
  final Widget? label;
  final String? errorText;
  final TextStyle? textStyle;
  final InputDecorationTheme? inputDecorationTheme;
  final MenuStyle? menuStyle;
  final bool? requestFocusOnTap;
  final EdgeInsets? expandedInsets;
  final bool enabled;
  final List<DropdownMenuEntry<T>> dropdownMenuEntries;
  final ValueChanged<T?>? onSelected;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selected =
        dropdownMenuEntries.where((e) => e.value == initialSelection);
    return SizedBox(
        width: width,
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MenuAnchor(
                style: MenuStyle(
                    backgroundColor:
                        WidgetStatePropertyAll(colors.surfaceContainerLow),
                    elevation: const WidgetStatePropertyAll(4),
                    maximumSize:
                        WidgetStatePropertyAll(Size(360, menuHeight ?? 400)),
                    padding: const WidgetStatePropertyAll(EdgeInsets.all(8)),
                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(MiuixRadii.control)))),
                menuChildren: dropdownMenuEntries
                    .map((entry) => MenuItemButton(
                        onPressed: enabled && entry.enabled
                            ? () => onSelected?.call(entry.value)
                            : null,
                        trailingIcon: entry.value == initialSelection
                            ? Icon(Icons.check_rounded,
                                size: 20, color: colors.primary)
                            : null,
                        style: ButtonStyle(
                            minimumSize:
                                const WidgetStatePropertyAll(Size(120, 48)),
                            shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        MiuixRadii.small)))),
                        child: Text(entry.label,
                            style: TextStyle(
                                fontSize: 15, color: colors.onSurface))))
                    .toList(),
                builder: (context, controller, child) => Semantics(
                    button: true,
                    child: Material(
                        color: colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(MiuixRadii.control),
                        child: InkWell(
                            borderRadius:
                                BorderRadius.circular(MiuixRadii.control),
                            onTap: enabled
                                ? () => controller.isOpen
                                    ? controller.close()
                                    : controller.open()
                                : null,
                            child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 14),
                                child: Row(children: [
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                        if (label != null)
                                          DefaultTextStyle.merge(
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      colors.onSurfaceVariant),
                                              child: label!),
                                        if (label != null)
                                          const SizedBox(height: 5),
                                        Text(
                                            selected.isEmpty
                                                ? '请选择'
                                                : selected.first.label,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(fontSize: 16),
                                            softWrap: true),
                                      ])),
                                  const SizedBox(width: 10),
                                  Icon(Icons.expand_more_rounded,
                                      size: 20, color: colors.onSurfaceVariant)
                                ]))))),
              ),
              if (errorText != null)
                Padding(
                    padding: const EdgeInsets.only(top: 6, left: 16),
                    child: Text(errorText!,
                        style: TextStyle(fontSize: 12, color: colors.error))),
            ]));
  }
}

class MiuixButton extends StatelessWidget {
  const MiuixButton(
      {super.key,
      required this.onPressed,
      required this.child,
      this.style,
      this.icon});
  const MiuixButton.icon(
      {super.key,
      required this.onPressed,
      required Widget label,
      required this.icon,
      this.style})
      : child = label;
  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final ButtonStyle? style;
  static ButtonStyle styleFrom(
          {EdgeInsetsGeometry? padding,
          Size? minimumSize,
          TextStyle? textStyle,
          VisualDensity? visualDensity,
          Color? backgroundColor,
          Color? foregroundColor,
          OutlinedBorder? shape,
          double? elevation}) =>
      ButtonStyle(
          padding: padding == null ? null : WidgetStatePropertyAll(padding),
          minimumSize:
              minimumSize == null ? null : WidgetStatePropertyAll(minimumSize),
          textStyle:
              textStyle == null ? null : WidgetStatePropertyAll(textStyle));
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final disabled = onPressed == null;
    return Semantics(
        button: true,
        enabled: !disabled,
        child: Material(
            color: disabled ? colors.surfaceContainerHigh : colors.primary,
            borderRadius: BorderRadius.circular(MiuixRadii.control),
            child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(MiuixRadii.control),
                child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(minHeight: 50, minWidth: 96),
                    child: Padding(
                        padding: style?.padding?.resolve({}) ??
                            const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                        child: DefaultTextStyle.merge(
                            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                                fontSize: 16,
                                color: disabled
                                    ? colors.onSurfaceVariant
                                    : colors.onPrimary),
                            child: IconTheme(
                                data: IconThemeData(
                                    size: 20, color: colors.onPrimary),
                                child: icon == null
                                    ? Center(
                                        widthFactor: 1,
                                        heightFactor: 1,
                                        child: child)
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                            icon!,
                                            const SizedBox(width: 8),
                                            Flexible(child: child)
                                          ]))))))));
  }
}
