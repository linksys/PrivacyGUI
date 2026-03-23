import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// PnP wizard — main WiFi + guest WiFi configuration (two-step stepper).
class PnpSetupView extends ConsumerStatefulWidget {
  const PnpSetupView({super.key});

  @override
  ConsumerState<PnpSetupView> createState() => _PnpSetupViewState();
}

class _PnpSetupViewState extends ConsumerState<PnpSetupView> {
  late final TextEditingController _ssidController;
  late final TextEditingController _wifiPasswordController;
  late final TextEditingController _guestSsidController;
  late final TextEditingController _guestPasswordController;
  bool _initialized = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _ssidController.dispose();
    _wifiPasswordController.dispose();
    _guestSsidController.dispose();
    _guestPasswordController.dispose();
    super.dispose();
  }

  void _initControllers(WizardConfiguring phase) {
    if (_initialized) return;
    _ssidController = TextEditingController(text: phase.wifiConfig.ssid);
    _wifiPasswordController =
        TextEditingController(text: phase.wifiConfig.password);
    _guestSsidController =
        TextEditingController(text: phase.wifiConfig.guestSsid);
    _guestPasswordController =
        TextEditingController(text: phase.wifiConfig.guestPassword);
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final pnpState = ref.watch(pnpProvider);
    final phase = pnpState.phase;

    return UiKitPageView(
      appBarStyle: UiKitAppBarStyle.back,
      title: loc(context).pnpPersonalizeWiFiTitle,
      scrollable: true,
      onBackTap: () {
        if (phase is WizardConfiguring && _currentStep > 0) {
          setState(() => _currentStep = 0);
        } else {
          context.pop();
        }
      },
      child: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: switch (phase) {
            WizardConfiguring() => _buildStepperForm(context, phase),
            WizardSaving() => _buildSavingOverlay(context),
            WizardSaved() => _buildSavingOverlay(context),
            WizardNeedsReconnect(newSsid: final ssid) =>
              _buildReconnectView(context, ssid),
            WizardTestingReconnect(
              attemptCount: final count,
              maxAttempts: final max
            ) =>
              _buildTestingReconnect(context, count, max),
            WizardCheckingFirmware() => _buildSavingOverlay(context),
            WizardWifiReady(ssid: final ssid, password: final pw) =>
              _buildComplete(context, ssid, pw),
            WizardError(message: final msg) => _buildError(context, msg),
            _ => const Center(child: CircularProgressIndicator()),
          },
        );
      },
    );
  }

  // ── Two-Step Stepper ──────────────────────────────────────

  Widget _buildStepperForm(BuildContext context, WizardConfiguring phase) {
    _initControllers(phase);
    final hasGuestNetwork = phase.wifiConfig.guestSsidInstancePaths.isNotEmpty;

    final steps = [
      StepperStep(
        id: 'wifi',
        label: loc(context).pnpPersonalizeWiFiTitle,
      ),
      if (hasGuestNetwork)
        StepperStep(
          id: 'guest',
          label: loc(context).guestWifi,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasGuestNetwork)
          AppStepper(
            steps: steps,
            currentStep: _currentStep,
            completedSteps: {for (int i = 0; i < _currentStep; i++) i},
            indicatorType: StepIndicatorType.bar,
            stepSize: 4.0,
            interactive: false,
          ),
        if (hasGuestNetwork) AppGap.xl(),

        // Step content
        if (_currentStep == 0)
          _buildMainWifiStep(context, phase)
        else
          _buildGuestWifiStep(context, phase),
      ],
    );
  }

  // ── Step 0: Main WiFi ──

  Widget _buildMainWifiStep(BuildContext context, WizardConfiguring phase) {
    final hasGuestNetwork = phase.wifiConfig.guestSsidInstancePaths.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText.bodyMedium(loc(context).pnpPersonalizeInfo),
        AppGap.xl(),
        AppText.labelMedium(loc(context).wifiName),
        AppGap.xs(),
        AppTextField(
          hintText: loc(context).wifiName,
          controller: _ssidController,
          onChanged: (v) => ref.read(pnpProvider.notifier).updateWifiSsid(v),
        ),
        AppGap.lg(),
        AppText.labelMedium(loc(context).wifiPassword),
        AppGap.xs(),
        AppTextField(
          hintText: loc(context).wifiPassword,
          controller: _wifiPasswordController,
          obscureText: true,
          onChanged: (v) =>
              ref.read(pnpProvider.notifier).updateWifiPassword(v),
        ),
        AppGap.xxxl(),
        Align(
          alignment: Alignment.centerRight,
          child: hasGuestNetwork
              ? AppButton(
                  label: loc(context).next,
                  onTap: () => setState(() => _currentStep = 1),
                )
              : AppButton(
                  label: loc(context).save,
                  onTap: () => ref.read(pnpProvider.notifier).saveChanges(),
                ),
        ),
      ],
    );
  }

  // ── Step 1: Guest WiFi ──

  Widget _buildGuestWifiStep(BuildContext context, WizardConfiguring phase) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AppText.titleMedium(loc(context).guestWifi),
            ),
            Switch(
              value: phase.wifiConfig.guestEnabled,
              onChanged: (v) =>
                  ref.read(pnpProvider.notifier).updateGuestEnabled(v),
            ),
          ],
        ),
        if (phase.wifiConfig.guestEnabled) ...[
          AppGap.lg(),
          AppText.labelMedium(loc(context).wifiName),
          AppGap.xs(),
          AppTextField(
            hintText: loc(context).wifiName,
            controller: _guestSsidController,
            onChanged: (v) => ref.read(pnpProvider.notifier).updateGuestSsid(v),
          ),
          AppGap.lg(),
          AppText.labelMedium(loc(context).wifiPassword),
          AppGap.xs(),
          AppTextField(
            hintText: loc(context).wifiPassword,
            controller: _guestPasswordController,
            obscureText: true,
            onChanged: (v) =>
                ref.read(pnpProvider.notifier).updateGuestPassword(v),
          ),
        ],
        AppGap.xxxl(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppButton.text(
              label: loc(context).back,
              onTap: () => setState(() => _currentStep = 0),
            ),
            AppButton(
              label: loc(context).save,
              onTap: () => ref.read(pnpProvider.notifier).saveChanges(),
            ),
          ],
        ),
      ],
    );
  }

  // ── Saving / Loading ──────────────────────────────────────

  Widget _buildSavingOverlay(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          AppGap.lg(),
          AppText.bodyMedium(loc(context).pnpSavingChangesDesc),
        ],
      ),
    );
  }

  // ── Reconnect ─────────────────────────────────────────────

  Widget _buildReconnectView(BuildContext context, String ssid) {
    return Center(
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi, size: 48),
              AppGap.lg(),
              AppText.titleMedium(loc(context).pnpReconnectWiFi),
              AppGap.md(),
              AppText.bodyMedium(
                loc(context).pnpWiFiReadyConnectToNewWiFi,
              ),
              AppGap.sm(),
              AppText.titleSmall(ssid),
              AppGap.xxxl(),
              AppButton(
                label: loc(context).next,
                onTap: () => ref.read(pnpProvider.notifier).testReconnect(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Testing Reconnect ─────────────────────────────────────

  Widget _buildTestingReconnect(
      BuildContext context, int attempt, int maxAttempts) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          AppGap.lg(),
          AppText.bodyMedium(
            '${loc(context).pnpWaitingModemCheckingInternet} ($attempt/$maxAttempts)',
          ),
        ],
      ),
    );
  }

  // ── Complete ──────────────────────────────────────────────

  Widget _buildComplete(BuildContext context, String ssid, String password) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 64, color: Colors.green),
                AppGap.lg(),
                AppText.headlineSmall(loc(context).pnpWiFiReady(ssid)),
                if (ssid.isNotEmpty) ...[
                  AppGap.xl(),
                  AppText.bodyMedium('${loc(context).wifiName}: $ssid'),
                ],
                AppGap.xxxl(),
                AppButton(
                  label: loc(context).done,
                  onTap: () => context.go(RoutePath.uspDashboard),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          AppGap.lg(),
          AppText.bodyMedium(message),
          AppGap.xl(),
          AppButton.text(
            label: loc(context).tryAgain,
            onTap: () => ref.read(pnpProvider.notifier).startFlow(),
          ),
        ],
      ),
    );
  }
}
