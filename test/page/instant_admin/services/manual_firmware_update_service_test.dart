import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/cloud/model/error_response.dart';
import 'package:privacy_gui/page/instant_admin/services/manual_firmware_update_service.dart';
import 'package:http/http.dart' as http;

import '../../../mocks/_index.dart';

void main() {
  group('ManualFirmwareUpdateService', () {
    late MockLinksysHttpClient mockHttpClient;
    late ProviderContainer container;

    setUp(() {
      mockHttpClient = MockLinksysHttpClient();
      // The service is provided by Riverpod and depends on LinksysHttpClient.
      // To test the service in isolation, we override the dependency provider
      // to supply our mock http client.
      container = ProviderContainer(
        overrides: [
          linksysHttpClientProvider.overrideWithValue(mockHttpClient),
        ],
      );
    });

    test('manualFirmwareUpdate returns true on successful upload', () async {
      final service = container.read(manualFirmwareUpdateServiceProvider);
      const filename = 'firmware.img';
      final bytes = Uint8List.fromList([1, 2, 3]);
      const password = 'password';
      const ip = '192.168.1.1';

      when(mockHttpClient.getHost()).thenReturn(ip);
      when(mockHttpClient.upload(any, any,
              headers: anyNamed('headers'), fields: anyNamed('fields')))
          .thenAnswer((_) async => http.Response('{"result": "OK"}', 200));

      final result =
          await service.manualFirmwareUpdate(filename, bytes, password, ip);

      expect(result, isTrue);
    });

    test(
        'manualFirmwareUpdate returns true when upload throws ErrorResponse with 500 code',
        () async {
      final service = container.read(manualFirmwareUpdateServiceProvider);
      const filename = 'firmware.img';
      final bytes = Uint8List.fromList([1, 2, 3]);
      const password = 'password';
      const ip = '192.168.1.1';

      when(mockHttpClient.getHost()).thenReturn(ip);
      // Simulate ErrorResponse with 500 error code
      when(mockHttpClient.upload(any, any,
              headers: anyNamed('headers'), fields: anyNamed('fields')))
          .thenAnswer((_) async => throw ErrorResponse(status: 500, code: '500', errorMessage: 'Error'));

      // Expect throw ManualFirmwareUpdateException
      final result =
          await service.manualFirmwareUpdate(filename, bytes, password, ip);

      expect(result, isTrue);
    });

    test(
        'manualFirmwareUpdate throws ManualFirmwareUpdateException for other errors',
        () async {
      final service = container.read(manualFirmwareUpdateServiceProvider);
      const filename = 'firmware.img';
      final bytes = Uint8List.fromList([1, 2, 3]);
      const password = 'password';
      const ip = '192.168.1.1';

      when(mockHttpClient.getHost()).thenReturn(ip);
      when(mockHttpClient.upload(any, any,
              headers: anyNamed('headers'), fields: anyNamed('fields')))
          .thenAnswer((_) async => throw Exception('Some other error'));

      expect(() => service.manualFirmwareUpdate(filename, bytes, password, ip),
          throwsA(isA<ManualFirmwareUpdateException>()));
    });

    test('manualFirmwareUpdate returns false on failed upload', () async {
      final service = container.read(manualFirmwareUpdateServiceProvider);
      const filename = 'firmware.img';
      final bytes = Uint8List.fromList([1, 2, 3]);
      const password = 'password';
      const ip = '192.168.1.1';

      when(mockHttpClient.getHost()).thenReturn(ip);
      when(mockHttpClient.upload(any, any,
              headers: anyNamed('headers'), fields: anyNamed('fields')))
          .thenAnswer((_) async => throw ManualFirmwareUpdateException('FAIL'));

      expect(() => service.manualFirmwareUpdate(filename, bytes, password, ip),
          throwsA(isA<ManualFirmwareUpdateException>()));
    });
  });
}
