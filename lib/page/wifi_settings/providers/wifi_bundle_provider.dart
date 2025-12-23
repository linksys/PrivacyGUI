import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/guest_wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_advanced_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/page/wifi_settings/services/wifi_settings_mapper.dart';
import 'package:privacy_gui/page/wifi_settings/services/wifi_settings_service.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';
import 'package:privacy_gui/util/extensions.dart';

final wifiBundleProvider =
    NotifierProvider<WifiBundleNotifier, WifiBundleState>(() {
  return WifiBundleNotifier();
});

final preservableWifiSettingsProvider =
    Provider<PreservableContract<WifiBundleSettings, WifiBundleStatus>>((ref) {
  return ref.watch(wifiBundleProvider.notifier);
});

class WifiBundleNotifier extends Notifier<WifiBundleState>
    with
        PreservableNotifierMixin<WifiBundleSettings, WifiBundleStatus,
            WifiBundleState> {
  @override
  WifiBundleState build() {
    final dashboardManagerState = ref.read(dashboardManagerProvider);
    final deviceManagerState = ref.read(deviceManagerProvider);
    final homeState = ref.read(dashboardHomeProvider);

    final initialWifiItems = dashboardManagerState.mainRadios
        .map(
          (radio) => WifiSettingsMapper.fromRadio(radio,
              numOfDevices: deviceManagerState.mainWifiDevices.where((device) {
                final deviceBand = ref
                    .read(deviceManagerProvider.notifier)
                    .getBandConnectedBy(device);
                return device.isOnline() && deviceBand == radio.band;
              }).length),
        )
        .toList();

    final initialGuestWiFi = GuestWiFiItem(
        isEnabled: dashboardManagerState.isGuestNetworkEnabled,
        ssid: dashboardManagerState.guestRadios.firstOrNull?.guestSSID ?? '',
        password:
            dashboardManagerState.guestRadios.firstOrNull?.guestWPAPassphrase ??
                '',
        numOfDevices: deviceManagerState.guestWifiDevices.length);

    final simpleModeWifi =
        initialWifiItems.firstWhereOrNull((e) => e.isEnabled) ??
            (initialWifiItems.isNotEmpty
                ? initialWifiItems.first
                : WiFiItem.fromMap(const {
                    'channel': 0,
                    'isBroadcast': false,
                    'isEnabled': false,
                    'numOfDevices': 0,
                  }));

    final initialWifiListSettings = WiFiListSettings(
      mainWiFi: initialWifiItems,
      guestWiFi: initialGuestWiFi,
      isSimpleMode: true, // Default to simple mode
      simpleModeWifi: simpleModeWifi,
    );

    final initialWifiListStatus = WiFiListStatus(
        canDisableMainWiFi: homeState.lanPortConnections.isNotEmpty);

    const initialAdvancedSettings = WifiAdvancedSettingsState();
    final initialPrivacySettings = InstantPrivacySettings.init();
    final initialPrivacyStatus = InstantPrivacyStatus.init();

    final initialBundleSettings = WifiBundleSettings(
      wifiList: initialWifiListSettings,
      advanced: initialAdvancedSettings,
      privacy: initialPrivacySettings,
    );

    final initialBundleStatus = WifiBundleStatus(
      wifiList: initialWifiListStatus,
      privacy: initialPrivacyStatus,
    );

    // Future.microtask(() => performFetch());

    return WifiBundleState(
      settings: Preservable(
          original: initialBundleSettings, current: initialBundleSettings),
      status: initialBundleStatus,
    );
  }

  @override
  Future<(WifiBundleSettings?, WifiBundleStatus?)> performFetch(
      {bool forceRemote = false, bool updateStatusOnly = false}) async {
    final deviceManagerState = ref.read(deviceManagerProvider);
    final homeState = ref.read(dashboardHomeProvider);
    final (newSettings, newStatus) =
        await ref.read(wifiSettingsServiceProvider).fetchBundleSettings(
              serviceHelper: serviceHelper,
              forceRemote: forceRemote,
              mainWifiDevices: deviceManagerState.mainWifiDevices,
              guestWifiDevices: deviceManagerState.guestWifiDevices,
              allDevices: deviceManagerState.deviceList,
              isLanConnected: homeState.lanPortConnections.isNotEmpty,
              getBandConnectedBy: (device) => ref
                  .read(deviceManagerProvider.notifier)
                  .getBandConnectedBy(device),
            );

    if (updateStatusOnly) {
      state = state.copyWith(status: newStatus);
      return (null, newStatus);
    }
    state = state.copyWith(
      settings: Preservable(original: newSettings, current: newSettings),
      status: newStatus,
    );
    return (newSettings, newStatus);
  }

  @override
  Future<void> performSave() async {
    final original = state.settings.original;
    final current = state.settings.current;

    final repo = ref.read(routerRepositoryProvider);
    final futures = <Future>[];

    if (original.wifiList != current.wifiList) {
      futures.add(_saveWifiList(current.wifiList));
    }
    if (original.advanced != current.advanced) {
      futures.add(_saveAdvancedSettings(repo, current.advanced));
    }
    if (original.privacy != current.privacy) {
      futures.add(_savePrivacySettings(repo, current.privacy));
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  Future<void> _saveWifiList(WiFiListSettings settings) async {
    final isSupportGuestWiFi = serviceHelper.isSupportGuestNetwork();
    await ref
        .read(wifiSettingsServiceProvider)
        .saveWifiListSettings(settings, isSupportGuestWiFi);
  }

  Future<void> _saveAdvancedSettings(
      RouterRepository repo, WifiAdvancedSettingsState settings) {
    return ref
        .read(wifiSettingsServiceProvider)
        .saveAdvancedSettings(settings: settings, serviceHelper: serviceHelper);
  }

  Future<void> _savePrivacySettings(
      RouterRepository repo, InstantPrivacySettings settings) {
    final nodeDevices = ref.read(deviceManagerProvider).nodeDevices;
    return ref
        .read(wifiSettingsServiceProvider)
        .savePrivacySettings(settings: settings, nodeDevices: nodeDevices);
  }

  // --- Setters ---

  void _updateSettings(WifiBundleSettings newSettings) {
    state = state.copyWith(
      settings: state.settings.update(newSettings),
    );
  }

  Future<void> saveToggleEnabled(
      {required List<String>? radios, required bool enabled}) async {
    if (radios == null) {
      setWiFiEnabled(enabled);
    } else {
      for (final radio in radios) {
        setWiFiEnabled(enabled, WifiRadioBand.getByValue(radio));
      }
    }
    await save();
  }

  // WifiList Setters
  void setWiFiSSID(String ssid, [WifiRadioBand? band]) {
    final currentSettings = state.settings.current;
    if (band == null) {
      final newWifiList = currentSettings.wifiList.copyWith(
        guestWiFi: currentSettings.wifiList.guestWiFi.copyWith(ssid: ssid),
      );
      _updateSettings(currentSettings.copyWith(wifiList: newWifiList));
    } else {
      final newMainWiFi = currentSettings.wifiList.mainWiFi.map((item) {
        return item.radioID == band ? item.copyWith(ssid: ssid) : item;
      }).toList();
      final newWifiList =
          currentSettings.wifiList.copyWith(mainWiFi: newMainWiFi);
      _updateSettings(currentSettings.copyWith(wifiList: newWifiList));
    }
  }

  void setWiFiPassword(String password, [WifiRadioBand? band]) {
    final currentSettings = state.settings.current;
    if (band == null) {
      final newWifiList = currentSettings.wifiList.copyWith(
        guestWiFi:
            currentSettings.wifiList.guestWiFi.copyWith(password: password),
      );
      _updateSettings(currentSettings.copyWith(wifiList: newWifiList));
    } else {
      final newMainWiFi = currentSettings.wifiList.mainWiFi.map((item) {
        return item.radioID == band ? item.copyWith(password: password) : item;
      }).toList();
      final newWifiList =
          currentSettings.wifiList.copyWith(mainWiFi: newMainWiFi);
      _updateSettings(currentSettings.copyWith(wifiList: newWifiList));
    }
  }

  void setWiFiEnabled(bool isEnabled, [WifiRadioBand? band]) {
    final currentSettings = state.settings.current;
    if (band == null) {
      final newWifiList = currentSettings.wifiList.copyWith(
        guestWiFi:
            currentSettings.wifiList.guestWiFi.copyWith(isEnabled: isEnabled),
      );
      _updateSettings(currentSettings.copyWith(wifiList: newWifiList));
    } else {
      final newMainWiFi = currentSettings.wifiList.mainWiFi.map((item) {
        return item.radioID == band
            ? item.copyWith(isEnabled: isEnabled)
            : item;
      }).toList();
      final newWifiList =
          currentSettings.wifiList.copyWith(mainWiFi: newMainWiFi);
      _updateSettings(currentSettings.copyWith(wifiList: newWifiList));
    }
  }

  void setWiFiSecurityType(WifiSecurityType type, WifiRadioBand band) {
    final currentSettings = state.settings.current;
    final newMainWiFi = currentSettings.wifiList.mainWiFi.map((item) {
      return item.radioID == band ? item.copyWith(securityType: type) : item;
    }).toList();
    final newWifiList =
        currentSettings.wifiList.copyWith(mainWiFi: newMainWiFi);
    _updateSettings(currentSettings.copyWith(wifiList: newWifiList));
  }

  void setWiFiMode(WifiWirelessMode mode, WifiRadioBand band) {
    final currentSettings = state.settings.current;
    final newMainWiFi = currentSettings.wifiList.mainWiFi.map((item) {
      return item.radioID == band ? item.copyWith(wirelessMode: mode) : item;
    }).toList();
    final newWifiList =
        currentSettings.wifiList.copyWith(mainWiFi: newMainWiFi);
    _updateSettings(currentSettings.copyWith(wifiList: newWifiList));
  }

  void setEnableBoardcast(bool isEnabled, WifiRadioBand band) {
    final currentSettings = state.settings.current;
    final newMainWiFi = currentSettings.wifiList.mainWiFi.map((item) {
      return item.radioID == band
          ? item.copyWith(isBroadcast: isEnabled)
          : item;
    }).toList();
    final newWifiList =
        currentSettings.wifiList.copyWith(mainWiFi: newMainWiFi);
    _updateSettings(currentSettings.copyWith(wifiList: newWifiList));
  }

  void setChannelWidth(WifiChannelWidth channelWidth, WifiRadioBand band) {
    final currentSettings = state.settings.current;
    final newMainWiFi = currentSettings.wifiList.mainWiFi.map((item) {
      if (item.radioID == band) {
        final newChannelList = item.availableChannels[channelWidth] ?? [];
        final newChannel = !newChannelList.contains(item.channel)
            ? newChannelList.first
            : item.channel;
        return item.copyWith(channelWidth: channelWidth, channel: newChannel);
      }
      return item;
    }).toList();
    final newWifiList =
        currentSettings.wifiList.copyWith(mainWiFi: newMainWiFi);
    _updateSettings(currentSettings.copyWith(wifiList: newWifiList));
  }

  void setChannel(int channel, WifiRadioBand band) {
    final currentSettings = state.settings.current;
    final newMainWiFi = currentSettings.wifiList.mainWiFi.map((item) {
      return item.radioID == band ? item.copyWith(channel: channel) : item;
    }).toList();
    final newWifiList =
        currentSettings.wifiList.copyWith(mainWiFi: newMainWiFi);
    _updateSettings(currentSettings.copyWith(wifiList: newWifiList));
  }

  void setSimpleMode(bool isSimple) {
    final currentSettings = state.settings.current;
    final newWifiList =
        currentSettings.wifiList.copyWith(isSimpleMode: isSimple);
    _updateSettings(currentSettings.copyWith(wifiList: newWifiList));
  }

  void setSimpleModeWifi(WiFiItem wifi) {
    final currentSettings = state.settings.current;
    final newWifiList = currentSettings.wifiList.copyWith(simpleModeWifi: wifi);
    _updateSettings(currentSettings.copyWith(wifiList: newWifiList));
  }

  // AdvancedSettings Setters
  void setClientSteeringEnabled(bool value) {
    final currentSettings = state.settings.current;
    final newAdvanced =
        currentSettings.advanced.copyWith(isClientSteeringEnabled: value);
    _updateSettings(currentSettings.copyWith(advanced: newAdvanced));
  }

  void setNodesSteeringEnabled(bool value) {
    final currentSettings = state.settings.current;
    final newAdvanced =
        currentSettings.advanced.copyWith(isNodesSteeringEnabled: value);
    _updateSettings(currentSettings.copyWith(advanced: newAdvanced));
  }

  void setIptvEnabled(bool value) {
    final currentSettings = state.settings.current;
    final newAdvanced = currentSettings.advanced.copyWith(isIptvEnabled: value);
    _updateSettings(currentSettings.copyWith(advanced: newAdvanced));
  }

  void setDFSEnabled(bool value) {
    final currentSettings = state.settings.current;
    final newAdvanced = currentSettings.advanced.copyWith(isDFSEnabled: value);
    _updateSettings(currentSettings.copyWith(advanced: newAdvanced));
  }

  void setMLOEnabled(bool value) {
    final currentSettings = state.settings.current;
    final newAdvanced = currentSettings.advanced.copyWith(isMLOEnabled: value);
    _updateSettings(currentSettings.copyWith(advanced: newAdvanced));
  }

  void setAirtimeFairnessEnabled(bool value) {
    final currentSettings = state.settings.current;
    final newAdvanced =
        currentSettings.advanced.copyWith(isAirtimeFairnessEnabled: value);
    _updateSettings(currentSettings.copyWith(advanced: newAdvanced));
  }

  // Privacy (MAC Filter) Setters
  void setMacFilterMode(MacFilterMode mode) {
    final currentSettings = state.settings.current;
    final newPrivacy = currentSettings.privacy.copyWith(mode: mode);
    _updateSettings(currentSettings.copyWith(privacy: newPrivacy));
  }

  void setMacFilterSelection(List<String> selections, [bool isDeny = true]) {
    final currentSettings = state.settings.current;
    selections = selections.map((e) => e.toUpperCase()).toList();
    final currentList = isDeny
        ? currentSettings.privacy.denyMacAddresses
        : currentSettings.privacy.macAddresses;
    final unique = List<String>.from(currentList)
      ..addAll(selections)
      ..unique();
    final newPrivacy = currentSettings.privacy.copyWith(
      macAddresses: isDeny ? [] : unique,
      denyMacAddresses: isDeny ? unique : [],
    );
    _updateSettings(currentSettings.copyWith(privacy: newPrivacy));
  }

  void removeMacFilterSelection(List<String> selection, [bool isDeny = true]) {
    final currentSettings = state.settings.current;
    selection = selection.map((e) => e.toUpperCase()).toList();
    final currentList = isDeny
        ? currentSettings.privacy.denyMacAddresses
        : currentSettings.privacy.macAddresses;
    final newList = List<String>.from(currentList)
      ..removeWhere((element) => selection.contains(element));
    final newPrivacy = currentSettings.privacy.copyWith(
      macAddresses: isDeny ? currentSettings.privacy.macAddresses : newList,
      denyMacAddresses:
          isDeny ? newList : currentSettings.privacy.denyMacAddresses,
    );
    _updateSettings(currentSettings.copyWith(privacy: newPrivacy));
  }

  void setMacAddressList(List<String> macAddressList) {
    final currentSettings = state.settings.current;
    macAddressList = macAddressList.map((e) => e.toUpperCase()).toList();
    final newPrivacy =
        currentSettings.privacy.copyWith(denyMacAddresses: macAddressList);
    _updateSettings(currentSettings.copyWith(privacy: newPrivacy));
  }

  // --- Delegate methods for service layer ---

  /// Validates the current WiFi list settings.
  /// Delegates to [WifiSettingsService.validateWifiListSettings].
  bool validateWifiListSettings(WiFiListSettings settings) {
    return ref
        .read(wifiSettingsServiceProvider)
        .validateWifiListSettings(settings);
  }

  /// Checks for MLO settings conflicts.
  /// Delegates to [WifiSettingsService.checkingMLOSettingsConflicts].
  bool checkingMLOSettingsConflicts(Map<WifiRadioBand, WiFiItem> radios,
      {bool? isMloEnabled}) {
    return ref
        .read(wifiSettingsServiceProvider)
        .checkingMLOSettingsConflicts(radios, isMloEnabled: isMloEnabled);
  }
}
