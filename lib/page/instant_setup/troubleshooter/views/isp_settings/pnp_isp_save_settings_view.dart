import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/models/auto_master_status.dart';
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
import 'package:privacy_gui/page/instant_setup/widgets/pnp_auto_master_flow.dart';
import 'package:privacy_gui/page/instant_setup/widgets/pnp_auto_master_waiting_view.dart';
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

class _PnpIspSaveSettingsViewState extends ConsumerState<PnpIspSaveSettingsView>
    with PnpAutoMasterFlowMixin<PnpIspSaveSettingsView> {
  final _passwordController = TextEditingController();
  late final InternetSettingsState newSettings;
  String? _spinnerText; //TODO: all spinner text is not confirmed
  StreamSubscription? subscription;

  // Auto Master state
  bool _waitingForAutoMaster = false;
  bool _showAutoMasterConnectionError = false;

  // Whether the current Auto Master wait was triggered after WAN came up
  // (post internet-check), as opposed to the pre-save check. Governs the retry
  // path in [build].
  bool _autoMasterPostWanUp = false;

  @override
  void initState() {
    super.initState();
    newSettings = widget.args['newSettings'] as InternetSettingsState;
    _saveNewSettings();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    subscription?.cancel();
    super.dispose();
  }

  /// Check Auto Master status before saving ISP settings.
  /// Returns true if save should continue, false if redirected or waiting.
  Future<bool> _checkAndWaitForAutoMaster() async {
    final status = await ref.read(pnpProvider.notifier).checkAutoMasterStatus();

    // null means the status is unavailable — unreachable router, or firmware
    // that does not serve GetAutoMasterStatus unauthed. Either way there is
    // nothing to wait for, so continue the save.
    if (status == null) {
      logger.d(
          '[PnP]: Troubleshooter - Auto Master status unavailable, continue save');
      return true;
    }

    if (status == AutoMasterStatus.running) {
      _autoMasterPostWanUp = false;
      final result = await runAutoMasterFlow(
        onEnterWaiting: () => setState(() {
          _waitingForAutoMaster = true;
          _showAutoMasterConnectionError = false;
        }),
        onShowConnectionError: () =>
            setState(() => _showAutoMasterConnectionError = true),
        onExitWaiting: () => setState(() => _waitingForAutoMaster = false),
      );
      if (!mounted) return false;
      switch (result) {
        case AutoMasterFlowResult.completed:
          logger.i(
              '[PnP]: Troubleshooter - Auto Master completed, redirect to PnP');
          context.goNamed(RouteNamed.pnp);
          return false;
        case AutoMasterFlowResult.proceed:
          logger.i('[PnP]: Troubleshooter - Auto Master done, continue save');
          return true;
        case AutoMasterFlowResult.budgetExhausted:
          // Out of time but the router answers, so Auto Master may still be
          // mid-flight. Save anyway: we have already waited out the full
          // budget, and if the credential does get rotated under us the save
          // fails as a JNAPError, which _saveNewSettings' error path already
          // turns into a message the user can act on.
          logger.w(
              '[PnP]: Troubleshooter - Auto Master outcome unknown, continue save');
          return true;
        case AutoMasterFlowResult.connectionError:
          // Waiting view already shows the error + retry.
          return false;
      }
    }

    // Only when the rotation happened *since* our last accepted password. The
    // firmware latches this status at `complete` permanently, so read on its own
    // it says "this router was auto-mastered at some point" — which, on any
    // router that has ever been auto-mastered, is true on every subsequent
    // visit. That made this branch a trap: entering the ISP-save view would
    // bounce to PnP before saving anything, PnP would find no internet and route
    // back into the troubleshooter, and the user could never get their PPPoE
    // settings saved at all. The flag narrows it to the case that needs the
    // redirect: a credential older than the rotation.
    if (status == AutoMasterStatus.complete &&
        ref.read(pnpProvider).autoMasterRotatedSinceLogin) {
      logger.i(
          '[PnP]: Troubleshooter - Auto Master already completed, redirect to PnP');
      if (mounted) context.goNamed(RouteNamed.pnp);
      return false;
    }

    return true; // idle/failed → continue save
  }

  Future<void> _saveNewSettings() async {
    // Check Auto Master status before saving
    final shouldContinue = await _checkAndWaitForAutoMaster();
    if (!shouldContinue) return;
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
                    .then((value) async {
                  logger.i(
                      '[PnP]: Troubleshooter - Check internet connection with new settings - OK');
                  // Internet connection is OK. WAN is now up, so firmware may
                  // start Auto Master ("make Master") shortly. Detect it here
                  // (★) so the user waits once instead of filling WiFi twice.
                  _autoMasterPostWanUp = true;
                  final result = await runAutoMasterFlow(
                    waitForRunningFirst: true,
                    onEnterWaiting: () => setState(() {
                      _waitingForAutoMaster = true;
                      _showAutoMasterConnectionError = false;
                    }),
                    onShowConnectionError: () =>
                        setState(() => _showAutoMasterConnectionError = true),
                    onExitWaiting: () =>
                        setState(() => _waitingForAutoMaster = false),
                  );
                  if (!mounted) return;
                  if (result != AutoMasterFlowResult.connectionError) {
                    // completed / proceed / budgetExhausted → go to PnP and let
                    // its entry precheck decide. Nothing is pending here (the
                    // settings are already saved), so an unknown Auto Master
                    // outcome needs no special handling: PnP re-reads whatever
                    // state the router is actually in.
                    context.goNamed(RouteNamed.pnp);
                  }
                  // connectionError → waiting view shows error + retry.
                }).catchError((error) {
                  logger.e(
                      '[PnP]: Troubleshooter - Check internet connection with new settings - Failed');
                  // Internet connection is Not OK
                  context.pop(_getErrorMessage(wanType));
                }, test: (error) => error is ExceptionNoInternetConnection).catchError(
                    (error) {
                  // The credential was rotated while we were checking. This
                  // window is 30 retries wide (~90s) and Auto Master runs for
                  // ~115s from WAN-up, so a rotation can land inside it — and
                  // that is *success*, not a settings failure. Popping an ISP
                  // error here would blame the settings the user just got right.
                  logger.i(
                      '[PnP]: Troubleshooter - Auto Master rotated the password mid-check, back to PnP');
                  if (mounted) context.goNamed(RouteNamed.pnp);
                }, test: (error) => error is ExceptionInvalidAdminPassword);
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
    if (_waitingForAutoMaster) {
      return PnpAutoMasterWaitingView(
        showConnectionError: _showAutoMasterConnectionError,
        onRetry: () {
          setState(() {
            _showAutoMasterConnectionError = false;
            _waitingForAutoMaster = false;
          });
          if (_autoMasterPostWanUp) {
            // The error happened after WAN was already up (settings saved).
            // Re-saving would be wrong; restart the flow via PnP (re-entry is
            // itself the recovery path).
            context.goNamed(RouteNamed.pnp);
          } else {
            // Pre-save error → re-run the save from the top.
            _saveNewSettings();
          }
        },
      );
    }
    return AppFullScreenSpinner(text: _spinnerText);
  }
}
