import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/models/set_radio_settings.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
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
    return _getWifiList(deviceManagerState, dashboardManagerState);
  }

  Future<WiFiState> fetch([bool force = false]) async {
    final radioInfo = await ref
        .read(routerRepositoryProvider)
        .send(JNAPAction.getRadioInfo, fetchRemote: force, auth: true)
        .then((result) => GetRadioInfo.fromMap(result.output));
    final deviceManagerState = ref.read(deviceManagerProvider);
    final wifiItems = radioInfo.radios
        .map(
          (radio) => WiFiItem.fromRadio(radio,
              numOfDevices: deviceManagerState.mainWifiDevices.where((device) {
                final deviceBand = ref
                    .read(deviceManagerProvider.notifier)
                    .getBandConnectedBy(device);
                return device.connections.isNotEmpty &&
                    deviceBand == radio.band;
              }).length),
        )
        .toList();
    state = state.copyWith(
        mainWiFi: wifiItems, simpleWiFi: wifiItems.first.copyWith());
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
                return device.connections.isNotEmpty &&
                    deviceBand == radio.band;
              }).length),
        )
        .toList();

    return WiFiState(
      mainWiFi: wifiItems,
      simpleWiFi: wifiItems.first,
    );
  }

  Future<void> save(WiFiListViewMode mode) {
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

  bool isAllBandsConsistent() {
    return !state.mainWiFi.any((element) =>
        element.ssid != state.simpleWiFi.ssid ||
        element.password != state.simpleWiFi.ssid);
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
