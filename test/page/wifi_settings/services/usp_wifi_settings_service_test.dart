import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/generated/wi_fi_access_points.g.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';
import 'package:privacy_gui/usp/services/usp_service.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_settings_service.dart';

class MockUspService extends Mock implements UspService {}

void main() {
  late UspWifiSettingsService svc;

  setUp(() {
    svc = UspWifiSettingsService(MockUspService());
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
}
