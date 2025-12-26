import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/services/dhcp_reservations_service.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/services/local_network_settings_service.dart';

import '../../../../mocks/test_data/dhcp_reservations_test_data.dart';
import '../../../../mocks/router_repository_mocks.dart';

void main() {
  group('DHCPReservationsService -', () {
    late DHCPReservationsService service;
    late LocalNetworkSettingsService localNetworkService;
    late MockRouterRepository mockRepository;

    setUp(() {
      mockRepository = MockRouterRepository();
      localNetworkService = LocalNetworkSettingsService(mockRepository);
      service = DHCPReservationsService(localNetworkService);
    });

    group('isConflict -', () {
      test('returns true when MAC address conflicts', () {
        final existingList = DHCPReservationsTestData.createReservationList();
        final conflictingItem =
            DHCPReservationsTestData.createConflictingMACReservation();

        final result = service.isConflict(conflictingItem, existingList);

        expect(result, isTrue);
      });

      test('returns true when IP address conflicts', () {
        final existingList = DHCPReservationsTestData.createReservationList();
        final conflictingItem =
            DHCPReservationsTestData.createConflictingIPReservation();

        final result = service.isConflict(conflictingItem, existingList);

        expect(result, isTrue);
      });

      test('returns false when no conflicts exist', () {
        final existingList = DHCPReservationsTestData.createReservationList();
        final validItem = DHCPReservationsTestData.createValidNewReservation();

        final result = service.isConflict(validItem, existingList);

        expect(result, isFalse);
      });

      test('excludes item at indexToExclude from conflict check', () {
        final existingList = DHCPReservationsTestData.createReservationList();
        final itemToEdit = existingList[0];

        // Same item should not conflict with itself
        final result =
            service.isConflict(itemToEdit, existingList, indexToExclude: 0);

        expect(result, isFalse);
      });

      test(
          'detects conflict even with indexToExclude if different item matches',
          () {
        final existingList = DHCPReservationsTestData.createReservationList();
        final conflictingItem =
            DHCPReservationsTestData.createReservationUIModel(
          macAddress: existingList[1].macAddress, // Matches second item
          ipAddress: '192.168.1.99',
          description: 'Edited Device',
        );

        // Exclude first item, but should still conflict with second
        final result = service.isConflict(conflictingItem, existingList,
            indexToExclude: 0);

        expect(result, isTrue);
      });

      test('returns false for empty existing list', () {
        final item = DHCPReservationsTestData.createReservationUIModel();

        final result = service.isConflict(item, []);

        expect(result, isFalse);
      });
    });
  });
}
