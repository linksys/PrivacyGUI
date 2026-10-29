import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/active_ipv4_connection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/internet_settings/services/usp_wan_data_service.dart';

import '../../../mocks/test_data/internet_settings_test_data.dart';

class MockUspClient extends Mock implements UspClient {}

void main() {
  late MockUspClient mockUsp;
  late UspWanDataService svc;

  setUp(() {
    mockUsp = MockUspClient();
    svc = UspWanDataService(mockUsp);
  });

  // ---------------------------------------------------------------------------
  // Helper to stub WanStatus.fetch + gateway/IPv6 query
  // ---------------------------------------------------------------------------

  /// Answers every GET of a WAN status read by the paths requested.
  ///
  /// The WAN is on `Interface.5` with its address on row 3, and the routes sit
  /// on two routers (see [InternetSettingsTestData]). [wanEnable] is the WAN
  /// interface's `Enable`; [wanStatus] replaces the `WanStatus` response;
  /// [routing] replaces the routing response, or throws when it is an [Exception].
  void stubWan({
    Object wanEnable = true,
    Map<String, dynamic>? wanStatus,
    Object? routing,
    List<String> ipv6Addresses = const [],
  }) {
    const wan = InternetSettingsTestData.wanInterface;
    when(() => mockUsp.get(any(), priority: any(named: 'priority')))
        .thenAnswer((invocation) async {
      final paths = invocation.positionalArguments[0] as List<String>;
      if (paths.contains('Device.IP.Interface.*.Alias')) {
        return InternetSettingsTestData.interfaceAliases();
      }
      if (paths.contains('${wan}Enable')) {
        return {
          '${wan}Enable': wanEnable,
          '${wan}MaxMTUSize': '1500',
          '${wan}IPv6Enable': false,
        };
      }
      if (paths.contains('${wan}Status')) {
        return wanStatus ?? InternetSettingsTestData.wanStatus();
      }
      if (paths.any((p) => p.startsWith('Device.Routing.'))) {
        if (routing is Exception) throw routing;
        return (routing as Map<String, dynamic>?) ??
            InternetSettingsTestData.routing();
      }
      if (paths.contains('${wan}IPv6Address.*.IPAddress')) {
        return InternetSettingsTestData.wanIpv6Addresses(ipv6Addresses);
      }
      return {};
    });
  }

  void stubWanStatus({
    String status = 'Up',
    String ipAddress = '203.0.113.1',
    String subnetMask = '255.255.255.0',
    String addressingType = 'DHCP',
    int maxMtuSize = 1500,
    bool ipv6Enabled = false,
    String gateway = '203.0.113.254',
    List<String> ipv6Addresses = const [],
  }) {
    stubWan(
      wanStatus: InternetSettingsTestData.wanStatus(
        status: status,
        ipAddress: ipAddress,
        subnetMask: subnetMask,
        addressingType: addressingType,
        maxMtuSize: maxMtuSize.toString(),
        ipv6Enabled: ipv6Enabled,
      ),
      routing: InternetSettingsTestData.routing(gateway: gateway),
      ipv6Addresses: ipv6Addresses,
    );
  }

  // ---------------------------------------------------------------------------
  // WAN Status mapping
  // ---------------------------------------------------------------------------

  for (final supported in [false, true]) {
    test('ordinary WAN works with Auto-IPoE support $supported', () async {
      stubWanStatus();
      final service = UspWanDataService(mockUsp, autoIPoESupported: supported);

      final result = await service.fetch();

      expect(result.isUp, isTrue);
      expect(result.addressingType, 'DHCP');
      expect(result.gateway, '203.0.113.254');
      final requests = verify(
              () => mockUsp.get(captureAny(), priority: any(named: 'priority')))
          .captured
          .cast<List<String>>()
          .expand((paths) => paths);
      expect(requests.contains(ActiveIpv4Connection.path), supported);
    });

    test('service provider injects Auto-IPoE support $supported', () async {
      stubWanStatus();
      when(() => mockUsp.get([ActiveIpv4Connection.path]))
          .thenAnswer((_) async => {
                ActiveIpv4Connection.path: jsonEncode({
                  'apiVersion': 1,
                  'available': true,
                  'state': 'Up',
                  'activeIPv4Route': true,
                  'tunnelType': 'DS-Lite',
                  'mtu': 1460,
                }),
              });
      final container = ProviderContainer(overrides: [
        uspClientProvider.overrideWithValue(mockUsp),
        deviceCapabilitiesProvider.overrideWithValue(supported
            ? DeviceCapabilities({DeviceCapability.autoIPoE})
            : DeviceCapabilities.empty),
      ]);
      addTearDown(container.dispose);

      final result = await container.read(uspWanDataServiceProvider).fetch();

      expect(result.isUp, isTrue);
      expect(result.addressingType, supported ? 'DS-Lite' : 'DHCP');
      final requests = verify(
              () => mockUsp.get(captureAny(), priority: any(named: 'priority')))
          .captured
          .cast<List<String>>()
          .expand((paths) => paths);
      expect(requests.contains(ActiveIpv4Connection.path), supported);
    });
  }

  group('UspWanDataService — fetch', () {
    test('maps WanStatus fields to UIModel', () async {
      stubWanStatus(
        status: 'Up',
        ipAddress: '203.0.113.1',
        subnetMask: '255.255.255.0',
        addressingType: 'DHCP',
        maxMtuSize: 1500,
        ipv6Enabled: true,
      );

      final result = await svc.fetch();

      expect(result.isUp, isTrue);
      expect(result.ipAddress, '203.0.113.1');
      expect(result.subnetMask, '255.255.255.0');
      expect(result.addressingType, 'DHCP');
      expect(result.mtu, 1500);
      expect(result.ipv6Enabled, isTrue);
    });

    test('isUp derived from status (case insensitive)', () async {
      stubWanStatus(status: 'up');
      var result = await svc.fetch();
      expect(result.isUp, isTrue);

      stubWanStatus(status: 'UP');
      result = await svc.fetch();
      expect(result.isUp, isTrue);

      stubWanStatus(status: 'Down');
      result = await svc.fetch();
      expect(result.isUp, isFalse);

      stubWanStatus(status: 'down');
      result = await svc.fetch();
      expect(result.isUp, isFalse);
    });

    test('gateway parsed from routing table (default route)', () async {
      stubWanStatus(gateway: '10.0.0.1');

      final result = await svc.fetch();

      expect(result.gateway, '10.0.0.1');
    });

    test('IPv6 addresses extracted from interface', () async {
      stubWanStatus(
        ipv6Enabled: true,
        ipv6Addresses: ['2001:db8::1', '2001:db8::2'],
      );

      final result = await svc.fetch();

      expect(result.ipv6Addresses, hasLength(2));
      expect(result.ipv6Addresses, contains('2001:db8::1'));
      expect(result.ipv6Addresses, contains('2001:db8::2'));
    });

    test('global IPv6 surfaces first, link-local kept at end (issue #1128)',
        () async {
      // Instance order as reported by the router in the #1128 diagnostic log:
      // instance 1 is the link-local fe80:: address.
      stubWanStatus(
        ipv6Enabled: true,
        ipv6Addresses: const [
          'fe80::7612:13ff:fe21:5394',
          '2401:e180:8831:505f::1',
          '2401:e180:8831:505f:7612:13ff:fe21:5394',
          '2401:e180:8801:d79d:7612:13ff:fe21:5394',
        ],
      );

      final result = await svc.fetch();

      // The widget shows ipv6Addresses.first, which must be a global unicast
      // address. Link-local is not filtered — every address is kept and merely
      // reordered so global unicast wins; the UI tags the link-local one with a
      // scope badge. So all 4 remain and the link-local sinks to the end.
      expect(result.ipv6Addresses, hasLength(4));
      expect(result.ipv6Addresses.first, '2401:e180:8831:505f::1');
      expect(result.ipv6Addresses.last, 'fe80::7612:13ff:fe21:5394');
    });

    test('link-local-only WAN keeps the link-local address (issue #1128)',
        () async {
      // Real case observed on an M60TB whose upstream assigns no IPv6 prefix:
      // the WAN interface (eth0) holds only a scope-link fe80:: address. It is
      // still surfaced (tagged with a scope badge by the UI), not hidden.
      stubWanStatus(
        ipv6Enabled: true,
        ipv6Addresses: const ['fe80::7612:13ff:fe21:5502'],
      );

      final result = await svc.fetch();

      expect(result.ipv6Addresses, ['fe80::7612:13ff:fe21:5502']);
    });
  });

  // ---------------------------------------------------------------------------
  // Gateway parsing edge cases
  // ---------------------------------------------------------------------------

  group('UspWanDataService — gateway parsing', () {
    /// Stubs a WAN interface resolved to [wanInstance] (via Alias='wan') plus
    /// the routing table of [InternetSettingsTestData.routing], whose default route
    /// is on [routeInterface]. Proves the gateway lookup follows the resolved
    /// instance and matches it exactly.
    void stubResolvedWan({
      required int wanInstance,
      required String routeInterface,
      String gateway = '198.51.100.1',
    }) {
      final wan = 'Device.IP.Interface.$wanInstance.';
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
        if (paths.contains('Device.IP.Interface.*.Alias')) {
          return InternetSettingsTestData.interfaceAliases(wan: wan);
        }
        if (paths.contains('${wan}Enable')) {
          return {'${wan}Enable': true};
        }
        if (paths.contains('${wan}Status')) {
          return InternetSettingsTestData.wanStatus(
              wan: wan, ipAddress: '1.2.3.4');
        }
        if (paths.any((p) => p.startsWith('Device.Routing.'))) {
          return InternetSettingsTestData.routing(
              gateway: gateway, defaultRouteInterface: routeInterface);
        }
        return {};
      });
    }

    test('gateway follows a WAN resolved to a non-2 instance', () async {
      // WAN on Interface.4; the route's Interface matches it → gateway found.
      stubResolvedWan(
        wanInstance: 4,
        routeInterface: 'Device.IP.Interface.4',
        gateway: '198.51.100.1',
      );

      final result = await svc.fetch();

      expect(result.gateway, '198.51.100.1');
    });

    test('WAN Interface.2 does not match a route on Interface.20 (substring)',
        () async {
      // Regression: `contains('Interface.2')` would wrongly match Interface.20.
      // Exact-prefix matching must reject it, leaving the gateway empty.
      stubResolvedWan(
        wanInstance: 2,
        routeInterface: 'Device.IP.Interface.20',
      );

      final result = await svc.fetch();

      expect(result.gateway, isEmpty);
    });

    test('a default route with a trailing dot on Interface still matches',
        () async {
      stubResolvedWan(
        wanInstance: 5,
        routeInterface: 'Device.IP.Interface.5.',
        gateway: '198.51.100.9',
      );

      final result = await svc.fetch();

      expect(result.gateway, '198.51.100.9');
    });

    test('the default route on the WAN is found on any router', () async {
      // The WAN default route sits on router 4, behind a LAN route; router 7
      // holds a default route on another interface that must not be picked.
      stubWan();

      final result = await svc.fetch();

      expect(result.gateway, '203.0.113.254');
    });

    test('a route table the router answers incompletely leaves no gateway',
        () async {
      // usp-codegen 0.19 fails StaticRouting.fetch on a forwarding missing a
      // required leaf; the gateway reads empty and the WAN status still loads.
      stubWan(
        routing: {
          for (final e in InternetSettingsTestData.routing().entries)
            if (!e.key.endsWith('.ForwardingMetric')) e.key: e.value,
        },
      );

      final result = await svc.fetch();

      expect(result.gateway, isEmpty);
      expect(result.ipAddress, '203.0.113.1');
      expect(result.isUp, isTrue);
    });

    test('returns empty gateway if no default route found', () async {
      stubWan(
          routing: InternetSettingsTestData.routing(hasDefaultRoute: false));

      final result = await svc.fetch();

      expect(result.gateway, isEmpty);
    });

    test('gateway query failure returns empty gracefully', () async {
      stubWan(
        wanStatus: InternetSettingsTestData.wanStatus(
            ipAddress: '1.2.3.4', addressingType: 'Static'),
        routing: Exception('routing not supported'),
      );

      // The gateway helper catches and returns empty, so the fetch still
      // succeeds and the address comes from WanStatus.
      final result = await svc.fetch();

      expect(result.gateway, isEmpty);
      expect(result.ipv6Addresses, isEmpty);
      expect(result.ipAddress, '1.2.3.4');
    });

    test('a gateway that cannot be read keeps the IPv6 addresses', () async {
      stubWan(
        routing: Exception('routing not supported'),
        ipv6Addresses: ['2001:db8::1'],
      );

      final result = await svc.fetch();

      expect(result.gateway, isEmpty);
      expect(result.ipv6Addresses, ['2001:db8::1']);
    });
  });

  // ---------------------------------------------------------------------------
  // Error handling
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // A WAN with no address row — linksys/PrivacyGUI#1615
  //
  // Measured on FW 2.0.2.26091803 with the interface down: `Status` is
  // `Dormant`, `IPv4AddressNumberOfEntries` is `0`, and no `IPv4Address.{i}`
  // row exists. `WanStatus.ipv4Addresses` is then an empty list: the WAN is
  // down with no address, not a failed read.
  // ---------------------------------------------------------------------------
  group('UspWanDataService — WAN with no address row (#1615)', () {
    test('reports the WAN as down with an empty address, rather than throwing',
        () async {
      stubWan(
        wanStatus: InternetSettingsTestData.wanStatus(
            status: 'Dormant', hasAddress: false),
      );

      final model = await svc.fetch();

      expect(model.isUp, isFalse);
      expect(model.ipAddress, isEmpty,
          reason: 'an absent address must read as no address, so the UI '
              'stops showing the one that no longer exists');
      expect(model.subnetMask, isEmpty);
      expect(model.addressingType, isEmpty);
      expect(model.mtu, 1500);
    });

    test('an Up status with no address row still reads as down', () async {
      stubWan(wanStatus: InternetSettingsTestData.wanStatus(hasAddress: false));

      final model = await svc.fetch();

      expect(model.isUp, isFalse);
      expect(model.ipAddress, isEmpty);
    });

    test('the first address row is the WAN address', () async {
      stubWan(wanStatus: {
        ...InternetSettingsTestData.wanStatus(ipAddress: '203.0.113.7'),
        '${InternetSettingsTestData.wanInterface}IPv4Address.8.IPAddress':
            '198.51.100.8',
        '${InternetSettingsTestData.wanInterface}IPv4Address.8.SubnetMask':
            '255.255.0.0',
        '${InternetSettingsTestData.wanInterface}IPv4Address.8.AddressingType':
            'Static',
      });

      final model = await svc.fetch();

      expect(model.ipAddress, '203.0.113.7');
      expect(model.addressingType, 'DHCP');
    });

    test('still throws for a missing field that is not an address', () async {
      // `MaxMTUSize` missing is not an addressing state, and must not be
      // absorbed.
      stubWan(
        wanStatus: InternetSettingsTestData.wanStatus()
          ..remove('${InternetSettingsTestData.wanInterface}MaxMTUSize'),
      );

      await expectLater(svc.fetch(), throwsA(isA<ServiceError>()));
    });
  });

  group('UspWanDataService — error handling', () {
    test('fetch maps USP error to ServiceError', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenThrow('Get failed: Transport error');

      expect(() => svc.fetch(), throwsA(isA<ServiceError>()));
    });
  });
  group('UspWanDataService native connection error handling', () {
    setUp(() {
      svc = UspWanDataService(mockUsp, autoIPoESupported: true);
    });
    for (final error in const <ServiceError>[
      NotAuthenticatedError(
          code: 401, detail: 'Synthetic authentication failure'),
      SessionTokenExpiredError(detail: 'Synthetic expired session'),
      InvalidSessionTokenError(detail: 'Synthetic invalid session'),
      NetworkError(code: 503, detail: 'Synthetic unavailable service'),
      InvalidInputError(code: 7004, detail: 'Synthetic invalid response'),
    ]) {
      test('preserves ${error.runtimeType} from the native read', () async {
        when(() => mockUsp.get(any())).thenThrow(error);

        await expectLater(svc.fetch(), throwsA(same(error)));

        verify(() => mockUsp.get(any())).called(1);
        verifyNoMoreInteractions(mockUsp);
      });
    }

    test('keeps a mapped HTTP auth failure through the outer catch', () async {
      when(() => mockUsp.get(any()))
          .thenThrow('Get failed: Transport error: HTTP error: HTTP 401');

      await expectLater(
        svc.fetch(),
        throwsA(
            isA<NotAuthenticatedError>().having((e) => e.code, 'code', 401)),
      );

      verify(() => mockUsp.get(any())).called(1);
      verifyNoMoreInteractions(mockUsp);
    });
  });

  // ---------------------------------------------------------------------------
  // Bridge mode (#1597)
  // ---------------------------------------------------------------------------

  group('UspWanDataService — bridge mode', () {
    // WAN and LAN deliberately on instances other than 2 and 1, so a read that
    // assumed a fixed instance number could not pass.
    void stubBridged({
      Object enable = false,
      String lanIp = '10.92.12.83',
      String lanMask = '255.255.255.0',
      bool lanHasRow = true,
    }) {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
        if (paths.contains('Device.IP.Interface.*.Alias')) {
          return {
            'Device.IP.Interface.3.Alias': 'lan',
            'Device.IP.Interface.5.Alias': 'wan',
            'Device.IP.Interface.6.Alias': '',
          };
        }
        if (paths.contains('Device.IP.Interface.5.Enable')) {
          return {
            'Device.IP.Interface.5.Enable': enable,
            'Device.IP.Interface.5.MaxMTUSize': '1500',
            'Device.IP.Interface.5.IPv6Enable': true,
          };
        }
        // LanNetworkInfo on the lan interface. Its first address row is the
        // lease br-lan took upstream; a later row must not be read.
        if (paths.contains('Device.IP.Interface.3.IPv4Address.*.IPAddress')) {
          return {
            'Device.DeviceInfo.HostName': 'Linksys00080',
            'Device.IP.Interface.3.IPv6Enable': true,
            if (lanHasRow) ...{
              'Device.IP.Interface.3.IPv4Address.4.IPAddress': lanIp,
              'Device.IP.Interface.3.IPv4Address.4.SubnetMask': lanMask,
              'Device.IP.Interface.3.IPv4Address.9.IPAddress': '169.254.0.1',
              'Device.IP.Interface.3.IPv4Address.9.SubnetMask': '255.255.0.0',
            },
          };
        }
        if (paths.any((p) => p.startsWith('Device.Routing.'))) {
          return InternetSettingsTestData.routing(gateway: '10.92.12.1');
        }
        if (paths.any((p) => p.contains('Device.IP.Interface.5.Status'))) {
          throw StateError('a bridged WAN must not read the WAN IPv4 row');
        }
        return {};
      });
    }

    test('reports Bridge and takes the IP from the lan interface', () async {
      stubBridged();

      final result = await svc.fetch();

      expect(result.addressingType, UspWanDataService.bridgeAddressingType);
      expect(result.ipAddress, '10.92.12.83');
      expect(result.subnetMask, '255.255.255.0');
      expect(result.isUp, isTrue);
      expect(result.mtu, 1500);
      expect(result.ipv6Enabled, isTrue);
      expect(result.gateway, '10.92.12.1');
    });

    test('Enable reported as the integer 0 reads as bridge, as on Settings',
        () async {
      // The Internet Settings page treats any Enable that is not true as
      // bridge; the dashboard must agree.
      stubBridged(enable: 0);

      final result = await svc.fetch();

      expect(result.addressingType, UspWanDataService.bridgeAddressingType);
    });

    test('an absent Enable is not a bridge reading', () async {
      // Without an Enable value there is no bridge reading, so the WAN row is
      // read as usual.
      const wan = InternetSettingsTestData.wanInterface;
      stubWanStatus(addressingType: 'DHCP', ipAddress: '203.0.113.5');
      when(() => mockUsp.get([
            '${wan}Enable',
            '${wan}MaxMTUSize',
            '${wan}IPv6Enable',
          ])).thenAnswer((_) async => {'${wan}MaxMTUSize': '1500'});

      final result = await svc.fetch();

      expect(result.addressingType, 'DHCP');
      expect(result.ipAddress, '203.0.113.5');
    });

    test('Enable reported as the string "0" still reads as bridge', () async {
      stubBridged(enable: '0');

      final result = await svc.fetch();

      expect(result.addressingType, UspWanDataService.bridgeAddressingType);
    });

    test('a lan interface with no address yet reads as down, not an error',
        () async {
      // br-lan has not taken its upstream lease yet.
      stubBridged(lanHasRow: false);

      final result = await svc.fetch();

      expect(result.addressingType, UspWanDataService.bridgeAddressingType);
      expect(result.ipAddress, isEmpty);
      expect(result.isUp, isFalse);
    });

    test('an enabled WAN is not bridge and keeps reading the WAN', () async {
      stubWanStatus(addressingType: 'Static', ipAddress: '203.0.113.9');

      final result = await svc.fetch();

      expect(result.addressingType, 'Static');
      expect(result.ipAddress, '203.0.113.9');
    });
  });
}
