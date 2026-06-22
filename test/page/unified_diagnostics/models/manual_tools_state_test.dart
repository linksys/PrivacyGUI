import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/models/operate_result.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/manual_tools_state.dart';

void main() {
  const samplePing = PingResult(
    host: '8.8.8.8',
    successCount: 3,
    failureCount: 0,
    avgResponseTime: 12,
    minResponseTime: 10,
    maxResponseTime: 14,
    status: 'Complete',
  );

  const sampleTraceroute = TracerouteResult(
    host: 'google.com',
    status: 'Complete',
    hops: [],
  );

  const sampleNsLookup = NsLookupResult(
    hostName: 'example.com',
    status: 'Complete',
    successCount: 1,
    answers: [],
  );

  group('NetworkDiagnosticsState', () {
    test('default state is idle on ping tab', () {
      const state = NetworkDiagnosticsState();
      expect(state.activeTab, DiagnosticType.ping);
      expect(state.status, DiagnosticStatus.idle);
      expect(state.host, '');
      expect(state.pingCount, 3);
      expect(state.maxHops, 30);
      expect(state.dnsServer, '');
      expect(state.isRunning, isFalse);
      expect(state.hasResult, isFalse);
    });

    group('isRunning', () {
      test('only true when status is running', () {
        for (final status in DiagnosticStatus.values) {
          final s = const NetworkDiagnosticsState().copyWith(status: status);
          expect(s.isRunning, status == DiagnosticStatus.running);
        }
      });
    });

    group('hasResult', () {
      test('false unless completed AND a result is present', () {
        const completedNoResult =
            NetworkDiagnosticsState(status: DiagnosticStatus.completed);
        expect(completedNoResult.hasResult, isFalse);
      });

      test('true when completed and pingResult is present', () {
        final state = const NetworkDiagnosticsState().copyWith(
          status: DiagnosticStatus.completed,
          pingResult: samplePing,
        );
        expect(state.hasResult, isTrue);
      });

      test('false when result is present but status is not completed', () {
        final state = const NetworkDiagnosticsState().copyWith(
          status: DiagnosticStatus.running,
          pingResult: samplePing,
        );
        expect(state.hasResult, isFalse);
      });
    });

    group('copyWith', () {
      const baseline = NetworkDiagnosticsState(
        host: '8.8.8.8',
        pingCount: 5,
        maxHops: 15,
        dnsServer: '1.1.1.1',
      );

      test('updates only the fields explicitly passed', () {
        final next = baseline.copyWith(host: 'google.com');
        expect(next.host, 'google.com');
        expect(next.pingCount, baseline.pingCount);
        expect(next.maxHops, baseline.maxHops);
        expect(next.dnsServer, baseline.dnsServer);
      });

      test('clearError resets error to null', () {
        final withError =
            baseline.copyWith(error: const UnexpectedError(detail: 'oops'));
        expect(withError.error, isA<UnexpectedError>());
        final cleared = withError.copyWith(clearError: true);
        expect(cleared.error, isNull);
      });

      test('clearPingResult resets pingResult to null', () {
        final withResult = baseline.copyWith(pingResult: samplePing);
        expect(withResult.pingResult, isNotNull);
        expect(withResult.copyWith(clearPingResult: true).pingResult, isNull);
      });

      test('clearTracerouteResult resets tracerouteResult to null', () {
        final withResult =
            baseline.copyWith(tracerouteResult: sampleTraceroute);
        expect(withResult.tracerouteResult, isNotNull);
        expect(
          withResult.copyWith(clearTracerouteResult: true).tracerouteResult,
          isNull,
        );
      });

      test('clearNsLookupResult resets nsLookupResult to null', () {
        final withResult = baseline.copyWith(nsLookupResult: sampleNsLookup);
        expect(withResult.nsLookupResult, isNotNull);
        expect(
          withResult.copyWith(clearNsLookupResult: true).nsLookupResult,
          isNull,
        );
      });
    });

    test('Equatable equality compares all fields', () {
      const a = NetworkDiagnosticsState(host: '1.1.1.1', pingCount: 5);
      const b = NetworkDiagnosticsState(host: '1.1.1.1', pingCount: 5);
      const c = NetworkDiagnosticsState(host: '1.1.1.1', pingCount: 3);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
