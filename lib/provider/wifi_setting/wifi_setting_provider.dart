import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/constants/pref_key.dart';
import 'package:linksys_app/core/cloud/linksys_cloud_repository.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/models/guest_radio_settings.dart';
import 'package:linksys_app/core/jnap/models/radio_info.dart';
import 'package:linksys_app/core/jnap/providers/dashboard_manager_provider.dart';
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

  void selectWifi(WifiListItem wifiItem) {
    state = state.copyWith(selectedWifiItem: wifiItem);
  }

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
        await repo.send(JNAPAction.setGuestRadioSettings, auth: true, data: {
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
        await repo.send(JNAPAction.setGuestRadioSettings, auth: true, data: {
          'isGuestNetworkEnabled': guestRadios.firstOrNull?.isEnabled ?? false,
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
}
