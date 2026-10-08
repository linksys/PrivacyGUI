import 'package:privacy_gui/constants/build_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_isp_config.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_band.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_config.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_service.dart';

class MockUspClient extends Mock implements UspClient {}

void main() {
  late MockUspClient mockUsp;
  late PnpService service;

  // Standard WAN response (DHCP mode)
  const wanResponse = <String, dynamic>{
    'Device.IP.Interface.2.IPv4Address.1.AddressingType': 'DHCP',
    'Device.IP.Interface.2.MaxMTUSize': '1500',
    'Device.IP.Interface.2.IPv4Address.1.IPAddress': '',
    'Device.IP.Interface.2.IPv4Address.1.SubnetMask': '',
    'Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DefaultGateway': '',
    'Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DNSServers': '',
    'Device.Bridging.Bridge.1.Enable': false,
    'Device.Ethernet.Interface.1.MACAddress': '11:22:33:44:55:66',
  };

  const ipv6Response = <String, dynamic>{
    'Device.IP.Interface.2.IPv6Enable': true,
    'Device.DHCPv6.Client.1.Enable': true,
    'Device.DHCPv6.Client.1.DUID': '00:01:00:01:2a:3b:4c:5d',
    'Device.IPv6rd.InterfaceSetting.1.Enable': false,
    'Device.IPv6rd.InterfaceSetting.1.SPIPv6Prefix': '',
    'Device.IPv6rd.InterfaceSetting.1.IPv4MaskLength': '0',
    'Device.IPv6rd.InterfaceSetting.1.BorderRelayIPv4Addresses': '',
  };

  const pppEmptyResponse = <String, dynamic>{};
  const vlanEmptyResponse = <String, dynamic>{};

  const pppExistingResponse = <String, dynamic>{
    'Device.PPP.Interface.1.Username': 'existinguser',
    'Device.PPP.Interface.1.Password': 'existingpass',
    'Device.PPP.Interface.1.PPPoE.ServiceName': '',
    'Device.PPP.Interface.1.ConnectionTrigger': 'AlwaysOn',
    'Device.PPP.Interface.1.IdleDisconnectTime': '0',
    'Device.PPP.Interface.1.LCPEcho': '30',
    'Device.PPP.Interface.1.ConnectionStatus': 'Connected',
    'Device.PPP.Interface.1.LowerLayers': 'Device.Ethernet.Link.2',
  };

  const vlanExistingResponse = <String, dynamic>{
    'Device.Ethernet.VLANTermination.1.Enable': true,
    'Device.Ethernet.VLANTermination.1.VLANID': '100',
  };

  // Alias resolution response for WanSettings and Ipv6Settings _resolveInstance()
  const ipAliasResolutionResponse = <String, dynamic>{
    'Device.IP.Interface.1.Alias': 'lan',
    'Device.IP.Interface.2.Alias': 'wan',
  };

  // Alias resolution response for Ethernet.Link (used by various codegen)
  const ethLinkAliasResolutionResponse = <String, dynamic>{
    'Device.Ethernet.Link.1.Alias': 'eth-lan',
    'Device.Ethernet.Link.2.Alias': 'eth-wan',
  };

  void setupFetchMocks({
    Map<String, dynamic> pppResponse = pppEmptyResponse,
    Map<String, dynamic> vlanResponse = vlanEmptyResponse,
  }) {
    when(() => mockUsp.get(any())).thenAnswer((invocation) async {
      final paths = invocation.positionalArguments[0] as List<String>;
      // Handle _resolveInstance() calls for Ethernet.Link
      if (paths.any((p) => p.contains('Ethernet.Link.*.Alias'))) {
        return ethLinkAliasResolutionResponse;
      }
      // Handle _resolveInstance() calls for WanSettings/Ipv6Settings (IP.Interface)
      if (paths.any((p) => p.contains('IP.Interface.*.Alias'))) {
        return ipAliasResolutionResponse;
      }
      if (paths.any((p) => p.contains('AddressingType'))) {
        return wanResponse;
      }
      if (paths.any((p) => p.contains('IPv6Enable'))) {
        return ipv6Response;
      }
      if (paths.any((p) => p.contains('PPP.Interface'))) {
        return pppResponse;
      }
      if (paths.any((p) => p.contains('VLANTermination'))) {
        return vlanResponse;
      }
      // PnP setup never configures a PPTP/L2TP WAN, so connectionType is never
      // PPTP/L2TP and Phase-2 fetches no tunnel. A tunnel GET here means an
      // unconditional fetch regressed — fail fast instead of returning empty.
      if (paths.any((p) => p.contains('GRE.Tunnel'))) {
        throw StateError('Unexpected GRE.Tunnel GET in PnP fetch');
      }
      if (paths.any((p) => p.contains('L2TPv2.Tunnel'))) {
        throw StateError('Unexpected L2TPv2.Tunnel GET in PnP fetch');
      }
      return {};
    });
  }

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

  void setupAddMock({String createdPath = 'Device.PPP.Interface.1.'}) {
    when(() => mockUsp.add(any())).thenAnswer((_) async => {
          'overallSuccess': true,
          'hasAnySuccess': true,
          'hasErrors': false,
          'results': [
            {
              'requestedPath': createdPath.replaceAll(RegExp(r'\d+\.$'), ''),
              'success': true,
              'createdInstances': [
                {'affectedPath': createdPath, 'initialParams': {}}
              ]
            }
          ]
        });
  }

  void setupOperateMock() {
    when(() => mockUsp.operate(any())).thenAnswer((_) async => {
          'success': true,
          'result': {'data': <String, dynamic>{}},
        });
  }

  setUp(() {
    mockUsp = MockUspClient();
    service = PnpService(mockUsp);
  });

  group(
      'PnpService.saveIspSettings — integration with UspInternetSettingsService',
      () {
    test('DHCP: calls renewDhcpLease only, does not call fetchSettings/saveAll',
        () async {
      setupOperateMock();

      const config = PnpIspConfig(type: IspConnectionType.dhcp);

      await service.saveIspSettings(config);

      // Verify DHCP renew was called
      verify(() => mockUsp.operate('Device.DHCPv4.Client.1.Renew()')).called(1);

      // Verify NO fetch calls were made (fetchSettings not called)
      verifyNever(() => mockUsp.get(any()));
      // Verify NO set/add calls (saveAll not called)
      verifyNever(() => mockUsp.set(any()));
      verifyNever(
          () => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')));
      verifyNever(() =>
          mockUsp.setOrdered(any(), allowPartial: any(named: 'allowPartial')));
      verifyNever(() => mockUsp.add(any()));
    });

    test(
        'Static IP: fetches all 4 endpoints then calls WanStaticIp.updateOrdered',
        () async {
      setupFetchMocks();
      setupSetMocks();

      const config = PnpIspConfig(
        type: IspConnectionType.staticIp,
        staticIpAddress: '192.168.1.100',
        subnetMask: '255.255.255.0',
        defaultGateway: '192.168.1.1',
        dnsServer1: '8.8.8.8',
        dnsServer2: '8.8.4.4',
      );

      await service.saveIspSettings(config);

      // Verify fetchSettings + saveAll get calls:
      // fetchSettings:
      // - WanSettings._resolveInstance() + fetch() = 2 calls
      // - Ipv6Settings._resolveInstance() + fetch() = 2 calls
      // - PppInterface.fetch() = 1 call
      // - VlanTermination.fetch() = 1 call
      // - _fetchHostName() (Device.DeviceInfo.HostName) = 1 call
      // No GRE/L2TP fetch: tunnels are fetched only for the pptp/l2tp
      // connection types, not for Static IP.
      // saveAll:
      // - WanStaticIp.updateOrdered() → _resolveInstance() = 1 call
      // - Ipv6Settings.update() → _resolveInstance() = 1 call
      // Total = 9 get calls
      verify(() => mockUsp.get(any())).called(9);

      // Verify setOrdered was called for Static IP mode switch
      final capturedOrdered = verify(() => mockUsp.setOrdered(captureAny(),
          allowPartial: any(named: 'allowPartial'))).captured;
      expect(capturedOrdered, isNotEmpty);

      final orderedGroups =
          capturedOrdered.first as List<List<Map<String, String>>>;
      // Group 1: AddressingType = 'Static'
      expect(orderedGroups[0].length, equals(1));
      expect(orderedGroups[0][0]['value'], equals('Static'));

      // Group 2: IP config fields
      final group2Values = orderedGroups[1].map((p) => p['value']).toList();
      expect(group2Values, contains('192.168.1.100'));
      expect(group2Values, contains('255.255.255.0'));
      expect(group2Values, contains('192.168.1.1'));
      expect(group2Values, contains('8.8.8.8,8.8.4.4'));
    });

    test(
        'PPPoE (no existing PPP instance): calls PppInterface.add then WanPppoe.update',
        () async {
      setupFetchMocks(pppResponse: pppEmptyResponse);
      setupSetMocks();
      setupAddMock(createdPath: 'Device.PPP.Interface.1.');

      const config = PnpIspConfig(
        type: IspConnectionType.pppoe,
        pppUsername: 'myuser',
        pppPassword: 'mypass',
      );

      await service.saveIspSettings(config);

      // Verify fetchSettings + saveAll get calls:
      // fetchSettings: 7 calls (WanSettings x2, Ipv6 x2, PPP, VLAN,
      //   _fetchHostName = Device.DeviceInfo.HostName). No GRE/L2TP fetch:
      //   tunnels are fetched only for the pptp/l2tp connection types.
      // saveAll:
      // - WanPppoe.update() → _resolveInstance() = 1 call
      // - Ipv6Settings.update() → _resolveInstance() = 1 call
      // Total = 9 get calls
      verify(() => mockUsp.get(any())).called(9);

      // Verify PppInterface.add was called (new PPP instance created)
      final addCaptures = verify(() => mockUsp.add(captureAny())).captured;
      expect(addCaptures, isNotEmpty);
      final addPath = addCaptures.first as List<Map<String, dynamic>>;
      // PppInterface.add sends [{}] to 'Device.PPP.Interface.'
      expect(addPath.length, equals(1));

      // Verify WanPppoe.update was called with credentials + AddressingType
      final setCaptures = verify(() => mockUsp.set(captureAny(),
          allowPartial: any(named: 'allowPartial'))).captured;
      final pppoeSet = setCaptures.whereType<Map<String, dynamic>>().firstWhere(
            (m) => m.containsKey('Device.PPP.Interface.1.Username'),
            orElse: () => {},
          );
      expect(pppoeSet, isNotEmpty);
      expect(pppoeSet['Device.PPP.Interface.1.Username'], equals('myuser'));
      expect(pppoeSet['Device.PPP.Interface.1.Password'], equals('mypass'));
      expect(
        pppoeSet['Device.IP.Interface.2.IPv4Address.1.AddressingType'],
        equals('IPCP'),
      );
    });

    test(
        'PPPoE+VLAN → PPPoE: disables VLAN via SET Enable=false on existing instance',
        () async {
      // Start with PPPoE+VLAN enabled
      final wanPppoeResponse = Map<String, dynamic>.from(wanResponse);
      wanPppoeResponse['Device.IP.Interface.2.IPv4Address.1.AddressingType'] =
          'IPCP';

      when(() => mockUsp.get(any())).thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
        if (paths.any((p) => p.contains('Ethernet.Link.*.Alias'))) {
          return ethLinkAliasResolutionResponse;
        }
        if (paths.any((p) => p.contains('IP.Interface.*.Alias'))) {
          return ipAliasResolutionResponse;
        }
        if (paths.any((p) => p.contains('AddressingType'))) {
          return wanPppoeResponse;
        }
        if (paths.any((p) => p.contains('IPv6Enable'))) {
          return ipv6Response;
        }
        if (paths.any((p) => p.contains('PPP.Interface'))) {
          return pppExistingResponse;
        }
        if (paths.any((p) => p.contains('VLANTermination'))) {
          return vlanExistingResponse;
        }
        // PPPoE connection → no tunnel fetch in Phase-2; a tunnel GET is a
        // regression (unconditional fetch).
        if (paths.any((p) => p.contains('GRE.Tunnel'))) {
          throw StateError('Unexpected GRE.Tunnel GET in PnP PPPoE fetch');
        }
        if (paths.any((p) => p.contains('L2TPv2.Tunnel'))) {
          throw StateError('Unexpected L2TPv2.Tunnel GET in PnP PPPoE fetch');
        }
        return {};
      });
      setupSetMocks();

      const config = PnpIspConfig(
        type: IspConnectionType.pppoe,
        pppUsername: 'existinguser',
        pppPassword: 'existingpass',
        vlanEnabled: false,
        vlanId: 0,
      );

      await service.saveIspSettings(config);

      // Verify SET was called with VLANTermination.Enable = false
      final setCaptures = verify(() => mockUsp.set(captureAny())).captured;
      final vlanSet = setCaptures.whereType<Map<String, dynamic>>().where(
          (params) => params.keys.any((k) => k.contains('VLANTermination')));
      expect(vlanSet, isNotEmpty);
      expect(
          vlanSet.first['Device.Ethernet.VLANTermination.1.Enable'], isFalse);

      // Verify no DELETE was called
      verifyNever(() => mockUsp.delete(any()));
    });

    test('PPPoE+VLAN: enables VLAN via SET on existing instance', () async {
      // Start with PPPoE, VLAN instance exists but disabled
      final wanPppoeResponse = Map<String, dynamic>.from(wanResponse);
      wanPppoeResponse['Device.IP.Interface.2.IPv4Address.1.AddressingType'] =
          'IPCP';

      // VLAN instance exists but is disabled — fetchSettings will find it
      // and pass vlanInstancePath to saveAll.
      // Note: codegen skips instances where ALL fields are zero/false/empty,
      // so VLANID must be non-zero for the instance to be recognized.
      const vlanDisabledResponse = <String, dynamic>{
        'Device.Ethernet.VLANTermination.1.Enable': false,
        'Device.Ethernet.VLANTermination.1.VLANID': '50',
      };

      when(() => mockUsp.get(any())).thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
        if (paths.any((p) => p.contains('Ethernet.Link.*.Alias'))) {
          return ethLinkAliasResolutionResponse;
        }
        if (paths.any((p) => p.contains('IP.Interface.*.Alias'))) {
          return ipAliasResolutionResponse;
        }
        if (paths.any((p) => p.contains('AddressingType'))) {
          return wanPppoeResponse;
        }
        if (paths.any((p) => p.contains('IPv6Enable'))) {
          return ipv6Response;
        }
        if (paths.any((p) => p.contains('PPP.Interface'))) {
          return pppExistingResponse;
        }
        if (paths.any((p) => p.contains('VLANTermination'))) {
          return vlanDisabledResponse;
        }
        // PPPoE connection → no tunnel fetch in Phase-2; a tunnel GET is a
        // regression (unconditional fetch).
        if (paths.any((p) => p.contains('GRE.Tunnel'))) {
          throw StateError('Unexpected GRE.Tunnel GET in PnP PPPoE fetch');
        }
        if (paths.any((p) => p.contains('L2TPv2.Tunnel'))) {
          throw StateError('Unexpected L2TPv2.Tunnel GET in PnP PPPoE fetch');
        }
        return {};
      });
      setupSetMocks();

      const config = PnpIspConfig(
        type: IspConnectionType.pppoeVlan,
        pppUsername: 'existinguser',
        pppPassword: 'existingpass',
        vlanEnabled: true,
        vlanId: 100,
      );

      await service.saveIspSettings(config);

      // Verify SET was called with VLANTermination.Enable = true
      final setCaptures = verify(() => mockUsp.set(captureAny())).captured;
      final vlanSet = setCaptures.whereType<Map<String, dynamic>>().where(
          (params) => params.keys.any((k) => k.contains('VLANTermination')));
      expect(vlanSet, isNotEmpty);
      expect(vlanSet.first['Device.Ethernet.VLANTermination.1.Enable'], isTrue);
      expect(vlanSet.first['Device.Ethernet.VLANTermination.1.VLANID'],
          equals(100));

      // Verify no ADD was called
      verifyNever(() => mockUsp.add(any()));
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

  group('PnpService — WiFi save (#1000 / #1490 / #1491)', () {
    // The router's own reply when the request never reached it: the browser lost
    // the network the write restarted. Shape taken from #1490's log.
    Map<String, dynamic> transportLost(Map<String, dynamic> params) => {
          'success': false,
          'result': {
            'data': <String, dynamic>{},
            'error': {
              for (final path in params.keys)
                path: {
                  'errorCode': 9999,
                  'errorMessage': 'Transport error: Transport error: HTTP '
                      'error: error sending request: TypeError: Failed to fetch',
                },
            },
          },
        };

    Map<String, dynamic> refused(Map<String, dynamic> params) => {
          'success': false,
          'result': {
            'data': <String, dynamic>{},
            'error': {
              for (final path in params.keys)
                path: {
                  'errorCode': 7002,
                  'errorMessage': 'An instance with ssid already present.',
                },
            },
          },
        };

    /// What the broker sent back on FLWRT 2.0.2 for an atomic SET across the
    /// SSID and AccessPoint tables, copied from the bench log of 2026-10-05: the
    /// router answered and refused, yet every path carries the same `9999` a
    /// lost answer does.
    Map<String, dynamic> refusedAsTransport(Map<String, dynamic> params) => {
          'success': false,
          'result': {
            'data': <String, dynamic>{},
            'error': {
              for (final path in params.keys)
                path: {
                  'errorCode': 9999,
                  'errorMessage': 'Transport error: Protocol error: Decoding '
                      'error: Received error response: '
                      'ProcessSet_AllowPartialFalse: Allow partial=false not '
                      'supported across more than one USP Service (code: 7005)',
                },
            },
          },
        };

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
        'saveWifi throws on a refusal the WASM client reports as 9999 — the '
        'router answered, so nothing landed', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((inv) async => refusedAsTransport(
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
  group('PnpService native connection error handling', () {
    for (final error in const <ServiceError>[
      NotAuthenticatedError(
          code: 401, detail: 'Synthetic authentication failure'),
      SessionTokenExpiredError(detail: 'Synthetic expired session'),
      InvalidSessionTokenError(detail: 'Synthetic invalid session'),
      NetworkError(code: 503, detail: 'Synthetic unavailable service'),
      InvalidInputError(code: 7004, detail: 'Synthetic invalid response'),
    ]) {
      test('preserves ${error.runtimeType} from the native read', () async {
        when(() => mockUsp.get(any(), fresh: true)).thenThrow(error);

        await expectLater(
            service.checkInternetConnected(), throwsA(same(error)));

        verify(() => mockUsp.get(any(), fresh: true)).called(1);
        verifyNoMoreInteractions(mockUsp);
      });
    }

    test('keeps a mapped HTTP auth failure through the outer catch', () async {
      when(() => mockUsp.get(any(), fresh: true))
          .thenThrow('Get failed: Transport error: HTTP error: HTTP 401');

      await expectLater(
        service.checkInternetConnected(),
        throwsA(
            isA<NotAuthenticatedError>().having((e) => e.code, 'code', 401)),
      );

      verify(() => mockUsp.get(any(), fresh: true)).called(1);
      verifyNoMoreInteractions(mockUsp);
    });
  }, skip: !BuildConfig.autoIPoEEnabled);
}
