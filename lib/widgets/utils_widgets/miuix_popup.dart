import 'package:flutter/material.dart';
import 'package:sachet/widgets/utils_widgets/miuix_glyph.dart';

class MiuixPopup<T> extends StatelessWidget {
  const MiuixPopup(
      {super.key,
      required this.itemBuilder,
      this.onSelected,
      this.icon,
      this.tooltip,
      this.child});
  final List<PopupMenuEntry<T>> Function(BuildContext) itemBuilder;
  final ValueChanged<T>? onSelected;
  final Widget? icon, child;
  final String? tooltip;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MenuAnchor(
      style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(colors.surfaceContainerLow),
          elevation: const WidgetStatePropertyAll(4),
          padding: const WidgetStatePropertyAll(EdgeInsets.all(8)),
          shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)))),
      menuChildren: itemBuilder(context).map((item) {
        if (item is! PopupMenuItem<T>) return const Divider();
        return MenuItemButton(
            onPressed: item.enabled
                ? () {
                    if (item.value != null) onSelected?.call(item.value as T);
                    // The menu closes before an operation opens a dialog or pushes a page.
                    if (item.onTap != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) item.onTap!();
                      });
                    }
                  }
                : null,
            style: ButtonStyle(
                minimumSize: const WidgetStatePropertyAll(Size(120, 48)),
                shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)))),
            child: item.child);
      }).toList(),
      builder: (context, controller, _) => child != null
          ? TextButton(
              onPressed: () =>
                  controller.isOpen ? controller.close() : controller.open(),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 48)),
              child: child!,
            )
          : IconButton(
              tooltip: tooltip,
              onPressed: () =>
                  controller.isOpen ? controller.close() : controller.open(),
              icon: icon ?? const MiuixGlyph(MiuixSymbol.more)),
    );
  }
}
