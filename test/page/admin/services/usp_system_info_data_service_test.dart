import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/admin/services/usp_system_info_data_service.dart';

class MockUspClient extends Mock implements UspClient {}

void main() {
  late MockUspClient mockUsp;
  late UspSystemInfoDataService svc;

  final systemInfoResponse = <String, dynamic>{
    'Device.DeviceInfo.Manufacturer': 'Linksys',
    'Device.DeviceInfo.ModelName': 'M60TB',
    'Device.DeviceInfo.SerialNumber': 'SN123',
    'Device.DeviceInfo.HardwareVersion': '1.0',
    'Device.DeviceInfo.SoftwareVersion': '1.0.16',
    'Device.DeviceInfo.UpTime': '86400',
    'Device.DeviceInfo.MemoryStatus.Total': '512000',
    'Device.DeviceInfo.MemoryStatus.Free': '256000',
    'Device.DeviceInfo.ProcessStatus.CPUUsage': '25',
    'Device.DeviceInfo.ActiveFirmwareImage':
        'Device.DeviceInfo.FirmwareImage.1.',
    'Device.DeviceInfo.BootFirmwareImage': 'Device.DeviceInfo.FirmwareImage.1.',
  };

  final firmwareImagesResponse = <String, dynamic>{
    'Device.DeviceInfo.FirmwareImage.1.Name': 'fw_image_1',
    'Device.DeviceInfo.FirmwareImage.1.Version': '1.0.16',
    'Device.DeviceInfo.FirmwareImage.1.Status': 'Active',
    'Device.DeviceInfo.FirmwareImage.1.Available': true,
    'Device.DeviceInfo.FirmwareImage.2.Name': 'fw_image_2',
    'Device.DeviceInfo.FirmwareImage.2.Version': '1.0.14',
    'Device.DeviceInfo.FirmwareImage.2.Status': 'Inactive',
    'Device.DeviceInfo.FirmwareImage.2.Available': true,
  };

  void stubAllFetches() {
    when(() => mockUsp.get(any(), priority: any(named: 'priority')))
        .thenAnswer((_) async {
      final paths = _.positionalArguments[0] as List;
      if (paths.any((p) => p.toString().contains('Manufacturer'))) {
        return systemInfoResponse;
      } else if (paths.any((p) => p.toString().contains('FirmwareImage.*.'))) {
        return firmwareImagesResponse;
      }
      return <String, dynamic>{};
    });
  }

  setUp(() {
    mockUsp = MockUspClient();
    svc = UspSystemInfoDataService(mockUsp);
  });

  group('UspSystemInfoDataService — fetch', () {
    test('maps all system info fields', () async {
      stubAllFetches();

      final model = await svc.fetch();

      expect(model.manufacturer, 'Linksys');
      expect(model.modelName, 'M60TB');
      expect(model.serialNumber, 'SN123');
      expect(model.hardwareVersion, '1.0');
      expect(model.softwareVersion, '1.0.16');
      expect(model.uptime, 86400);
      expect(model.totalMemory, 512000);
      expect(model.freeMemory, 256000);
      expect(model.cpuUsage, 25);
    });

    test('firmware images have correct active/boot flags', () async {
      stubAllFetches();

      final model = await svc.fetch();

      expect(model.firmwareImages, hasLength(2));
      final active =
          model.firmwareImages.firstWhere((f) => f.name == 'fw_image_1');
      expect(active.isActive, isTrue);
      expect(active.isBootTarget, isTrue);

      final inactive =
          model.firmwareImages.firstWhere((f) => f.name == 'fw_image_2');
      expect(inactive.isActive, isFalse);
      expect(inactive.isBootTarget, isFalse);
    });

    test('firmware images fetch failure returns empty images', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async {
        final paths = _.positionalArguments[0] as List;
        if (paths.any((p) => p.toString().contains('Manufacturer'))) {
          return systemInfoResponse;
        }
        throw Exception('firmware fetch failed');
      });

      final model = await svc.fetch();

      expect(model.modelName, 'M60TB');
      expect(model.firmwareImages, isEmpty);
    });

    test('strips trailing dot for active/boot ref comparison', () async {
      // activeRef has trailing dot, instancePath also has trailing dot — should match
      stubAllFetches();

      final model = await svc.fetch();
      final fw1 = model.firmwareImages.first;
      expect(fw1.isActive, isTrue);
    });

    test('maps USP error to ServiceError', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenThrow('Get failed: Transport error: Request timeout');

      expect(() => svc.fetch(), throwsA(isA<NetworkError>()));
    });
  });
}
