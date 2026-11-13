import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_band.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_config.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_service.dart';
import 'package:privacy_gui/page/internet_settings/services/auto_ipoe_service.dart';

import '../../../mocks/test_data/internet_settings_test_data.dart';
import '../../../mocks/test_data/usp_envelope_test_data.dart';

class MockUspClient extends Mock implements UspClient {}

class MockAutoIPoEService extends Mock implements AutoIPoEService {}

void main() {
  late MockUspClient mockUsp;
  late PnpService service;

  void setupSetMocks() {
    when(() => mockUsp.set(any())).thenAnswer((_) async => {
          'success': true,
          'result': {'data': <String, dynamic>{}}
        });
    when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
        .thenAnswer((_) async => {
              'success': true,
              'result': {'data': <String, dynamic>{}}
            });
    when(() =>
            mockUsp.setOrdered(any(), allowPartial: any(named: 'allowPartial')))
        .thenAnswer((_) async => {
              'success': true,
              'result': {'data': <String, dynamic>{}}
            });
  }

  setUp(() {
    mockUsp = MockUspClient();
    service = PnpService(mockUsp);
  });

  // #1098: on FLWRT 2.0 a WAN with no connection has no IPv4Address row at all
  // (measured for #1615 on FW 2.0.2.26091803: Status `Dormant`,
  // IPv4AddressNumberOfEntries `0`, no IPv4Address.{i} row). That is a WAN
  // with no internet, which the no-internet page is for, not a router that
  // cannot be read.
  group('PnpService.checkInternetConnected — WAN with no address (#1098)', () {
    /// The WAN status read: the WAN on Interface.5, its address on row 3.
    void stubWan({String status = 'Up', bool hasAddress = true}) {
      when(() => mockUsp.get(any())).thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
        if (paths.contains('Device.IP.Interface.*.Alias')) {
          return InternetSettingsTestData.interfaceAliases();
        }
        return InternetSettingsTestData.wanStatus(
            status: status, ipAddress: '203.0.113.7', hasAddress: hasAddress);
      });
    }

    test('returns false instead of throwing when the WAN has no address',
        () async {
      stubWan(status: 'Dormant', hasAddress: false);

      expect(await service.checkInternetConnected(), isFalse,
          reason: 'no address row is a WAN with no internet, which the '
              'no-internet page is for, not a router that cannot be read');
    });

    test('an Up WAN with no address is not connected', () async {
      stubWan(hasAddress: false);

      expect(await service.checkInternetConnected(), isFalse);
    });

    test('still throws when every GET comes back empty', () async {
      // #1098's original log: the router answered every GET with no data. No
      // WAN interface resolves, so this stays a read failure (#1132).
      when(() => mockUsp.get(any())).thenAnswer((_) async => {});

      await expectLater(
          service.checkInternetConnected(), throwsA(isA<ServiceError>()));
    });

    test('a WAN that is up with an address still reads as connected', () async {
      stubWan();

      expect(await service.checkInternetConnected(), isTrue);
    });

    test('a WAN with an address that is not Up is not connected', () async {
      stubWan(status: 'Down');

      expect(await service.checkInternetConnected(), isFalse);
    });
  });

  group('PnpService.fetchWizardData — guest detection via alias', () {
    // Two radios, each with a main + guest SSID. Guest is identified purely by
    // the `-guest` alias suffix (see wifi_guest_detection), NOT instance order.
    const wifiSsidsResponse = <String, dynamic>{
      'Device.WiFi.SSID.1.SSID': 'MyHome',
      'Device.WiFi.SSID.1.Enable': true,
      'Device.WiFi.SSID.1.Status': 'Up',
      'Device.WiFi.SSID.1.BSSID': 'AA:BB:CC:DD:EE:01',
      'Device.WiFi.SSID.1.LowerLayers': 'Device.WiFi.Radio.1.',
      'Device.WiFi.SSID.1.Alias': 'wifi-2g',
      'Device.WiFi.SSID.2.SSID': 'MyHome',
      'Device.WiFi.SSID.2.Enable': true,
      'Device.WiFi.SSID.2.Status': 'Up',
      'Device.WiFi.SSID.2.BSSID': 'AA:BB:CC:DD:EE:02',
      'Device.WiFi.SSID.2.LowerLayers': 'Device.WiFi.Radio.2.',
      'Device.WiFi.SSID.2.Alias': 'wifi-5g',
      'Device.WiFi.SSID.3.SSID': 'MyHome-Guest',
      'Device.WiFi.SSID.3.Enable': false,
      'Device.WiFi.SSID.3.Status': 'Down',
      'Device.WiFi.SSID.3.BSSID': 'AA:BB:CC:DD:EE:03',
      'Device.WiFi.SSID.3.LowerLayers': 'Device.WiFi.Radio.1.',
      'Device.WiFi.SSID.3.Alias': 'wifi-2g-guest',
      'Device.WiFi.SSID.4.SSID': 'MyHome-Guest',
      'Device.WiFi.SSID.4.Enable': false,
      'Device.WiFi.SSID.4.Status': 'Down',
      'Device.WiFi.SSID.4.BSSID': 'AA:BB:CC:DD:EE:04',
      'Device.WiFi.SSID.4.LowerLayers': 'Device.WiFi.Radio.2.',
      'Device.WiFi.SSID.4.Alias': 'wifi-5g-guest',
    };
    const wifiApsResponse = <String, dynamic>{
      'Device.WiFi.AccessPoint.1.Enable': true,
      'Device.WiFi.AccessPoint.1.Status': 'Enabled',
      'Device.WiFi.AccessPoint.1.Security.ModesSupported':
          'WPA2-Personal,WPA3-Personal',
      'Device.WiFi.AccessPoint.1.Security.ModeEnabled': 'WPA2-Personal',
      'Device.WiFi.AccessPoint.1.Security.EncryptionMode': 'AES',
      'Device.WiFi.AccessPoint.1.Security.KeyPassphrase': 'mainpass1',
      'Device.WiFi.AccessPoint.1.SSIDAdvertisementEnabled': true,
      'Device.WiFi.AccessPoint.1.SSIDReference': 'Device.WiFi.SSID.1.',
      'Device.WiFi.AccessPoint.2.Enable': true,
      'Device.WiFi.AccessPoint.2.Status': 'Enabled',
      'Device.WiFi.AccessPoint.2.Security.ModesSupported':
          'WPA2-Personal,WPA3-Personal',
      'Device.WiFi.AccessPoint.2.Security.ModeEnabled': 'WPA2-Personal',
      'Device.WiFi.AccessPoint.2.Security.EncryptionMode': 'AES',
      'Device.WiFi.AccessPoint.2.Security.KeyPassphrase': 'mainpass2',
      'Device.WiFi.AccessPoint.2.SSIDAdvertisementEnabled': true,
      'Device.WiFi.AccessPoint.2.SSIDReference': 'Device.WiFi.SSID.2.',
      'Device.WiFi.AccessPoint.3.Enable': false,
      'Device.WiFi.AccessPoint.3.Status': 'Disabled',
      'Device.WiFi.AccessPoint.3.Security.ModesSupported': '',
      'Device.WiFi.AccessPoint.3.Security.ModeEnabled': 'None',
      'Device.WiFi.AccessPoint.3.Security.EncryptionMode': 'None',
      'Device.WiFi.AccessPoint.3.Security.KeyPassphrase': 'guestpass1',
      'Device.WiFi.AccessPoint.3.SSIDAdvertisementEnabled': true,
      'Device.WiFi.AccessPoint.3.SSIDReference': 'Device.WiFi.SSID.3.',
      'Device.WiFi.AccessPoint.4.Enable': false,
      'Device.WiFi.AccessPoint.4.Status': 'Disabled',
      'Device.WiFi.AccessPoint.4.Security.ModesSupported': '',
      'Device.WiFi.AccessPoint.4.Security.ModeEnabled': 'None',
      'Device.WiFi.AccessPoint.4.Security.EncryptionMode': 'None',
      'Device.WiFi.AccessPoint.4.Security.KeyPassphrase': 'guestpass2',
      'Device.WiFi.AccessPoint.4.SSIDAdvertisementEnabled': true,
      'Device.WiFi.AccessPoint.4.SSIDReference': 'Device.WiFi.SSID.4.',
    };
    Map<String, dynamic> radioFields(int i, String band, int channel) => {
          'Device.WiFi.Radio.$i.Enable': true,
          'Device.WiFi.Radio.$i.Status': 'Up',
          'Device.WiFi.Radio.$i.Channel': channel,
          'Device.WiFi.Radio.$i.ChannelsInUse': '$channel',
          'Device.WiFi.Radio.$i.OperatingFrequencyBand': band,
          'Device.WiFi.Radio.$i.OperatingChannelBandwidth': '20MHz',
          'Device.WiFi.Radio.$i.PossibleChannels': '1,6,11',
          'Device.WiFi.Radio.$i.OperatingStandards': 'n',
          'Device.WiFi.Radio.$i.SupportedStandards': 'b,g,n',
          'Device.WiFi.Radio.$i.TransmitPower': 100,
          'Device.WiFi.Radio.$i.MaxBitRate': 300,
          'Device.WiFi.Radio.$i.AutoChannelEnable': true,
          'Device.WiFi.Radio.$i.IEEE80211hEnabled': false,
          'Device.WiFi.Radio.$i.SupportedOperatingChannelBandwidths':
              'Auto,20MHz,40MHz',
        };
    final wifiRadiosResponse = <String, dynamic>{
      ...radioFields(1, '2.4GHz', 6),
      ...radioFields(2, '5GHz', 36),
    };

    void stubWifiFetches() {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
        final first = paths.isNotEmpty ? paths.first : '';
        if (first.startsWith('Device.WiFi.SSID.')) {
          return wifiSsidsResponse;
        }
        if (first.startsWith('Device.WiFi.AccessPoint.')) {
          return wifiApsResponse;
        }
        if (first.startsWith('Device.WiFi.Radio.')) {
          return wifiRadiosResponse;
        }
        return <String, dynamic>{};
      });
    }

    test('classifies -guest alias SSIDs as guest, others as main', () async {
      stubWifiFetches();

      final result = await service.fetchWizardData();
      final config = result.wifiConfig;

      // Main network built from the non-guest SSIDs.
      expect(config.ssid, 'MyHome');
      // Guest network built from the -guest alias SSIDs.
      expect(config.guestSsid, 'MyHome-Guest');
      expect(config.guestEnabled, isFalse);
      expect(
          config.guestAccessPointInstancePaths,
          containsAll(
              ['Device.WiFi.AccessPoint.3.', 'Device.WiFi.AccessPoint.4.']));
      // Guest AP paths must not leak into the main path list.
      expect(config.accessPointInstancePaths,
          isNot(contains('Device.WiFi.AccessPoint.3.')));
    });
  });

  // usp-codegen 0.18 returns every row, including one with every value
  // blank, which 0.17 dropped (#1654).
  group('PnpService — rows with every value blank', () {
    // Every SSID leaf present, every value blank, on a row before the real
    // ones so a first-row pick would take it.
    const blankSsid = <String, dynamic>{
      'Device.WiFi.SSID.1.SSID': '',
      'Device.WiFi.SSID.1.Enable': false,
      'Device.WiFi.SSID.1.Status': '',
      'Device.WiFi.SSID.1.BSSID': '',
      'Device.WiFi.SSID.1.LowerLayers': '',
      'Device.WiFi.SSID.1.Alias': '',
    };
    Map<String, dynamic> ssid(int i, String name, String radio, String alias) =>
        {
          'Device.WiFi.SSID.$i.SSID': name,
          'Device.WiFi.SSID.$i.Enable': true,
          'Device.WiFi.SSID.$i.Status': 'Up',
          'Device.WiFi.SSID.$i.BSSID': 'AA:BB:CC:DD:EE:0$i',
          'Device.WiFi.SSID.$i.LowerLayers': radio,
          'Device.WiFi.SSID.$i.Alias': alias,
        };

    test('fetchCurrentSsid skips a blank first row', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            ...blankSsid,
            ...ssid(3, 'MyHome', 'Device.WiFi.Radio.1.', 'wifi-2g'),
          });

      expect(await service.fetchCurrentSsid(), 'MyHome');
    });

    test('a blank SSID is no main band, so the wizard stays unified', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((invocation) async {
        final first = (invocation.positionalArguments[0] as List<String>).first;
        if (first.startsWith('Device.WiFi.SSID.')) {
          return {
            ...blankSsid,
            ...ssid(3, 'MyHome', 'Device.WiFi.Radio.1.', 'wifi-2g'),
            ...ssid(4, 'MyHome', 'Device.WiFi.Radio.2.', 'wifi-5g'),
          };
        }
        if (first.startsWith('Device.WiFi.Radio.')) {
          return {
            for (final i in [1, 2]) ...{
              'Device.WiFi.Radio.$i.Enable': true,
              'Device.WiFi.Radio.$i.Status': 'Up',
              'Device.WiFi.Radio.$i.Channel': i == 1 ? 6 : 36,
              'Device.WiFi.Radio.$i.ChannelsInUse': i == 1 ? '6' : '36',
              'Device.WiFi.Radio.$i.OperatingFrequencyBand':
                  i == 1 ? '2.4GHz' : '5GHz',
              'Device.WiFi.Radio.$i.OperatingChannelBandwidth': '20MHz',
              'Device.WiFi.Radio.$i.PossibleChannels': '1,6,11',
              'Device.WiFi.Radio.$i.OperatingStandards': 'n',
              'Device.WiFi.Radio.$i.SupportedStandards': 'b,g,n',
              'Device.WiFi.Radio.$i.TransmitPower': 100,
              'Device.WiFi.Radio.$i.MaxBitRate': 300,
              'Device.WiFi.Radio.$i.AutoChannelEnable': true,
              'Device.WiFi.Radio.$i.IEEE80211hEnabled': false,
              'Device.WiFi.Radio.$i.SupportedOperatingChannelBandwidths':
                  'Auto,20MHz',
            },
          };
        }
        return <String, dynamic>{};
      });

      final config = (await service.fetchWizardData()).wifiConfig;

      expect(config.isSplitMode, isFalse);
      expect(config.ssid, 'MyHome');
      expect(config.ssidInstancePaths, isNot(contains('Device.WiFi.SSID.1.')),
          reason: 'a save must never write to the blank row');
    });

    test('a blank mesh node row is no node', () async {
      const node = 'Device.WiFi.DataElements.Network.Device.';
      when(() => mockUsp.get(any())).thenAnswer((inv) async {
        final paths = inv.positionalArguments[0] as List<String>;
        if (paths.any((p) => p.endsWith('Network.ControllerID'))) {
          return {
            'Device.WiFi.DataElements.Network.ControllerID':
                'AA:BB:CC:DD:EE:01',
          };
        }
        return {
          '${node}2.ID': '',
          '${node}2.MultiAPDevice.Backhaul.LinkType': '',
          '${node}5.ID': 'AA:BB:CC:DD:EE:01',
          '${node}5.MultiAPDevice.Backhaul.LinkType': 'None',
        };
      });

      final topology = await service.fetchMeshTopology();

      expect(topology.nodes.map((n) => n.deviceId), ['AA:BB:CC:DD:EE:01']);
    });
  });

  group('PnpService — WiFi save (#1000 / #1490 / #1491)', () {
    // The router's own reply when the request never reached it: the browser lost
    // the network the write restarted. Shape taken from #1490's log.
    Map<String, dynamic> transportLost(Map<String, dynamic> params) =>
        UspEnvelopeTestData.failedAsAWhole(
          params.keys.toList(),
          errorCode: 9999,
          errorMessage: 'Transport error: Transport error: HTTP '
              'error: error sending request: TypeError: Failed to fetch',
        );

    Map<String, dynamic> refused(Map<String, dynamic> params) =>
        UspEnvelopeTestData.parameterErrors(
          {
            for (final path in params.keys)
              path: (
                code: 7002,
                message: 'An instance with ssid already present.',
              ),
          },
          success: false,
        );

    /// What the broker sends back for an atomic SET across the SSID and
    /// AccessPoint tables (FLWRT 2.0.2, bench log of 2026-10-05): the router
    /// refuses the request as a whole. Up to usp-client 0.14.0 every path
    /// carried the same `9999` a lost answer does, with this message inside
    /// `Received error response: … (code: 7005)`; since 0.15.0 each carries
    /// the router's own code and message (#1787).
    Map<String, dynamic> refusedAcrossServices(Map<String, dynamic> params) =>
        UspEnvelopeTestData.failedAsAWhole(
          params.keys.toList(),
          errorCode: 7005,
          errorMessage: 'ProcessSet_AllowPartialFalse: Allow partial=false not '
              'supported across more than one USP Service',
        );

    /// #1000's form: main renamed and re-passworded, guest turned on, renamed
    /// and passworded.
    const unifiedConfig = PnpWifiConfig(
      ssid: 'NewHome',
      password: 'NewPass123',
      originalSsid: 'OldHome',
      originalPassword: 'OldPass123',
      ssidInstancePaths: ['Device.WiFi.SSID.1.', 'Device.WiFi.SSID.2.'],
      accessPointInstancePaths: [
        'Device.WiFi.AccessPoint.1.',
        'Device.WiFi.AccessPoint.2.',
      ],
      guestEnabled: true,
      guestSsid: 'NewHome-guest',
      guestPassword: 'GuestPass123',
      originalGuestSsid: 'OldHome-guest',
      originalGuestPassword: 'OldGuest123',
      guestSsidInstancePaths: ['Device.WiFi.SSID.3.', 'Device.WiFi.SSID.4.'],
      guestAccessPointInstancePaths: [
        'Device.WiFi.AccessPoint.3.',
        'Device.WiFi.AccessPoint.4.',
      ],
    );

    /// The one write, asserting it went out with `allowPartial: true`: `false`
    /// is refused outright on FLWRT 2.0 because the two tables sit behind more
    /// than one USP Service (7005, bench 2026-10-05). `.single` is the other half
    /// of the point — any WiFi write restarts every radio, so a second SET would
    /// go out over a network that is restarting.
    Map<String, dynamic> theOneWrite() => verify(() => mockUsp.set(
          captureAny(),
          allowPartial: true,
        )).captured.single as Map<String, dynamic>;

    test('saveWifi writes guest and main in a single SET', () async {
      setupSetMocks();

      final outcome = await service.saveWifi(unifiedConfig);

      expect(outcome, PnpWifiWriteOutcome.confirmed);
      expect(theOneWrite(), {
        'Device.WiFi.SSID.3.SSID': 'NewHome-guest',
        'Device.WiFi.SSID.3.Enable': true,
        'Device.WiFi.SSID.4.SSID': 'NewHome-guest',
        'Device.WiFi.SSID.4.Enable': true,
        // #972: SSID.Enable alone does not stop the AP broadcasting.
        'Device.WiFi.AccessPoint.3.Enable': true,
        'Device.WiFi.AccessPoint.4.Enable': true,
        'Device.WiFi.AccessPoint.3.Security.KeyPassphrase': 'GuestPass123',
        'Device.WiFi.AccessPoint.4.Security.KeyPassphrase': 'GuestPass123',
        'Device.WiFi.SSID.1.SSID': 'NewHome',
        'Device.WiFi.SSID.2.SSID': 'NewHome',
        'Device.WiFi.AccessPoint.1.Security.KeyPassphrase': 'NewPass123',
        'Device.WiFi.AccessPoint.2.Security.KeyPassphrase': 'NewPass123',
      });
    });

    test('saveWifi sends only what changed', () async {
      setupSetMocks();

      await service.saveWifi(const PnpWifiConfig(
        ssid: 'OldHome',
        password: 'NewPass123',
        originalSsid: 'OldHome',
        originalPassword: 'OldPass123',
        ssidInstancePaths: ['Device.WiFi.SSID.1.'],
        accessPointInstancePaths: ['Device.WiFi.AccessPoint.1.'],
        guestSsidInstancePaths: ['Device.WiFi.SSID.3.'],
        guestAccessPointInstancePaths: ['Device.WiFi.AccessPoint.3.'],
      ));

      expect(theOneWrite().keys,
          ['Device.WiFi.AccessPoint.1.Security.KeyPassphrase']);
    });

    test('saveWifi with nothing to write sends nothing', () async {
      setupSetMocks();

      final outcome = await service.saveWifi(const PnpWifiConfig(
        ssid: 'OldHome',
        password: 'OldPass123',
        originalSsid: 'OldHome',
        originalPassword: 'OldPass123',
        ssidInstancePaths: ['Device.WiFi.SSID.1.'],
      ));

      expect(outcome, PnpWifiWriteOutcome.confirmed);
      verifyNever(
          () => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')));
    });

    test(
        'saveWifi reports a write whose answer was lost as unanswered, not as '
        'a failure', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((inv) async => transportLost(
              inv.positionalArguments[0] as Map<String, dynamic>));

      final outcome = await service.saveWifi(unifiedConfig);

      expect(outcome, PnpWifiWriteOutcome.unanswered);
    });

    test(
        'saveWifi throws on a cross-service refusal — the router answered, so '
        'nothing landed', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((inv) async => refusedAcrossServices(
              inv.positionalArguments[0] as Map<String, dynamic>));

      await expectLater(
        service.saveWifi(unifiedConfig),
        throwsA(isA<UspCompleteFailureError>()),
      );
    });

    test('saveWifi throws when the router refuses the write', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((inv) async =>
              refused(inv.positionalArguments[0] as Map<String, dynamic>));

      await expectLater(
        service.saveWifi(unifiedConfig),
        throwsA(isA<UspCompleteFailureError>()),
      );
    });

    test('saveWifi in split mode writes each changed band, guest included',
        () async {
      setupSetMocks();
      PnpWifiBand band(int n, String freq, String ssid, String pass) =>
          PnpWifiBand(
            bandName: freq,
            frequency: freq,
            ssid: ssid,
            password: pass,
            originalSsid: ssid,
            originalPassword: pass,
            ssidInstancePath: 'Device.WiFi.SSID.$n.',
            accessPointInstancePath: 'Device.WiFi.AccessPoint.$n.',
            radioPath: 'Device.WiFi.Radio.${n.isOdd ? 1 : 2}.',
          );
      final config = PnpWifiConfig(
        ssid: 'Home-2G',
        password: 'pass-2g',
        originalSsid: 'Home-2G',
        originalPassword: 'pass-2g',
        mainBands: [
          band(1, '2.4GHz', 'Home-2G', 'pass-2g').copyWith(ssid: 'Renamed-2G'),
          band(2, '5GHz', 'Home-5G', 'pass-5g')
              .copyWith(password: 'newpass-5g'),
        ],
        guestEnabled: true,
        guestBands: [
          band(3, '2.4GHz', 'Guest-2G', 'gpass'),
          band(4, '5GHz', 'Guest-5G', 'gpass'),
        ],
      );
      expect(config.isSplitMode, isTrue);
      expect(config.isGuestSplitMode, isTrue);

      await service.saveWifi(config);

      expect(theOneWrite(), {
        'Device.WiFi.SSID.3.Enable': true,
        'Device.WiFi.AccessPoint.3.Enable': true,
        'Device.WiFi.SSID.4.Enable': true,
        'Device.WiFi.AccessPoint.4.Enable': true,
        'Device.WiFi.SSID.1.SSID': 'Renamed-2G',
        'Device.WiFi.AccessPoint.2.Security.KeyPassphrase': 'newpass-5g',
      });
    });

    group('isWifiApplied', () {
      void routerReads({
        required Map<String, ({String ssid, bool enable})> ssids,
        Map<String, bool> apEnable = const {},
      }) {
        when(() => mockUsp.get(any(), priority: any(named: 'priority')))
            .thenAnswer((inv) async {
          final paths = inv.positionalArguments[0] as List<String>;
          if (paths.first.startsWith('Device.WiFi.AccessPoint.')) {
            return {
              for (final e in apEnable.entries) ...{
                '${e.key}Enable': e.value,
                '${e.key}Status': e.value ? 'Enabled' : 'Disabled',
                '${e.key}Security.ModesSupported': 'WPA2-Personal',
                '${e.key}Security.ModeEnabled': 'WPA2-Personal',
                '${e.key}Security.EncryptionMode': 'AES',
                '${e.key}Security.KeyPassphrase': '',
                '${e.key}SSIDAdvertisementEnabled': true,
                '${e.key}SSIDReference': '',
              },
            };
          }
          return {
            for (final e in ssids.entries) ...{
              '${e.key}SSID': e.value.ssid,
              '${e.key}Enable': e.value.enable,
              '${e.key}Status': e.value.enable ? 'Up' : 'Down',
              '${e.key}BSSID': 'AA:BB:CC:DD:EE:01',
              '${e.key}LowerLayers': 'Device.WiFi.Radio.1.',
              '${e.key}Alias': 'wifi',
            },
          };
        });
      }

      const applied = {
        'Device.WiFi.SSID.1.': (ssid: 'NewHome', enable: true),
        'Device.WiFi.SSID.2.': (ssid: 'NewHome', enable: true),
        'Device.WiFi.SSID.3.': (ssid: 'NewHome-guest', enable: true),
        'Device.WiFi.SSID.4.': (ssid: 'NewHome-guest', enable: true),
      };
      const apsOn = {
        'Device.WiFi.AccessPoint.3.': true,
        'Device.WiFi.AccessPoint.4.': true,
      };

      test('is true when main and guest read back as written', () async {
        routerReads(ssids: applied, apEnable: apsOn);

        expect(await service.isWifiApplied(unifiedConfig), isTrue);
      });

      test('is false when the main network is still on the old name', () async {
        routerReads(ssids: {
          ...applied,
          'Device.WiFi.SSID.2.': (ssid: 'OldHome', enable: true),
        }, apEnable: apsOn);

        expect(await service.isWifiApplied(unifiedConfig), isFalse);
      });

      test('is false when the guest network did not turn on', () async {
        // The guest half of the one write is checked too: a rename that landed
        // says nothing about the guest Enable beside it.
        routerReads(ssids: applied, apEnable: {
          ...apsOn,
          'Device.WiFi.AccessPoint.4.': false,
        });

        expect(await service.isWifiApplied(unifiedConfig), isFalse);
      });

      test('reads nothing when only passwords changed', () async {
        final applied = await service.isWifiApplied(const PnpWifiConfig(
          ssid: 'OldHome',
          password: 'NewPass123',
          originalSsid: 'OldHome',
          originalPassword: 'OldPass123',
          ssidInstancePaths: ['Device.WiFi.SSID.1.'],
        ));

        expect(applied, isTrue);
        verifyNever(() => mockUsp.get(any(), priority: any(named: 'priority')));
      });
    });
  });
  // The wizard's "Your Network" step lists what this returns. A node that has
  // just joined has no backhaul data yet, which by backhaul alone also
  // describes the controller; ControllerID is what keeps it a slave, as it
  // does on the topology (#1688 review).
  group('PnpService.fetchMeshTopology — the controller', () {
    const controller = 'AA:BB:CC:DD:EE:01';
    const joiningAgent = 'AA:BB:CC:DD:EE:02';
    const node1 = 'Device.WiFi.DataElements.Network.Device.1.';
    const node2 = 'Device.WiFi.DataElements.Network.Device.2.';
    // FL-WRT 2.0 shape: the controller reports LinkType None, and the agent
    // has no LinkType and no parent yet.
    const networkResponse = <String, dynamic>{
      '${node1}ID': controller,
      '${node1}MultiAPDevice.Backhaul.LinkType': 'None',
      '${node2}ID': joiningAgent,
    };

    void stubDataElements({
      Map<String, dynamic> networkInfo = const {},
      bool networkInfoFails = false,
    }) {
      when(() => mockUsp.get(any())).thenAnswer((inv) async {
        final paths = inv.positionalArguments[0] as List<String>;
        if (paths.any((p) => p.endsWith('Network.ControllerID'))) {
          if (networkInfoFails) throw 'USP get failed: 7026 Invalid path';
          return networkInfo;
        }
        return networkResponse;
      });
    }

    test('with ControllerID an agent with no backhaul yet is a slave',
        () async {
      stubDataElements(networkInfo: {
        'Device.WiFi.DataElements.Network.ControllerID': controller,
      });

      final topology = await service.fetchMeshTopology();

      expect(topology.nodes.whereType<MasterNode>().map((n) => n.deviceId),
          [controller]);
      expect(topology.nodes.whereType<SlaveNode>().map((n) => n.deviceId),
          [joiningAgent]);
    });

    // The fallback the fault isolation is for: the node list survives, and the
    // controller is told apart by backhaul as before.
    test('a ControllerID read that fails leaves the node list intact',
        () async {
      stubDataElements(networkInfoFails: true);

      final topology = await service.fetchMeshTopology();

      expect(topology.nodes.map((n) => n.deviceId), [controller, joiningAgent]);
    });
  });

  group('PnpService injected connection error handling', () {
    late MockAutoIPoEService ipoe;

    setUp(() {
      ipoe = MockAutoIPoEService();
      service = PnpService(mockUsp, fetchAutoIPoE: ipoe.fetch);
    });
    for (final error in const <ServiceError>[
      NotAuthenticatedError(
          code: 401, detail: 'Synthetic authentication failure'),
      SessionTokenExpiredError(detail: 'Synthetic expired session'),
      InvalidSessionTokenError(detail: 'Synthetic invalid session'),
      NetworkError(code: 503, detail: 'Synthetic unavailable service'),
      InvalidInputError(code: 7004, detail: 'Synthetic invalid response'),
    ]) {
      test('preserves ${error.runtimeType} from the injected read', () async {
        when(() => ipoe.fetch()).thenThrow(error);

        await expectLater(
            service.checkInternetConnected(), throwsA(same(error)));

        verify(() => ipoe.fetch()).called(1);
        verifyNoMoreInteractions(ipoe);
        verifyZeroInteractions(mockUsp);
      });
    }

    test('keeps a mapped HTTP auth failure through the outer catch', () async {
      when(() => ipoe.fetch())
          .thenThrow('Get failed: Transport error: HTTP error: HTTP 401');

      await expectLater(
        service.checkInternetConnected(),
        throwsA(
            isA<NotAuthenticatedError>().having((e) => e.code, 'code', 401)),
      );

      verify(() => ipoe.fetch()).called(1);
      verifyNoMoreInteractions(ipoe);
      verifyZeroInteractions(mockUsp);
    });
  });
}
