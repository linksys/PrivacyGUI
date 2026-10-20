import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/services/usp_pdf_service.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';

import '../../../mocks/test_data/devices_test_data.dart';
import '../../../mocks/test_data/firmware_update_test_data.dart';

class MockUspClient extends Mock implements UspClient {}

/// First tests for [UspPdfService]. The subject is the firmware-image list on
/// page 1 of the support report: it prints one row per
/// `SystemInfoUIModel.firmwareImages` entry unconditionally, so a virtual `ota`
/// instance reaching that model would be printed as a third firmware image with
/// the upgradeable version in the version column.
void main() {
  final systemInfoResponse = <String, dynamic>{
    'Device.DeviceInfo.Manufacturer': 'Linksys',
    'Device.DeviceInfo.ModelName': 'M60TB',
    'Device.DeviceInfo.SerialNumber': 'SN123',
    'Device.DeviceInfo.HardwareVersion': '1.0',
    'Device.DeviceInfo.SoftwareVersion': '2.0.1.26091007',
    'Device.DeviceInfo.UpTime': '86400',
    'Device.DeviceInfo.MemoryStatus.Total': '512000',
    'Device.DeviceInfo.MemoryStatus.Free': '256000',
    'Device.DeviceInfo.ProcessStatus.CPUUsage': '25',
    'Device.DeviceInfo.ActiveFirmwareImage':
        'Device.DeviceInfo.FirmwareImage.1.',
    'Device.DeviceInfo.BootFirmwareImage': 'Device.DeviceInfo.FirmwareImage.1.',
  };

  group('firmwareImageRows', () {
    test('prints one row per image, labelled by name', () {
      final rows = UspPdfService.firmwareImageRows(const [
        FirmwareImageUIModel(
          instancePath: 'Device.DeviceInfo.FirmwareImage.1.',
          name: '2.0.1',
          version: '2.0.1.26091007',
          status: 'Active',
          available: true,
          isActive: true,
          isBootTarget: true,
        ),
      ]);

      expect(rows, hasLength(1));
      expect(rows.single.label, '  2.0.1');
      expect(rows.single.value, '2.0.1.26091007 (Active, Boot)');
    });

    test('falls back to the instance path when the image has no name', () {
      final rows = UspPdfService.firmwareImageRows(const [
        FirmwareImageUIModel(
          instancePath: 'Device.DeviceInfo.FirmwareImage.2.',
          name: '',
          version: '',
          status: 'Available',
          available: true,
        ),
      ]);

      expect(rows.single.label, '  Device.DeviceInfo.FirmwareImage.2.');
    });

    test('an empty version is printed as a normal state, not a failure', () {
      // A non-active bank cannot report its version — confirmed with firmware,
      // so the report must not read as a read error.
      final rows = UspPdfService.firmwareImageRows(const [
        FirmwareImageUIModel(
          instancePath: 'Device.DeviceInfo.FirmwareImage.2.',
          name: 'fw2',
          version: '',
          status: 'Available',
          available: true,
        ),
      ]);

      expect(rows, hasLength(1));
      expect(rows.single.value, isEmpty);
    });
  });

  group('firmware list on a three-instance router', () {
    late MockUspClient mockUsp;

    setUp(() {
      mockUsp = MockUspClient();
      when(() => mockUsp.get(any())).thenAnswer((_) async {
        final paths = _.positionalArguments[0] as List;
        if (paths.any((p) => p.toString().contains('Manufacturer'))) {
          return systemInfoResponse;
        } else if (paths
            .any((p) => p.toString().contains('FirmwareImage.*.'))) {
          return FirmwareUpdateTestData.threeInstanceResponse(
            otaAvailable: true,
            otaVersion: '2.0.1.26091009',
          );
        }
        return <String, dynamic>{};
      });
    });

    test('the report lists 2 firmware images, not 3', () async {
      final container = ProviderContainer(
        overrides: [uspClientProvider.overrideWithValue(mockUsp)],
      );
      addTearDown(container.dispose);

      final data = await container.read(systemInfoDataProvider.future);
      final rows = UspPdfService.firmwareImageRows(data.model.firmwareImages);

      expect(rows, hasLength(2));
      expect(
        rows.map((r) => r.value).join('\n'),
        isNot(contains('2.0.1.26091009')),
        reason: 'the version the router could update to is not a firmware '
            'image the router holds',
      );
    });
  });

  // #1121: a node's client list holds offline clients too. The PDF printed
  // its length, so the Devices column over-reported against the active-only
  // count the report used before PR #1068.
  group('meshTopologyRows', () {
    test('the Devices column counts online clients only', () {
      final rows = UspPdfService.meshTopologyRows([
        DevicesTestData.createMaster(
          friendlyName: 'Living Room',
          connectedClients: [
            DevicesTestData.createWifiClient(mac: DevicesTestData.clientMac1),
            DevicesTestData.createWiredClient(mac: DevicesTestData.clientMac2),
            DevicesTestData.createOfflineClient(
                mac: DevicesTestData.clientMac3),
          ],
        ),
        DevicesTestData.createWifiSlave(
          friendlyName: 'Office',
          connectedClients: [
            DevicesTestData.createOfflineClient(
                mac: DevicesTestData.clientMac4),
          ],
        ),
      ]);

      expect(rows.map((r) => r.last).toList(), ['2', '0'],
          reason: 'two of the master\'s three clients are online, and none of '
              'the extender\'s one');
    });

    test('prints name, role, model and firmware beside the count', () {
      final rows = UspPdfService.meshTopologyRows([
        DevicesTestData.createMaster(friendlyName: 'Living Room'),
        DevicesTestData.createWifiSlave(friendlyName: 'Office'),
      ]);

      expect(rows.first, [
        'Living Room',
        'Master',
        DevicesTestData.defaultModel,
        DevicesTestData.defaultSoftwareVersion,
        '0',
      ]);
      expect(rows.last[1], 'Extender');
    });
  });
}
