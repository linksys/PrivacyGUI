import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_advanced_feature_state.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_advanced_settings.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_advanced_status.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_network_ui_model.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_quick_setup_network.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_settings_settings.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_settings_status.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_state.dart';

// ---------------------------------------------------------------------------
// Network models
// ---------------------------------------------------------------------------

const _main24 = WifiNetworkUIModel(
  ssidInstancePath: 'Device.WiFi.SSID.1.',
  accessPointInstancePath: 'Device.WiFi.AccessPoint.1.',
  radioInstancePath: 'Device.WiFi.Radio.1.',
  ssid: 'HomeNetwork',
  enabled: true,
  ssidAdvertisementEnabled: true,
  supportedSecurityModes: ['WPA2-Personal', 'WPA3-Personal', 'None'],
  securityMode: 'WPA2-Personal',
  keyPassphrase: '',
  isGuest: false,
  band: '2.4GHz',
  channel: 6,
  channelBandwidth: '20MHz',
  autoChannelEnable: false,
  possibleChannels: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
  operatingStandards: 'b,g,n,ax',
  supportedStandards: 'b,g,n,ax',
  supportedBandwidths: ['Auto', '20MHz', '40MHz'],
  availableChannelsPerBandwidth: {
    'Auto': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
    '20MHz': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
    '40MHz': [1, 2, 3, 4, 5, 6, 7, 8, 9],
  },
);

const _main5 = WifiNetworkUIModel(
  ssidInstancePath: 'Device.WiFi.SSID.2.',
  accessPointInstancePath: 'Device.WiFi.AccessPoint.2.',
  radioInstancePath: 'Device.WiFi.Radio.2.',
  ssid: 'HomeNetwork',
  enabled: true,
  ssidAdvertisementEnabled: true,
  supportedSecurityModes: ['WPA2-Personal', 'WPA3-Personal', 'None'],
  securityMode: 'WPA3-Personal',
  keyPassphrase: '',
  isGuest: false,
  band: '5GHz',
  channel: 36,
  channelBandwidth: '80MHz',
  autoChannelEnable: true,
  possibleChannels: [36, 40, 44, 48, 149, 153, 157, 161],
  operatingStandards: 'a,n,ac,ax',
  supportedStandards: 'a,n,ac,ax',
  supportedBandwidths: ['Auto', '20MHz', '40MHz', '80MHz', '160MHz'],
  availableChannelsPerBandwidth: {
    'Auto': [36, 40, 44, 48, 149, 153, 157, 161],
    '20MHz': [36, 40, 44, 48, 149, 153, 157, 161],
    '40MHz': [36, 44, 149, 157],
    '80MHz': [36, 149],
    '160MHz': [36],
  },
);

const _guest24 = WifiNetworkUIModel(
  ssidInstancePath: 'Device.WiFi.SSID.3.',
  accessPointInstancePath: 'Device.WiFi.AccessPoint.3.',
  radioInstancePath: 'Device.WiFi.Radio.1.',
  ssid: 'HomeNetwork-Guest',
  enabled: true,
  ssidAdvertisementEnabled: true,
  supportedSecurityModes: ['WPA2-Personal', 'None'],
  securityMode: 'WPA2-Personal',
  keyPassphrase: '',
  isGuest: true,
  band: '2.4GHz',
  channel: 6,
  channelBandwidth: '20MHz',
  autoChannelEnable: false,
  possibleChannels: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
  operatingStandards: 'b,g,n,ax',
  supportedStandards: 'b,g,n,ax',
  supportedBandwidths: ['Auto', '20MHz', '40MHz'],
);

const _guest5 = WifiNetworkUIModel(
  ssidInstancePath: 'Device.WiFi.SSID.4.',
  accessPointInstancePath: 'Device.WiFi.AccessPoint.4.',
  radioInstancePath: 'Device.WiFi.Radio.2.',
  ssid: 'HomeNetwork-Guest',
  enabled: false,
  ssidAdvertisementEnabled: true,
  supportedSecurityModes: ['WPA2-Personal', 'None'],
  securityMode: 'WPA2-Personal',
  keyPassphrase: '',
  isGuest: true,
  band: '5GHz',
  channel: 36,
  channelBandwidth: '80MHz',
  autoChannelEnable: true,
  possibleChannels: [36, 40, 44, 48, 149, 153, 157, 161],
  operatingStandards: 'a,n,ac,ax',
  supportedStandards: 'a,n,ac,ax',
  supportedBandwidths: ['Auto', '20MHz', '40MHz', '80MHz', '160MHz'],
);

const _testNetworks = [_main24, _main5, _guest24, _guest5];

// ---------------------------------------------------------------------------
// Quick Setup aggregates (status)
// ---------------------------------------------------------------------------

const _quickSetupMainAggregate = WifiQuickSetupNetwork(
  isGuest: false,
  ssid: 'HomeNetwork',
  securityMode: 'WPA2-Personal',
  keyPassphrase: '',
  supportedSecurityModes: ['WPA2-Personal', 'WPA3-Personal', 'None'],
  ssidInstancePaths: ['Device.WiFi.SSID.1.', 'Device.WiFi.SSID.2.'],
  apInstancePaths: ['Device.WiFi.AccessPoint.1.', 'Device.WiFi.AccessPoint.2.'],
);

const _quickSetupGuestAggregate = WifiQuickSetupNetwork(
  isGuest: true,
  ssid: 'HomeNetwork-Guest',
  securityMode: 'WPA2-Personal',
  keyPassphrase: '',
  supportedSecurityModes: ['WPA2-Personal', 'None'],
  ssidInstancePaths: ['Device.WiFi.SSID.3.', 'Device.WiFi.SSID.4.'],
  apInstancePaths: ['Device.WiFi.AccessPoint.3.', 'Device.WiFi.AccessPoint.4.'],
);

// ---------------------------------------------------------------------------
// WiFi Tab States
// ---------------------------------------------------------------------------

/// Quick Setup OFF — normal per-band network cards
final quickSetupOffState = UspWifiSettingsState(
  settings: Preservable(
    original: WifiSettingsSettings(
      networks: _testNetworks,
      quickSetupEnabled: false,
    ),
    current: WifiSettingsSettings(
      networks: _testNetworks,
      quickSetupEnabled: false,
    ),
  ),
  status: WifiSettingsStatus(
    quickSetupMainAggregate: _quickSetupMainAggregate,
    quickSetupGuestAggregate: _quickSetupGuestAggregate,
  ),
);

/// Quick Setup ON — Main + Guest aggregate cards
final quickSetupOnState = UspWifiSettingsState(
  settings: Preservable(
    original: WifiSettingsSettings(
      networks: _testNetworks,
      quickSetupEnabled: true,
      quickSetupMain: WifiQuickSetupSettings(
        isGuest: false,
        enabled: true,
        ssid: 'HomeNetwork',
        password: '',
        securityMode: 'WPA2-Personal',
        supportedSecurityModes: ['WPA2-Personal', 'WPA3-Personal', 'None'],
      ),
      quickSetupGuest: WifiQuickSetupSettings(
        isGuest: true,
        enabled: false,
        ssid: 'HomeNetwork-Guest',
        password: '',
        securityMode: 'WPA2-Personal',
        supportedSecurityModes: ['WPA2-Personal', 'None'],
      ),
    ),
    current: WifiSettingsSettings(
      networks: _testNetworks,
      quickSetupEnabled: true,
      quickSetupMain: WifiQuickSetupSettings(
        isGuest: false,
        enabled: true,
        ssid: 'HomeNetwork',
        password: '',
        securityMode: 'WPA2-Personal',
        supportedSecurityModes: ['WPA2-Personal', 'WPA3-Personal', 'None'],
      ),
      quickSetupGuest: WifiQuickSetupSettings(
        isGuest: true,
        enabled: false,
        ssid: 'HomeNetwork-Guest',
        password: '',
        securityMode: 'WPA2-Personal',
        supportedSecurityModes: ['WPA2-Personal', 'None'],
      ),
    ),
  ),
  status: WifiSettingsStatus(
    quickSetupMainAggregate: _quickSetupMainAggregate,
    quickSetupGuestAggregate: _quickSetupGuestAggregate,
  ),
);

/// Dirty state — SSID changed, showing Save/Cancel bottom bar
final editDirtyState = UspWifiSettingsState(
  settings: Preservable(
    original: WifiSettingsSettings(
      networks: _testNetworks,
      quickSetupEnabled: false,
    ),
    current: WifiSettingsSettings(
      networks: [
        _main24.copyWith(ssid: 'MyNewNetwork'),
        _main5.copyWith(ssid: 'MyNewNetwork-5G'),
        _guest24,
        _guest5,
      ],
      quickSetupEnabled: false,
    ),
  ),
  status: WifiSettingsStatus(
    quickSetupMainAggregate: _quickSetupMainAggregate,
    quickSetupGuestAggregate: _quickSetupGuestAggregate,
  ),
);

// ---------------------------------------------------------------------------
// Advanced Tab States
// ---------------------------------------------------------------------------

/// DFS enabled on all radios
final advancedDfsOnState = WifiAdvancedFeatureState(
  settings: Preservable(
    original: WifiAdvancedSettings(ieee80211hByRadio: {
      'Device.WiFi.Radio.1.': true,
      'Device.WiFi.Radio.2.': true,
    }),
    current: WifiAdvancedSettings(ieee80211hByRadio: {
      'Device.WiFi.Radio.1.': true,
      'Device.WiFi.Radio.2.': true,
    }),
  ),
  status: const WifiAdvancedStatus(),
);

/// DFS disabled on all radios
final advancedDfsOffState = WifiAdvancedFeatureState(
  settings: Preservable(
    original: WifiAdvancedSettings(ieee80211hByRadio: {
      'Device.WiFi.Radio.1.': false,
      'Device.WiFi.Radio.2.': false,
    }),
    current: WifiAdvancedSettings(ieee80211hByRadio: {
      'Device.WiFi.Radio.1.': false,
      'Device.WiFi.Radio.2.': false,
    }),
  ),
  status: const WifiAdvancedStatus(),
);

/// Advanced tab dirty — DFS was off, user toggled on
final advancedDirtyState = WifiAdvancedFeatureState(
  settings: Preservable(
    original: WifiAdvancedSettings(ieee80211hByRadio: {
      'Device.WiFi.Radio.1.': false,
      'Device.WiFi.Radio.2.': false,
    }),
    current: WifiAdvancedSettings(ieee80211hByRadio: {
      'Device.WiFi.Radio.1.': true,
      'Device.WiFi.Radio.2.': true,
    }),
  ),
  status: const WifiAdvancedStatus(),
);

// ---------------------------------------------------------------------------
// Default (non-dirty) advanced state used as companion for WiFi tab tests
// ---------------------------------------------------------------------------

final defaultAdvancedState = advancedDfsOnState;
