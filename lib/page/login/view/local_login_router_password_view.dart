import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/provider/auth/_auth.dart';
import 'package:linksys_app/provider/auth/auth_provider.dart';
import 'package:linksys_app/provider/connectivity/_connectivity.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/core/jnap/models/device_info.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/page/components/customs/network_check_view.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/provider/network/_network.dart';
import 'package:linksys_app/util/error_code_handler.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/theme/data/colors.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

class EnterRouterPasswordView extends ConsumerStatefulWidget {
  const EnterRouterPasswordView({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<EnterRouterPasswordView> createState() =>
      _EnterRouterPasswordState();
}

class _EnterRouterPasswordState extends ConsumerState<EnterRouterPasswordView> {
  bool _isConnectedToRouter = false;
  bool _isLoading = false;
  bool _isPasswordValidate = false;
  String _errorReason = '';

  String _hint = '';
  RouterDeviceInfo? _deviceInfo;

  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const AppFullScreenSpinner()
        : StyledAppPageView(
            scrollable: true,
            child: _isConnectedToRouter
                ? _enterRouterPasswordView(context)
                : NetworkCheckView(
                    description: getAppLocalizations(context)
                        .local_login_connect_to_your_router,
                    button: AppPrimaryButton(
                      getAppLocalizations(context).text_continue,
                      onTap: () {
                        checkWifi();
                      },
                    )),
          );
  }

  void checkWifi() async {
    // TODO: check if connect to router
    setState(() {
      _isLoading = true;
    });

    bool isConnected =
        ref.read(connectivityProvider).connectivityInfo.routerType !=
            RouterType.others;

    if (isConnected) {
      _deviceInfo = await ref.read(networkProvider.notifier).getDeviceInfo();
      await ref
          .read(authProvider.notifier)
          .getAdminPasswordInfo()
          .then((value) => _handleAdminPasswordInfo(value))
          .onError((error, stackTrace) {
        logger.d('Get Admin Password Hint Error $error');
      });
    }
    setState(() {
      _isConnectedToRouter = isConnected;
      _isLoading = false;
    });
  }

  Widget _enterRouterPasswordView(BuildContext context) {
    return AppBasicLayout(
      crossAxisAlignment: CrossAxisAlignment.start,
      header: AppText.titleLarge(
        getAppLocalizations(context).local_login_title,
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppGap.regular(),
          AppPasswordField(
            headerText: getAppLocalizations(context).router_password,
            controller: _passwordController,
            hintText: getAppLocalizations(context).router_password,
            onChanged: _verifyPassword,
            // isError: _errorReason.isNotEmpty,
            errorText: generalErrorCodeHandler(context, _errorReason),
          ),
          if (_hint.isNotEmpty)
            Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: AppText.headlineSmall(
                  getAppLocalizations(context).show_hint,
                  color: ConstantColors.primaryLinksysBlue,
                ),
                collapsedTextColor: Theme.of(context).colorScheme.onTertiary,
                textColor: Theme.of(context).colorScheme.onTertiary,
                tilePadding: EdgeInsets.zero,
                backgroundColor: Colors.transparent,
                trailing: const SizedBox(),
                expandedAlignment: Alignment.centerLeft,
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(_hint)],
              ),
            ),
          AppTertiaryButton(getAppLocalizations(context).forgot_router_password,
              onTap: () {
            // Go Router
          }),
          const Spacer(),
          AppPrimaryButton(
            getAppLocalizations(context).text_continue,
            onTap: _isPasswordValidate ? _localLogin : null,
          ),
        ],
      ),
    );
  }

  _verifyPassword(String value) async {
    setState(() {
      _isPasswordValidate = value.isNotEmpty;
    });
  }

  _localLogin() async {
    await ref
        .read(authProvider.notifier)
        .localLogin(_passwordController.text)
        .then<void>((_) {})
        .onError((error, stackTrace) => _handleError(error, stackTrace));
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
