import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/_providers.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/providers/pnp_troubleshooter_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';

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
  String? _spinnerText; //TODO: all spinner text is not confirmed
  String? _inputPasswordError;
  StreamSubscription? subscription;

  @override
  void initState() {
    //First check if the admin password is available (from QRCode/URL)
    newSettings = widget.args['newSettings'] as InternetSettingsState;
    final isLoggedIn = ref.read(routerRepositoryProvider).isLoggedIn();
    final attachedPassword = ref.read(pnpProvider).attachedPassword;
    if (isLoggedIn) {
      logger.i('[PnP]: Troubleshooter - Now is already logged in');
      // Credencials already exist, now save the settings
      _saveNewSettings();
    } else if (!isLoggedIn &&
        attachedPassword != null &&
        attachedPassword.isNotEmpty) {
      logger.i(
          '[PnP]: Troubleshooter - Not logged in yet but has credential attached');
      // Use the attached password to log in
      _loginAndSaveNewSettings(attachedPassword);
    } else {
      logger
          .i('[PnP]: Troubleshooter - No credential at all, need manual input');
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
    setState(() {
      _spinnerText = 'Verifying the attached credential...';
    });
    return ref
        .read(pnpProvider.notifier)
        .checkAdminPassword(password)
        .then((value) {
      logger.i('[PnP]: Troubleshooter - Login succeeded');
      // Login succeeded
      _saveNewSettings();
    }).catchError((error) {
      logger
          .e('[PnP]: Troubleshooter - Login failed - Invalid admin password!');
      // Login failed, show password input form with an error
      setState(() {
        _inputPasswordError = loc(context).errorIncorrectPassword;
        _isLoading = false;
      });
    }, test: (error) => error is ExceptionInvalidAdminPassword);
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
      setState(() {
        _spinnerText = loc(context).savingChanges;
      });
      logger
          .i('[PnP]: Troubleshooter - The new settings is saved successfully');
      // Saving successfully, check if the new settings valid
      subscription?.cancel();
      subscription = ref
          .read(pnpTroubleshooterProvider.notifier)
          .checkNewSettings(
            settingWanType: wanType,
            onCompleted: () {
              if (settingError != null) {
                logger.e(
                    '[PnP]: Troubleshooter - Failed to use the new router configuration');
                // New setting check failed
                context.pop(settingError);
              } else {
                logger.i(
                    '[PnP]: Troubleshooter - The new router configuration is fine to work now');
                // New setting check passed, then check real internet connection
                setState(() {
                  _spinnerText = loc(context).launchCheckInternet;
                });
                ref
                    .read(pnpProvider.notifier)
                    .checkInternetConnection()
                    .then((value) {
                  logger.i(
                      '[PnP]: Troubleshooter - Check internet connection with new settings - OK');
                  // Internet connection is OK
                  context.goNamed(RouteNamed.pnp);
                }).catchError((error) {
                  logger.e(
                      '[PnP]: Troubleshooter - Check internet connection with new settings - Failed');
                  // Internet connection is Not OK
                  context.pop(_getErrorMessage(wanType));
                }, test: (error) => error is ExceptionNoInternetConnection);
              }
              subscription?.cancel();
            },
          )
          .listen((isValid) {
        logger.i(
          '[PnP]: Troubleshooter - Check the new setting configuration - ${isValid ? 'Passed' : 'Not passed'}',
        );
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
    }).catchError(
      (error) {
        logger.e(
            '[PnP]: Troubleshooter - Failed to save the new settings - $error');
        // Saving new settings failed
        context.pop('Failed to save the new settings');
      },
      test: (error) => (error is JNAPError ||
          error is TimeoutException ||
          error is ClientException),
    );
  }

  String _getErrorMessage(WanType wanType) {
    if (wanType == WanType.static || wanType == WanType.dhcp) {
      return loc(context).pnpErrorForStaticIpAndDhcp;
    } else {
      // This case must be PPPOE
      return loc(context).pnpErrorForPppoe;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? AppFullScreenSpinner(text: _spinnerText)
        : StyledAppPageView(
            title: loc(context).pnpIspSettingsAuthTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField.outline(
                  secured: true,
                  headerText: loc(context).password,
                  controller: _passwordController,
                ),
                if (_inputPasswordError != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: Spacing.medium,
                    ),
                    child: AppText.bodyLarge(
                      _inputPasswordError!,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: Spacing.large3 + Spacing.small2,
                  ),
                  child: AppTextButton.noPadding(
                    loc(context).pnpRouterLoginWhereIsIt,
                    onTap: () {
                      //TODO: Where is it?
                    },
                  ),
                ),
                AppFilledButton(
                  loc(context).next,
                  onTap: () {
                    setState(() {
                      _isLoading = true;
                    });
                    _loginAndSaveNewSettings(_passwordController.text);
                  },
                ),
              ],
            ),
          );
  }
}
