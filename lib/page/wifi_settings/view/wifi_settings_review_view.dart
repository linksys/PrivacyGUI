import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/shortcuts/snack_bar.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/wifi_settings/wifi_term_titles.dart';
import 'package:linksys_app/provider/wifi_setting/_wifi_setting.dart';
import 'package:linksys_app/provider/wifi_setting/wifi_item.dart';
import 'package:linksys_app/validator_rules/rules.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/dropdown/dropdown_menu.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

class WifiSettingsReviewView extends ArgumentsConsumerStatefulView {
  const WifiSettingsReviewView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<WifiSettingsReviewView> createState() =>
      _WifiSettingsReviewViewState();
}

class _WifiSettingsReviewViewState
    extends ConsumerState<WifiSettingsReviewView> {
  late WifiItem currentSettings;
  final _wifiNameController = TextEditingController();
  final _wifiPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isSSIDValid = true;
  bool _isPasswordValid = true;
  bool _isOptionsValid = true;

  @override
  initState() {
    super.initState();
    currentSettings = ref.read(wifiSettingProvider.notifier).currentSettings();
    _wifiNameController.text = currentSettings.ssid;
    _wifiPasswordController.text = currentSettings.password;
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? AppFullScreenSpinner(text: getAppLocalizations(context).processing)
        : StyledAppPageView(
            scrollable: true,
            title: getWifiTypeTitle(context, currentSettings.wifiType),
            child: AppBasicLayout(
              content: settingsView(context),
              footer: AppFilledButton.fillWidth(
                'Save',
                onTap: _isNewSettingValid() ? _saveSettings : null,
              ),
            ),
          );
  }

  Widget settingsView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppText.bodyLarge(
              getWifiRadioBandTitle(context, currentSettings.radioID),
            ),
            const Spacer(),
            AppSwitch(
              value: currentSettings.isEnabled,
              onChanged: (enabled) {
                setState(() {
                  currentSettings = currentSettings.copyWith(
                    isEnabled: enabled,
                  );
                });
              },
            ),
          ],
        ),
        const AppGap.regular(),
        const AppText.bodyLarge(
          'Wi-Fi name',
        ),
        const AppGap.small(),
        AppTextField.outline(
          controller: _wifiNameController,
          hintText: 'SSID',
          onChanged: (text) {
            setState(() {
              _isSSIDValid = text.isNotEmpty;
            });
          },
        ),
        const AppGap.regular(),
        const AppText.bodyLarge(
          'Wi-Fi password',
        ),
        const AppGap.small(),
        Visibility(
          visible: currentSettings.securityType.isWpaPersonalVariant,
          replacement: const AppText.labelSmall('None'),
          child: AppPasswordField.withValidator(
            controller: _wifiPasswordController,
            border: const OutlineInputBorder(),
            validationLabel: 'Password must have',
            validations: [
              Validation(
                description: '8 - 64 characters',
                validator: ((text) =>
                    LengthRule(min: 8, max: 64).validate(text)),
              ),
            ],
            onValidationChanged: (isValid) => setState(() {
              _isPasswordValid = isValid;
            }),
          ),
        ),
        const AppGap.regular(),
        const AppText.bodyLarge(
          'Security mode',
        ),
        const AppGap.small(),
        AppDropdownMenu<WifiSecurityType>(
          items: currentSettings.availableSecurityTypes,
          initial: currentSettings.securityType,
          label: (item) {
            return getWifiSecurityTypeTitle(context, item);
          },
          onChanged: (newValue) {
            setState(() {
              currentSettings = currentSettings.copyWith(
                securityType: newValue,
              );
            });
          },
        ),
        const AppGap.regular(),
        const AppText.bodyLarge(
          'Wi-Fi mode',
        ),
        const AppGap.small(),
        AppDropdownMenu<WifiWirelessMode>(
          items: currentSettings.availableWirelessModes,
          initial: currentSettings.wirelessMode,
          label: (item) {
            return getWifiWirelessModeTitle(
                context, item, currentSettings.defaultMixedMode);
          },
          onChanged: (newValue) {
            currentSettings = currentSettings.copyWith(
              wirelessMode: newValue,
            );
          },
        ),
        const AppGap.regular(),
        const AppText.bodyLarge(
          'Channel Width',
        ),
        const AppGap.small(),
        AppDropdownMenu<WifiChannelWidth>(
          items: currentSettings.availableChannels.keys.toList(),
          initial: currentSettings.channelWidth,
          label: (item) {
            return getWifiChannelWidthTitle(context, item);
          },
          onChanged: (newValue) {
            setState(() {
              // Update the selected channel width
              currentSettings = currentSettings.copyWith(
                channelWidth: newValue,
              );
              // Check if the current selected channel is available within
              // the new channel width
              final newChannel = ref
                  .read(wifiSettingProvider.notifier)
                  .checkIfChannelLegalWithWidth(
                    channel: currentSettings.channel,
                    channelWidth: newValue,
                  );
              if (newChannel != null) {
                currentSettings = currentSettings.copyWith(
                  channel: newChannel,
                );
              }
            });
          },
        ),
        const AppGap.regular(),
        const AppText.bodyLarge(
          'Channel',
        ),
        const AppGap.small(),
        AppDropdownMenu<int>(
          items:
              currentSettings.availableChannels[currentSettings.channelWidth] ??
                  [],
          initial: currentSettings.channel,
          label: (item) {
            return getWifiChannelTitle(context, item, currentSettings.radioID);
          },
          onChanged: (newValue) {
            currentSettings = currentSettings.copyWith(
              channel: newValue,
            );
          },
        ),
        const AppGap.regular(),
        const AppText.bodyLarge(
          'Broadcast SSID',
        ),
        const AppGap.small(),
        AppDropdownMenu<bool>(
          items: const [true, false],
          initial: currentSettings.isBroadcast,
          label: (item) => item ? 'YES' : 'NO',
          onChanged: (newValue) {
            currentSettings = currentSettings.copyWith(
              isBroadcast: newValue,
            );
          },
        ),
        const AppGap.extraBig(),
      ],
    );
  }

  bool _isNewSettingValid() =>
      _isSSIDValid && _isPasswordValid && _isOptionsValid;

  void _saveSettings() {
    currentSettings = currentSettings.copyWith(
      ssid: _wifiNameController.text,
      password: _wifiPasswordController.text,
    );
    setState(() {
      _isLoading = true;
    });
    ref
        .read(wifiSettingProvider.notifier)
        .saveWiFiSettings(currentSettings)
        .then((value) {
      setState(() {
        _isLoading = false;
      });
      showSuccessSnackBar(context, 'Success!');
    }).onError((error, stackTrace) {
      _isLoading = false;
      showFailedSnackBar(context, 'Failed!');
    });
  }
}
