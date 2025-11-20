import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/wifi_setting_modal_mixin.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

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

class _MainWiFiCardState extends ConsumerState<MainWiFiCard>
    with WifiSettingModalMixin {
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController()
      ..text =
          widget.radio.securityType.isOpenVariant ? '' : widget.radio.password;
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
      child: AppCard(
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
        ),
      ),
    );
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
                      .read(wifiBundleProvider.notifier)
                      .setWiFiEnabled(value, radio.radioID);
                }
              : null,
        ),
      );

  Widget _advancedWiFiNameCard(WiFiItem radio) => AppListCard(
        key: ValueKey('wifiNameCard-${radio.radioID.bandName}'),
        showBorder: false,
        title: AppText.bodyMedium(loc(context).wifiName),
        description: AppText.labelLarge(radio.ssid),
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        trailing: const Icon(
          LinksysIcons.edit,
          semanticLabel: 'edit',
        ),
        onTap: () {
          showWiFiNameModal(radio.ssid, (value) {
            ref
                .read(wifiBundleProvider.notifier)
                .setWiFiSSID(value, radio.radioID);
          });
        },
      );

  Widget _advancedWiFiPasswordCard(WiFiItem radio) => Opacity(
        opacity: radio.securityType.isOpenVariant ? .5 : 1,
        child: IgnorePointer(
          ignoring: radio.securityType.isOpenVariant ? true : false,
          child: AppListCard(
            key: ValueKey('wifiPasswordCard-${radio.radioID.bandName}'),
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
                          semanticLabel: '${radio.radioID.bandName} wifi password',
                          key: ValueKey('${radio.radioID.bandName} wifi password input'),
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
              print('XXXXX showWifiPasswordModal');
              showWifiPasswordModal(radio.password, (value) {
                ref
                    .read(wifiBundleProvider.notifier)
                    .setWiFiPassword(value, radio.radioID);
              });
            },
          ),
        ),
      );

  Widget _advancedWiFiSecurityTypeCard(WiFiItem radio) {
    final securityType = getWifiSecurityTypeTitle(context, radio.securityType);
    return AppListCard(
      key: ValueKey('wifiSecurityTypeCard-${radio.radioID.bandName}'),
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
        showSecurityModeModal(radio.securityType, radio.availableSecurityTypes,
            (value) {
          ref
              .read(wifiBundleProvider.notifier)
              .setWiFiSecurityType(value, radio.radioID);
        });
      },
    );
  }

  Widget _advanvedWiFiWirelessModeCard(WiFiItem radio) =>
      AppSettingCard.noBorder(
        key: ValueKey('wifiWirelessModeCard-${radio.radioID.bandName}'),
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
          showWirelessWiFiModeModal(radio.wirelessMode, radio.defaultMixedMode,
              radio.availableWirelessModes, validWirelessModes, (value) {
            ref
                .read(wifiBundleProvider.notifier)
                .setWiFiMode(value, radio.radioID);
            if (!validWirelessModes.contains(value)) {
              ref
                  .read(wifiBundleProvider.notifier)
                  .setChannelWidth(WifiChannelWidth.auto, radio.radioID);
            }
          });
        },
      );

  Widget _advancedWiFiBoradcastCard(WiFiItem radio) => AppListCard(
        key: ValueKey('wifiBroadcastCard-${radio.radioID.bandName}'),
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
                .read(wifiBundleProvider.notifier)
                .setEnableBoardcast(value, radio.radioID);
          },
        ),
      );

  Widget _advancedWiFiChannelWidthCard(WiFiItem radio) =>
      AppSettingCard.noBorder(
        key: ValueKey('wifiChannelWidthCard-${radio.radioID.bandName}'),
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
          showChannelWidthModal(
            radio.channelWidth,
            radio.availableChannels.keys.toList(),
            getAvailableChannelWidths(
                radio.wirelessMode, radio.availableChannels.keys.toList()),
            (value) {
              ref
                  .read(wifiBundleProvider.notifier)
                  .setChannelWidth(value, radio.radioID);
            },
          );
        },
      );

  Widget _advancedWiFiChannelCard(WiFiItem radio) => AppSettingCard.noBorder(
        key: ValueKey('wifiChannelCard-${radio.radioID.bandName}'),
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
          showChannelModal(
              radio.channel,
              radio.availableChannels[radio.channelWidth] ?? [],
              radio.radioID, (value) {
            ref
                .read(wifiBundleProvider.notifier)
                .setChannel(value, radio.radioID);
          });
        },
      );
}
