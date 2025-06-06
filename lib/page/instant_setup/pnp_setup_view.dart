import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as service;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
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
  bool _needToReconnect = false;
  bool _hasNewFW = false;
  bool _forceLogin = false;
  bool _fetchError = false;
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
    }).then((_) {
      _isUnconfigured = ref.read(pnpProvider).isRouterUnConfigured;
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
    // Need a common way to figure out which step to save changes
    return switch ((_forceLogin, _isUnconfigured)) {
      (false, true) => [
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
      (true, false) => [
          PersonalWiFiStep(),
        ],
      (true, true) => [
          PersonalWiFiStep(saveChanges: _saveChanges),
          YourNetworkStep(saveChanges: _confirmAddedNodes),
        ],
      _ => [
          PersonalWiFiStep(),
          if (isGuestWiFiSupport) GuestWiFiStep(),
          if (isNightModeSupport) NightModeStep(),
        ],
    };
  }

  Widget _buildPnpSetupView(BoxConstraints constraints) {
    final showConfig = _setupStep != _PnpSetupStep.saving &&
        _setupStep != _PnpSetupStep.saved &&
        _setupStep != _PnpSetupStep.needReconnect;
    return switch (_setupStep) {
      _PnpSetupStep.init => _loadingSpinner(),
      _PnpSetupStep.wifiReady => _showWiFi(),
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

  Widget _showWiFi() {
    final wifiData =
        ref.read(pnpProvider).stepStateList[PersonalWiFiStep.id]?.data;
    final wifiSSID = wifiData?['ssid'] as String? ?? '';
    final wifiPassword = wifiData?['password'] as String? ?? '';
    return Center(
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
          AppText.headlineSmall(loc(context).pnpWiFiReady(wifiSSID)),
          const AppGap.medium(),
          if (_needToReconnect)
            AppText.bodyMedium(loc(context).pnpWiFiReadyConnectToNewWiFi),
          const AppGap.medium(),
          AppText.bodyMedium(loc(context).pnpScanQR),
          const AppGap.large5(),
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
                      onTap: () {
                        final ctx = context;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            createWiFiQRCode(WiFiCredential(
                                    ssid: wifiSSID,
                                    password: wifiPassword,
                                    type: SecurityType.wpa))
                                .then((imageBytes) {
                              printWiFiQRCode(
                                  ctx, imageBytes, wifiSSID, wifiPassword);
                            });
                          }
                        });
                      },
                    ),
                    AppTextButton(
                      loc(context).downloadQR,
                      icon: LinksysIcons.download,
                      onTap: () async {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            createWiFiQRCode(WiFiCredential(
                                    ssid: wifiSSID,
                                    password: wifiPassword,
                                    type: SecurityType.wpa))
                                .then((imageBytes) {
                              exportFileFromBytes(
                                  fileName: 'share_wifi_$wifiSSID)}.png',
                                  utf8Bytes: imageBytes);
                            });
                          }
                        });
                      },
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
                onTap: () {
                  service.Clipboard.setData(
                          service.ClipboardData(text: wifiPassword))
                      .then((value) => showSharedCopiedSnackBar());
                },
              ),
            ),
          ),
          const AppGap.large5(),
          AppFilledButton(
            loc(context).done,
            onTap: () {
              // Check router connected propor, then go to dashboard
              testConnection(success: () {
                logger.i(
                    '[PnP]: The customized WiFi is well connected, go to dashboard!');
                context.goNamed(RouteNamed.prepareDashboard);
              });
            },
          )
        ],
      ),
    );
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
                        .getDefaultWiFiNameAndPassphrase()
                        .password;
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
}
