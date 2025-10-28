import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
import 'package:privacy_gui/core/jnap/models/mac_filter_settings.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/models/set_radio_settings.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/guest_wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_advanced_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
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
          (radio) => WiFiItem.fromRadio(radio,
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
                : WiFiItem.fromMap(const {}));

    final initialWifiListSettings = WiFiListSettings(
      mainWiFi: initialWifiItems,
      guestWiFi: initialGuestWiFi,
      isSimpleMode: true, // Default to simple mode
      simpleModeWifi: simpleModeWifi,
    );

    final initialWifiListStatus = WiFiListStatus(
        canDisableMainWiFi: homeState.lanPortConnections.isNotEmpty);

    final initialAdvancedSettings = const WifiAdvancedSettingsState();
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

  Future<(WifiBundleSettings, WifiBundleStatus)> _fetchData(
      {bool forceRemote = false}) async {
    final repo = ref.read(routerRepositoryProvider);

    List<MapEntry<JNAPAction, Map<String, dynamic>>> commands = [
      const MapEntry(JNAPAction.getRadioInfo, {}),
    ];
    if (serviceHelper.isSupportGuestNetwork()) {
      commands.add(const MapEntry(JNAPAction.getGuestRadioSettings, {}));
    }
    if (serviceHelper.isSupportTopologyOptimization()) {
      commands
          .add(const MapEntry(JNAPAction.getTopologyOptimizationSettings, {}));
    }
    if (serviceHelper.isSupportIPTv()) {
      commands.add(const MapEntry(JNAPAction.getIptvSettings, {}));
    }
    if (serviceHelper.isSupportMLO()) {
      commands.add(const MapEntry(JNAPAction.getMLOSettings, {}));
    }
    if (serviceHelper.isSupportDFS()) {
      commands.add(const MapEntry(JNAPAction.getDFSSettings, {}));
    }
    if (serviceHelper.isSupportAirtimeFairness()) {
      commands.add(const MapEntry(JNAPAction.getAirtimeFairnessSettings, {}));
    }
    commands.add(const MapEntry(JNAPAction.getMACFilterSettings, {}));
    if (serviceHelper.isSupportGetSTABSSID()) {
      commands.add(const MapEntry(JNAPAction.getSTABSSIDs, {}));
    }

    final transaction = JNAPTransactionBuilder(auth: true, commands: commands);
    final transactionResultFuture =
        repo.transaction(transaction, fetchRemote: forceRemote);
    final myMacFuture = _getMyMACAddress();

    final results = await Future.wait([transactionResultFuture, myMacFuture]);
    final transactionResult = results[0] as JNAPTransactionSuccessWrap;
    final myMac = results[1] as String?;
    final resultMap = Map.fromEntries(transactionResult.data);

    final deviceManagerState = ref.read(deviceManagerProvider);
    final homeState = ref.read(dashboardHomeProvider);
    final radioInfoJson = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getRadioInfo, resultMap);
    final radioInfo = radioInfoJson != null
        ? GetRadioInfo.fromMap(radioInfoJson.output)
        : null;
    final wifiItems = radioInfo?.radios
            .map(
              (radio) => WiFiItem.fromRadio(radio,
                  numOfDevices:
                      deviceManagerState.mainWifiDevices.where((device) {
                    final deviceBand = ref
                        .read(deviceManagerProvider.notifier)
                        .getBandConnectedBy(device);
                    return device.isOnline() && deviceBand == radio.band;
                  }).length),
            )
            .toList() ??
        [];
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

    final availableSecurityTypeList =
        getSimpleModeAvailableSecurityTypeList(wifiItems);
    final firstEnabledWifi =
        wifiItems.firstWhereOrNull((e) => e.isEnabled) ?? wifiItems.first;

    final isSimpleMode = wifiItems.every((wifi) =>
        wifi.isEnabled == firstEnabledWifi.isEnabled &&
        wifi.ssid == firstEnabledWifi.ssid &&
        wifi.password == firstEnabledWifi.password &&
        wifi.securityType == firstEnabledWifi.securityType);
    final simpleModeWifi = firstEnabledWifi.copyWith(
      securityType: getSimpleModeAvailableSecurityType(
          firstEnabledWifi.securityType, availableSecurityTypeList),
      availableSecurityTypes: availableSecurityTypeList,
    );

    final wifiListSettings = WiFiListSettings(
        mainWiFi: wifiItems,
        guestWiFi: guestWiFi,
        isSimpleMode: isSimpleMode,
        simpleModeWifi: simpleModeWifi);
    final wifiListStatus = WiFiListStatus(
        canDisableMainWiFi: homeState.lanPortConnections.isNotEmpty);

    final topologyData = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getTopologyOptimizationSettings, resultMap);
    final iptvData = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getIptvSettings, resultMap);
    final mloData = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getMLOSettings, resultMap);
    final dfsData = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getDFSSettings, resultMap);
    final airtimeData = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getAirtimeFairnessSettings, resultMap);

    final advancedSettings = WifiAdvancedSettingsState(
      isClientSteeringEnabled: topologyData?.output['isClientSteeringEnabled'],
      isNodesSteeringEnabled: topologyData?.output['isNodeSteeringEnabled'],
      isIptvEnabled: iptvData?.output['isEnabled'],
      isMLOEnabled: (mloData?.output['isMLOSupported'] ?? false)
          ? mloData?.output['isMLOEnabled']
          : null,
      isDFSEnabled: (dfsData?.output['isDFSSupported'] ?? false)
          ? dfsData?.output['isDFSEnabled']
          : null,
      isAirtimeFairnessEnabled:
          (airtimeData?.output['isAirtimeFairnessSupported'] ?? false)
              ? airtimeData?.output['isAirtimeFairnessEnabled']
              : null,
    );

    final macFilterJson = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getMACFilterSettings, resultMap);
    final macFilterSettings = MACFilterSettings.fromMap(macFilterJson!.output);
    final staBssidsJson = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getSTABSSIDs, resultMap);
    final staBSSIDS = staBssidsJson != null
        ? List<String>.from(staBssidsJson.output['staBSSIDS'])
        : <String>[];
    final mode = MacFilterMode.reslove(macFilterSettings.macFilterMode);
    final macAddresses =
        macFilterSettings.macAddresses.map((e) => e.toUpperCase()).toList();

    final privacySettings = InstantPrivacySettings(
      mode: mode,
      macAddresses: mode == MacFilterMode.allow ? macAddresses : [],
      denyMacAddresses: mode == MacFilterMode.deny ? macAddresses : [],
      maxMacAddresses: macFilterSettings.maxMACAddresses,
      bssids: staBSSIDS.map((e) => e.toUpperCase()).toList(),
      myMac: myMac,
    );
    final privacyStatus = InstantPrivacyStatus(mode: mode);

    final bundleSettings = WifiBundleSettings(
      wifiList: wifiListSettings,
      advanced: advancedSettings,
      privacy: privacySettings,
    );

    final bundleStatus = WifiBundleStatus(
      wifiList: wifiListStatus,
      privacy: privacyStatus,
    );

    return (bundleSettings, bundleStatus);
  }

  Future<String?> _getMyMACAddress() {
    final repo = ref.read(routerRepositoryProvider);
    return repo
        .send(JNAPAction.getLocalDevice, auth: true, fetchRemote: true)
        .then((result) {
      final deviceID = result.output['deviceID'];
      return ref
          .read(deviceManagerProvider)
          .deviceList
          .firstWhereOrNull((device) => device.deviceID == deviceID)
          ?.getMacAddress();
    }).onError((_, __) {
      return null;
    });
  }

  @override
  Future<(WifiBundleSettings?, WifiBundleStatus?)> performFetch(
      {bool forceRemote = false, bool updateStatusOnly = false}) async {
    final (newSettings, newStatus) = await _fetchData(forceRemote: forceRemote);
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
      futures.add(_saveWifiList(repo, current.wifiList));
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

  Future<void> _saveWifiList(
      RouterRepository repo, WiFiListSettings settings) async {
    final isSupportGuestWiFi = serviceHelper.isSupportGuestNetwork();

    final radioSettings = (settings.isSimpleMode
            ? settings.getMainWifiItemsWithSimpleSettings()
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

    final newSettings = SetRadioSettings(radios: radioSettings);

    SetGuestRadioSettings? newSetGuestRadioSettings;
    if (isSupportGuestWiFi) {
      final guestRadioInfo = await repo
          .send(JNAPAction.getGuestRadioSettings, fetchRemote: true, auth: true)
          .then((response) => GuestRadioSettings.fromMap(response.output));
      final setGuestRadioSettings =
          SetGuestRadioSettings.fromGuestRadioSettings(guestRadioInfo);
      final newGuestRadios = setGuestRadioSettings.radios
          .map(
            (e) => e.copyWith(
              isEnabled: settings.mainWiFi
                      .firstWhereOrNull(
                          (mainRadio) => e.radioID == mainRadio.radioID.value)
                      ?.isEnabled ??
                  settings.guestWiFi.isEnabled,
              guestSSID: settings.guestWiFi.ssid,
              guestWPAPassphrase: settings.guestWiFi.password,
              canEnableRadio: settings.guestWiFi.isEnabled,
            ),
          )
          .toList();
      newSetGuestRadioSettings = setGuestRadioSettings.copyWith(
          isGuestNetworkEnabled: settings.guestWiFi.isEnabled,
          radios: newGuestRadios);
    }

    final builder = JNAPTransactionBuilder(auth: true, commands: [
      MapEntry(JNAPAction.setRadioSettings, newSettings.toMap()),
      if (isSupportGuestWiFi)
        MapEntry(JNAPAction.setGuestRadioSettings,
            newSetGuestRadioSettings?.toMap() ?? {}),
    ]);

    await repo.transaction(builder,
        fetchRemote: true, cacheLevel: CacheLevel.noCache);
  }

  Future<void> _saveAdvancedSettings(
      RouterRepository repo, WifiAdvancedSettingsState settings) {
    List<MapEntry<JNAPAction, Map<String, dynamic>>> commands = [];
    if (serviceHelper.isSupportTopologyOptimization()) {
      commands.add(MapEntry(
          JNAPAction.setTopologyOptimizationSettings,
          {
            'isClientSteeringEnabled': settings.isClientSteeringEnabled,
            'isNodeSteeringEnabled': settings.isNodesSteeringEnabled,
          }..removeWhere((key, value) => value == null)));
    }
    if (serviceHelper.isSupportIPTv()) {
      commands.add(
        MapEntry(
            JNAPAction.setIptvSettings, {'isEnabled': settings.isIptvEnabled}),
      );
    }
    if (serviceHelper.isSupportMLO() && settings.isMLOEnabled != null) {
      commands.add(
        MapEntry(
            JNAPAction.setMLOSettings, {'isMLOEnabled': settings.isMLOEnabled}),
      );
    }
    if (serviceHelper.isSupportDFS() && settings.isDFSEnabled != null) {
      commands.add(
        MapEntry(
            JNAPAction.setDFSSettings, {'isDFSEnabled': settings.isDFSEnabled}),
      );
    }
    if (serviceHelper.isSupportAirtimeFairness() &&
        settings.isAirtimeFairnessEnabled != null) {
      commands.add(
        MapEntry(JNAPAction.setAirtimeFairnessSettings,
            {'isAirtimeFairnessEnabled': settings.isAirtimeFairnessEnabled}),
      );
    }

    final builder = JNAPTransactionBuilder(auth: true, commands: commands);
    return repo.transaction(builder);
  }

  Future<void> _savePrivacySettings(
      RouterRepository repo, InstantPrivacySettings settings) {
    var macAddresses = <String>[];
    if (settings.mode == MacFilterMode.allow) {
      final nodesMacAddresses = ref
          .read(deviceManagerProvider)
          .nodeDevices
          .map((e) => e.getMacAddress().toUpperCase())
          .toList();
      macAddresses = [
        ...settings.macAddresses,
        ...nodesMacAddresses,
        ...settings.bssids,
      ].unique();
    } else if (settings.mode == MacFilterMode.deny) {
      macAddresses = [
        ...settings.denyMacAddresses,
      ];
    }
    return repo.send(
      JNAPAction.setMACFilterSettings,
      data: {
        'macFilterMode': settings.mode.name.capitalize(),
        'macAddresses': macAddresses,
      },
      auth: true,
      fetchRemote: true,
      cacheLevel: CacheLevel.noCache,
    );
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

  @visibleForTesting
  WifiSecurityType getSimpleModeAvailableSecurityType(
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

  @visibleForTesting
  List<WifiSecurityType> getSimpleModeAvailableSecurityTypeList(
      List<WiFiItem> wifiList) {
    return wifiList.isEmpty
        ? <WifiSecurityType>[]
        : wifiList
            .map((e) => e.availableSecurityTypes.toSet())
            .reduce((value, element) => value.intersection(element))
            .toList();
  }
}
