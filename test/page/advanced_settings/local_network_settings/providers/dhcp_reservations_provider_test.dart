import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/dhcp_reservations_provider.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/dhcp_reservations_state.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/services/dhcp_reservations_service.dart';

class MockDHCPReservationsService extends Mock
    implements DHCPReservationsService {}

class MockRef extends Mock implements Ref {}

void main() {
  late ProviderContainer container;
  late MockDHCPReservationsService mockService;

  setUpAll(() {
    registerFallbackValue(MockRef());
    registerFallbackValue(<DHCPReservationUIModel>[]);
  });

  setUp(() {
    mockService = MockDHCPReservationsService();
    container = ProviderContainer(
      overrides: [
        dhcpReservationsServiceProvider.overrideWithValue(mockService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('DHCPReservationsNotifier', () {
    group('build', () {
      test('returns initial state', () {
        final state = container.read(dhcpReservationProvider);

        expect(state.settings.current.reservations, isEmpty);
        expect(state.status.devices, isEmpty);
        expect(state.status.additionalReservations, isEmpty);
      });
    });

    group('setInitialReservations', () {
      test('sets reservations with reserved flag true', () {
        final notifier = container.read(dhcpReservationProvider.notifier);
        const model = DHCPReservationUIModel(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          ipAddress: '192.168.1.100',
          description: 'Device1',
        );

        notifier.setInitialReservations([model]);
        final state = container.read(dhcpReservationProvider);

        expect(state.settings.original.reservations, hasLength(1));
        expect(state.settings.current.reservations, hasLength(1));
        expect(state.settings.current.reservations.first.reserved, true);
        expect(state.settings.current.reservations.first.data, model);
      });

      test('sets multiple reservations', () {
        final notifier = container.read(dhcpReservationProvider.notifier);
        const model1 = DHCPReservationUIModel(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          ipAddress: '192.168.1.100',
          description: 'Device1',
        );
        const model2 = DHCPReservationUIModel(
          macAddress: '11:22:33:44:55:66',
          ipAddress: '192.168.1.101',
          description: 'Device2',
        );

        notifier.setInitialReservations([model1, model2]);
        final state = container.read(dhcpReservationProvider);

        expect(state.settings.current.reservations, hasLength(2));
      });
    });

    group('updateSettings', () {
      test('updates current settings', () {
        final notifier = container.read(dhcpReservationProvider.notifier);
        const item = ReservedListItem(
          reserved: true,
          data: DHCPReservationUIModel(
            macAddress: 'AA:BB:CC:DD:EE:FF',
            ipAddress: '192.168.1.100',
            description: 'Test',
          ),
        );
        const newSettings = DHCPReservationsSettings(reservations: [item]);

        notifier.updateSettings(newSettings);
        final state = container.read(dhcpReservationProvider);

        expect(state.settings.current.reservations, hasLength(1));
      });
    });

    group('updateDevices', () {
      test('updates status devices', () {
        final notifier = container.read(dhcpReservationProvider.notifier);

        notifier.updateDevices([]);
        final state = container.read(dhcpReservationProvider);

        expect(state.status.devices, isEmpty);
        expect(state.status.additionalReservations, isEmpty);
      });
    });

    group('isConflict', () {
      test('returns true when MAC address conflicts', () {
        final notifier = container.read(dhcpReservationProvider.notifier);
        notifier.setInitialReservations([
          const DHCPReservationUIModel(
            macAddress: 'AA:BB:CC:DD:EE:FF',
            ipAddress: '192.168.1.100',
            description: 'Existing',
          ),
        ]);

        const conflictItem = ReservedListItem(
          reserved: true,
          data: DHCPReservationUIModel(
            macAddress: 'AA:BB:CC:DD:EE:FF',
            ipAddress: '192.168.1.200',
            description: 'New',
          ),
        );

        expect(notifier.isConflict(conflictItem), true);
      });

      test('returns true when IP address conflicts', () {
        final notifier = container.read(dhcpReservationProvider.notifier);
        notifier.setInitialReservations([
          const DHCPReservationUIModel(
            macAddress: 'AA:BB:CC:DD:EE:FF',
            ipAddress: '192.168.1.100',
            description: 'Existing',
          ),
        ]);

        const conflictItem = ReservedListItem(
          reserved: true,
          data: DHCPReservationUIModel(
            macAddress: '11:22:33:44:55:66',
            ipAddress: '192.168.1.100',
            description: 'New',
          ),
        );

        expect(notifier.isConflict(conflictItem), true);
      });

      test('returns false when no conflict', () {
        final notifier = container.read(dhcpReservationProvider.notifier);
        notifier.setInitialReservations([
          const DHCPReservationUIModel(
            macAddress: 'AA:BB:CC:DD:EE:FF',
            ipAddress: '192.168.1.100',
            description: 'Existing',
          ),
        ]);

        const noConflictItem = ReservedListItem(
          reserved: true,
          data: DHCPReservationUIModel(
            macAddress: '11:22:33:44:55:66',
            ipAddress: '192.168.1.200',
            description: 'New',
          ),
        );

        expect(notifier.isConflict(noConflictItem), false);
      });

      test('ignores unreserved items when checking conflict', () {
        final notifier = container.read(dhcpReservationProvider.notifier);
        const unreservedItem = ReservedListItem(
          reserved: false,
          data: DHCPReservationUIModel(
            macAddress: 'AA:BB:CC:DD:EE:FF',
            ipAddress: '192.168.1.100',
            description: 'Existing',
          ),
        );
        notifier.updateSettings(
            const DHCPReservationsSettings(reservations: [unreservedItem]));

        const checkItem = ReservedListItem(
          reserved: true,
          data: DHCPReservationUIModel(
            macAddress: 'AA:BB:CC:DD:EE:FF',
            ipAddress: '192.168.1.200',
            description: 'New',
          ),
        );

        expect(notifier.isConflict(checkItem), false);
      });
    });

    group('updateReservationItem', () {
      test('updates existing reservation item', () {
        final notifier = container.read(dhcpReservationProvider.notifier);
        const item = ReservedListItem(
          reserved: true,
          data: DHCPReservationUIModel(
            macAddress: 'AA:BB:CC:DD:EE:FF',
            ipAddress: '192.168.1.100',
            description: 'Original',
          ),
        );
        notifier.updateSettings(
            const DHCPReservationsSettings(reservations: [item]));

        notifier.updateReservationItem(item, 'Updated', '192.168.1.101', null);
        final state = container.read(dhcpReservationProvider);

        expect(state.settings.current.reservations.first.data.description,
            'Updated');
        expect(state.settings.current.reservations.first.data.ipAddress,
            '192.168.1.101');
        expect(state.settings.current.reservations.first.data.macAddress,
            'AA:BB:CC:DD:EE:FF');
      });

      test('does nothing when item not found', () {
        final notifier = container.read(dhcpReservationProvider.notifier);
        const item = ReservedListItem(
          reserved: true,
          data: DHCPReservationUIModel(
            macAddress: 'AA:BB:CC:DD:EE:FF',
            ipAddress: '192.168.1.100',
            description: 'Original',
          ),
        );
        notifier.updateSettings(
            const DHCPReservationsSettings(reservations: [item]));

        const nonExistentItem = ReservedListItem(
          reserved: true,
          data: DHCPReservationUIModel(
            macAddress: '11:22:33:44:55:66',
            ipAddress: '192.168.1.200',
            description: 'NonExistent',
          ),
        );
        notifier.updateReservationItem(
            nonExistentItem, 'Updated', '192.168.1.101', null);
        final state = container.read(dhcpReservationProvider);

        expect(state.settings.current.reservations, hasLength(1));
        expect(state.settings.current.reservations.first.data.description,
            'Original');
      });
    });

    group('updateReservations', () {
      test('adds new item to reservations', () {
        final notifier = container.read(dhcpReservationProvider.notifier);

        const newItem = ReservedListItem(
          reserved: true,
          data: DHCPReservationUIModel(
            macAddress: 'AA:BB:CC:DD:EE:FF',
            ipAddress: '192.168.1.100',
            description: 'New Device',
          ),
        );

        notifier.updateReservations(newItem);
        final state = container.read(dhcpReservationProvider);

        expect(state.settings.current.reservations, hasLength(1));
      });
    });

    group('preservable functionality', () {
      test('preservable contract accessor returns notifier', () {
        final preservable = container.read(preservableDHCPReservationsProvider)
            as DHCPReservationsNotifier;

        expect(preservable, isNotNull);
        expect(preservable, isA<DHCPReservationsNotifier>());
      });

      test('preservable stores original values for reset', () {
        final notifier = container.read(dhcpReservationProvider.notifier);
        notifier.setInitialReservations([
          const DHCPReservationUIModel(
            macAddress: 'AA:BB:CC:DD:EE:FF',
            ipAddress: '192.168.1.100',
            description: 'Device1',
          ),
        ]);

        const newItem = ReservedListItem(
          reserved: true,
          data: DHCPReservationUIModel(
            macAddress: '11:22:33:44:55:66',
            ipAddress: '192.168.1.101',
            description: 'Device2',
          ),
        );
        notifier
            .updateSettings(DHCPReservationsSettings(reservations: const [newItem]));
        final state = container.read(dhcpReservationProvider);

        expect(state.settings.current.reservations, hasLength(1));
        expect(state.settings.original.reservations, hasLength(1));
        expect(state.settings.current.reservations.first.data.macAddress,
            '11:22:33:44:55:66');
        expect(state.settings.original.reservations.first.data.macAddress,
            'AA:BB:CC:DD:EE:FF');
      });
    });

    group('isDirty tracking', () {
      test('isDirty is true when current differs from original', () {
        final notifier = container.read(dhcpReservationProvider.notifier);
        notifier.setInitialReservations([
          const DHCPReservationUIModel(
            macAddress: 'AA:BB:CC:DD:EE:FF',
            ipAddress: '192.168.1.100',
            description: 'Device1',
          ),
        ]);

        notifier
            .updateSettings(const DHCPReservationsSettings(reservations: []));
        final state = container.read(dhcpReservationProvider);

        expect(state.isDirty, true);
      });

      test('isDirty is false when current equals original', () {
        final state = container.read(dhcpReservationProvider);

        expect(state.isDirty, false);
      });
    });

    group('performFetch', () {
      test('returns current settings and null status', () async {
        final notifier = container.read(dhcpReservationProvider.notifier);

        final result = await notifier.performFetch();

        expect(result.$1, isNotNull);
        expect(result.$2, isNull);
      });
    });

    group('performSave', () {
      test('calls service with reserved items only', () async {
        final notifier = container.read(dhcpReservationProvider.notifier);
        const reservedItem = ReservedListItem(
          reserved: true,
          data: DHCPReservationUIModel(
            macAddress: 'AA:BB:CC:DD:EE:FF',
            ipAddress: '192.168.1.100',
            description: 'Reserved',
          ),
        );
        const unreservedItem = ReservedListItem(
          reserved: false,
          data: DHCPReservationUIModel(
            macAddress: '11:22:33:44:55:66',
            ipAddress: '192.168.1.101',
            description: 'Unreserved',
          ),
        );
        notifier.updateSettings(const DHCPReservationsSettings(
            reservations: [reservedItem, unreservedItem]));

        when(() => mockService.saveReservations(any(), any()))
            .thenAnswer((_) async {});

        await notifier.performSave();

        verify(() => mockService.saveReservations(
              any(),
              any(
                  that: isA<List<DHCPReservationUIModel>>()
                      .having((list) => list.length, 'length', 1)),
            )).called(1);
      });
    });
  });
}
