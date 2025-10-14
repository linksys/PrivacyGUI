import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/validators.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/wifi_name_field.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/wifi_password_field.dart';
import 'package:privacy_gui/validator_rules/_validator_rules.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/radios/radio_list.dart';

class MainWiFiCard extends ConsumerStatefulWidget {
  const MainWiFiCard({
    super.key,
    required this.radio,
    required this.canBeDisable,
    this.lastInRow = false,
  });

  final WiFiItem radio;
  final bool canBeDisable;
  final bool lastInRow;

  @override
  ConsumerState<MainWiFiCard> createState() => _MainWiFiCardState();
}

class _MainWiFiCardState extends ConsumerState<MainWiFiCard> {
  final InputValidator wifiSSIDValidator = getWifiSSIDValidator();
  final InputValidator wifiPasswordValidator = getWifiPasswordValidator();

  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController()
      ..text = widget.radio.securityType.isOpenVariant ? '' : widget.radio.password;
  }

  @override
  void didUpdateWidget(covariant MainWiFiCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.radio.password != oldWidget.radio.password ||
        widget.radio.securityType != oldWidget.radio.securityType) {
      _passwordController.text =
          widget.radio.securityType.isOpenVariant ? '' : widget.radio.password;
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radio = widget.radio;
    return Padding(
      padding: EdgeInsets.only(
        right: widget.lastInRow ? 0 : ResponsiveLayout.columnPadding(context),
        bottom: Spacing.medium,
      ),
      child: Column(
        children: [
          AppCard(
              key: ValueKey('WiFiCard-${radio.radioID.bandName}'),
              padding: const EdgeInsets.symmetric(
                  vertical: Spacing.small2, horizontal: Spacing.large2),
              child: Column(
                children: [
                  _advancedWiFiBandCard(radio, widget.canBeDisable),
                  if (radio.isEnabled) ...[
                    const Divider(),
                    _advancedWiFiNameCard(radio),
                    const Divider(),
                    _advancedWiFiPasswordCard(radio),
                    const Divider(),
                    _advancedWiFiSecurityTypeCard(radio),
                    const Divider(),
                    _advanvedWiFiWirelessModeCard(radio),
                    const Divider(),
                    _advancedWiFiBoradcastCard(radio),
                    const Divider(),
                    _advancedWiFiChannelWidthCard(radio),
                    const Divider(),
                    _advancedWiFiChannelCard(radio),
                  ]
                ],
              )),
        ],
      ),
    );
  }

  ///
  /// Dialog modal
  ///
  _showWiFiNameModal(String initValue, void Function(String) onEdited) async {
    TextEditingController controller = TextEditingController()
      ..text = initValue;
    final result = await showSubmitAppDialog<String>(
      context,
      title: loc(context).wifiName,
      contentBuilder: (context, setState, onSubmit) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WifiNameField(
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

  _showWifiPasswordModal(
      String initValue, void Function(String) onEdited) async {
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

  _showSecurityModeModal(
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
            AppRadioList<WifiSecurityType>(
              initial: type,
              mainAxisSize: MainAxisSize.min,
              itemHeight: 56,
              items: list
                  .map((e) => AppRadioListItem(
                        title: getWifiSecurityTypeTitle(context, e),
                        value: e,
                      ))
                  .toList(),
              onChanged: (index, selectedType) {
                if (selectedType != null) {
                  selected = selectedType;
                }
              },
            ),
          ],
        ),
        actions: [
          AppTextButton(
            loc(context).cancel,
            onTap: () {
              context.pop();
            },
          ),
          AppTextButton(
            loc(context).ok,
            onTap: () {
              context.pop(selected);
            },
          ),
        ]);

    if (result != null) {
      onSelected.call(result);
    }
  }

  _showWirelessWiFiModeModal(
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
            AppRadioList<WifiWirelessMode>(
              initial: mode,
              itemHeight: 56,
              mainAxisSize: MainAxisSize.min,
              items: list
                  .map((e) => AppRadioListItem(
                        title: getWifiWirelessModeTitle(
                            context, e, defaultMixedMode),
                        value: e,
                        subTitleWidget: !availablelist.contains(e)
                            ? AppText.bodySmall(
                                loc(context).wifiModeNotAvailable,
                                color: Theme.of(context).colorScheme.error,
                              )
                            : null,
                      ))
                  .toList(),
              onChanged: (index, selectedType) {
                if (selectedType != null) {
                  selected = selectedType;
                }
              },
            ),
          ],
        ),
        actions: [
          AppTextButton(
            loc(context).cancel,
            onTap: () {
              context.pop();
            },
          ),
          AppTextButton(
            loc(context).ok,
            onTap: () {
              context.pop(selected);
            },
          ),
        ]);

    if (result != null) {
      onSelected.call(result);
    }
  }

  _showChannelModal(
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
              AppRadioList<int>(
                initial: channel,
                itemHeight: 56,
                mainAxisSize: MainAxisSize.min,
                items: list
                    .map((e) => AppRadioListItem(
                          title: getWifiChannelTitle(context, e, band),
                          value: e,
                        ))
                    .toList(),
                onChanged: (index, selectedType) {
                  if (selectedType != null) {
                    selected = selectedType;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          AppTextButton(
            loc(context).cancel,
            onTap: () {
              context.pop();
            },
          ),
          AppTextButton(
            loc(context).ok,
            onTap: () {
              context.pop(selected);
            },
          ),
        ]);

    if (result != null) {
      onSelected.call(result);
    }
  }

  _showChannelWidthModal(
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
              AppRadioList<WifiChannelWidth>(
                initial: channelWidth,
                itemHeight: 56,
                mainAxisSize: MainAxisSize.min,
                items: list
                    .map((e) => AppRadioListItem(
                          title: getWifiChannelWidthTitle(
                            context,
                            e,
                          ),
                          value: e,
                          enabled: validList.contains(e),
                        ))
                    .toList(),
                onChanged: (index, selectedType) {
                  if (selectedType != null) {
                    selected = selectedType;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          AppTextButton(
            loc(context).cancel,
            onTap: () {
              context.pop();
            },
          ),
          AppTextButton(
            loc(context).ok,
            onTap: () {
              context.pop(selected);
            },
          ),
        ]);

    if (result != null) {
      onSelected.call(result);
    }
  }

  List<WifiChannelWidth> getAvailableChannelWidths(
      WifiWirelessMode mode, List<WifiChannelWidth> list) {
    WifiChannelWidth maxSupportedWidth = mode.maxSupportedWidth;
    return list.where((width) {
      if (width == WifiChannelWidth.auto) {
        return true;
      }
      return width.index <= maxSupportedWidth.index;
    }).toList();
  }

  List<WifiWirelessMode> validWirelessModeForChannelWidth(
      WifiChannelWidth channelWidth, List<WifiWirelessMode> modes) {
    if (channelWidth == WifiChannelWidth.auto) {
      return modes.toList();
    }
    final int requiredWidthIndex = channelWidth.index;
    return modes.where((mode) {
      final int maxModeWidthIndex = mode.maxSupportedWidth.index;
      return maxModeWidthIndex >= requiredWidthIndex;
    }).toList();
  }

  Widget _advancedWiFiBandCard(WiFiItem radio, [bool canBeDisable = true]) =>
      AppListCard(
        showBorder: false,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        title:
            AppText.labelLarge(getWifiRadioBandTitle(context, radio.radioID)),
        trailing: AppSwitch(
          semanticLabel: getWifiRadioBandTitle(context, radio.radioID),
          value: radio.isEnabled,
          onChanged: !radio.isEnabled || canBeDisable
              ? (value) {
                  ref
                      .read(wifiListProvider.notifier)
                      .setWiFiEnabled(value, radio.radioID);
                }
              : null,
        ),
      );

  Widget _advancedWiFiNameCard(WiFiItem radio) => AppSettingCard.noBorder(
        title: loc(context).wifiName,
        description: radio.ssid,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        trailing: const Icon(
          LinksysIcons.edit,
          semanticLabel: 'edit',
        ),
        onTap: () {
          _showWiFiNameModal(radio.ssid, (value) {
            ref
                .read(wifiListProvider.notifier)
                .setWiFiSSID(value, radio.radioID);
          });
        },
      );

  Widget _advancedWiFiPasswordCard(WiFiItem radio) => Opacity(
        opacity: radio.securityType.isOpenVariant ? .5 : 1,
        child: IgnorePointer(
          ignoring: radio.securityType.isOpenVariant ? true : false,
          child: AppListCard(
            showBorder: false,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            title: AppText.bodyMedium(
              loc(context).wifiPassword,
              color: !radio.securityType.isOpenVariant && radio.password.isEmpty
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurface,
            ),
            description: IntrinsicWidth(
              child: Theme(
                data: Theme.of(context).copyWith(
                    inputDecorationTheme: const InputDecorationTheme(
                        isDense: true, contentPadding: EdgeInsets.zero)),
                child: radio.securityType.isOpenVariant
                    ? Semantics(
                        textField: false,
                        explicitChildNodes: true,
                        child: AppTextField(
                          readOnly: true,
                          border: InputBorder.none,
                          controller: _passwordController,
                        ),
                      )
                    : Semantics(
                        textField: false,
                        explicitChildNodes: true,
                        child: AppPasswordField(
                          semanticLabel: '${radio.radioID.value} wifi password',
                          readOnly: true,
                          border: InputBorder.none,
                          controller: _passwordController,
                          suffixIconConstraints: const BoxConstraints(),
                        ),
                      ),
              ),
            ),
            trailing: const Icon(LinksysIcons.edit),
            onTap: () {
              _showWifiPasswordModal(radio.password, (value) {
                ref
                    .read(wifiListProvider.notifier)
                    .setWiFiPassword(value, radio.radioID);
              });
            },
          ),
        ),
      );

  Widget _advancedWiFiSecurityTypeCard(WiFiItem radio) {
    final securityType = getWifiSecurityTypeTitle(context, radio.securityType);
    return AppListCard(
      showBorder: false,
      title: AppText.bodyMedium(loc(context).securityMode),
      description: SizedBox(
        height: 36,
        child: AppText.labelLarge(securityType),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      trailing: const Icon(
        LinksysIcons.edit,
        semanticLabel: 'edit',
      ),
      onTap: () {
        _showSecurityModeModal(radio.securityType, radio.availableSecurityTypes,
            (value) {
          ref
              .read(wifiListProvider.notifier)
              .setWiFiSecurityType(value, radio.radioID);
        });
      },
    );
  }

  Widget _advanvedWiFiWirelessModeCard(WiFiItem radio) =>
      AppSettingCard.noBorder(
        title: loc(context).wifiMode,
        description: getWifiWirelessModeTitle(
          context,
          radio.wirelessMode,
          radio.defaultMixedMode,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        trailing: const Icon(
          LinksysIcons.edit,
          semanticLabel: 'edit',
        ),
        onTap: () {
          final validWirelessModes = validWirelessModeForChannelWidth(
              radio.channelWidth, radio.availableWirelessModes);
          _showWirelessWiFiModeModal(radio.wirelessMode, radio.defaultMixedMode,
              radio.availableWirelessModes, validWirelessModes, (value) {
            ref
                .read(wifiListProvider.notifier)
                .setWiFiMode(value, radio.radioID);
            if (!validWirelessModes.contains(value)) {
              ref
                  .read(wifiListProvider.notifier)
                  .setChannelWidth(WifiChannelWidth.auto, radio.radioID);
            }
          });
        },
      );

  Widget _advancedWiFiBoradcastCard(WiFiItem radio) => AppListCard(
        showBorder: false,
        title: AppText.labelLarge(loc(context).broadcastSSID),
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        trailing: AppCheckbox(
          value: radio.isBroadcast,
          onChanged: (value) {
            if (value == null) {
              return;
            }
            ref
                .read(wifiListProvider.notifier)
                .setEnableBoardcast(value, radio.radioID);
          },
        ),
      );

  Widget _advancedWiFiChannelWidthCard(WiFiItem radio) =>
      AppSettingCard.noBorder(
        title: loc(context).channelWidth,
        description: getWifiChannelWidthTitle(
          context,
          radio.channelWidth,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        trailing: const Icon(
          LinksysIcons.edit,
          semanticLabel: 'edit',
        ),
        onTap: () {
          _showChannelWidthModal(
            radio.channelWidth,
            radio.availableChannels.keys.toList(),
            getAvailableChannelWidths(
                radio.wirelessMode, radio.availableChannels.keys.toList()),
            (value) {
              ref
                  .read(wifiListProvider.notifier)
                  .setChannelWidth(value, radio.radioID);
            },
          );
        },
      );

  Widget _advancedWiFiChannelCard(WiFiItem radio) => AppSettingCard.noBorder(
        title: loc(context).channel,
        description: getWifiChannelTitle(
          context,
          radio.channel,
          radio.radioID,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        trailing: const Icon(
          LinksysIcons.edit,
          semanticLabel: 'edit',
        ),
        onTap: () {
          _showChannelModal(
              radio.channel,
              radio.availableChannels[radio.channelWidth] ?? [],
              radio.radioID, (value) {
            ref
                .read(wifiListProvider.notifier)
                .setChannel(value, radio.radioID);
          });
        },
      );
}
