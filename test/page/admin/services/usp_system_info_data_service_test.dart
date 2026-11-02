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
    test('a firmware image row with every value blank is no image', () async {
      // usp-codegen 0.18 returns a row with every value blank where 0.17
      // dropped it (#1654).
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List;
        if (paths.any((p) => p.toString().contains('Manufacturer'))) {
          return systemInfoResponse;
        }
        return {
          ...firmwareImagesResponse,
          'Device.DeviceInfo.FirmwareImage.4.Name': '',
          'Device.DeviceInfo.FirmwareImage.4.Version': '',
          'Device.DeviceInfo.FirmwareImage.4.Status': '',
          'Device.DeviceInfo.FirmwareImage.4.Available': false,
        };
      });

      expect((await svc.fetch()).firmwareImages, hasLength(2));
    });

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

  group('UspSystemInfoDataService — base MAC (#1665)', () {
    void stubBaseMac(Object? value) {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async {
        final paths = _.positionalArguments[0] as List;
        if (paths.any((p) => p.toString().contains('Manufacturer'))) {
          return {
            ...systemInfoResponse,
            if (value != null)
              'Device.DeviceInfo.X_LINKSYS_BaseMACAddress': value,
          };
        }
        return firmwareImagesResponse;
      });
    }

    test('carries the router base MAC into the UI model', () async {
      stubBaseMac('74:12:13:21:55:02');

      final model = await svc.fetch();

      expect(model.baseMacAddress, '74:12:13:21:55:02');
    });

    test('upper-cases a base MAC the router reports in lower case', () async {
      stubBaseMac(' 74:12:13:21:5a:bc ');

      final model = await svc.fetch();

      expect(model.baseMacAddress, '74:12:13:21:5A:BC');
    });

    test('an empty base MAC is no base MAC', () async {
      stubBaseMac('');

      final model = await svc.fetch();

      expect(model.baseMacAddress, isNull);
    });

    test('a router that does not report the leaf yields null', () async {
      stubBaseMac(null);

      final model = await svc.fetch();

      expect(model.baseMacAddress, isNull);
    });
  });

  // The router's own name (#1691). The detail page writes only
  // X_LINKSYS_UserDeviceLocation; DeviceInfo.FriendlyName is read as a
  // fallback in case something else set it. Both read "" when unset.
  group('UspSystemInfoDataService — router name (#1691)', () {
    void stubName({Object? location, Object? friendlyName, Object? hostName}) {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async {
        final paths = _.positionalArguments[0] as List;
        if (paths.any((p) => p.toString().contains('Manufacturer'))) {
          return {
            ...systemInfoResponse,
            if (location != null)
              'Device.DeviceInfo.X_LINKSYS_UserDeviceLocation': location,
            if (friendlyName != null)
              'Device.DeviceInfo.FriendlyName': friendlyName,
            if (hostName != null) 'Device.DeviceInfo.HostName': hostName,
          };
        }
        return firmwareImagesResponse;
      });
    }

    // The fallback name when neither is set (#1751), read in the same Get.
    test('carries DeviceInfo.HostName into the UI model', () async {
      stubName(hostName: 'Linksys12345');

      final model = await svc.fetch();

      expect(model.hostName, 'Linksys12345');
    });

    test('reads HostName in the same Get as the rest of system info', () async {
      stubName(hostName: 'Linksys12345');

      await svc.fetch();

      final calls = verify(
              () => mockUsp.get(captureAny(), priority: any(named: 'priority')))
          .captured
          .cast<List>();
      final systemInfoGet = calls.singleWhere(
          (paths) => paths.any((p) => p.toString().contains('Manufacturer')));
      expect(systemInfoGet, contains('Device.DeviceInfo.HostName'));
    });

    test('no HostName, or "", is no host name and does not fail the fetch',
        () async {
      stubName();
      expect((await svc.fetch()).hostName, isNull,
          reason: 'optional: an image without the leaf reads null');

      stubName(hostName: '');
      expect((await svc.fetch()).hostName, isNull);
    });

    test('carries the location and FriendlyName into the UI model', () async {
      stubName(location: 'Office', friendlyName: 'Main router');

      final model = await svc.fetch();

      expect(model.userDeviceLocation, 'Office');
      expect(model.friendlyName, 'Main router');
    });

    test('"" is no name', () async {
      stubName(location: '', friendlyName: '');

      final model = await svc.fetch();

      expect(model.userDeviceLocation, isNull);
      expect(model.friendlyName, isNull);
    });

    test('writes the name to X_LINKSYS_UserDeviceLocation only, in one Set',
        () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {
                'success': true,
                'result': {'data': <String, dynamic>{}},
              });

      await svc.updateRouterName('Office');

      // Never FriendlyName: the detail page writes the location alone.
      verify(() => mockUsp.set(
            {'Device.DeviceInfo.X_LINKSYS_UserDeviceLocation': 'Office'},
            allowPartial: false,
          )).called(1);
    });

    test('an empty name is written, which clears it', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {
                'success': true,
                'result': {'data': <String, dynamic>{}},
              });

      await svc.updateRouterName('');

      verify(() => mockUsp.set(
            {'Device.DeviceInfo.X_LINKSYS_UserDeviceLocation': ''},
            allowPartial: false,
          )).called(1);
    });

    test('a refused Set throws UspCompleteFailureError', () {
      // What the firmware does for 65 bytes: the whole Set is refused.
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {
                'success': false,
                'result': {
                  'data': <String, dynamic>{},
                  'error': {
                    'Device.DeviceInfo.X_LINKSYS_UserDeviceLocation': {
                      'errorCode': 9007,
                      'errorMessage': 'Invalid parameter value',
                    },
                  },
                },
              });

      expect(() => svc.updateRouterName('x'),
          throwsA(isA<UspCompleteFailureError>()));
    });

    test('a transport error maps to ServiceError', () {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenThrow('Set failed: Transport error: Connection refused');

      expect(
          () => svc.updateRouterName('x'), throwsA(isA<ConnectivityError>()));
    });
  });
}
