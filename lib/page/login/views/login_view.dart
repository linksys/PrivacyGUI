import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:linksys_app/page/components/styled/bottom_bar.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/providers/auth/_auth.dart';
import 'package:linksys_app/providers/auth/auth_provider.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_app/util/error_code_handler.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/card/card.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

class LoginView extends ArgumentsConsumerStatefulView {
  const LoginView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  bool _isLoading = false;
  bool _isPasswordValidate = false;
  String _errorReason = '';

  String _hint = '';

  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    checkWifi();
    ref.read(dashboardManagerProvider.notifier).checkDeviceInfo(null);
  }

  @override
  void dispose() {
    super.dispose();
    _passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const AppFullScreenSpinner()
        : StyledAppPageView(
            appBarStyle: AppBarStyle.none,
            padding: EdgeInsets.zero,
            scrollable: true,
            child: AppBasicLayout(
              content: Center(
                child: AppCard(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText.headlineSmall(getAppLocalizations(context).login),
                      const AppGap.big(),
                      SizedBox(
                        width: 289,
                        child: AppPasswordField(
                          border: const OutlineInputBorder(),
                          controller: _passwordController,
                          hintText: getAppLocalizations(context).password,
                          onChanged: _verifyPassword,
                          errorText:
                              generalErrorCodeHandler(context, _errorReason),
                        ),
                      ),
                      if (_hint.isNotEmpty)
                        Theme(
                          data: Theme.of(context)
                              .copyWith(dividerColor: Colors.transparent),
                          child: SizedBox(
                            width: 200,
                            child: ExpansionTile(
                              title: AppText.bodySmall(
                                getAppLocalizations(context).show_hint,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              tilePadding: EdgeInsets.zero,
                              backgroundColor: Colors.transparent,
                              trailing: const SizedBox(),
                              expandedAlignment: Alignment.centerLeft,
                              expandedCrossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [Text(_hint)],
                            ),
                          ),
                        ),
                      const AppGap.big(),
                      AppTextButton.noPadding(
                        'Forgot password',
                        onTap: () {
                          context.pushNamed(RouteNamed.localRouterRecovery);
                        },
                      ),
                      const AppGap.big(),
                      AppFilledButton(
                        'Log in',
                        onTap: _isPasswordValidate
                            ? () {
                                _localLogin();
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              footer: const BottomBar(),
            ),
          );
  }

  void checkWifi() async {
    // TODO: check if connect to router
    setState(() {
      _isLoading = true;
    });

    await ref
        .read(authProvider.notifier)
        .getAdminPasswordInfo()
        .then((value) => _handleAdminPasswordInfo(value))
        .onError((error, stackTrace) {
      logger.d('Get Admin Password Hint Error $error');
    });

    setState(() {
      _isLoading = false;
    });
  }

  _verifyPassword(String value) async {
    setState(() {
      _isPasswordValidate = value.isNotEmpty;
    });
  }

  _localLogin() async {
    setState(() {
      _isLoading = true;
    });
    await ref
        .read(authProvider.notifier)
        .localLogin(_passwordController.text)
        .then<void>((_) {})
        .onError((error, stackTrace) => _handleError(error, stackTrace));
    setState(() {
      _isLoading = false;
    });
  }

  _handleAdminPasswordInfo(String info) {
    setState(() {
      _hint = info;
    });
  }

  _handleError(Object? e, StackTrace trace) {
    if (e is JNAPError) {
      setState(() {
        _errorReason = e.result;
      });
    } else {
      // Unknown error or error parsing
      logger.d('Unknown error: $e');
    }
  }
}
