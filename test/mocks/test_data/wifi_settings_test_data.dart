import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/generated/wi_fi_access_points.g.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_network_ui_model.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_quick_setup_network.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_settings_settings.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_settings_status.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';

/// Test data builder for WiFi Settings tests.
///
/// Provides factory methods to create codegen models, UI models, and
/// composed state objects with sensible defaults.
class WifiSettingsTestData {
  // ---------------------------------------------------------------------------
  // Codegen models
  // ---------------------------------------------------------------------------

  static WiFiSsid createSsid({
    String instancePath = 'Device.WiFi.SSID.1.',
    String ssid = 'TestNetwork',
    bool enable = true,
    String lowerLayers = 'Device.WiFi.Radio.1.',
    String? alias,
  }) =>
      WiFiSsid(
        instancePath: instancePath,
        ssid: ssid,
        enable: enable,
        status: enable ? 'Up' : 'Down',
        bssid: 'AA:BB:CC:DD:EE:FF',
        lowerLayers: lowerLayers,
        alias: alias,
      );

  static WiFiAccessPoint createAccessPoint({
    String instancePath = 'Device.WiFi.AccessPoint.1.',
    String modesSupported = 'None,WPA2-Personal,WPA3-Personal',
    String securityModeEnabled = 'WPA2-Personal',
    String keyPassphrase = 'password123',
    bool ssidAdvertisementEnabled = true,
    String ssidReference = 'Device.WiFi.SSID.1.',
  }) =>
      WiFiAccessPoint(
        instancePath: instancePath,
        enable: true,
        status: 'Enabled',
        modesSupported: modesSupported,
        securityModeEnabled: securityModeEnabled,
        encryptionMode: 'AES',
        keyPassphrase: keyPassphrase,
        ssidAdvertisementEnabled: ssidAdvertisementEnabled,
        ssidReference: ssidReference,
      );

  static WiFiRadio createRadio({
    String instancePath = 'Device.WiFi.Radio.1.',
    String operatingFrequencyBand = '2.4GHz',
    int channel = 6,
    String operatingChannelBandwidth = '20MHz',
    String possibleChannels = '1,6,11',
    String operatingStandards = 'n',
    String supportedStandards = 'b,g,n',
    bool autoChannelEnable = true,
    String supportedOperatingChannelBandwidths = 'Auto,20MHz,40MHz',
  }) =>
      WiFiRadio(
        instancePath: instancePath,
        enable: true,
        status: 'Up',
        channel: channel,
        operatingFrequencyBand: operatingFrequencyBand,
        operatingChannelBandwidth: operatingChannelBandwidth,
        possibleChannels: possibleChannels,
        operatingStandards: operatingStandards,
        supportedStandards: supportedStandards,
        transmitPower: 100,
        maxBitRate: 300,
        autoChannelEnable: autoChannelEnable,
        ieee80211hEnabled: false,
        supportedOperatingChannelBandwidths:
            supportedOperatingChannelBandwidths,
      );

  // ---------------------------------------------------------------------------
  // Codegen collections
  // ---------------------------------------------------------------------------

  /// Typical dual-band + guest setup: 2.4 GHz + 5 GHz + guest.
  ///
  /// Guest is identified by the canonical `-guest` alias suffix (see
  /// wifi_guest_detection), matching firmware auto-provisioned aliases.
  static WiFiSsids createSsids() => WiFiSsids(items: [
        createSsid(
          instancePath: 'Device.WiFi.SSID.1.',
          ssid: 'Home',
          lowerLayers: 'Device.WiFi.Radio.1.',
          alias: 'wifi-2g',
        ),
        createSsid(
          instancePath: 'Device.WiFi.SSID.2.',
          ssid: 'Home',
          lowerLayers: 'Device.WiFi.Radio.2.',
          alias: 'wifi-5g',
        ),
        createSsid(
          instancePath: 'Device.WiFi.SSID.3.',
          ssid: 'Home-Guest',
          lowerLayers: 'Device.WiFi.Radio.1.',
          alias: 'wifi-2g-guest',
        ),
      ]);

  static WiFiAccessPoints createAccessPoints() => WiFiAccessPoints(items: [
        createAccessPoint(
          instancePath: 'Device.WiFi.AccessPoint.1.',
          ssidReference: 'Device.WiFi.SSID.1.',
        ),
        createAccessPoint(
          instancePath: 'Device.WiFi.AccessPoint.2.',
          ssidReference: 'Device.WiFi.SSID.2.',
          modesSupported: 'WPA2-Personal,WPA3-Personal',
          securityModeEnabled: 'WPA3-Personal',
        ),
        createAccessPoint(
          instancePath: 'Device.WiFi.AccessPoint.3.',
          ssidReference: 'Device.WiFi.SSID.3.',
        ),
      ]);

  static WiFiRadios createRadios() => WiFiRadios(items: [
        createRadio(
          instancePath: 'Device.WiFi.Radio.1.',
          operatingFrequencyBand: '2.4GHz',
          channel: 6,
          possibleChannels: '1,6,11',
          supportedOperatingChannelBandwidths: 'Auto,20MHz,40MHz',
        ),
        createRadio(
          instancePath: 'Device.WiFi.Radio.2.',
          operatingFrequencyBand: '5GHz',
          channel: 36,
          operatingChannelBandwidth: '80MHz',
          possibleChannels: '36,40,44,48',
          operatingStandards: 'ax',
          supportedStandards: 'a,n,ac,ax',
          autoChannelEnable: false,
          supportedOperatingChannelBandwidths: 'Auto,20MHz,40MHz,80MHz',
        ),
      ]);

  // ---------------------------------------------------------------------------
  // Tri-band codegen collections (2.4 GHz + 5 GHz + 6 GHz, each with guest)
  // ---------------------------------------------------------------------------

  static WiFiSsids createTriBandSsids() => WiFiSsids(items: [
        createSsid(
          instancePath: 'Device.WiFi.SSID.1.',
          ssid: 'Home',
          lowerLayers: 'Device.WiFi.Radio.1.',
          alias: 'wifi-2g',
        ),
        createSsid(
          instancePath: 'Device.WiFi.SSID.2.',
          ssid: 'Home',
          lowerLayers: 'Device.WiFi.Radio.2.',
          alias: 'wifi-5g',
        ),
        createSsid(
          instancePath: 'Device.WiFi.SSID.3.',
          ssid: 'Home',
          lowerLayers: 'Device.WiFi.Radio.3.',
          alias: 'wifi-6g',
        ),
        createSsid(
          instancePath: 'Device.WiFi.SSID.4.',
          ssid: 'Home-Guest',
          enable: false,
          lowerLayers: 'Device.WiFi.Radio.1.',
          alias: 'wifi-2g-guest',
        ),
        createSsid(
          instancePath: 'Device.WiFi.SSID.5.',
          ssid: 'Home-Guest',
          enable: false,
          lowerLayers: 'Device.WiFi.Radio.2.',
          alias: 'wifi-5g-guest',
        ),
        createSsid(
          instancePath: 'Device.WiFi.SSID.6.',
          ssid: 'Home-Guest',
          enable: false,
          lowerLayers: 'Device.WiFi.Radio.3.',
          alias: 'wifi-6g-guest',
        ),
      ]);

  static WiFiAccessPoints createTriBandAccessPoints() =>
      WiFiAccessPoints(items: [
        createAccessPoint(
          instancePath: 'Device.WiFi.AccessPoint.1.',
          ssidReference: 'Device.WiFi.SSID.1.',
        ),
        createAccessPoint(
          instancePath: 'Device.WiFi.AccessPoint.2.',
          ssidReference: 'Device.WiFi.SSID.2.',
          modesSupported: 'WPA2-Personal,WPA3-Personal',
          securityModeEnabled: 'WPA3-Personal',
        ),
        createAccessPoint(
          instancePath: 'Device.WiFi.AccessPoint.3.',
          ssidReference: 'Device.WiFi.SSID.3.',
          modesSupported: 'WPA3-Personal',
          securityModeEnabled: 'WPA3-Personal',
        ),
        createAccessPoint(
          instancePath: 'Device.WiFi.AccessPoint.4.',
          ssidReference: 'Device.WiFi.SSID.4.',
        ),
        createAccessPoint(
          instancePath: 'Device.WiFi.AccessPoint.5.',
          ssidReference: 'Device.WiFi.SSID.5.',
          modesSupported: 'WPA2-Personal,WPA3-Personal',
          securityModeEnabled: 'WPA3-Personal',
        ),
        createAccessPoint(
          instancePath: 'Device.WiFi.AccessPoint.6.',
          ssidReference: 'Device.WiFi.SSID.6.',
          modesSupported: 'WPA3-Personal',
          securityModeEnabled: 'WPA3-Personal',
        ),
      ]);

  static WiFiRadios createTriBandRadios() => WiFiRadios(items: [
        createRadio(
          instancePath: 'Device.WiFi.Radio.1.',
          operatingFrequencyBand: '2.4GHz',
          channel: 6,
          possibleChannels: '1,6,11',
          supportedOperatingChannelBandwidths: 'Auto,20MHz,40MHz',
        ),
        createRadio(
          instancePath: 'Device.WiFi.Radio.2.',
          operatingFrequencyBand: '5GHz',
          channel: 36,
          operatingChannelBandwidth: '80MHz',
          possibleChannels: '36,40,44,48',
          operatingStandards: 'ax',
          supportedStandards: 'a,n,ac,ax',
          autoChannelEnable: false,
          supportedOperatingChannelBandwidths: 'Auto,20MHz,40MHz,80MHz',
        ),
        createRadio(
          instancePath: 'Device.WiFi.Radio.3.',
          operatingFrequencyBand: '6GHz',
          channel: 1,
          operatingChannelBandwidth: '160MHz',
          possibleChannels: '1,5,9,13,17,21,25,29',
          operatingStandards: 'ax',
          supportedStandards: 'ax',
          autoChannelEnable: true,
          supportedOperatingChannelBandwidths: 'Auto,20MHz,40MHz,80MHz,160MHz',
        ),
      ]);

  static WifiData createTriBandWifiData() => WifiData(
        codegenContext: WifiCodegenContext(
          createTriBandRadios(),
          createTriBandSsids(),
          createTriBandAccessPoints(),
        ),
      );

  // ---------------------------------------------------------------------------
  // UI models
  // ---------------------------------------------------------------------------

  static WifiNetworkUIModel createNetworkUIModel({
    String ssidInstancePath = 'Device.WiFi.SSID.1.',
    String? accessPointInstancePath = 'Device.WiFi.AccessPoint.1.',
    String? radioInstancePath = 'Device.WiFi.Radio.1.',
    String ssid = 'Home',
    bool enabled = true,
    bool ssidAdvertisementEnabled = true,
    List<String> supportedSecurityModes = const [
      'None',
      'WPA2-Personal',
      'WPA3-Personal'
    ],
    String securityMode = 'WPA2-Personal',
    String keyPassphrase = 'password123',
    bool isGuest = false,
    String band = '2.4GHz',
    int channel = 6,
    String channelBandwidth = '20MHz',
    bool autoChannelEnable = true,
    List<int> possibleChannels = const [1, 6, 11],
    String operatingStandards = 'n',
    String supportedStandards = 'b,g,n',
    List<String> supportedBandwidths = const ['Auto', '20MHz', '40MHz'],
    Map<String, List<int>> availableChannelsPerBandwidth = const {},
  }) =>
      WifiNetworkUIModel(
        ssidInstancePath: ssidInstancePath,
        accessPointInstancePath: accessPointInstancePath,
        radioInstancePath: radioInstancePath,
        ssid: ssid,
        enabled: enabled,
        ssidAdvertisementEnabled: ssidAdvertisementEnabled,
        supportedSecurityModes: supportedSecurityModes,
        securityMode: securityMode,
        keyPassphrase: keyPassphrase,
        isGuest: isGuest,
        band: band,
        channel: channel,
        channelBandwidth: channelBandwidth,
        autoChannelEnable: autoChannelEnable,
        possibleChannels: possibleChannels,
        operatingStandards: operatingStandards,
        supportedStandards: supportedStandards,
        supportedBandwidths: supportedBandwidths,
        availableChannelsPerBandwidth: availableChannelsPerBandwidth,
      );

  /// Standard dual-band networks list (2.4 GHz main + 5 GHz main + guest).
  static List<WifiNetworkUIModel> createNetworks() => [
        createNetworkUIModel(
          ssidInstancePath: 'Device.WiFi.SSID.1.',
          accessPointInstancePath: 'Device.WiFi.AccessPoint.1.',
          radioInstancePath: 'Device.WiFi.Radio.1.',
          ssid: 'Home',
          band: '2.4GHz',
        ),
        createNetworkUIModel(
          ssidInstancePath: 'Device.WiFi.SSID.2.',
          accessPointInstancePath: 'Device.WiFi.AccessPoint.2.',
          radioInstancePath: 'Device.WiFi.Radio.2.',
          ssid: 'Home',
          band: '5GHz',
          channel: 36,
          channelBandwidth: '80MHz',
          autoChannelEnable: false,
          securityMode: 'WPA3-Personal',
          supportedSecurityModes: const ['WPA2-Personal', 'WPA3-Personal'],
          supportedBandwidths: const ['Auto', '20MHz', '40MHz', '80MHz'],
        ),
        createNetworkUIModel(
          ssidInstancePath: 'Device.WiFi.SSID.3.',
          accessPointInstancePath: 'Device.WiFi.AccessPoint.3.',
          radioInstancePath: 'Device.WiFi.Radio.1.',
          ssid: 'Home-Guest',
          isGuest: true,
        ),
      ];

  // ---------------------------------------------------------------------------
  // Quick Setup aggregates
  // ---------------------------------------------------------------------------

  static WifiQuickSetupNetwork createQuickSetupAggregate({
    bool isGuest = false,
    String ssid = 'Home',
    String securityMode = 'WPA2-Personal',
    String keyPassphrase = 'password123',
    List<String> supportedSecurityModes = const [
      'WPA2-Personal',
      'WPA3-Personal'
    ],
    List<String> ssidInstancePaths = const [
      'Device.WiFi.SSID.1.',
      'Device.WiFi.SSID.2.'
    ],
    List<String> apInstancePaths = const [
      'Device.WiFi.AccessPoint.1.',
      'Device.WiFi.AccessPoint.2.'
    ],
  }) =>
      WifiQuickSetupNetwork(
        isGuest: isGuest,
        ssid: ssid,
        securityMode: securityMode,
        keyPassphrase: keyPassphrase,
        supportedSecurityModes: supportedSecurityModes,
        ssidInstancePaths: ssidInstancePaths,
        apInstancePaths: apInstancePaths,
      );

  // ---------------------------------------------------------------------------
  // Settings & Status
  // ---------------------------------------------------------------------------

  static WifiSettingsSettings createSettings({
    List<WifiNetworkUIModel>? networks,
    bool quickSetupEnabled = false,
    WifiQuickSetupSettings? quickSetupMain,
    WifiQuickSetupSettings? quickSetupGuest,
  }) =>
      WifiSettingsSettings(
        networks: networks ?? createNetworks(),
        quickSetupEnabled: quickSetupEnabled,
        quickSetupMain: quickSetupMain,
        quickSetupGuest: quickSetupGuest,
      );

  static WifiSettingsStatus createStatus({
    bool isLoading = false,
    bool isSaving = false,
    ServiceError? error,
    WifiQuickSetupNetwork? quickSetupMainAggregate,
    WifiQuickSetupNetwork? quickSetupGuestAggregate,
  }) =>
      WifiSettingsStatus(
        isLoading: isLoading,
        isSaving: isSaving,
        error: error,
        quickSetupMainAggregate: quickSetupMainAggregate,
        quickSetupGuestAggregate: quickSetupGuestAggregate,
      );

  // ---------------------------------------------------------------------------
  // WifiData (L1)
  // ---------------------------------------------------------------------------

  static WifiData createWifiData() => WifiData(
        codegenContext: WifiCodegenContext(
          createRadios(),
          createSsids(),
          createAccessPoints(),
        ),
      );
}
