import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/cloud/http/linksys_http_client.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_info.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_ota_check_service.dart';

class MockLinksysHttpClient extends Mock implements LinksysHttpClient {}

class FakeUri extends Fake implements Uri {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  group('FirmwareOtaCheckService', () {
    late MockLinksysHttpClient mockClient;
    late FirmwareOtaCheckService service;

    const testParams = FirmwareOtaCheckParams(
      macAddress: '74-12-13-21-56-3A',
      installedVersion: '1.2.1.26052809',
      modelNumber: 'M60-US',
      hardwareVersion: '1',
      ipAddress: '118.163.122.211',
    );

    setUp(() {
      mockClient = MockLinksysHttpClient();
      service = FirmwareOtaCheckService(client: mockClient);
    });

    test('returns FirmwareOtaInfo when update is available', () async {
      const responseBody = '''
{
  "version": "1.0.10.25092307",
  "release_date": "2025-09-23T17:06:26Z",
  "download_url": "http://download.linksys.com/updates/firmware.img",
  "checksum": "1022217387",
  "check_interval": "daily",
  "check_time": "06:00:00Z"
}
''';
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(responseBody, 200),
      );

      final result = await service.checkForUpdate(testParams);

      expect(result, isNotNull);
      expect(result!.version, '1.0.10.25092307');
      expect(result.downloadUrl,
          'http://download.linksys.com/updates/firmware.img');
      expect(result.checksum, '1022217387');
    });

    test('returns null when no update available (empty body)', () async {
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response('', 200),
      );

      final result = await service.checkForUpdate(testParams);

      expect(result, isNull);
    });

    test('throws FirmwareOtaCheckException on non-200 status', () async {
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response('Server Error', 500),
      );

      expect(
        () => service.checkForUpdate(testParams),
        throwsA(isA<FirmwareOtaCheckException>().having(
          (e) => e.message,
          'message',
          contains('HTTP 500'),
        )),
      );
    });

    test('throws FirmwareOtaCheckException on 404', () async {
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response('Not Found', 404),
      );

      expect(
        () => service.checkForUpdate(testParams),
        throwsA(isA<FirmwareOtaCheckException>().having(
          (e) => e.message,
          'message',
          contains('HTTP 404'),
        )),
      );
    });

    test('throws FirmwareOtaCheckException on invalid JSON', () async {
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response('not valid json', 200),
      );

      expect(
        () => service.checkForUpdate(testParams),
        throwsA(isA<FirmwareOtaCheckException>()),
      );
    });

    test('throws FirmwareOtaCheckException on network error', () async {
      when(() => mockClient.get(any())).thenThrow(
        Exception('Network unreachable'),
      );

      expect(
        () => service.checkForUpdate(testParams),
        throwsA(isA<FirmwareOtaCheckException>().having(
          (e) => e.message,
          'message',
          contains('Network unreachable'),
        )),
      );
    });

    test('constructs correct URI with query parameters', () async {
      Uri? capturedUri;
      when(() => mockClient.get(any())).thenAnswer((invocation) async {
        capturedUri = invocation.positionalArguments[0] as Uri;
        return http.Response('', 200);
      });

      await service.checkForUpdate(testParams);

      expect(capturedUri, isNotNull);
      expect(capturedUri!.queryParameters['mac_address'], '74-12-13-21-56-3A');
      expect(
          capturedUri!.queryParameters['installed_version'], '1.2.1.26052809');
      expect(capturedUri!.queryParameters['model_number'], 'M60-US');
      expect(capturedUri!.queryParameters['hardware_version'], '1');
      expect(capturedUri!.queryParameters['ip_address'], '118.163.122.211');
    });
  });

  group('FirmwareOtaCheckException', () {
    test('toString returns message', () {
      final exception = FirmwareOtaCheckException('Test error message');
      expect(exception.toString(), 'Test error message');
    });
  });
}
