import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';

class MockUspService extends Mock implements UspService {}

void main() {
  late MockUspService mockUsp;

  /// LanNetworkInfo codegen response (includes IPv6Enable since YAML v1.2.0).
  final lanInfoResponse = <String, dynamic>{
    'Device.IP.Interface.1.IPv4Address.1.IPAddress': '192.168.1.1',
    'Device.IP.Interface.1.IPv4Address.1.SubnetMask': '255.255.255.0',
    'Device.DHCPv4.Server.Pool.1.Enable': true,
    'Device.DHCPv4.Server.Pool.1.MinAddress': '192.168.1.100',
    'Device.DHCPv4.Server.Pool.1.MaxAddress': '192.168.1.199',
    'Device.DHCPv4.Server.Pool.1.LeaseTime': '7200',
    'Device.DHCPv4.Server.Pool.1.DNSServers': '8.8.8.8,8.8.4.4',
    'Device.DeviceInfo.HostName': 'LinksysRouter',
    'Device.IP.Interface.1.IPv6Enable': true,
  };

  /// IPv6 response from raw usp.get().
  final ipv6Response = <String, dynamic>{
    'Device.IP.Interface.1.IPv6Enable': true,
    'Device.IP.Interface.1.IPv6Address.1.IPAddress': 'fe80::1',
    'Device.IP.Interface.1.IPv6Address.2.IPAddress': '2001:db8::1',
  };

  setUp(() {
    mockUsp = MockUspService();
    when(() => mockUsp.get(any())).thenAnswer((_) async {
      final paths = _.positionalArguments[0] as List;
      // IPv6 multi-instance address query (separate from LanNetworkInfo.fetch)
      if (paths.any((p) => p.toString().contains('IPv6Address'))) {
        return ipv6Response;
      }
      return lanInfoResponse;
    });
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        uspServiceProvider.overrideWithValue(mockUsp),
      ],
    );
  }

  group('LanDataNotifier', () {
    test('build fetches LAN info and IPv6', () async {
      final container = createContainer();
      final data = await container.read(lanDataProvider.future);

      expect(data.model.ipAddress, '192.168.1.1');
      expect(data.model.subnetMask, '255.255.255.0');
      expect(data.model.dhcpEnabled, isTrue);
      expect(data.model.minAddress, '192.168.1.100');
      expect(data.model.maxAddress, '192.168.1.199');
      expect(data.model.leaseTimeMinutes, 120); // 7200s / 60
      expect(data.model.dnsServers, '8.8.8.8,8.8.4.4');
      expect(data.model.hostName, 'LinksysRouter');
      expect(data.model.ipv6Enabled, isTrue);
      expect(data.model.ipv6Addresses, ['fe80::1', '2001:db8::1']);
      container.dispose();
    });

    test('build throws ConnectivityError when usp is null', () async {
      final container = ProviderContainer(
        overrides: [
          uspServiceProvider.overrideWithValue(null),
        ],
      );

      expect(
        container.read(lanDataProvider.future),
        throwsA(isA<ConnectivityError>()),
      );
      container.dispose();
    });

    test('IPv6 fetch failure falls back to disabled', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async {
        final paths = _.positionalArguments[0] as List;
        if (paths.any((p) => p.toString().contains('IPv6Address'))) {
          throw Exception('IPv6 not supported');
        }
        return lanInfoResponse;
      });

      final container = createContainer();
      final data = await container.read(lanDataProvider.future);

      // LAN info should still be present
      expect(data.model.ipAddress, '192.168.1.1');
      // ipv6Enabled comes from LanNetworkInfo (still true from IPv6Enable key),
      // but addresses should be empty because the address fetch failed
      expect(data.model.ipv6Enabled, isTrue);
      expect(data.model.ipv6Addresses, isEmpty);
      container.dispose();
    });

    test('dhcpRange formats min ~ max', () async {
      final container = createContainer();
      final data = await container.read(lanDataProvider.future);

      expect(data.model.dhcpRange, '192.168.1.100 ~ 192.168.1.199');
      container.dispose();
    });

    test('LanData.empty() has default values', () {
      const data = LanData.empty();
      expect(data.model.ipAddress, isEmpty);
      expect(data.model.subnetMask, isEmpty);
      expect(data.model.dhcpEnabled, isFalse);
      expect(data.model.minAddress, isEmpty);
      expect(data.model.maxAddress, isEmpty);
    });

    test('LanData equality uses model props', () async {
      final container = createContainer();
      final data1 = await container.read(lanDataProvider.future);
      final data2 = await container.read(lanDataProvider.future);

      expect(data1, equals(data2));
      expect(data1.props, [data1.model]);

      const empty = LanData.empty();
      expect(data1, isNot(equals(empty)));
      container.dispose();
    });

    test('fetch maps USP transport error to ServiceError', () async {
      when(() => mockUsp.get(any()))
          .thenThrow('Get failed: Transport error: Request timeout');

      final container = createContainer();

      expect(
        container.read(lanDataProvider.future),
        throwsA(isA<NetworkError>()),
      );
      container.dispose();
    });
  });
}
