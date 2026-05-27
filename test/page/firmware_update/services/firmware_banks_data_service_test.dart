import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_banks_data_service.dart';

class MockUspClient extends Mock implements UspClient {}

void main() {
  late MockUspClient mockUsp;
  late FirmwareBanksDataService service;

  setUp(() {
    mockUsp = MockUspClient();
    service = FirmwareBanksDataService(mockUsp);
  });

  group('FirmwareBanksDataService', () {
    test('fetch returns banks from UspClient', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            'Device.DeviceInfo.FirmwareImage.1.Name': 'linux',
            'Device.DeviceInfo.FirmwareImage.1.Version': '1.0.16.0',
            'Device.DeviceInfo.FirmwareImage.1.Status': 'Active',
            'Device.DeviceInfo.FirmwareImage.1.Available': 'true',
            'Device.DeviceInfo.FirmwareImage.2.Name': 'linux',
            'Device.DeviceInfo.FirmwareImage.2.Version': '1.0.15.0',
            'Device.DeviceInfo.FirmwareImage.2.Status': 'Available',
            'Device.DeviceInfo.FirmwareImage.2.Available': 'true',
          });

      final banks = await service.fetch();

      expect(banks.length, 2);
      expect(banks[0].version, '1.0.16.0');
      expect(banks[0].isActive, isTrue);
      expect(banks[1].version, '1.0.15.0');
      expect(banks[1].isActive, isFalse);
    });

    test('fetch parses instance number from path', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            'Device.DeviceInfo.FirmwareImage.3.Name': 'linux',
            'Device.DeviceInfo.FirmwareImage.3.Version': '1.0.16.0',
            'Device.DeviceInfo.FirmwareImage.3.Status': 'Active',
            'Device.DeviceInfo.FirmwareImage.3.Available': 'true',
          });

      final banks = await service.fetch();

      expect(banks.first.instance, 3);
    });

    test('fetch maps USP error to ServiceError', () async {
      when(() => mockUsp.get(any()))
          .thenThrow(Exception('Transport error: timeout'));

      expect(
        () => service.fetch(),
        throwsA(isA<ServiceError>()),
      );
    });

    test('fetch returns empty list when no banks', () async {
      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => <String, dynamic>{});

      final banks = await service.fetch();

      expect(banks, isEmpty);
    });
  });
}
