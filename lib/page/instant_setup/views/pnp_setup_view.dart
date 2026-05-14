import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/composed/app_node_list_card.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/qr_code.dart';
import 'package:privacy_gui/util/wifi_credential.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:qr_flutter/qr_flutter.dart';
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

  /// Password validation rules for display
  List<AppPasswordRule> _buildPasswordRules(TextEditingController controller) =>
      [
        AppPasswordRule(
          label: loc(context).wifiPasswordLimit, // "8 - 64 characters"
          validate: (text) => LengthRule(min: 8, max: 64).validate(text),
        ),
        AppPasswordRule(
          label: loc(context).routerPasswordRuleStartEndWithSpace,
          validate: (text) =>
              text.isEmpty || NoSurroundWhitespaceRule().validate(text),
        ),
        AppPasswordRule(
          label: loc(context).routerPasswordRuleUnsupportSpecialChar,
          validate: (text) => text.isEmpty || AsciiRule().validate(text),
        ),
        // Only show hex rule when password is 64 characters (PSK)
        if (controller.text.length == 64)
          AppPasswordRule(
            label: loc(context).wifiPasswordRuleHex,
            validate: (text) => WiFiPSKRule().validate(text),
          ),
      ];

  /// Check if all password rules pass for main WiFi
  bool _allMainPasswordRulesPass() {
    final text = _wifiPasswordController.text;
    if (text.isEmpty) return false;
    return _buildPasswordRules(_wifiPasswordController)
        .every((r) => r.validate(text));
  }

  /// Check if all password rules pass for guest WiFi
  bool _allGuestPasswordRulesPass() {
    final text = _guestPasswordController.text;
    if (text.isEmpty) return false;
    return _buildPasswordRules(_guestPasswordController)
        .every((r) => r.validate(text));
  }

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
      appBarStyle: UiKitAppBarStyle.none,
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
            _ => const Center(child: AppLoader()),
          },
        );
      },
    );
  }

  // ── Stepper ─────────────────────────────────────────────

  Widget _buildStepperForm(BuildContext context, WizardConfiguring phase) {
    _initControllers(phase);
    final hasGuestNetwork = phase.wifiConfig.guestSsidInstancePaths.isNotEmpty;
    final hasMeshNodes = phase.meshNodes.length > 1;
    final totalSteps = 1 + (hasGuestNetwork ? 1 : 0) + (hasMeshNodes ? 1 : 0);

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
      if (hasMeshNodes)
        StepperStep(
          id: 'network',
          label: loc(context).pnpYourNetworkTitle,
        ),
    ];

    // Map step index to content builder
    Widget buildStepContent() {
      if (_currentStep == 0) return _buildMainWifiStep(context, phase);
      int stepIdx = 1;
      if (hasGuestNetwork) {
        if (_currentStep == stepIdx) return _buildGuestWifiStep(context, phase);
        stepIdx++;
      }
      if (hasMeshNodes) {
        if (_currentStep == stepIdx) {
          return _buildYourNetworkStep(context, phase);
        }
      }
      return _buildMainWifiStep(context, phase);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (totalSteps > 1)
          AppStepper(
            steps: steps,
            currentStep: _currentStep,
            completedSteps: {for (int i = 0; i < _currentStep; i++) i},
            indicatorType: StepIndicatorType.bar,
            stepSize: 4.0,
            interactive: false,
          ),
        if (totalSteps > 1) AppGap.xl(),

        // Step content
        buildStepContent(),
      ],
    );
  }

  // ── Step 0: Main WiFi ──

  Widget _buildMainWifiStep(BuildContext context, WizardConfiguring phase) {
    final hasNextStep = phase.wifiConfig.guestSsidInstancePaths.isNotEmpty ||
        phase.meshNodes.length > 1;

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
        AppPasswordInput(
          label: loc(context).wifiPassword,
          hintText: loc(context).wifiPassword,
          controller: _wifiPasswordController,
          rules: _buildPasswordRules(_wifiPasswordController),
          onChanged: (v) {
            ref.read(pnpProvider.notifier).updateWifiPassword(v);
            setState(() {}); // Rebuild to update rule indicators
          },
        ),
        AppGap.xxxl(),
        Align(
          alignment: Alignment.centerRight,
          child: hasNextStep
              ? AppButton(
                  label: loc(context).next,
                  onTap: _allMainPasswordRulesPass()
                      ? () => setState(() => _currentStep = 1)
                      : null,
                )
              : AppButton(
                  label: loc(context).save,
                  onTap: _allMainPasswordRulesPass()
                      ? () => ref.read(pnpProvider.notifier).saveChanges()
                      : null,
                ),
        ),
      ],
    );
  }

  // ── Step 1: Guest WiFi ──

  Widget _buildGuestWifiStep(BuildContext context, WizardConfiguring phase) {
    final hasMeshStep = phase.meshNodes.length > 1;
    final guestPasswordValid =
        !phase.wifiConfig.guestEnabled || _allGuestPasswordRulesPass();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AppText.titleMedium(loc(context).guestWifi),
            ),
            AppSwitch(
              value: phase.wifiConfig.guestEnabled,
              onChanged: (v) {
                ref.read(pnpProvider.notifier).updateGuestEnabled(v);
                setState(() {});
              },
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
          AppPasswordInput(
            label: loc(context).wifiPassword,
            hintText: loc(context).wifiPassword,
            controller: _guestPasswordController,
            rules: _buildPasswordRules(_guestPasswordController),
            onChanged: (v) {
              ref.read(pnpProvider.notifier).updateGuestPassword(v);
              setState(() {}); // Rebuild to update rule indicators
            },
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
            hasMeshStep
                ? AppButton(
                    label: loc(context).next,
                    onTap: guestPasswordValid
                        ? () => setState(() => _currentStep = _currentStep + 1)
                        : null,
                  )
                : AppButton(
                    label: loc(context).save,
                    onTap: guestPasswordValid
                        ? () => ref.read(pnpProvider.notifier).saveChanges()
                        : null,
                  ),
          ],
        ),
      ],
    );
  }

  // ── Step: Your Network (mesh nodes) ──

  Widget _buildYourNetworkStep(BuildContext context, WizardConfiguring phase) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText.titleMedium(loc(context).pnpYourNetworkTitle),
        AppGap.sm(),
        AppText.bodyMedium(loc(context).pnpYourNetworkDesc),
        AppGap.xl(),

        // Node list
        ...phase.meshNodes.asMap().entries.map((entry) {
          final node = entry.value;
          final isMaster = entry.key == 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppNodeListCard(
              leading: DeviceImageHelper.getRouterImage(
                routerIconTestByModel(modelNumber: node.model),
              ),
              title: node.model.isNotEmpty ? node.model : node.deviceId,
              description: isMaster ? 'Gateway' : 'Extender',
              trailing: AppIcon.font(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
          );
        }),

        AppGap.xxxl(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppButton.text(
              label: loc(context).back,
              onTap: () => setState(() => _currentStep = _currentStep - 1),
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
          const AppLoader(),
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
              AppIcon.font(Icons.wifi, size: 48),
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
          const AppLoader(),
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
    final wifiString = WiFiCredential(
      ssid: ssid,
      password: password,
      type: SecurityType.wpa,
    ).generate();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Assets.images.pnpFinishDesktop.svg(width: 120),
                AppGap.lg(),
                AppText.headlineSmall(loc(context).pnpWiFiReady(ssid)),
                AppGap.xl(),

                // QR Code
                QrImageView(
                  data: wifiString,
                  size: 180,
                  backgroundColor: Colors.white,
                ),
                AppGap.xl(),

                // WiFi Name
                _buildCredentialRow(
                  context,
                  label: loc(context).wifiName,
                  value: ssid,
                ),
                AppGap.sm(),

                // WiFi Password
                _buildCredentialRow(
                  context,
                  label: loc(context).wifiPassword,
                  value: password,
                ),
                AppGap.xl(),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppButton.text(
                      label: loc(context).print,
                      icon: AppIcon.font(Icons.print_outlined, size: 18),
                      onTap: () async {
                        final imageBytes = await createWiFiQRCode(
                          WiFiCredential(
                            ssid: ssid,
                            password: password,
                            type: SecurityType.wpa,
                          ),
                        );
                        if (context.mounted) {
                          await printWiFiQRCode(
                              context, imageBytes, ssid, password);
                        }
                      },
                    ),
                    AppGap.lg(),
                    AppButton(
                      label: loc(context).done,
                      onTap: () => context.go(RoutePath.uspDashboard),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCredentialRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText.bodyMedium('$label: '),
        AppText.titleSmall(value),
        AppGap.xs(),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            AppToast.show(
              context,
              type: ToastType.success,
              title: loc(context).sharedCopied,
            );
          },
          child: AppIcon.font(Icons.copy, size: 16),
        ),
      ],
    );
  }

  // ── Error ─────────────────────────────────────────────────

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon.font(Icons.error_outline, size: 48, color: Colors.red),
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
