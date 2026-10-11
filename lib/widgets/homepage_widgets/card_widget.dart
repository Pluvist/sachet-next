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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return MiuixPress(
        child: Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap ??
            () {
              if (link != null) {
                openLink(link!);
              } else if (page != null) {
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => page!));
              }
            },
        onLongPress: link == null
            ? null
            : () => copyToClipboard(context, link!, prefix: '链接'),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: HomeDesign.cardHeight),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 18.0, horizontal: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(theme.useMaterial3 ? 12 : 0),
                  decoration: theme.useMaterial3
                      ? BoxDecoration(
                          color: colors.primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(16),
                        )
                      : null,
                  child: Icon(
                    icon,
                    size: HomeDesign.iconSize,
                    applyTextScaling: true,
                    color: theme.useMaterial3 ? colors.primary : colors.primary,
                  ),
                ),
                SizedBox(height: theme.useMaterial3 ? 10 : 3),
                Text(
                  title,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: HomeDesign.cardSize,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
