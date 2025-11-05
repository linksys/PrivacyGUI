import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_step_state.dart';
import 'package:privacy_gui/page/instant_setup/widgets/wifi_password_widget.dart';
import 'package:privacy_gui/page/instant_setup/widgets/wifi_ssid_widget.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/input_field/validator_widget.dart';

/// A PnP (Plug and Play) step for configuring Guest Wi-Fi settings.
///
/// This step allows the user to enable/disable Guest Wi-Fi and set its SSID and password.
class GuestWiFiStep extends PnpStep {
  /// Controller for the Guest Wi-Fi SSID input field.
  TextEditingController? _ssidEditController;

  /// Controller for the Guest Wi-Fi password input field.
  TextEditingController? _passwordEditController;

  GuestWiFiStep({
    super.saveChanges,
  }) : super(stepId: PnpStepId.guestWifi);

  @override
  Future<void> onInit(WidgetRef ref) async {
    await super.onInit(ref);

    _ssidEditController = TextEditingController();
    _passwordEditController = TextEditingController();

    // Get default Guest Wi-Fi name and password.
    final guestWifi = pnp.getDefaultGuestWiFiNameAndPassPhrase();

    // Populate controllers with existing data or defaults.
    _ssidEditController?.text =
        pnp.getStepState(stepId).getData<String>('ssid', guestWifi.name);
    _passwordEditController?.text = pnp
        .getStepState(stepId)
        .getData<String>('password', guestWifi.password);

    // Perform initial validation.
    _check(ref);
  }

  @override
  Future<Map<String, dynamic>> onNext(WidgetRef ref) async {
    // Retrieve the enabled state of Guest Wi-Fi.
    final isEnabled =
        pnp.getStepState(stepId).getData<bool>('isEnabled', false);
    return {
      'isEnabled': isEnabled,
      // Only include SSID and password if Guest Wi-Fi is enabled.
      if (isEnabled) 'ssid': _ssidEditController?.text,
      if (isEnabled) 'password': _passwordEditController?.text,
    };
  }

  @override
  void onDispose() {
    /// Disposes of the text editing controllers to free up resources.
    _passwordEditController?.dispose();
    _ssidEditController?.dispose();
  }

  @override
  Map<String, dynamic> getValidationData() {
    /// Returns a map of data collected in this step that needs to be validated.
    return {
      'isEnabled': pnp.getStepState(stepId).getData<bool>('isEnabled', false),
      'ssid': _ssidEditController?.text ?? '',
      'password': _passwordEditController?.text ?? '',
    };
  }

  @override
  Map<String, List<ValidationRule>> getValidationRules() {
    /// Defines the validation rules for the Guest Wi-Fi SSID and password fields.
    // No validation needed if guest WiFi is disabled.
    if (!pnp.getStepState(stepId).getData<bool>('isEnabled', false)) {
      return {};
    }
    return {
      'ssid': [
        RequiredRule(),
        NoSurroundWhitespaceRule(),
        LengthRule(min: 1, max: 32),
      ],
      'password': [
        RequiredRule(),
        NoSurroundWhitespaceRule(),
        AsciiRule(),
        LengthRule(min: 8, max: 64),
      ],
    };
  }

  @override
  Widget content({
    required BuildContext context,
    required WidgetRef ref,
    Widget? child,
  }) {
    /// Builds the UI content for the Guest Wi-Fi step.
    final stepState =
        ref.watch(pnpProvider.select((s) => s.stepStateList[stepId])) ??
            const PnpStepState(status: StepViewStatus.data, data: {});
    final isEnabled = stepState.getData<bool>('isEnabled', false);
    final errors = stepState.error as Map<String, String?>? ?? {};

    return Semantics(
      explicitChildNodes: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle switch for enabling/disabling Guest Wi-Fi.
          AppSwitch(
            semanticLabel: 'pnp guest wifi',
            value: isEnabled,
            onChanged: (value) {
              pnp.setStepData(stepId, data: {'isEnabled': value});
              _check(ref);
            },
          ),
          const AppGap.large3(),
          AppText.bodyLarge(loc(context).pnpGuestWiFiDesc),
          const AppGap.large3(),
          // Display SSID and password fields only if Guest Wi-Fi is enabled.
          if (isEnabled) ...[
            WiFiSSIDField(
              controller: _ssidEditController,
              label: loc(context).guestWiFiName,
              hint: loc(context).guestWiFiName,
              errorText: _getSSIDLocalizedError(context, errors['ssid']),
              onChanged: (value) {
                pnp.setStepData(stepId, data: {'ssid': value});
                _check(ref);
              },
            ),
            const AppGap.medium(),
            WiFiPasswordField(
              controller: _passwordEditController,
              label: loc(context).guestWiFiPassword,
              hint: loc(context).guestWiFiPassword,
              onChanged: (value) {
                pnp.setStepData(stepId, data: {'password': value});
                _check(ref);
              },
              validations: [
                Validation(
                    description: loc(context).wifiPasswordLimit,
                    validator: LengthRule(min: 8, max: 64).validate),
                Validation(
                    description:
                        loc(context).routerPasswordRuleStartEndWithSpace,
                    validator: NoSurroundWhitespaceRule().validate),
                Validation(
                  description:
                      loc(context).routerPasswordRuleUnsupportSpecialChar,
                  validator: (AsciiRule().validate),
                ),
                if (_passwordEditController?.text.length == 64)
                  Validation(
                    description: loc(context).wifiPasswordRuleHex,
                    validator: WiFiPSKRule().validate,
                  ),
              ],
            ),
            const AppGap.medium(),
          ]
        ],
      ),
    );
  }

  /// Returns a localized error message for the SSID field based on the error code.
  String? _getSSIDLocalizedError(BuildContext context, String? errorCode) {
    if (errorCode == null) return null;
    return loc(context).notBeEmptyAndLessThanThirtyThree;
  }

  @override
  /// Returns the localized title for the Guest Wi-Fi step.
  String title(BuildContext context) => loc(context).guestNetwork;

  /// Triggers validation for the current step.
  void _check(WidgetRef ref) {
    pnp.validateStep(this);
  }
}
