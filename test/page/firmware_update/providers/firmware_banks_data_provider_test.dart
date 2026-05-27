import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_banks_data_service.dart';

import '../../../mocks/test_data/firmware_update_test_data.dart';

class MockFirmwareBanksDataService extends Mock
    implements FirmwareBanksDataService {}

void main() {
  late MockFirmwareBanksDataService mockService;

  setUp(() {
    mockService = MockFirmwareBanksDataService();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        firmwareBanksDataServiceProvider.overrideWithValue(mockService),
      ],
    );
  }

  group('FirmwareBanksData', () {
    test('activeBank returns bank with Active status', () {
      final data = FirmwareBanksData(banks: [
        FirmwareUpdateTestData.bankWithStatus(instance: 1, status: 'Available'),
        FirmwareUpdateTestData.bankWithStatus(instance: 2, status: 'Active'),
      ]);

      expect(data.activeBank?.instance, 2);
      expect(data.activeBank?.isActive, isTrue);
    });

    test('activeBank returns null when no active bank', () {
      final data = FirmwareBanksData(banks: [
        FirmwareUpdateTestData.bankWithStatus(instance: 1, status: 'Available'),
        FirmwareUpdateTestData.bankWithStatus(instance: 2, status: 'Available'),
      ]);

      expect(data.activeBank, isNull);
    });

    test('availableBank returns available non-active bank', () {
      final data = FirmwareBanksData(banks: [
        FirmwareUpdateTestData.bankWithStatus(instance: 1, status: 'Active'),
        FirmwareUpdateTestData.bankWithStatus(
          instance: 2,
          status: 'Available',
          available: true,
        ),
      ]);

      expect(data.availableBank?.instance, 2);
      expect(data.availableBank?.isActive, isFalse);
    });

    test('availableBank returns null when no available bank', () {
      final data = FirmwareBanksData(banks: [
        FirmwareUpdateTestData.bankWithStatus(instance: 1, status: 'Active'),
        FirmwareUpdateTestData.bankWithStatus(
          instance: 2,
          status: 'Available',
          available: false,
        ),
      ]);

      expect(data.availableBank, isNull);
    });

    test('props includes banks for equality', () {
      final banks = [
        FirmwareUpdateTestData.bankWithStatus(instance: 1, status: 'Active'),
      ];
      final data1 = FirmwareBanksData(banks: banks);
      final data2 = FirmwareBanksData(banks: banks);

      expect(data1, equals(data2));
    });

    test('empty banks returns null for activeBank and availableBank', () {
      const data = FirmwareBanksData(banks: []);

      expect(data.activeBank, isNull);
      expect(data.availableBank, isNull);
    });
  });

  group('FirmwareBanksDataNotifier', () {
    test('build fetches banks from service', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [
            FirmwareImageUIModel(
              instance: 1,
              instancePath: 'Device.DeviceInfo.FirmwareImage.1.',
              name: 'linux',
              version: '1.0.16.0',
              status: 'Active',
              available: true,
            ),
            FirmwareImageUIModel(
              instance: 2,
              instancePath: 'Device.DeviceInfo.FirmwareImage.2.',
              name: 'linux',
              version: '1.0.15.0',
              status: 'Available',
              available: true,
            ),
          ]);

      final container = createContainer();
      addTearDown(container.dispose);

      final data = await container.read(firmwareBanksDataProvider.future);

      expect(data.banks.length, 2);
      expect(data.activeBank?.version, '1.0.16.0');
      expect(data.availableBank?.version, '1.0.15.0');
      verify(() => mockService.fetch()).called(1);
    });

    test('refresh returns fresh data', () async {
      var callCount = 0;
      when(() => mockService.fetch()).thenAnswer((_) async {
        callCount++;
        return [
          FirmwareImageUIModel(
            instance: 1,
            instancePath: 'Device.DeviceInfo.FirmwareImage.1.',
            name: 'linux',
            version: callCount == 1 ? '1.0.16.0' : '1.0.17.0',
            status: 'Active',
            available: true,
          ),
        ];
      });

      final container = createContainer();
      addTearDown(container.dispose);

      // Initial fetch
      final data1 = await container.read(firmwareBanksDataProvider.future);
      expect(data1.activeBank?.version, '1.0.16.0');

      // Refresh
      final data2 =
          await container.read(firmwareBanksDataProvider.notifier).refresh();
      expect(data2.activeBank?.version, '1.0.17.0');
      verify(() => mockService.fetch()).called(2);
    });

    test('propagates service errors', () async {
      when(() => mockService.fetch()).thenThrow(Exception('Network error'));

      final container = createContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(firmwareBanksDataProvider.future),
        throwsA(isA<Exception>()),
      );
    });
  });
}
