import 'package:sachet/utils/miuix_shapes.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Shared HyperOS-style surfaces, headers and preference rows. Kept compatible
/// with Flutter 3.24 so presentation changes do not replace the data layer.
const miuixPanelShape = MiuixRadii.panelShape;

Color miuixIconColor(IconData icon) {
  const palette = [
    Color(0xff3482ff),
    Color(0xff7962ff),
    Color(0xff28c65b),
    Color(0xffffa922),
    Color(0xff899eaf)
  ];
  if ({
    Icons.wifi,
    Icons.public,
    Icons.settings_outlined,
    Icons.devices,
    Icons.calendar_month,
    Icons.calendar_month_outlined
  }.contains(icon)) {
    return palette[0];
  }
  return palette[icon.codePoint % palette.length];
}

class MiuixIconBadge extends StatelessWidget {
  const MiuixIconBadge(this.icon, {super.key, this.size = 36, this.color});
  final IconData icon;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: ShapeDecoration(
            color: color ?? miuixIconColor(icon),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(size * .28))),
        child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: size * .62, color: Colors.white)),
      );
}

class MiuixAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MiuixAppBar(
      {super.key,
      this.title,
      this.leading,
      this.actions,
      this.bottom,
      this.toolbarHeight,
      this.centerTitle,
      this.automaticallyImplyLeading = true,
      this.backgroundColor,
      this.foregroundColor,
      this.elevation,
      this.scrolledUnderElevation,
      this.titleSpacing,
      this.flexibleSpace,
      this.surfaceTintColor,
      this.compact = false});
  final Widget? title, leading, flexibleSpace;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final double? toolbarHeight, elevation, scrolledUnderElevation, titleSpacing;
  final bool? centerTitle;
  final bool automaticallyImplyLeading, compact;
  final Color? backgroundColor, foregroundColor, surfaceTintColor;
  bool get _large => !compact && title != null;
  double get height =>
      compact ? (toolbarHeight ?? 56) : math.max(132, toolbarHeight ?? 132);
  @override
  Size get preferredSize =>
      Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (!_large) {
      return AppBar(
          title: title,
          leading: leading,
          actions: actions,
          bottom: bottom,
          toolbarHeight: toolbarHeight ?? 56,
          centerTitle: centerTitle ?? false,
          automaticallyImplyLeading: automaticallyImplyLeading,
          titleSpacing: titleSpacing ?? 18,
          backgroundColor: backgroundColor ?? colors.surface,
          foregroundColor: foregroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent);
    }
    // Actions and back navigation stay in a 56dp toolbar. The large title lives
    // below it, so long labels and accessibility scaling cannot cover controls.
    return AppBar(
      bottom: bottom,
      toolbarHeight: height,
      automaticallyImplyLeading: false,
      backgroundColor: backgroundColor ?? colors.surface,
      foregroundColor: foregroundColor ?? colors.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: SafeArea(
          bottom: false,
          child: Padding(
              padding:
                  EdgeInsets.only(bottom: bottom?.preferredSize.height ?? 0),
              child: Column(children: [
                SizedBox(
                    height: 56,
                    child: Row(children: [
                      const SizedBox(width: 12),
                      if (leading != null)
                        SizedBox(width: 48, child: leading)
                      else if (automaticallyImplyLeading &&
                          Navigator.of(context).canPop())
                        const BackButton(),
                      if (leading == null &&
                          automaticallyImplyLeading &&
                          !Navigator.of(context).canPop() &&
                          Scaffold.of(context).hasDrawer)
                        IconButton(
                            tooltip: '导航菜单',
                            icon: const Icon(Icons.menu),
                            onPressed: () => Scaffold.of(context).openDrawer()),
                      const Spacer(),
                      ...?actions,
                      const SizedBox(width: 12),
                    ])),
                Expanded(
                    child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(26, 0, 26, 18),
                          child: DefaultTextStyle.merge(
                              style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w400,
                                  height: 1.16,
                                  color: colors.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              child: MediaQuery.withClampedTextScaling(
                                  maxScaleFactor: 1.4, child: title!)),
                        ))),
              ]))),
    );
  }
}

class MiuixCard extends StatelessWidget {
  const MiuixCard(
      {super.key,
      this.child,
      this.color,
      this.shadowColor,
      this.surfaceTintColor,
      this.elevation,
      this.shape,
      this.margin,
      this.clipBehavior,
      this.borderOnForeground = true,
      this.semanticContainer = true});
  final Widget? child;
  final Color? color, shadowColor, surfaceTintColor;
  final double? elevation;
  final ShapeBorder? shape;
  final EdgeInsetsGeometry? margin;
  final Clip? clipBehavior;
  final bool borderOnForeground, semanticContainer;
  @override
  Widget build(BuildContext context) => Card(
        color: color ?? Theme.of(context).colorScheme.surfaceContainerLow,
        shadowColor: shadowColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: shape ?? miuixPanelShape,
        margin:
            margin ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        clipBehavior: clipBehavior ?? Clip.antiAlias,
        borderOnForeground: borderOnForeground,
        semanticContainer: semanticContainer,
        child: child,
      );
}

class MiuixListTile extends StatelessWidget {
  const MiuixListTile(
      {super.key,
      this.leading,
      this.title,
      this.subtitle,
      this.trailing,
      this.onTap,
      this.onLongPress,
      this.contentPadding,
      this.enabled = true,
      this.selected = false,
      this.dense,
      this.isThreeLine = false,
      this.visualDensity,
      this.shape,
      this.tileColor,
      this.selectedTileColor,
      this.iconColor,
      this.textColor,
      this.selectedColor,
      this.horizontalTitleGap,
      this.minLeadingWidth,
      this.minVerticalPadding,
      this.titleAlignment,
      this.focusNode,
      this.autofocus = false,
      this.enableFeedback,
      this.mouseCursor,
      this.style,
      this.splashColor,
      this.hoverColor,
      this.focusColor});
  final Widget? leading, title, subtitle, trailing;
  final VoidCallback? onTap, onLongPress;
  final EdgeInsetsGeometry? contentPadding;
  final bool enabled, selected, isThreeLine, autofocus;
  final bool? dense, enableFeedback;
  final VisualDensity? visualDensity;
  final ShapeBorder? shape;
  final Color? tileColor,
      selectedTileColor,
      iconColor,
      textColor,
      selectedColor,
      splashColor,
      hoverColor,
      focusColor;
  final double? horizontalTitleGap, minLeadingWidth, minVerticalPadding;
  final ListTileTitleAlignment? titleAlignment;
  final FocusNode? focusNode;
  final MouseCursor? mouseCursor;
  final ListTileStyle? style;
  Widget? _icon(Widget? child) {
    if (child is Icon && child.icon != null) return MiuixIconBadge(child.icon!);
    if (child is Align && child.child is Icon) return _icon(child.child);
    return child;
  }

  Widget? _trailing(BuildContext context) {
    if (trailing is Icon &&
        {
          Icons.arrow_forward,
          Icons.arrow_forward_ios,
          Icons.arrow_forward_rounded
        }.contains((trailing as Icon).icon)) {
      return Icon(Icons.chevron_right_rounded,
          size: 24,
          color:
              Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(.65));
    }
    return trailing;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: _icon(leading),
      title: title,
      subtitle: subtitle == null
          ? null
          : DefaultTextStyle.merge(
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
              child: subtitle!),
      trailing: _trailing(context) ??
          (onTap != null
              ? Icon(Icons.chevron_right_rounded,
                  size: 24, color: colors.onSurfaceVariant.withOpacity(.65))
              : null),
      onTap: onTap,
      onLongPress: onLongPress,
      enabled: enabled,
      selected: selected,
      dense: dense,
      isThreeLine: isThreeLine,
      visualDensity: visualDensity,
      contentPadding: contentPadding ??
          const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      horizontalTitleGap: horizontalTitleGap ?? 16,
      minLeadingWidth: minLeadingWidth ?? 36,
      minVerticalPadding: minVerticalPadding ?? 12,
      titleAlignment: titleAlignment ?? ListTileTitleAlignment.center,
      shape: shape ?? MiuixRadii.controlShape,
      tileColor: tileColor,
      selectedTileColor: selectedTileColor,
      iconColor: iconColor,
      textColor: textColor,
      selectedColor: selectedColor,
      focusNode: focusNode,
      autofocus: autofocus,
      enableFeedback: enableFeedback,
      mouseCursor: mouseCursor,
      style: style,
      splashColor: splashColor,
      hoverColor: hoverColor,
      focusColor: focusColor,
    );
  }
}

class MiuixBanner extends StatelessWidget {
  const MiuixBanner(
      {super.key,
      required this.content,
      required this.actions,
      this.leading,
      this.backgroundColor,
      this.contentTextStyle,
      this.padding,
      this.leadingPadding,
      this.forceActionsBelow = false,
      this.dividerColor,
      this.elevation,
      this.onVisible,
      this.margin});
  final Widget content;
  final List<Widget> actions;
  final Widget? leading;
  final Color? backgroundColor, dividerColor;
  final TextStyle? contentTextStyle;
  final EdgeInsetsGeometry? padding, leadingPadding, margin;
  final bool forceActionsBelow;
  final double? elevation;
  final VoidCallback? onVisible;
  @override
  Widget build(BuildContext context) => Padding(
        padding:
            margin ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Material(
            shape: miuixPanelShape,
            clipBehavior: Clip.antiAlias,
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: MaterialBanner(
                content: content,
                actions: actions,
                leading: leading ??
                    const MiuixIconBadge(Icons.info_outline, size: 30),
                backgroundColor: Colors.transparent,
                dividerColor: Colors.transparent,
                forceActionsBelow: forceActionsBelow,
                onVisible: onVisible,
                contentTextStyle: contentTextStyle ??
                    Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        height: 1.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                padding: padding ?? const EdgeInsets.all(18),
                leadingPadding: leadingPadding)),
      );
}

class MiuixSliverAppBar extends StatelessWidget {
  const MiuixSliverAppBar(
      {super.key,
      this.title,
      this.actions,
      this.leading,
      this.bottom,
      this.flexibleSpace,
      this.toolbarHeight = 56,
      this.expandedHeight,
      this.collapsedHeight,
      this.pinned = true,
      this.floating = false,
      this.snap = false,
      this.automaticallyImplyLeading = true,
      this.centerTitle,
      this.backgroundColor,
      this.elevation,
      this.forceElevated = false,
      this.compact = false});
  final Widget? title, leading, flexibleSpace;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final double toolbarHeight;
  final double? expandedHeight, collapsedHeight, elevation;
  final bool pinned,
      floating,
      snap,
      automaticallyImplyLeading,
      forceElevated,
      compact;
  final bool? centerTitle;
  final Color? backgroundColor;
  @override
  Widget build(BuildContext context) {
    final large = !compact && title != null && flexibleSpace == null;
    final height = expandedHeight ?? (large ? 144.0 : toolbarHeight);
    return SliverAppBar(
        title: large ? null : title,
        actions: actions,
        leading: leading,
        bottom: bottom,
        pinned: pinned,
        floating: floating,
        snap: snap,
        automaticallyImplyLeading: automaticallyImplyLeading,
        toolbarHeight: toolbarHeight,
        expandedHeight: height,
        collapsedHeight: collapsedHeight,
        centerTitle: centerTitle,
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        forceElevated: forceElevated,
        flexibleSpace: flexibleSpace ??
            (large
                ? LayoutBuilder(builder: (context, constraints) {
                    final top = MediaQuery.paddingOf(context).top;
                    final progress =
                        ((constraints.maxHeight - top - toolbarHeight) /
                                math.max(1, height - toolbarHeight))
                            .clamp(0.0, 1.0);
                    return SafeArea(
                      bottom: false,
                      child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                  26,
                                  0,
                                  26 +
                                      (1 - progress) *
                                          ((actions?.length ?? 0) * 48 + 28),
                                  14 + progress * 4),
                              child: MediaQuery.withClampedTextScaling(
                                  maxScaleFactor: 1.4,
                                  child: DefaultTextStyle.merge(
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 20 + progress * 14,
                                          fontWeight: FontWeight.w400,
                                          height: 1.1),
                                      child: title!)))),
                    );
                  })
                : null));
  }
}
