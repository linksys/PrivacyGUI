import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';
import 'package:privacy_gui/page/instant_setup/widgets/wifi_password_widget.dart';
import 'package:privacy_gui/page/instant_setup/widgets/wifi_ssid_widget.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

class PersonalWiFiStep extends PnpStep {
  TextEditingController? _ssidEditController;
  TextEditingController? _passwordEditController;

  PersonalWiFiStep({
    super.saveChanges,
  }) : super(stepId: PnpStepId.personalWifi);

  @override
  Future<void> onInit(WidgetRef ref) async {
    await super.onInit(ref);

    _ssidEditController = TextEditingController();
    _passwordEditController = TextEditingController();

    final wifi = pnp.getDefaultWiFiNameAndPassphrase();
    _ssidEditController?.text = wifi.name;
    _passwordEditController?.text = wifi.password;

    _checkForEnablingNext(ref);
    canGoNext(saveChanges == null);
  }

  @override
  Future<Map<String, dynamic>> onNext(WidgetRef ref) async {
    return {
      'ssid': _ssidEditController?.text,
      'password': _passwordEditController?.text,
    };
  }

  @override
  void onDispose() {
    _passwordEditController?.dispose();
    _ssidEditController?.dispose();
  }

  @override
  Widget content({
    required BuildContext context,
    required WidgetRef ref,
    Widget? child,
  }) =>
      Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WiFiSSIDField(
            controller: _ssidEditController,
            label: loc(context).wifiName,
            hint: loc(context).wifiName,
            onCheckInput: (isValid, input) {
              _checkForEnablingNext(ref);
            },
          ),
          const AppGap.medium(),
          WiFiPasswordField(
            controller: _passwordEditController,
            label: loc(context).wifiPassword,
            hint: loc(context).wifiPassword,
            onCheckInput: (isValid, input) {
              _checkForEnablingNext(ref);
            },
          ),
          const AppGap.large5(),
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

  @override
  String title(BuildContext context) => loc(context).pnpPersonalizeWiFiTitle;

  void _checkForEnablingNext(WidgetRef ref) {
    final ssid = _ssidEditController?.text ?? '';
    final InputValidator wifiSSIDValidator = InputValidator([
      RequiredRule(),
      NoSurroundWhitespaceRule(),
      LengthRule(min: 1, max: 32),
      WiFiSsidRule(),
    ]);
    final isSSIDValid = wifiSSIDValidator.validate(ssid);

    final password = _passwordEditController?.text ?? '';
    final InputValidator wifiPasswordValidator = InputValidator([
      LengthRule(min: 8, max: 64),
      NoSurroundWhitespaceRule(),
      AsciiRule(),
      WiFiPSKRule(),
    ]);
    final isPasswordValid = wifiPasswordValidator.validate(password);

    if (isSSIDValid && isPasswordValid) {
      pnp.setStepStatus(stepId, status: StepViewStatus.data);
    } else {
      pnp.setStepStatus(stepId, status: StepViewStatus.error);
    }
  }

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
              onTap: () {
                context.pop();
              },
            ),
          ],
          content: SizedBox(
            child: Container(
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