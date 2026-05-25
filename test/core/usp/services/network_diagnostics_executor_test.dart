import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/services/network_diagnostics_executor.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_awaiter.dart';

class _MockAwaiter extends Mock implements SseOperationAwaiter {}

OperateResult _stubResult({
  String name = 'IPPing()',
  String status = 'Complete',
  Map<String, String> outputArgs = const {},
}) =>
    OperateResult(
      commandName: name,
      commandKey: 'k',
      status: status,
      outputArgs: outputArgs,
    );

void main() {
  late _MockAwaiter awaiter;
  late NetworkDiagnosticsExecutor executor;

  setUpAll(() {
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    awaiter = _MockAwaiter();
    executor = NetworkDiagnosticsExecutor(awaiter);

    when(() => awaiter.hasSharedSubscription).thenReturn(false);
    when(() => awaiter.startSharedSession(
          referencePath: any(named: 'referencePath'),
          referencePaths: any(named: 'referencePaths'),
        )).thenAnswer((_) async {});
    when(() => awaiter.endSharedSession()).thenAnswer((_) async {});
    when(() => awaiter.execute(
          operateCommand: any(named: 'operateCommand'),
          referencePath: any(named: 'referencePath'),
          args: any(named: 'args'),
          timeout: any(named: 'timeout'),
        )).thenAnswer((_) async => _stubResult());
    when(() => awaiter.executeInSession(
          operateCommand: any(named: 'operateCommand'),
          args: any(named: 'args'),
          timeout: any(named: 'timeout'),
        )).thenAnswer((_) async => _stubResult());
  });

  // ---------------------------------------------------------------------------
  // acquireScope / DiagnosticScope.release
  // ---------------------------------------------------------------------------
  group('acquireScope', () {
    test('default subscribes IP + DNS diagnostic paths', () async {
      final scope = await executor.acquireScope();

      verify(() => awaiter.startSharedSession(
            referencePaths: const [
              'Device.IP.Diagnostics.',
              'Device.DNS.Diagnostics.',
            ],
          )).called(1);

      await scope.release();
      verify(() => awaiter.endSharedSession()).called(1);
    });

    test('release is idempotent', () async {
      final scope = await executor.acquireScope();
      await scope.release();
      await scope.release();
      verify(() => awaiter.endSharedSession()).called(1);
    });

    test('after release, ops on scope throw StateError', () async {
      final scope = await executor.acquireScope();
      await scope.release();
      expect(() => scope.ping(host: '8.8.8.8'), throwsStateError);
    });

    test('custom referencePaths forwarded to awaiter', () async {
      await executor.acquireScope(referencePaths: const ['Device.X.']);
      verify(() => awaiter.startSharedSession(
            referencePaths: const ['Device.X.'],
          )).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // Ad-hoc ops — args mirror codegen NetworkDiagnostics.* parameter names.
  // ---------------------------------------------------------------------------
  group('ad-hoc ops', () {
    test('ping forwards Host + NumberOfRepetitions to IPPing()', () async {
      await executor.ping(host: '8.8.8.8', numberOfRepetitions: 5);
      verify(() => awaiter.execute(
            operateCommand: 'Device.IP.Diagnostics.IPPing()',
            referencePath: 'Device.IP.Diagnostics.',
            args: {'Host': '8.8.8.8', 'NumberOfRepetitions': '5'},
            timeout: any(named: 'timeout'),
          )).called(1);
    });

    test('traceRoute forwards Host + MaxHopCount to TraceRoute()', () async {
      await executor.traceRoute(host: 'example.com', maxHopCount: 30);
      verify(() => awaiter.execute(
            operateCommand: 'Device.IP.Diagnostics.TraceRoute()',
            referencePath: 'Device.IP.Diagnostics.',
            args: {'Host': 'example.com', 'MaxHopCount': '30'},
            timeout: any(named: 'timeout'),
          )).called(1);
    });

    test('nsLookup uses DNS reference path', () async {
      await executor.nsLookup(hostName: 'example.com', dnsServer: '1.1.1.1');
      verify(() => awaiter.execute(
            operateCommand: 'Device.DNS.Diagnostics.NSLookupDiagnostics()',
            referencePath: 'Device.DNS.Diagnostics.',
            args: {'HostName': 'example.com', 'DNSServer': '1.1.1.1'},
            timeout: any(named: 'timeout'),
          )).called(1);
    });

    test('downloadDiagnostic forwards DownloadURL', () async {
      await executor.downloadDiagnostic(
        downloadUrl: 'http://example.com/file',
        numberOfConnections: 4,
      );
      verify(() => awaiter.execute(
            operateCommand: 'Device.IP.Diagnostics.DownloadDiagnostics()',
            referencePath: 'Device.IP.Diagnostics.',
            args: {
              'DownloadURL': 'http://example.com/file',
              'NumberOfConnections': '4',
            },
            timeout: any(named: 'timeout'),
          )).called(1);
    });

    test('uploadDiagnostic forwards UploadURL + TestFileLength', () async {
      await executor.uploadDiagnostic(
        uploadUrl: 'http://example.com/upload',
        testFileLength: 10485760,
      );
      verify(() => awaiter.execute(
            operateCommand: 'Device.IP.Diagnostics.UploadDiagnostics()',
            referencePath: 'Device.IP.Diagnostics.',
            args: {
              'UploadURL': 'http://example.com/upload',
              'TestFileLength': '10485760',
            },
            timeout: any(named: 'timeout'),
          )).called(1);
    });

    test('udpEcho forwards Host + Port', () async {
      await executor.udpEcho(host: '8.8.8.8', port: 7);
      verify(() => awaiter.execute(
            operateCommand: 'Device.IP.Diagnostics.UDPEchoDiagnostics()',
            referencePath: 'Device.IP.Diagnostics.',
            args: {'Host': '8.8.8.8', 'Port': '7'},
            timeout: any(named: 'timeout'),
          )).called(1);
    });

    test('serverSelection forwards HostList + Protocol', () async {
      await executor.serverSelection(
        hostList: 'a,b,c',
        protocol: 'ICMP',
      );
      verify(() => awaiter.execute(
            operateCommand:
                'Device.IP.Diagnostics.ServerSelectionDiagnostics()',
            referencePath: 'Device.IP.Diagnostics.',
            args: {'HostList': 'a,b,c', 'Protocol': 'ICMP'},
            timeout: any(named: 'timeout'),
          )).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // Scoped ops — same arg semantics, but executeInSession instead of execute.
  // ---------------------------------------------------------------------------
  group('scoped ops', () {
    test('scope.ping uses executeInSession', () async {
      final scope = await executor.acquireScope();
      await scope.ping(host: '8.8.8.8');
      verify(() => awaiter.executeInSession(
            operateCommand: 'Device.IP.Diagnostics.IPPing()',
            args: {'Host': '8.8.8.8'},
            timeout: any(named: 'timeout'),
          )).called(1);
    });

    test('scope.nsLookup uses executeInSession', () async {
      final scope = await executor.acquireScope();
      await scope.nsLookup(hostName: 'example.com');
      verify(() => awaiter.executeInSession(
            operateCommand: 'Device.DNS.Diagnostics.NSLookupDiagnostics()',
            args: {'HostName': 'example.com'},
            timeout: any(named: 'timeout'),
          )).called(1);
    });

    test('scope.downloadDiagnostic uses executeInSession', () async {
      final scope = await executor.acquireScope();
      await scope.downloadDiagnostic(downloadUrl: 'http://x/y');
      verify(() => awaiter.executeInSession(
            operateCommand: 'Device.IP.Diagnostics.DownloadDiagnostics()',
            args: {'DownloadURL': 'http://x/y'},
            timeout: any(named: 'timeout'),
          )).called(1);
    });
  });
}
