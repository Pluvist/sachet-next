import 'package:sachet/widgets/utils_widgets/source_expand_route.dart';
import 'package:sachet/widgets/utils_widgets/ios_page_route.dart';
import 'package:sachet/utils/miuix_shapes.dart';
import 'package:sachet/widgets/utils_widgets/miuix_components.dart';
import 'package:sachet/widgets/intro_widgets/provision_page.dart';
import 'package:sachet/widgets/utils_widgets/miuix_glyph.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sachet/constants/url_constants.dart';
import 'package:sachet/pages/utilspages/zhengfang_jwxt_manual_login_page.dart';
import 'package:sachet/providers/login_page_provider.dart';
import 'package:sachet/providers/zhengfang_user_provider.dart';
import 'package:sachet/services/zhengfang_jwxt/login/account_authenticator.dart';
import 'package:sachet/utils/utils_functions.dart';
import 'package:sachet/widgets/utilspages_widgets/login_page_widgets/error_info_snackbar.dart';
import 'package:sachet/widgets/utilspages_widgets/login_page_widgets/log_in_use_cookie_dialog.dart';
import 'package:sachet/widgets/utilspages_widgets/login_page_widgets/password_form_field.dart';
import 'package:sachet/widgets/utilspages_widgets/login_page_widgets/username_form_field.dart';
import 'package:provider/provider.dart';

class ZhengFangJwxtLoginPage extends StatelessWidget {
  const ZhengFangJwxtLoginPage(
      {super.key,
      this.title = '登录',
      this.onboarding = false,
      this.nextOnboardingPage,
      this.authenticator = const AccountAuthenticator()});
  final String title;
  final bool onboarding;
  final WidgetBuilder? nextOnboardingPage;
  final AccountAuthenticator authenticator;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginPageProvider(),
      child: ZhengFangJwxtLoginPageView(
          title: title,
          onboarding: onboarding,
          nextOnboardingPage: nextOnboardingPage,
          authenticator: authenticator),
    );
  }
}

class ZhengFangJwxtLoginPageView extends StatefulWidget {
  const ZhengFangJwxtLoginPageView(
      {super.key,
      this.title = '登录',
      this.onboarding = false,
      this.nextOnboardingPage,
      this.authenticator = const AccountAuthenticator()});
  final String title;
  final bool onboarding;
  final WidgetBuilder? nextOnboardingPage;
  final AccountAuthenticator authenticator;

  @override
  State<ZhengFangJwxtLoginPageView> createState() =>
      _ZhengFangJwxtLoginPageViewState();
}

class _ZhengFangJwxtLoginPageViewState
    extends State<ZhengFangJwxtLoginPageView> {
  final _loginFormKey = GlobalKey<FormState>();
  final usernameTextController = TextEditingController();
  final passwordTextController = TextEditingController();

  String? showErrorText;
  final _nextKey = GlobalKey();
  bool _advancing = false;
  Future<void> _finishLogin() async {
    if (!mounted || _advancing) return;
    if (widget.nextOnboardingPage == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() => _advancing = true);
    await expandPage<void>(context, widget.nextOnboardingPage!(context),
        sourceKey: _nextKey,
        sourceColor: Theme.of(context).colorScheme.primary);
    if (mounted) setState(() => _advancing = false);
  }

  /// 获取储存的 学号和密码
  Future loadDataFromSecureStorage() async {
    try {
      final user = context.read<ZhengFangUserProvider>();
      await user.init();
      final studentIDText = user.user.studentID;
      final passwordText = await ZhengFangUserProvider.readPassword();
      if (!mounted) return;
      // Slow storage reads must not replace text or the remember choice that
      // the user has already changed while the form was being restored.
      if (usernameTextController.text.isEmpty) {
        usernameTextController.text = studentIDText ?? '';
      }
      if (passwordTextController.text.isEmpty) {
        passwordTextController.text = passwordText ?? '';
      }
    } catch (_) {
      // Manual login remains usable if secure storage is temporarily unavailable.
      // A failed save is still reported by the login operation itself.
    }
  }

  Future _pressLoginButton(BuildContext context) async {
    if (context.read<LoginPageProvider>().isLoggingIn) return;
    if (_loginFormKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      context.read<LoginPageProvider>().setIsLoggingIn(true);
      final username = usernameTextController.text;
      final password = passwordTextController.text;
      final remember = context.read<LoginPageProvider>().isRememberPassword;

      try {
        final user =
            await widget.authenticator.passwordLogin(username, password);

        if (!context.mounted) return;

        await context
            .read<ZhengFangUserProvider>()
            .setUser(user, password: password, rememberPassword: remember);

        if (!context.mounted) return;

        context.read<LoginPageProvider>().setIsLoggingIn(false);
        _finishLogin();
      } catch (e) {
        // *****有异常*****

        if (!context.mounted) return;

        // 显示 显示登录错误信息的 SnackBar，显示3秒后隐藏
        ScaffoldMessenger.of(context).showSnackBar(errorInfoSnackBar(
            context, e.toString().replaceAll('Exception: ', '')));
      } finally {
        if (context.mounted) {
          context.read<LoginPageProvider>().setIsLoggingIn(false);
        }
      }
    }
  }

  Future _loginUseCookie(BuildContext context) async {
    String? cookie = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => LogInUseCookieDialog(),
    );
    if (!context.mounted || cookie == null || cookie.trim().isEmpty) return;
    context.read<LoginPageProvider>().setIsLoggingIn(true);
    try {
      final user = await widget.authenticator.cookieLogin(cookie.trim());
      if (!context.mounted) return;
      await context.read<ZhengFangUserProvider>().setUser(user);
      if (!context.mounted) return;
      context.read<LoginPageProvider>().setIsLoggingIn(false);
      _finishLogin();
    } catch (e) {
      if (!context.mounted) return;

      if (kDebugMode) {
        print(e);
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('登录失败'),
          content: Text(e.toString().replaceAll('Exception: ', '')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('确认'),
            )
          ],
        ),
      );
    } finally {
      if (context.mounted) {
        context.read<LoginPageProvider>().setIsLoggingIn(false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    loadDataFromSecureStorage();
  }

  @override
  void dispose() {
    usernameTextController.dispose();
    passwordTextController.dispose();
    super.dispose();
  }

  Future<void> _otherMethods() async {
    final colors = Theme.of(context).colorScheme;
    final method = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: colors.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(MiuixRadii.panel))),
        builder: (sheet) => SafeArea(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                          color: colors.outlineVariant,
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  const Text('其他登录方式',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  MiuixListTile(
                      leading: const Icon(Icons.open_in_browser_rounded),
                      title: const Text('手动登录'),
                      onTap: () => Navigator.pop(sheet, 'web')),
                  MiuixListTile(
                      leading: const Icon(Icons.account_balance_outlined),
                      title: const Text('从信息门户登录'),
                      onTap: () => Navigator.pop(sheet, 'portal')),
                  MiuixListTile(
                      leading: const Icon(Icons.cookie_outlined),
                      title: const Text('使用 Cookie 登录'),
                      onTap: () => Navigator.pop(sheet, 'cookie')),
                ]))));
    if (!mounted || method == null) return;
    if (method == 'cookie') {
      await _loginUseCookie(context);
    } else {
      final result = await Navigator.push<bool>(
          context,
          IOSPageRoute(
              builder: (_) => ZhengFangManualLoginPage(
                  initialUrl: method == 'portal'
                      ? xinXiMenHuBaseUrl
                      : newJwxtBaseUrl)));
      if (mounted && result == true) _finishLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final login = context.watch<LoginPageProvider>();
    final busy = login.isLoggingIn || _advancing;
    InputDecoration input(String label, String hint) => InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 20));
    return ProvisionPage(
        title: widget.onboarding
            ? '登录账号'
            : widget.title == '登录'
                ? '登录账号'
                : widget.title,
        symbol: MiuixSymbol.person,
        subtitle: '连接湘潭大学教务系统',
        busy: busy,
        action: ExpansionAnchor(
            key: _nextKey,
            child: ProvisionButton(
                key: const ValueKey('provisionLogin'),
                label: widget.onboarding ? '登录并继续' : '登录',
                loading: busy,
                onPressed: busy ? null : () => _pressLoginButton(context))),
        secondaryAction: widget.onboarding
            ? TextButton(
                key: const ValueKey('onboardLoginSkip'),
                onPressed: busy ? null : _finishLogin,
                style: TextButton.styleFrom(
                    foregroundColor: colors.onSurfaceVariant),
                child: const Text('稍后登录'))
            : null,
        content: AutofillGroup(
            child: Form(
                key: _loginFormKey,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ProvisionPanel(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 2),
                          child: Column(children: [
                            UsernameFormField(
                                key: const ValueKey('loginUsernameField'),
                                controller: usernameTextController,
                                enabled: !busy,
                                decoration: input('学号', '请输入 12 位学号')),
                            Divider(
                                height: 1,
                                thickness: .5,
                                color: colors.outlineVariant.withOpacity(.5)),
                            PasswordFormField(
                                key: const ValueKey('loginPasswordField'),
                                controller: passwordTextController,
                                enabled: !busy,
                                decoration: input(
                                    '密码', '默认密码为 Xtu@身份证后六位'),
                                onSubmitted: (_) => _pressLoginButton(context)),
                          ])),
                      const SizedBox(height: 8),
                      ProvisionCheck(
                          key: const ValueKey('loginRemember'),
                          label: '记住密码',
                          value: login.isRememberPassword,
                          onChanged: busy ? null : login.setIsRememberPassword),
                      const SizedBox(height: 16),
                      ProvisionPanel(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('首次使用初始密码？',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: colors.onSurface,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Text('请先在学校教务网页设置新密码，再回到这里登录。',
                                style: TextStyle(
                                    fontSize: 12,
                                    height: 1.5,
                                    color: colors.onSurfaceVariant)),
                            TextButton(
                                onPressed: busy
                                    ? null
                                    : () => openLink(newJwxtBaseUrl),
                                style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    alignment: Alignment.centerLeft),
                                child: const Text('打开教务系统')),
                          ])),
                      const SizedBox(height: 10),
                      Center(
                          child: TextButton(
                              key: const ValueKey('otherLoginMethods'),
                              onPressed: busy ? null : _otherMethods,
                              child: const Text('其他登录方式'))),
                    ]))));
  }
}
