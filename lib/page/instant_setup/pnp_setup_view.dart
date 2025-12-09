import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as service;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/instant_setup/model/impl/guest_wifi_step.dart';
import 'package:privacy_gui/page/instant_setup/model/impl/night_mode_step.dart';
import 'package:privacy_gui/page/instant_setup/model/impl/personal_wifi_step.dart';
import 'package:privacy_gui/page/instant_setup/model/impl/your_network_step.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/widgets/pnp_stepper.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/export_selector/export_base.dart';
import 'package:privacy_gui/util/qr_code.dart';
import 'package:privacy_gui/util/wifi_credential.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/gap/gap.dart';
import 'package:privacygui_widgets/widgets/progress_bar/spinner.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';
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

    return StyledAppPageView.innerPage(
      scrollable: true,
      padding: EdgeInsets.zero,
      useMainPadding: true,
      child: (context, constraints) => AppCard(
        showBorder: false,
        color: Theme.of(context).colorScheme.background,
        padding: EdgeInsets.symmetric(
            horizontal: ResponsiveLayout.pageHorizontalPadding(context)),
        child: _buildContentView(pnpState, constraints),
      ),
    );
  }

  /// Builds the content view, showing different widgets based on the current PnP status.
  Widget _buildContentView(PnpState pnpState, BoxConstraints constraints) {
    final status = pnpState.status;

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
            vertical: ResponsiveLayout.isMobileLayout(context)
                ? Spacing.small2
                : Spacing.large5),
        child: PnpStepper(
          steps: steps,
          stepperType: StepperType.horizontal,
          onLastStep: pnpState.isRouterUnConfigured
              ? null
              : ref.read(pnpProvider.notifier).savePnpSettings,
          onStepChanged: ((index, step, controller) {
            _stepController = controller;
          }),
        ),
      );
    });
  }

  /// Displays a view for firmware update checking/updating.
  Widget _fwUpdateCheck() => Container(
        color: Theme.of(context).colorScheme.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: AppSpinner(key: Key('pnp_fw_update_spinner'))),
              const AppGap.medium(),
              AppText.titleLarge(loc(context).pnpFwUpdateTitle),
              const AppGap.medium(),
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
      color: Theme.of(context).colorScheme.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Center(child: AppSpinner(key: Key('pnp_loading_spinner'))),
            const AppGap.medium(),
            AppText.headlineSmall(message),
          ],
        ),
      ),
    );
  }

  /// Displays a generic error view with a "Try Again" button.
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
          Icon(
            LinksysIcons.wifi,
            semanticLabel: 'wifi icon',
            color: Theme.of(context).colorScheme.primary,
            size: 48,
          ),
          const AppGap.medium(),
          AppText.headlineSmall(loc(context).pnpWiFiReady(wifiSSID)),
          const AppGap.medium(),
          if (needsReconnect)
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
                      type: SecurityType.wpa,
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
                    AppTextButton(
                      loc(context).downloadQR,
                      icon: LinksysIcons.download,
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
                key: const Key('pnp_reconnect_next_button'),
                loc(context).next,
                onTap: () async {
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
