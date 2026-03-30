import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/page/_shared/models/wan_status_ui_model.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';

class MockUspService extends Mock implements UspService {}

void main() {
  late MockUspService mockUsp;

  /// Simulated WAN status response (Device.IP.Interface.2.*).
  final wanStatusResponse = <String, dynamic>{
    'Device.IP.Interface.2.Status': 'Up',
    'Device.IP.Interface.2.IPv4Address.1.IPAddress': '100.64.0.10',
    'Device.IP.Interface.2.IPv4Address.1.SubnetMask': '255.255.255.0',
    'Device.IP.Interface.2.IPv4Address.1.AddressingType': 'DHCP',
    'Device.IP.Interface.2.MaxMTUSize': '1500',
  };

  /// Simulated routing table response for gateway lookup.
  final routingResponse = <String, dynamic>{
    'Device.Routing.Router.1.IPv4Forwarding.1.DestIPAddress': '0.0.0.0',
    'Device.Routing.Router.1.IPv4Forwarding.1.GatewayIPAddress': '100.64.0.1',
    'Device.Routing.Router.1.IPv4Forwarding.1.Interface':
        'Device.IP.Interface.2.',
    'Device.Routing.Router.1.IPv4Forwarding.2.DestIPAddress': '192.168.1.0',
    'Device.Routing.Router.1.IPv4Forwarding.2.GatewayIPAddress': '0.0.0.0',
    'Device.Routing.Router.1.IPv4Forwarding.2.Interface':
        'Device.IP.Interface.1.',
  };

  /// Simulated IPv6 response.
  final ipv6Response = <String, dynamic>{
    'Device.IP.Interface.2.IPv6Enable': true,
    'Device.IP.Interface.2.IPv6Address.1.IPAddress': '2001:db8::1',
    'Device.IP.Interface.2.IPv6Address.2.IPAddress': 'fe80::1',
  };

  setUp(() {
    mockUsp = MockUspService();

    // Route usp.get() calls by path content.
    when(() => mockUsp.get(any())).thenAnswer((invocation) async {
      final paths = invocation.positionalArguments[0] as List;
      final joined = paths.join(',');

      if (joined.contains('IPv4Forwarding')) return routingResponse;
      if (joined.contains('IPv6Enable') || joined.contains('IPv6Address')) {
        return ipv6Response;
      }
      // WAN status (Device.IP.Interface.2.*)
      return wanStatusResponse;
    });
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        uspServiceProvider.overrideWithValue(mockUsp),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
      ],
    );
    container.listen(wanDataProvider, (_, __) {});
    return container;
  }

  group('WanDataNotifier', () {
    // -----------------------------------------------------------------------
    // build / fetch
    // -----------------------------------------------------------------------

    test('fetch builds WanData with IP, status, and gateway', () async {
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final data = container.read(wanDataProvider).requireValue;

      expect(data.model.ipAddress, '100.64.0.10');
      expect(data.model.isUp, isTrue);
      expect(data.model.gateway, '100.64.0.1');
      expect(data.model.subnetMask, '255.255.255.0');
      expect(data.model.mtu, 1500);
      container.dispose();
    });

    test('fetch includes IPv6 addresses when available', () async {
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final data = container.read(wanDataProvider).requireValue;

      expect(data.model.ipv6Enabled, isTrue);
      expect(data.model.ipv6Addresses, contains('2001:db8::1'));
      container.dispose();
    });

    test('fetch sets error state when USP service unavailable', () async {
      final container = ProviderContainer(
        overrides: [
          uspServiceProvider.overrideWithValue(null),
          uspMutationLockProvider.overrideWithValue(UspMutationLock()),
        ],
      );
      container.listen(wanDataProvider, (_, __) {});
      await Future.delayed(Duration.zero);

      final state = container.read(wanDataProvider);
      expect(state.hasError, isTrue);
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // Gateway lookup
    // -----------------------------------------------------------------------

    test(
        'gateway found from default route (DestIPAddress 0.0.0.0 on Interface.2)',
        () async {
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final data = container.read(wanDataProvider).requireValue;
      expect(data.model.gateway, '100.64.0.1');
      container.dispose();
    });

    test('gateway empty when no default route matches', () async {
      when(() => mockUsp.get(any())).thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List;
        final joined = paths.join(',');

        if (joined.contains('IPv4Forwarding')) {
          // No route with DestIP 0.0.0.0 on Interface.2
          return <String, dynamic>{
            'Device.Routing.Router.1.IPv4Forwarding.1.DestIPAddress':
                '192.168.1.0',
            'Device.Routing.Router.1.IPv4Forwarding.1.GatewayIPAddress':
                '0.0.0.0',
            'Device.Routing.Router.1.IPv4Forwarding.1.Interface':
                'Device.IP.Interface.1.',
          };
        }
        if (joined.contains('IPv6')) return ipv6Response;
        return wanStatusResponse;
      });

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final data = container.read(wanDataProvider).requireValue;
      expect(data.model.gateway, isEmpty);
      container.dispose();
    });

    test('gateway gracefully handles fetch failure', () async {
      when(() => mockUsp.get(any())).thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List;
        final joined = paths.join(',');

        if (joined.contains('IPv4Forwarding')) {
          throw Exception('timeout');
        }
        if (joined.contains('IPv6')) return ipv6Response;
        return wanStatusResponse;
      });

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final data = container.read(wanDataProvider).requireValue;
      // Gateway falls back to empty string, rest of data still loads
      expect(data.model.gateway, isEmpty);
      expect(data.model.ipAddress, '100.64.0.10');
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // IPv6 fallback
    // -----------------------------------------------------------------------

    test('IPv6 gracefully handles fetch failure', () async {
      when(() => mockUsp.get(any())).thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List;
        final joined = paths.join(',');

        if (joined.contains('IPv6')) throw Exception('not supported');
        if (joined.contains('IPv4Forwarding')) return routingResponse;
        return wanStatusResponse;
      });

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final data = container.read(wanDataProvider).requireValue;
      expect(data.model.ipv6Enabled, isFalse);
      expect(data.model.ipv6Addresses, isEmpty);
      // Core WAN data still loads
      expect(data.model.ipAddress, '100.64.0.10');
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // WanData equality
    // -----------------------------------------------------------------------

    test('WanData equality uses model props', () {
      const a = WanData(
        model: WanStatusUIModel(
          isUp: true,
          ipAddress: '1.2.3.4',
          subnetMask: '255.255.255.0',
          addressingType: 'DHCP',
          mtu: 1500,
          gateway: '1.2.3.1',
        ),
      );
      const b = WanData(
        model: WanStatusUIModel(
          isUp: true,
          ipAddress: '1.2.3.4',
          subnetMask: '255.255.255.0',
          addressingType: 'DHCP',
          mtu: 1500,
          gateway: '1.2.3.1',
        ),
      );
      expect(a, equals(b));
    });
  });
}
