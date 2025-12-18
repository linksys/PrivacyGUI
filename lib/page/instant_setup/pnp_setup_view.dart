import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as service;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/instant_setup/model/impl/guest_wifi_step.dart';
import 'package:privacy_gui/page/instant_setup/model/impl/night_mode_step.dart';
import 'package:privacy_gui/page/instant_setup/model/impl/personal_wifi_step.dart';
import 'package:privacy_gui/page/instant_setup/model/impl/your_network_step.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/widgets/pnp_stepper.dart';
import 'package:privacy_gui/page/components/composed/app_loadable_widget.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/export_selector/export_base.dart';
import 'package:privacy_gui/util/qr_code.dart';
import 'package:privacy_gui/util/wifi_credential.dart';
import 'package:privacy_gui/page/components/composed/app_list_card.dart';
import 'package:ui_kit_library/ui_kit.dart' hide AppBarStyle;
import 'package:qr_flutter/qr_flutter.dart';

/// A widget that orchestrates the entire PnP (Plug and Play) setup process.
///
/// This view presents a stepper UI that guides the user through various steps
/// of configuring their router, such as personal Wi-Fi, guest Wi-Fi, night mode,
/// and network overview. It handles state changes, error handling, and navigation
/// throughout the PnP flow.
class PnpSetupView extends ConsumerStatefulWidget {
  const PnpSetupView({Key? key}) : super(key: key);

  @override
  ConsumerState<PnpSetupView> createState() => _PnpSetupViewState();
}

class _PnpSetupViewState extends ConsumerState<PnpSetupView>
    with PageSnackbarMixin {
  late List<PnpStep> steps;
  ({void Function() stepCancel, void Function() stepContinue})? _stepController;

  @override
  void initState() {
    super.initState();
    steps = [];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pnpProvider.notifier).initializeWizard();
    });
  }

  @override
  void dispose() {
    for (var element in steps) {
      element.onDispose();
    }
    super.dispose();
  }

  /// Builds the list of PnP steps dynamically based on the router's capabilities
  /// and the current PnP state (e.g., force login, unconfigured).
  List<PnpStep> _buildSteps(PnpState pnpState) {
    final capabilities = pnpState.capabilities;
    final isGuestWiFiSupport = capabilities?.isGuestWiFiSupported ?? false;
    final isNightModeSupport = capabilities?.isNightModeSupported ?? false;

    final pnpNotifier = ref.read(pnpProvider.notifier);

    // Determines the sequence of steps based on router's state.
    return switch ((pnpState.forceLogin, pnpState.isRouterUnConfigured)) {
      // Scenario: Not force login and router unconfigured
      (false, true) => [
          PersonalWiFiStep(
              saveChanges: !isGuestWiFiSupport && !isNightModeSupport
                  ? pnpNotifier.savePnpSettings
                  : null),
          if (isGuestWiFiSupport)
            GuestWiFiStep(
                saveChanges:
                    !isNightModeSupport ? pnpNotifier.savePnpSettings : null),
          if (isNightModeSupport)
            NightModeStep(saveChanges: pnpNotifier.savePnpSettings),
          YourNetworkStep(saveChanges: pnpNotifier.completeFwCheck),
        ],
      // Scenario: Force login and router is configured
      (true, false) => [
          PersonalWiFiStep(),
        ],
      // Scenario: Force login and router is unconfigured
      (true, true) => [
          PersonalWiFiStep(saveChanges: pnpNotifier.savePnpSettings),
          YourNetworkStep(saveChanges: pnpNotifier.completeFwCheck),
        ],
      // Default scenario (catch-all)
      _ => [
          PersonalWiFiStep(),
          if (isGuestWiFiSupport) GuestWiFiStep(),
          if (isNightModeSupport) NightModeStep(),
        ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final pnpState = ref.watch(pnpProvider);

    // Listen for changes in PnP flow status.
    ref.listen(pnpProvider.select((s) => s.status), (previous, next) {
      if (next == PnpFlowStatus.wizardConfiguring &&
          previous == PnpFlowStatus.wizardSaving) {
        // This handles the case for unconfigured routers where saving moves to the next step.
        _stepController?.stepContinue();
      }
      if (next == PnpFlowStatus.wizardSaveFailed) {
        showSimpleSnackBar(context, 'Unexcepted error! <${pnpState.error}>');
      }
    });

    // Listen for firmware update status changes.
    ref.listen(firmwareUpdateProvider, (previous, next) {
      if (pnpState.status != PnpFlowStatus.wizardUpdatingFirmware) return;

      if (previous?.isUpdating == true && next.isUpdating == false) {
        logger.i(
            '[PnP]: Firmware update finished, proceeding to Wi-Fi Ready screen.');
        ref.read(pnpProvider.notifier).completeFwCheck();
      }
    });

    // Build steps only once or when necessary.
    if (steps.isEmpty) {
      steps = _buildSteps(pnpState);
    }

    return UiKitPageView(
      backState: UiKitBackState.none,
      scrollable: false,
      padding: EdgeInsets.zero,
      useMainPadding: true,
      child: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: AppSurface(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal:
                      context.isMobileLayout ? AppSpacing.lg : AppSpacing.xxxl),
              child: _buildContentView(pnpState, constraints),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the content view, showing different widgets based on the current PnP status.
  Widget _buildContentView(PnpState pnpState, BoxConstraints constraints) {
    final status = pnpState.status;
    print('XXXXX: ${constraints.maxHeight}');
    // Determine if the config view (stepper) should be visible and interactive.
    final showConfig = status == PnpFlowStatus.wizardConfiguring ||
        status == PnpFlowStatus.wizardSaveFailed;

    return Stack(
      children: [
        // Layer 1: The Stepper (always in the tree, but visibility is toggled)
        IgnorePointer(
          ignoring: !showConfig,
          child: Opacity(
            opacity: showConfig ? 1.0 : 0.0,
            child: SizedBox(
                height: constraints.maxHeight, child: _configView(pnpState)),
          ),
        ),

        // Layer 2: Overlays (conditionally visible based on PnP flow status)
        if (status == PnpFlowStatus.wizardInitializing ||
            status == PnpFlowStatus.wizardSaving ||
            status == PnpFlowStatus.wizardTestingReconnect)
          _loadingSpinner(pnpState),
        if (status == PnpFlowStatus.wizardCheckingFirmware ||
            status == PnpFlowStatus.wizardUpdatingFirmware)
          _fwUpdateCheck(),
        if (status == PnpFlowStatus.wizardInitFailed) _errorView(),
        if (status == PnpFlowStatus.wizardSaved) _showSaved(),
        if (status == PnpFlowStatus.wizardNeedsReconnect) _showNeedReconnect(),
        if (status == PnpFlowStatus.wizardWifiReady) _showWiFi(pnpState),
      ],
    );
  }

  /// Builds the PnP Stepper widget.
  Widget _configView(PnpState pnpState) {
    return LayoutBuilder(builder: (context, constraints) {
      return Padding(
        padding: EdgeInsets.symmetric(
            vertical: context.isMobileLayout ? AppSpacing.sm : AppSpacing.xxxl),
        child: Center(
          child: PnpStepper(
            steps: steps,
            stepperVariant: StepperVariant.horizontal,
            onLastStep: pnpState.isRouterUnConfigured
                ? null
                : ref.read(pnpProvider.notifier).savePnpSettings,
            onStepChanged: ((index, step, controller) {
              _stepController = controller;
            }),
          ),
        ),
      );
    });
  }

  /// Displays a view for firmware update checking/updating.
  Widget _fwUpdateCheck() => Container(
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: AppLoader(key: Key('pnp_fw_update_spinner'))),
              AppGap.lg(),
              AppText.titleLarge(loc(context).pnpFwUpdateTitle),
              AppGap.lg(),
              AppText.bodyMedium(loc(context).pnpFwUpdateDesc),
            ],
          ),
        ),
      );

  /// Displays a loading spinner with a customizable message.
  Widget _loadingSpinner(PnpState pnpState) {
    // You can map statuses to specific messages if needed
    final message = pnpState.loadingMessage ?? loc(context).processing;
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(child: AppLoader(key: Key('pnp_loading_spinner'))),
            AppGap.lg(),
            AppText.headlineSmall(message),
          ],
        ),
      ),
    );
  }

  /// Displays a generic error view with a "Try Again" button.
  Widget _errorView() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: AppCard(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText.headlineSmall(loc(context).generalError),
              AppGap.xxxl(),
              AppButton(
                label: loc(context).tryAgain,
                variant: SurfaceVariant.highlight,
                onTap: () {
                  context.goNamed(RouteNamed.home);
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  /// Displays a success message after saving settings.
  Widget _showSaved() => Container(
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppText.labelLarge(loc(context).saved),
              AppGap.lg(),
              AppIcon.font(
                AppFontIcons.checkCircle,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      );

  /// Displays the Wi-Fi Ready screen with QR code and password.
  Widget _showWiFi(PnpState pnpState) {
    final wifiData = pnpState.stepStateList[PnpStepId.personalWifi]?.data;
    final wifiSSID = wifiData?['ssid'] as String? ?? '';
    final wifiPassword = wifiData?['password'] as String? ?? '';
    final needsReconnect =
        pnpState.status == PnpFlowStatus.wizardNeedsReconnect;

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon.font(
            AppFontIcons.wifi,
            color: Theme.of(context).colorScheme.primary,
            size: 48,
          ),
          AppGap.lg(),
          AppText.headlineSmall(loc(context).pnpWiFiReady(wifiSSID)),
          AppGap.lg(),
          if (needsReconnect)
            AppText.bodyMedium(loc(context).pnpWiFiReadyConnectToNewWiFi),
          AppGap.lg(),
          AppText.bodyMedium(loc(context).pnpScanQR),
          AppGap.xxxl(),
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
                      type: SecurityType.wpa,
                    ).generate(),
                  ),
                ),
                AppGap.lg(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    AppButton.text(
                      label: loc(context).print,
                      icon: AppIcon.font(AppFontIcons.print),
                      onTap: () {
                        createWiFiQRCode(WiFiCredential(
                                ssid: wifiSSID,
                                password: wifiPassword,
                                type: SecurityType.wpa))
                            .then((imageBytes) {
                          printWiFiQRCode(
                              context, imageBytes, wifiSSID, wifiPassword);
                        });
                      },
                    ),
                    AppButton.text(
                      label: loc(context).downloadQR,
                      icon: AppIcon.font(AppFontIcons.download),
                      onTap: () async {
                        createWiFiQRCode(WiFiCredential(
                                ssid: wifiSSID,
                                password: wifiPassword,
                                type: SecurityType.wpa))
                            .then((imageBytes) {
                          exportFileFromBytes(
                              fileName: 'share_wifi_$wifiSSID)}.png',
                              utf8Bytes: imageBytes);
                        });
                      },
                    ),
                  ],
                ),
              ],
            )),
          ),
          AppGap.sm(),
          Center(
            child: AppListCard.setting(
              title: loc(context).wifiPassword,
              description: wifiPassword,
              trailing: AppIconButton(
                icon: AppIcon.font(AppFontIcons.fileCopy),
                onTap: () {
                  service.Clipboard.setData(
                          service.ClipboardData(text: wifiPassword))
                      .then((value) => showSharedCopiedSnackBar());
                },
              ),
            ),
          ),
          AppGap.xxxl(),
          AppButton(
            label: loc(context).done,
            variant: SurfaceVariant.highlight,
            onTap: () {
              context.goNamed(RouteNamed.prepareDashboard);
            },
          )
        ],
      ),
    );
  }

  /// Displays a view prompting the user to reconnect to the Wi-Fi network.
  Widget _showNeedReconnect() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: AppCard(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon.font(
                AppFontIcons.wifi,
                color: Theme.of(context).colorScheme.primary,
                size: 48,
              ),
              AppGap.lg(),
              AppText.headlineSmall(loc(context).pnpReconnectWiFi),
              AppGap.xxxl(),
              AppLoadableWidget.primaryButton(
                key: const Key('pnp_reconnect_next_button'),
                title: loc(context).next,
                onTap: (controller) async {
                  await ref.read(pnpProvider.notifier).testPnpReconnect();
                  _stepController?.stepContinue();
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
