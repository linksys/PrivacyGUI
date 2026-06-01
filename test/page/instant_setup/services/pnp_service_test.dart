import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_isp_config.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_service.dart';

class MockUspClient extends Mock implements UspClient {}

void main() {
  late MockUspClient mockUsp;
  late PnpService service;

  // Standard WAN response (DHCP mode)
  // Note: WanSettings.fetch() requests PPP.Interface.1.Username/Password
  // even though they're logically PPP fields — codegen bundles them together.
  const wanResponse = <String, dynamic>{
    'Device.IP.Interface.2.IPv4Address.1.AddressingType': 'DHCP',
    'Device.IP.Interface.2.MaxMTUSize': '1500',
    'Device.IP.Interface.2.IPv4Address.1.IPAddress': '',
    'Device.IP.Interface.2.IPv4Address.1.SubnetMask': '',
    'Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DefaultGateway': '',
    'Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DNSServers': '',
    'Device.PPP.Interface.1.Username': '',
    'Device.PPP.Interface.1.Password': '',
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
  };

  const vlanExistingResponse = <String, dynamic>{
    'Device.Ethernet.VLANTermination.1.Enable': true,
    'Device.Ethernet.VLANTermination.1.VLANID': '100',
  };

  // Alias resolution response for WanSettings and Ipv6Settings _resolveInstance()
  const aliasResolutionResponse = <String, dynamic>{
    'Device.IP.Interface.1.Alias': 'cpe-lan',
    'Device.IP.Interface.2.Alias': 'cpe-wan',
  };

  void setupFetchMocks({
    Map<String, dynamic> pppResponse = pppEmptyResponse,
    Map<String, dynamic> vlanResponse = vlanEmptyResponse,
  }) {
    when(() => mockUsp.get(any())).thenAnswer((invocation) async {
      final paths = invocation.positionalArguments[0] as List<String>;
      // Handle _resolveInstance() calls for WanSettings/Ipv6Settings
      if (paths.any((p) => p.contains('Interface.*.Alias'))) {
        return aliasResolutionResponse;
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

  void setupDeleteMock() {
    when(() => mockUsp.delete(any())).thenAnswer((_) async => {
          'success': true,
          'result': {'data': <String, dynamic>{}},
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
      // saveAll:
      // - WanStaticIp.updateOrdered() → _resolveInstance() = 1 call
      // - Ipv6Settings.update() → _resolveInstance() = 1 call
      // Total = 8 get calls
      verify(() => mockUsp.get(any())).called(8);

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
      // fetchSettings: 6 calls
      // saveAll:
      // - WanPppoe.update() → _resolveInstance() = 1 call
      // - Ipv6Settings.update() → _resolveInstance() = 1 call
      // Total = 8 get calls
      verify(() => mockUsp.get(any())).called(8);

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
        'PPPoE+VLAN → PPPoE: calls VlanTermination.delete to remove VLAN instance',
        () async {
      // Start with PPPoE+VLAN enabled
      final wanPppoeResponse = Map<String, dynamic>.from(wanResponse);
      wanPppoeResponse['Device.IP.Interface.2.IPv4Address.1.AddressingType'] =
          'IPCP';

      when(() => mockUsp.get(any())).thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
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
        return {};
      });
      setupSetMocks();
      setupDeleteMock();

      // PnpIspConfig with PPPoE (no VLAN) — this should trigger VLAN delete
      const config = PnpIspConfig(
        type: IspConnectionType.pppoe,
        pppUsername: 'existinguser',
        pppPassword: 'existingpass',
        vlanEnabled: false,
        vlanId: 0,
      );

      await service.saveIspSettings(config);

      // Verify fetchSettings was called
      verify(() => mockUsp.get(any())).called(7);

      // Verify VlanTermination.delete was called
      final deleteCaptures =
          verify(() => mockUsp.delete(captureAny())).captured;
      expect(deleteCaptures, isNotEmpty);
      final deletePaths = deleteCaptures.first as List<String>;
      expect(deletePaths, contains('Device.Ethernet.VLANTermination.1.'));
    });

    test('PPPoE+VLAN: creates VLAN instance when enabling VLAN', () async {
      // Start with PPPoE (no VLAN)
      final wanPppoeResponse = Map<String, dynamic>.from(wanResponse);
      wanPppoeResponse['Device.IP.Interface.2.IPv4Address.1.AddressingType'] =
          'IPCP';

      when(() => mockUsp.get(any())).thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
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
          return vlanEmptyResponse; // No existing VLAN
        }
        return {};
      });
      setupSetMocks();
      setupAddMock(createdPath: 'Device.Ethernet.VLANTermination.1.');

      const config = PnpIspConfig(
        type: IspConnectionType.pppoeVlan,
        pppUsername: 'existinguser',
        pppPassword: 'existingpass',
        vlanEnabled: true,
        vlanId: 100,
      );

      await service.saveIspSettings(config);

      // Verify VlanTermination.add was called
      final addCaptures = verify(() => mockUsp.add(captureAny())).captured;
      expect(addCaptures, isNotEmpty);
    });
  });
}
