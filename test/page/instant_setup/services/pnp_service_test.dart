import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_isp_config.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_band.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_config.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_service.dart';
import 'package:privacy_gui/page/internet_settings/services/auto_ipoe_service.dart';

import '../../../mocks/test_data/internet_settings_test_data.dart';

class MockUspClient extends Mock implements UspClient {}

class MockAutoIPoEService extends Mock implements AutoIPoEService {}

void main() {
  late MockUspClient mockUsp;
  late PnpService service;

  // Standard WAN response (DHCP mode)
  const wanResponse = <String, dynamic>{
    'Device.IP.Interface.2.IPv4Address.1.AddressingType': 'DHCP',
    'Device.IP.Interface.2.MaxMTUSize': '1500',
    'Device.IP.Interface.2.LowerLayers': 'Device.Ethernet.Link.2',
    'Device.IP.Interface.2.IPv4Address.1.IPAddress': '',
    'Device.IP.Interface.2.IPv4Address.1.SubnetMask': '',
    'Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DefaultGateway': '',
    'Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DNSServers': '',
    // Enable is the bridge signal — true means a normal (non-bridged) WAN.
    'Device.IP.Interface.2.Enable': true,
    'Device.Ethernet.Interface.1.MACAddress': '11:22:33:44:55:66',
  };

  const ipv6Response = <String, dynamic>{
    'Device.IP.Interface.2.IPv6Enable': true,
  };

  const dhcpv6Response = <String, dynamic>{
    'Device.DHCPv6.Client.1.Enable': true,
    'Device.DHCPv6.Client.1.Interface': 'Device.IP.Interface.2',
    'Device.DHCPv6.Client.1.DUID': '00:01:00:01:2a:3b:4c:5d',
  };

  const ipv6rdResponse = <String, dynamic>{
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
    'Device.PPP.Interface.1.LCPEchoRetry': '5',
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
      if (paths.any((p) => p.contains('DHCPv6.Client'))) {
        return dhcpv6Response;
      }
      if (paths.any((p) => p.contains('IPv6rd.InterfaceSetting'))) {
        return ipv6rdResponse;
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
    // The shape UspResultParser.parseAddResult reads: the created instance
    // paths under result.data.instances.
    when(() => mockUsp.add(any())).thenAnswer((_) async => {
          'success': true,
          'result': {
            'data': {
              'instances': [createdPath],
            },
          },
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

  group(
      'PnpService.saveIspSettings — integration with UspInternetSettingsService',
      () {
    test('DHCP: calls renewDhcpLease only, does not call fetchSettings/saveAll',
        () async {
      setupOperateMock();
      // The renew reads the client table to find the client on the WAN:
      // Client.6 (Client.3 runs on the LAN).
      when(() => mockUsp.get(any())).thenAnswer((invocation) async =>
          InternetSettingsTestData.renewAnswer(
              invocation.positionalArguments[0] as List<String>));

      const config = PnpIspConfig(type: IspConnectionType.dhcp);

      await service.saveIspSettings(config);

      // Verify DHCP renew was called on the WAN's client
      verify(() => mockUsp.operate('Device.DHCPv4.Client.6.Renew()')).called(1);

      // fetchSettings not called: nothing of WanSettings was read.
      final requested = verify(() => mockUsp.get(captureAny()))
          .captured
          .cast<List<String>>()
          .expand((paths) => paths);
      expect(requested.where((p) => p.endsWith('X_LINKSYS_MTUMode')), isEmpty);
      // Verify NO set/add calls (saveAll not called)
      verifyNever(() => mockUsp.set(any()));
      verifyNever(
          () => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')));
      verifyNever(() =>
          mockUsp.setOrdered(any(), allowPartial: any(named: 'allowPartial')));
      verifyNever(() => mockUsp.add(any()));
    });

    test('DHCP: a failed read before the renew is a ServiceError', () async {
      when(() => mockUsp.get(any()))
          .thenThrow('Get failed: Transport error: Connection refused');

      await expectLater(
        service
            .saveIspSettings(const PnpIspConfig(type: IspConnectionType.dhcp)),
        throwsA(isA<ConnectivityError>()),
      );
      verifyNever(() => mockUsp.operate(any()));
    });

    test('DHCP: a WAN with no DHCPv4 client renews nothing and says so',
        () async {
      when(() => mockUsp.get(any())).thenAnswer((invocation) async =>
          InternetSettingsTestData.renewAnswer(
              invocation.positionalArguments[0] as List<String>,
              hasWanClient: false));

      await expectLater(
        service
            .saveIspSettings(const PnpIspConfig(type: IspConnectionType.dhcp)),
        throwsA(isA<ResourceNotFoundError>()),
      );
      verifyNever(() => mockUsp.operate(any()));
    });

    test('Static IP: fetches settings then writes the WAN IPv4 row in order',
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
      // - Dhcpv6Clients.fetch() = 1 call (matched on WanSettings.instancePath)
      // - Ipv6rdSettings.fetch() = 1 call
      // No GRE/L2TP fetch: tunnels are fetched only for the pptp/l2tp
      // connection types, not for Static IP.
      // saveAll:
      // - WAN IPv4 row re-read (_resolveInstance() + fetch()) = 2 calls
      // - No IPv6 field changed, so the IPv6 save sends nothing
      // Total = 11 get calls
      verify(() => mockUsp.get(any())).called(11);

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
        'PPPoE (no existing PPP instance): adds a PPP instance, sets IPCP, then '
        'writes LowerLayers and the credentials', () async {
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
      // fetchSettings: 9 calls (WanSettings x2, Ipv6 x2, PPP, VLAN,
      //   _fetchHostName = Device.DeviceInfo.HostName, Dhcpv6Clients,
      //   Ipv6rdSettings). No GRE/L2TP fetch: tunnels are fetched only for
      //   the pptp/l2tp connection types.
      // saveAll:
      // - WAN IPv4 row re-read (_resolveInstance() + fetch()) = 2 calls
      // - No IPv6 field changed, so the IPv6 save sends nothing
      // Total = 11 get calls
      verify(() => mockUsp.get(any())).called(11);

      // Verify PppInterface.add was called (new PPP instance created)
      final addCaptures = verify(() => mockUsp.add(captureAny())).captured;
      expect(addCaptures, isNotEmpty);
      final addPath = addCaptures.first as List<Map<String, dynamic>>;
      // PppInterface.add sends [{}] to 'Device.PPP.Interface.'
      expect(addPath.length, equals(1));

      // SET 1: AddressingType=IPCP alone, on the WAN IPv4 row.
      final ordered = verify(() => mockUsp.setOrdered(captureAny(),
          allowPartial: any(named: 'allowPartial'))).captured;
      expect(ordered.single, [
        [
          {
            'path': 'Device.IP.Interface.2.IPv4Address.1.AddressingType',
            'value': 'IPCP',
          }
        ]
      ]);

      // SET 2: LowerLayers cleared plus the credentials, as one PPP batch.
      final setCaptures = verify(() => mockUsp.set(captureAny(),
          allowPartial: any(named: 'allowPartial'))).captured;
      final pppoeSet = setCaptures.whereType<Map<String, dynamic>>().firstWhere(
            (m) => m.containsKey('Device.PPP.Interface.1.Username'),
            orElse: () => {},
          );
      expect(pppoeSet, {
        'Device.PPP.Interface.1.LowerLayers': '',
        'Device.PPP.Interface.1.Username': 'myuser',
        'Device.PPP.Interface.1.Password': 'mypass',
      });
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
        if (paths.any((p) => p.contains('DHCPv6.Client'))) {
          return dhcpv6Response;
        }
        if (paths.any((p) => p.contains('IPv6rd.InterfaceSetting'))) {
          return ipv6rdResponse;
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
        if (paths.any((p) => p.contains('DHCPv6.Client'))) {
          return dhcpv6Response;
        }
        if (paths.any((p) => p.contains('IPv6rd.InterfaceSetting'))) {
          return ipv6rdResponse;
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
