import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_isp_config.dart';
import 'package:privacy_gui/page/instant_setup/services/internet_troubleshooting_service.dart';
import 'package:privacy_gui/page/internet_settings/services/usp_internet_settings_service.dart';

import '../../../mocks/test_data/internet_settings_test_data.dart';

class MockUspClient extends Mock implements UspClient {}

/// The ISP save the no-internet troubleshooting flow runs (#1511 P1).
///
/// Moved from `pnp_service_test.dart` with the method: these cases asserted
/// `PnpService.saveIspSettings`, and they now assert the same writes through
/// [InternetTroubleshootingService.saveIspSettings], case for case.
void main() {
  late MockUspClient mockUsp;
  late InternetTroubleshootingService service;

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

  // #1072: what FW 2.0.4 holds right after a factory reset (measured on M60-EU
  // 2.0.4.26102917): the PPP row unset, and the WAN VLAN row off with VLAN ID 1.
  // That firmware refuses a VLAN ID of 0 (7012, range 1-4094).
  final pppFactoryResponse = <String, dynamic>{
    ...pppExistingResponse,
    'Device.PPP.Interface.1.Username': '',
    'Device.PPP.Interface.1.Password': '',
    'Device.PPP.Interface.1.LowerLayers': '',
    'Device.PPP.Interface.1.ConnectionStatus': 'Disconnected',
  };
  final vlanShippedResponse = <String, dynamic>{
    ...vlanExistingResponse,
    'Device.Ethernet.VLANTermination.1.Enable': false,
    'Device.Ethernet.VLANTermination.1.VLANID': '1',
  };
  final writesVlanId = predicate<Map<String, dynamic>>(
      (params) => params.keys.any((k) =>
          k.startsWith('Device.Ethernet.VLANTermination.') &&
          k.endsWith('.VLANID')),
      'a SET that writes a VLAN ID');

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
    service = InternetTroubleshootingService(
      internetSettings: UspInternetSettingsService(mockUsp),
      checkInternetConnected: () async => false,
    );
  });

  group('InternetTroubleshootingService.fetchCurrentWanSettings', () {
    test('reads the router\'s WAN for the forms to prefill', () async {
      setupFetchMocks(
        pppResponse: pppExistingResponse,
        vlanResponse: vlanExistingResponse,
      );

      final form = await service.fetchCurrentWanSettings();

      expect(form, isNotNull);
      expect(form!.pppUsername, 'existinguser');
    });

    test('a WAN that cannot be read is no prefill, not a failure', () async {
      // An empty form is still usable; the troubleshooting run must not stop
      // over it.
      when(() => mockUsp.get(any())).thenThrow(const ConnectivityError());

      expect(await service.fetchCurrentWanSettings(), isNull);
    });
  });

  group(
      'InternetTroubleshootingService.saveIspSettings — integration with '
      'UspInternetSettingsService', () {
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
      // Enable alone: the VLAN ID field is closed, so its 0 is not the user's
      // and FW 2.0.4 refuses it (#1072).
      expect(
          vlanSet.single, {'Device.Ethernet.VLANTermination.1.Enable': false});

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

    // The user never opened the VLAN field, so no VLAN ID is theirs to write;
    // a 0 written to the shipped row fails the whole save (#1072).
    test('PPPoE without VLAN writes no VLAN ID to the shipped VLAN row (#1072)',
        () async {
      setupFetchMocks(
          pppResponse: pppFactoryResponse, vlanResponse: vlanShippedResponse);
      setupSetMocks();

      // What the PPPoE step submits with the VLAN field closed.
      const config = PnpIspConfig(
        type: IspConnectionType.pppoe,
        pppUsername: 'userrr',
        pppPassword: 'passsss',
        vlanEnabled: false,
        vlanId: 0,
      );

      await service.saveIspSettings(config);

      verifyNever(() => mockUsp.set(any(that: writesVlanId)));
    });

    // The Static IP step has no VLAN field, so its config carries the default
    // VLAN ID 0, which the shipped row refuses just the same (#1072).
    test('Static IP writes no VLAN ID to the shipped VLAN row (#1072)',
        () async {
      setupFetchMocks(
          pppResponse: pppFactoryResponse, vlanResponse: vlanShippedResponse);
      setupSetMocks();

      // What the Static IP step submits.
      const config = PnpIspConfig(
        type: IspConnectionType.staticIp,
        staticIpAddress: '192.168.1.100',
        subnetMask: '255.255.255.0',
        defaultGateway: '192.168.1.1',
        dnsServer1: '8.8.8.8',
        dnsServer2: '8.8.4.4',
      );

      await service.saveIspSettings(config);

      verifyNever(() => mockUsp.set(any(that: writesVlanId)));
    });
  });
}
