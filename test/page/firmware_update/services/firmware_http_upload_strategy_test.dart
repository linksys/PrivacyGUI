import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_http_upload_strategy.dart';

class MockUspClient extends Mock implements UspClient {}

void main() {
  late MockUspClient mockUsp;
  late UspMutationLock lock;
  late FirmwareHttpUploadStrategy strategy;

  setUpAll(() {
    registerFallbackValue(<String, String>{});
  });

  setUp(() {
    mockUsp = MockUspClient();
    lock = UspMutationLock();
    strategy = FirmwareHttpUploadStrategy(
      client: mockUsp,
      lock: lock,
    );
  });

  group('FirmwareHttpUploadStrategy', () {
    test('name returns HTTP', () {
      expect(strategy.name, 'HTTP');
    });

    test('isAvailable returns true when authenticated', () async {
      when(() => mockUsp.isAuthenticated).thenReturn(true);

      final available = await strategy.isAvailable();

      expect(available, isTrue);
    });

    test('isAvailable returns false when not authenticated', () async {
      when(() => mockUsp.isAuthenticated).thenReturn(false);

      final available = await strategy.isAvailable();

      expect(available, isFalse);
    });

    test('prepare is no-op', () async {
      // Should complete without error
      await strategy.prepare();
    });

    test('finalize is no-op', () async {
      // Should complete without error
      await strategy.finalize();
    });

    test('uploadChunk sends operate with correct parameters', () async {
      when(() => mockUsp.operate(any(), args: any(named: 'args')))
          .thenAnswer((_) async => <String, dynamic>{'success': true});

      final chunk = Uint8List.fromList([1, 2, 3, 4, 5]);
      await strategy.uploadChunk(
        chunk: chunk,
        sequenceNumber: 1,
        totalChunks: 10,
        md5: 'abc123md5',
        fileSize: 1000,
        commandKey: '1234567890',
      );

      final captured = verify(
        () => mockUsp.operate(captureAny(), args: captureAny(named: 'args')),
      ).captured;

      expect(captured[0], 'Device.LocalAgent.X_LINKSYS_Download()');
      final args = captured[1] as Map<String, String>;
      expect(args['Content'], base64Encode(chunk));
      expect(args['Filename'], 'firmware.img');
      expect(args['TotalFragment'], '10');
      expect(args['SequenceNumber'], '1');
      expect(args['CommandKey'], '1234567890');
      expect(args['Checksum'], 'abc123md5');
      expect(args['Filesize'], '1000');
    });

    test('uploadChunk rethrows ServiceError', () async {
      when(() => mockUsp.operate(any(), args: any(named: 'args')))
          .thenThrow(const NetworkError(detail: 'Connection lost'));

      expect(
        () => strategy.uploadChunk(
          chunk: Uint8List.fromList([1, 2, 3]),
          sequenceNumber: 1,
          totalChunks: 5,
          md5: 'md5hash',
          fileSize: 500,
          commandKey: '123',
        ),
        throwsA(isA<NetworkError>()),
      );
    });

    test('uploadChunk maps raw errors to ServiceError', () async {
      when(() => mockUsp.operate(any(), args: any(named: 'args')))
          .thenThrow('Operate failed: Transport error: timeout');

      expect(
        () => strategy.uploadChunk(
          chunk: Uint8List.fromList([1, 2, 3]),
          sequenceNumber: 1,
          totalChunks: 5,
          md5: 'md5hash',
          fileSize: 500,
          commandKey: '123',
        ),
        throwsA(isA<ServiceError>()),
      );
    });
  });
}
