import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/advanced_settings/internet_settings/providers/_providers.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/pnp/data/pnp_exception.dart';
import 'package:linksys_app/page/pnp/data/pnp_provider.dart';
import 'package:linksys_app/page/pnp/troubleshooter/providers/pnp_troubleshooter_provider.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

class PnpIspSettingsAuthView extends ArgumentsConsumerStatefulView {
  const PnpIspSettingsAuthView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<PnpIspSettingsAuthView> createState() =>
      _PnpIspSettingsAuthViewState();
}

class _PnpIspSettingsAuthViewState
    extends ConsumerState<PnpIspSettingsAuthView> {
  final _passwordController = TextEditingController();
  late final InternetSettingsState newSettings;
  bool _isLoading = true;
  String? _inputPasswordError;
  late StreamSubscription subscription;

  @override
  void initState() {
    //First check if the admin password is available (from QRCode/URL)
    newSettings = widget.args['newSettings'] as InternetSettingsState;
    final isLoggedIn = ref.read(routerRepositoryProvider).isLoggedIn();
    final attachedPassword = ref.read(pnpProvider).attachedPassword;
    if (isLoggedIn) {
      // Credencials already exist, now save the settings
      _saveNewSettings();
    } else if (!isLoggedIn &&
        attachedPassword != null &&
        attachedPassword.isNotEmpty) {
      // Use the attached password to log in
      _loginAndSaveNewSettings(attachedPassword);
    } else {
      // Not logged in and no attached password
      _isLoading = false;
    }
    super.initState();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginAndSaveNewSettings(String password) {
    return ref
        .read(pnpProvider.notifier)
        .checkAdminPassword(password)
        .then((value) {
      // Login succeeded
      _saveNewSettings();
    }).onError((error, stackTrace) {
      // Login failed, show an error and password input form
      setState(() {
        _inputPasswordError = 'Invalid password';
        _isLoading = false;
      });
    });
  }

  Future<void> _saveNewSettings() {
    String? settingError;
    final wanType = WanType.resolve(
      newSettings.ipv4Setting.ipv4ConnectionType,
    )!;
    return ref
        .read(internetSettingsProvider.notifier)
        .saveIpv4(newSettings)
        .then((value) {
      // Saving successfully, check if the new settings valid
      subscription.cancel();
      subscription = ref
          .read(pnpTroubleshooterProvider.notifier)
          .checkNewSettings(
            settingWanType: wanType,
            onCompleted: () {
              if (settingError != null) {
                // New setting check failed
                context.pop(settingError);
              } else {
                // New setting check passed, then check real internet connection
                ref
                    .read(pnpProvider.notifier)
                    .checkInternetConnection()
                    .then((value) {
                  // Internet connection is OK
                  context.goNamed(RouteNamed.pnp);
                }).catchError((error) {
                  // Internet connection is Not OK
                  context.pop(_getErrorMessage(wanType));
                }, test: (error) => error is ExceptionNoInternetConnection);
              }
              subscription.cancel();
            },
          )
          .listen((isValid) {
        if (isValid) {
          // The new setting is working now
          settingError = null;
          // This also indicates the check loop has fulfilled
        } else {
          // The new setting is not working yet for the moment
          settingError = _getErrorMessage(wanType);
          // Keep the error record until the check loop is fulfilled or runs out of the re-try quota
        }
      });
    }).onError((error, stackTrace) {
      // Saving new settings failed
      context.pop('Fail to save the new settings');
    });
  }

  String _getErrorMessage(WanType wanType) {
    if (wanType == WanType.static || wanType == WanType.dhcp) {
      return 'Couldn’t establish a connection. Please check your info and try again.';
    } else {
      // This case must be PPPOE
      return 'Account name or password incorrect. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const AppFullScreenSpinner()
        : StyledAppPageView(
            title: 'Enter your router’s password to proceed',
            child: AppBasicLayout(
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField.outline(
                    headerText: loc(context).password,
                    controller: _passwordController,
                  ),
                  const AppGap.extraBig(),
                  if (_inputPasswordError != null)
                    AppText.bodyLarge(
                      _inputPasswordError!,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  const AppGap.extraBig(),
                  AppTextButton.noPadding(
                    'Where is it?',
                    onTap: () {
                      //TODO: Where is it?
                    },
                  ),
                ],
              ),
              footer: AppFilledButton.fillWidth(
                loc(context).next,
                onTap: () {
                  setState(() {
                    _isLoading = true;
                  });
                  _loginAndSaveNewSettings(_passwordController.text);
                },
              ),
            ),
          );
  }
}
