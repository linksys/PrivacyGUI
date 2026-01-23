import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
import 'package:privacy_gui/core/data/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/models/mac_filter_settings.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/core/models/device_list_item.dart';
import 'package:privacy_gui/core/models/privacy_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/guest_wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_advanced_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/page/wifi_settings/services/wifi_settings_mapper.dart';
import 'package:privacy_gui/util/extensions.dart';

final wifiSettingsServiceProvider = Provider((ref) {
  return WifiSettingsService(ref.watch(routerRepositoryProvider));
});

class WifiSettingsService {
  final RouterRepository _repo;

  WifiSettingsService(this._repo);

  /// Creates initial WiFiListSettings from dashboard state data.
  ///
  /// Used by WifiBundleNotifier.build() to initialize state without
  /// requiring JNAP imports in the provider layer.
  WiFiListSettings createInitialWifiListSettings({
    required List<RouterRadio> mainRadios,
    required bool isGuestNetworkEnabled,
    required String? guestSSID,
    required String? guestPassword,
    required List<LinksysDevice> mainWifiDevices,
    required int guestWifiDevicesCount,
    required String? Function(LinksysDevice) getBandConnectedBy,
  }) {
    final wifiItems = mainRadios
        .map(
          (radio) => WifiSettingsMapper.fromRadio(radio,
              numOfDevices: mainWifiDevices.where((device) {
                final deviceBand = getBandConnectedBy(device);
                return device.isOnline() && deviceBand == radio.band;
              }).length),
        )
        .toList();

    final guestWiFi = GuestWiFiItem(
      isEnabled: isGuestNetworkEnabled,
      ssid: guestSSID ?? '',
      password: guestPassword ?? '',
      numOfDevices: guestWifiDevicesCount,
    );

    final simpleModeWifi = wifiItems.firstWhereOrNull((e) => e.isEnabled) ??
        (wifiItems.isNotEmpty
            ? wifiItems.first
            : WiFiItem.fromMap(const {
                'channel': 0,
                'isBroadcast': false,
                'isEnabled': false,
                'numOfDevices': 0,
              }));

    return WiFiListSettings(
      mainWiFi: wifiItems,
      guestWiFi: guestWiFi,
      isSimpleMode: true, // Default to simple mode
      simpleModeWifi: simpleModeWifi,
    );
  }

  Future<void> saveWifiListSettings(
      WiFiListSettings settings, bool isSupportGuestWiFi) async {
    final setRadioSettings = WifiSettingsMapper.toSetRadioSettings(settings);

    SetGuestRadioSettings? newSetGuestRadioSettings;
    if (isSupportGuestWiFi) {
      final guestRadioInfo = await _repo
          .send(JNAPAction.getGuestRadioSettings, fetchRemote: true, auth: true)
          .then((response) => GuestRadioSettings.fromMap(response.output));

      newSetGuestRadioSettings = WifiSettingsMapper.mergeGuestSettings(
          guestRadioInfo, settings.guestWiFi, settings.mainWiFi);
    }

    final builder = JNAPTransactionBuilder(auth: true, commands: [
      MapEntry(JNAPAction.setRadioSettings, setRadioSettings.toMap()),
      if (isSupportGuestWiFi)
        MapEntry(JNAPAction.setGuestRadioSettings,
            newSetGuestRadioSettings?.toMap() ?? {}),
    ]);

    await _repo.transaction(builder,
        fetchRemote: true, cacheLevel: CacheLevel.noCache);
  }

  Future<(WifiBundleSettings, WifiBundleStatus)> fetchBundleSettings({
    required ServiceHelper serviceHelper,
    bool forceRemote = false,
    required List<LinksysDevice> mainWifiDevices,
    required List<LinksysDevice> guestWifiDevices,
    required List<LinksysDevice> allDevices,
    required bool isLanConnected,
    required String? Function(LinksysDevice) getBandConnectedBy,
  }) async {
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
        _repo.transaction(transaction, fetchRemote: forceRemote);
    final myMacFuture = _getMyMACAddress(allDevices);

    final results = await Future.wait([transactionResultFuture, myMacFuture]);
    final transactionResult = results[0] as JNAPTransactionSuccessWrap;
    final myMac = results[1] as String?;
    final resultMap = Map.fromEntries(transactionResult.data);

    final radioInfoJson = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getRadioInfo, resultMap);
    final radioInfo = radioInfoJson != null
        ? GetRadioInfo.fromMap(radioInfoJson.output)
        : null;
    final wifiItems = radioInfo?.radios
            .map(
              (radio) => WifiSettingsMapper.fromRadio(radio,
                  numOfDevices: mainWifiDevices.where((device) {
                    final deviceBand = getBandConnectedBy(device);
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
      numOfDevices: guestWifiDevices.length,
    );

    // Use 2.4G band for primary security type list
    final wifiForSecurityList = wifiItems.isEmpty
        ? WifiSettingsMapper.fromRadio(
            RouterRadio.fromMap(const {
              'radioID': 'RADIO_2.4GHz',
              'physicalRadioID': '1',
              'band': '2.4GHz',
              'bssid': '00:00:00:00:00:00',
              'supportedModes': ['802.11mixed'],
              'supportedChannelsForChannelWidths': [],
              'supportedSecurityTypes': ['None'],
              'maxRADIUSSharedKeyLength': 64,
              'ssid': 'Main',
              'settings': {
                'ssid': 'Main',
                'password': 'p',
                'security': 'None',
                'mode': '802.11mixed',
                'channelWidth': 'Auto',
                'channel': 1,
                'broadcastSSID': true,
                'isEnabled': true
              }
            }),
            numOfDevices: 0,
          )
        : wifiItems.firstWhere(
            (wifi) => wifi.radioID == WifiRadioBand.radio_24,
            orElse: () => wifiItems.first,
          );
    final availableSecurityTypeList =
        WifiSettingsMapper.getSimpleModeAvailableSecurityTypeList(
            [wifiForSecurityList]);
    final firstEnabledWifi = wifiItems.isEmpty
        ? WifiSettingsMapper.fromRadio(
            RouterRadio.fromMap(const {
              'radioID': 'RADIO_2.4GHz',
              'physicalRadioID': '1',
              'band': '2.4GHz',
              'bssid': '00:00:00:00:00:00',
              'supportedModes': ['802.11mixed'],
              'supportedChannelsForChannelWidths': [],
              'supportedSecurityTypes': ['None'],
              'maxRADIUSSharedKeyLength': 64,
              'ssid': 'Main',
              'settings': {
                'ssid': 'Main',
                'password': 'p',
                'security': 'None',
                'mode': '802.11mixed',
                'channelWidth': 'Auto',
                'channel': 1,
                'broadcastSSID': true,
                'isEnabled': true
              }
            }),
            numOfDevices: 0,
          )
        : (wifiItems.firstWhereOrNull((e) => e.isEnabled) ?? wifiItems.first);

    final isSimpleMode = wifiItems.isEmpty ||
        wifiItems.every((wifi) =>
            wifi.isEnabled == firstEnabledWifi.isEnabled &&
            wifi.ssid == firstEnabledWifi.ssid &&
            wifi.password == firstEnabledWifi.password);

    final simpleModeWifi = firstEnabledWifi.copyWith(
      securityType: WifiSettingsMapper.getSimpleModeAvailableSecurityType(
          firstEnabledWifi.securityType, availableSecurityTypeList),
      availableSecurityTypes: availableSecurityTypeList,
    );

    final wifiListSettings = WiFiListSettings(
        mainWiFi: wifiItems,
        guestWiFi: guestWiFi,
        isSimpleMode: isSimpleMode,
        simpleModeWifi: simpleModeWifi);
    final wifiListStatus = WiFiListStatus(canDisableMainWiFi: isLanConnected);

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
        ? List<String>.from(staBssidsJson.output['staBSSIDS'] ?? [])
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

  Future<String?> _getMyMACAddress(List<LinksysDevice> allDevices) {
    return _repo
        .send(JNAPAction.getLocalDevice, auth: true, fetchRemote: true)
        .then((result) {
      final deviceID = result.output['deviceID'];
      return allDevices
          .firstWhereOrNull((device) => device.deviceID == deviceID)
          ?.getMacAddress();
    }).onError((_, __) {
      return null;
    });
  }

  Future<void> saveAdvancedSettings({
    required WifiAdvancedSettingsState settings,
    required ServiceHelper serviceHelper,
  }) {
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
    return _repo.transaction(builder);
  }

  Future<void> savePrivacySettings({
    required InstantPrivacySettings settings,
    required List<LinksysDevice> nodeDevices,
  }) {
    var macAddresses = <String>[];
    if (settings.mode == MacFilterMode.allow) {
      final nodesMacAddresses =
          nodeDevices.map((e) => e.getMacAddress().toUpperCase()).toList();
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
    return _repo.send(
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

  List<DeviceListItem> getFilteredDeviceList({
    required List<DeviceListItem> allDevices,
    required List<String> macAddresses,
    required List<String> bssidList,
  }) {
    return (macAddresses.toSet())
        .difference(bssidList.toSet())
        .toList()
        .map((e) =>
            allDevices.firstWhereOrNull((device) => device.macAddress == e) ??
            DeviceListItem(macAddress: e, name: '--'))
        .toList();
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

  bool validateWifiListSettings(WiFiListSettings settings) {
    // Password verify
    if (settings.isSimpleMode) {
      final emptyPassword =
          !settings.simpleModeWifi.securityType.isOpenVariant &&
              settings.simpleModeWifi.password.isEmpty;
      return !emptyPassword;
    } else {
      final hasEmptyPassword = settings.mainWiFi
          .any((e) => !e.securityType.isOpenVariant && e.password.isEmpty);
      return !hasEmptyPassword;
    }
  }
}
