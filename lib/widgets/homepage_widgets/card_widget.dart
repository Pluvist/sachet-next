import 'package:sachet/widgets/utils_widgets/miuix_components.dart';
import 'package:sachet/utils/utils_functions.dart';
import 'package:sachet/widgets/utils_widgets/miuix_press.dart';
import 'package:flutter/material.dart';
import 'package:sachet/utils/home_design.dart';

class CardWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MiuixPress(
        child: MiuixCard(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap ??
            () {
              if (link != null) {
                openLink(link!);
              } else if (page != null) {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => page!));
              }
            },
        onLongPress: link == null
            ? null
            : () => copyToClipboard(context, link!, prefix: '链接'),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: HomeDesign.cardHeight),
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                MiuixIconBadge(icon, size: 34),
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
    ));
  }
}
