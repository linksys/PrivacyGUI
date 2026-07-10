import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/dhcp_data_provider.dart';

class MockUspClient extends Mock implements UspClient {}

void main() {
  late MockUspClient mockUsp;

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
    mockUsp = MockUspClient();
    // DhcpClients.fetch + DhcpReservations.fetch both call usp.get()
    when(() => mockUsp.get(any())).thenAnswer((_) async {
      final paths = _.positionalArguments[0] as List;
      if (paths.any((p) => p.toString().contains('StaticAddress'))) {
        return dhcpReservationsResponse;
      }
      return dhcpClientsResponse;
    });
    when(() => mockUsp.set(any())).thenAnswer((_) async => {
          'overallSuccess': true,
          'hasAnySuccess': true,
          'hasErrors': false,
          'results': []
        });
    when(() => mockUsp.add(any())).thenAnswer((_) async => {
          'overallSuccess': true,
          'hasAnySuccess': true,
          'hasErrors': false,
          'results': [
            {
              'requestedPath': 'Device.DHCPv4.Server.Pool.1.StaticAddress.',
              'success': true,
              'createdInstances': [
                {
                  'affectedPath':
                      'Device.DHCPv4.Server.Pool.1.StaticAddress.1.',
                  'initialParams': {}
                }
              ]
            }
          ]
        });
    when(() => mockUsp.delete(any())).thenAnswer((_) async => {
          'overallSuccess': true,
          'hasAnySuccess': true,
          'hasErrors': false,
          'results': []
        });
  });

  ProviderContainer createContainer({
    DevicesData? devicesData,
  }) {
    return ProviderContainer(
      overrides: [
        uspClientProvider.overrideWithValue(mockUsp),
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
      expect(data.clientModels[0].leaseActive, isTrue);
      expect(data.clientModels[1].leaseActive, isFalse);

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

    test('isOnline enrichment from devicesData deviceModels', () async {
      final container = createContainer(
        devicesData: const DevicesData(
          hostNameByMac: {'AA:BB:CC:DD:EE:01': 'MyLaptop'},
          deviceModels: [
            DeviceUIModel(
              mac: 'AA:BB:CC:DD:EE:01',
              ip: '192.168.1.101',
              hostName: 'MyLaptop',
              isActive: true,
              isWifi: true,
            ),
            DeviceUIModel(
              mac: 'AA:BB:CC:DD:EE:02',
              ip: '192.168.1.102',
              hostName: '',
              isActive: false,
              isWifi: false,
            ),
          ],
        ),
      );
      await container.read(devicesDataProvider.future);
      final data = await container.read(dhcpDataProvider.future);

      // Client 1: online (from Hosts.Active)
      expect(data.clientModels[0].isOnline, isTrue);
      // Client 2: offline (from Hosts.Active)
      expect(data.clientModels[1].isOnline, isFalse);
      container.dispose();
    });

    test('isOnline is null when no matching device in devicesData', () async {
      // Empty deviceModels - no Hosts data available
      final container = createContainer(
        devicesData: const DevicesData(
          hostNameByMac: {},
          deviceModels: [],
        ),
      );
      await container.read(devicesDataProvider.future);
      final data = await container.read(dhcpDataProvider.future);

      // No matching device, isOnline should be null
      expect(data.clientModels[0].isOnline, isNull);
      expect(data.clientModels[1].isOnline, isNull);
      container.dispose();
    });

    test('build throws when usp is null', () async {
      final container = ProviderContainer(
        overrides: [
          uspClientProvider.overrideWithValue(null),
          devicesDataProvider.overrideWith(
            () => _TestDevicesDataNotifier(const DevicesData()),
          ),
        ],
      );

      expect(
        container.read(dhcpDataProvider.future),
        throwsA(isA<ServiceNotInitializedError>()),
      );
      container.dispose();
    });

    // Mutation tests (toggleReservation, addReservation, updateReservation,
    // deleteReservation) moved to usp_dhcp_reservations_notifier_test.dart
    // as immediate* methods on L2 Provider.

    test('empty clients and reservations', () async {
      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => <String, dynamic>{});

      final container = createContainer();
      final data = await container.read(dhcpDataProvider.future);

      expect(data.clientModels, isEmpty);
      expect(data.reservationModels, isEmpty);
      container.dispose();
    });

    test('DhcpData props uses full lists for equality', () async {
      final container = createContainer();
      final data1 = await container.read(dhcpDataProvider.future);
      final data2 = await container.read(dhcpDataProvider.future);

      expect(data1, equals(data2));
      expect(data1.props, [data1.clientModels, data1.reservationModels]);
      container.dispose();
    });

    test('SSE dhcpReservations domain triggers debounced re-fetch', () {
      fakeAsync((async) {
        final sseController = StreamController<InvalidationDomain>.broadcast();

        final container = ProviderContainer(
          overrides: [
            uspClientProvider.overrideWithValue(mockUsp),
            uspMutationLockProvider.overrideWithValue(UspMutationLock()),
            devicesDataProvider.overrideWith(
              () => _TestDevicesDataNotifier(const DevicesData()),
            ),
            sseInvalidationProvider.overrideWith((ref) => sseController.stream),
          ],
        );

        container.listen(dhcpDataProvider, (_, __) {});
        async.flushMicrotasks();
        clearInteractions(mockUsp);

        // Emit SSE for dhcpReservations
        sseController.add(InvalidationDomain.dhcpReservations);
        async.flushMicrotasks();

        // Timer pending — no re-fetch yet
        verifyNever(() => mockUsp.get(any()));

        // Advance past 500ms debounce
        async.elapse(const Duration(milliseconds: 500));
        async.flushMicrotasks();

        verify(() => mockUsp.get(any())).called(greaterThanOrEqualTo(1));

        sseController.close();
        container.dispose();
      });
    });

    test('SSE dhcpClients domain also triggers re-fetch', () {
      fakeAsync((async) {
        final sseController = StreamController<InvalidationDomain>.broadcast();

        final container = ProviderContainer(
          overrides: [
            uspClientProvider.overrideWithValue(mockUsp),
            uspMutationLockProvider.overrideWithValue(UspMutationLock()),
            devicesDataProvider.overrideWith(
              () => _TestDevicesDataNotifier(const DevicesData()),
            ),
            sseInvalidationProvider.overrideWith((ref) => sseController.stream),
          ],
        );

        container.listen(dhcpDataProvider, (_, __) {});
        async.flushMicrotasks();
        clearInteractions(mockUsp);

        // Emit SSE for dhcpClients (second OR-gate branch)
        sseController.add(InvalidationDomain.dhcpClients);
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 500));
        async.flushMicrotasks();

        verify(() => mockUsp.get(any())).called(greaterThanOrEqualTo(1));

        sseController.close();
        container.dispose();
      });
    });

    test('SSE unrelated domain does not trigger re-fetch', () {
      fakeAsync((async) {
        final sseController = StreamController<InvalidationDomain>.broadcast();

        final container = ProviderContainer(
          overrides: [
            uspClientProvider.overrideWithValue(mockUsp),
            uspMutationLockProvider.overrideWithValue(UspMutationLock()),
            devicesDataProvider.overrideWith(
              () => _TestDevicesDataNotifier(const DevicesData()),
            ),
            sseInvalidationProvider.overrideWith((ref) => sseController.stream),
          ],
        );

        container.listen(dhcpDataProvider, (_, __) {});
        async.flushMicrotasks();
        clearInteractions(mockUsp);

        sseController.add(InvalidationDomain.wifiSsids);
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 600));
        async.flushMicrotasks();

        verifyNever(() => mockUsp.get(any()));

        sseController.close();
        container.dispose();
      });
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
