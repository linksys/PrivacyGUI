import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/constants/pref_key.dart';
import 'package:linksys_app/core/cloud/linksys_cloud_repository.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/extensions/_extensions.dart';
import 'package:linksys_app/core/jnap/models/guest_radio_settings.dart';
import 'package:linksys_app/core/jnap/models/radio_info.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/provider/wifi_setting/wifi_setting_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

final wifiSettingProvider =
    NotifierProvider<WifiSettingNotifier, WifiSettingState>(
        () => WifiSettingNotifier());

class WifiSettingNotifier extends Notifier<WifiSettingState> {
  @override
  WifiSettingState build() => const WifiSettingState();

  Future<void> fetchAllRadioInfo() async {
    List<WifiListItem> wifiList = [];
    List<RouterRadioInfo>? mainRadioInfo0;
    GuestRadioSetting? guestRadioInfoSetting0;
    final repo = ref.read(routerRepositoryProvider);
    await repo.fetchAllRadioInfo();
    final results = await repo.fetchAllRadioInfo();
    final radioInfo = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getRadioInfo, Map.fromEntries(results));

    if (radioInfo != null) {
      final mainRadioInfo = List.from(radioInfo.output['radios'])
          .map((e) => RouterRadioInfo.fromJson(e))
          .toList();

      String security6GType = '';
      String securityType = '';
      for (RouterRadioInfo radioInfo in mainRadioInfo) {
        if (radioInfo.band == '6GHz') {
          security6GType = radioInfo.settings.security;
        } else if (radioInfo.band == '2.4GHz' || radioInfo.band == '5GHz') {
          securityType = radioInfo.settings.security;
        }
      }
      wifiList.add(WifiListItem(
          wifiType: WifiType.main,
          ssid: mainRadioInfo.first.settings.ssid,
          password: mainRadioInfo.first.settings.wpaPersonalSettings.passphrase,
          securityType: WifiListItem.convertToWifiSecurityType(securityType),
          security6GType:
              WifiListItem.convertToWifiSecurityType(security6GType),
          mode:
              WifiListItem.convertToWifiMode(mainRadioInfo.first.settings.mode),
          isWifiEnabled: mainRadioInfo.first.settings.isEnabled,
          numOfDevices: 0,
          signal: 0));
      mainRadioInfo0 = mainRadioInfo;
    }
    final guestRadioSettings = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getGuestRadioSettings, Map.fromEntries(results));
    if (guestRadioSettings != null) {
      final guestRadioInfoSetting =
          GuestRadioSetting.fromJson(guestRadioSettings.output);
      wifiList.add(WifiListItem(
          wifiType: WifiType.guest,
          ssid: guestRadioInfoSetting.radios.first.guestSSID,
          password: guestRadioInfoSetting.radios.first.guestWPAPassphrase ?? '',
          securityType: wifiList.isNotEmpty
              ? wifiList.first.securityType
              : WifiSecurityType.wpa2Wpa3Mixed,
          mode: wifiList.isNotEmpty ? wifiList.first.mode : WifiMode.mixed,
          isWifiEnabled: guestRadioInfoSetting.radios.first.isEnabled,
          numOfDevices: 0,
          signal: 0));
      guestRadioInfoSetting0 = guestRadioInfoSetting;
    }

    state = state.copyWith(
      wifiList: wifiList,
      mainRadioInfo: mainRadioInfo0,
      guestRadioInfo: guestRadioInfoSetting0,
    );
  }

  void selectWifi(WifiListItem wifiItem) {
    state = state.copyWith(selectedWifiItem: wifiItem);
  }

  Future<void> enableWifi(bool enable, WifiType wifiType) async {
    final repo = ref.read(routerRepositoryProvider);
    switch (wifiType) {
      case WifiType.main:
        List<NewRadioSettings> radioSettings = [];
        for (RouterRadioInfo radioInfo in state.mainRadioInfo ?? []) {
          RouterRadioInfoSettings settings =
              radioInfo.settings.copyWith(isEnable: enable);
          radioSettings.add(
              NewRadioSettings(radioID: radioInfo.radioID, settings: settings));
        }

        await repo.send(
          JNAPAction.setRadioSettings,
          auth: true,
          data: {
            'radios': radioSettings.map((e) => e.toJson()).toList(),
          },
        ).then((value) {
          fetchAllRadioInfo();
          state = state.copyWith(
              selectedWifiItem:
                  state.selectedWifiItem.copyWith(isWifiEnabled: enable));
        });
        break;
      case WifiType.guest:
        List<GuestRadioInfo> radios = [];
        for (GuestRadioInfo radioInfo in state.guestRadioInfo?.radios ?? []) {
          GuestRadioInfo newRadioInfo = radioInfo.copyWith(isEnabled: enable);
          radios.add(newRadioInfo);
        }
        await repo.send(JNAPAction.setGuestRadioSettings, auth: true, data: {
          'isGuestNetworkEnabled': enable,
          'radios': radios.map((e) => e.toJson()).toList(),
        }).then((value) {
          fetchAllRadioInfo();
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
        for (RouterRadioInfo radioInfo in state.mainRadioInfo ?? []) {
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
          data: {
            'radios': radioSettings.map((e) => e.toJson()).toList(),
          },
        ).then((value) {
          fetchAllRadioInfo();
          state = state.copyWith(
              selectedWifiItem: state.selectedWifiItem
                  .copyWith(ssid: name, password: password));
        });
        break;
      case WifiType.guest:
        List<GuestRadioInfo> radios = [];
        for (GuestRadioInfo radioInfo in state.guestRadioInfo?.radios ?? []) {
          GuestRadioInfo newRadioInfo =
              radioInfo.copyWith(guestSSID: name, guestWPAPassphrase: password);
          radios.add(newRadioInfo);
        }
        await repo.send(JNAPAction.setGuestRadioSettings, auth: true, data: {
          'isGuestNetworkEnabled':
              state.guestRadioInfo?.isGuestNetworkEnabled ?? false,
          'radios': radios.map((e) => e.toJson()).toList(),
        }).then((value) {
          fetchAllRadioInfo();
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
        List<NewRadioSettings> radioSettings = [];
        if (settingOption == WifiSettingOption.securityType6G) {
          for (RouterRadioInfo radioInfo in state.mainRadioInfo ?? []) {
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
          for (RouterRadioInfo radioInfo in state.mainRadioInfo ?? []) {
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
          data: {
            'radios': radioSettings.map((e) => e.toJson()).toList(),
          },
        ).then((value) {
          fetchAllRadioInfo();
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
        List<NewRadioSettings> radioSettings = [];
        for (RouterRadioInfo radioInfo in state.mainRadioInfo ?? []) {
          RouterRadioInfoSettings settings =
              radioInfo.settings.copyWith(mode: wifiMode.value);
          radioSettings.add(
              NewRadioSettings(radioID: radioInfo.radioID, settings: settings));
        }
        await repo.send(
          JNAPAction.setRadioSettings,
          auth: true,
          data: {
            'radios': radioSettings.map((e) => e.toJson()).toList(),
          },
        ).then((value) {
          fetchAllRadioInfo();
          state = state.copyWith(
              selectedWifiItem:
                  state.selectedWifiItem.copyWith(mode: wifiMode));
        });
        break;
      case WifiType.guest:
        break;
    }
  }
}
