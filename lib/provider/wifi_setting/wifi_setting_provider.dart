import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/models/radio_info.dart';
import 'package:linksys_app/core/jnap/models/set_radio_settings.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/provider/wifi_setting/wifi_item.dart';

final wifiSettingProvider = NotifierProvider<WifiSettingNotifier, WifiItem>(
    () => WifiSettingNotifier());

class WifiSettingNotifier extends Notifier<WifiItem> {
  @override
  WifiItem build() => const WifiItem(
        wifiType: WifiType.main,
        radioID: WifiRadioBand.radio_24,
        ssid: '',
        password: '',
        securityType: WifiSecurityType.wpaPersonal,
        wirelessMode: WifiWirelessMode.mixed,
        channelWidth: WifiChannelWidth.auto,
        channel: 0,
        isBroadcast: false,
        isEnabled: false,
        availableSecurityTypes: [],
        availableWirelessModes: [],
        availableChannels: {},
        numOfDevices: 0,
      );

  void selectWifi(WifiItem wifiItem) {
    state = wifiItem;
  }

  WifiItem currentSettings() => state.copyWith();

  int? checkIfChannelLegalWithWidth({
    required int channel,
    required WifiChannelWidth channelWidth,
  }) {
    final newChannelList = state.availableChannels[channelWidth] ?? [];
    return !newChannelList.contains(channel) ? newChannelList.first : null;
  }

  Future<void> saveWiFiSettings(WifiItem wifiItem) {
    final newSettings = SetRadioSettings(radios: [
      NewRadioSettings(
        radioID: wifiItem.radioID.value,
        settings: RouterRadioSettings(
          isEnabled: wifiItem.isEnabled,
          mode: wifiItem.wirelessMode.value,
          ssid: wifiItem.ssid,
          broadcastSSID: wifiItem.isBroadcast,
          channelWidth: wifiItem.channelWidth.value,
          channel: wifiItem.channel,
          security: wifiItem.securityType.value,
          wepSettings: _getWepSettings(wifiItem),
          wpaPersonalSettings: _getWpaPersonalSettings(wifiItem),
          wpaEnterpriseSettings: _getWpaEnterpriseSettings(wifiItem),
        ),
      ),
    ]);

    final routerRepository = ref.read(routerRepositoryProvider);
    return routerRepository
        .send(
      JNAPAction.setRadioSettings,
      auth: true,
      data: newSettings.toMap(),
    )
        .then((result) {
      //Update the state
      state = state.copyWith(
        ssid: wifiItem.ssid,
        password: wifiItem.password,
        securityType: wifiItem.securityType,
        wirelessMode: wifiItem.wirelessMode,
        channelWidth: wifiItem.channelWidth,
        channel: wifiItem.channel,
        isBroadcast: wifiItem.isBroadcast,
        isEnabled: wifiItem.isEnabled,
      );
    });
  }

  WepSettings? _getWepSettings(WifiItem wifiItem) {
    // 20240124: Only WPA-Personal variant is available from app UI for now
    return wifiItem.securityType == WifiSecurityType.wep
        ? const WepSettings(
            encryption: '',
            key1: '',
            key2: '',
            key3: '',
            key4: '',
            txKey: 0,
          )
        : null;
  }

  WpaPersonalSettings? _getWpaPersonalSettings(WifiItem wifiItem) {
    return wifiItem.securityType.isWpaPersonalVariant
        ? WpaPersonalSettings(passphrase: wifiItem.password)
        : null;
  }

  WpaEnterpriseSettings? _getWpaEnterpriseSettings(WifiItem wifiItem) {
    // 20240124: Only WPA-Personal variant is available from app UI for now
    return wifiItem.securityType.isWpaEnterpriseVariant
        ? const WpaEnterpriseSettings(
            radiusServer: '',
            radiusPort: 0,
            sharedKey: '',
          )
        : null;
  }
}
