import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/system_log/services/usp_system_log_service.dart';

class MockUspClient extends Mock implements UspClient {}

void main() {
  late MockUspClient mockUsp;
  late UspSystemLogService service;

  setUp(() {
    mockUsp = MockUspClient();
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

  group('UspSystemLogService — error handling', () {
    test('fetch maps USP transport error to NetworkError', () {
      when(() => mockUsp.get(any()))
          .thenThrow('Get failed: Transport error: Request timeout');

      expect(() => service.fetch(), throwsA(isA<NetworkError>()));
    });

    test('fetch maps USP protocol error to ResourceNotFoundError', () {
      when(() => mockUsp.get(any())).thenThrow(
        'Get failed: Protocol error: Decoding error: '
        'Path (Device.DeviceInfo.VendorLogFile) does not exist (code: 7026)',
      );

      expect(() => service.fetch(), throwsA(isA<ResourceNotFoundError>()));
    });

    test('fetch maps non-USP error to UnexpectedError', () {
      when(() => mockUsp.get(any())).thenThrow('random error');

      expect(() => service.fetch(), throwsA(isA<UnexpectedError>()));
    });
  });
}
