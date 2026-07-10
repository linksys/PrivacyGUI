import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_data_service.dart';

class MockUspClient extends Mock implements UspClient {}

/// Raw USP response map for a dual-band radio setup (2.4 GHz + 5 GHz).
Map<String, dynamic> _buildRadiosResponse() => {
      'Device.WiFi.Radio.1.Enable': true,
      'Device.WiFi.Radio.1.Status': 'Up',
      'Device.WiFi.Radio.1.Channel': 6,
      'Device.WiFi.Radio.1.OperatingFrequencyBand': '2.4GHz',
      'Device.WiFi.Radio.1.OperatingChannelBandwidth': '20MHz',
      'Device.WiFi.Radio.1.PossibleChannels': '1,6,11',
      'Device.WiFi.Radio.1.OperatingStandards': 'n',
      'Device.WiFi.Radio.1.SupportedStandards': 'b,g,n',
      'Device.WiFi.Radio.1.TransmitPower': 100,
      'Device.WiFi.Radio.1.MaxBitRate': 300,
      'Device.WiFi.Radio.1.AutoChannelEnable': true,
      'Device.WiFi.Radio.1.IEEE80211hEnabled': false,
      'Device.WiFi.Radio.1.SupportedOperatingChannelBandwidths':
          'Auto,20MHz,40MHz',
      'Device.WiFi.Radio.2.Enable': true,
      'Device.WiFi.Radio.2.Status': 'Up',
      'Device.WiFi.Radio.2.Channel': 36,
      'Device.WiFi.Radio.2.OperatingFrequencyBand': '5GHz',
      'Device.WiFi.Radio.2.OperatingChannelBandwidth': '80MHz',
      'Device.WiFi.Radio.2.PossibleChannels': '36,40,44,48',
      'Device.WiFi.Radio.2.OperatingStandards': 'ax',
      'Device.WiFi.Radio.2.SupportedStandards': 'a,n,ac,ax',
      'Device.WiFi.Radio.2.TransmitPower': 100,
      'Device.WiFi.Radio.2.MaxBitRate': 2400,
      'Device.WiFi.Radio.2.AutoChannelEnable': false,
      'Device.WiFi.Radio.2.IEEE80211hEnabled': false,
      'Device.WiFi.Radio.2.SupportedOperatingChannelBandwidths':
          'Auto,20MHz,40MHz,80MHz',
    };

/// Raw USP response map for 3 SSIDs (2 main + 1 guest).
Map<String, dynamic> _buildSsidsResponse() => {
      'Device.WiFi.SSID.1.SSID': 'Home',
      'Device.WiFi.SSID.1.Enable': true,
      'Device.WiFi.SSID.1.Status': 'Up',
      'Device.WiFi.SSID.1.BSSID': 'AA:BB:CC:DD:EE:01',
      'Device.WiFi.SSID.1.LowerLayers': 'Device.WiFi.Radio.1.',
      'Device.WiFi.SSID.1.Alias': 'wifi-2g',
      'Device.WiFi.SSID.2.SSID': 'Home',
      'Device.WiFi.SSID.2.Enable': true,
      'Device.WiFi.SSID.2.Status': 'Up',
      'Device.WiFi.SSID.2.BSSID': 'AA:BB:CC:DD:EE:02',
      'Device.WiFi.SSID.2.LowerLayers': 'Device.WiFi.Radio.2.',
      'Device.WiFi.SSID.2.Alias': 'wifi-5g',
      'Device.WiFi.SSID.3.SSID': 'Home-Guest',
      'Device.WiFi.SSID.3.Enable': true,
      'Device.WiFi.SSID.3.Status': 'Up',
      'Device.WiFi.SSID.3.BSSID': 'AA:BB:CC:DD:EE:03',
      'Device.WiFi.SSID.3.LowerLayers': 'Device.WiFi.Radio.1.',
      'Device.WiFi.SSID.3.Alias': 'wifi-2g-guest',
    };

/// Raw USP response map for 3 access points.
Map<String, dynamic> _buildAccessPointsResponse() => {
      'Device.WiFi.AccessPoint.1.Enable': true,
      'Device.WiFi.AccessPoint.1.Status': 'Enabled',
      'Device.WiFi.AccessPoint.1.Security.ModesSupported':
          'None,WPA2-Personal,WPA3-Personal',
      'Device.WiFi.AccessPoint.1.Security.ModeEnabled': 'WPA2-Personal',
      'Device.WiFi.AccessPoint.1.Security.EncryptionMode': 'AES',
      'Device.WiFi.AccessPoint.1.Security.KeyPassphrase': 'password123',
      'Device.WiFi.AccessPoint.1.SSIDAdvertisementEnabled': true,
      'Device.WiFi.AccessPoint.1.SSIDReference': 'Device.WiFi.SSID.1.',
      'Device.WiFi.AccessPoint.2.Enable': true,
      'Device.WiFi.AccessPoint.2.Status': 'Enabled',
      'Device.WiFi.AccessPoint.2.Security.ModesSupported':
          'WPA2-Personal,WPA3-Personal',
      'Device.WiFi.AccessPoint.2.Security.ModeEnabled': 'WPA3-Personal',
      'Device.WiFi.AccessPoint.2.Security.EncryptionMode': 'AES',
      'Device.WiFi.AccessPoint.2.Security.KeyPassphrase': 'password456',
      'Device.WiFi.AccessPoint.2.SSIDAdvertisementEnabled': true,
      'Device.WiFi.AccessPoint.2.SSIDReference': 'Device.WiFi.SSID.2.',
      'Device.WiFi.AccessPoint.3.Enable': true,
      'Device.WiFi.AccessPoint.3.Status': 'Enabled',
      'Device.WiFi.AccessPoint.3.Security.ModesSupported':
          'None,WPA2-Personal,WPA3-Personal',
      'Device.WiFi.AccessPoint.3.Security.ModeEnabled': 'WPA2-Personal',
      'Device.WiFi.AccessPoint.3.Security.EncryptionMode': 'AES',
      'Device.WiFi.AccessPoint.3.Security.KeyPassphrase': 'guestpass',
      'Device.WiFi.AccessPoint.3.SSIDAdvertisementEnabled': true,
      'Device.WiFi.AccessPoint.3.SSIDReference': 'Device.WiFi.SSID.3.',
    };

/// Stubs `mockUsp.get()` to return the right response based on the requested
/// paths. Each codegen `.fetch()` requests distinct base paths, so we can
/// dispatch based on the first path element.
void _stubAllFetches(MockUspClient mockUsp) {
  when(() => mockUsp.get(any(), priority: any(named: 'priority')))
      .thenAnswer((invocation) async {
    final paths = invocation.positionalArguments[0] as List<String>;
    final first = paths.isNotEmpty ? paths.first : '';
    if (first.startsWith('Device.WiFi.Radio.')) {
      return _buildRadiosResponse();
    } else if (first.startsWith('Device.WiFi.SSID.')) {
      return _buildSsidsResponse();
    } else if (first.startsWith('Device.WiFi.AccessPoint.') &&
        first.contains('AssociatedDevice')) {
      // WifiClients paths
      return <String, dynamic>{};
    } else if (first.startsWith('Device.WiFi.AccessPoint.')) {
      return _buildAccessPointsResponse();
    }
    return <String, dynamic>{};
  });
}

/// Stubs fetches for a single 5 GHz radio whose `PossibleChannels` value is
/// [possibleChannels]. Used to exercise the shared `parsePossibleChannels` via
/// the public `fetch()` entry point.
void _stubRadioWithPossibleChannels(
  MockUspClient mockUsp,
  String possibleChannels,
) {
  when(() => mockUsp.get(any(), priority: any(named: 'priority')))
      .thenAnswer((invocation) async {
    final paths = invocation.positionalArguments[0] as List<String>;
    final first = paths.isNotEmpty ? paths.first : '';
    if (first.startsWith('Device.WiFi.Radio.')) {
      return {
        'Device.WiFi.Radio.1.Enable': true,
        'Device.WiFi.Radio.1.Status': 'Up',
        'Device.WiFi.Radio.1.Channel': 36,
        'Device.WiFi.Radio.1.OperatingFrequencyBand': '5GHz',
        'Device.WiFi.Radio.1.OperatingChannelBandwidth': '80MHz',
        'Device.WiFi.Radio.1.PossibleChannels': possibleChannels,
        'Device.WiFi.Radio.1.OperatingStandards': 'ax',
        'Device.WiFi.Radio.1.SupportedStandards': 'a,n,ac,ax',
        'Device.WiFi.Radio.1.TransmitPower': 100,
        'Device.WiFi.Radio.1.MaxBitRate': 2400,
        'Device.WiFi.Radio.1.AutoChannelEnable': false,
        'Device.WiFi.Radio.1.IEEE80211hEnabled': false,
        'Device.WiFi.Radio.1.SupportedOperatingChannelBandwidths':
            'Auto,20MHz,40MHz,80MHz',
      };
    }
    return <String, dynamic>{};
  });
}

void main() {
  late MockUspClient mockUsp;
  late UspWifiDataService svc;

  setUp(() {
    mockUsp = MockUspClient();
    svc = UspWifiDataService(mockUsp);
  });

  // -------------------------------------------------------------------------
  // fetch — success
  // -------------------------------------------------------------------------

  group('fetch', () {
    test('returns result with all fields populated', () async {
      _stubAllFetches(mockUsp);

      final result = await svc.fetch();

      // codegenContext
      expect(result.codegenContext.raw.radios.items.length, 2);
      expect(result.codegenContext.raw.ssids.items.length, 3);
      expect(result.codegenContext.raw.accessPoints.items.length, 3);

      // radioModels built from 2 radios
      expect(result.radioModels.length, 2);
      expect(result.radioModels[0].band, '2.4GHz');
      expect(result.radioModels[1].band, '5GHz');

      // wifiClientMap (empty since no clients stubbed)
      expect(result.wifiClientMap, isEmpty);
    });

    test('maps USP error to ServiceError on fetch failure', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenThrow(Exception('USP timeout'));

      expect(() => svc.fetch(), throwsA(isA<ServiceError>()));
    });
  });

  // -------------------------------------------------------------------------
  // radio UI models — radio-AP cross-reference
  // -------------------------------------------------------------------------

  group('radio UI models', () {
    test('groups access points under correct radio', () async {
      _stubAllFetches(mockUsp);

      final result = await svc.fetch();

      // Radio 1 (2.4GHz): SSID.1 + SSID.3 (guest) → AP.1 + AP.3
      final radio1 = result.radioModels[0];
      expect(radio1.accessPoints.length, 2);
      expect(radio1.accessPoints[0].ssidName, 'Home');
      expect(radio1.accessPoints[1].ssidName, 'Home-Guest');
      // Guest detection via alias suffix (-guest), not instance ordering.
      expect(radio1.accessPoints[0].isGuest, isFalse);
      expect(radio1.accessPoints[1].isGuest, isTrue);

      // Radio 2 (5GHz): SSID.2 → AP.2
      final radio2 = result.radioModels[1];
      expect(radio2.accessPoints.length, 1);
      expect(radio2.accessPoints[0].ssidName, 'Home');
    });

    test('populates radio fields correctly', () async {
      _stubAllFetches(mockUsp);

      final result = await svc.fetch();

      final radio1 = result.radioModels[0];
      expect(radio1.channel, 6);
      expect(radio1.autoChannelEnable, true);
      expect(radio1.channelBandwidth, '20MHz');
      expect(radio1.enable, true);
      expect(radio1.maxBitRate, 300);

      final radio2 = result.radioModels[1];
      expect(radio2.channel, 36);
      expect(radio2.autoChannelEnable, false);
      expect(radio2.channelBandwidth, '80MHz');
      expect(radio2.maxBitRate, 2400);
    });

    test('threads IEEE80211hEnabled into radio model isDfsEnabled', () async {
      _stubAllFetches(mockUsp);

      final result = await svc.fetch();

      // Both stub radios have IEEE80211hEnabled = false. The dashboard radio
      // model carries the per-radio DFS flag verbatim (channel filtering happens
      // in the channel dialog, not here).
      expect(result.radioModels[0].isDfsEnabled, isFalse);
      expect(result.radioModels[1].isDfsEnabled, isFalse);
    });

    test('AC7: enriches possibleChannels from PossibleChannels at fetch time',
        () async {
      _stubAllFetches(mockUsp);

      final result = await svc.fetch();

      // Radio 1 stub PossibleChannels = "1,6,11"; Radio 2 = "36,40,44,48".
      expect(result.radioModels[0].possibleChannels, [1, 6, 11]);
      expect(result.radioModels[1].possibleChannels, [36, 40, 44, 48]);
    });

    test('handles empty collections', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async => <String, dynamic>{});

      final result = await svc.fetch();

      expect(result.radioModels, isEmpty);
      expect(result.wifiClientMap, isEmpty);
      expect(result.connectionDetailMap, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // PossibleChannels parsing — range notation, sentinels, malformed tokens
  // (W-3 / W-4). Exercises the shared parsePossibleChannels via fetch().
  // -------------------------------------------------------------------------

  group('PossibleChannels parsing', () {
    test('expands mixed range + single notation ("1-3,6")', () async {
      _stubRadioWithPossibleChannels(mockUsp, '1-3,6');

      final result = await svc.fetch();

      expect(result.radioModels.single.possibleChannels, [1, 2, 3, 6]);
    });

    test('expands full range notation ("1-13")', () async {
      _stubRadioWithPossibleChannels(mockUsp, '1-13');

      final result = await svc.fetch();

      expect(
        result.radioModels.single.possibleChannels,
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13],
      );
    });

    test('inverted range ("11-1") degrades to empty without throwing',
        () async {
      _stubRadioWithPossibleChannels(mockUsp, '11-1');

      final result = await svc.fetch();

      expect(result.radioModels.single.possibleChannels, isEmpty);
    });

    test('filters out TR-181 "0" auto/any sentinel ("0,1,6,11")', () async {
      _stubRadioWithPossibleChannels(mockUsp, '0,1,6,11');

      final result = await svc.fetch();

      expect(result.radioModels.single.possibleChannels, [1, 6, 11]);
    });

    test('skips malformed range token ("1-2-3") without throwing', () async {
      _stubRadioWithPossibleChannels(mockUsp, '1-2-3');

      final result = await svc.fetch();

      // The malformed token yields nothing; parsing does not throw.
      expect(result.radioModels.single.possibleChannels, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // buildBssidToBandMap
  // -------------------------------------------------------------------------

  group('buildBssidToBandMap', () {
    test('maps BSSID to band via SSID.LowerLayers → Radio', () {
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
          supportedOperatingChannelBandwidths: '20MHz,40MHz',
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
          maxBitRate: 2400,
          autoChannelEnable: false,
          ieee80211hEnabled: false,
          supportedOperatingChannelBandwidths: '20MHz,40MHz,80MHz',
        ),
      ]);

      final result =
          UspWifiDataService.buildBssidToBandMap(ssids: ssids, radios: radios);

      expect(result, {
        'AA:BB:CC:DD:EE:01': '2.4GHz',
        'AA:BB:CC:DD:EE:02': '5GHz',
      });
    });

    test('normalizes BSSID to uppercase', () {
      final ssids = WiFiSsids(items: [
        WiFiSsid(
          instancePath: 'Device.WiFi.SSID.1.',
          ssid: 'Home',
          enable: true,
          status: 'Up',
          bssid: 'aa:bb:cc:dd:ee:01', // lowercase
          lowerLayers: 'Device.WiFi.Radio.1.',
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
          supportedOperatingChannelBandwidths: '20MHz,40MHz',
        ),
      ]);

      final result =
          UspWifiDataService.buildBssidToBandMap(ssids: ssids, radios: radios);

      expect(result.keys.single, 'AA:BB:CC:DD:EE:01');
    });

    test('skips SSID with empty BSSID', () {
      final ssids = WiFiSsids(items: [
        WiFiSsid(
          instancePath: 'Device.WiFi.SSID.1.',
          ssid: 'Home',
          enable: true,
          status: 'Up',
          bssid: '', // empty
          lowerLayers: 'Device.WiFi.Radio.1.',
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
          supportedOperatingChannelBandwidths: '20MHz,40MHz',
        ),
      ]);

      final result =
          UspWifiDataService.buildBssidToBandMap(ssids: ssids, radios: radios);

      expect(result, isEmpty);
    });

    test('returns empty map when no radios', () {
      final ssids = WiFiSsids(items: [
        WiFiSsid(
          instancePath: 'Device.WiFi.SSID.1.',
          ssid: 'Home',
          enable: true,
          status: 'Up',
          bssid: 'AA:BB:CC:DD:EE:01',
          lowerLayers: 'Device.WiFi.Radio.1.',
        ),
      ]);
      final radios = WiFiRadios(items: []);

      final result =
          UspWifiDataService.buildBssidToBandMap(ssids: ssids, radios: radios);

      expect(result, isEmpty);
    });
  });
}
