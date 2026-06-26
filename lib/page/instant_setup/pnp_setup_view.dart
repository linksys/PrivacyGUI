import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as service;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/models/auto_configuration_settings.dart';
import 'package:privacy_gui/core/jnap/models/auto_master_status.dart';
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
import 'package:privacy_gui/page/instant_setup/widgets/pnp_auto_master_waiting_view.dart';
import 'package:privacy_gui/page/instant_setup/widgets/pnp_stepper.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/qr_code.dart';
import 'package:privacy_gui/util/wifi_credential.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
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
    with PageSnackbarMixin {
  late final List<PnpStep> steps;
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
    super.dispose();
    for (var element in steps) {
      element.onDispose();
    }
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
      logger.i(
          '[PnP]: The customized WiFi is well connected, go to dashboard!');
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
    // Determine if this is the last step before YourNetworkStep
    final isLastBeforeYourNetwork =
        !isGuestWiFiSupport && !isNightModeSupport && !showYourNetwork;
    // Log PnP state for debugging
    final autoConfigData = ref.read(pnpProvider.notifier).getData(JNAPAction.getAutoConfigurationSettings);
    final autoConfigMethod = autoConfigData != null
        ? AutoConfigurationSettings.fromMap(autoConfigData).autoConfigurationMethod?.name
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
      (false, true, _) => [
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
      (false, false, true) => [
          PersonalWiFiStep(
              saveChanges: !isGuestWiFiSupport && !isNightModeSupport
                  ? null
                  : null),
          if (isGuestWiFiSupport)
            GuestWiFiStep(saveChanges: !isNightModeSupport ? null : null),
          if (isNightModeSupport) NightModeStep(saveChanges: null),
          YourNetworkStep(saveChanges: _saveChanges),
        ],
      (true, false, _) => [
          PersonalWiFiStep(),
        ],
      (true, true, _) => [
          PersonalWiFiStep(saveChanges: _saveChanges),
          YourNetworkStep(saveChanges: _confirmAddedNodes),
        ],
      _ => [
          PersonalWiFiStep(saveChanges: isLastBeforeYourNetwork ? _saveChanges : null),
          if (isGuestWiFiSupport) GuestWiFiStep(saveChanges: !isNightModeSupport && !showYourNetwork ? _saveChanges : null),
          if (isNightModeSupport) NightModeStep(saveChanges: !showYourNetwork ? _saveChanges : null),
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
            onLastStep: _isUnconfigured ? null : _saveChanges,
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
                          padding: const EdgeInsets.only(bottom: Spacing.small2),
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
                LinksysIcons.wifi,
                semanticLabel: 'wifi icon',
                color: Theme.of(context).colorScheme.primary,
                size: 48,
              ),
              const AppGap.medium(),
              AppText.headlineSmall(loc(context).pnpReconnectWiFi),
              const AppGap.large5(),
              AppFilledButtonWithLoading(
                loc(context).next,
                onTap: () async {
                  logger.d('[PnP]: Tap Next to check the WiFi reconnection');
                  await testConnection(success: () async {
                    final isUnconfigured =
                        ref.read(pnpProvider).isRouterUnConfigured;
                    logger.i(
                        '[PnP]: The customized WiFi has been reconnected - $isUnconfigured');
                    final password = ref
                        .read(pnpProvider.notifier)
                        .getDefaultWiFiSettings()
                        .primaryRadio
                        ?.password;
                    await ref
                        .read(pnpProvider.notifier)
                        .checkAdminPassword(password)
                        .then((value) => isUnconfigured
                            ? _stepController?.stepContinue()
                            : null);
                    if (isUnconfigured) {
                      setState(() {
                        _setupStep = _PnpSetupStep.config;
                        logger
                            .d('[PnP]: WiFi reconnected. Setup step = config');
                      });
                    } else {
                      logger.d('[PnP]: WiFi reconnected. Setup step = fwCheck');
                      _doFwUpdateCheck();
                    }
                  });
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  Future _saveChanges() async {
    final isUnconfigured = ref.read(pnpProvider).isRouterUnConfigured;

    // Check Auto Master status before save (Second Defense)
    final statusOnEntry = ref.read(pnpProvider).autoMasterStatusOnEntry;
    final AutoMasterStatus? currentStatus;
    try {
      currentStatus =
          await ref.read(pnpProvider.notifier).checkAutoMasterStatus();
    } on ExceptionAutoMasterUnauthorized {
      logger.e('[PnP]: Auto Master check unauthorized, redirect to login');
      if (mounted) {
        context.goNamed(RouteNamed.localLoginPassword);
      }
      return;
    }

    logger.d('[PnP]: Auto Master check before save - '
        'entry status: $statusOnEntry, current: $currentStatus');

    if (currentStatus == AutoMasterStatus.running) {
      // Show waiting view and poll
      setState(() {
        _setupStep = _PnpSetupStep.waitingAutoMaster;
        _showAutoMasterConnectionError = false;
      });

      int consecutiveFailures = 0;
      const maxConsecutiveFailures = 3;

      await for (final pollStatus
          in ref.read(pnpProvider.notifier).pollAutoMasterStatus()) {
        logger.d('[PnP]: Auto Master polling status: $pollStatus');

        if (pollStatus == null) {
          consecutiveFailures++;
          logger.w(
              '[PnP]: Auto Master polling failed, consecutive failures: $consecutiveFailures');

          if (consecutiveFailures >= maxConsecutiveFailures) {
            logger.e(
                '[PnP]: Auto Master polling failed $maxConsecutiveFailures times, showing connection error');
            setState(() {
              _showAutoMasterConnectionError = true;
            });
            return;
          }
        } else {
          consecutiveFailures = 0;

          if (pollStatus == AutoMasterStatus.complete ||
              pollStatus == AutoMasterStatus.idle) {
            // Redirect to login page - password changed
            if (mounted) {
              context.goNamed(RouteNamed.localLoginPassword);
            }
            return;
          }
        }
      }

      // Polling exceeded max retry (timeout)
      logger.w('[PnP]: Auto Master polling timeout, checking router connection');
      try {
        await ref.read(pnpProvider.notifier).testConnectionReconnected();
        logger.i('[PnP]: Router connected after timeout, proceed to save');
        setState(() {
          _setupStep = _PnpSetupStep.config;
        });
        // Continue to save - call _saveChanges again but status should be different now
        return _saveChanges();
      } catch (e) {
        logger.e('[PnP]: Router not connected after timeout');
        setState(() {
          _showAutoMasterConnectionError = true;
        });
        return;
      }
    }

    // Edge case: Was Idle on entry but now Complete
    if (statusOnEntry == AutoMasterStatus.idle &&
        currentStatus == AutoMasterStatus.complete) {
      logger
          .w('[PnP]: Auto Master completed during PnP config - password changed');
      if (mounted) {
        context.goNamed(RouteNamed.localLoginPassword);
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
    await ref.read(pnpProvider.notifier).save().catchError((error) {
      setState(() {
        _needToReconnect = true;
      });
      // if (isUnconfigured) {
      // if in unconfigured scenario, display the reconnect prompt
      _currentStep?.canGoNext(false);
      setState(() {
        logger.e(
            '[PnP]: Caught a connection error and the router is unconfigured. Setup step = needReconnect');
        _setupStep = _PnpSetupStep.needReconnect;
      });
      // }
    }, test: (error) => error is ExceptionNeedToReconnect).catchError((error) {
      setState(() {
        logger.e('[PnP]: Caught a saving error: $error. Setup step = config');
        _setupStep = _PnpSetupStep.config;
      });
      final err = error is ExceptionSavingChanges ? error.error : error;
      showSimpleSnackBar(context, 'Unexceped error! <$err}>');
    }, test: (error) => error is ExceptionSavingChanges).whenComplete(() async {
      logger.d(
          '[PnP]: Save completed. isUnconfigured = $isUnconfigured, SetupStep = $_setupStep');
      if (isUnconfigured) {
        // if is unconfigured scenario and no need to reconnect to the router, continue add nodes flow
        if (_setupStep != _PnpSetupStep.needReconnect) {
          _stepController?.stepContinue();
          setState(() {
            logger.d(
                '[PnP]: The router is unconfigured and no need to reconnect. Setup step = config');
            _setupStep = _PnpSetupStep.config;
          });
        }
      } else {
        if (_setupStep != _PnpSetupStep.needReconnect) {
          // if is configured scenario, go display WiFi page
          setState(() {
            logger.d('[PnP]: The router is configured. Setup step = saved');
            _setupStep = _PnpSetupStep.saved;
          });
          await Future.delayed(const Duration(seconds: 3));
          logger.d('[PnP]: The router is configured. Setup step = fwCheck');
          _doFwUpdateCheck();
        } else {
          setState(() {
            logger.d(
                '[PnP]: The router is configured but need to reconnect. Setup step = saved');
            _setupStep = _PnpSetupStep.saved;
          });
          await Future.delayed(const Duration(seconds: 3));
          setState(() {
            _setupStep = _PnpSetupStep.needReconnect;
          });
        }
      }
    });
  }

  Future _confirmAddedNodes() async {
    logger.i('[PnP]: Added nodes confirmed. Setup step = fwCheck');
    _doFwUpdateCheck();
  }

  void _doFwUpdateCheck() {
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

  Future<void> testConnection(
      {required void Function() success, void Function()? failed}) {
    // Check router connected propor, then go to dashboard
    return ref
        .read(pnpProvider.notifier)
        .testConnectionReconnected()
        .then((value) {
      success.call();
    }).onError((error, stackTrace) {
      logger.e('[PnP]: Cannot detect the expected WiFi connected!');
      showSimpleSnackBar(context, loc(context).pnpReconnectWiFi);
      failed?.call();
    });
  }

  void _retryAutoMasterSave() {
    setState(() {
      _showAutoMasterConnectionError = false;
    });
    _saveChanges();
  }
}
