import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/wifi_list_tile.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/wifi_password_field.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/wifi_setting_modal_mixin.dart';
import 'package:ui_kit_library/ui_kit.dart';

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
  // Get serviceHelper from dependency injection
  final serviceHelper = getIt<ServiceHelper>();

  @override
  Widget build(BuildContext context) {
    final radio = widget.radio;
    return Padding(
      padding: EdgeInsets.only(
        // Note: horizontal spacing is handled by Wrap's spacing property
        // Only add bottom padding for vertical separation between rows
        bottom: AppSpacing.lg,
      ),
      child: AppCard(
        key: Key('WiFiCard-${widget.radio.radioID.value}'),
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm, horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

  Widget _advancedWiFiBandCard(WiFiItem radio, bool canBeDisable) {
    return WifiListTile(
      key: Key('wifiBandCard-${radio.radioID.value}'),
      title: AppText.labelLarge(radio.radioID.bandName),
      trailing: canBeDisable
          ? AppSwitch(
              key: Key('WiFiSwitch-${radio.radioID.value}'),
              value: radio.isEnabled,
              onChanged: (value) {
                ref
                    .read(wifiBundleProvider.notifier)
                    .setWiFiEnabled(value, radio.radioID);
              },
            )
          : null,
    );
  }

  Widget _advancedWiFiNameCard(WiFiItem radio) => WifiListTile(
        key: Key('wifiNameCard-${radio.radioID.value}'),
        title: AppText.bodyMedium(loc(context).wifiName),
        description: AppText.labelLarge(radio.ssid),
        trailing: const AppIcon.font(
          AppFontIcons.edit,
        ),
        onTap: () {
          showWiFiNameModal(radio.ssid, (value) {
            ref
                .read(wifiBundleProvider.notifier)
                .setWiFiSSID(value, radio.radioID);
          });
        },
      );

  Widget _advancedWiFiPasswordCard(WiFiItem radio) => WifiListTile(
        key: Key('wifiPasswordCard-${radio.radioID.value}'),
        title: AppText.bodyMedium(loc(context).wifiPassword),
        description: WifiPasswordField(
          controller: TextEditingController(text: radio.password),
          readOnly: true,
          showLabel: false,
          isLength64: true,
        ),
        trailing: const AppIcon.font(AppFontIcons.edit),
        onTap: () {
          showWifiPasswordModal(radio.password, (value) {
            ref
                .read(wifiBundleProvider.notifier)
                .setWiFiPassword(value, radio.radioID);
          });
        },
      );

  Widget _advancedWiFiSecurityTypeCard(WiFiItem radio) => WifiListTile(
        key: Key('wifiSecurityCard-${radio.radioID.value}'),
        title: AppText.bodyMedium(loc(context).securityMode),
        description: AppText.labelLarge(
            getWifiSecurityTypeTitle(context, radio.securityType)),
        trailing: const AppIcon.font(AppFontIcons.edit),
        onTap: () {
          showSecurityModeModal(
              radio.securityType, radio.availableSecurityTypes, (value) {
            ref
                .read(wifiBundleProvider.notifier)
                .setWiFiSecurityType(value, radio.radioID);
          });
        },
      );

  Widget _advanvedWiFiWirelessModeCard(WiFiItem radio) {
    final isShowMode = radio.availableWirelessModes.isNotEmpty;

    if (!isShowMode)
      return const SizedBox.shrink(key: Key('wireless-mode-hidden'));

    return WifiListTile(
      key: Key('wifiWirelessModeCard-${radio.radioID.value}'),
      title: AppText.bodyMedium(loc(context).wifiMode),
      description: AppText.labelLarge(
          getWifiWirelessModeTitle(context, radio.wirelessMode, null)),
      trailing: const AppIcon.font(AppFontIcons.edit),
      onTap: () {
        final availableModes = radio.availableWirelessModes
            .where((element) =>
                element != WifiWirelessMode.ax || serviceHelper.isSupportMLO())
            .toList();

        final validList = validWirelessModeForChannelWidth(
            radio.channelWidth, availableModes);

        showWirelessWiFiModeModal(radio.wirelessMode, radio.defaultMixedMode,
            availableModes, validList, (value) {
          ref
              .read(wifiBundleProvider.notifier)
              .setWiFiMode(value, radio.radioID);
        });
      },
    );
  }

  Widget _advancedWiFiBoradcastCard(WiFiItem radio) => WifiListTile(
        key: Key('wifiBroadcastCard-${radio.radioID.value}'),
        title: AppText.bodyMedium(loc(context).broadcastSSID),
        trailing: AppSwitch(
          key: Key('BroadcastSwitch-${radio.radioID.value}'),
          value: radio.isBroadcast,
          onChanged: (value) {
            ref
                .read(wifiBundleProvider.notifier)
                .setEnableBoardcast(value, radio.radioID);
          },
        ),
      );

  Widget _advancedWiFiChannelWidthCard(WiFiItem radio) => WifiListTile(
        key: Key('wifiChannelWidthCard-${radio.radioID.value}'),
        title: AppText.bodyMedium(loc(context).channelWidth),
        description: AppText.labelLarge(
          getWifiChannelWidthTitle(context, radio.channelWidth),
        ),
        trailing: const AppIcon.font(AppFontIcons.edit),
        onTap: () {
          showChannelWidthModal(
              radio.channelWidth,
              radio.availableChannels.keys.toList(),
              radio.availableChannels.keys.toList(), (value) {
            ref
                .read(wifiBundleProvider.notifier)
                .setChannelWidth(value, radio.radioID);
          });
        },
      );

  Widget _advancedWiFiChannelCard(WiFiItem radio) => WifiListTile(
        key: Key('wifiChannelCard-${radio.radioID.value}'),
        title: AppText.bodyMedium(loc(context).channel),
        description: AppText.labelLarge(getWifiChannelTitle(
          context,
          radio.channel,
          radio.radioID,
        )),
        trailing: const AppIcon.font(AppFontIcons.edit),
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
