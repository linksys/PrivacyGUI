import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/models/set_radio_settings.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/_providers.dart';
import 'package:privacy_gui/page/wifi_settings/providers/guest_wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';

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
    final commands = JNAPTransactionBuilder(auth: true, commands: [
      const MapEntry(JNAPAction.getRadioInfo, {}),
      const MapEntry(JNAPAction.getGuestRadioSettings, {}),
    ]);
    await ref.read(wifiAdvancedProvider.notifier).fetch();
    final deviceManagerState = ref.read(deviceManagerProvider);
    final results = await ref
        .read(routerRepositoryProvider)
        .transaction(commands, fetchRemote: force);
    final resultMap = Map.fromEntries(results.data);

    final radioInfoJson = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getRadioInfo, resultMap);
    final radioInfo = radioInfoJson != null
        ? GetRadioInfo.fromMap(radioInfoJson.output)
        : null;
    final wifiItems = radioInfo?.radios
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
    final guestRadioSettingsJson = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getGuestRadioSettings, resultMap);
    final guestRadioInfo = guestRadioSettingsJson != null
        ? GuestRadioSettings.fromMap(guestRadioSettingsJson.output)
        : null;

    final guestWiFi = GuestWiFiItem(
      isEnabled: guestRadioInfo?.isGuestNetworkEnabled ?? false,
      ssid: guestRadioInfo?.radios.firstOrNull?.guestSSID ?? '',
      password: guestRadioInfo?.radios.firstOrNull?.guestWPAPassphrase ?? '',
      numOfDevices: deviceManagerState.guestWifiDevices.length,
    );
    state = state.copyWith(
      mainWiFi: wifiItems,
      guestWiFi: guestWiFi,
    );

    logger.d('[State]:[wiFiList]: ${state.toJson()}');
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
        guestWiFi: GuestWiFiItem(
            isEnabled: dashboardManagerState.isGuestNetworkEnabled,
            ssid:
                dashboardManagerState.guestRadios.firstOrNull?.guestSSID ?? '',
            password: dashboardManagerState
                    .guestRadios.firstOrNull?.guestWPAPassphrase ??
                '',
            numOfDevices: deviceManagerState.guestWifiDevices.length));
  }

  Future<WiFiState> save() async {
    final routerRepository = ref.read(routerRepositoryProvider);
    // build main wifi settings
    final result = state.mainWiFi
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
    // build guest wifi settings
    final guestRadioInfo = await routerRepository
        .send(JNAPAction.getGuestRadioSettings, auth: true)
        .then((response) => GuestRadioSettings.fromMap(response.output));
    final setGuestRadioSettings =
        SetGuestRadioSettings.fromGuestRadioSettings(guestRadioInfo);
    final newGuestRadios = setGuestRadioSettings.radios
        .map((e) => e.copyWith(
            isEnabled: state.guestWiFi.isEnabled,
            guestSSID: state.guestWiFi.ssid,
            guestWPAPassphrase: state.guestWiFi.password))
        .toList();
    final newSetGuestRadioSettings = setGuestRadioSettings.copyWith(
        isGuestNetworkEnabled: state.guestWiFi.isEnabled,
        radios: newGuestRadios);

    final builder = JNAPTransactionBuilder(auth: true, commands: [
      MapEntry(JNAPAction.setRadioSettings, newSettings.toMap()),
      MapEntry(
          JNAPAction.setGuestRadioSettings, newSetGuestRadioSettings.toMap()),
    ]);
    return routerRepository
        .transaction(
          builder,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
        )
        .then((_) => ref.read(pollingProvider.notifier).forcePolling())
        .then((_) => fetch(true));
  }

  Future<void> saveToggleEnabled(
      {required List<String>? radios, required bool enabled}) async {
    if (radios == null) {
      final guestRadioInfo = await ref
          .read(routerRepositoryProvider)
          .send(JNAPAction.getGuestRadioSettings, auth: true)
          .then((response) => GuestRadioSettings.fromMap(response.output));
      final setGuestRadioSettings =
          SetGuestRadioSettings.fromGuestRadioSettings(guestRadioInfo);
      final newGuestRadios = setGuestRadioSettings.radios
          .map((e) => e.copyWith(
              isEnabled: state.guestWiFi.isEnabled,
              guestSSID: state.guestWiFi.ssid,
              guestWPAPassphrase: state.guestWiFi.password))
          .toList();
      final newSetGuestRadioSettings = setGuestRadioSettings.copyWith(
          isGuestNetworkEnabled: state.guestWiFi.isEnabled,
          radios: newGuestRadios);
      await ref
          .read(routerRepositoryProvider)
          .send(
            JNAPAction.setGuestRadioSettings,
            data: newSetGuestRadioSettings.toMap(),
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache,
            auth: true,
          )
          .then((_) => fetch(true))
          .then((_) => ref.read(pollingProvider.notifier).forcePolling());
    } else {
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
          .then((_) => fetch(true))
          .then((_) => ref.read(pollingProvider.notifier).forcePolling());
    }
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
  void setWiFiSSID(String ssid, [WifiRadioBand? band]) {
    if (band == null) {
      final current = state.guestWiFi;
      state = state.copyWith(guestWiFi: current.copyWith(ssid: ssid));
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

  void setWiFiPassword(String password, [WifiRadioBand? band]) {
    if (band == null) {
      final current = state.guestWiFi;
      state = state.copyWith(guestWiFi: current.copyWith(password: password));
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

  void setWiFiEnabled(bool isEnabled, [WifiRadioBand? band]) {
    if (band == null) {
      final current = state.guestWiFi;
      state = state.copyWith(guestWiFi: current.copyWith(isEnabled: isEnabled));
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

  void setWiFiSecurityType(WifiSecurityType type, WifiRadioBand band) {
    final current =
        state.mainWiFi.firstWhereOrNull((element) => element.radioID == band);
    if (current != null) {
      final index = state.mainWiFi.indexOf(current);
      final newOne = current.copyWith(securityType: type);
      state =
          state.copyWith(mainWiFi: List.from(state.mainWiFi)..[index] = newOne);
    }
  }

  void setWiFiMode(WifiWirelessMode mode, WifiRadioBand band) {
    final current =
        state.mainWiFi.firstWhereOrNull((element) => element.radioID == band);
    if (current != null) {
      final index = state.mainWiFi.indexOf(current);
      final newOne = current.copyWith(wirelessMode: mode);
      state =
          state.copyWith(mainWiFi: List.from(state.mainWiFi)..[index] = newOne);
    }
  }

  void setEnableBoardcast(bool isEnabled, WifiRadioBand band) {
    final current =
        state.mainWiFi.firstWhereOrNull((element) => element.radioID == band);
    if (current != null) {
      final index = state.mainWiFi.indexOf(current);
      final newOne = current.copyWith(isBroadcast: isEnabled);
      state =
          state.copyWith(mainWiFi: List.from(state.mainWiFi)..[index] = newOne);
    }
  }

  void setChannelWidth(WifiChannelWidth channelWidth, WifiRadioBand band) {
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
      state =
          state.copyWith(mainWiFi: List.from(state.mainWiFi)..[index] = newOne);
    }
  }

  void setChannel(int channel, WifiRadioBand band) {
    final current =
        state.mainWiFi.firstWhereOrNull((element) => element.radioID == band);
    if (current != null) {
      final index = state.mainWiFi.indexOf(current);
      final newOne = current.copyWith(channel: channel);
      state =
          state.copyWith(mainWiFi: List.from(state.mainWiFi)..[index] = newOne);
    }
  }
}
