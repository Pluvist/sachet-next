import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:sachet/constants/app_notices.dart';
import 'package:sachet/pages/utilspages/zhengfang_jwxt_login_page.dart';
import 'package:sachet/utils/utils_functions.dart';
import 'package:sachet/widgets/intro_widgets/provision_page.dart';
import 'package:sachet/widgets/utils_widgets/miuix_glyph.dart';
import 'package:sachet/widgets/utils_widgets/source_expand_route.dart';

class AgreementPage extends StatefulWidget {
  const AgreementPage({super.key});
  @override
  State<AgreementPage> createState() => _AgreementPageState();
}

class _AgreementPageState extends State<AgreementPage> {
  bool accepted = false;
  bool opening = false;
  Future<void> _continue(BuildContext source) async {
    if (!accepted || opening) return;
    setState(() => opening = true);
    final result = await Navigator.of(context).push<bool>(
        SourceExpandRoute<bool>(
            source: expansionSource(source),
            reduceMotion: MediaQuery.disableAnimationsOf(context),
            builder: (_) =>
                const ZhengFangJwxtLoginPage(title: '登录账号', onboarding: true)));
    if (!mounted) return;
    setState(() => opening = false);
    if (result == true) Navigator.of(context).pop(true);
  }

  void _read(bool privacy) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => NoticeDetailsPage(privacy: privacy)));
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = Theme.of(context)
        .textTheme
        .bodyMedium!
        .copyWith(fontSize: 14, height: 1.55, color: colors.onSurfaceVariant);
    Widget link(bool privacy) => TextButton(
        key: ValueKey(privacy ? 'privacyNoticeLink' : 'usageNoticeLink'),
        style: TextButton.styleFrom(
            foregroundColor: colors.primary,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: style),
        onPressed: () => _read(privacy),
        child: Text(privacy ? '《隐私说明》' : '《使用协议》'));
    return ProvisionPage(
        title: '协议与声明',
        symbol: MiuixSymbol.document,
        busy: opening,
        content:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ProvisionPanel(
              child: Text.rich(TextSpan(style: style, children: [
            const TextSpan(text: '使用 Sachet Next 前，请阅读并了解 '),
            WidgetSpan(
                alignment: PlaceholderAlignment.middle, child: link(false)),
            const TextSpan(text: ' 与 '),
            WidgetSpan(
                alignment: PlaceholderAlignment.middle, child: link(true)),
            const TextSpan(text: ' 中的说明，包括教务账号、本地课程数据及通知组件的使用方式。勾选同意后即可继续。'),
          ]))),
          const SizedBox(height: 8),
          ProvisionCheck(
              key: const ValueKey('agreementConsent'),
              label: '我已仔细阅读并同意上述条款',
              value: accepted,
              onChanged:
                  opening ? null : (value) => setState(() => accepted = value)),
        ]),
        action: Builder(
            builder: (source) => ProvisionButton(
                key: const ValueKey('agreementContinue'),
                label: '同意并继续',
                onPressed:
                    accepted && !opening ? () => _continue(source) : null)));
  }
}

class NoticeDetailsPage extends StatelessWidget {
  const NoticeDetailsPage({super.key, required this.privacy});
  final bool privacy;
  @override
  Widget build(BuildContext context) => ProvisionPage(
      title: privacy ? '隐私说明' : '使用协议',
      symbol: MiuixSymbol.document,
      content: ProvisionPanel(
          child: MarkdownBody(
              data: privacy ? privacyNotice : usageNotice,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                  .copyWith(
                      p: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.65)),
              onTapLink: (_, href, __) {
                if (href != null) openLink(href);
              })),
      action: ProvisionButton(
          label: '阅读完毕', onPressed: () => Navigator.of(context).pop()));
}
