import 'package:collection/collection.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/models/set_radio_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/guest_wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';

class WifiSettingsMapper {
  static WiFiItem fromRadio(RouterRadio radio, {int numOfDevices = 0}) {
    return WiFiItem(
      radioID: WifiRadioBand.getByValue(radio.radioID),
      ssid: radio.settings.ssid,
      password: radio.settings.wpaPersonalSettings?.passphrase ?? '',
      securityType: WifiSecurityType.getByValue(radio.settings.security),
      wirelessMode: WifiWirelessMode.getByValue(radio.settings.mode),
      defaultMixedMode: radio.defaultMixedMode != null
          ? WifiWirelessMode.getByValue(radio.defaultMixedMode!)
          : null,
      channelWidth: WifiChannelWidth.getByValue(radio.settings.channelWidth),
      channel: radio.settings.channel,
      isBroadcast: radio.settings.broadcastSSID,
      isEnabled: radio.settings.isEnabled,
      availableSecurityTypes: radio.supportedSecurityTypes
          .map((e) => WifiSecurityType.getByValue(e))
          //Remove "WEP" and "WPA-Enterprise" types from UI for now
          .where((e) => e.isOpenVariant || e.isWpaPersonalVariant)
          .toList(),
      availableWirelessModes: radio.supportedModes
          .map((e) => WifiWirelessMode.getByValue(e))
          .toList(),
      availableChannels:
          Map.fromIterable(radio.supportedChannelsForChannelWidths, key: (e) {
        final channelWidth =
            (e as SupportedChannelsForChannelWidths).channelWidth;
        return WifiChannelWidth.getByValue(channelWidth);
      }, value: ((e) {
        return (e as SupportedChannelsForChannelWidths).channels;
      })),
      numOfDevices: numOfDevices,
    );
  }

  static List<WiFiItem> toSimpleModeWifiItems(WiFiListSettings settings) {
    return settings.mainWiFi.map((wifiItem) {
      final isEnabled = settings.isSimpleMode ? true : wifiItem.isEnabled;
      final ssid =
          settings.isSimpleMode ? settings.simpleModeWifi.ssid : wifiItem.ssid;
      final security = settings.isSimpleMode
          // Handle security type for 6G band
          ? wifiItem.radioID == WifiRadioBand.radio_6
              ? settings.simpleModeWifi.securityType.isOpenVariant
                  ? WifiSecurityType.enhancedOpenOnly
                  : WifiSecurityType.wpa3Personal
              : settings.simpleModeWifi.securityType
          : wifiItem.securityType;
      final password = settings.isSimpleMode
          ? settings.simpleModeWifi.password
          : wifiItem.password;

      return wifiItem.copyWith(
        isEnabled: isEnabled,
        ssid: ssid,
        securityType: security,
        password: password,
      );
    }).toList();
  }

  static SetRadioSettings toSetRadioSettings(WiFiListSettings settings) {
    final radioSettings = (settings.isSimpleMode
            ? toSimpleModeWifiItems(settings)
            : settings.mainWiFi)
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
                wpaPersonalSettings: wifiItem.securityType.isWpaPersonalVariant
                    ? WpaPersonalSettings(passphrase: wifiItem.password)
                    : null,
              ),
            ))
        .toList();

    return SetRadioSettings(radios: radioSettings);
  }

  static SetGuestRadioSettings mergeGuestSettings(
      GuestRadioSettings original,
      GuestWiFiItem guestItem,
      List<WiFiItem> mainRadios) {
    final newGuestRadios = original.radios
        .map(
          (e) => e.copyWith(
            isEnabled: mainRadios
                    .firstWhereOrNull(
                        (mainRadio) => e.radioID == mainRadio.radioID.value)
                    ?.isEnabled ??
                guestItem.isEnabled,
            guestSSID: guestItem.ssid,
            guestWPAPassphrase: guestItem.password,
            canEnableRadio: guestItem.isEnabled,
          ),
        )
        .toList();
    return SetGuestRadioSettings.fromGuestRadioSettings(original).copyWith(
        isGuestNetworkEnabled: guestItem.isEnabled, radios: newGuestRadios);
  }

  static WifiSecurityType getSimpleModeAvailableSecurityType(
      WifiSecurityType currentSecurityType,
      List<WifiSecurityType> availableSecurityTypeList) {
    // 1. Return the current security type if availableSecurityTypeList is empty
    if (availableSecurityTypeList.isEmpty) {
      return currentSecurityType;
    }
    // 2. Return the current security type if it is available
    if (availableSecurityTypeList.contains(currentSecurityType)) {
      return currentSecurityType;
    }
    // 3. Return the first available security type in priority order
    const priorityOrder = [
      WifiSecurityType.wpa3Personal,
      WifiSecurityType.wpa2Or3MixedPersonal,
      WifiSecurityType.wpa2Personal,
    ];
    for (final type in priorityOrder) {
      if (availableSecurityTypeList.contains(type)) {
        return type;
      }
    }
    // 4. Return the first available security type
    return availableSecurityTypeList.first;
  }

  static List<WifiSecurityType> getSimpleModeAvailableSecurityTypeList(
      List<WiFiItem> wifiList) {
    return wifiList.isEmpty
        ? <WifiSecurityType>[]
        : wifiList
            .map((e) => e.availableSecurityTypes.toSet())
            .reduce((value, element) => value.intersection(element))
            .toList();
  }
}
