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
  });

  // ---------------------------------------------------------------------------
  // Gateway parsing edge cases
  // ---------------------------------------------------------------------------

  group('UspWanDataService — gateway parsing', () {
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

  group('UspWanDataService — error handling', () {
    test('fetch maps USP error to ServiceError', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenThrow('Get failed: Transport error');

      expect(() => svc.fetch(), throwsA(isA<ServiceError>()));
    });
  });
}
