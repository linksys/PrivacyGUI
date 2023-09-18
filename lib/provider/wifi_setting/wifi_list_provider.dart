import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/models/radio_info.dart';
import 'package:linksys_app/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/dashboard_manager_state.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_state.dart';
import 'package:linksys_app/provider/wifi_setting/_wifi_setting.dart';

final wifiListProvider = NotifierProvider<WifiListNotifier, List<WifiListItem>>(
  () => WifiListNotifier(),
);

class WifiListNotifier extends Notifier<List<WifiListItem>> {
  @override
  List<WifiListItem> build() {
    final dashboardManagerState = ref.watch(dashboardManagerProvider);
    final deviceManagerState = ref.watch(deviceManagerProvider);
    return _getWifiInfo(deviceManagerState, dashboardManagerState);
  }

  List<WifiListItem> _getWifiInfo(
    DeviceManagerState deviceManagerState,
    DashboardManagerState dashboardManagerState,
  ) {
    List<WifiListItem> items = [];
    final mainRadios = dashboardManagerState.mainRadios;
    Map<String, RouterRadioInfo> infoMap =
        Map.fromEntries(mainRadios.map((e) => MapEntry(e.settings.ssid, e)));
    items = List.from(infoMap.values).map((e) {
      RouterRadioInfo info = e as RouterRadioInfo;
      return WifiListItem(
        wifiType: WifiType.main,
        ssid: info.settings.ssid,
        password: info.settings.wpaPersonalSettings.passphrase,
        securityType:
            WifiListItem.convertToWifiSecurityType(info.settings.security),
        mode: WifiListItem.convertToWifiMode(info.settings.mode),
        band: info.band,
        isWifiEnabled: info.settings.isEnabled,
        numOfDevices: deviceManagerState.mainWifiDevices
            .where((device) =>
                device.connections.isNotEmpty &&
                ref
                        .read(deviceManagerProvider.notifier)
                        .getWirelessBand(device) ==
                    info.band)
            .length,
        signal: 0,
      );
    }).toList();
    final guestRadio = dashboardManagerState.guestRadios.firstOrNull;
    if (guestRadio != null) {
      items.add(
        WifiListItem(
          wifiType: WifiType.guest,
          ssid: guestRadio.guestSSID,
          password: guestRadio.guestWPAPassphrase ?? '',
          securityType: items.isNotEmpty
              ? items.first.securityType
              : WifiSecurityType.wpa2Wpa3Mixed,
          mode: items.isNotEmpty ? items.first.mode : WifiMode.mixed,
          isWifiEnabled: dashboardManagerState.isGuestNetworkEnabled,
          numOfDevices: deviceManagerState.guestWifiDevices
              .where((device) => device.connections.isNotEmpty)
              .length,
          signal: 0,
        ),
      );
    }
    return items;
  }
}
