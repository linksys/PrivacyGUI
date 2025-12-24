import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/page/instant_admin/providers/power_table_provider.dart';
import 'package:privacy_gui/page/instant_admin/providers/power_table_state.dart';
import 'package:privacy_gui/page/instant_admin/services/power_table_service.dart';

class MockPowerTableService extends Mock implements PowerTableService {}

void main() {
  late MockPowerTableService mockService;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(PowerTableCountries.usa);
  });

  setUp(() {
    mockService = MockPowerTableService();
  });

  tearDown(() {
    container.dispose();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        powerTableServiceProvider.overrideWithValue(mockService),
      ],
    );
  }

  group('PowerTableNotifier - build()', () {
    test('returns default state when parsePowerTableSettings returns null', () {
      // Arrange
      when(() => mockService.parsePowerTableSettings(any())).thenReturn(null);
      container = createContainer();

      // Act
      final state = container.read(powerTableProvider);

      // Assert
      expect(state.isPowerTableSelectable, false);
      expect(state.supportedCountries, isEmpty);
      expect(state.country, isNull);
    });

    test('returns parsed state when parsePowerTableSettings returns data', () {
      // Arrange
      const expectedState = PowerTableState(
        isPowerTableSelectable: true,
        supportedCountries: [
          PowerTableCountries.usa,
          PowerTableCountries.twn,
        ],
        country: PowerTableCountries.usa,
      );
      when(() => mockService.parsePowerTableSettings(any()))
          .thenReturn(expectedState);
      container = createContainer();

      // Act
      final state = container.read(powerTableProvider);

      // Assert
      expect(state.isPowerTableSelectable, true);
      expect(state.supportedCountries.length, 2);
      expect(state.country, PowerTableCountries.usa);
    });

    test('returns state with isPowerTableSelectable false when not selectable',
        () {
      // Arrange
      when(() => mockService.parsePowerTableSettings(any())).thenReturn(
        const PowerTableState(
          isPowerTableSelectable: false,
          supportedCountries: [],
        ),
      );
      container = createContainer();

      // Act
      final state = container.read(powerTableProvider);

      // Assert
      expect(state.isPowerTableSelectable, false);
      expect(state.supportedCountries, isEmpty);
    });
  });

  // Note: PowerTableNotifier.save() tests require mocking PollingNotifier,
  // which is an AsyncNotifier and complex to mock properly. The service
  // delegation is tested in power_table_service_test.dart.
  // Integration tests should cover the full save flow.

  group('PowerTableCountries', () {
    test('resolve converts uppercase country codes correctly', () {
      expect(PowerTableCountries.resolve('USA'), PowerTableCountries.usa);
      expect(PowerTableCountries.resolve('TWN'), PowerTableCountries.twn);
      expect(PowerTableCountries.resolve('JPN'), PowerTableCountries.jpn);
      expect(PowerTableCountries.resolve('KOR'), PowerTableCountries.kor);
    });

    test('resolve returns USA for unknown country codes', () {
      expect(PowerTableCountries.resolve('UNKNOWN'), PowerTableCountries.usa);
      expect(PowerTableCountries.resolve('XYZ'), PowerTableCountries.usa);
      expect(PowerTableCountries.resolve(''), PowerTableCountries.usa);
    });

    test('compareTo compares by enum index', () {
      // chn has index 0, usa has index 24 (last)
      expect(PowerTableCountries.chn.compareTo(PowerTableCountries.usa),
          lessThan(0));
      expect(PowerTableCountries.usa.compareTo(PowerTableCountries.chn),
          greaterThan(0));
      expect(PowerTableCountries.usa.compareTo(PowerTableCountries.usa),
          equals(0));
    });
  });
}
