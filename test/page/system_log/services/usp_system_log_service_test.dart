import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/page/system_log/services/usp_system_log_service.dart';

class MockUspService extends Mock implements UspService {}

void main() {
  late MockUspService mockUsp;
  late UspSystemLogService service;

  setUp(() {
    mockUsp = MockUspService();
    service = UspSystemLogService(mockUsp);
  });

  group('UspSystemLogService — fetch', () {
    test('returns empty list when no log files exist', () async {
      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => <String, dynamic>{});

      final result = await service.fetch();

      expect(result, isEmpty);
    });

    test('maps single vendor log file correctly', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            'Device.DeviceInfo.VendorLogFile.1.Name': 'syslog',
            'Device.DeviceInfo.VendorLogFile.1.MaximumSize': '524288',
            'Device.DeviceInfo.VendorLogFile.1.Persistent': true,
          });

      final result = await service.fetch();

      expect(result, hasLength(1));
      expect(result[0].name, 'syslog');
      expect(result[0].maximumSize, 524288);
      expect(result[0].persistent, isTrue);
      expect(
        result[0].instancePath,
        'Device.DeviceInfo.VendorLogFile.1.',
      );
    });

    test('maps multiple vendor log files in order', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            'Device.DeviceInfo.VendorLogFile.1.Name': 'syslog',
            'Device.DeviceInfo.VendorLogFile.1.MaximumSize': '524288',
            'Device.DeviceInfo.VendorLogFile.1.Persistent': true,
            'Device.DeviceInfo.VendorLogFile.2.Name': 'crashlog',
            'Device.DeviceInfo.VendorLogFile.2.MaximumSize': '65536',
            'Device.DeviceInfo.VendorLogFile.2.Persistent': false,
          });

      final result = await service.fetch();

      expect(result, hasLength(2));
      expect(result[0].name, 'syslog');
      expect(result[1].name, 'crashlog');
      expect(result[1].maximumSize, 65536);
      expect(result[1].persistent, isFalse);
    });
  });
}
