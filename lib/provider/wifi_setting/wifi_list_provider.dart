import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/models/radio_info.dart';
import 'package:linksys_app/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/dashboard_manager_state.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_state.dart';
import 'package:linksys_app/provider/wifi_setting/wifi_item.dart';

final wifiListProvider = NotifierProvider<WifiListNotifier, List<WifiItem>>(
  () => WifiListNotifier(),
);

class WifiListNotifier extends Notifier<List<WifiItem>> {
  @override
  List<WifiItem> build() {
    final dashboardManagerState = ref.watch(dashboardManagerProvider);
    final deviceManagerState = ref.watch(deviceManagerProvider);
    return _getWifiList(deviceManagerState, dashboardManagerState);
  }

  List<WifiItem> _getWifiList(
    DeviceManagerState deviceManagerState,
    DashboardManagerState dashboardManagerState,
  ) {
    final wifiItems = dashboardManagerState.mainRadios
        .map((radio) => WifiItem(
              wifiType: WifiType.main,
              radioID: WifiRadioBand.getByValue(radio.radioID),
              ssid: radio.settings.ssid,
              password: radio.settings.wpaPersonalSettings?.passphrase ?? '',
              securityType:
                  WifiSecurityType.getByValue(radio.settings.security),
              wirelessMode: WifiWirelessMode.getByValue(radio.settings.mode),
              channelWidth:
                  WifiChannelWidth.getByValue(radio.settings.channelWidth),
              channel: radio.settings.channel,
              isBroadcast: radio.settings.broadcastSSID,
              isEnabled: radio.settings.isEnabled,
              availableSecurityTypes: radio.supportedSecurityTypes
                  .map((e) => WifiSecurityType.getByValue(e))
                  .toList(),
              availableWirelessModes: radio.supportedModes
                  .map((e) => WifiWirelessMode.getByValue(e))
                  .toList(),
              availableChannels: Map.fromIterable(
                  radio.supportedChannelsForChannelWidths, key: (e) {
                final channelWidth =
                    (e as SupportedChannelsForChannelWidths).channelWidth;
                return WifiChannelWidth.getByValue(channelWidth);
              }, value: ((e) {
                return (e as SupportedChannelsForChannelWidths).channels;
              })),
              numOfDevices: deviceManagerState.mainWifiDevices
                  .where((device) =>
                      device.connections.isNotEmpty &&
                      ref
                              .read(deviceManagerProvider.notifier)
                              .getWirelessBand(device) ==
                          radio.band)
                  .length,
            ))
        .toList();

    final guestRadio = dashboardManagerState.guestRadios.firstOrNull;
    if (guestRadio != null) {
      wifiItems.add(
        WifiItem(
          wifiType: WifiType.guest,
          radioID: WifiRadioBand.radio_24,
          ssid: guestRadio.guestSSID,
          password: guestRadio.guestWPAPassphrase ?? '',
          securityType: WifiSecurityType.wpaPersonal,
          wirelessMode: WifiWirelessMode.mixed,
          channelWidth: WifiChannelWidth.auto,
          channel: 0,
          isBroadcast: guestRadio.broadcastGuestSSID,
          isEnabled: dashboardManagerState.isGuestNetworkEnabled,
          availableSecurityTypes: const [],
          availableWirelessModes: const [],
          availableChannels: const {},
          numOfDevices: deviceManagerState.guestWifiDevices
              .where((device) => device.connections.isNotEmpty)
              .length,
        ),
      );
    }
    return wifiItems;
  }
}
