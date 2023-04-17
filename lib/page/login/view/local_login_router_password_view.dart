import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/auth/bloc.dart';
import 'package:linksys_moab/bloc/auth/state.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/model/router/device_info.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/page/components/customs/network_check_view.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_moab/util/error_code_handler.dart';

import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/theme/data/colors.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/input_field/app_password_field.dart';
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
        ? const LinksysFullScreenSpinner()
        : StyledLinksysPageView(
            scrollable: true,
            child: _isConnectedToRouter
                ? _enterRouterPasswordView(context)
                : NetworkCheckView(
                    description: getAppLocalizations(context)
                        .local_login_connect_to_your_router,
                    button: LinksysPrimaryButton(
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

    final bloc = context.read<AuthBloc>();
    bool isConnected =
        context.read<ConnectivityCubit>().state.connectivityInfo.routerType !=
            RouterType.others;

    if (isConnected) {
      _deviceInfo = await context.read<NetworkCubit>().getDeviceInfo();
      await bloc
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
    return LinksysBasicLayout(
      crossAxisAlignment: CrossAxisAlignment.start,
      header: LinksysText.screenName(
        getAppLocalizations(context).local_login_title,
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LinksysGap.regular(),
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
                title: LinksysText.label(
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
          LinksysTertiaryButton(
              getAppLocalizations(context).forgot_router_password, onTap: () {
            ref
                .read(navigationsProvider.notifier)
                .push(AuthLocalRecoveryKeyPath());
          }),
          const Spacer(),
          LinksysPrimaryButton(
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
    setState(() {
      _isLoading = true;
    });
    await context
        .read<AuthBloc>()
        .localLogin(_passwordController.text)
        .then<void>((_) {})
        .onError((error, stackTrace) => _handleError(error, stackTrace));
    setState(() {
      _isLoading = false;
    });
  }

  _handleAdminPasswordInfo(AdminPasswordInfo info) {
    if (!info.hasAdminPassword) {
      ref
          .read(navigationsProvider.notifier)
          .replace(CreateAdminPasswordPath()..args = {});
    } else {
      setState(() {
        _hint = info.hint;
      });
    }
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
