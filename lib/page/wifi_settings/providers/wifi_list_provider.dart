import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/models/set_radio_settings.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/_providers.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_list_view.dart';

final wifiListProvider = NotifierProvider<WifiListNotifier, WiFiState>(
  () => WifiListNotifier(),
);

class WifiListNotifier extends Notifier<WiFiState> {
  @override
  WiFiState build() {
    final dashboardManagerState = ref.read(dashboardManagerProvider);
    final deviceManagerState = ref.read(deviceManagerProvider);
    return _getWifiList(
      deviceManagerState,
      dashboardManagerState,
    );
  }

  Future<WiFiState> fetch([bool force = false]) async {
    final radioInfo = await ref
        .read(routerRepositoryProvider)
        .send(JNAPAction.getRadioInfo, fetchRemote: force, auth: true)
        .then((result) => GetRadioInfo.fromMap(result.output));
    await ref.read(wifiAdvancedProvider.notifier).fetch();
    final deviceManagerState = ref.read(deviceManagerProvider);
    final wifiItems = radioInfo.radios
        .map(
          (radio) => WiFiItem.fromRadio(radio,
              numOfDevices: deviceManagerState.mainWifiDevices.where((device) {
                final deviceBand = ref
                    .read(deviceManagerProvider.notifier)
                    .getBandConnectedBy(device);
                return device.isOnline() && deviceBand == radio.band;
              }).length),
        )
        .toList();
    state = state.copyWith(
      mainWiFi: wifiItems,
      simpleWiFi: wifiItems.first.copyWith(),
    );
    return state;
  }

  WiFiState _getWifiList(
    DeviceManagerState deviceManagerState,
    DashboardManagerState dashboardManagerState,
  ) {
    final wifiItems = dashboardManagerState.mainRadios
        .map(
          (radio) => WiFiItem.fromRadio(radio,
              numOfDevices: deviceManagerState.mainWifiDevices.where((device) {
                final deviceBand = ref
                    .read(deviceManagerProvider.notifier)
                    .getBandConnectedBy(device);
                return device.isOnline() && deviceBand == radio.band;
              }).length),
        )
        .toList();
    return WiFiState(
      mainWiFi: wifiItems,
      simpleWiFi: wifiItems.first.copyWith(),
    );
  }

  Future<WiFiState> save(WiFiListViewMode mode) {
    final result = switch (mode) {
      WiFiListViewMode.simple => state.mainWiFi
          .map((e) => e.copyWith(
              ssid: state.simpleWiFi.ssid, password: state.simpleWiFi.password))
          .toList(),
      WiFiListViewMode.advanced => state.mainWiFi,
    }
        .map((wifiItem) => NewRadioSettings(
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
            ))
        .toList();

    final newSettings = SetRadioSettings(radios: result);

    final routerRepository = ref.read(routerRepositoryProvider);
    return routerRepository
        .send(
          JNAPAction.setRadioSettings,
          auth: true,
          data: newSettings.toMap(),
        )
        .then((_) => ref.read(pollingProvider.notifier).forcePolling())
        .then((_) => fetch(true));
  }

  Future<void> saveToggleEnabled(
      {required List<String> radios, required bool enabled}) async {
    final settings = state.mainWiFi
        .map((wifiItem) => NewRadioSettings(
              radioID: wifiItem.radioID.value,
              settings: RouterRadioSettings(
                isEnabled: radios.contains(wifiItem.radioID.value)
                    ? enabled
                    : wifiItem.isEnabled,
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
            ))
        .toList();
    final newSettings = SetRadioSettings(radios: settings);

    final routerRepository = ref.read(routerRepositoryProvider);
    return routerRepository
        .send(
          JNAPAction.setRadioSettings,
          auth: true,
          data: newSettings.toMap(),
        )
        .then((_) => fetch(true));
  }

  WepSettings? _getWepSettings(WiFiItem wifiItem) {
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

  WpaPersonalSettings? _getWpaPersonalSettings(WiFiItem wifiItem) {
    return wifiItem.securityType.isWpaPersonalVariant
        ? WpaPersonalSettings(passphrase: wifiItem.password)
        : null;
  }

  WpaEnterpriseSettings? _getWpaEnterpriseSettings(WiFiItem wifiItem) {
    // 20240124: Only WPA-Personal variant is available from app UI for now
    return wifiItem.securityType.isWpaEnterpriseVariant
        ? const WpaEnterpriseSettings(
            radiusServer: '',
            radiusPort: 0,
            sharedKey: '',
          )
        : null;
  }

  bool checkingMLOSettingsConflicts(Map<WifiRadioBand, WiFiItem> radios,
      {bool? isMloEnabled}) {
    if (radios.isEmpty) {
      return false;
    }
    if (isMloEnabled == false) {
      return false;
    }
    // Bands do not have the same main settings (SSID/PW/Security Type)
    final first = radios.values.first;
    final isMainSettingsInconsitent = radios.values.any((element) =>
        element.ssid != first.ssid || element.password != first.password);
    // 5 or 6 GHz band has non-WPA3 Security Type (covers scenario that all bands were set to “Enhanced Open Only”)
    final hasNonWPA3SecurityType =
        radios.values.any((element) => !element.securityType.isWPA3Variant);
    // 5 or 6 GHz band is Disabled
    final hasDisabled5G6GBand = radios.entries
        .where((e) => e.key != WifiRadioBand.radio_24)
        .map((e) => e.value)
        .any((element) => !element.isEnabled);
    // 5 or 6 GHz band is not set to “Mixed” Network Mode (non-802.11be mode)
    final has5G6GModeNotMixed = radios.entries
        .where((e) => e.key != WifiRadioBand.radio_24)
        .map((e) => e.value)
        .any((element) => !element.wirelessMode.isIncludeBeMixedMode);
    return isMainSettingsInconsitent ||
        hasNonWPA3SecurityType ||
        hasDisabled5G6GBand ||
        has5G6GModeNotMixed;
  }

  bool isAllBandsConsistent() {
    return !state.mainWiFi.any((element) =>
        element.ssid != state.simpleWiFi.ssid ||
        element.password != state.simpleWiFi.password);
  }

  int? checkIfChannelLegalWithWidth(
      {required int channel,
      required WifiChannelWidth channelWidth,
      required WifiRadioBand band}) {
    final newChannelList = state.mainWiFi
            .firstWhereOrNull((element) => element.radioID == band)
            ?.availableChannels[channelWidth] ??
        [];
    return !newChannelList.contains(channel) ? newChannelList.first : null;
  }

  ///
  /// Setter
  ///
  void setWiFiSSID(String ssid, WifiRadioBand? band) {
    if (band == null) {
      final current = state.simpleWiFi;
      state = state.copyWith(simpleWiFi: current.copyWith(ssid: ssid));
    } else {
      final current =
          state.mainWiFi.firstWhereOrNull((element) => element.radioID == band);
      if (current != null) {
        final index = state.mainWiFi.indexOf(current);
        final newOne = current.copyWith(ssid: ssid);
        state = state.copyWith(
            mainWiFi: List.from(state.mainWiFi)..[index] = newOne);
      }
    }
  }

  void setWiFiPassword(String password, WifiRadioBand? band) {
    if (band == null) {
      final current = state.simpleWiFi;
      state = state.copyWith(simpleWiFi: current.copyWith(password: password));
    } else {
      final current =
          state.mainWiFi.firstWhereOrNull((element) => element.radioID == band);
      if (current != null) {
        final index = state.mainWiFi.indexOf(current);
        final newOne = current.copyWith(password: password);
        state = state.copyWith(
            mainWiFi: List.from(state.mainWiFi)..[index] = newOne);
      }
    }
  }

  void setWiFiEnabled(bool isEnabled, WifiRadioBand? band) {
    if (band == null) {
      final current = state.simpleWiFi;
      state =
          state.copyWith(simpleWiFi: current.copyWith(isEnabled: isEnabled));
    } else {
      final current =
          state.mainWiFi.firstWhereOrNull((element) => element.radioID == band);
      if (current != null) {
        final index = state.mainWiFi.indexOf(current);
        final newOne = current.copyWith(isEnabled: isEnabled);
        state = state.copyWith(
            mainWiFi: List.from(state.mainWiFi)..[index] = newOne);
      }
    }
  }

  void setWiFiSecurityType(WifiSecurityType type, WifiRadioBand? band) {
    if (band == null) {
      final current = state.simpleWiFi;
      state = state.copyWith(simpleWiFi: current.copyWith(securityType: type));
    } else {
      final current =
          state.mainWiFi.firstWhereOrNull((element) => element.radioID == band);
      if (current != null) {
        final index = state.mainWiFi.indexOf(current);
        final newOne = current.copyWith(securityType: type);
        state = state.copyWith(
            mainWiFi: List.from(state.mainWiFi)..[index] = newOne);
      }
    }
  }

  void setWiFiMode(WifiWirelessMode mode, WifiRadioBand? band) {
    if (band == null) {
      final current = state.simpleWiFi;
      state = state.copyWith(simpleWiFi: current.copyWith(wirelessMode: mode));
    } else {
      final current =
          state.mainWiFi.firstWhereOrNull((element) => element.radioID == band);
      if (current != null) {
        final index = state.mainWiFi.indexOf(current);
        final newOne = current.copyWith(wirelessMode: mode);
        state = state.copyWith(
            mainWiFi: List.from(state.mainWiFi)..[index] = newOne);
      }
    }
  }

  void setEnableBoardcast(bool isEnabled, WifiRadioBand? band) {
    if (band == null) {
      final current = state.simpleWiFi;
      state =
          state.copyWith(simpleWiFi: current.copyWith(isBroadcast: isEnabled));
    } else {
      final current =
          state.mainWiFi.firstWhereOrNull((element) => element.radioID == band);
      if (current != null) {
        final index = state.mainWiFi.indexOf(current);
        final newOne = current.copyWith(isBroadcast: isEnabled);
        state = state.copyWith(
            mainWiFi: List.from(state.mainWiFi)..[index] = newOne);
      }
    }
  }

  void setChannelWidth(WifiChannelWidth channelWidth, WifiRadioBand? band) {
    if (band == null) {
      final current = state.simpleWiFi;
      state = state.copyWith(
          simpleWiFi: current.copyWith(
              channelWidth: channelWidth,
              channel: checkIfChannelLegalWithWidth(
                      channel: current.channel,
                      channelWidth: channelWidth,
                      band: current.radioID) ??
                  current.channel));
    } else {
      final current =
          state.mainWiFi.firstWhereOrNull((element) => element.radioID == band);
      if (current != null) {
        final index = state.mainWiFi.indexOf(current);
        final newOne = current.copyWith(
            channelWidth: channelWidth,
            channel: checkIfChannelLegalWithWidth(
                    channel: current.channel,
                    channelWidth: channelWidth,
                    band: band) ??
                current.channel);
        state = state.copyWith(
            mainWiFi: List.from(state.mainWiFi)..[index] = newOne);
      }
    }
  }

  void setChannel(int channel, WifiRadioBand? band) {
    if (band == null) {
      final current = state.simpleWiFi;
      state = state.copyWith(simpleWiFi: current.copyWith(channel: channel));
    } else {
      final current =
          state.mainWiFi.firstWhereOrNull((element) => element.radioID == band);
      if (current != null) {
        final index = state.mainWiFi.indexOf(current);
        final newOne = current.copyWith(channel: channel);
        state = state.copyWith(
            mainWiFi: List.from(state.mainWiFi)..[index] = newOne);
      }
    }
  }
}
