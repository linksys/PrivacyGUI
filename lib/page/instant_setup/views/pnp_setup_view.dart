import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/composed/app_node_list_card.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_update_notifier.dart';
import 'package:privacy_gui/page/firmware_update/views/components/firmware_install_phase_card.dart';
import 'package:privacy_gui/page/firmware_update/views/components/firmware_update_warning_note.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_config.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/page/instant_setup/helpers/pnp_wifi_ready_store.dart';
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
  // Unified mode controllers.
  //
  // Created with the field, not in _initControllers: that runs only on the
  // WizardConfiguring branch, while dispose() below disposes all four
  // unconditionally. Every other phase renders the loader and never calls it, so
  // `late final` fields meant leaving the wizard early — back button, a
  // WizardError, a save that navigated away — threw LateInitializationError
  // during teardown. _initControllers assigns .text instead.
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _wifiPasswordController = TextEditingController();
  final TextEditingController _guestSsidController = TextEditingController();
  final TextEditingController _guestPasswordController =
      TextEditingController();

  // Split mode controllers: keyed by ssidInstancePath
  final Map<String, TextEditingController> _bandSsidControllers = {};
  final Map<String, TextEditingController> _bandPasswordControllers = {};
  final Map<String, TextEditingController> _guestBandSsidControllers = {};
  final Map<String, TextEditingController> _guestBandPasswordControllers = {};

  bool _initialized = false;
  int _currentStep = 0;

  /// The credentials store, captured rather than read in [dispose].
  ///
  /// Nothing in `lib/` uses `ref` inside a `dispose()`, and this is not the place to
  /// start: the element is unmounting by then. The store is a plain object off a
  /// `Provider` that is not `autoDispose`, so the reference taken once here is the
  /// same instance for this widget's whole life.
  late final PnpWifiReadyStore _wifiReadyStore;

  @override
  void initState() {
    super.initState();
    _wifiReadyStore = ref.read(pnpWifiReadyStoreProvider);
  }

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
    // REQ-B4's other half. The credentials are persisted to survive one reboot, and
    // the wizard unmounting is the end of every exit that has no handler: a pop off
    // the completion screen, a redirect, a save that ended in `WizardError`. `_onDone`
    // clears too, and a delete of a key that is not there costs nothing — what this
    // adds is the exits nobody presses a button for. A page *reload* does not run
    // `dispose`, which is the one case the stored copy exists for, so this does not
    // close the door on a restore.
    unawaited(_wifiReadyStore.clear());
    super.dispose();
  }

  void _initControllers(WizardConfiguring phase) {
    if (_initialized) return;

    final config = phase.wifiConfig;

    // Unified mode controllers — the objects already exist (see the fields), so
    // this seeds their text rather than replacing them.
    _ssidController.text = config.ssid;
    _wifiPasswordController.text = config.password;
    _guestSsidController.text = config.guestSsid;
    _guestPasswordController.text = config.guestPassword;

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
      // Unreachable, and not this work's to remove: `_buildAppBarConfig()` returns
      // null for `UiKitAppBarStyle.none` (line above) before it reaches the only
      // line that consumes `onBackTap`, so nothing in this closure runs. REQ-B2's
      // lock is therefore the route's `onExit` in `route_pnp.dart` plus a firmware
      // phase that renders no button — a phase check added here would have looked
      // like a second guard and been dead code.
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
            WizardUpdatingFirmware() => _buildFirmwareUpdate(context, phase),
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
                child: AppText.labelLarge(loc(context).guestNetwork),
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

  // ── Firmware Update ───────────────────────────────────────

  /// The first-connection firmware update: the version, the progress, and no way
  /// out (REQ-B2).
  ///
  /// **W5's card, not a copy of it.** `FirmwareInstallPhaseCard` already renders the
  /// six install phases — including the two-pass `fwup_state` progress that mode 2
  /// produces — off `firmwareUpdateNotifierProvider`, which is the same notifier the
  /// PnP stage drives. Anything drawn here instead would be a second phase machine
  /// reading the same fields, and #1497 already recorded what that costs.
  ///
  /// **No Skip, and nothing else to press.** The card's only control is the retry on
  /// its failure card, and a failure does not reach this screen: the notifier catches
  /// it and finishes setup. So this phase has zero affordances by construction rather
  /// than by hiding buttons — first connection's only two ways past a firmware update
  /// are "there is none" and "there is no internet", and both are decided before the
  /// phase is published. That is half of REQ-B2's lock and the load-bearing half:
  /// this page has no app bar, so the other half is the route's `onExit` guard rather
  /// than anything in this file.
  Widget _buildFirmwareUpdate(
      BuildContext context, WizardUpdatingFirmware phase) {
    final firmwareState = ref.watch(firmwareUpdateNotifierProvider);

    return Semantics(
      // One anchor per page, the same shape the two firmware pages emit and for the
      // same reason (the E2E phase-sequence walk keys on the phase name rather than
      // on translated copy). Prefixed, because this is a different page: the walk
      // must be able to tell an update during setup from one on the admin page.
      identifier: 'pnp-firmware-phase-${firmwareState.phase.name}',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText.headlineSmall(
                loc(context).updatingFirmware,
                textAlign: TextAlign.center,
              ),
              // Omitted rather than blank when the router published `Available=true`
              // with no `Version`, which it does on some builds.
              if (phase.version.isNotEmpty) ...[
                AppGap.sm(),
                AppText.bodyMedium(
                  loc(context).availableVersionLabel(phase.version),
                  textAlign: TextAlign.center,
                ),
              ],
              AppGap.xl(),
              FirmwareInstallPhaseCard(state: firmwareState),
              AppGap.lg(),
              // The bound this phase otherwise does not have: it can sit on
              // `rebooting` for up to `pnpFirmwareRebootDeadlineProvider` (six
              // minutes) with no Skip and no way back, and a spinner with no stated
              // duration is what makes a user power-cycle a router mid-flash. The
              // existing note is reused rather than a new string written — it
              // already says both halves ("approximately 5–8 minutes", "do not power
              // off"), in 26 locales, and it is shared for exactly this reason.
              const FirmwareUpdateWarningNote(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Complete ──────────────────────────────────────────────

  Widget _buildComplete(BuildContext context, WizardWifiReady phase) {
    if (phase.isSplitMode) {
      return _buildCompleteSplitMode(context, phase);
    }
    return _buildCompleteUnifiedMode(context, phase.ssid, phase.password);
  }

  /// Leaves the wizard for the dashboard, and forgets the credentials on the way.
  ///
  /// They are persisted so that a firmware reboot cannot lose this screen (REQ-B4);
  /// once the screen has been dismissed there is nothing left to restore, and a
  /// passphrase in the keystore with no reader is just a passphrase in the keystore.
  ///
  /// Awaited, so that the delete has happened by the time the screen it belonged to
  /// is gone rather than at some point after. The failure is still swallowed —
  /// `PnpWifiReadyStore` swallows all three verbs by design — so what the `await`
  /// buys is ordering and a test that can observe it without pumping timers.
  Future<void> _onDone(BuildContext context) async {
    await ref.read(pnpProvider.notifier).completeSetup();
    if (!context.mounted) return;
    context.go(RoutePath.uspDashboard);
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
                      onTap: () => _onDone(context),
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

  Widget _buildCompleteSplitMode(BuildContext context, WizardWifiReady phase) {
    final bands = phase.bands;
    // Unreachable: `WizardWifiReady.isSplitMode` is `bands.length > 1`, so an empty
    // list never gets here. Kept because the old signature took the whole config and
    // this guard was load-bearing then — and because falling back is what the caller
    // would want if the invariant ever moved. It takes the **phase** rather than the
    // band list so that the fallback has the real credentials to fall back to: a
    // placeholder chosen to satisfy a signature would be drawn on the one screen
    // where these two strings exist nowhere else.
    if (bands.isEmpty) {
      logger.w('[PnP] split mode with no bands — falling back to unified mode');
      return _buildCompleteUnifiedMode(context, phase.ssid, phase.password);
    }
    // Use first band for title display
    final firstBand = bands.first;

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
                ...bands.map((band) => Padding(
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
                  onTap: () => _onDone(context),
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
