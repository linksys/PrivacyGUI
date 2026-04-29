import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/generated/wi_fi_access_points.g.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_network_ui_model.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_quick_setup_network.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_settings_settings.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_settings_status.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_settings_service.dart';

class MockUspClient extends Mock implements UspClient {}

// WASM v0.11.0 response helpers
Map<String, dynamic> uspSuccess({Map<String, dynamic> data = const {}}) => {
      'success': true,
      'result': {'data': data},
    };

Map<String, dynamic> uspFailure(
        {String path = 'bulk_operation',
        int errorCode = 7004,
        String errorMessage = 'Operation failed'}) =>
    {
      'success': false,
      'result': {
        'data': <String, dynamic>{},
        'error': {
          path: {
            'errorCode': errorCode,
            'errorMessage': errorMessage,
          }
        },
      },
    };

void main() {
  late UspWifiSettingsService svc;

  setUp(() {
    svc = UspWifiSettingsService(MockUspClient());
  });

  // -------------------------------------------------------------------------
  // buildWifiNetworks — supportedBandwidths & availableChannelsPerBandwidth
  // -------------------------------------------------------------------------

  group('buildWifiNetworks', () {
    test('populates supportedBandwidths from radio field', () {
      final ssids = WiFiSsids(items: [
        WiFiSsid(
          instancePath: 'Device.WiFi.SSID.1.',
          ssid: 'MyNetwork',
          enable: true,
          status: 'Up',
          bssid: 'AA:BB:CC:DD:EE:FF',
          lowerLayers: 'Device.WiFi.Radio.1.',
        ),
      ]);

      final accessPoints = WiFiAccessPoints(items: [
        WiFiAccessPoint(
          instancePath: 'Device.WiFi.AccessPoint.1.',
          enable: true,
          status: 'Enabled',
          modesSupported: 'None,WPA2-Personal,WPA3-Personal',
          securityModeEnabled: 'WPA2-Personal',
          encryptionMode: 'AES',
          keyPassphrase: 'test1234',
          ssidAdvertisementEnabled: true,
          ssidReference: 'Device.WiFi.SSID.1.',
        ),
      ]);

      final radios = WiFiRadios(items: [
        WiFiRadio(
          instancePath: 'Device.WiFi.Radio.1.',
          enable: true,
          status: 'Up',
          channel: 36,
          operatingFrequencyBand: '5GHz',
          operatingChannelBandwidth: '80MHz',
          possibleChannels: '36,40,44,48,52,56,60,64',
          operatingStandards: 'ax',
          supportedStandards: 'a,n,ac,ax',
          transmitPower: 100,
          maxBitRate: 2402,
          autoChannelEnable: true,
          ieee80211hEnabled: false,
          supportedOperatingChannelBandwidths: 'Auto,20MHz,40MHz,80MHz',
        ),
      ]);

      final networks = svc.buildWifiNetworks(
        ssids: ssids,
        accessPoints: accessPoints,
        radios: radios,
      );

      expect(networks, hasLength(1));
      final n = networks.first;

      // supportedBandwidths parsed from comma-separated string
      expect(n.supportedBandwidths, ['Auto', '20MHz', '40MHz', '80MHz']);
    });

    test('populates availableChannelsPerBandwidth with bonding rules', () {
      final ssids = WiFiSsids(items: [
        WiFiSsid(
          instancePath: 'Device.WiFi.SSID.1.',
          ssid: 'TestNet',
          enable: true,
          status: 'Up',
          bssid: 'AA:BB:CC:DD:EE:FF',
          lowerLayers: 'Device.WiFi.Radio.1.',
        ),
      ]);

      final accessPoints = WiFiAccessPoints(items: [
        WiFiAccessPoint(
          instancePath: 'Device.WiFi.AccessPoint.1.',
          enable: true,
          status: 'Enabled',
          modesSupported: 'WPA2-Personal',
          securityModeEnabled: 'WPA2-Personal',
          encryptionMode: 'AES',
          keyPassphrase: 'pass',
          ssidAdvertisementEnabled: true,
          ssidReference: 'Device.WiFi.SSID.1.',
        ),
      ]);

      final radios = WiFiRadios(items: [
        WiFiRadio(
          instancePath: 'Device.WiFi.Radio.1.',
          enable: true,
          status: 'Up',
          channel: 36,
          operatingFrequencyBand: '5GHz',
          operatingChannelBandwidth: '80MHz',
          possibleChannels: '36,40,44,48,52,56,60,64',
          operatingStandards: 'ax',
          supportedStandards: 'a,n,ac,ax',
          transmitPower: 100,
          maxBitRate: 2402,
          autoChannelEnable: false,
          ieee80211hEnabled: false,
          supportedOperatingChannelBandwidths: 'Auto,20MHz,40MHz,80MHz,160MHz',
        ),
      ]);

      final networks = svc.buildWifiNetworks(
        ssids: ssids,
        accessPoints: accessPoints,
        radios: radios,
      );

      final n = networks.first;
      final bwMap = n.availableChannelsPerBandwidth;

      // Auto → all channels
      expect(bwMap['Auto'], [36, 40, 44, 48, 52, 56, 60, 64]);

      // 20MHz → all channels
      expect(bwMap['20MHz'], [36, 40, 44, 48, 52, 56, 60, 64]);

      // 40MHz → valid pairs: (36,40), (44,48), (52,56), (60,64)
      expect(bwMap['40MHz'], [36, 40, 44, 48, 52, 56, 60, 64]);

      // 80MHz → valid groups: [36,40,44,48], [52,56,60,64]
      expect(bwMap['80MHz'], [36, 40, 44, 48, 52, 56, 60, 64]);

      // 160MHz → valid group: [36..64]
      expect(bwMap['160MHz'], [36, 40, 44, 48, 52, 56, 60, 64]);
    });

    test('empty supportedOperatingChannelBandwidths falls back to defaults',
        () {
      final ssids = WiFiSsids(items: [
        WiFiSsid(
          instancePath: 'Device.WiFi.SSID.1.',
          ssid: 'FallbackNet',
          enable: true,
          status: 'Up',
          bssid: '11:22:33:44:55:66',
          lowerLayers: 'Device.WiFi.Radio.1.',
        ),
      ]);

      final accessPoints = WiFiAccessPoints(items: [
        WiFiAccessPoint(
          instancePath: 'Device.WiFi.AccessPoint.1.',
          enable: true,
          status: 'Enabled',
          modesSupported: 'WPA2-Personal',
          securityModeEnabled: 'WPA2-Personal',
          encryptionMode: 'AES',
          keyPassphrase: 'pass',
          ssidAdvertisementEnabled: true,
          ssidReference: 'Device.WiFi.SSID.1.',
        ),
      ]);

      final radios = WiFiRadios(items: [
        WiFiRadio(
          instancePath: 'Device.WiFi.Radio.1.',
          enable: true,
          status: 'Up',
          channel: 6,
          operatingFrequencyBand: '2.4GHz',
          operatingChannelBandwidth: '20MHz',
          possibleChannels: '1,2,3,4,5,6,7,8,9,10,11',
          operatingStandards: 'n',
          supportedStandards: 'b,g,n',
          transmitPower: 100,
          maxBitRate: 300,
          autoChannelEnable: true,
          ieee80211hEnabled: false,
          supportedOperatingChannelBandwidths: '', // empty → fallback
        ),
      ]);

      final networks = svc.buildWifiNetworks(
        ssids: ssids,
        accessPoints: accessPoints,
        radios: radios,
      );

      final n = networks.first;

      // supportedBandwidths should be empty (raw value was empty)
      expect(n.supportedBandwidths, isEmpty);

      // But availableChannelsPerBandwidth should still be computed with defaults
      final bwMap = n.availableChannelsPerBandwidth;
      expect(bwMap.containsKey('Auto'), isTrue);
      expect(bwMap.containsKey('20MHz'), isTrue);
      expect(bwMap.containsKey('40MHz'), isTrue);
    });

    test('multi-band networks each get correct bonding', () {
      final ssids = WiFiSsids(items: [
        WiFiSsid(
          instancePath: 'Device.WiFi.SSID.1.',
          ssid: 'Home',
          enable: true,
          status: 'Up',
          bssid: 'AA:BB:CC:DD:EE:01',
          lowerLayers: 'Device.WiFi.Radio.1.',
        ),
        WiFiSsid(
          instancePath: 'Device.WiFi.SSID.2.',
          ssid: 'Home',
          enable: true,
          status: 'Up',
          bssid: 'AA:BB:CC:DD:EE:02',
          lowerLayers: 'Device.WiFi.Radio.2.',
        ),
      ]);

      final accessPoints = WiFiAccessPoints(items: [
        WiFiAccessPoint(
          instancePath: 'Device.WiFi.AccessPoint.1.',
          enable: true,
          status: 'Enabled',
          modesSupported: 'WPA2-Personal',
          securityModeEnabled: 'WPA2-Personal',
          encryptionMode: 'AES',
          keyPassphrase: 'pass',
          ssidAdvertisementEnabled: true,
          ssidReference: 'Device.WiFi.SSID.1.',
        ),
        WiFiAccessPoint(
          instancePath: 'Device.WiFi.AccessPoint.2.',
          enable: true,
          status: 'Enabled',
          modesSupported: 'WPA2-Personal,WPA3-Personal',
          securityModeEnabled: 'WPA3-Personal',
          encryptionMode: 'AES',
          keyPassphrase: 'pass',
          ssidAdvertisementEnabled: true,
          ssidReference: 'Device.WiFi.SSID.2.',
        ),
      ]);

      final radios = WiFiRadios(items: [
        WiFiRadio(
          instancePath: 'Device.WiFi.Radio.1.',
          enable: true,
          status: 'Up',
          channel: 6,
          operatingFrequencyBand: '2.4GHz',
          operatingChannelBandwidth: '20MHz',
          possibleChannels: '1,2,3,4,5,6,7,8,9,10,11',
          operatingStandards: 'n',
          supportedStandards: 'b,g,n',
          transmitPower: 100,
          maxBitRate: 300,
          autoChannelEnable: true,
          ieee80211hEnabled: false,
          supportedOperatingChannelBandwidths: 'Auto,20MHz,40MHz',
        ),
        WiFiRadio(
          instancePath: 'Device.WiFi.Radio.2.',
          enable: true,
          status: 'Up',
          channel: 36,
          operatingFrequencyBand: '5GHz',
          operatingChannelBandwidth: '80MHz',
          possibleChannels: '36,40,44,48',
          operatingStandards: 'ax',
          supportedStandards: 'a,n,ac,ax',
          transmitPower: 100,
          maxBitRate: 2402,
          autoChannelEnable: false,
          ieee80211hEnabled: false,
          supportedOperatingChannelBandwidths: 'Auto,20MHz,40MHz,80MHz',
        ),
      ]);

      final networks = svc.buildWifiNetworks(
        ssids: ssids,
        accessPoints: accessPoints,
        radios: radios,
      );

      expect(networks, hasLength(2));

      // 2.4 GHz network
      final n24 = networks[0];
      expect(n24.band, '2.4GHz');
      expect(n24.supportedBandwidths, ['Auto', '20MHz', '40MHz']);
      expect(n24.availableChannelsPerBandwidth['20MHz'],
          [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]);
      // 40MHz bonding: all channels 1-11 should be present
      // because pairs (1,5),(2,6),(3,7),...,(7,11) cover 1-11
      expect(n24.availableChannelsPerBandwidth['40MHz'], isNotEmpty);

      // 5 GHz network
      final n5 = networks[1];
      expect(n5.band, '5GHz');
      expect(n5.supportedBandwidths, ['Auto', '20MHz', '40MHz', '80MHz']);
      expect(n5.availableChannelsPerBandwidth['20MHz'], [36, 40, 44, 48]);
      expect(n5.availableChannelsPerBandwidth['40MHz'], [36, 40, 44, 48]);
      expect(n5.availableChannelsPerBandwidth['80MHz'], [36, 40, 44, 48]);
    });

    test('normalizes band strings correctly', () {
      final ssids = WiFiSsids(items: [
        WiFiSsid(
          instancePath: 'Device.WiFi.SSID.1.',
          ssid: 'Test6GHz',
          enable: true,
          status: 'Up',
          bssid: 'AA:BB:CC:DD:EE:FF',
          lowerLayers: 'Device.WiFi.Radio.1.',
        ),
      ]);

      final accessPoints = WiFiAccessPoints(items: [
        WiFiAccessPoint(
          instancePath: 'Device.WiFi.AccessPoint.1.',
          enable: true,
          status: 'Enabled',
          modesSupported: 'WPA3-Personal',
          securityModeEnabled: 'WPA3-Personal',
          encryptionMode: 'AES',
          keyPassphrase: 'pass',
          ssidAdvertisementEnabled: true,
          ssidReference: 'Device.WiFi.SSID.1.',
        ),
      ]);

      final radios = WiFiRadios(items: [
        WiFiRadio(
          instancePath: 'Device.WiFi.Radio.1.',
          enable: true,
          status: 'Up',
          channel: 1,
          operatingFrequencyBand: '6GHz', // already normalized
          operatingChannelBandwidth: '80MHz',
          possibleChannels: '1,5,9,13,17,21,25,29',
          operatingStandards: 'ax',
          supportedStandards: 'ax',
          transmitPower: 100,
          maxBitRate: 2402,
          autoChannelEnable: true,
          ieee80211hEnabled: false,
          supportedOperatingChannelBandwidths: 'Auto,20MHz,40MHz,80MHz,160MHz',
        ),
      ]);

      final networks = svc.buildWifiNetworks(
        ssids: ssids,
        accessPoints: accessPoints,
        radios: radios,
      );

      final n = networks.first;
      expect(n.band, '6GHz');

      // 6GHz bonding: [1,5,9,13,17,21,25,29] is a valid 160MHz group
      expect(n.availableChannelsPerBandwidth['160MHz'],
          [1, 5, 9, 13, 17, 21, 25, 29]);

      // 80MHz: [1,5,9,13] and [17,21,25,29]
      expect(n.availableChannelsPerBandwidth['80MHz'],
          [1, 5, 9, 13, 17, 21, 25, 29]);

      // 40MHz: [1,5],[9,13],[17,21],[25,29]
      expect(n.availableChannelsPerBandwidth['40MHz'],
          [1, 5, 9, 13, 17, 21, 25, 29]);
    });

    test('SSID without matching radio still builds network', () {
      final ssids = WiFiSsids(items: [
        WiFiSsid(
          instancePath: 'Device.WiFi.SSID.1.',
          ssid: 'NoRadio',
          enable: true,
          status: 'Up',
          bssid: 'AA:BB:CC:DD:EE:FF',
          lowerLayers: 'Device.WiFi.Radio.99.', // no matching radio
        ),
      ]);

      final accessPoints = WiFiAccessPoints(items: []);
      final radios = WiFiRadios(items: []);

      final networks = svc.buildWifiNetworks(
        ssids: ssids,
        accessPoints: accessPoints,
        radios: radios,
      );

      expect(networks, hasLength(1));
      final n = networks.first;
      expect(n.supportedBandwidths, isEmpty);
      expect(n.availableChannelsPerBandwidth, isEmpty);
      expect(n.possibleChannels, isEmpty);
    });

    test('trailing dot normalization matches AP to SSID', () {
      // AP ssidReference without trailing dot, SSID path with trailing dot
      final ssids = WiFiSsids(items: [
        WiFiSsid(
          instancePath: 'Device.WiFi.SSID.1.', // with trailing dot
          ssid: 'DotTest',
          enable: true,
          status: 'Up',
          bssid: 'AA:BB:CC:DD:EE:FF',
          lowerLayers: 'Device.WiFi.Radio.1', // without trailing dot
        ),
      ]);

      final accessPoints = WiFiAccessPoints(items: [
        WiFiAccessPoint(
          instancePath: 'Device.WiFi.AccessPoint.1.',
          enable: true,
          status: 'Enabled',
          modesSupported: 'WPA2-Personal',
          securityModeEnabled: 'WPA2-Personal',
          encryptionMode: 'AES',
          keyPassphrase: 'pass',
          ssidAdvertisementEnabled: true,
          ssidReference: 'Device.WiFi.SSID.1', // without trailing dot
        ),
      ]);

      final radios = WiFiRadios(items: [
        WiFiRadio(
          instancePath: 'Device.WiFi.Radio.1', // without trailing dot
          enable: true,
          status: 'Up',
          channel: 6,
          operatingFrequencyBand: '2.4GHz',
          operatingChannelBandwidth: '20MHz',
          possibleChannels: '1,6,11',
          operatingStandards: 'n',
          supportedStandards: 'b,g,n',
          transmitPower: 100,
          maxBitRate: 300,
          autoChannelEnable: true,
          ieee80211hEnabled: false,
          supportedOperatingChannelBandwidths: 'Auto,20MHz',
        ),
      ]);

      final networks = svc.buildWifiNetworks(
        ssids: ssids,
        accessPoints: accessPoints,
        radios: radios,
      );

      expect(networks, hasLength(1));
      final n = networks.first;
      // AP should be matched despite dot mismatch
      expect(n.accessPointInstancePath, 'Device.WiFi.AccessPoint.1.');
      expect(n.securityMode, 'WPA2-Personal');
      // Radio should be matched
      expect(n.band, '2.4GHz');
      expect(n.possibleChannels, [1, 6, 11]);
    });
  });

  // -------------------------------------------------------------------------
  // buildQuickSetupNetworks
  // -------------------------------------------------------------------------

  group('buildQuickSetupNetworks', () {
    test('isQuickSetup true when all main networks share ssid and enabled', () {
      final ssids = WiFiSsids(items: [
        WiFiSsid(
          instancePath: 'Device.WiFi.SSID.1.',
          ssid: 'Home',
          enable: true,
          status: 'Up',
          bssid: '01:01:01:01:01:01',
          lowerLayers: 'Device.WiFi.Radio.1.',
        ),
        WiFiSsid(
          instancePath: 'Device.WiFi.SSID.2.',
          ssid: 'Home',
          enable: true,
          status: 'Up',
          bssid: '02:02:02:02:02:02',
          lowerLayers: 'Device.WiFi.Radio.2.',
        ),
      ]);

      final accessPoints = WiFiAccessPoints(items: [
        WiFiAccessPoint(
          instancePath: 'Device.WiFi.AccessPoint.1.',
          enable: true,
          status: 'Enabled',
          modesSupported: 'WPA2-Personal,WPA3-Personal',
          securityModeEnabled: 'WPA2-Personal',
          encryptionMode: 'AES',
          keyPassphrase: 'pass',
          ssidAdvertisementEnabled: true,
          ssidReference: 'Device.WiFi.SSID.1.',
        ),
        WiFiAccessPoint(
          instancePath: 'Device.WiFi.AccessPoint.2.',
          enable: true,
          status: 'Enabled',
          modesSupported: 'WPA2-Personal,WPA3-Personal',
          securityModeEnabled: 'WPA3-Personal',
          encryptionMode: 'AES',
          keyPassphrase: 'pass',
          ssidAdvertisementEnabled: true,
          ssidReference: 'Device.WiFi.SSID.2.',
        ),
      ]);

      final radios = WiFiRadios(items: [
        WiFiRadio(
          instancePath: 'Device.WiFi.Radio.1.',
          enable: true,
          status: 'Up',
          channel: 6,
          operatingFrequencyBand: '2.4GHz',
          operatingChannelBandwidth: '20MHz',
          possibleChannels: '1,6,11',
          operatingStandards: 'n',
          supportedStandards: 'b,g,n',
          transmitPower: 100,
          maxBitRate: 300,
          autoChannelEnable: true,
          ieee80211hEnabled: false,
          supportedOperatingChannelBandwidths: 'Auto,20MHz,40MHz',
        ),
        WiFiRadio(
          instancePath: 'Device.WiFi.Radio.2.',
          enable: true,
          status: 'Up',
          channel: 36,
          operatingFrequencyBand: '5GHz',
          operatingChannelBandwidth: '80MHz',
          possibleChannels: '36,40,44,48',
          operatingStandards: 'ax',
          supportedStandards: 'a,n,ac,ax',
          transmitPower: 100,
          maxBitRate: 2402,
          autoChannelEnable: false,
          ieee80211hEnabled: false,
          supportedOperatingChannelBandwidths: 'Auto,20MHz,40MHz,80MHz',
        ),
      ]);

      final networks = svc.buildWifiNetworks(
        ssids: ssids,
        accessPoints: accessPoints,
        radios: radios,
      );

      final qs = svc.buildQuickSetupNetworks(networks);
      expect(qs.isQuickSetup, isTrue);
      expect(qs.main, isNotNull);
      expect(qs.guest, isNull);
      expect(qs.main!.ssid, 'Home');
      // Intersection of security modes
      expect(
          qs.main!.supportedSecurityModes, ['WPA2-Personal', 'WPA3-Personal']);
    });
  });

  // -------------------------------------------------------------------------
  // buildWifiNetworks — guest detection (per-radio instance ordering)
  // -------------------------------------------------------------------------

  group('buildWifiNetworks — guest detection', () {
    WiFiSsid _ssid(String path, String name, String radio,
            {bool enable = true}) =>
        WiFiSsid(
          instancePath: path,
          ssid: name,
          enable: enable,
          status: enable ? 'Up' : 'Down',
          bssid: 'AA:BB:CC:DD:EE:FF',
          lowerLayers: radio,
        );

    WiFiAccessPoint _ap(String path, String ssidRef) => WiFiAccessPoint(
          instancePath: path,
          enable: true,
          status: 'Enabled',
          modesSupported: 'WPA2-Personal',
          securityModeEnabled: 'WPA2-Personal',
          encryptionMode: 'AES',
          keyPassphrase: 'pass',
          ssidAdvertisementEnabled: true,
          ssidReference: ssidRef,
        );

    WiFiRadio _radio(String path, String band) => WiFiRadio(
          instancePath: path,
          enable: true,
          status: 'Up',
          channel: 6,
          operatingFrequencyBand: band,
          operatingChannelBandwidth: '20MHz',
          possibleChannels: '1,6,11',
          operatingStandards: 'n',
          supportedStandards: 'b,g,n',
          transmitPower: 100,
          maxBitRate: 300,
          autoChannelEnable: true,
          ieee80211hEnabled: false,
          supportedOperatingChannelBandwidths: 'Auto,20MHz',
        );

    test('dual-band: 2 main + 2 guest', () {
      final networks = svc.buildWifiNetworks(
        ssids: WiFiSsids(items: [
          _ssid('Device.WiFi.SSID.1.', 'Home', 'Device.WiFi.Radio.1.'),
          _ssid('Device.WiFi.SSID.2.', 'Home', 'Device.WiFi.Radio.2.'),
          _ssid('Device.WiFi.SSID.3.', 'Home-Guest', 'Device.WiFi.Radio.1.',
              enable: false),
          _ssid('Device.WiFi.SSID.4.', 'Home-Guest', 'Device.WiFi.Radio.2.',
              enable: false),
        ]),
        accessPoints: WiFiAccessPoints(items: [
          _ap('Device.WiFi.AccessPoint.1.', 'Device.WiFi.SSID.1.'),
          _ap('Device.WiFi.AccessPoint.2.', 'Device.WiFi.SSID.2.'),
          _ap('Device.WiFi.AccessPoint.3.', 'Device.WiFi.SSID.3.'),
          _ap('Device.WiFi.AccessPoint.4.', 'Device.WiFi.SSID.4.'),
        ]),
        radios: WiFiRadios(items: [
          _radio('Device.WiFi.Radio.1.', '2.4GHz'),
          _radio('Device.WiFi.Radio.2.', '5GHz'),
        ]),
      );

      expect(networks, hasLength(4));
      expect(networks[0].isGuest, isFalse); // SSID.1 — Main
      expect(networks[1].isGuest, isFalse); // SSID.2 — Main
      expect(networks[2].isGuest, isTrue); // SSID.3 — Guest
      expect(networks[3].isGuest, isTrue); // SSID.4 — Guest
    });

    test('tri-band: 3 main + 3 guest', () {
      final networks = svc.buildWifiNetworks(
        ssids: WiFiSsids(items: [
          _ssid('Device.WiFi.SSID.1.', 'Home', 'Device.WiFi.Radio.1.'),
          _ssid('Device.WiFi.SSID.2.', 'Home', 'Device.WiFi.Radio.2.'),
          _ssid('Device.WiFi.SSID.3.', 'Home', 'Device.WiFi.Radio.3.'),
          _ssid('Device.WiFi.SSID.4.', 'Home-Guest', 'Device.WiFi.Radio.1.',
              enable: false),
          _ssid('Device.WiFi.SSID.5.', 'Home-Guest', 'Device.WiFi.Radio.2.',
              enable: false),
          _ssid('Device.WiFi.SSID.6.', 'Home-Guest', 'Device.WiFi.Radio.3.',
              enable: false),
        ]),
        accessPoints: WiFiAccessPoints(items: [
          _ap('Device.WiFi.AccessPoint.1.', 'Device.WiFi.SSID.1.'),
          _ap('Device.WiFi.AccessPoint.2.', 'Device.WiFi.SSID.2.'),
          _ap('Device.WiFi.AccessPoint.3.', 'Device.WiFi.SSID.3.'),
          _ap('Device.WiFi.AccessPoint.4.', 'Device.WiFi.SSID.4.'),
          _ap('Device.WiFi.AccessPoint.5.', 'Device.WiFi.SSID.5.'),
          _ap('Device.WiFi.AccessPoint.6.', 'Device.WiFi.SSID.6.'),
        ]),
        radios: WiFiRadios(items: [
          _radio('Device.WiFi.Radio.1.', '2.4GHz'),
          _radio('Device.WiFi.Radio.2.', '5GHz'),
          _radio('Device.WiFi.Radio.3.', '6GHz'),
        ]),
      );

      expect(networks, hasLength(6));
      // Main: SSID.1, SSID.2, SSID.3
      expect(networks[0].isGuest, isFalse);
      expect(networks[1].isGuest, isFalse);
      expect(networks[2].isGuest, isFalse);
      // Guest: SSID.4, SSID.5, SSID.6
      expect(networks[3].isGuest, isTrue);
      expect(networks[4].isGuest, isTrue);
      expect(networks[5].isGuest, isTrue);
    });

    test('guest SSID without "guest" in name still detected', () {
      final networks = svc.buildWifiNetworks(
        ssids: WiFiSsids(items: [
          _ssid('Device.WiFi.SSID.1.', 'Home', 'Device.WiFi.Radio.1.'),
          _ssid('Device.WiFi.SSID.2.', 'Visitors', 'Device.WiFi.Radio.1.'),
        ]),
        accessPoints: WiFiAccessPoints(items: [
          _ap('Device.WiFi.AccessPoint.1.', 'Device.WiFi.SSID.1.'),
          _ap('Device.WiFi.AccessPoint.2.', 'Device.WiFi.SSID.2.'),
        ]),
        radios: WiFiRadios(items: [
          _radio('Device.WiFi.Radio.1.', '2.4GHz'),
        ]),
      );

      expect(networks, hasLength(2));
      expect(networks[0].isGuest, isFalse); // SSID.1 — Main
      expect(networks[0].ssid, 'Home');
      expect(
          networks[1].isGuest, isTrue); // SSID.2 — Guest (no "guest" in name)
      expect(networks[1].ssid, 'Visitors');
    });

    test('single SSID per radio — no guest', () {
      final networks = svc.buildWifiNetworks(
        ssids: WiFiSsids(items: [
          _ssid('Device.WiFi.SSID.1.', 'Home', 'Device.WiFi.Radio.1.'),
          _ssid('Device.WiFi.SSID.2.', 'Home', 'Device.WiFi.Radio.2.'),
        ]),
        accessPoints: WiFiAccessPoints(items: [
          _ap('Device.WiFi.AccessPoint.1.', 'Device.WiFi.SSID.1.'),
          _ap('Device.WiFi.AccessPoint.2.', 'Device.WiFi.SSID.2.'),
        ]),
        radios: WiFiRadios(items: [
          _radio('Device.WiFi.Radio.1.', '2.4GHz'),
          _radio('Device.WiFi.Radio.2.', '5GHz'),
        ]),
      );

      expect(networks, hasLength(2));
      expect(networks[0].isGuest, isFalse);
      expect(networks[1].isGuest, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // toggleRadio
  // -------------------------------------------------------------------------

  group('toggleRadio', () {
    late MockUspClient mockUsp;
    late UspWifiSettingsService writeSvc;

    setUp(() {
      mockUsp = MockUspClient();
      writeSvc = UspWifiSettingsService(mockUsp);
    });

    test('succeeds on UspSuccess', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => uspSuccess());

      await writeSvc.toggleRadio('Device.WiFi.Radio.1.', true);

      verify(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .called(1);
    });

    test('throws UspCompleteFailureError on UspFailure', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => uspFailure());

      expect(
        () => writeSvc.toggleRadio('Device.WiFi.Radio.1.', true),
        throwsA(isA<UspCompleteFailureError>()),
      );
    });

    test('maps transport error to ServiceError', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenThrow('Set failed: Transport error: HTTP error: HTTP 504');

      expect(
        () => writeSvc.toggleRadio('Device.WiFi.Radio.1.', true),
        throwsA(isA<NetworkError>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // updateRadioChannel
  // -------------------------------------------------------------------------

  group('updateRadioChannel', () {
    late MockUspClient mockUsp;
    late UspWifiSettingsService writeSvc;

    setUp(() {
      mockUsp = MockUspClient();
      writeSvc = UspWifiSettingsService(mockUsp);
    });

    test('succeeds on UspSuccess', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => uspSuccess());

      await writeSvc.updateRadioChannel(
        'Device.WiFi.Radio.1.',
        channel: 36,
        autoChannel: false,
      );

      verify(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .called(1);
    });

    test('throws UspCompleteFailureError on UspFailure', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => uspFailure());

      expect(
        () => writeSvc.updateRadioChannel(
          'Device.WiFi.Radio.1.',
          channel: 36,
          autoChannel: false,
        ),
        throwsA(isA<UspCompleteFailureError>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // saveAdvanced — strict error handling
  // -------------------------------------------------------------------------

  group('saveAdvanced', () {
    late MockUspClient mockUsp;
    late UspWifiSettingsService writeSvc;

    setUp(() {
      mockUsp = MockUspClient();
      writeSvc = UspWifiSettingsService(mockUsp);
    });

    WifiNetworkUIModel makeNetwork({
      String ssid = 'TestNet',
      bool enabled = true,
      String securityMode = 'WPA2-Personal',
      String keyPassphrase = 'pass1234',
      String band = '5GHz',
      int channel = 36,
      String channelBandwidth = '80MHz',
      bool autoChannelEnable = true,
    }) =>
        WifiNetworkUIModel(
          ssidInstancePath: 'Device.WiFi.SSID.1.',
          accessPointInstancePath: 'Device.WiFi.AccessPoint.1.',
          radioInstancePath: 'Device.WiFi.Radio.1.',
          ssid: ssid,
          enabled: enabled,
          ssidAdvertisementEnabled: true,
          supportedSecurityModes: ['WPA2-Personal', 'WPA3-Personal'],
          securityMode: securityMode,
          keyPassphrase: keyPassphrase,
          isGuest: false,
          band: band,
          channel: channel,
          channelBandwidth: channelBandwidth,
          autoChannelEnable: autoChannelEnable,
          possibleChannels: [36, 40, 44, 48],
          operatingStandards: 'ax',
          supportedStandards: 'a,n,ac,ax',
        );

    test('succeeds when all updates return UspSuccess', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => uspSuccess());

      final original = [makeNetwork(ssid: 'OldName')];
      final current = [makeNetwork(ssid: 'NewName')];

      await writeSvc.saveAdvanced(original: original, current: current);

      verify(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .called(1);
    });

    test('throws UspCompleteFailureError when SSID update fails', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => uspFailure(errorMessage: 'SSID rejected'));

      final original = [makeNetwork(ssid: 'OldName')];
      final current = [makeNetwork(ssid: 'NewName')];

      expect(
        () => writeSvc.saveAdvanced(original: original, current: current),
        throwsA(isA<UspCompleteFailureError>()),
      );
    });

    test('skips unchanged networks', () async {
      final networks = [makeNetwork()];

      await writeSvc.saveAdvanced(
        original: networks,
        current: List.of(networks),
      );

      verifyNever(
          () => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')));
    });
  });

  // -------------------------------------------------------------------------
  // saveQuickSetup — field-level diff
  // -------------------------------------------------------------------------

  group('saveQuickSetup', () {
    late MockUspClient mockUsp;
    late UspWifiSettingsService writeSvc;

    setUp(() {
      mockUsp = MockUspClient();
      writeSvc = UspWifiSettingsService(mockUsp);
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => uspSuccess());
    });

    WifiNetworkUIModel makeNetwork({
      String ssidInstancePath = 'Device.WiFi.SSID.1.',
      String accessPointInstancePath = 'Device.WiFi.AccessPoint.1.',
      String band = '2.4GHz',
      bool isGuest = false,
    }) =>
        WifiNetworkUIModel(
          ssidInstancePath: ssidInstancePath,
          accessPointInstancePath: accessPointInstancePath,
          radioInstancePath: 'Device.WiFi.Radio.1.',
          ssid: 'Home',
          enabled: true,
          ssidAdvertisementEnabled: true,
          supportedSecurityModes: const ['WPA2-Personal', 'WPA3-Personal'],
          securityMode: 'WPA2-Personal',
          keyPassphrase: '',
          isGuest: isGuest,
          band: band,
          channel: 6,
          channelBandwidth: '20MHz',
          autoChannelEnable: true,
          possibleChannels: const [1, 6, 11],
          operatingStandards: 'n',
          supportedStandards: 'b,g,n',
        );

    /// Captures all TR-181 parameter keys that were passed to `mockUsp.set`.
    Set<String> capturedKeys() {
      final captured = verify(() => mockUsp.set(captureAny(),
          allowPartial: any(named: 'allowPartial'))).captured;
      final keys = <String>{};
      for (final arg in captured) {
        if (arg is Map) keys.addAll(arg.keys.cast<String>());
      }
      return keys;
    }

    test('skips AP write when only guest enabled toggled', () async {
      // Guest group: only `enabled` changed. No SSID-name change, no AP change.
      final guestAgg = WifiQuickSetupNetwork(
        isGuest: true,
        ssid: 'Home-Guest',
        securityMode: 'None',
        keyPassphrase: '',
        supportedSecurityModes: const [],
        ssidInstancePaths: const ['Device.WiFi.SSID.3.'],
        apInstancePaths: const ['Device.WiFi.AccessPoint.3.'],
      );
      const guestOrig = WifiQuickSetupSettings(
        isGuest: true,
        enabled: true,
        ssid: 'Home-Guest',
        password: '',
        securityMode: 'None',
        supportedSecurityModes: [],
      );

      final original = WifiSettingsSettings(
        networks: [
          makeNetwork(
            ssidInstancePath: 'Device.WiFi.SSID.3.',
            accessPointInstancePath: 'Device.WiFi.AccessPoint.3.',
            isGuest: true,
          ),
        ],
        quickSetupEnabled: true,
        quickSetupGuest: guestOrig,
      );
      final current = original.copyWith(
        quickSetupGuest: guestOrig.copyWith(enabled: false),
      );
      final status = WifiSettingsStatus(quickSetupGuestAggregate: guestAgg);

      await writeSvc.saveQuickSetup(
        original: original,
        current: current,
        status: status,
      );

      final keys = capturedKeys();
      // SSID enable write happens…
      expect(keys, contains('Device.WiFi.SSID.3.Enable'));
      // …but AP layer (KeyPassphrase / Security.ModeEnabled) must NOT be touched.
      expect(
        keys.any((k) => k.startsWith('Device.WiFi.AccessPoint.3.Security.')),
        isFalse,
      );
    });

    test('skips SSID write when only password changed', () async {
      final mainAgg = WifiQuickSetupNetwork(
        isGuest: false,
        ssid: 'Home',
        securityMode: 'WPA2-Personal',
        keyPassphrase: '',
        supportedSecurityModes: const ['WPA2-Personal', 'WPA3-Personal'],
        ssidInstancePaths: const ['Device.WiFi.SSID.1.', 'Device.WiFi.SSID.2.'],
        apInstancePaths: const [
          'Device.WiFi.AccessPoint.1.',
          'Device.WiFi.AccessPoint.2.'
        ],
      );
      const mainOrig = WifiQuickSetupSettings(
        isGuest: false,
        enabled: true,
        ssid: 'Home',
        password: '',
        securityMode: 'WPA2-Personal',
        supportedSecurityModes: ['WPA2-Personal', 'WPA3-Personal'],
      );

      final original = WifiSettingsSettings(
        networks: [
          makeNetwork(ssidInstancePath: 'Device.WiFi.SSID.1.'),
          makeNetwork(
            ssidInstancePath: 'Device.WiFi.SSID.2.',
            accessPointInstancePath: 'Device.WiFi.AccessPoint.2.',
            band: '5GHz',
          ),
        ],
        quickSetupEnabled: true,
        quickSetupMain: mainOrig,
      );
      final current = original.copyWith(
        quickSetupMain: mainOrig.copyWith(password: 'brandnew1'),
      );
      final status = WifiSettingsStatus(quickSetupMainAggregate: mainAgg);

      await writeSvc.saveQuickSetup(
        original: original,
        current: current,
        status: status,
      );

      final keys = capturedKeys();
      // AP layer gets written — passphrase + mode.
      expect(
          keys.any((k) => k.contains('AccessPoint.1.Security.KeyPassphrase')),
          isTrue);
      expect(
          keys.any((k) => k.contains('AccessPoint.2.Security.KeyPassphrase')),
          isTrue);
      // SSID layer must NOT be touched.
      expect(keys.any((k) => k.startsWith('Device.WiFi.SSID.')), isFalse);
    });

    test('omits keyPassphrase param when password empty on mode change',
        () async {
      // User switches main to Open without entering a password. AP write
      // still happens (mode changed) but must not send an empty passphrase.
      final mainAgg = WifiQuickSetupNetwork(
        isGuest: false,
        ssid: 'Home',
        securityMode: 'WPA2-Personal',
        keyPassphrase: '',
        supportedSecurityModes: const ['None', 'WPA2-Personal'],
        ssidInstancePaths: const ['Device.WiFi.SSID.1.'],
        apInstancePaths: const ['Device.WiFi.AccessPoint.1.'],
      );
      const mainOrig = WifiQuickSetupSettings(
        isGuest: false,
        enabled: true,
        ssid: 'Home',
        password: '',
        securityMode: 'WPA2-Personal',
        supportedSecurityModes: ['None', 'WPA2-Personal'],
      );

      final original = WifiSettingsSettings(
        networks: [makeNetwork()],
        quickSetupEnabled: true,
        quickSetupMain: mainOrig,
      );
      final current = original.copyWith(
        quickSetupMain: mainOrig.copyWith(securityMode: 'None'),
      );
      final status = WifiSettingsStatus(quickSetupMainAggregate: mainAgg);

      await writeSvc.saveQuickSetup(
        original: original,
        current: current,
        status: status,
      );

      final keys = capturedKeys();
      expect(keys.any((k) => k.contains('Security.ModeEnabled')), isTrue);
      // Empty passphrase must not be sent to firmware.
      expect(keys.any((k) => k.contains('Security.KeyPassphrase')), isFalse);
    });
  });
}
