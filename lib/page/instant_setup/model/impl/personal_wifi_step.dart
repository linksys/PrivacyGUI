import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_step_state.dart';
import 'package:privacy_gui/page/instant_setup/widgets/wifi_password_widget.dart';
import 'package:privacy_gui/page/instant_setup/widgets/wifi_ssid_widget.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/input_field/validator_widget.dart';

/// A PnP (Plug and Play) step for configuring personal Wi-Fi settings.
///
/// This step allows the user to set the SSID and password for their main Wi-Fi network.
class PersonalWiFiStep extends PnpStep {
  /// Controller for the Wi-Fi SSID input field.
  final TextEditingController _ssidEditController = TextEditingController();

  /// Controller for the Wi-Fi password input field.
  final TextEditingController _passwordEditController = TextEditingController();

  PersonalWiFiStep({
    super.saveChanges,
  }) : super(stepId: PnpStepId.personalWifi);

  @override
  Future<void> onInit(WidgetRef ref) async {
    await super.onInit(ref);

    // Get default Wi-Fi name and password.
    final wifi = pnp.getDefaultWiFiNameAndPassphrase();

    // Populate controllers with existing data or defaults.
    _ssidEditController.text =
        pnp.getStepState(stepId).getData<String>('ssid', wifi.name);
    _passwordEditController.text =
        pnp.getStepState(stepId).getData<String>('password', wifi.password);

    // Perform initial validation to enable/disable the "Next" button.
    _checkForEnablingNext(ref);
  }

  @override
  Future<Map<String, dynamic>> onNext(WidgetRef ref) async {
    return {
      'ssid': _ssidEditController.text,
      'password': _passwordEditController.text,
    };
  }

  @override
  void onDispose() {
    _passwordEditController.dispose();
    _ssidEditController.dispose();
  }

  @override
  Map<String, dynamic> getValidationData() {
    return {
      'ssid': _ssidEditController.text,
      'password': _passwordEditController.text,
    };
  }

  @override
  Map<String, List<ValidationRule>> getValidationRules() {
    return {
      'ssid': [
        RequiredRule(),
        NoSurroundWhitespaceRule(),
        LengthRule(min: 1, max: 32),
        WiFiSsidRule(),
      ],
      'password': [
        LengthRule(min: 8, max: 64),
        NoSurroundWhitespaceRule(),
        AsciiRule(),
        WiFiPSKRule(),
      ],
    };
  }

  @override
  Widget content({
    required BuildContext context,
    required WidgetRef ref,
    Widget? child,
  }) {
    final stepState =
        ref.watch(pnpProvider.select((s) => s.stepStateList[stepId])) ??
            const PnpStepState(status: StepViewStatus.data, data: {});
    final errors = stepState.error as Map<String, String?>? ?? {};
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Wi-Fi SSID input field.
        WiFiSSIDField(
          controller: _ssidEditController,
          label: loc(context).wifiName,
          hint: loc(context).wifiName,
          errorText: _getSSIDLocalizedError(context, errors['ssid']),
          onChanged: (value) {
            _checkForEnablingNext(ref);
          },
        ),
        const AppGap.medium(),
        // Wi-Fi Password input field with validations.
        WiFiPasswordField(
          controller: _passwordEditController,
          label: loc(context).wifiPassword,
          hint: loc(context).wifiPassword,
          onChanged: (value) {
            _checkForEnablingNext(ref);
          },
          validations: [
            Validation(
                description: loc(context).wifiPasswordLimit,
                validator: LengthRule(min: 8, max: 64).validate),
            Validation(
                description: loc(context).routerPasswordRuleStartEndWithSpace,
                validator: NoSurroundWhitespaceRule().validate),
            Validation(
              description: loc(context).routerPasswordRuleUnsupportSpecialChar,
              validator: (AsciiRule().validate),
            ),
            if (_passwordEditController.text.length == 64)
              Validation(
                description: loc(context).wifiPasswordRuleHex,
                validator: WiFiPSKRule().validate,
              ),
          ],
        ),
        const AppGap.large5(),
        // Information section about personalizing Wi-Fi.
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: AppText.bodySmall(
                loc(context).pnpPersonalizeInfo,
                maxLines: 10,
              ),
            ),
            AppIconButton.noPadding(
              icon: LinksysIcons.infoCircle,
              semanticLabel: 'info',
              color: Theme.of(context).colorScheme.primary,
              onTap: () {
                _showDefaultsInfoModal(context);
              },
            )
          ],
        ),
        const AppGap.large5(),
      ],
    );
  }

  /// Returns a localized error message for the SSID field based on the error code.
  String? _getSSIDLocalizedError(BuildContext context, String? errorCode) {
    if (errorCode == null) return null;
    return loc(context).notBeEmptyAndLessThanThirtyThree;
  }

  @override
  String title(BuildContext context) => loc(context).pnpPersonalizeWiFiTitle;

  /// Triggers validation for the current step to enable/disable the "Next" button.
  void _checkForEnablingNext(WidgetRef ref) {
    pnp.validateStep(this);
  }

  /// Shows a modal dialog with information about Wi-Fi defaults.
  _showDefaultsInfoModal(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: SizedBox(
              width: 400.0,
              child: AppText.titleLarge(
                  loc(context).modalPnpWiFiDefaultsInfoTitle)),
          actions: [
            AppTextButton(
              loc(context).close,
              key: const Key('pnp_wifi_info_close_button'),
              onTap: () {
                context.pop();
              },
            ),
          ],
          content: SizedBox(
            child: SizedBox(
              width: 400.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyMedium(
                      loc(context).modalPnpWiFiDefaultsInfoDesc1),
                  const AppGap.medium(),
                  AppText.bodyMedium(
                      loc(context).modalPnpWiFiDefaultsInfoDesc2),
                  const AppGap.medium(),
                  AppText.bodyMedium(
                      loc(context).modalPnpWiFiDefaultsInfoDesc3),
                  const AppGap.medium(),
                  AppText.bodyMedium(
                      loc(context).modalPnpWiFiDefaultsInfoDesc4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
