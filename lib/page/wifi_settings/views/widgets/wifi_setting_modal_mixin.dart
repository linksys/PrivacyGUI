import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/validators.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/wifi_name_field.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/wifi_password_field.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_term_titles.dart';
import 'package:ui_kit_library/ui_kit.dart';

mixin WifiSettingModalMixin<T extends StatefulWidget> on State<T> {
  void showWiFiNameModal(
      String initValue, void Function(String) onEdited) async {
    final wifiSSIDValidator = getWifiSSIDValidator();
    TextEditingController controller = TextEditingController()
      ..text = initValue;
    final result = await showSubmitAppDialog<String>(
      context,
      title: loc(context).wifiName,
      contentBuilder: (context, setState, onSubmit) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WifiNameField(
            semanticLabel: loc(context).wifiName,
            controller: controller,
            onChanged: (value) {
              setState(() {
                // Do setState to show error message
              });
            },
            onSubmitted: (_) {
              if (wifiSSIDValidator.validate(controller.text)) {
                context.pop(controller.text);
              }
            },
          ),
        ],
      ),
      event: () async => controller.text,
      checkPositiveEnabled: () => wifiSSIDValidator.validate(controller.text),
    );

    if (result != null) {
      onEdited.call(result);
    }
  }

  void showWifiPasswordModal(
      String initValue, void Function(String) onEdited) async {
    final wifiPasswordValidator = getWifiPasswordValidator();
    TextEditingController controller = TextEditingController()
      ..text = initValue;
    bool isPasswordValid = true;
    bool isLength64 = initValue.length == 64;
    final result = await showSubmitAppDialog<String>(
      context,
      title: loc(context).wifiPassword,
      contentBuilder: (context, setState, onSubmit) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WifiPasswordField(
              semanticLabel: loc(context).wifiPassword,
              key: ValueKey('wifi password input'),
              controller: controller,
              isLength64: isLength64,
              onChanged: (value) {
                setState(() {
                  isLength64 = value.length == 64;
                });
              },
              onValidationChanged: (isValid) => setState(() {
                isPasswordValid =
                    wifiPasswordValidator.validate(controller.text);
              }),
              onSubmitted: (_) {
                if (wifiPasswordValidator.validate(controller.text)) {
                  context.pop(controller.text);
                }
              },
            ),
          ],
        ),
      ),
      event: () async => controller.text,
      checkPositiveEnabled: () => isPasswordValid,
    );

    if (result != null) {
      onEdited(result);
    }
  }

  void showSecurityModeModal(
    WifiSecurityType type,
    List<WifiSecurityType> list,
    void Function(WifiSecurityType) onSelected,
  ) async {
    WifiSecurityType selected = type;
    final result = await showSimpleAppDialog<WifiSecurityType?>(context,
        title: loc(context).securityMode,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: list
                  .map((e) => RadioListTile<WifiSecurityType>(
                        title: AppText.bodyMedium(getWifiSecurityTypeTitle(context, e)),
                        value: e,
                        groupValue: selected,
                        onChanged: (value) {
                          if (value != null) {
                            selected = value;
                          }
                        },
                      ))
                  .toList(),
            ),
          ],
        ),
        actions: [
          AppButton.text(
            label: loc(context).cancel,
            onTap: () {
              context.pop();
            },
          ),
          AppButton.text(
            label: loc(context).ok,
            onTap: () {
              context.pop(selected);
            },
          ),
        ]);

    if (result != null) {
      onSelected.call(result);
    }
  }

  void showWirelessWiFiModeModal(
    WifiWirelessMode mode,
    WifiWirelessMode? defaultMixedMode,
    List<WifiWirelessMode> list,
    List<WifiWirelessMode> availablelist,
    void Function(WifiWirelessMode) onSelected,
  ) async {
    WifiWirelessMode selected = mode;
    final result = await showSimpleAppDialog<WifiWirelessMode?>(context,
        title: loc(context).wifiMode,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: list
                  .map((e) => Column(
                        children: [
                          RadioListTile<WifiWirelessMode>(
                            title: AppText.bodyMedium(getWifiWirelessModeTitle(
                                context, e, defaultMixedMode)),
                            value: e,
                            groupValue: selected,
                            onChanged: availablelist.contains(e) ? (value) {
                              if (value != null) {
                                selected = value;
                              }
                            } : null,
                          ),
                          if (!availablelist.contains(e))
                            Padding(
                              padding: const EdgeInsets.only(left: 56, bottom: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: AppText.bodySmall(
                                  loc(context).wifiModeNotAvailable,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                        ],
                      ))
                  .toList(),
            ),
          ],
        ),
        actions: [
          AppButton.text(
            label: loc(context).cancel,
            onTap: () {
              context.pop();
            },
          ),
          AppButton.text(
            label: loc(context).ok,
            onTap: () {
              context.pop(selected);
            },
          ),
        ]);

    if (result != null) {
      onSelected.call(result);
    }
  }

  void showChannelModal(
    int channel,
    List<int> list,
    WifiRadioBand band,
    void Function(int) onSelected,
  ) async {
    int selected = channel;
    final result = await showSimpleAppDialog<int?>(context,
        title: loc(context).channel,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: list
                    .map((e) => RadioListTile<int>(
                          title: AppText.bodyMedium(getWifiChannelTitle(context, e, band)),
                          value: e,
                          groupValue: selected,
                          onChanged: (value) {
                            if (value != null) {
                              selected = value;
                            }
                          },
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
        actions: [
          AppButton.text(
            label: loc(context).cancel,
            onTap: () {
              context.pop();
            },
          ),
          AppButton.text(
            label: loc(context).ok,
            onTap: () {
              context.pop(selected);
            },
          ),
        ]);

    if (result != null) {
      onSelected.call(result);
    }
  }

  void showChannelWidthModal(
    WifiChannelWidth channelWidth,
    List<WifiChannelWidth> list,
    List<WifiChannelWidth> validList,
    void Function(WifiChannelWidth) onSelected,
  ) async {
    WifiChannelWidth selected = channelWidth;
    final result = await showSimpleAppDialog<WifiChannelWidth?>(context,
        title: loc(context).channelWidth,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: list
                    .map((e) => RadioListTile<WifiChannelWidth>(
                          title: AppText.bodyMedium(getWifiChannelWidthTitle(
                            context,
                            e,
                          )),
                          value: e,
                          groupValue: selected,
                          onChanged: validList.contains(e) ? (value) {
                            if (value != null) {
                              selected = value;
                            }
                          } : null,
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
        actions: [
          AppButton.text(
            label: loc(context).cancel,
            onTap: () {
              context.pop();
            },
          ),
          AppButton.text(
            label: loc(context).ok,
            onTap: () {
              context.pop(selected);
            },
          ),
        ]);

    if (result != null) {
      onSelected.call(result);
    }
  }
}
