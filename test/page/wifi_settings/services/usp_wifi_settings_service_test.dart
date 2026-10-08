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

import '../../../mocks/test_data/wifi_settings_test_data.dart';

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

/// A per-path SET error whose request never got an answer — what the WASM
/// client reports when the browser's `fetch` fails under a WiFi restart.
Map<String, dynamic> uspUnanswered(String path) => {
      'success': false,
      'result': {
        'data': <String, dynamic>{},
        'error': {
          path: {
            'errorCode': 9999,
            'errorMessage': 'Transport error: Failed to fetch',
          }
        },
      },
    };

/// Sends [plan] the way a caller would, returning what it planned and the
/// outcome — the shape these tests assert on.
Future<({int count, WifiWriteOutcome outcome, Map<String, dynamic> written})>
    sent(WifiWritePlan plan) async => (
          count: plan.count,
          outcome: await plan.send(),
          written: plan.params,
        );

/// Every SET [usp] received, one entry per call, with its `allowPartial`.
///
/// Per call rather than merged, because the defect this pins (#1499) is the
/// NUMBER of writes: a merged key set is identical whether the save sent one SET
/// or five.
List<({Map<String, dynamic> params, bool allowPartial})> capturedSets(
    MockUspClient usp) {
  final captured = verify(() => usp.set(captureAny(),
      allowPartial: captureAny(named: 'allowPartial'))).captured;
  return [
    for (var i = 0; i < captured.length; i += 2)
      (
        params: Map<String, dynamic>.from(captured[i] as Map),
        allowPartial: captured[i + 1] as bool,
      ),
  ];
}

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
          // DFS enabled so DFS channels (52–64) survive filtering — this test
          // exercises bonding-group rules, not DFS filtering.
          ieee80211hEnabled: true,
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

    // -----------------------------------------------------------------------
    // DFS channel filtering (#1025). When IEEE80211hEnabled is false, 5 GHz
    // DFS channels (52–64, 100–144) must be stripped from BOTH possibleChannels
    // and availableChannelsPerBandwidth so the dropdown and the "N channels
    // available" counts stay consistent.
    // -----------------------------------------------------------------------

    WiFiSsids singleSsid() => WiFiSsids(items: [
          WiFiSsid(
            instancePath: 'Device.WiFi.SSID.1.',
            ssid: 'DfsNet',
            enable: true,
            status: 'Up',
            bssid: 'AA:BB:CC:DD:EE:FF',
            lowerLayers: 'Device.WiFi.Radio.1.',
          ),
        ]);

    WiFiAccessPoints singleAp() => WiFiAccessPoints(items: [
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

    WiFiRadios fiveGhzRadio({required bool dfsEnabled}) => WiFiRadios(items: [
          WiFiRadio(
            instancePath: 'Device.WiFi.Radio.1.',
            enable: true,
            status: 'Up',
            channel: 36,
            operatingFrequencyBand: '5GHz',
            operatingChannelBandwidth: '80MHz',
            possibleChannels: '36,40,44,48,52,56,60,64,100,104,108,112',
            operatingStandards: 'ax',
            supportedStandards: 'a,n,ac,ax',
            transmitPower: 100,
            maxBitRate: 2402,
            autoChannelEnable: false,
            ieee80211hEnabled: dfsEnabled,
            supportedOperatingChannelBandwidths: 'Auto,20MHz,40MHz,80MHz',
          ),
        ]);

    test('DFS disabled on 5 GHz strips DFS channels from possibleChannels', () {
      final networks = svc.buildWifiNetworks(
        ssids: singleSsid(),
        accessPoints: singleAp(),
        radios: fiveGhzRadio(dfsEnabled: false),
      );

      // Only non-DFS UNII-1 channels remain.
      expect(networks.first.possibleChannels, [36, 40, 44, 48]);
    });

    test('DFS disabled on 5 GHz strips DFS from availableChannelsPerBandwidth',
        () {
      final networks = svc.buildWifiNetworks(
        ssids: singleSsid(),
        accessPoints: singleAp(),
        radios: fiveGhzRadio(dfsEnabled: false),
      );

      final bwMap = networks.first.availableChannelsPerBandwidth;
      expect(bwMap['Auto'], [36, 40, 44, 48]);
      expect(bwMap['20MHz'], [36, 40, 44, 48]);
      // No DFS channel should appear under any bandwidth.
      for (final channels in bwMap.values) {
        expect(channels.any((c) => c >= 52), isFalse,
            reason: 'DFS channel leaked into bandwidth map');
      }
    });

    test('DFS enabled on 5 GHz retains DFS channels', () {
      final networks = svc.buildWifiNetworks(
        ssids: singleSsid(),
        accessPoints: singleAp(),
        radios: fiveGhzRadio(dfsEnabled: true),
      );

      expect(
        networks.first.possibleChannels,
        [36, 40, 44, 48, 52, 56, 60, 64, 100, 104, 108, 112],
      );
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
            {bool enable = true, String? alias}) =>
        WiFiSsid(
          instancePath: path,
          ssid: name,
          enable: enable,
          status: enable ? 'Up' : 'Down',
          bssid: 'AA:BB:CC:DD:EE:FF',
          lowerLayers: radio,
          alias: alias,
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
          _ssid('Device.WiFi.SSID.1.', 'Home', 'Device.WiFi.Radio.1.',
              alias: 'wifi-2g'),
          _ssid('Device.WiFi.SSID.2.', 'Home', 'Device.WiFi.Radio.2.',
              alias: 'wifi-5g'),
          _ssid('Device.WiFi.SSID.3.', 'Home-Guest', 'Device.WiFi.Radio.1.',
              enable: false, alias: 'wifi-2g-guest'),
          _ssid('Device.WiFi.SSID.4.', 'Home-Guest', 'Device.WiFi.Radio.2.',
              enable: false, alias: 'wifi-5g-guest'),
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
          _ssid('Device.WiFi.SSID.1.', 'Home', 'Device.WiFi.Radio.1.',
              alias: 'wifi-2g'),
          _ssid('Device.WiFi.SSID.2.', 'Home', 'Device.WiFi.Radio.2.',
              alias: 'wifi-5g'),
          _ssid('Device.WiFi.SSID.3.', 'Home', 'Device.WiFi.Radio.3.',
              alias: 'wifi-6g'),
          _ssid('Device.WiFi.SSID.4.', 'Home-Guest', 'Device.WiFi.Radio.1.',
              enable: false, alias: 'wifi-2g-guest'),
          _ssid('Device.WiFi.SSID.5.', 'Home-Guest', 'Device.WiFi.Radio.2.',
              enable: false, alias: 'wifi-5g-guest'),
          _ssid('Device.WiFi.SSID.6.', 'Home-Guest', 'Device.WiFi.Radio.3.',
              enable: false, alias: 'wifi-6g-guest'),
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

    test('guest SSID without "guest" in name still detected by alias', () {
      final networks = svc.buildWifiNetworks(
        ssids: WiFiSsids(items: [
          _ssid('Device.WiFi.SSID.1.', 'Home', 'Device.WiFi.Radio.1.',
              alias: 'wifi-2g'),
          _ssid('Device.WiFi.SSID.2.', 'Visitors', 'Device.WiFi.Radio.1.',
              alias: 'wifi-2g-guest'),
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
      expect(networks[0].isGuest, isFalse); // SSID.1 — Main (alias: wifi-2g)
      expect(networks[0].ssid, 'Home');
      expect(networks[1].isGuest,
          isTrue); // SSID.2 — Guest (alias ends with -guest)
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
  // toggleSsidsByName — writes SSID.Enable + matched AccessPoint.Enable (#972)
  // -------------------------------------------------------------------------

  group('toggleSsidsByName', () {
    late MockUspClient mockUsp;
    late UspWifiSettingsService writeSvc;

    setUp(() {
      mockUsp = MockUspClient();
      writeSvc = UspWifiSettingsService(mockUsp);
    });

    WiFiSsid ssid(String path, String name, String radio) => WiFiSsid(
          instancePath: path,
          ssid: name,
          enable: true,
          status: 'Up',
          bssid: '',
          lowerLayers: radio,
        );
    WiFiAccessPoint ap(String path, String ssidRef) => WiFiAccessPoint(
          instancePath: path,
          alias: '',
          enable: true,
          status: 'Up',
          modesSupported: '',
          securityModeEnabled: '',
          encryptionMode: '',
          keyPassphrase: '',
          ssidAdvertisementEnabled: true,
          ssidReference: ssidRef,
        );

    Set<String> capturedKeys() {
      final captured = verify(() => mockUsp.set(captureAny(),
          allowPartial: any(named: 'allowPartial'))).captured;
      final keys = <String>{};
      for (final arg in captured) {
        if (arg is Map) keys.addAll(arg.keys.cast<String>());
      }
      return keys;
    }

    test('toggles matched SSIDs and their AccessPoints across bands', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => uspSuccess());

      final ssids = WiFiSsids(items: [
        ssid('Device.WiFi.SSID.1.', 'Home', 'Device.WiFi.Radio.1.'),
        ssid('Device.WiFi.SSID.2.', 'Home', 'Device.WiFi.Radio.2.'),
        ssid('Device.WiFi.SSID.3.', 'Home-Guest', 'Device.WiFi.Radio.1.'),
      ]);
      final aps = WiFiAccessPoints(items: [
        ap('Device.WiFi.AccessPoint.1.', 'Device.WiFi.SSID.1.'),
        ap('Device.WiFi.AccessPoint.2.', 'Device.WiFi.SSID.2.'),
        ap('Device.WiFi.AccessPoint.3.', 'Device.WiFi.SSID.3.'),
      ]);

      final result =
          await sent(writeSvc.toggleSsidsByName(ssids, aps, 'Home', false));

      expect(result.count, 2); // SSID.1 + SSID.2 (both named "Home")
      final keys = capturedKeys();
      expect(keys, contains('Device.WiFi.SSID.1.Enable'));
      expect(keys, contains('Device.WiFi.SSID.2.Enable'));
      expect(keys, contains('Device.WiFi.AccessPoint.1.Enable'));
      expect(keys, contains('Device.WiFi.AccessPoint.2.Enable'));
      // The guest network (SSID.3) must be untouched.
      expect(keys, isNot(contains('Device.WiFi.SSID.3.Enable')));
      expect(keys, isNot(contains('Device.WiFi.AccessPoint.3.Enable')));
    });

    test('SSID + AccessPoint Enable go out as ONE SET with allowPartial',
        () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => uspSuccess());
      final ssids = WiFiSsids(items: [
        ssid('Device.WiFi.SSID.1.', 'Home', 'Device.WiFi.Radio.1.'),
        ssid('Device.WiFi.SSID.2.', 'Home', 'Device.WiFi.Radio.2.'),
      ]);
      final aps = WiFiAccessPoints(items: [
        ap('Device.WiFi.AccessPoint.1.', 'Device.WiFi.SSID.1.'),
        ap('Device.WiFi.AccessPoint.2.', 'Device.WiFi.SSID.2.'),
      ]);

      final result =
          await sent(writeSvc.toggleSsidsByName(ssids, aps, 'Home', false));

      final sets = capturedSets(mockUsp);
      expect(sets, hasLength(1));
      expect(sets.single.allowPartial, isTrue);
      expect(sets.single.params, {
        'Device.WiFi.SSID.1.Enable': false,
        'Device.WiFi.SSID.2.Enable': false,
        'Device.WiFi.AccessPoint.1.Enable': false,
        'Device.WiFi.AccessPoint.2.Enable': false,
      });
      expect(result.count, 2);
      expect(result.outcome, WifiWriteOutcome.confirmed);
      expect(result.written, sets.single.params);
    });

    test('returns 0 and issues no writes when no SSID matches', () async {
      final ssids = WiFiSsids(items: [
        ssid('Device.WiFi.SSID.1.', 'Home', 'Device.WiFi.Radio.1.'),
      ]);
      final aps = WiFiAccessPoints(items: [
        ap('Device.WiFi.AccessPoint.1.', 'Device.WiFi.SSID.1.'),
      ]);

      final result = await sent(
          writeSvc.toggleSsidsByName(ssids, aps, 'Nonexistent', false));

      expect(result.count, 0);
      verifyNever(
          () => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')));
    });
  });

  // -------------------------------------------------------------------------
  // isApplied — read-back after an unanswered write
  // -------------------------------------------------------------------------

  group('isApplied', () {
    late MockUspClient mockUsp;
    late UspWifiSettingsService writeSvc;

    setUp(() {
      mockUsp = MockUspClient();
      writeSvc = UspWifiSettingsService(mockUsp);
    });

    /// One GET answers all three tables; each generated `fetch` picks its own
    /// leaves out of it.
    void routerReads(Map<String, dynamic> leaves) {
      when(() => mockUsp.get(any())).thenAnswer((_) async => leaves);
    }

    final router = <String, dynamic>{
      'Device.WiFi.SSID.1.SSID': 'NewHome',
      'Device.WiFi.SSID.1.Enable': true,
      'Device.WiFi.SSID.1.Status': 'Up',
      'Device.WiFi.SSID.1.BSSID': '',
      'Device.WiFi.SSID.1.LowerLayers': 'Device.WiFi.Radio.1.',
      'Device.WiFi.AccessPoint.1.Enable': true,
      'Device.WiFi.AccessPoint.1.Status': 'Enabled',
      'Device.WiFi.AccessPoint.1.Security.ModesSupported': 'WPA2-Personal',
      'Device.WiFi.AccessPoint.1.Security.ModeEnabled': 'WPA2-Personal',
      'Device.WiFi.AccessPoint.1.Security.EncryptionMode': 'AES',
      // TR-181 never reads the passphrase back.
      'Device.WiFi.AccessPoint.1.Security.KeyPassphrase': '',
      'Device.WiFi.AccessPoint.1.SSIDAdvertisementEnabled': true,
      'Device.WiFi.AccessPoint.1.SSIDReference': 'Device.WiFi.SSID.1.',
      'Device.WiFi.Radio.1.Enable': true,
      'Device.WiFi.Radio.1.Status': 'Up',
      'Device.WiFi.Radio.1.Channel': 36,
      'Device.WiFi.Radio.1.OperatingFrequencyBand': '5GHz',
      'Device.WiFi.Radio.1.OperatingChannelBandwidth': '80MHz',
      'Device.WiFi.Radio.1.PossibleChannels': '36,40,44,48',
      'Device.WiFi.Radio.1.OperatingStandards': 'ax',
      'Device.WiFi.Radio.1.SupportedStandards': 'a,n,ac,ax',
      'Device.WiFi.Radio.1.TransmitPower': 100,
      'Device.WiFi.Radio.1.MaxBitRate': 0,
      'Device.WiFi.Radio.1.AutoChannelEnable': false,
      'Device.WiFi.Radio.1.IEEE80211hEnabled': true,
      'Device.WiFi.Radio.1.SupportedOperatingChannelBandwidths': '20MHz,80MHz',
    };

    test('true when every readable leaf it wrote reads back', () async {
      routerReads(router);

      expect(
        await writeSvc.isApplied({
          'Device.WiFi.SSID.1.SSID': 'NewHome',
          'Device.WiFi.AccessPoint.1.Security.ModeEnabled': 'WPA2-Personal',
          'Device.WiFi.Radio.1.Channel': 36,
        }),
        isTrue,
      );
    });

    test('false while any written leaf still reads the old value', () async {
      routerReads({...router, 'Device.WiFi.SSID.1.SSID': 'Home'});

      expect(
        await writeSvc.isApplied({'Device.WiFi.SSID.1.SSID': 'NewHome'}),
        isFalse,
      );
    });

    test('a passphrase is not compared — TR-181 reads it back empty', () async {
      routerReads(router);

      // Went out in the same SET as the SSID, so the SSID landing means it did.
      expect(
        await writeSvc.isApplied({
          'Device.WiFi.SSID.1.SSID': 'NewHome',
          'Device.WiFi.AccessPoint.1.Security.KeyPassphrase': 'secret12',
        }),
        isTrue,
      );
    });

    test('fails closed: nothing comparable is NOT applied', () async {
      expect(
        await writeSvc.isApplied({
          'Device.WiFi.AccessPoint.1.Security.KeyPassphrase': 'secret12',
        }),
        isFalse,
      );
      expect(await writeSvc.isApplied(const {}), isFalse);
      verifyNever(() => mockUsp.get(any()));
    });

    test(
        'an EMPTY table is a failed read, not the old values — the router '
        'answers a GET with no rows while its radios reload', () async {
      // Bench round 3, 2026-10-07 (M60, 2.0.2): from 30 s to 60 s after a
      // Quick Setup rename, every `Device.WiFi.SSID.*.` GET came back `{}` in
      // ~18 ms. Read as "reached the router, values wrong", that ruled a save
      // that landed as refused.
      routerReads(const {});

      expect(
        writeSvc.isApplied({'Device.WiFi.SSID.1.SSID': 'NewHome'}),
        throwsA(isA<ServiceError>()),
      );
    });

    test('a table that lacks a written row is a failed read too', () async {
      // Only SSID.1 answered; the save also wrote SSID.2.
      routerReads(router);

      expect(
        writeSvc.isApplied({
          'Device.WiFi.SSID.1.SSID': 'NewHome',
          'Device.WiFi.SSID.2.SSID': 'NewHome',
        }),
        throwsA(isA<ServiceError>()),
      );
    });

    test('a failed read is a ServiceError, for the caller to retry', () async {
      when(() => mockUsp.get(any())).thenThrow(Exception('Failed to fetch'));

      expect(
        writeSvc.isApplied({'Device.WiFi.SSID.1.SSID': 'NewHome'}),
        throwsA(isA<ServiceError>()),
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

      final result = await sent(writeSvc.updateRadioChannel(
        'Device.WiFi.Radio.1.',
        channel: 36,
        autoChannel: false,
      ));

      final sets = capturedSets(mockUsp);
      expect(sets, hasLength(1));
      expect(sets.single.params, {
        'Device.WiFi.Radio.1.Channel': 36,
        'Device.WiFi.Radio.1.AutoChannelEnable': false,
      });
      // One USP service, so the SET stays atomic: the router either moves the
      // radio or does not, never half (a refused Channel with an accepted
      // AutoChannelEnable).
      expect(sets.single.allowPartial, isFalse);
      expect(result.outcome, WifiWriteOutcome.confirmed);
      expect(result.written, sets.single.params);
    });

    test(
        'auto channel proves itself by AutoChannelEnable alone — the '
        'firmware picks the channel', () {
      final plan = writeSvc.updateRadioChannel(
        'Device.WiFi.Radio.1.',
        channel: 36,
        autoChannel: true,
      );

      expect(plan.proof, {'Device.WiFi.Radio.1.AutoChannelEnable': true});
    });

    test('a lost reply is "unanswered" — a channel change reloads the radio',
        () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer(
              (_) async => uspUnanswered('Device.WiFi.Radio.1.Channel'));

      final result = await sent(writeSvc.updateRadioChannel(
        'Device.WiFi.Radio.1.',
        channel: 36,
        autoChannel: false,
      ));

      expect(result.outcome, WifiWriteOutcome.unanswered);
    });

    test('throws UspCompleteFailureError on UspFailure', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => uspFailure());

      expect(
        () => sent(writeSvc.updateRadioChannel(
          'Device.WiFi.Radio.1.',
          channel: 36,
          autoChannel: false,
        )),
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

      await sent(writeSvc.saveAdvanced(original: original, current: current));

      verify(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .called(1);
    });

    test('throws UspCompleteFailureError when SSID update fails', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => uspFailure(errorMessage: 'SSID rejected'));

      final original = [makeNetwork(ssid: 'OldName')];
      final current = [makeNetwork(ssid: 'NewName')];

      expect(
        () => sent(writeSvc.saveAdvanced(original: original, current: current)),
        throwsA(isA<UspCompleteFailureError>()),
      );
    });

    test(
        'SSID + AP + Radio changes on two networks are ONE SET with '
        'allowPartial (#1499)', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => uspSuccess());
      WifiNetworkUIModel second({String ssid = 'TestNet'}) =>
          WifiSettingsTestData.createNetworkUIModel(
            ssidInstancePath: 'Device.WiFi.SSID.2.',
            accessPointInstancePath: 'Device.WiFi.AccessPoint.2.',
            radioInstancePath: 'Device.WiFi.Radio.2.',
            ssid: ssid,
          );
      final original = [makeNetwork(), second()];
      final current = [
        makeNetwork(
          ssid: 'NewName',
          keyPassphrase: 'newpass1',
          autoChannelEnable: false,
          channel: 40,
        ),
        second(ssid: 'NewName'),
      ];

      final result = await sent(
          writeSvc.saveAdvanced(original: original, current: current));

      final sets = capturedSets(mockUsp);
      expect(sets, hasLength(1));
      expect(sets.single.allowPartial, isTrue);
      expect(
        sets.single.params.keys,
        containsAll([
          'Device.WiFi.SSID.1.SSID',
          'Device.WiFi.AccessPoint.1.Security.KeyPassphrase',
          'Device.WiFi.Radio.1.Channel',
          'Device.WiFi.SSID.2.SSID',
        ]),
      );
      expect(result.outcome, WifiWriteOutcome.confirmed);
    });

    test('skips unchanged networks', () async {
      final networks = [makeNetwork()];

      await sent(writeSvc.saveAdvanced(
        original: networks,
        current: List.of(networks),
      ));

      verifyNever(
          () => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')));
    });

    test('enable-only toggle writes SSID.Enable + AP.Enable, not security',
        () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => uspSuccess());

      final original = [makeNetwork(enabled: true)];
      final current = [makeNetwork(enabled: false)];

      await sent(writeSvc.saveAdvanced(original: original, current: current));

      final captured = verify(() => mockUsp.set(captureAny(),
          allowPartial: any(named: 'allowPartial'))).captured;
      final keys = <String>{};
      for (final arg in captured) {
        if (arg is Map) keys.addAll(arg.keys.cast<String>());
      }
      // Both enable layers are written…
      expect(keys, contains('Device.WiFi.SSID.1.Enable'));
      expect(keys, contains('Device.WiFi.AccessPoint.1.Enable'));
      // …but the security/advertisement params are NOT re-sent on a pure
      // enable toggle (mirrors saveQuickSetup gating).
      expect(keys,
          isNot(contains('Device.WiFi.AccessPoint.1.Security.KeyPassphrase')));
      expect(keys,
          isNot(contains('Device.WiFi.AccessPoint.1.Security.ModeEnabled')));
      expect(
          keys,
          isNot(
              contains('Device.WiFi.AccessPoint.1.SSIDAdvertisementEnabled')));
    });

    // -----------------------------------------------------------------------
    // 6 GHz security override (#1073, #1142) — saveAdvanced must apply the
    // same _securityModeFor6GHz coercion as saveQuickSetup, so both save
    // paths write a firmware-valid mode on 6 GHz.
    // -----------------------------------------------------------------------

    /// Returns the value written to AccessPoint.1 Security.ModeEnabled after a
    /// mode change on the given band, or null if it was never sent.
    Future<String?> capturedModeEnabled({
      required String band,
      required String selectedMode,
    }) async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => uspSuccess());
      // Baseline mode differs from every selectedMode under test so the
      // security diff always fires (WPA2-in == WPA2-baseline would send nothing).
      final original = [
        makeNetwork(band: band, securityMode: 'WPA3-Personal-Transition')
      ];
      final current = [makeNetwork(band: band, securityMode: selectedMode)];

      await sent(writeSvc.saveAdvanced(original: original, current: current));

      final captured = verify(() => mockUsp.set(captureAny(),
          allowPartial: any(named: 'allowPartial'))).captured;
      const key = 'Device.WiFi.AccessPoint.1.Security.ModeEnabled';
      for (final arg in captured) {
        if (arg is Map && arg.containsKey(key)) return arg[key] as String?;
      }
      return null;
    }

    test('6 GHz + OWE selected → sends OWE verbatim', () async {
      expect(
        await capturedModeEnabled(band: '6GHz', selectedMode: 'OWE'),
        'OWE',
      );
    });

    test('6 GHz + None (open) selected → normalized to OWE', () async {
      expect(
        await capturedModeEnabled(band: '6GHz', selectedMode: 'None'),
        'OWE',
      );
    });

    test('6 GHz + WPA2-Personal selected → forced to WPA3-Personal', () async {
      expect(
        await capturedModeEnabled(band: '6GHz', selectedMode: 'WPA2-Personal'),
        'WPA3-Personal',
      );
    });

    test('5 GHz + None selected → written verbatim (no 6 GHz override)',
        () async {
      expect(
        await capturedModeEnabled(band: '5GHz', selectedMode: 'None'),
        'None',
      );
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

    test('writes AP.Enable but not Security when only enabled toggled',
        () async {
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

      await sent(writeSvc.saveQuickSetup(
        original: original,
        current: current,
        status: status,
      ));

      final keys = capturedKeys();
      // SSID enable write happens…
      expect(keys, contains('Device.WiFi.SSID.3.Enable'));
      // …and AP.Enable is mirrored so the AP actually stops broadcasting (#972)…
      expect(keys, contains('Device.WiFi.AccessPoint.3.Enable'));
      // …but the AP security layer (KeyPassphrase / Security.*) must NOT be
      // touched when only the enabled flag changed.
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

      await sent(writeSvc.saveQuickSetup(
        original: original,
        current: current,
        status: status,
      ));

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

    test(
        'a name + password change is ONE SET with allowPartial, '
        'carrying both layers (#1499)', () async {
      // Every WiFi SET reloads all radios on FL-WRT 2.0, so a save split into
      // one SET per SSID / AP only ever had a live connection under the first
      // write (#1499 log: SSID.1 25.3 s, SSID.2 26.9 s, then failure).
      final mainAgg =
          WifiSettingsTestData.createQuickSetupAggregate(keyPassphrase: '');
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
        quickSetupMain:
            mainOrig.copyWith(ssid: 'NewHome', password: 'secret12'),
      );

      final result = await sent(writeSvc.saveQuickSetup(
        original: original,
        current: current,
        status: WifiSettingsStatus(quickSetupMainAggregate: mainAgg),
      ));

      final sets = capturedSets(mockUsp);
      expect(sets, hasLength(1));
      expect(sets.single.allowPartial, isTrue);
      expect(sets.single.params, {
        'Device.WiFi.SSID.1.SSID': 'NewHome',
        'Device.WiFi.SSID.1.Enable': true,
        'Device.WiFi.SSID.2.SSID': 'NewHome',
        'Device.WiFi.SSID.2.Enable': true,
        'Device.WiFi.AccessPoint.1.Security.ModeEnabled': 'WPA2-Personal',
        'Device.WiFi.AccessPoint.1.Security.KeyPassphrase': 'secret12',
        'Device.WiFi.AccessPoint.2.Security.ModeEnabled': 'WPA2-Personal',
        'Device.WiFi.AccessPoint.2.Security.KeyPassphrase': 'secret12',
      });
      expect(result.outcome, WifiWriteOutcome.confirmed);
      expect(result.written, sets.single.params);
    });

    group('outcome', () {
      final mainAgg = WifiSettingsTestData.createQuickSetupAggregate(
        keyPassphrase: '',
        supportedSecurityModes: const ['WPA2-Personal'],
        ssidInstancePaths: const ['Device.WiFi.SSID.1.'],
        apInstancePaths: const ['Device.WiFi.AccessPoint.1.'],
      );
      const mainOrig = WifiQuickSetupSettings(
        isGuest: false,
        enabled: true,
        ssid: 'Home',
        password: '',
        securityMode: 'WPA2-Personal',
        supportedSecurityModes: ['WPA2-Personal'],
      );
      late WifiSettingsSettings original;
      setUp(() {
        original = WifiSettingsSettings(
          networks: [makeNetwork()],
          quickSetupEnabled: true,
          quickSetupMain: mainOrig,
        );
      });
      Future<WifiWriteOutcome> renameAndSave() async =>
          (await sent(writeSvc.saveQuickSetup(
            original: original,
            current: original.copyWith(
                quickSetupMain: mainOrig.copyWith(ssid: 'NewHome')),
            status: WifiSettingsStatus(quickSetupMainAggregate: mainAgg),
          )))
              .outcome;

      test('a lost reply is "unanswered", not a failure', () async {
        when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
            .thenAnswer((_) async => uspUnanswered('Device.WiFi.SSID.1.SSID'));

        expect(await renameAndSave(), WifiWriteOutcome.unanswered);
      });

      test(
          'Remote Assistance: an HTTP 5xx with no fault code is "unanswered" '
          '— Guardian could not reach a router that was reloading its radios '
          '(CLOUD_GUARDIANS#215)', () async {
        when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
            .thenAnswer((_) async => uspFailure(
                  path: 'Device.WiFi.SSID.1.SSID',
                  errorCode: 9999,
                  // Verbatim from #215's log.
                  errorMessage:
                      'Transport error: Transport error: HTTP error: HTTP 500',
                ));

        expect(await renameAndSave(), WifiWriteOutcome.unanswered);
      });

      test('an HTTP 4xx still throws — a 401 must end the session (#1627)',
          () async {
        when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
            .thenAnswer((_) async => uspFailure(
                  path: 'Device.WiFi.SSID.1.SSID',
                  errorCode: 9999,
                  errorMessage: 'Transport error: HTTP error: HTTP 401',
                ));

        expect(renameAndSave(), throwsA(isA<ServiceError>()));
      });

      test('a refusal still throws — 9999 with a fault inside is an answer',
          () async {
        when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
            .thenAnswer((_) async => uspFailure(
                  path: 'Device.WiFi.SSID.1.SSID',
                  errorCode: 9999,
                  errorMessage: 'Transport error: Protocol error: Received '
                      'error response: Invalid value (code: 7012)',
                ));

        expect(renameAndSave(), throwsA(isA<UspCompleteFailureError>()));
      });

      test('nothing changed sends no SET and is confirmed', () async {
        final result = await sent(writeSvc.saveQuickSetup(
          original: original,
          current: original,
          status: WifiSettingsStatus(quickSetupMainAggregate: mainAgg),
        ));

        expect(result.outcome, WifiWriteOutcome.confirmed);
        expect(result.written, isEmpty);
        verifyNever(
            () => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')));
      });

      test('an invalid SSID throws InvalidInputError before any SET', () {
        for (final bad in ['', 'x' * 33]) {
          expect(
            () => writeSvc.saveQuickSetup(
              original: original,
              current: original.copyWith(
                  quickSetupMain: mainOrig.copyWith(ssid: bad)),
              status: WifiSettingsStatus(quickSetupMainAggregate: mainAgg),
            ),
            throwsA(isA<InvalidInputError>()),
            reason: 'ssid "${bad.length > 3 ? '${bad.length} chars' : bad}"',
          );
        }
        verifyNever(
            () => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')));
      });

      group('proof — only what this save changes is read back', () {
        WifiWritePlan planFor(WifiQuickSetupSettings edited) =>
            writeSvc.saveQuickSetup(
              original: original,
              current: original.copyWith(quickSetupMain: edited),
              status: WifiSettingsStatus(quickSetupMainAggregate: mainAgg),
            );

        test(
            'a password-only change has NO proof — the unchanged ModeEnabled '
            'it resends would read back as the old value and fake a success '
            '(CLOUD_GUARDIANS#215)', () {
          final plan = planFor(mainOrig.copyWith(password: 'secret12'));

          // The SET still carries the mode alongside the passphrase…
          expect(plan.params.keys, {
            'Device.WiFi.AccessPoint.1.Security.ModeEnabled',
            'Device.WiFi.AccessPoint.1.Security.KeyPassphrase',
          });
          // …but neither can prove the write landed: one is unchanged, the
          // other reads back empty.
          expect(plan.proof, isEmpty);
        });

        test('a rename proves itself by the new SSID', () {
          final plan = planFor(mainOrig.copyWith(ssid: 'NewHome'));

          expect(plan.proof, {'Device.WiFi.SSID.1.SSID': 'NewHome'});
        });

        test('a mode change proves itself by the new mode', () {
          final plan =
              planFor(mainOrig.copyWith(securityMode: 'WPA3-Personal'));

          expect(
            plan.proof,
            {'Device.WiFi.AccessPoint.1.Security.ModeEnabled': 'WPA3-Personal'},
          );
        });

        test('an enable toggle proves itself on both rows (#972)', () {
          final plan = planFor(mainOrig.copyWith(enabled: false));

          expect(plan.proof, {
            'Device.WiFi.SSID.1.Enable': false,
            'Device.WiFi.AccessPoint.1.Enable': false,
          });
        });
      });
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

      await sent(writeSvc.saveQuickSetup(
        original: original,
        current: current,
        status: status,
      ));

      final keys = capturedKeys();
      expect(keys.any((k) => k.contains('Security.ModeEnabled')), isTrue);
      // Empty passphrase must not be sent to firmware.
      expect(keys.any((k) => k.contains('Security.KeyPassphrase')), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // 6 GHz security override (_securityModeFor6GHz) — issue #1073
  //
  // Wi-Fi 6E mandates WPA3, so on 6 GHz the service overrides the selected
  // mode: open modes ('None' / 'OWE' / '') → 'OWE' (the TR-181 token firmware
  // accepts for Enhanced Open), everything else → 'WPA3-Personal'. On other
  // bands the selected mode is written verbatim. These tests assert the exact
  // ModeEnabled value sent to firmware, guarding against a regression to the
  // old invalid 'Enhanced-Open' token.
  // -------------------------------------------------------------------------

  group('saveQuickSetup — 6 GHz security override (#1073)', () {
    late MockUspClient mockUsp;
    late UspWifiSettingsService writeSvc;

    setUp(() {
      mockUsp = MockUspClient();
      writeSvc = UspWifiSettingsService(mockUsp);
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => uspSuccess());
    });

    WifiNetworkUIModel makeNetwork({
      required String band,
      String ssidInstancePath = 'Device.WiFi.SSID.1.',
      String accessPointInstancePath = 'Device.WiFi.AccessPoint.1.',
    }) =>
        WifiNetworkUIModel(
          ssidInstancePath: ssidInstancePath,
          accessPointInstancePath: accessPointInstancePath,
          radioInstancePath: 'Device.WiFi.Radio.1.',
          ssid: 'Home',
          enabled: true,
          ssidAdvertisementEnabled: true,
          supportedSecurityModes: const [
            'None',
            'WPA2-Personal',
            'WPA3-Personal',
            'OWE'
          ],
          securityMode: 'WPA2-Personal',
          keyPassphrase: '',
          isGuest: false,
          band: band,
          channel: 6,
          channelBandwidth: '20MHz',
          autoChannelEnable: true,
          possibleChannels: const [1, 6, 11],
          operatingStandards: 'ax',
          supportedStandards: 'ax',
        );

    /// Returns the value written to `<ap>Security.ModeEnabled`, or null if the
    /// param was never sent.
    Future<String?> capturedModeEnabled({
      required String band,
      required String selectedMode,
      String ap = 'Device.WiFi.AccessPoint.1.',
    }) async {
      final agg = WifiQuickSetupNetwork(
        isGuest: false,
        ssid: 'Home',
        securityMode: 'WPA2-Personal',
        keyPassphrase: '',
        supportedSecurityModes: const [
          'None',
          'WPA2-Personal',
          'WPA3-Personal',
          'OWE'
        ],
        ssidInstancePaths: const ['Device.WiFi.SSID.1.'],
        apInstancePaths: [ap],
      );
      // Baseline mode differs from every selectedMode under test so the
      // security diff always fires (otherwise WPA2-in == WPA2-baseline would
      // be a no-op and nothing would be sent).
      const orig = WifiQuickSetupSettings(
        isGuest: false,
        enabled: true,
        ssid: 'Home',
        password: '',
        securityMode: 'WPA3-Personal-Transition',
        supportedSecurityModes: [
          'None',
          'WPA2-Personal',
          'WPA3-Personal',
          'OWE'
        ],
      );

      final original = WifiSettingsSettings(
        networks: [
          makeNetwork(band: band, accessPointInstancePath: ap)
              .copyWith(securityMode: 'WPA3-Personal-Transition')
        ],
        quickSetupEnabled: true,
        quickSetupMain: orig,
      );
      final current = original.copyWith(
        quickSetupMain: orig.copyWith(securityMode: selectedMode),
      );
      final status = WifiSettingsStatus(quickSetupMainAggregate: agg);

      await sent(writeSvc.saveQuickSetup(
        original: original,
        current: current,
        status: status,
      ));

      final captured = verify(() => mockUsp.set(captureAny(),
          allowPartial: any(named: 'allowPartial'))).captured;
      for (final arg in captured) {
        if (arg is Map && arg.containsKey('${ap}Security.ModeEnabled')) {
          return arg['${ap}Security.ModeEnabled'] as String?;
        }
      }
      return null;
    }

    test('6 GHz + OWE selected → sends OWE verbatim', () async {
      expect(
        await capturedModeEnabled(band: '6GHz', selectedMode: 'OWE'),
        'OWE',
      );
    });

    test('6 GHz + None (open) selected → normalized to OWE', () async {
      expect(
        await capturedModeEnabled(band: '6GHz', selectedMode: 'None'),
        'OWE',
      );
    });

    test('6 GHz + WPA2-Personal selected → forced to WPA3-Personal', () async {
      // Pass a non-WPA3 mode so this genuinely exercises the coercion branch
      // (WPA3 input would pass even if the override were removed).
      expect(
        await capturedModeEnabled(band: '6GHz', selectedMode: 'WPA2-Personal'),
        'WPA3-Personal',
      );
    });

    test('2.4 GHz + OWE selected → written verbatim (no 6 GHz override)',
        () async {
      expect(
        await capturedModeEnabled(band: '2.4GHz', selectedMode: 'OWE'),
        'OWE',
      );
    });

    test('5 GHz + None selected → written verbatim (no 6 GHz override)',
        () async {
      expect(
        await capturedModeEnabled(band: '5GHz', selectedMode: 'None'),
        'None',
      );
    });
  });
}
