import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/_providers.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/providers/pnp_troubleshooter_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/error_code_helper.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';

class PnpIspSaveSettingsView extends ArgumentsConsumerStatefulView {
  const PnpIspSaveSettingsView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<PnpIspSaveSettingsView> createState() =>
      _PnpIspSaveSettingsViewState();
}

class _PnpIspSaveSettingsViewState
    extends ConsumerState<PnpIspSaveSettingsView> {
  final _passwordController = TextEditingController();
  late final InternetSettingsState newSettings;
  String? _spinnerText;
  StreamSubscription? subscription;

  @override
  void initState() {
    super.initState();
    newSettings = widget.args['newSettings'] as InternetSettingsState;
    _saveNewSettings();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveNewSettings() {
    String? settingError;
    final wanType = WanType.resolve(
      newSettings.ipv4Setting.ipv4ConnectionType,
    )!;
    return ref
        .read(internetSettingsProvider.notifier)
        .savePnpIpv4(newSettings)
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
            onCompleted: (_) {
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
                    .checkInternetConnection(30)
                    .then((value) {
                  logger.i(
                      '[PnP]: Troubleshooter - Check internet connection with new settings - OK');
                  if (mounted) {
                    context.goNamed(RouteNamed.pnp);
                  }
                }).catchError((error) {
                  logger.e(
                      '[PnP]: Troubleshooter - Check internet connection with new settings - Failed');
                  if (mounted) {
                    context.pop(_getErrorMessage(wanType));
                  }
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
    }).onError((error, stackTrace) {
      logger.e(
          '[PnP]: Troubleshooter - Failed to save the new settings - $error');
      if (!mounted) return;
      if (error is JNAPSideEffectError) {
        final lastHandledResult = error.lastHandledResult;
        if (lastHandledResult != null && lastHandledResult is JNAPSuccess) {
          context.pop(_getErrorMessage(wanType));
        } else {
          // Handle side effect error
          showRouterNotFoundAlert(context, ref, onComplete: () async {
            context.goNamed(RouteNamed.pnp);
          });
        }
      } else if (error is JNAPError) {
        // Saving new settings failed
        context.pop(
            errorCodeHelper(context, error.result, _getErrorMessage(wanType)) ??
                _getErrorMessage(wanType));
      } else {
        context.pop(_getErrorMessage(wanType));
      }
    });
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
    return AppFullScreenSpinner(text: _spinnerText);
  }
}
