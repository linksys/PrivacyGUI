import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/models/operate_result.dart';
import 'package:privacy_gui/core/usp/services/network_diagnostics_executor.dart';
import 'package:privacy_gui/page/unified_diagnostics/services/diagnostics_scope_service.dart';

class MockNetworkDiagnosticsExecutor extends Mock
    implements NetworkDiagnosticsExecutor {}

class MockDiagnosticScope extends Mock implements DiagnosticScope {}

UspError _testUspError() => UspError(
      operation: 'Get',
      category: UspErrorCategory.operation,
      message: 'USP error',
      rawError: 'Get failed: operation: USP error',
    );

OperateResult _testOperateResult(String commandName) => OperateResult(
      commandName: commandName,
      commandKey: 'test-key',
      status: 'Complete',
      outputArgs: {'Status': 'Complete'},
    );

void main() {
  late MockNetworkDiagnosticsExecutor mockExecutor;
  late MockDiagnosticScope mockScope;
  late DiagnosticsScopeService service;

  setUpAll(() {
    registerFallbackValue(const Duration(seconds: 30));
  });

  setUp(() {
    mockExecutor = MockNetworkDiagnosticsExecutor();
    mockScope = MockDiagnosticScope();
    service = DiagnosticsScopeService(mockExecutor);
  });

  group('acquireScope', () {
    test('returns scope on success', () async {
      when(() => mockExecutor.acquireScope())
          .thenAnswer((_) async => mockScope);

      final result = await service.acquireScope();

      expect(result, mockScope);
      verify(() => mockExecutor.acquireScope()).called(1);
    });

    test('rethrows ServiceError unchanged', () async {
      when(() => mockExecutor.acquireScope())
          .thenThrow(const NetworkError(detail: 'Connection lost'));

      expect(
        () => service.acquireScope(),
        throwsA(isA<NetworkError>()),
      );
    });

    test('rethrows TimeoutException unchanged', () async {
      when(() => mockExecutor.acquireScope())
          .thenThrow(TimeoutException('Timed out'));

      expect(
        () => service.acquireScope(),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('maps UspError to ServiceError', () async {
      when(() => mockExecutor.acquireScope()).thenThrow(_testUspError());

      expect(
        () => service.acquireScope(),
        throwsA(isA<ServiceError>()),
      );
    });

    test('maps generic exception to ServiceError', () async {
      when(() => mockExecutor.acquireScope())
          .thenThrow(Exception('Unknown error'));

      expect(
        () => service.acquireScope(),
        throwsA(isA<ServiceError>()),
      );
    });
  });

  group('releaseScope', () {
    test('calls scope.release()', () async {
      when(() => mockScope.isReleased).thenReturn(false);
      when(() => mockScope.release()).thenAnswer((_) async {});

      await service.releaseScope(mockScope);

      verify(() => mockScope.release()).called(1);
    });

    test('skips release if already released', () async {
      when(() => mockScope.isReleased).thenReturn(true);

      await service.releaseScope(mockScope);

      verifyNever(() => mockScope.release());
    });

    test('swallows release errors', () async {
      when(() => mockScope.isReleased).thenReturn(false);
      when(() => mockScope.release()).thenThrow(Exception('Release failed'));

      // Should not throw
      await service.releaseScope(mockScope);
    });
  });

  group('ping', () {
    test('returns result on success', () async {
      final testResult = _testOperateResult('IPPing');
      when(() => mockScope.ping(
            host: any(named: 'host'),
            numberOfRepetitions: any(named: 'numberOfRepetitions'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) async => testResult);

      final result = await service.ping(mockScope, host: '8.8.8.8');

      expect(result, testResult);
    });

    test('rethrows TimeoutException unchanged', () async {
      when(() => mockScope.ping(
            host: any(named: 'host'),
            numberOfRepetitions: any(named: 'numberOfRepetitions'),
            timeout: any(named: 'timeout'),
          )).thenThrow(TimeoutException('Ping timed out'));

      expect(
        () => service.ping(mockScope, host: '8.8.8.8'),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('rethrows ServiceError unchanged', () async {
      when(() => mockScope.ping(
            host: any(named: 'host'),
            numberOfRepetitions: any(named: 'numberOfRepetitions'),
            timeout: any(named: 'timeout'),
          )).thenThrow(const InvalidInputError(detail: 'Invalid host'));

      expect(
        () => service.ping(mockScope, host: 'invalid'),
        throwsA(isA<InvalidInputError>()),
      );
    });

    test('maps UspError to ServiceError', () async {
      when(() => mockScope.ping(
            host: any(named: 'host'),
            numberOfRepetitions: any(named: 'numberOfRepetitions'),
            timeout: any(named: 'timeout'),
          )).thenThrow(_testUspError());

      expect(
        () => service.ping(mockScope, host: '8.8.8.8'),
        throwsA(isA<ServiceError>()),
      );
    });
  });

  group('traceRoute', () {
    test('returns result on success', () async {
      final testResult = _testOperateResult('TraceRoute');
      when(() => mockScope.traceRoute(
            host: any(named: 'host'),
            maxHopCount: any(named: 'maxHopCount'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) async => testResult);

      final result = await service.traceRoute(mockScope, host: '8.8.8.8');

      expect(result, testResult);
    });

    test('rethrows TimeoutException unchanged', () async {
      when(() => mockScope.traceRoute(
            host: any(named: 'host'),
            maxHopCount: any(named: 'maxHopCount'),
            timeout: any(named: 'timeout'),
          )).thenThrow(TimeoutException('Traceroute timed out'));

      expect(
        () => service.traceRoute(mockScope, host: '8.8.8.8'),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('maps generic exception to ServiceError', () async {
      when(() => mockScope.traceRoute(
            host: any(named: 'host'),
            maxHopCount: any(named: 'maxHopCount'),
            timeout: any(named: 'timeout'),
          )).thenThrow(Exception('Unknown'));

      expect(
        () => service.traceRoute(mockScope, host: '8.8.8.8'),
        throwsA(isA<ServiceError>()),
      );
    });
  });

  group('nsLookup', () {
    test('returns result on success', () async {
      final testResult = _testOperateResult('NSLookupDiagnostics');
      when(() => mockScope.nsLookup(
            hostName: any(named: 'hostName'),
            dnsServer: any(named: 'dnsServer'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) async => testResult);

      final result = await service.nsLookup(mockScope, hostName: 'google.com');

      expect(result, testResult);
    });

    test('rethrows TimeoutException unchanged', () async {
      when(() => mockScope.nsLookup(
            hostName: any(named: 'hostName'),
            dnsServer: any(named: 'dnsServer'),
            timeout: any(named: 'timeout'),
          )).thenThrow(TimeoutException('NS Lookup timed out'));

      expect(
        () => service.nsLookup(mockScope, hostName: 'google.com'),
        throwsA(isA<TimeoutException>()),
      );
    });
  });

  group('downloadDiagnostic', () {
    test('returns result on success', () async {
      final testResult = _testOperateResult('DownloadDiagnostics');
      when(() => mockScope.downloadDiagnostic(
            downloadUrl: any(named: 'downloadUrl'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) async => testResult);

      final result = await service.downloadDiagnostic(
        mockScope,
        downloadUrl: 'https://example.com/file',
      );

      expect(result, testResult);
    });

    test('rethrows TimeoutException unchanged', () async {
      when(() => mockScope.downloadDiagnostic(
            downloadUrl: any(named: 'downloadUrl'),
            timeout: any(named: 'timeout'),
          )).thenThrow(TimeoutException('Download timed out'));

      expect(
        () => service.downloadDiagnostic(
          mockScope,
          downloadUrl: 'https://example.com/file',
        ),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('maps UspError to ServiceError', () async {
      when(() => mockScope.downloadDiagnostic(
            downloadUrl: any(named: 'downloadUrl'),
            timeout: any(named: 'timeout'),
          )).thenThrow(_testUspError());

      expect(
        () => service.downloadDiagnostic(
          mockScope,
          downloadUrl: 'https://example.com/file',
        ),
        throwsA(isA<ServiceError>()),
      );
    });
  });
}
