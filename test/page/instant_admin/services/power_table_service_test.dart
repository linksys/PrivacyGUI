import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_admin/providers/power_table_provider.dart';
import 'package:privacy_gui/page/instant_admin/services/power_table_service.dart';

import '../../../mocks/test_data/instant_admin_test_data.dart';

class MockRouterRepository extends Mock implements RouterRepository {}

void main() {
  late PowerTableService service;
  late MockRouterRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(JNAPAction.setPowerTableSettings);
  });

  setUp(() {
    mockRepository = MockRouterRepository();
    service = PowerTableService(mockRepository);
  });

  group('PowerTableService - parsePowerTableSettings', () {
    test('returns PowerTableState on success', () {
      // Arrange
      final pollingData = InstantAdminTestData.createPollingDataWithPowerTable(
        isPowerTableSelectable: true,
        supportedCountries: ['USA', 'CAN', 'JPN'],
        country: 'USA',
      );

      // Act
      final result = service.parsePowerTableSettings(pollingData);

      // Assert
      expect(result, isNotNull);
      expect(result!.isPowerTableSelectable, true);
      expect(result.supportedCountries, isNotEmpty);
      expect(result.country, PowerTableCountries.usa);
    });

    test('returns null when data is missing', () {
      // Arrange
      final pollingData = InstantAdminTestData.emptyPollingData;

      // Act
      final result = service.parsePowerTableSettings(pollingData);

      // Assert
      expect(result, isNull);
    });

    test('resolves country codes correctly', () {
      // Arrange
      final pollingData = InstantAdminTestData.createPollingDataWithPowerTable(
        supportedCountries: ['TWN', 'JPN', 'USA'],
        country: 'TWN',
      );

      // Act
      final result = service.parsePowerTableSettings(pollingData);

      // Assert
      expect(result, isNotNull);
      expect(result!.country, PowerTableCountries.twn);
      expect(
        result.supportedCountries,
        containsAll([
          PowerTableCountries.twn,
          PowerTableCountries.jpn,
          PowerTableCountries.usa,
        ]),
      );
    });

    test('sorts countries by enum index', () {
      // Arrange - Provide countries in non-enum-order
      final pollingData = InstantAdminTestData.createPollingDataWithPowerTable(
        supportedCountries: InstantAdminTestData.unsortedCountries,
      );

      // Act
      final result = service.parsePowerTableSettings(pollingData);

      // Assert
      final indices = result!.supportedCountries.map((c) => c.index).toList();
      expect(indices, isSortedList);
    });

    test('handles non-selectable state', () {
      // Arrange
      final pollingData = InstantAdminTestData.createPollingDataWithPowerTable(
        isPowerTableSelectable: false,
        supportedCountries: [],
      );

      // Act
      final result = service.parsePowerTableSettings(pollingData);

      // Assert
      expect(result, isNotNull);
      expect(result!.isPowerTableSelectable, false);
      expect(result.supportedCountries, isEmpty);
    });
  });

  group('PowerTableService - savePowerTableCountry', () {
    test('saves country successfully', () async {
      // Arrange
      when(() => mockRepository.send(
                JNAPAction.setPowerTableSettings,
                data: any(named: 'data'),
                auth: true,
              ))
          .thenAnswer((_) async =>
              InstantAdminTestData.createSetPowerTableSettingsSuccess());

      // Act
      await service.savePowerTableCountry(PowerTableCountries.twn);

      // Assert
      verify(() => mockRepository.send(
            JNAPAction.setPowerTableSettings,
            data: {'country': 'TWN'},
            auth: true,
          )).called(1);
    });

    test('throws ServiceError on JNAP failure', () async {
      // Arrange
      when(() => mockRepository.send(
            JNAPAction.setPowerTableSettings,
            data: any(named: 'data'),
            auth: true,
          )).thenThrow(InstantAdminTestData.createSetPowerTableSettingsError());

      // Act & Assert
      expect(
        () => service.savePowerTableCountry(PowerTableCountries.usa),
        throwsA(isA<ServiceError>()),
      );
    });
  });
}

/// Custom matcher for checking if a list is sorted in ascending order
const Matcher isSortedList = _IsSortedList();

class _IsSortedList extends Matcher {
  const _IsSortedList();

  @override
  bool matches(Object? item, Map matchState) {
    if (item is! List<int>) return false;
    for (int i = 0; i < item.length - 1; i++) {
      if (item[i] > item[i + 1]) return false;
    }
    return true;
  }

  @override
  Description describe(Description description) =>
      description.add('is a sorted list in ascending order');
}
