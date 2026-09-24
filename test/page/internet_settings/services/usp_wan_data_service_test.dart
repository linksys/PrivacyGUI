import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/internet_settings/services/usp_wan_data_service.dart';

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
    when(() => mockUsp.get(any(), priority: any(named: 'priority')))
        .thenAnswer((invocation) async {
      final paths = invocation.positionalArguments[0] as List<String>;

      // WanStatus.fetch paths (Device.IP.Interface.2.*)
      if (paths.any((p) => p.contains('Device.IP.Interface.2.Status'))) {
        return {
          'Device.IP.Interface.2.Status': status,
          'Device.IP.Interface.2.IPv4Address.1.IPAddress': ipAddress,
          'Device.IP.Interface.2.IPv4Address.1.SubnetMask': subnetMask,
          'Device.IP.Interface.2.IPv4Address.1.AddressingType': addressingType,
          'Device.IP.Interface.2.MaxMTUSize': maxMtuSize.toString(),
          'Device.IP.Interface.2.IPv6Enable': ipv6Enabled,
        };
      }

      // Gateway query (StaticRouting.fetch uses Device.Routing.*)
      if (paths.any((p) => p.contains('Routing'))) {
        return {
          // StaticRouting requires all fields for validation
          'Device.Routing.Router.1.IPv4Forwarding.1.Enable': true,
          'Device.Routing.Router.1.IPv4Forwarding.1.DestIPAddress': '0.0.0.0',
          'Device.Routing.Router.1.IPv4Forwarding.1.DestSubnetMask': '0.0.0.0',
          'Device.Routing.Router.1.IPv4Forwarding.1.GatewayIPAddress': gateway,
          'Device.Routing.Router.1.IPv4Forwarding.1.Interface':
              'Device.IP.Interface.2',
          'Device.Routing.Router.1.IPv4Forwarding.1.Origin': 'Static',
          'Device.Routing.Router.1.IPv4Forwarding.1.Alias': 'DefaultRoute',
        };
      }

      // IPv6 addresses query (WanIpv6Addresses.fetch)
      if (paths.any((p) => p.contains('IPv6Address'))) {
        final result = <String, dynamic>{};
        for (var i = 0; i < ipv6Addresses.length; i++) {
          result['Device.IP.Interface.2.IPv6Address.${i + 1}.IPAddress'] =
              ipv6Addresses[i];
        }
        return result;
      }

      return {};
    });
  }

  // ---------------------------------------------------------------------------
  // WAN Status mapping
  // ---------------------------------------------------------------------------

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
    /// Stubs a WAN interface resolved to [wanInstance] (via Alias='wan') plus a
    /// default route whose Interface is [routeInterface]. Used to prove the
    /// gateway lookup follows the resolved instance and matches it exactly.
    void stubResolvedWan({
      required int wanInstance,
      required String routeInterface,
      String gateway = '198.51.100.1',
    }) {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;

        // Routing query first: StaticRouting.fetch requests an
        // `IPv4Forwarding.*.Alias` path too, so it must be matched before the
        // WAN-interface Alias resolution below.
        if (paths.any((p) => p.contains('Routing'))) {
          return {
            'Device.Routing.Router.1.IPv4Forwarding.1.Enable': true,
            'Device.Routing.Router.1.IPv4Forwarding.1.DestIPAddress': '0.0.0.0',
            'Device.Routing.Router.1.IPv4Forwarding.1.DestSubnetMask':
                '0.0.0.0',
            'Device.Routing.Router.1.IPv4Forwarding.1.GatewayIPAddress':
                gateway,
            'Device.Routing.Router.1.IPv4Forwarding.1.Interface':
                routeInterface,
            'Device.Routing.Router.1.IPv4Forwarding.1.Origin': 'Static',
            'Device.Routing.Router.1.IPv4Forwarding.1.Alias': 'DefaultRoute',
          };
        }

        // WAN-interface Alias resolution → WAN is on `wanInstance`. Issued by
        // resolveWanInterfacePath and the generated _resolveInstance helpers.
        if (paths
            .any((p) => p.contains('IP.Interface') && p.contains('Alias'))) {
          return {
            'Device.IP.Interface.1.Alias': 'lan',
            'Device.IP.Interface.$wanInstance.Alias': 'wan',
          };
        }

        // WanStatus.fetch resolves its own instance via Alias, so answer its
        // per-instance Status paths for `wanInstance`.
        if (paths.any((p) => p.contains('.Status'))) {
          return {
            'Device.IP.Interface.$wanInstance.Status': 'Up',
            'Device.IP.Interface.$wanInstance.IPv4Address.1.IPAddress':
                '1.2.3.4',
            'Device.IP.Interface.$wanInstance.IPv4Address.1.SubnetMask':
                '255.255.255.0',
            'Device.IP.Interface.$wanInstance.IPv4Address.1.AddressingType':
                'DHCP',
            'Device.IP.Interface.$wanInstance.MaxMTUSize': '1500',
            'Device.IP.Interface.$wanInstance.IPv6Enable': false,
          };
        }

        // IPv6 address query (WanIpv6Addresses.fetch) — empty is valid.
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

    test('returns empty gateway if no default route found', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;

        if (paths.any((p) => p.contains('Device.IP.Interface.2.Status'))) {
          return {
            'Device.IP.Interface.2.Status': 'Up',
            'Device.IP.Interface.2.IPv4Address.1.IPAddress': '1.2.3.4',
            'Device.IP.Interface.2.IPv4Address.1.SubnetMask': '255.255.255.0',
            'Device.IP.Interface.2.IPv4Address.1.AddressingType': 'Static',
            'Device.IP.Interface.2.MaxMTUSize': '1500',
            'Device.IP.Interface.2.IPv6Enable': false,
          };
        }

        // No default route (DestIPAddress != 0.0.0.0)
        if (paths.any((p) => p.contains('Routing'))) {
          return {
            'Device.Routing.Router.1.IPv4Forwarding.1.Enable': true,
            'Device.Routing.Router.1.IPv4Forwarding.1.DestIPAddress':
                '192.168.1.0',
            'Device.Routing.Router.1.IPv4Forwarding.1.DestSubnetMask':
                '255.255.255.0',
            'Device.Routing.Router.1.IPv4Forwarding.1.GatewayIPAddress':
                '192.168.1.1',
            'Device.Routing.Router.1.IPv4Forwarding.1.Interface':
                'Device.IP.Interface.1',
            'Device.Routing.Router.1.IPv4Forwarding.1.Origin': 'Static',
            'Device.Routing.Router.1.IPv4Forwarding.1.Alias': 'LanRoute',
          };
        }

        return {};
      });

      final result = await svc.fetch();

      expect(result.gateway, isEmpty);
    });

    test('gateway query failure returns empty gracefully', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;

        if (paths.any((p) => p.contains('Device.IP.Interface.2.Status'))) {
          return {
            'Device.IP.Interface.2.Status': 'Up',
            'Device.IP.Interface.2.IPv4Address.1.IPAddress': '1.2.3.4',
            'Device.IP.Interface.2.IPv4Address.1.SubnetMask': '255.255.255.0',
            'Device.IP.Interface.2.IPv4Address.1.AddressingType': 'Static',
            'Device.IP.Interface.2.MaxMTUSize': '1500',
            'Device.IP.Interface.2.IPv6Enable': false,
          };
        }

        // Gateway/IPv6 query throws
        if (paths.any((p) => p.contains('Routing'))) {
          throw Exception('routing not supported');
        }

        return {};
      });

      // Service does parallel fetch: WanStatus succeeds, gateway fails
      // Since gateway helper catches and returns empty, the fetch should still succeed
      // but ipAddress comes from WanStatus which succeeds
      final result = await svc.fetch();

      expect(result.gateway, isEmpty);
      expect(result.ipv6Addresses, isEmpty);
      expect(result.ipAddress, '1.2.3.4');
    });
  });

  // ---------------------------------------------------------------------------
  // Error handling
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // A WAN with no address instance — linksys/PrivacyGUI#1615
  //
  // Measured on FW 2.0.2.26091803 with the interface down: `Status` is `Dormant`,
  // `IPv4AddressNumberOfEntries` is `0`, and `IPv4Address.1.*` do not exist as
  // parameters at all. The generated `WanStatus._fromResponse` treats three of those as
  // required and throws, so every refresh while the WAN is down failed — the very
  // refresh that should tell the UI to stop showing a dead address.
  //
  // Translating that into "no address" is a domain judgement, which is why it lives in
  // the service layer rather than in the generated model (constitution Article VI).
  // These three tests pin the shape of that judgement: it applies in the measured case,
  // and NOT in either way of getting the same error for a different reason.
  // ---------------------------------------------------------------------------
  group('UspWanDataService — WAN with no address instance (#1615)', () {
    /// The device as measured with the WAN down: the address parameters are absent from
    /// the response, and the interface reports zero address entries.
    /// Same as [stubWanDownNoAddress] but returns `entries` with its real type rather
    /// than as a string — the device does both, depending on firmware.
    void stubWanDownNoAddressTyped(Object entries) {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
        if (paths.any((p) => p.contains('IPv4AddressNumberOfEntries'))) {
          return {'Device.IP.Interface.2.IPv4AddressNumberOfEntries': entries};
        }
        if (paths.any((p) => p.contains('Device.IP.Interface.2.Status'))) {
          return {
            'Device.IP.Interface.2.Status': 'Dormant',
            'Device.IP.Interface.2.MaxMTUSize': '1500',
            'Device.IP.Interface.2.IPv6Enable': false,
          };
        }
        return {};
      });
    }

    void stubWanDownNoAddress({String entries = '0'}) {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;

        if (paths.any((p) => p.contains('IPv4AddressNumberOfEntries'))) {
          return {'Device.IP.Interface.2.IPv4AddressNumberOfEntries': entries};
        }
        if (paths.any((p) => p.contains('Device.IP.Interface.2.Status'))) {
          // IPv4Address.1.* deliberately absent — this is what the device returns.
          return {
            'Device.IP.Interface.2.Status': 'Dormant',
            'Device.IP.Interface.2.MaxMTUSize': '1500',
            'Device.IP.Interface.2.IPv6Enable': false,
          };
        }
        if (paths.any((p) => p.contains('Routing'))) return {};
        if (paths.any((p) => p.contains('IPv6Address'))) return {};
        return {};
      });
    }

    test('reports the WAN as down with an empty address, rather than throwing',
        () async {
      stubWanDownNoAddress();
      final service = UspWanDataService(mockUsp);

      final model = await service.fetch();

      expect(model.isUp, isFalse);
      expect(model.ipAddress, isEmpty,
          reason:
              'an absent address must read as no address — the whole point is that '
              'the UI stops showing the one that no longer exists');
      expect(model.subnetMask, isEmpty);
      expect(model.addressingType, isEmpty);
    });

    // The three branches added when this tolerance was reviewed. Each was reachable and
    // none was covered — the existing tests all passed against the looser version.
    test('entries reported as a NUMBER, not a string, still reads as WAN down',
        () async {
      // The device's value arrives untyped and its shape varies across firmware. A string
      // comparison against '0' failed CLOSED — an `int` 0 was read as "not zero", turning
      // a down WAN back into a fetch error, which is the defect this whole method exists
      // to prevent.
      stubWanDownNoAddressTyped(0);
      final service = UspWanDataService(mockUsp);

      final model = await service.fetch();
      expect(model.isUp, isFalse);
      expect(model.ipAddress, isEmpty);
    });

    test('entries with surrounding whitespace still reads as WAN down',
        () async {
      stubWanDownNoAddress(entries: ' 0 ');
      final service = UspWanDataService(mockUsp);

      final model = await service.fetch();
      expect(model.isUp, isFalse);
    });

    test('an unparseable entries value throws rather than guessing', () async {
      // "Not confirmed zero" is not "confirmed zero". If the device answers something
      // this code cannot read, the original validation error is the honest outcome.
      stubWanDownNoAddress(entries: 'unexpected');
      final service = UspWanDataService(mockUsp);

      await expectLater(service.fetch(), throwsA(isA<ServiceError>()));
    });

    test(
        'a failed confirmation surfaces the ORIGINAL error, not the confirmation\'s',
        () async {
      // The confirming `get` can fail on its own. Unguarded it replaced the original
      // error — which is both more accurate and the one a triager needs. A failed
      // confirmation is not a confirmation.
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
        if (paths.any((p) => p.contains('IPv4AddressNumberOfEntries'))) {
          throw const NetworkError(detail: 'socket closed mid-confirmation');
        }
        if (paths.any((p) => p.contains('Device.IP.Interface.2.Status'))) {
          return {
            'Device.IP.Interface.2.Status': 'Dormant',
            'Device.IP.Interface.2.MaxMTUSize': '1500',
            'Device.IP.Interface.2.IPv6Enable': false,
          };
        }
        return {};
      });
      final service = UspWanDataService(mockUsp);

      await expectLater(
        service.fetch(),
        throwsA(
          isA<ServiceError>().having(
            (e) => e.toString(),
            'message',
            contains('9998'),
          ),
        ),
        reason:
            'the codegen validation error must survive, not the socket failure',
      );
    });

    test('still throws when the device reports it HAS an address', () async {
      // Same validation error, but the device contradicts it: entries is 1, so the
      // fields should have been in the response and something else is wrong. Swallowing
      // this would render a real fault as "the WAN is down".
      stubWanDownNoAddress(entries: '1');
      final service = UspWanDataService(mockUsp);

      await expectLater(service.fetch(), throwsA(isA<ServiceError>()));
    });

    test('still throws for a validation error about a different field',
        () async {
      // `MaxMTUSize` missing is not an addressing state, and must not be absorbed.
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
        if (paths.any((p) => p.contains('Device.IP.Interface.2.Status'))) {
          return {
            'Device.IP.Interface.2.Status': 'Up',
            'Device.IP.Interface.2.IPv4Address.1.IPAddress': '203.0.113.1',
            'Device.IP.Interface.2.IPv4Address.1.SubnetMask': '255.255.255.0',
            'Device.IP.Interface.2.IPv4Address.1.AddressingType': 'DHCP',
            'Device.IP.Interface.2.IPv6Enable': false,
            // MaxMTUSize absent
          };
        }
        return {};
      });
      final service = UspWanDataService(mockUsp);

      await expectLater(service.fetch(), throwsA(isA<ServiceError>()));
    });
  });

  group('UspWanDataService — error handling', () {
    test('fetch maps USP error to ServiceError', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenThrow('Get failed: Transport error');

      expect(() => svc.fetch(), throwsA(isA<ServiceError>()));
    });
  });
}
