import 'package:privacy_gui/page/advanced_settings/local_network_settings/models/reservation_item_ui_model.dart';

/// Test data builder for DHCPReservationsService tests
///
/// Provides factory methods to create ReservationItemUIModel test data
/// with sensible defaults and various test scenarios.
class DHCPReservationsTestData {
  /// Create default ReservationItemUIModel
  static DHCPReservationUIModel createReservationUIModel({
    String macAddress = '00:11:22:33:44:55',
    String ipAddress = '192.168.1.100',
    String description = 'Test Device',
  }) {
    return DHCPReservationUIModel(
      macAddress: macAddress,
      ipAddress: ipAddress,
      description: description,
    );
  }

  /// Create a list of test reservations
  static List<DHCPReservationUIModel> createReservationList() {
    return [
      createReservationUIModel(
        macAddress: '00:11:22:33:44:55',
        ipAddress: '192.168.1.10',
        description: 'Device 1',
      ),
      createReservationUIModel(
        macAddress: 'AA:BB:CC:DD:EE:FF',
        ipAddress: '192.168.1.20',
        description: 'Device 2',
      ),
      createReservationUIModel(
        macAddress: '11:22:33:44:55:66',
        ipAddress: '192.168.1.30',
        description: 'Device 3',
      ),
    ];
  }

  /// Create a reservation with conflicting MAC address
  static DHCPReservationUIModel createConflictingMACReservation() {
    return createReservationUIModel(
      macAddress: '00:11:22:33:44:55', // Same as first in list
      ipAddress: '192.168.1.99',
      description: 'Conflicting Device',
    );
  }

  /// Create a reservation with conflicting IP address
  static DHCPReservationUIModel createConflictingIPReservation() {
    return createReservationUIModel(
      macAddress: 'FF:EE:DD:CC:BB:AA',
      ipAddress: '192.168.1.10', // Same as first in list
      description: 'Conflicting Device',
    );
  }

  /// Create a valid new reservation (no conflicts)
  static DHCPReservationUIModel createValidNewReservation() {
    return createReservationUIModel(
      macAddress: 'AB:CD:EF:12:34:56',
      ipAddress: '192.168.1.99',
      description: 'New Valid Device',
    );
  }

  /// Create empty reservation list
  static List<DHCPReservationUIModel> createEmptyList() {
    return [];
  }

  /// Create single reservation list
  static List<DHCPReservationUIModel> createSingleReservation() {
    return [createReservationUIModel()];
  }
}
