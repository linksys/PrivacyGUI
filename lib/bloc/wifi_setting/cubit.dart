import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/wifi_setting/_wifi_setting.dart';
import 'package:linksys_moab/constants/_constants.dart';
import 'package:linksys_moab/model/router/guest_radio_settings.dart';
import 'package:linksys_moab/model/router/radio_info.dart';
import 'package:linksys_moab/network/jnap/better_action.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/repository/linksys_cloud_repository.dart';
import 'package:linksys_moab/repository/router/commands/_commands.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WifiSettingCubit extends Cubit<WifiSettingState> {
  WifiSettingCubit(
      {required LinksysCloudRepository cloudRepository,
      required RouterRepository routerRepository})
      : _routerRepository = routerRepository,
        _cloudRepository = cloudRepository,
        super(const WifiSettingState());

  final RouterRepository _routerRepository;
  final LinksysCloudRepository _cloudRepository;

  Future<void> fetchAllRadioInfo() async {
    List<WifiListItem> wifiList = [];
    List<RouterRadioInfo>? mainRadioInfo0;
    GuestRadioSetting? guestRadioInfoSetting0;
    final results = await _routerRepository.fetchAllRadioInfo();
    final radioInfo =
        JNAPTransactionSuccessWrap.getResult(JNAPAction.getRadioInfo, results);
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
        JNAPAction.getGuestRadioSettings, results);
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
    // if (results.containsKey(JNAPAction.getIoTNetworkSettings.actionValue)) {
    //   final isIoTNetworkEnabled =
    //       results[JNAPAction.getIoTNetworkSettings.actionValue]!
    //           .output['isIoTNetworkEnabled'];
    //   _wifiList.add(WifiListItem(
    //       wifiType: WifiType.iot,
    //       ssid: '',
    //       password: '',
    //       securityType: _wifiList.isNotEmpty
    //           ? _wifiList.first.securityType
    //           : WifiSecurityType.wpa2Wpa3Mixed,
    //       mode: _wifiList.isNotEmpty ? _wifiList.first.mode : WifiMode.mixed,
    //       isWifiEnabled: isIoTNetworkEnabled,
    //       numOfDevices: 0,
    //       signal: 0));
    // }

    emit(state.copyWith(
      wifiList: wifiList,
      mainRadioInfo: mainRadioInfo0,
      guestRadioInfo: guestRadioInfoSetting0,
    ));
  }

  void selectWifi(WifiListItem wifiItem) {
    emit(state.copyWith(selectedWifiItem: wifiItem));
  }

  Future<void> enableWifi(bool enable, WifiType wifiType) async {
    switch (wifiType) {
      case WifiType.main:
        List<NewRadioSettings> radioSettings = [];
        for (RouterRadioInfo radioInfo in state.mainRadioInfo ?? []) {
          RouterRadioInfoSettings settings =
              radioInfo.settings.copyWith(isEnable: enable);
          radioSettings.add(
              NewRadioSettings(radioID: radioInfo.radioID, settings: settings));
        }

        await _routerRepository.send(
          JNAPAction.setRadioSettings,
          auth: true,
          data: {
            'radios': radioSettings.map((e) => e.toJson()).toList(),
          },
        ).then((value) {
          fetchAllRadioInfo();
          emit(state.copyWith(
              selectedWifiItem:
                  state.selectedWifiItem.copyWith(isWifiEnabled: enable)));
        });
        break;
      case WifiType.guest:
        List<GuestRadioInfo> radios = [];
        for (GuestRadioInfo radioInfo in state.guestRadioInfo?.radios ?? []) {
          GuestRadioInfo newRadioInfo = radioInfo.copyWith(isEnabled: enable);
          radios.add(newRadioInfo);
        }
        await _routerRepository
            .send(JNAPAction.setGuestRadioSettings, auth: true, data: {
          'isGuestNetworkEnabled': enable,
          'radios': radios.map((e) => e.toJson()).toList(),
        }).then((value) {
          fetchAllRadioInfo();
          emit(state.copyWith(
              selectedWifiItem:
                  state.selectedWifiItem.copyWith(isWifiEnabled: enable)));
        });
        break;
      case WifiType.iot:
        // await _routerRepository.setIoTNetworkSettings(enable).then((value) {
        //   fetchAllRadioInfo();
        //   emit(state.copyWith(
        //       selectedWifiItem:
        //           state.selectedWifiItem.copyWith(isWifiEnabled: enable)));
        // });
        break;
    }
  }

  Future<void> updateSecurityType(WifiSettingOption settingOption,
      WifiSecurityType securityType, WifiType wifiType) async {
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

        await _routerRepository.send(
          JNAPAction.setRadioSettings,
          auth: true,
          data: {
            'radios': radioSettings.map((e) => e.toJson()).toList(),
          },
        ).then((value) {
          fetchAllRadioInfo();
          if (settingOption == WifiSettingOption.securityType6G) {
            emit(state.copyWith(
                selectedWifiItem: state.selectedWifiItem
                    .copyWith(security6GType: securityType)));
          } else {
            emit(state.copyWith(
                selectedWifiItem: state.selectedWifiItem
                    .copyWith(securityType: securityType)));
          }
        });

        break;
      case WifiType.guest:
        break;
      case WifiType.iot:
        break;
    }
  }

  Future<void> updateWifiNameAndPassword(
      String name, String password, WifiType wifiType) async {
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
        final networkId = pref.getString(linksysPrefSelectedNetworkId) ?? '';
        final cloudUpdateSuccess = await _cloudRepository
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
        await _routerRepository.send(
          JNAPAction.setRadioSettings,
          auth: true,
          data: {
            'radios': radioSettings.map((e) => e.toJson()).toList(),
          },
        ).then((value) {
          fetchAllRadioInfo();
          emit(state.copyWith(
              selectedWifiItem: state.selectedWifiItem
                  .copyWith(ssid: name, password: password)));
        });
        break;
      case WifiType.guest:
        List<GuestRadioInfo> radios = [];
        for (GuestRadioInfo radioInfo in state.guestRadioInfo?.radios ?? []) {
          GuestRadioInfo newRadioInfo =
              radioInfo.copyWith(guestSSID: name, guestWPAPassphrase: password);
          radios.add(newRadioInfo);
        }
        await _routerRepository
            .send(JNAPAction.setGuestRadioSettings, auth: true, data: {
          'isGuestNetworkEnabled':
              state.guestRadioInfo?.isGuestNetworkEnabled ?? false,
          'radios': radios.map((e) => e.toJson()).toList(),
        }).then((value) {
          fetchAllRadioInfo();
          emit(state.copyWith(
              selectedWifiItem: state.selectedWifiItem
                  .copyWith(ssid: name, password: password)));
        });
        break;
      case WifiType.iot:
        break;
    }
  }

  // modify WiFi mode
  Future<void> updateWifiMode(WifiMode wifiMode, WifiType wifiType) async {
    switch (wifiType) {
      case WifiType.main:
        List<NewRadioSettings> radioSettings = [];
        for (RouterRadioInfo radioInfo in state.mainRadioInfo ?? []) {
          RouterRadioInfoSettings settings =
              radioInfo.settings.copyWith(mode: wifiMode.value);
          radioSettings.add(
              NewRadioSettings(radioID: radioInfo.radioID, settings: settings));
        }
        await _routerRepository.send(
          JNAPAction.setRadioSettings,
          auth: true,
          data: {
            'radios': radioSettings.map((e) => e.toJson()).toList(),
          },
        ).then((value) {
          fetchAllRadioInfo();
          emit(state.copyWith(
              selectedWifiItem:
                  state.selectedWifiItem.copyWith(mode: wifiMode)));
        });
        break;
      case WifiType.guest:
        break;
      case WifiType.iot:
        break;
    }
  }
}
