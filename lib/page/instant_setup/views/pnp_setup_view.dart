import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/composed/app_node_list_card.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_config.dart';
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
  // Unified mode controllers
  late final TextEditingController _ssidController;
  late final TextEditingController _wifiPasswordController;
  late final TextEditingController _guestSsidController;
  late final TextEditingController _guestPasswordController;

  // Split mode controllers: keyed by ssidInstancePath
  final Map<String, TextEditingController> _bandSsidControllers = {};
  final Map<String, TextEditingController> _bandPasswordControllers = {};
  final Map<String, TextEditingController> _guestBandSsidControllers = {};
  final Map<String, TextEditingController> _guestBandPasswordControllers = {};

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

  /// Check if all password rules pass for main WiFi (unified mode)
  bool _allMainPasswordRulesPass() {
    final text = _wifiPasswordController.text;
    if (text.isEmpty) return false;
    return _buildPasswordRules(_wifiPasswordController)
        .every((r) => r.validate(text));
  }

  /// Check if all password rules pass for main WiFi (split mode)
  bool _allMainBandPasswordRulesPass() {
    for (final controller in _bandPasswordControllers.values) {
      final text = controller.text;
      if (text.isEmpty) return false;
      if (!_buildPasswordRules(controller).every((r) => r.validate(text))) {
        return false;
      }
    }
    return true;
  }

  /// Check if all password rules pass for guest WiFi (unified mode)
  bool _allGuestPasswordRulesPass() {
    final text = _guestPasswordController.text;
    if (text.isEmpty) return false;
    return _buildPasswordRules(_guestPasswordController)
        .every((r) => r.validate(text));
  }

  /// Check if all password rules pass for guest WiFi (split mode)
  bool _allGuestBandPasswordRulesPass() {
    for (final controller in _guestBandPasswordControllers.values) {
      final text = controller.text;
      if (text.isEmpty) return false;
      if (!_buildPasswordRules(controller).every((r) => r.validate(text))) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _wifiPasswordController.dispose();
    _guestSsidController.dispose();
    _guestPasswordController.dispose();
    for (final c in _bandSsidControllers.values) {
      c.dispose();
    }
    for (final c in _bandPasswordControllers.values) {
      c.dispose();
    }
    for (final c in _guestBandSsidControllers.values) {
      c.dispose();
    }
    for (final c in _guestBandPasswordControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initControllers(WizardConfiguring phase) {
    if (_initialized) return;

    final config = phase.wifiConfig;

    // Unified mode controllers
    _ssidController = TextEditingController(text: config.ssid);
    _wifiPasswordController = TextEditingController(text: config.password);
    _guestSsidController = TextEditingController(text: config.guestSsid);
    _guestPasswordController =
        TextEditingController(text: config.guestPassword);

    // Split mode controllers for main WiFi
    for (final band in config.mainBands) {
      _bandSsidControllers[band.ssidInstancePath] =
          TextEditingController(text: band.ssid);
      _bandPasswordControllers[band.ssidInstancePath] =
          TextEditingController(text: band.password);
    }

    // Split mode controllers for guest WiFi
    for (final band in config.guestBands) {
      _guestBandSsidControllers[band.ssidInstancePath] =
          TextEditingController(text: band.ssid);
      _guestBandPasswordControllers[band.ssidInstancePath] =
          TextEditingController(text: band.password);
    }

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
            WizardWifiReady() => _buildComplete(context, phase),
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
        if (totalSteps > 1) ...[
          AppStepper(
            steps: steps,
            currentStep: _currentStep,
            completedSteps: {for (int i = 0; i < _currentStep; i++) i},
            indicatorType: StepIndicatorType.bar,
            stepSize: 4.0,
            interactive: false,
          ),
          AppGap.xl(),
        ],

        // Step content wrapped in AppCard
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: buildStepContent(),
          ),
        ),
      ],
    );
  }

  // ── Step 0: Main WiFi ──

  Widget _buildMainWifiStep(BuildContext context, WizardConfiguring phase) {
    final config = phase.wifiConfig;
    final isSplitMode = config.isSplitMode;
    final hasNextStep =
        config.guestSsidInstancePaths.isNotEmpty || phase.meshNodes.length > 1;

    // Validation for button enable state
    final isValid = isSplitMode
        ? _allMainBandPasswordRulesPass()
        : _allMainPasswordRulesPass();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText.titleMedium(loc(context).pnpPersonalizeWiFiTitle),
        AppGap.sm(),
        AppText.bodyMedium(loc(context).pnpPersonalizeInfo),
        AppGap.xl(),
        if (isSplitMode)
          // Split mode: per-band WiFi settings
          ..._buildSplitModeMainWifi(context, config)
        else
          // Unified mode: single WiFi settings block
          _buildUnifiedModeMainWifi(context),
        AppGap.xxxl(),
        Align(
          alignment: Alignment.centerRight,
          child: hasNextStep
              ? AppButton(
                  label: loc(context).next,
                  onTap:
                      isValid ? () => setState(() => _currentStep = 1) : null,
                )
              : AppButton(
                  label: loc(context).save,
                  onTap: isValid
                      ? () => ref.read(pnpProvider.notifier).saveChanges()
                      : null,
                ),
        ),
      ],
    );
  }

  Widget _buildUnifiedModeMainWifi(BuildContext context) {
    return LayoutBlock(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
        ],
      ),
    );
  }

  List<Widget> _buildSplitModeMainWifi(
      BuildContext context, PnpWifiConfig config) {
    return config.mainBands.asMap().entries.map((entry) {
      final index = entry.key;
      final band = entry.value;
      final ssidController = _bandSsidControllers[band.ssidInstancePath]!;
      final passwordController =
          _bandPasswordControllers[band.ssidInstancePath]!;

      return Padding(
        padding: EdgeInsets.only(
            bottom: index < config.mainBands.length - 1 ? AppSpacing.md : 0),
        child: LayoutBlock(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText.labelLarge(band.bandName),
              AppGap.md(),
              AppText.labelMedium(loc(context).wifiName),
              AppGap.xs(),
              AppTextField(
                hintText: loc(context).wifiName,
                controller: ssidController,
                onChanged: (v) => ref
                    .read(pnpProvider.notifier)
                    .updateMainBandSsid(band.ssidInstancePath, v),
              ),
              AppGap.lg(),
              AppPasswordInput(
                label: loc(context).wifiPassword,
                hintText: loc(context).wifiPassword,
                controller: passwordController,
                rules: _buildPasswordRules(passwordController),
                onChanged: (v) {
                  ref
                      .read(pnpProvider.notifier)
                      .updateMainBandPassword(band.ssidInstancePath, v);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildUnifiedModeGuestWifi(BuildContext context) {
    return LayoutBlock(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSplitModeGuestWifi(
      BuildContext context, PnpWifiConfig config) {
    return config.guestBands.asMap().entries.map((entry) {
      final index = entry.key;
      final band = entry.value;
      final ssidController = _guestBandSsidControllers[band.ssidInstancePath]!;
      final passwordController =
          _guestBandPasswordControllers[band.ssidInstancePath]!;

      return Padding(
        padding: EdgeInsets.only(
            bottom: index < config.guestBands.length - 1 ? AppSpacing.md : 0),
        child: LayoutBlock(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText.labelLarge(band.bandName),
              AppGap.md(),
              AppText.labelMedium(loc(context).wifiName),
              AppGap.xs(),
              AppTextField(
                hintText: loc(context).wifiName,
                controller: ssidController,
                onChanged: (v) => ref
                    .read(pnpProvider.notifier)
                    .updateGuestBandSsid(band.ssidInstancePath, v),
              ),
              AppGap.lg(),
              AppPasswordInput(
                label: loc(context).wifiPassword,
                hintText: loc(context).wifiPassword,
                controller: passwordController,
                rules: _buildPasswordRules(passwordController),
                onChanged: (v) {
                  ref
                      .read(pnpProvider.notifier)
                      .updateGuestBandPassword(band.ssidInstancePath, v);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  // ── Step 1: Guest WiFi ──

  Widget _buildGuestWifiStep(BuildContext context, WizardConfiguring phase) {
    final config = phase.wifiConfig;
    final isGuestSplitMode = config.isGuestSplitMode;
    final hasMeshStep = phase.meshNodes.length > 1;

    // Validation for button enable state
    final guestPasswordValid = !config.guestEnabled ||
        (isGuestSplitMode
            ? _allGuestBandPasswordRulesPass()
            : _allGuestPasswordRulesPass());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText.titleMedium(loc(context).guestWifi),
        AppGap.xl(),

        // Guest WiFi toggle block
        LayoutBlock(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.labelLarge(loc(context).guestNetwork),
                    AppGap.xxs(),
                    AppText.bodySmall(
                      loc(context).pnpGuestWiFiDesc,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              AppGap.md(),
              AppSwitch(
                value: config.guestEnabled,
                onChanged: (v) {
                  ref.read(pnpProvider.notifier).updateGuestEnabled(v);
                  setState(() {});
                },
              ),
            ],
          ),
        ),

        if (config.guestEnabled) ...[
          AppGap.md(),
          if (isGuestSplitMode)
            // Split mode: per-band guest WiFi settings
            ..._buildSplitModeGuestWifi(context, config)
          else
            // Unified mode: single guest WiFi settings block
            _buildUnifiedModeGuestWifi(context),
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

        // Node list block
        LayoutBlock(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: phase.meshNodes.asMap().entries.map((entry) {
              final node = entry.value;
              final isMaster = entry.key == 0;
              final isLast = entry.key == phase.meshNodes.length - 1;
              return Column(
                children: [
                  AppNodeListCard(
                    leading: DeviceImageHelper.getRouterImage(
                      routerIconTestByModel(modelNumber: node.model),
                    ),
                    title: node.model.isNotEmpty ? node.model : node.deviceId,
                    description: isMaster ? 'Master' : 'Slave',
                    trailing: AppIcon.font(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  if (!isLast) const Divider(height: AppSpacing.md),
                ],
              );
            }).toList(),
          ),
        ),

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
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLoader(),
              AppGap.lg(),
              AppText.bodyMedium(
                loc(context).pnpSavingChangesDesc,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLoader(),
              AppGap.lg(),
              AppText.bodyMedium(
                '${loc(context).checkingForInternet} ($attempt/$maxAttempts)',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Complete ──────────────────────────────────────────────

  Widget _buildComplete(BuildContext context, WizardWifiReady phase) {
    final isSplitMode = phase.isSplitMode;

    if (isSplitMode && phase.wifiConfig != null) {
      return _buildCompleteSplitMode(context, phase.wifiConfig!);
    }
    return _buildCompleteUnifiedMode(context, phase.ssid, phase.password);
  }

  Widget _buildCompleteUnifiedMode(
      BuildContext context, String ssid, String password) {
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

  Widget _buildCompleteSplitMode(BuildContext context, PnpWifiConfig config) {
    // Use first band for title display
    final firstBand = config.mainBands.first;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Assets.images.pnpFinishDesktop.svg(width: 120),
                AppGap.lg(),
                AppText.headlineSmall(
                    loc(context).pnpWiFiReady(firstBand.ssid)),
                AppGap.xl(),

                // Per-band credentials
                ...config.mainBands.map((band) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: LayoutBlock(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText.labelLarge(band.bandName),
                            AppGap.md(),
                            _buildCredentialRow(
                              context,
                              label: loc(context).wifiName,
                              value: band.ssid,
                            ),
                            AppGap.xs(),
                            _buildCredentialRow(
                              context,
                              label: loc(context).wifiPassword,
                              value: band.password,
                            ),
                          ],
                        ),
                      ),
                    )),

                AppGap.md(),

                // Actions
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
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon.font(Icons.error_outline, size: 48, color: Colors.red),
              AppGap.lg(),
              AppText.bodyMedium(
                message,
                textAlign: TextAlign.center,
              ),
              AppGap.xl(),
              AppButton.text(
                label: loc(context).tryAgain,
                onTap: () =>
                    ref.read(pnpProvider.notifier).startPostLoginFlow(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
