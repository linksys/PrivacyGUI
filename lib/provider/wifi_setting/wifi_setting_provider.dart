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

/*
  Future<void> enableWifi(bool enable, WifiType wifiType) async {
    final repo = ref.read(routerRepositoryProvider);
    switch (wifiType) {
      case WifiType.main:
        List<NewRadioSettings> radioSettings = [];
        final mainRadios = ref.read(dashboardManagerProvider).mainRadios;
        for (RouterRadioInfo radioInfo in mainRadios) {
          RouterRadioInfoSettings settings =
              radioInfo.settings.copyWith(isEnable: enable);
          radioSettings.add(
              NewRadioSettings(radioID: radioInfo.radioID, settings: settings));
        }

        await repo.send(
          JNAPAction.setRadioSettings,
          auth: true,
          cacheLevel: CacheLevel.noCache,
          data: {
            'radios': radioSettings.map((e) => e.toJson()).toList(),
          },
        ).then((value) {
          //fetchAllRadioInfo();
          state = state.copyWith(
              selectedWifiItem:
                  state.selectedWifiItem.copyWith(isWifiEnabled: enable));
        });
        break;
      case WifiType.guest:
        final guestRadios = ref.read(dashboardManagerProvider).guestRadios;
        List<GuestRadioInfo> radios = [];
        for (GuestRadioInfo radioInfo in guestRadios) {
          GuestRadioInfo newRadioInfo = radioInfo.copyWith(isEnabled: enable);
          radios.add(newRadioInfo);
        }
        await repo.send(JNAPAction.setGuestRadioSettings,
            auth: true,
            cacheLevel: CacheLevel.noCache,
            data: {
              'isGuestNetworkEnabled': enable,
              'radios': radios.map((e) => e.toJson()).toList(),
            }).then((value) {
          // fetchAllRadioInfo();
          state = state.copyWith(
              selectedWifiItem:
                  state.selectedWifiItem.copyWith(isWifiEnabled: enable));
        });
        break;
    }
  }

  Future<void> updateWifiNameAndPassword(
      String name, String password, WifiType wifiType) async {
    final repo = ref.read(routerRepositoryProvider);
    switch (wifiType) {
      case WifiType.main:
        List<NewRadioSettings> radioSettings = [];
        final mainRadios = ref.read(dashboardManagerProvider).mainRadios;
        for (RouterRadioInfo radioInfo in mainRadios) {
          RouterWPAPersonalSettings routerWPAPersonalSettings = radioInfo
              .settings.wpaPersonalSettings
              .copyWith(password: password);
          RouterRadioInfoSettings settings = radioInfo.settings.copyWith(
              ssid: name, wpaPersonalSettings: routerWPAPersonalSettings);
          radioSettings.add(
              NewRadioSettings(radioID: radioInfo.radioID, settings: settings));
        }
        final pref = await SharedPreferences.getInstance();
        final networkId = pref.getString(pSelectedNetworkId) ?? '';
        final cloudUpdateSuccess = await ref
            .read(cloudRepositoryProvider)
            .updateFriendlyName(name, networkId)
            .then((value) => true)
            .onError((error, stackTrace) {
          logger.i('update friendly name error: $error');
          return false;
        });
        if (!cloudUpdateSuccess) {
          // Error handling and do not continue update router settings
          break;
        }
        await repo.send(
          JNAPAction.setRadioSettings,
          auth: true,
          cacheLevel: CacheLevel.noCache,
          data: {
            'radios': radioSettings.map((e) => e.toJson()).toList(),
          },
        ).then((value) {
          // fetchAllRadioInfo();
          state = state.copyWith(
              selectedWifiItem: state.selectedWifiItem
                  .copyWith(ssid: name, password: password));
        });
        break;
      case WifiType.guest:
        final guestRadios = ref.read(dashboardManagerProvider).guestRadios;
        List<GuestRadioInfo> radios = [];
        for (GuestRadioInfo radioInfo in guestRadios) {
          GuestRadioInfo newRadioInfo =
              radioInfo.copyWith(guestSSID: name, guestWPAPassphrase: password);
          radios.add(newRadioInfo);
        }
        await repo.send(JNAPAction.setGuestRadioSettings,
            auth: true,
            cacheLevel: CacheLevel.noCache,
            data: {
              'isGuestNetworkEnabled':
                  guestRadios.firstOrNull?.isEnabled ?? false,
              'radios': radios.map((e) => e.toJson()).toList(),
            }).then((value) {
          // fetchAllRadioInfo();
          state = state.copyWith(
              selectedWifiItem: state.selectedWifiItem
                  .copyWith(ssid: name, password: password));
        });
        break;
    }
  }

  Future<void> updateSecurityType(WifiSettingOption settingOption,
      WifiSecurityType securityType, WifiType wifiType) async {
    final repo = ref.read(routerRepositoryProvider);
    switch (wifiType) {
      case WifiType.main:
        final mainRadios = ref.read(dashboardManagerProvider).mainRadios;
        List<NewRadioSettings> radioSettings = [];
        if (settingOption == WifiSettingOption.securityType6G) {
          for (RouterRadioInfo radioInfo in mainRadios) {
            if (radioInfo.band == '2.4GHz' || radioInfo.band == '5GHz') {
              radioSettings.add(NewRadioSettings(
                  radioID: radioInfo.radioID, settings: radioInfo.settings));
            } else if (radioInfo.band == '6GHz') {
              RouterRadioInfoSettings settings =
                  radioInfo.settings.copyWith(security: securityType.value);
              radioSettings.add(NewRadioSettings(
                  radioID: radioInfo.radioID, settings: settings));
            }
          }
        } else {
          for (RouterRadioInfo radioInfo in mainRadios) {
            if (radioInfo.band == '2.4GHz' || radioInfo.band == '5GHz') {
              RouterRadioInfoSettings settings =
                  radioInfo.settings.copyWith(security: securityType.value);
              radioSettings.add(NewRadioSettings(
                  radioID: radioInfo.radioID, settings: settings));
            } else if (radioInfo.band == '6GHz') {
              radioSettings.add(NewRadioSettings(
                  radioID: radioInfo.radioID, settings: radioInfo.settings));
            }
          }
        }

        await repo.send(
          JNAPAction.setRadioSettings,
          auth: true,
          cacheLevel: CacheLevel.noCache,
          data: {
            'radios': radioSettings.map((e) => e.toJson()).toList(),
          },
        ).then((value) {
          // fetchAllRadioInfo();
          if (settingOption == WifiSettingOption.securityType6G) {
            state = state.copyWith(
                selectedWifiItem: state.selectedWifiItem
                    .copyWith(security6GType: securityType));
          } else {
            state = state.copyWith(
                selectedWifiItem: state.selectedWifiItem
                    .copyWith(securityType: securityType));
          }
        });

        break;
      case WifiType.guest:
        break;
    }
  }

  // modify WiFi mode
  Future<void> updateWifiMode(WifiMode wifiMode, WifiType wifiType) async {
    final repo = ref.read(routerRepositoryProvider);
    switch (wifiType) {
      case WifiType.main:
        final mainRadios = ref.read(dashboardManagerProvider).mainRadios;
        List<NewRadioSettings> radioSettings = [];
        for (RouterRadioInfo radioInfo in mainRadios) {
          RouterRadioInfoSettings settings =
              radioInfo.settings.copyWith(mode: wifiMode.value);
          radioSettings.add(
              NewRadioSettings(radioID: radioInfo.radioID, settings: settings));
        }
        await repo.send(
          JNAPAction.setRadioSettings,
          auth: true,
          cacheLevel: CacheLevel.noCache,
          data: {
            'radios': radioSettings.map((e) => e.toJson()).toList(),
          },
        ).then((value) {
          // fetchAllRadioInfo();
          state = state.copyWith(
              selectedWifiItem:
                  state.selectedWifiItem.copyWith(mode: wifiMode));
        });
        break;
      case WifiType.guest:
        break;
    }
  }
  */
}
