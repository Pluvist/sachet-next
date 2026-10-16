import 'package:sachet/widgets/utils_widgets/source_expand_route.dart';
import 'package:sachet/widgets/utils_widgets/miuix_components.dart';
import 'package:sachet/utils/utils_functions.dart';
import 'package:sachet/widgets/utils_widgets/miuix_press.dart';
import 'package:flutter/material.dart';
import 'package:sachet/utils/home_design.dart';

class CardWidget extends StatefulWidget {
  const CardWidget({
    super.key,
    required this.title,
    required this.icon,
    this.page,
    this.onTap,
    this.link,
  });
  final String title;
  final IconData icon;
  final String? link;
  final Widget? page;
  final VoidCallback? onTap;

  @override
  State<CardWidget> createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget> {
  final iconKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    final title = widget.title;
    final icon = widget.icon;
    final link = widget.link;
    final page = widget.page;
    final onTap = widget.onTap;
    final colors = Theme.of(context).colorScheme;
    return Builder(
        builder: (sourceContext) => MiuixPress(
                child: MiuixCard(
              margin: EdgeInsets.zero,
              child: InkWell(
                onTap: onTap ??
                    () {
                      if (link != null) {
                        expandAction(sourceContext, () => openLink(link),
                            sourceKey: iconKey,
                            sourceRadius: 8.5,
                            sourceColor: miuixIconColor(icon));
                      } else if (page != null) {
                        expandPage(sourceContext, page,
                            sourceKey: iconKey,
                            sourceRadius: 8.5,
                            sourceColor: miuixIconColor(icon));
                      }
                    },
                onLongPress: link == null
                    ? null
                    : () => copyToClipboard(context, link, prefix: '链接'),
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(minHeight: HomeDesign.cardHeight),
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        ExpansionAnchor(
                            key: iconKey,
                            child: MiuixIconBadge(icon, size: 34)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(title,
                                style: TextStyle(
                                    color: colors.onSurface,
                                    fontSize: HomeDesign.cardSize,
                                    fontWeight: FontWeight.w400))),
                      ])),
                ),
              ),
            )));
  }
}
