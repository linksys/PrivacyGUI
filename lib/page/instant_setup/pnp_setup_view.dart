import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as service;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/models/auto_configuration_settings.dart';
import 'package:privacy_gui/core/jnap/models/auto_master_status.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/model/impl/guest_wifi_step.dart';
import 'package:privacy_gui/page/instant_setup/model/impl/night_mode_step.dart';
import 'package:privacy_gui/page/instant_setup/model/impl/personal_wifi_step.dart';
import 'package:privacy_gui/page/instant_setup/model/impl/your_network_step.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';
import 'package:privacy_gui/page/instant_setup/widgets/pnp_auto_master_flow.dart';
import 'package:privacy_gui/page/instant_setup/widgets/pnp_auto_master_waiting_view.dart';
import 'package:privacy_gui/page/instant_setup/widgets/pnp_stepper.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/qr_code.dart';
import 'package:privacy_gui/util/wifi_credential.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacygui_widgets/widgets/progress_bar/spinner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:privacy_gui/util/export_selector/export_base.dart'
    if (dart.library.io) 'package:privacy_gui/util/export_selector/export_mobile.dart'
    if (dart.library.html) 'package:privacy_gui/util/export_selector/export_web.dart';

enum _PnpSetupStep {
  init,
  config,
  waitingAutoMaster,
  saving,
  saved,
  fwCheck,
  wifiReady,
  needReconnect,
  ;
}

class PnpSetupView extends ConsumerStatefulWidget {
  const PnpSetupView({Key? key}) : super(key: key);

  @override
  ConsumerState<PnpSetupView> createState() => _PnpSetupViewState();
}

class _PnpSetupViewState extends ConsumerState<PnpSetupView>
    with PageSnackbarMixin, PnpAutoMasterFlowMixin<PnpSetupView> {
  // Defaulted rather than `late final`: `dispose()` iterates this, and the
  // assignment in initState only happens after fetchData succeeds, so a fetch
  // error used to make disposal throw a LateInitializationError.
  List<PnpStep> steps = const [];
  _PnpSetupStep _setupStep = _PnpSetupStep.init;
  String _loadingMessage = '';
  String _loadingMessageSub = '';
  bool _isUnconfigured = false;
  bool _isPrePaired = false;
  bool _needToReconnect = false;
  bool _hasNewFW = false;
  bool _forceLogin = false;
  bool _fetchError = false;
  bool _showAutoMasterConnectionError = false;
  bool _wifiVerificationRetried =
      false; // Prevent infinite loop in WiFi verification
  bool _saveStarted = false;
  bool _firmwareCheckStarted = false;
  bool _reconnectChecking = false;
  bool _reconnectTimedOut = false;
  bool _reconnectWasUnconfigured = false;
  bool _reconnectCompleted = false;
  bool _reconnectProbePending = false;
  List<String>? _postSavePasswordCandidates;
  PnpStep? _currentStep;
  ({void Function() stepCancel, void Function() stepContinue})? _stepController;

  @override
  void initState() {
    super.initState();

    Future.doWhile(() => !mounted).then((_) async {
      setState(() {
        _loadingMessage = loc(context).collectingData;
        _setupStep = _PnpSetupStep.init;
        logger.d('[PnP]: Fetching data. Setup step = init');
      });
      await ref.read(pnpProvider.notifier).fetchData();
    }).then((_) async {
      // Record Auto Master status on entry for edge case detection
      final status =
          await ref.read(pnpProvider.notifier).checkAutoMasterStatus();
      ref.read(pnpProvider.notifier).setAutoMasterStatusOnEntry(status);
      logger.d('[PnP]: Auto Master status on entry: $status');
    }).then((_) {
      _isUnconfigured = ref.read(pnpProvider).isRouterUnConfigured;
      _isPrePaired = ref.read(pnpProvider).isPrePaired;
      _forceLogin = ref.read(pnpProvider).forceLogin;
      steps = buildSteps();
      logger.d(
          '[PnP]: Prescribed setup steps=${steps.map((e) => e.title(context))}');
      setState(() {
        _setupStep = _PnpSetupStep.config;
        logger.d('[PnP]: Settle configuration. Setup step = config');
      });
    }).onError((e, _) {
      logger.d('[PnP]: Fetch router data failed. Try again');
      setState(() {
        _fetchError = true;
      });
    });
  }

  @override
  void dispose() {
    for (var element in steps) {
      element.onDispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(firmwareUpdateProvider, (previous, next) {
      if (_setupStep != _PnpSetupStep.fwCheck) {
        return;
      }
      if (!_hasNewFW) {
        return;
      }
      if (previous?.isUpdating == true && next.isUpdating == false) {
        logger.d('[PnP]: FW update finish go WiFi Ready!');
        _goWiFiReady();
      }
    });
    return StyledAppPageView.innerPage(
        scrollable: true,
        padding: EdgeInsets.zero,
        useMainPadding: true,
        child: (context, constraints) => AppCard(
              showBorder: false,
              color: Theme.of(context).colorScheme.background,
              padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveLayout.pageHorizontalPadding(context)),
              child:
                  _fetchError ? _errorView() : _buildPnpSetupView(constraints),
            ));
  }

  void _onWiFiReadyDone() {
    // Check router connected proper, then go to dashboard
    testConnection(success: () {
      logger
          .i('[PnP]: The customized WiFi is well connected, go to dashboard!');
      context.goNamed(RouteNamed.prepareDashboard);
    });
  }

  Widget _errorView() {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: Center(
        child: AppCard(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText.headlineSmall(loc(context).generalError),
              const AppGap.large5(),
              AppFilledButton(
                loc(context).tryAgain,
                onTap: () {
                  logger.d('[PnP]: Tap try again, go home.');
                  context.goNamed(RouteNamed.home);
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  List<PnpStep> buildSteps() {
    // For Pinnacle
    final services = ref.read(pnpProvider).deviceInfo?.services;
    final isGuestWiFiSupport = serviceHelper.isSupportGuestNetwork(services);
    final isNightModeSupport = serviceHelper.isSupportLedMode(services);
    // Show YourNetworkStep when unconfigured OR not pre-paired (AutoParent case)
    final showYourNetwork = _isUnconfigured || !_isPrePaired;
    // Log PnP state for debugging
    final autoConfigData = ref
        .read(pnpProvider.notifier)
        .getData(JNAPAction.getAutoConfigurationSettings);
    final autoConfigMethod = autoConfigData != null
        ? AutoConfigurationSettings.fromMap(autoConfigData)
            .autoConfigurationMethod
            ?.name
        : 'unknown';
    logger.d('[PnP]: buildSteps state - '
        'isUnconfigured=$_isUnconfigured, '
        'isPrePaired=$_isPrePaired, '
        'forceLogin=$_forceLogin, '
        'showYourNetwork=$showYourNetwork, '
        'autoConfigurationMethod=$autoConfigMethod, '
        'isGuestWiFiSupport=$isGuestWiFiSupport, '
        'isNightModeSupport=$isNightModeSupport');
    // Need a common way to figure out which step to save changes
    return switch ((_forceLogin, _isUnconfigured, showYourNetwork)) {
      // Unconfigured and AutoParent share the same step assembly:
      // save at last WiFi step before YourNetwork to ensure smart mode = master
      (false, _, true) => [
          PersonalWiFiStep(
              saveChanges: !isGuestWiFiSupport && !isNightModeSupport
                  ? _saveChanges
                  : null),
          if (isGuestWiFiSupport)
            GuestWiFiStep(
                saveChanges: !isNightModeSupport ? _saveChanges : null),
          if (isNightModeSupport) NightModeStep(saveChanges: _saveChanges),
          YourNetworkStep(saveChanges: _confirmAddedNodes),
        ],
      (true, false, _) => [
          PersonalWiFiStep(),
        ],
      (true, true, _) => [
          PersonalWiFiStep(saveChanges: _saveChanges),
          YourNetworkStep(saveChanges: _confirmAddedNodes),
        ],
      _ => [
          // Configured + PrePaired: no YourNetwork step
          // WiFi steps have no saveChanges - saving is handled by onLastStep
          PersonalWiFiStep(),
          if (isGuestWiFiSupport) GuestWiFiStep(),
          if (isNightModeSupport) NightModeStep(),
        ],
    };
  }

  Widget _buildPnpSetupView(BoxConstraints constraints) {
    final showConfig = _setupStep != _PnpSetupStep.saving &&
        _setupStep != _PnpSetupStep.saved &&
        _setupStep != _PnpSetupStep.needReconnect &&
        _setupStep != _PnpSetupStep.waitingAutoMaster;
    return switch (_setupStep) {
      _PnpSetupStep.init => _loadingSpinner(),
      _PnpSetupStep.waitingAutoMaster => PnpAutoMasterWaitingView(
          showConnectionError: _showAutoMasterConnectionError,
          onRetry: _retryAutoMasterSave,
        ),
      _PnpSetupStep.wifiReady => _showWiFi(constraints),
      _PnpSetupStep.fwCheck => _fwUpdateCheck(),
      _ => Stack(
          children: [
            IgnorePointer(
                ignoring: !showConfig,
                child: Opacity(
                    opacity: showConfig ? 1 : 0,
                    child: SizedBox(
                        height: constraints.maxHeight, child: _configView()))),
            Container(
              color: Theme.of(context).colorScheme.background,
              child: switch (_setupStep) {
                _PnpSetupStep.saving => _loadingSpinner(),
                _PnpSetupStep.saved => _showSaved(),
                _PnpSetupStep.needReconnect => _showNeedReconnect(),
                _ => SizedBox.square(),
              },
            )
          ],
        ),
    };
  }

  Widget _configView() => LayoutBuilder(builder: (context, constraints) {
        return Padding(
          padding: EdgeInsets.symmetric(
              vertical: ResponsiveLayout.isMobileLayout(context)
                  ? Spacing.small2
                  : Spacing.large5),
          child: PnpStepper(
            steps: steps,
            stepperType: StepperType.horizontal,
            // When showYourNetwork=true (except forceLogin), saving is handled by step's saveChanges, not onLastStep
            // forceLogin + configured + !isPrePaired still needs onLastStep since no YourNetwork step
            onLastStep: (_isUnconfigured || (!_forceLogin && !_isPrePaired))
                ? null
                : _saveChanges,
            onStepChanged: ((index, step, controller) {
              _currentStep = step;
              _stepController = controller;
            }),
          ),
        );
      });

  Widget _fwUpdateCheck() => Container(
        color: Theme.of(context).colorScheme.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: AppSpinner()),
              const AppGap.medium(),
              AppText.titleLarge(loc(context).pnpFwUpdateTitle),
              const AppGap.medium(),
              AppText.bodyMedium(loc(context).pnpFwUpdateDesc),
            ],
          ),
        ),
      );
  Widget _loadingSpinner() => Container(
        color: Theme.of(context).colorScheme.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: AppSpinner()),
              const AppGap.medium(),
              AppText.headlineSmall(_loadingMessage),
              const AppGap.medium(),
              AppText.bodyLarge(_loadingMessageSub),
            ],
          ),
        ),
      );
  Widget _showSaved() => Container(
        color: Theme.of(context).colorScheme.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppText.labelLarge(loc(context).saved),
              const AppGap.medium(),
              const Icon(
                LinksysIcons.checkCircle,
                semanticLabel: 'check icon',
              ),
            ],
          ),
        ),
      );

  Widget _showWiFi(BoxConstraints constraints) {
    final wifiData =
        ref.read(pnpProvider).stepStateList[PersonalWiFiStep.id]?.data;
    final isSplitMode = wifiData?['isSplitMode'] as bool? ?? false;
    // Build the list of bands to present. In split mode each enabled band has
    // its own ssid/password; in unified mode there is a single credential.
    final List<({String band, String ssid, String password})> bands;
    if (isSplitMode) {
      final perBandSettings =
          wifiData?['perBandSettings'] as Map<String, dynamic>? ?? {};
      bands = perBandSettings.entries.map((entry) {
        final value = entry.value as Map<String, dynamic>? ?? {};
        return (
          band: entry.key,
          ssid: value['ssid'] as String? ?? '',
          password: value['password'] as String? ?? '',
        );
      }).toList();
    } else {
      bands = [
        (
          band: '',
          ssid: wifiData?['ssid'] as String? ?? '',
          password: wifiData?['password'] as String? ?? '',
        ),
      ];
    }
    // Headline uses the primary/first band's SSID.
    final headlineSSID = bands.firstOrNull?.ssid ?? '';
    // Bound the height and split scrollable content from a pinned footer, the
    // same pattern the stepper uses, so the "Done" button stays visible at the
    // bottom and is aligned/styled consistently with the Back/Next steps.
    return SizedBox(
      height: constraints.maxHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LinksysIcons.wifi,
                    semanticLabel: 'wifi icon',
                    color: Theme.of(context).colorScheme.primary,
                    size: 48,
                  ),
                  const AppGap.medium(),
                  AppText.headlineSmall(isSplitMode
                      ? loc(context).pnpNetworkReady
                      : loc(context).pnpWiFiReady(headlineSSID)),
                  const AppGap.medium(),
                  if (_needToReconnect)
                    AppText.bodyMedium(
                        loc(context).pnpWiFiReadyConnectToNewWiFi),
                  const AppGap.medium(),
                  AppText.bodyMedium(loc(context).pnpScanQR),
                  const AppGap.large5(),
                  if (isSplitMode)
                    ...bands.map((b) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: Spacing.small2),
                          child: _splitBandCard(b.band, b.ssid, b.password),
                        ))
                  else
                    _unifiedWiFiCard(
                        headlineSSID, bands.firstOrNull?.password ?? ''),
                ],
              ),
            ),
          ),
          // Pinned footer — matches the stepper's control row styling
          // (vertical 16 padding, content-aligned, no divider).
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: AppFilledButton(
              loc(context).done,
              onTap: _onWiFiReadyDone,
            ),
          ),
        ],
      ),
    );
  }

  // Unified mode: large QR + separate password card (original layout).
  Widget _unifiedWiFiCard(String wifiSSID, String wifiPassword) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: AppCard(
              child: Column(
            children: [
              Container(
                color: Colors.white,
                height: 240,
                width: 240,
                child: QrImageView(
                  data: WiFiCredential(
                    ssid: wifiSSID,
                    password: wifiPassword,
                    type: SecurityType
                        .wpa, //TODO: The security type is fixed for now
                  ).generate(),
                ),
              ),
              const AppGap.medium(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  AppTextButton(
                    loc(context).print,
                    icon: LinksysIcons.print,
                    onTap: () => _printWiFi(wifiSSID, wifiPassword),
                  ),
                  AppTextButton(
                    loc(context).downloadQR,
                    icon: LinksysIcons.download,
                    onTap: () => _downloadWiFi(wifiSSID, wifiPassword),
                  ),
                ],
              ),
            ],
          )),
        ),
        const AppGap.small2(),
        Center(
          child: AppSettingCard(
            title: loc(context).wifiPassword,
            description: wifiPassword,
            trailing: AppIconButton(
              icon: LinksysIcons.fileCopy,
              semanticLabel: 'file copy',
              onTap: () => _copyPassword(wifiPassword),
            ),
          ),
        ),
      ],
    );
  }

  // Split mode: one compact horizontal card per band (QR on the left, band
  // name / SSID / password / actions on the right).
  Widget _splitBandCard(String band, String ssid, String password) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.white,
            height: 120,
            width: 120,
            child: QrImageView(
              data: WiFiCredential(
                ssid: ssid,
                password: password,
                type: SecurityType.wpa,
              ).generate(),
            ),
          ),
          const AppGap.medium(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.labelLarge(_bandLabel(band)),
                const AppGap.small1(),
                AppText.bodySmall(loc(context).wifiName),
                AppText.bodyMedium(ssid),
                const AppGap.small1(),
                AppText.bodySmall(loc(context).wifiPassword),
                Row(
                  children: [
                    Expanded(child: AppText.bodyMedium(password)),
                    AppIconButton.noPadding(
                      icon: LinksysIcons.fileCopy,
                      semanticLabel: 'file copy',
                      onTap: () => _copyPassword(password),
                    ),
                  ],
                ),
                const AppGap.small2(),
                Row(
                  children: [
                    AppTextButton.noPadding(
                      loc(context).print,
                      icon: LinksysIcons.print,
                      onTap: () => _printWiFi(ssid, password),
                    ),
                    const AppGap.medium(),
                    AppTextButton.noPadding(
                      loc(context).downloadQR,
                      icon: LinksysIcons.download,
                      onTap: () => _downloadWiFi(ssid, password),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _bandLabel(String band) {
    if (band.contains('2.4')) return '2.4 GHz';
    if (band.contains('5GHz_2')) return '5 GHz-2';
    if (band.contains('5GHz') || band.contains('5G')) return '5 GHz';
    if (band.contains('6GHz') || band.contains('6G')) return '6 GHz';
    return band;
  }

  void _printWiFi(String ssid, String password) {
    final ctx = context;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        createWiFiQRCode(WiFiCredential(
                ssid: ssid, password: password, type: SecurityType.wpa))
            .then((imageBytes) {
          printWiFiQRCode(ctx, imageBytes, ssid, password);
        });
      }
    });
  }

  void _downloadWiFi(String ssid, String password) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        createWiFiQRCode(WiFiCredential(
                ssid: ssid, password: password, type: SecurityType.wpa))
            .then((imageBytes) {
          exportFileFromBytes(
              fileName: 'share_wifi_$ssid.png', utf8Bytes: imageBytes);
        });
      }
    });
  }

  void _copyPassword(String password) {
    service.Clipboard.setData(service.ClipboardData(text: password))
        .then((value) => showSharedCopiedSnackBar());
  }

  Widget _showNeedReconnect() {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: Center(
        child: AppCard(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LinksysIcons.router,
                semanticLabel: 'router icon',
                color: Theme.of(context).colorScheme.primary,
                size: 48,
              ),
              const AppGap.medium(),
              AppText.headlineSmall(_reconnectTimedOut
                  ? loc(context).pnpRouterReconnectTimeoutTitle
                  : loc(context).pnpRouterReconnectTitle),
              const AppGap.medium(),
              AppText.bodyLarge(_reconnectTimedOut
                  ? (_reconnectProbePending
                      ? loc(context).pnpRouterReconnectPendingDesc
                      : loc(context).pnpRouterReconnectTimeoutDesc)
                  : loc(context).pnpRouterReconnectDesc),
              const AppGap.large5(),
              // No manual Next button: the check below runs itself and this
              // screen only surfaces its state. Try Again appears solely on the
              // timeout, and it re-probes -- it never resends the save.
              if (_reconnectTimedOut)
                AppFilledButton(
                  loc(context).tryAgain,
                  onTap: _reconnectChecking || _reconnectProbePending
                      ? null
                      : () => _checkPostSaveReconnect(waitForRestart: false),
                )
              else
                const AppSpinner(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkPostSaveReconnect({required bool waitForRestart}) async {
    if (_reconnectChecking ||
        _reconnectProbePending ||
        _reconnectCompleted ||
        !mounted) return;
    setState(() {
      _reconnectChecking = true;
      _reconnectTimedOut = false;
    });
    var acceptingResult = true;
    // Set when the SSID check below finds the WiFi settings did not take. The
    // corrective save re-enters this method, which this very call still holds,
    // so it has to be started from `finally` instead of inline.
    var resaveAfterMismatch = false;
    bool onReconnectPage() =>
        mounted && _setupStep == _PnpSetupStep.needReconnect;
    bool active() => acceptingResult && onReconnectPage();
    try {
      final operation = waitForPnpPostSaveReconnect(
        initialDelay: waitForRestart ? pnpReconnectInitialDelay : Duration.zero,
        shouldContinue: active,
        shouldRetry: (error) => error is! ExceptionInvalidAdminPassword,
        probe: () async {
          await ref.read(pnpProvider.notifier).testConnectionReconnected();
          if (!active()) throw ExceptionNeedToReconnect();
          await _checkPostSaveAdminPassword(shouldContinue: active);
          if (!active()) throw ExceptionNeedToReconnect();
          if (_reconnectWasUnconfigured) {
            final pnp = ref.read(pnpProvider.notifier);
            await pnp.checkRouterConfigured();
            if (!active() || ref.read(pnpProvider).isRouterUnConfigured) {
              throw ExceptionNeedToReconnect();
            }
          }
        },
      );
      _reconnectProbePending = true;
      // A timed-out request cannot be cancelled here. Do not overlap it with
      // a new authentication attempt; release Retry only when it settles.
      void settled() {
        if (mounted) setState(() => _reconnectProbePending = false);
      }

      unawaited(
          operation.then((_) => settled(), onError: (Object _) => settled()));
      final ready =
          await operation.timeout(pnpReconnectDeadline, onTimeout: () {
        acceptingResult = false;
        throw TimeoutException('PnP router readiness check timed out');
      });
      if (!active()) return;
      if (!ready) {
        setState(() => _reconnectTimedOut = true);
        return;
      }
      // The router answers and accepts the post-save credentials, but that only
      // proves it came back -- not that the WiFi settings landed. Verify the
      // SSID and correct it with one more save if it did not (issue #1006).
      // Note this keeps `pnpRouterReconnectTimeoutDesc` ("Your settings will
      // not be sent again") honest: that string belongs to the timeout view,
      // and Try Again still only re-probes.
      if (!_wifiVerificationRetried && !await _verifyWifiSettingsApplied()) {
        if (!active()) return;
        _wifiVerificationRetried = true;
        resaveAfterMismatch = true;
        return;
      }
      if (!active()) return;
      // Advance once, only after this same router accepts the post-save
      // credentials. No WiFi association, radio or Internet gate is added.
      _reconnectCompleted = true;
      _needToReconnect = false;
      // showYourNetwork, not `_reconnectWasUnconfigured`: AutoParent
      // (configured but not pre-paired) also has a YourNetwork step to advance
      // into, and would otherwise skip straight to the firmware check.
      final showYourNetwork = _isUnconfigured || !_isPrePaired;
      logger.i(
          '[PnP]: The router has come back after the save - isUnconfigured=$_isUnconfigured, isPrePaired=$_isPrePaired, showYourNetwork=$showYourNetwork');
      if (showYourNetwork) {
        _stepController?.stepContinue();
        if (mounted) setState(() => _setupStep = _PnpSetupStep.config);
      } else {
        logger.d(
            '[PnP]: Router reconnected, showYourNetwork=false. Setup step = fwCheck');
        _doFwUpdateCheck();
      }
    } catch (error) {
      if (!onReconnectPage()) return;
      setState(() => _reconnectTimedOut = true);
      if (error is! TimeoutException) {
        showSimpleSnackBar(
          context,
          error is ExceptionInvalidAdminPassword
              ? loc(context).incorrectPassword
              : describePnpSaveError(error),
        );
      }
    } finally {
      acceptingResult = false;
      if (mounted) setState(() => _reconnectChecking = false);
      if (resaveAfterMismatch && mounted) {
        unawaited(_resaveAfterWifiMismatch());
      }
    }
  }

  /// Re-runs the save after the SSID check found the WiFi settings did not take.
  /// Scheduled rather than awaited by its caller, which still holds the
  /// re-entrancy guard this re-save needs to pass.
  Future<void> _resaveAfterWifiMismatch() async {
    try {
      await _saveChanges(isRetry: true);
    } catch (error) {
      logger.e('[PnP]: Re-save after a WiFi settings mismatch failed: $error');
    }
  }

  /// Whether the router is now serving the WiFi settings the user entered.
  ///
  /// Returns true when there is nothing to compare or the comparison could not
  /// be made: this gates a *corrective re-save*, so an inconclusive answer must
  /// never trigger one.
  Future<bool> _verifyWifiSettingsApplied() async {
    final wifiData =
        ref.read(pnpProvider).stepStateList[PersonalWiFiStep.id]?.data ?? {};
    final isSplitMode = wifiData['isSplitMode'] as bool? ?? false;

    // Collect expected SSIDs (support split mode)
    Set<String> expectedSSIDs = {};
    if (isSplitMode) {
      final perBandSettings =
          wifiData['perBandSettings'] as Map<String, dynamic>? ?? {};
      for (final entry in perBandSettings.entries) {
        final value = entry.value as Map<String, dynamic>? ?? {};
        final ssid = value['ssid'] as String?;
        if (ssid != null && ssid.isNotEmpty) {
          expectedSSIDs.add(ssid);
        }
      }
    } else {
      final ssid = wifiData['ssid'] as String?;
      if (ssid != null && ssid.isNotEmpty) {
        expectedSSIDs.add(ssid);
      }
    }

    // Only verify if user has set SSID
    if (expectedSSIDs.isEmpty) return true;

    try {
      // Fetch current WiFi settings from router
      final radioInfoResult = await ref.read(routerRepositoryProvider).send(
            JNAPAction.getRadioInfo,
            auth: true,
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache,
          );
      final radioInfo = GetRadioInfo.fromMap(radioInfoResult.output);
      final currentSSIDs = radioInfo.radios.map((r) => r.settings.ssid).toSet();

      // Check if any expected SSID matches current settings
      if (expectedSSIDs.any((ssid) => currentSSIDs.contains(ssid))) {
        logger.d('[PnP]: WiFi settings verified - SSID matches');
        return true;
      }
      logger.w(
          '[PnP]: WiFi settings mismatch - expected: $expectedSSIDs, current: $currentSSIDs. Re-saving...');
      return false;
    } catch (e) {
      // API call failed, log warning but continue flow
      logger.w('[PnP]: Failed to verify WiFi settings: $e. Continuing...');
      return true;
    }
  }

  Future<void> _checkPostSaveAdminPassword({
    required bool Function() shouldContinue,
  }) async {
    final pnp = ref.read(pnpProvider.notifier);
    final currentPassword = ref.read(authProvider).value?.localPassword;
    final wifiPassword = pnp.getDefaultWiFiSettings().primaryRadio?.password;
    // localLogin enters a loading state before sending JNAP. Keep the accepted
    // save's candidates across transient errors instead of reading that state
    // again and incorrectly treating the missing value as a bad password.
    final candidates =
        _postSavePasswordCandidates ??= pnpPostSaveAdminPasswordCandidates(
      currentPassword: currentPassword,
      wifiPassword: wifiPassword,
      didSetAdminPassword: pnp.didSetAdminPasswordDuringSave,
    );
    if (candidates.isEmpty) {
      throw ExceptionInvalidAdminPassword();
    }

    for (var index = 0; index < candidates.length; index++) {
      if (!shouldContinue()) throw ExceptionNeedToReconnect();
      try {
        await pnp.checkAdminPassword(candidates[index]);
        return;
      } on ExceptionInvalidAdminPassword {
        if (!shouldContinue()) throw ExceptionNeedToReconnect();
        if (index + 1 == candidates.length) {
          rethrow;
        }
        logger.i(
          '[PnP]: Existing admin password was not accepted; trying the WiFi password used by factory-default PnP',
        );
      }
    }
  }

  /// How many Auto Master waits one save may spend before giving up.
  ///
  /// Counted in waits, not retries, because each wait now costs a full poll
  /// budget (~3 minutes) — the recursion below has to be read as wall-clock, not
  /// as a cheap re-check.
  static const int _maxAutoMasterWaits = 2;

  /// [isRetry] marks a deliberate re-entry by this view's own recovery paths —
  /// the Auto Master wait budget, the Auto Master retry button, and the
  /// corrective re-save after an SSID mismatch. Those legitimately call this
  /// method a second time, so they are exempt from the [_saveStarted] guard,
  /// which exists only to swallow *duplicate user input* (a double tap, or two
  /// steps both wired to `saveChanges`).
  Future<void> _saveChanges(
      {int autoMasterWaitsSpent = 0, bool isRetry = false}) async {
    if (_saveStarted && !isRetry) {
      logger.i('[PnP]: Save already started; ignoring duplicate request');
      return;
    }
    _saveStarted = true;
    final isUnconfigured = ref.read(pnpProvider).isRouterUnConfigured;

    // Check Auto Master status before save (Second Defense)
    final statusOnEntry = ref.read(pnpProvider).autoMasterStatusOnEntry;
    // null when the status is unavailable (unreachable, or firmware that does
    // not serve GetAutoMasterStatus unauthed) → fall through to the save.
    final AutoMasterStatus? currentStatus =
        await ref.read(pnpProvider.notifier).checkAutoMasterStatus();

    logger.d('[PnP]: Auto Master check before save - '
        'entry status: $statusOnEntry, current: $currentStatus');

    if (currentStatus == AutoMasterStatus.running) {
      // No onExitWaiting: each outcome below moves the step itself, and the
      // error outcomes have to stay on the waiting view to show the error.
      final result = await runAutoMasterFlow(
        onEnterWaiting: () => setState(() {
          _setupStep = _PnpSetupStep.waitingAutoMaster;
          _showAutoMasterConnectionError = false;
        }),
        onShowConnectionError: () =>
            setState(() => _showAutoMasterConnectionError = true),
      );
      if (!mounted) return;

      switch (result) {
        case AutoMasterFlowResult.completed:
          // make-Master rotated the admin password, so the pending save would
          // come back 401. Re-enter PnP so its precheck can ask for the new
          // password — the same destination the unauthorized-during-save branch
          // below already uses. Not `localLoginPassword`: that page belongs to a
          // finished setup (userAcknowledgedAutoConfiguration == true), and this
          // one never got saved.
          logger
              .w('[PnP]: Auto Master completed before save - password changed');
          context.goNamed(RouteNamed.pnp);
          return;
        case AutoMasterFlowResult.proceed:
          // Auto Master left the credential alone — the save can go ahead.
          logger.i('[PnP]: Auto Master not blocking, continuing save flow');
          break;
        case AutoMasterFlowResult.budgetExhausted:
          // Out of time, but the router answers — so Auto Master may still be
          // mid-flight. Unlike the other callers, this one has a save pending
          // that a rotation would break, so re-check from the top instead of
          // committing. Bounded, or a router stuck on `running` would loop for
          // ever.
          final waitsSpent = autoMasterWaitsSpent + 1;
          if (waitsSpent >= _maxAutoMasterWaits) {
            logger.e(
                '[PnP]: Auto Master still unresolved after $waitsSpent waits, giving up');
            setState(() {
              _showAutoMasterConnectionError = true;
            });
            return;
          }
          logger.w(
              '[PnP]: Auto Master outcome unknown, re-checking (wait $waitsSpent/$_maxAutoMasterWaits spent)');
          setState(() {
            _setupStep = _PnpSetupStep.config;
          });
          // isRetry: this is the wait budget re-checking from the top, not
          // duplicate user input, so it must pass the _saveStarted guard.
          return _saveChanges(autoMasterWaitsSpent: waitsSpent, isRetry: true);
        case AutoMasterFlowResult.connectionError:
          // The waiting view is showing the error + retry button.
          return;
      }
    }

    // Edge case: Was Idle on entry but now Complete.
    //
    // The `statusOnEntry == idle` half is what dates the transition, and is why
    // this branch does not need the `autoMasterRotatedSinceLogin` guard the two
    // gates outside this view carry: `complete` latches for ever, but `idle` on
    // entry proves it latched *during* this session rather than on some earlier
    // day. A router that was auto-mastered long ago reads `complete` on entry
    // too, so it never satisfies this condition.
    if (statusOnEntry == AutoMasterStatus.idle &&
        currentStatus == AutoMasterStatus.complete) {
      logger.w(
          '[PnP]: Auto Master completed during PnP config - password changed');
      if (mounted) {
        // Same destination as the branch above and as the
        // unauthorized-during-save handler: back into PnP for the new password.
        context.goNamed(RouteNamed.pnp);
      }
      return;
    }

    // Continue with existing save logic
    setState(() {
      _loadingMessage = loc(context).savingChanges;
      _loadingMessageSub = loc(context).pnpSavingChangesDesc;
      _setupStep = _PnpSetupStep.saving;
      logger.d('[PnP]: Save changes. Setup step = saving');
    });

    try {
      await ref.read(pnpProvider.notifier).save();
    } on ExceptionNeedToReconnect {
      if (!mounted) {
        return;
      }
      _currentStep?.canGoNext(false);
      setState(() {
        _needToReconnect = true;
        _reconnectWasUnconfigured = isUnconfigured;
        logger.e(
            '[PnP]: Connection changed while saving. Setup step = needReconnect');
        _setupStep = _PnpSetupStep.needReconnect;
      });
      unawaited(_checkPostSaveReconnect(waitForRestart: true));
      return;
    } on ExceptionInvalidAdminPassword {
      // The transaction may already have changed the factory-default admin
      // password. Reconcile credentials against the accepted save; never
      // offer to submit the transaction a second time.
      if (!mounted) {
        return;
      }
      _currentStep?.canGoNext(false);
      setState(() {
        _needToReconnect = true;
        _reconnectWasUnconfigured = isUnconfigured;
        _setupStep = _PnpSetupStep.needReconnect;
      });
      unawaited(_checkPostSaveReconnect(waitForRestart: false));
      return;
    } on ExceptionSavingChanges catch (error) {
      final innerError = error.error;
      // Auto Master rotating the admin password mid-save surfaces as a 401 on
      // the transaction. Nothing was written, so re-enter PnP and let its
      // precheck ask for the new password — the same destination the Auto
      // Master gates above use (#1418, #1419).
      if (innerError is JNAPError &&
          innerError.result == errorJNAPUnauthorized) {
        logger.w(
            '[PnP]: Caught unauthorized error during save - Auto Master may have completed');
        _saveStarted = false;
        if (mounted) {
          context.goNamed(RouteNamed.pnp);
        }
        return;
      }
      if (!mounted) {
        return;
      }
      final errorDetail = describePnpSaveError(innerError);
      setState(() {
        _saveStarted = false;
        logger.e(
          '[PnP]: Caught a saving error: $errorDetail. Setup step = config',
          error: innerError,
        );
        _setupStep = _PnpSetupStep.config;
      });
      showSimpleSnackBar(context, 'Unexpected error! <$errorDetail>');
      return;
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saveStarted = false;
        logger.e('[PnP]: Unexpected saving error: $error. Setup step = config');
        _setupStep = _PnpSetupStep.config;
      });
      showSimpleSnackBar(context, 'Unexpected error! <$error>');
      return;
    }

    if (!mounted) {
      return;
    }
    // Use showYourNetwork logic to handle both Unconfigured and AutoParent
    // scenarios. Every reconnect path above returns, so the step is still
    // `saving` here: this tail runs only when the transaction went through.
    final showYourNetwork = isUnconfigured || !_isPrePaired;
    logger.d(
        '[PnP]: Save completed. isUnconfigured = $isUnconfigured, isPrePaired = $_isPrePaired, showYourNetwork = $showYourNetwork, SetupStep = $_setupStep');
    if (showYourNetwork) {
      // Unconfigured or AutoParent: continue the add-nodes flow, only after the
      // save transaction succeeds.
      _stepController?.stepContinue();
      setState(() {
        logger.d(
            '[PnP]: showYourNetwork=true, no need to reconnect. Setup step = config');
        _setupStep = _PnpSetupStep.config;
      });
      return;
    }
    // Configured + PrePaired: confirm the save, then go to the WiFi ready page.
    setState(() {
      logger.d('[PnP]: showYourNetwork=false. Setup step = saved');
      _setupStep = _PnpSetupStep.saved;
    });
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) {
      return;
    }
    logger.d('[PnP]: showYourNetwork=false. Setup step = fwCheck');
    _doFwUpdateCheck();
  }

  Future _confirmAddedNodes() async {
    try {
      await ref
          .read(pnpProvider.notifier)
          .acknowledgeAutoConfigurationIfNeeded();
    } on ExceptionSavingChanges catch (error) {
      if (mounted) {
        showSimpleSnackBar(
          context,
          'Unexpected error! <${describePnpSaveError(error.error)}>',
        );
      }
      rethrow;
    }
    logger.i('[PnP]: Added nodes confirmed. Setup step = fwCheck');
    _doFwUpdateCheck();
  }

  void _doFwUpdateCheck() {
    if (_firmwareCheckStarted) {
      logger.i(
          '[PnP]: Firmware update check already started; ignoring duplicate');
      return;
    }
    _firmwareCheckStarted = true;
    if (_setupStep != _PnpSetupStep.fwCheck) {
      setState(() {
        _setupStep = _PnpSetupStep.fwCheck;
      });
      final fwUpdate = ref.read(firmwareUpdateProvider.notifier);
      logger.i('[PnP]: Do FW update check');
      fwUpdate.fetchAvailableFirmwareUpdates().then((_) async {
        setState(() {
          _hasNewFW = fwUpdate.getAvailableUpdateNumber() > 0;
        });
        if (_hasNewFW) {
          logger.i('[PnP]: New Firmware available!');
          await fwUpdate.updateFirmware();
        } else {
          logger.i('[PnP]: No available FW, go WiFi Ready');
          _goWiFiReady();
        }
      });
    }
  }

  void _goWiFiReady() {
    testConnection(success: () {
      setState(() {
        _setupStep = _PnpSetupStep.wifiReady;
      });
    }, failed: () {
      setState(() {
        _needToReconnect = true;
        _setupStep = _PnpSetupStep.wifiReady;
      });
    });
  }

  Future<void> testConnection({
    required FutureOr<void> Function() success,
    FutureOr<void> Function()? failed,
  }) async {
    // Check router connected proper, then run the caller's reconciliation in
    // sequence so the button cannot be submitted again while it is pending.
    // `success` is deliberately outside the try: a failure inside it is the
    // caller's, and must not be reported as "router not found".
    try {
      await ref.read(pnpProvider.notifier).testConnectionReconnected();
    } catch (error) {
      logger.e('[PnP]: Cannot detect the expected router!');
      if (mounted) {
        showSimpleSnackBar(context, loc(context).routerNotFound);
      }
      if (failed != null) {
        await failed();
      }
      return;
    }
    await success();
  }

  void _retryAutoMasterSave() {
    setState(() {
      _showAutoMasterConnectionError = false;
    });
    // isRetry: this view's own recovery button, not duplicate user input.
    _saveChanges(isRetry: true);
  }
}
