import 'package:flutter/material.dart';
import 'package:sachet/widgets/utils_widgets/miuix_components.dart';
import 'package:sachet/widgets/utils_widgets/miuix_glyph.dart';

/// Shared centered provision layout for consent and account connection.
class ProvisionPage extends StatelessWidget {
  const ProvisionPage(
      {super.key,
      required this.title,
      required this.symbol,
      required this.content,
      required this.action,
      this.subtitle,
      this.secondaryAction,
      this.busy = false});
  final String title;
  final MiuixSymbol symbol;
  final String? subtitle;
  final Widget content, action;
  final Widget? secondaryAction;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopScope(
        canPop: !busy,
        child: Scaffold(
          appBar: const MiuixAppBar(compact: true, title: SizedBox.shrink()),
          body: SafeArea(
              top: false,
              child: Column(children: [
                Expanded(
                    child: LayoutBuilder(
                        builder: (context, constraints) =>
                            SingleChildScrollView(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding: EdgeInsets.fromLTRB(
                                    28,
                                    constraints.maxHeight < 360 ? 12 : 38,
                                    28,
                                    24),
                                child: Center(
                                    child: ConstrainedBox(
                                        constraints:
                                            const BoxConstraints(maxWidth: 520),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Center(
                                                  child: MiuixGlyph(symbol,
                                                      size: 72,
                                                      color: colors.primary)),
                                              const SizedBox(height: 22),
                                              Text(title,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontSize: 32,
                                                      height: 1.25,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: colors.onSurface)),
                                              if (subtitle != null) ...[
                                                const SizedBox(height: 10),
                                                Text(subtitle!,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                        fontSize: 13,
                                                        height: 1.4,
                                                        color: colors
                                                            .onSurfaceVariant)),
                                              ],
                                              const SizedBox(height: 34),
                                              content,
                                            ])))))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            action,
                            if (secondaryAction != null) ...[
                              const SizedBox(height: 8),
                              secondaryAction!,
                            ]
                          ])),
                ),
              ])),
        ));
  }
}

class ProvisionButton extends StatelessWidget {
  const ProvisionButton(
      {super.key, required this.label, this.onPressed, this.loading = false});
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    return Semantics(
        button: true,
        enabled: enabled,
        child: Material(
            color: enabled || loading
                ? colors.primary
                : colors.primary.withOpacity(.10),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 17),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (loading) ...[
                            SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: colors.onPrimary)),
                            const SizedBox(width: 12),
                          ],
                          Flexible(
                              child: Text(label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: enabled || loading
                                          ? colors.onPrimary
                                          : colors.onSurface
                                              .withOpacity(.25)))),
                        ])))));
  }
}

class ProvisionCheck extends StatelessWidget {
  const ProvisionCheck(
      {super.key, required this.label, required this.value, this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
        checked: value,
        enabled: onChanged != null,
        label: label,
        child: ExcludeSemantics(
            child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onChanged == null ? null : () => onChanged!(!value),
                child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(children: [
                      AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: value
                                  ? colors.primary
                                  : colors.surfaceContainerHighest),
                          child: value
                              ? Center(
                                  child: MiuixGlyph(MiuixSymbol.check,
                                      size: 17, color: colors.onPrimary))
                              : null),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(label,
                              style: TextStyle(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: colors.onSurfaceVariant))),
                    ])))));
  }
}

class ProvisionPanel extends StatelessWidget {
  const ProvisionPanel(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => MiuixCard(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(padding: padding, child: child));
}
