import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/dhcp_data_provider.dart';

class MockUspService extends Mock implements UspService {}

void main() {
  late MockUspService mockUsp;

  /// DhcpClients codegen response.
  final dhcpClientsResponse = <String, dynamic>{
    'Device.DHCPv4.Server.Pool.1.Client.1.Chaddr': 'AA:BB:CC:DD:EE:01',
    'Device.DHCPv4.Server.Pool.1.Client.1.Active': true,
    'Device.DHCPv4.Server.Pool.1.Client.1.IPv4Address.1.IPAddress':
        '192.168.1.101',
    'Device.DHCPv4.Server.Pool.1.Client.1.IPv4Address.1.LeaseTimeRemaining':
        '2030-01-01T00:00:00Z',
    'Device.DHCPv4.Server.Pool.1.Client.2.Chaddr': 'AA:BB:CC:DD:EE:02',
    'Device.DHCPv4.Server.Pool.1.Client.2.Active': false,
    'Device.DHCPv4.Server.Pool.1.Client.2.IPv4Address.1.IPAddress':
        '192.168.1.102',
    'Device.DHCPv4.Server.Pool.1.Client.2.IPv4Address.1.LeaseTimeRemaining':
        '2020-01-01T00:00:00Z',
  };

  /// DhcpReservations codegen response.
  final dhcpReservationsResponse = <String, dynamic>{
    'Device.DHCPv4.Server.Pool.1.StaticAddress.1.Enable': true,
    'Device.DHCPv4.Server.Pool.1.StaticAddress.1.Chaddr': 'AA:BB:CC:DD:EE:01',
    'Device.DHCPv4.Server.Pool.1.StaticAddress.1.Yiaddr': '192.168.1.50',
  };

  setUp(() {
    mockUsp = MockUspService();
    // DhcpClients.fetch + DhcpReservations.fetch both call usp.get()
    when(() => mockUsp.get(any())).thenAnswer((_) async {
      final paths = _.positionalArguments[0] as List;
      if (paths.any((p) => p.toString().contains('StaticAddress'))) {
        return dhcpReservationsResponse;
      }
      return dhcpClientsResponse;
    });
    when(() => mockUsp.set(any())).thenAnswer((_) async {});
    when(() => mockUsp.add(any(), any())).thenAnswer((_) async => 'new.1.');
    when(() => mockUsp.delete(any())).thenAnswer((_) async {});
  });

  ProviderContainer createContainer({
    DevicesData? devicesData,
  }) {
    return ProviderContainer(
      overrides: [
        uspServiceProvider.overrideWithValue(mockUsp),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
        devicesDataProvider.overrideWith(
          () => _TestDevicesDataNotifier(devicesData ?? const DevicesData()),
        ),
      ],
    );
  }

  group('DhcpDataNotifier', () {
    test('build fetches clients and reservations', () async {
      final container = createContainer();
      final data = await container.read(dhcpDataProvider.future);

      expect(data.clientModels, hasLength(2));
      expect(data.reservationModels, hasLength(1));

      // Verify client fields
      expect(data.clientModels[0].mac, 'AA:BB:CC:DD:EE:01');
      expect(data.clientModels[0].ip, '192.168.1.101');
      expect(data.clientModels[0].active, isTrue);
      expect(data.clientModels[1].active, isFalse);

      // Verify reservation fields
      expect(data.reservationModels[0].mac, 'AA:BB:CC:DD:EE:01');
      expect(data.reservationModels[0].ip, '192.168.1.50');
      expect(data.reservationModels[0].enable, isTrue);
      container.dispose();
    });

    test('hostname enrichment from devicesData', () async {
      final container = createContainer(
        devicesData: const DevicesData(
          hostNameByMac: {'AA:BB:CC:DD:EE:01': 'MyLaptop'},
        ),
      );
      // Ensure devicesDataProvider resolves before dhcpDataProvider reads it.
      await container.read(devicesDataProvider.future);
      final data = await container.read(dhcpDataProvider.future);

      expect(data.clientModels[0].hostName, 'MyLaptop');
      expect(data.clientModels[0].displayName, 'MyLaptop');
      // Client 2 has no hostname entry
      expect(data.clientModels[1].hostName, isEmpty);
      container.dispose();
    });

    test('build throws when usp is null', () async {
      final container = ProviderContainer(
        overrides: [
          uspServiceProvider.overrideWithValue(null),
          devicesDataProvider.overrideWith(
            () => _TestDevicesDataNotifier(const DevicesData()),
          ),
        ],
      );

      expect(
        container.read(dhcpDataProvider.future),
        throwsA(isA<StateError>()),
      );
      container.dispose();
    });

    test('toggleReservation calls update and invalidates', () async {
      final container = createContainer();
      await container.read(dhcpDataProvider.future);

      await container.read(dhcpDataProvider.notifier).toggleReservation(
            'Device.DHCPv4.Server.Pool.1.StaticAddress.1.',
            false,
          );

      verify(() => mockUsp.set(any())).called(1);
      container.dispose();
    });

    test('addReservation calls add and invalidates', () async {
      final container = createContainer();
      await container.read(dhcpDataProvider.future);

      await container.read(dhcpDataProvider.notifier).addReservation(
            mac: 'AA:BB:CC:DD:EE:99',
            ip: '192.168.1.99',
          );

      verify(() => mockUsp.add(any(), any())).called(1);
      container.dispose();
    });

    test('updateReservation calls set and invalidates', () async {
      final container = createContainer();
      await container.read(dhcpDataProvider.future);

      await container.read(dhcpDataProvider.notifier).updateReservation(
            instancePath: 'Device.DHCPv4.Server.Pool.1.StaticAddress.1.',
            ip: '192.168.1.55',
          );

      verify(() => mockUsp.set(any())).called(1);
      container.dispose();
    });

    test('deleteReservation calls delete and invalidates', () async {
      final container = createContainer();
      await container.read(dhcpDataProvider.future);

      await container.read(dhcpDataProvider.notifier).deleteReservation(
            'Device.DHCPv4.Server.Pool.1.StaticAddress.1.',
          );

      verify(() => mockUsp.delete(any())).called(1);
      container.dispose();
    });

    test('empty clients and reservations', () async {
      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => <String, dynamic>{});

      final container = createContainer();
      final data = await container.read(dhcpDataProvider.future);

      expect(data.clientModels, isEmpty);
      expect(data.reservationModels, isEmpty);
      container.dispose();
    });
  });
}

/// Test override for DevicesDataNotifier.
class _TestDevicesDataNotifier extends DevicesDataNotifier {
  final DevicesData _data;

  _TestDevicesDataNotifier(this._data);

  @override
  Future<DevicesData> build() async => _data;
}
