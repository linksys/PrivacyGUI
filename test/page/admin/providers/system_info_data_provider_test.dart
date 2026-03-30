import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';

class MockUspService extends Mock implements UspService {}

void main() {
  late MockUspService mockUsp;

  /// Canned response covering SystemInfo (includes firmware refs since YAML v1.1.0).
  /// Two get() calls: SystemInfo.fetch (includes refs), FirmwareImages.fetch.
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
    'Device.DeviceInfo.BootFirmwareImage':
        'Device.DeviceInfo.FirmwareImage.1.',
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

  final firmwareRefResponse = <String, dynamic>{
    'Device.DeviceInfo.ActiveFirmwareImage':
        'Device.DeviceInfo.FirmwareImage.1.',
    'Device.DeviceInfo.BootFirmwareImage': 'Device.DeviceInfo.FirmwareImage.1.',
  };

  setUp(() {
    mockUsp = MockUspService();
    // The notifier makes 2 concurrent get() calls:
    // 1) SystemInfo.fetch → systemInfoResponse (includes firmware refs)
    // 2) FirmwareImages.fetch → firmwareImagesResponse
    when(() => mockUsp.get(any())).thenAnswer((_) async {
      final paths = _.positionalArguments[0] as List;
      if (paths.any((p) => p.toString().contains('Manufacturer'))) {
        return systemInfoResponse;
      } else if (paths.any((p) => p.toString().contains('FirmwareImage.*.'))) {
        return firmwareImagesResponse;
      }
      return <String, dynamic>{};
    });
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        uspServiceProvider.overrideWithValue(mockUsp),
      ],
    );
  }

  group('SystemInfoDataNotifier', () {
    test('build fetches system info and firmware images', () async {
      final container = createContainer();
      final data = await container.read(systemInfoDataProvider.future);

      expect(data.model.manufacturer, 'Linksys');
      expect(data.model.modelName, 'M60TB');
      expect(data.model.serialNumber, 'SN123');
      expect(data.model.softwareVersion, '1.0.16');
      expect(data.model.uptime, 86400);
      expect(data.model.totalMemory, 512000);
      expect(data.model.freeMemory, 256000);
      expect(data.model.cpuUsage, 25);
      expect(data.model.firmwareImages, hasLength(2));
      container.dispose();
    });

    test('firmware images have correct active/boot flags', () async {
      final container = createContainer();
      final data = await container.read(systemInfoDataProvider.future);

      final fws = data.model.firmwareImages;
      // FirmwareImage.1 is both active and boot target
      final active = fws.firstWhere((f) => f.name == 'fw_image_1');
      expect(active.isActive, isTrue);
      expect(active.isBootTarget, isTrue);

      // FirmwareImage.2 is neither
      final inactive = fws.firstWhere((f) => f.name == 'fw_image_2');
      expect(inactive.isActive, isFalse);
      expect(inactive.isBootTarget, isFalse);
      container.dispose();
    });

    test('build throws when usp is null', () async {
      final container = ProviderContainer(
        overrides: [
          uspServiceProvider.overrideWithValue(null),
        ],
      );

      expect(
        container.read(systemInfoDataProvider.future),
        throwsA(isA<StateError>()),
      );
      container.dispose();
    });

    test('firmware images fetch failure returns empty images', () async {
      // Override to fail on firmware fetch but succeed on system info
      when(() => mockUsp.get(any())).thenAnswer((_) async {
        final paths = _.positionalArguments[0] as List;
        if (paths.any((p) => p.toString().contains('Manufacturer'))) {
          return systemInfoResponse;
        }
        // All other calls (firmware images + refs) fail
        throw Exception('firmware fetch failed');
      });

      final container = createContainer();
      final data = await container.read(systemInfoDataProvider.future);

      // System info should still be present
      expect(data.model.modelName, 'M60TB');
      // Firmware images should be empty (graceful fallback)
      expect(data.model.firmwareImages, isEmpty);
      container.dispose();
    });

    test('SystemInfoData equality uses model props', () async {
      final container = createContainer();
      final data1 = await container.read(systemInfoDataProvider.future);
      final data2 = await container.read(systemInfoDataProvider.future);

      expect(data1, equals(data2));
      expect(data1.props, [data1.model]);
      container.dispose();
    });

    test('gatewayName falls back to Router when modelName empty', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async {
        final paths = _.positionalArguments[0] as List;
        if (paths.any((p) => p.toString().contains('Manufacturer'))) {
          return <String, dynamic>{
            ...systemInfoResponse,
            'Device.DeviceInfo.ModelName': '',
          };
        } else if (paths
            .any((p) => p.toString().contains('FirmwareImage.*.'))) {
          return firmwareImagesResponse;
        } else if (paths.any((p) => p.toString().contains('ActiveFirmware'))) {
          return firmwareRefResponse;
        }
        return <String, dynamic>{};
      });

      final container = createContainer();
      final data = await container.read(systemInfoDataProvider.future);

      expect(data.model.gatewayName, 'Router');
      container.dispose();
    });
  });
}
