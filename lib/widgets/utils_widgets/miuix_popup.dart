import 'package:sachet/utils/miuix_shapes.dart';
// Flutter port of NexioSchedule LiquidGlassDropdownMenu.kt.
// HaoZai000/NexioSchedule ab6c7a7, AGPL-3.0-only. See third_party/nexio/SOURCES.md.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sachet/widgets/utils_widgets/glass_backdrop.dart';
import 'package:sachet/widgets/utils_widgets/liquid_glass_surface.dart';
import 'package:sachet/widgets/utils_widgets/miuix_glyph.dart';

class MiuixPopup<T> extends StatefulWidget {
  const MiuixPopup(
      {super.key,
      required this.itemBuilder,
      this.onSelected,
      this.icon,
      this.tooltip,
      this.child,
      this.onExpanded,
      this.onDismissed,
      this.expanded});
  final List<PopupMenuEntry<T>> Function(BuildContext) itemBuilder;
  final ValueChanged<T>? onSelected;
  final Widget? icon, child;
  final String? tooltip;
  final VoidCallback? onExpanded, onDismissed;
  final bool? expanded;
  @override
  State<MiuixPopup<T>> createState() => _MiuixPopupState<T>();
}

class _MiuixPopupState<T> extends State<MiuixPopup<T>> {
  final anchor = GlobalKey();
  bool open = false;
  Route<int>? menuRoute;
  @override
  void initState() {
    super.initState();
    if (widget.expanded == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) expand();
      });
    }
  }

  @override
  void didUpdateWidget(MiuixPopup<T> old) {
    super.didUpdateWidget(old);
    if (widget.expanded == true && !open && old.expanded != true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) expand();
      });
    }
    if (widget.expanded == false &&
        old.expanded == true &&
        open &&
        menuRoute?.isCurrent == true) Navigator.of(context).pop();
  }

  Future<void> expand() async {
    if (open) return;
    final box = anchor.currentContext!.findRenderObject() as RenderBox;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final items = widget.itemBuilder(context);
    GlassBackdrop.capture();
    if (!mounted) return;
    setState(() => open = true);
    widget.onExpanded?.call();
    menuRoute = _GlassMenuRoute<T>(
        rect: rect,
        items: items,
        icon: widget.icon ?? const MiuixGlyph(MiuixSymbol.more),
        themes: InheritedTheme.capture(
            from: context, to: Navigator.of(context).context),
        label: MaterialLocalizations.of(context).modalBarrierDismissLabel);
    final selected = await Navigator.of(context).push<int>(menuRoute!);
    if (!mounted) return;
    setState(() => open = false);
    widget.onDismissed?.call();
    if (selected == null || items[selected] is! PopupMenuItem<T>) return;
    final item = items[selected] as PopupMenuItem<T>;
    if (item.value != null) widget.onSelected?.call(item.value as T);
    item.onTap?.call();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
      key: anchor,
      child: widget.child != null
          ? TextButton(
              onPressed: expand,
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 48)),
              child: widget.child!)
          : SizedBox.square(
              dimension: 48,
              child: Center(
                  child: Opacity(
                      opacity: open ? 0 : 1,
                      child: LiquidGlassSurface(
                          radius: MiuixRadii.panel,
                          child: SizedBox.square(
                              dimension: 42,
                              child: IconButton(
                                  tooltip: widget.tooltip,
                                  padding: EdgeInsets.zero,
                                  onPressed: expand,
                                  icon: widget.icon ??
                                      const MiuixGlyph(MiuixSymbol.more,
                                          size: 23))))))));
}

class _GlassMenuRoute<T> extends PopupRoute<int> {
  _GlassMenuRoute(
      {required this.rect,
      required this.items,
      required this.icon,
      required this.themes,
      required this.label});
  final Rect rect;
  final List<PopupMenuEntry<T>> items;
  final Widget icon;
  final CapturedThemes themes;
  final String label;
  @override
  Color? get barrierColor => Colors.transparent;
  @override
  bool get barrierDismissible => true;
  @override
  String get barrierLabel => label;
  @override
  Duration get transitionDuration => const Duration(milliseconds: 420);
  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 340);
  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) =>
      themes.wrap(_GlassMenu<T>(route: this, animation: animation));
  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) =>
      child;
}

class _GlassMenu<T> extends StatefulWidget {
  const _GlassMenu({required this.route, required this.animation});
  final _GlassMenuRoute<T> route;
  final Animation<double> animation;
  @override
  State<_GlassMenu<T>> createState() => _GlassMenuState<T>();
}

class _GlassMenuState<T> extends State<_GlassMenu<T>> {
  int? hover;
  bool chosen = false;
  void choose(int index) {
    if (chosen) return;
    chosen = true;
    Navigator.of(context).pop(index);
  }

  Widget _entries(double rowHeight, ColorScheme colors) =>
      SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < widget.route.items.length; i++)
              widget.route.items[i] is! PopupMenuItem<T>
                  ? const Divider()
                  : SizedBox(
                      key: ValueKey('liquidDropdownItem$i'),
                      height: rowHeight,
                      child: InkWell(
                          borderRadius: BorderRadius.circular(MiuixRadii.small),
                          onTap:
                              (widget.route.items[i] as PopupMenuItem<T>).enabled
                                  ? () => choose(i)
                                  : null,
                          child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(MiuixRadii.small),
                                  color: hover == i
                                      ? colors.onSurface.withOpacity(.08)
                                      : Colors.transparent),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10.5),
                              child: DefaultTextStyle.merge(
                                  style: TextStyle(
                                      fontSize: 15.6,
                                      fontWeight: FontWeight.w500,
                                      color: colors.onSurface),
                                  child: IconTheme(
                                      data: IconThemeData(
                                          size: 23, color: colors.onSurface),
                                      child: (widget.route.items[i] as PopupMenuItem<T>).child ?? const SizedBox())))))
          ]));
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final colors = Theme.of(context).colorScheme;
    final rowHeight = math.max(45.0, media.textScaler.scale(15.6) * 1.5 + 21);
    final top = widget.route.rect.top
        .clamp(media.padding.top, media.size.height - media.padding.bottom - 80)
        .toDouble();
    final height = math.min(rowHeight * widget.route.items.length + 16,
        media.size.height - media.padding.bottom - top - 12);
    final right = (media.size.width - widget.route.rect.right + 3)
        .clamp(8.0, math.max(8.0, media.size.width - 208))
        .toDouble();
    return AnimatedBuilder(
        animation: widget.animation,
        builder: (context, _) {
          final f = Curves.easeOutCubic.transform(widget.animation.value);
          final width = 42 + (200 - 42) * f;
          return Stack(children: [
            Positioned(
                top: top,
                right: right,
                width: width,
                height: 42 + (height - 42) * f,
                child: LiquidGlassSurface(
                    radius: MiuixRadii.panel,
                    blur: 8 + 16 * (f * 8).round() / 8,
                    lensHeight: 8,
                    lensAmount: 24,
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(MiuixRadii.panel),
                        child: OverflowBox(
                            alignment: Alignment.topRight,
                            minWidth: 200,
                            maxWidth: 200,
                            minHeight: height,
                            maxHeight: height,
                            child: Opacity(
                                opacity: f,
                                child: Transform.scale(
                                    scale: width / 200,
                                    alignment: Alignment.topRight,
                                    child: Material(
                                        type: MaterialType.transparency,
                                        child: Listener(
                                            onPointerMove: widget
                                                        .route.items.length >
                                                    8
                                                ? null
                                                : (event) {
                                                    final index =
                                                        ((event.localPosition
                                                                        .dy -
                                                                    8) /
                                                                rowHeight)
                                                            .floor();
                                                    final next = index >= 0 &&
                                                            index <
                                                                widget
                                                                    .route
                                                                    .items
                                                                    .length &&
                                                            event.localPosition
                                                                    .dx >=
                                                                8 &&
                                                            event.localPosition
                                                                    .dx <=
                                                                192
                                                        ? index
                                                        : null;
                                                    if (next != hover) {
                                                      setState(
                                                          () => hover = next);
                                                      HapticFeedback
                                                          .selectionClick();
                                                    }
                                                  },
                                            onPointerUp: (event) {
                                              final index = hover;
                                              if (index != null &&
                                                  widget.route.items[index]
                                                      is PopupMenuItem<T> &&
                                                  (widget.route.items[index]
                                                          as PopupMenuItem<T>)
                                                      .enabled) {
                                                choose(index);
                                              }
                                            },
                                            child: _entries(
                                                rowHeight, colors)))))))))
          ]);
        });
  }
}
