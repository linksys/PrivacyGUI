import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/dhcp_reservations_state.dart';
import 'package:privacy_gui/providers/preservable.dart';

void main() {
  group('DHCPReservationsSettings', () {
    test('creates instance with default empty reservations', () {
      const settings = DHCPReservationsSettings();
      expect(settings.reservations, isEmpty);
    });

    test('creates instance with reservations', () {
      const item = ReservedListItem(
        reserved: true,
        data: DHCPReservationUIModel(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          ipAddress: '192.168.1.100',
          description: 'Test',
        ),
      );
      const settings = DHCPReservationsSettings(reservations: [item]);
      expect(settings.reservations, hasLength(1));
    });

    test('copyWith updates reservations', () {
      const settings = DHCPReservationsSettings();
      const item = ReservedListItem(
        reserved: true,
        data: DHCPReservationUIModel(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          ipAddress: '192.168.1.100',
          description: 'Test',
        ),
      );
      final updated = settings.copyWith(reservations: [item]);
      expect(updated.reservations, hasLength(1));
    });

    test('toMap/fromMap serialization works', () {
      const item = ReservedListItem(
        reserved: true,
        data: DHCPReservationUIModel(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          ipAddress: '192.168.1.100',
          description: 'Test',
        ),
      );
      const original = DHCPReservationsSettings(reservations: [item]);
      final map = original.toMap();
      final restored = DHCPReservationsSettings.fromMap(map);
      expect(restored.reservations, hasLength(1));
      expect(restored.reservations.first.data.macAddress, 'AA:BB:CC:DD:EE:FF');
    });

    test('toJson/fromJson serialization works', () {
      const settings = DHCPReservationsSettings();
      final json = settings.toJson();
      final restored = DHCPReservationsSettings.fromJson(json);
      expect(restored, settings);
    });
  });

  group('DHCPReservationsStatus', () {
    test('creates instance with defaults', () {
      const status = DHCPReservationsStatus();
      expect(status.additionalReservations, isEmpty);
      expect(status.devices, isEmpty);
    });

    test('copyWith updates specified fields', () {
      const status = DHCPReservationsStatus();
      const item = ReservedListItem(
        reserved: false,
        data: DHCPReservationUIModel(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          ipAddress: '192.168.1.100',
          description: 'Device',
        ),
      );
      final updated = status.copyWith(devices: [item]);
      expect(updated.devices, hasLength(1));
    });

    test('toMap/fromMap serialization works', () {
      const status = DHCPReservationsStatus();
      final map = status.toMap();
      final restored = DHCPReservationsStatus.fromMap(map);
      expect(restored, status);
    });
  });

  group('DHCPReservationState', () {
    test('creates initial state', () {
      final state = DHCPReservationState.init();
      expect(state.settings.original.reservations, isEmpty);
      expect(state.status.devices, isEmpty);
    });

    test('copyWith updates specified fields', () {
      final state = DHCPReservationState.init();
      const newStatus = DHCPReservationsStatus(devices: []);
      final updated = state.copyWith(status: newStatus);
      expect(updated.status, newStatus);
    });

    test('toMap/fromMap serialization works', () {
      final original = DHCPReservationState.init();
      final map = original.toMap();
      final restored = DHCPReservationState.fromMap(map);
      expect(restored.settings.original.reservations, isEmpty);
    });

    test('toJson/fromJson serialization works', () {
      final original = DHCPReservationState.init();
      final json = original.toJson();
      final restored = DHCPReservationState.fromJson(json);
      expect(restored.settings.original.reservations, isEmpty);
    });
  });

  group('ReservedListItem', () {
    test('creates instance with required fields', () {
      const item = ReservedListItem(
        reserved: true,
        data: DHCPReservationUIModel(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          ipAddress: '192.168.1.100',
          description: 'Test',
        ),
      );
      expect(item.reserved, true);
      expect(item.data.macAddress, 'AA:BB:CC:DD:EE:FF');
    });

    test('copyWith updates fields', () {
      const item = ReservedListItem(
        reserved: true,
        data: DHCPReservationUIModel(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          ipAddress: '192.168.1.100',
          description: 'Test',
        ),
      );
      final updated = item.copyWith(reserved: false);
      expect(updated.reserved, false);
      expect(updated.data, item.data);
    });

    test('toMap/fromMap serialization works', () {
      const original = ReservedListItem(
        reserved: true,
        data: DHCPReservationUIModel(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          ipAddress: '192.168.1.100',
          description: 'Test',
        ),
      );
      final map = original.toMap();
      final restored = ReservedListItem.fromMap(map);
      expect(restored, original);
    });

    test('toJson/fromJson serialization works', () {
      const original = ReservedListItem(
        reserved: true,
        data: DHCPReservationUIModel(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          ipAddress: '192.168.1.100',
          description: 'Test',
        ),
      );
      final json = original.toJson();
      final restored = ReservedListItem.fromJson(json);
      expect(restored, original);
    });

    test('equality comparison works', () {
      const item1 = ReservedListItem(
        reserved: true,
        data: DHCPReservationUIModel(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          ipAddress: '192.168.1.100',
          description: 'Test',
        ),
      );
      const item2 = ReservedListItem(
        reserved: true,
        data: DHCPReservationUIModel(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          ipAddress: '192.168.1.100',
          description: 'Test',
        ),
      );
      expect(item1, item2);
    });
  });
}
