import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_chunker.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_local_upload_service.dart';

class MockUspClient extends Mock implements UspClient {}

void main() {
  late MockUspClient mockUsp;
  late UspMutationLock lock;
  late FirmwareLocalUploadService service;

  setUpAll(() {
    registerFallbackValue(<String, String>{});
  });

  setUp(() {
    mockUsp = MockUspClient();
    lock = UspMutationLock();
    service = FirmwareLocalUploadService(
      mockUsp,
      lock,
      // 4-byte chunks keep tests cheap and make sequence math easy to verify.
      chunker: const FirmwareChunker(chunkBytes: 4),
    );
  });

  Uint8List bytesOf(int len) =>
      Uint8List.fromList(List<int>.generate(len, (i) => i & 0xff));

  group('FirmwareLocalUploadService.uploadFile', () {
    test('rejects empty input with InvalidInputError', () async {
      expect(
        () => service.uploadFile(
          bytes: Uint8List(0),
          md5: 'abc',
          commandKey: 'cmd-1',
        ),
        throwsA(isA<InvalidInputError>()),
      );
    });

    test('emits onProgress(0,total) before sending and after each chunk',
        () async {
      when(() => mockUsp.operate(any(), args: any(named: 'args')))
          .thenAnswer((_) async => <String, dynamic>{});
      final progress = <List<int>>[];

      await service.uploadFile(
        bytes: bytesOf(10),
        md5: 'abc',
        commandKey: 'cmd-1',
        onProgress: (sent, total) => progress.add([sent, total]),
      );

      // 10 bytes / 4 bytes per chunk => 3 chunks; 1 init + 3 per-chunk emits.
      expect(progress, [
        [0, 3],
        [1, 3],
        [2, 3],
        [3, 3],
      ]);
    });

    test('forwards expected operate args per chunk (1-based sequence, base64)',
        () async {
      when(() => mockUsp.operate(any(), args: any(named: 'args')))
          .thenAnswer((_) async => <String, dynamic>{});
      final bytes = bytesOf(10);

      await service.uploadFile(
        bytes: bytes,
        md5: 'fingerprint',
        commandKey: 'cmd-1',
      );

      final captured = verify(
        () => mockUsp.operate(captureAny(), args: captureAny(named: 'args')),
      ).captured;
      expect(captured.length, 6); // 3 chunks × (path, args)
      expect(captured[0], 'Device.LocalAgent.X_LINKSYS_Download()');
      final args1 = captured[1] as Map<String, String>;
      expect(args1['SequenceNumber'], '1');
      expect(args1['TotalFragment'], '3');
      expect(args1['Filename'], 'firmware.img');
      expect(args1['Filesize'], '10');
      expect(args1['Checksum'], 'fingerprint');
      expect(args1['CommandKey'], 'cmd-1');
      expect(args1['Content'], base64Encode(bytes.sublist(0, 4)));

      final args2 = captured[3] as Map<String, String>;
      expect(args2['SequenceNumber'], '2');
      expect(args2['Content'], base64Encode(bytes.sublist(4, 8)));

      final args3 = captured[5] as Map<String, String>;
      expect(args3['SequenceNumber'], '3');
      expect(args3['Content'], base64Encode(bytes.sublist(8, 10)));
    });

    test('aborts before next chunk when isCancelled returns true', () async {
      var sent = 0;
      when(() => mockUsp.operate(any(), args: any(named: 'args')))
          .thenAnswer((_) async {
        sent++;
        return <String, dynamic>{};
      });

      // Cancel after the first chunk lands.
      var cancel = false;
      final future = service.uploadFile(
        bytes: bytesOf(20), // 5 chunks of 4 bytes
        md5: 'abc',
        commandKey: 'cmd-1',
        isCancelled: () => cancel,
        onProgress: (s, _) {
          if (s == 1) cancel = true;
        },
      );

      await expectLater(future, throwsA(isA<OperationCancelledError>()));
      expect(sent, 1, reason: 'should not push more chunks after cancel');
    });

    test('maps raw USP errors to ServiceError', () async {
      when(() => mockUsp.operate(any(), args: any(named: 'args')))
          .thenThrow('Operate failed: Authentication error: Permission denied');

      expect(
        () => service.uploadFile(
          bytes: bytesOf(10),
          md5: 'abc',
          commandKey: 'cmd-1',
        ),
        throwsA(isA<UnauthorizedError>()),
      );
    });

    // #1533 item 2: a chunk the router refuses must fail the upload visibly.
    // `uploadChunk` is `Future<void>` and only reacts to throws, which is why the
    // fix belongs in `UspClient.extractOperateResult`: once a refusal throws
    // there, this path needs no change. Before it threw, a refused chunk completed
    // normally and the UI showed a finished upload.
    //
    // **What this test does not cover.** `UspClient` is mocked here, so the real
    // `extractOperateResult` never runs and the throw is injected rather than
    // produced. It pins the second half — a refusal that reaches this service
    // surfaces as a command failure and not as a network error — and nothing
    // spans the two halves, because the seam between them *is* the mock. The
    // throw itself is pinned in `usp_client_operate_result_test.dart`.
    //
    // The assertion is on the *type*: `UnexpectedError` would render as
    // "something went wrong", which is what a network blip looks like too.
    test(
        'a refusal reaching this service is a command failure, not a network error',
        () async {
      when(() => mockUsp.operate(any(), args: any(named: 'args'))).thenThrow(
        'Operate failed: Operation error: '
        'Device.LocalAgent.X_LINKSYS_Download() refused: Command Failure '
        '(code: 7022)',
      );

      await expectLater(
        service.uploadFile(bytes: bytesOf(10), md5: 'abc', commandKey: 'cmd-1'),
        throwsA(
            isA<UspCompleteFailureError>().having((e) => e.code, 'code', 7022)),
      );
    });

    test('rethrows existing ServiceError without re-mapping', () async {
      when(() => mockUsp.operate(any(), args: any(named: 'args')))
          .thenThrow(const NetworkError(detail: 'timeout'));

      expect(
        () => service.uploadFile(
          bytes: bytesOf(10),
          md5: 'abc',
          commandKey: 'cmd-1',
        ),
        throwsA(isA<NetworkError>()),
      );
    });

    // The point of PrivacyGUI#1874: with no chunker injected, the HTTP push
    // slices 192 KiB, and every slice goes out as one Operate. Two full chunks
    // and a one-byte tail make an off-by-one in either direction visible.
    test('pushes 192 KiB chunks over HTTP by default', () async {
      when(() => mockUsp.operate(any(), args: any(named: 'args')))
          .thenAnswer((_) async => <String, dynamic>{});
      final bytes = bytesOf(2 * 196608 + 1);

      await FirmwareLocalUploadService(mockUsp, lock).uploadFile(
        bytes: bytes,
        md5: 'abc',
        commandKey: '123',
      );

      final args = verify(
        () => mockUsp.operate(
          'Device.LocalAgent.X_LINKSYS_Download()',
          args: captureAny(named: 'args'),
        ),
      ).captured.cast<Map<String, String>>();
      expect(args.map((a) => base64Decode(a['Content']!).length),
          [196608, 196608, 1]);
      expect(args.map((a) => a['TotalFragment']), ['3', '3', '3']);
      expect(base64Decode(args.last['Content']!), bytes.sublist(2 * 196608));
    });

    test('totalFragmentsFor mirrors chunker math', () {
      expect(service.totalFragmentsFor(0), 0);
      expect(service.totalFragmentsFor(1), 1);
      expect(service.totalFragmentsFor(4), 1);
      expect(service.totalFragmentsFor(5), 2);
    });
  });
}
