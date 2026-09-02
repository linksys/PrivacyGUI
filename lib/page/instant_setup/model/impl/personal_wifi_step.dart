import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_wifi_settings.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';
import 'package:privacy_gui/page/instant_setup/widgets/wifi_password_widget.dart';
import 'package:privacy_gui/page/instant_setup/widgets/wifi_ssid_widget.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

class PersonalWiFiStep extends PnpStep {
  static int id = 0;

  // Unified mode controllers
  TextEditingController? _ssidEditController;
  TextEditingController? _passwordEditController;

  // Split mode controllers
  Map<String, TextEditingController>? _perBandSsidControllers;
  Map<String, TextEditingController>? _perBandPasswordControllers;

  // WiFi settings
  PnpWiFiSettings? _wifiSettings;

  PersonalWiFiStep({
    super.saveChanges,
  }) : super(index: id);

  @override
  Future<void> onInit(WidgetRef ref) async {
    await super.onInit(ref);

    _wifiSettings = pnp.getDefaultWiFiSettings();

    if (_wifiSettings!.isSplitMode) {
      // Initialize per-band controllers
      _perBandSsidControllers = {};
      _perBandPasswordControllers = {};
      for (final radio in _wifiSettings!.radios) {
        _perBandSsidControllers![radio.band] =
            TextEditingController(text: radio.ssid);
        _perBandPasswordControllers![radio.band] =
            TextEditingController(text: radio.password);
      }
    } else {
      // Unified mode
      _ssidEditController = TextEditingController();
      _passwordEditController = TextEditingController();
      final primaryRadio = _wifiSettings!.primaryRadio;
      _ssidEditController?.text = primaryRadio?.ssid ?? '';
      _passwordEditController?.text = primaryRadio?.password ?? '';
    }

    _checkForEnablingNext(ref);
    canGoNext(saveChanges == null);
  }

  @override
  Future<Map<String, dynamic>> onNext(WidgetRef ref) async {
    if (_wifiSettings?.isSplitMode == true) {
      // Return per-band settings
      final perBandSettings = <String, Map<String, String>>{};
      for (final radio in _wifiSettings!.radios) {
        perBandSettings[radio.band] = {
          'ssid': _perBandSsidControllers![radio.band]!.text,
          'password': _perBandPasswordControllers![radio.band]!.text,
        };
      }
      // Include primary radio values for backward compatibility
      final primaryBand = _wifiSettings!.primaryRadio?.band;
      return {
        'isSplitMode': true,
        'perBandSettings': perBandSettings,
        'ssid': primaryBand != null
            ? _perBandSsidControllers![primaryBand]?.text
            : null,
        'password': primaryBand != null
            ? _perBandPasswordControllers![primaryBand]?.text
            : null,
      };
    } else {
      // Unified mode
      return {
        'ssid': _ssidEditController?.text,
        'password': _passwordEditController?.text,
      };
    }
  }

  @override
  void onDispose() {
    _passwordEditController?.dispose();
    _ssidEditController?.dispose();
    _perBandSsidControllers?.values.forEach((c) => c.dispose());
    _perBandPasswordControllers?.values.forEach((c) => c.dispose());
  }

  @override
  Widget content({
    required BuildContext context,
    required WidgetRef ref,
    Widget? child,
  }) {
    if (_wifiSettings == null) {
      return loadingView();
    }

    if (_wifiSettings!.isSplitMode) {
      return _splitModeContent(context, ref);
    } else {
      return _unifiedModeContent(context, ref);
    }
  }

  Widget _unifiedModeContent(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOptionalNotice(context),
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
        _buildInfoSection(context),
        const AppGap.large5(),
      ],
    );
  }

  Widget _splitModeContent(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOptionalNotice(context),
        for (final radio in _wifiSettings!.radios) ...[
          AppCard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleMedium(_getBandLabel(radio.band)),
                const AppGap.medium(),
                WiFiSSIDField(
                  controller: _perBandSsidControllers![radio.band],
                  label: loc(context).wifiName,
                  hint: loc(context).wifiName,
                  onCheckInput: (isValid, input) {
                    _checkForEnablingNext(ref);
                  },
                ),
                const AppGap.medium(),
                WiFiPasswordField(
                  controller: _perBandPasswordControllers![radio.band],
                  label: loc(context).wifiPassword,
                  hint: loc(context).wifiPassword,
                  onCheckInput: (isValid, input) {
                    _checkForEnablingNext(ref);
                  },
                ),
              ],
            ),
          ),
          const AppGap.medium(),
        ],
        const AppGap.small2(),
        _buildInfoSection(context),
        const AppGap.large5(),
      ],
    );
  }

  // Personalizing is optional: the shipped WiFi credentials are already
  // secure, so state that up front - before the fields - so users who already
  // have devices on the printed default network know they can just continue.
  Widget _buildOptionalNotice(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.large2),
      child: AppText.bodyMedium(
        loc(context).pnpPersonalizeOptionalInfo,
        maxLines: 10,
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Row(
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
    );
  }

  String _getBandLabel(String band) {
    if (band.contains('2.4')) return '2.4 GHz';
    if (band.contains('5GHz_2')) return '5 GHz-2';
    if (band.contains('5GHz')) return '5 GHz';
    if (band.contains('6GHz')) return '6 GHz';
    return band.replaceFirst('RADIO_', '');
  }

  @override
  String title(BuildContext context) => loc(context).pnpPersonalizeWiFiTitle;

  void _checkForEnablingNext(WidgetRef ref) {
    bool isValid;

    if (_wifiSettings?.isSplitMode == true) {
      // Validate all bands
      isValid = _wifiSettings!.radios.every((radio) {
        final ssid = _perBandSsidControllers?[radio.band]?.text ?? '';
        final password = _perBandPasswordControllers?[radio.band]?.text ?? '';
        return _validateSSID(ssid) && _validatePassword(password);
      });
    } else {
      // Unified mode
      final ssid = _ssidEditController?.text ?? '';
      final password = _passwordEditController?.text ?? '';
      isValid = _validateSSID(ssid) && _validatePassword(password);
    }

    if (isValid) {
      pnp.setStepStatus(index, status: StepViewStatus.data);
    } else {
      pnp.setStepStatus(index, status: StepViewStatus.error);
    }
  }

  bool _validateSSID(String ssid) {
    final InputValidator wifiSSIDValidator = InputValidator([
      RequiredRule(),
      NoSurroundWhitespaceRule(),
      LengthRule(min: 1, max: 32),
      WiFiSsidRule(),
    ]);
    return wifiSSIDValidator.validate(ssid);
  }

  bool _validatePassword(String password) {
    final InputValidator wifiPasswordValidator = InputValidator([
      LengthRule(min: 8, max: 64),
      NoSurroundWhitespaceRule(),
      AsciiRule(),
      WiFiPSKRule(),
    ]);
    return wifiPasswordValidator.validate(password);
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
          // The body holds six paragraphs, which can exceed the viewport on
          // short screens or in locales with longer copy. Scroll the body only,
          // so the title and the Close action stay visible.
          content: SizedBox(
            width: 400.0,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyMedium(loc(context).modalPnpWiFiOptionalDesc1),
                  const AppGap.medium(),
                  AppText.bodyMedium(loc(context).modalPnpWiFiOptionalDesc2),
                  const AppGap.medium(),
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
