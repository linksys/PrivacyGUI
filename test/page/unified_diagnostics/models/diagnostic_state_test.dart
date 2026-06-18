import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/speed_test_state.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/diagnostic_state.dart';

void main() {
  group('DiagnosticStep', () {
    test('has correct enum values', () {
      expect(DiagnosticStep.values.length, greaterThan(10));
      expect(DiagnosticStep.idle, isNotNull);
      expect(DiagnosticStep.selectFlow, isNotNull);
      expect(DiagnosticStep.checkingWanStatus, isNotNull);
      expect(DiagnosticStep.runningSpeedTest, isNotNull);
      expect(DiagnosticStep.showingResults, isNotNull);
    });
  });

  group('RecommendationUIModel', () {
    test('creates with required fields', () {
      final rec = RecommendationUIModel(
        id: 'test_rec',
        titleKey: 'title',
        descriptionKey: 'desc',
      );

      expect(rec.id, 'test_rec');
      expect(rec.titleKey, 'title');
      expect(rec.descriptionKey, 'desc');
      expect(rec.priority, 0);
      expect(rec.actionId, isNull);
    });

    test('creates with all fields', () {
      final rec = RecommendationUIModel(
        id: 'test_rec',
        titleKey: 'title',
        descriptionKey: 'desc',
        priority: 5,
        actionId: 'doAction',
      );

      expect(rec.priority, 5);
      expect(rec.actionId, 'doAction');
    });

    test('equality works', () {
      final rec1 = RecommendationUIModel(
        id: 'test',
        titleKey: 'title',
        descriptionKey: 'desc',
      );
      final rec2 = RecommendationUIModel(
        id: 'test',
        titleKey: 'title',
        descriptionKey: 'desc',
      );
      final rec3 = RecommendationUIModel(
        id: 'other',
        titleKey: 'title',
        descriptionKey: 'desc',
      );

      expect(rec1, equals(rec2));
      expect(rec1, isNot(equals(rec3)));
    });
  });

  group('UnifiedDiagnosticsState', () {
    test('creates with default values', () {
      final state = UnifiedDiagnosticsState();

      expect(state.step, DiagnosticStep.idle);
      expect(state.flow, isNull);
      expect(state.results, isEmpty);
      expect(state.speedTest, isNull);
      expect(state.recommendations, isEmpty);
      expect(state.error, isNull);
      expect(state.progress, isNull);
    });

    test('isRunning returns correct value', () {
      expect(
        UnifiedDiagnosticsState(step: DiagnosticStep.idle).isRunning,
        false,
      );
      expect(
        UnifiedDiagnosticsState(step: DiagnosticStep.selectFlow).isRunning,
        false,
      );
      expect(
        UnifiedDiagnosticsState(step: DiagnosticStep.showingResults).isRunning,
        false,
      );
      expect(
        UnifiedDiagnosticsState(step: DiagnosticStep.completed).isRunning,
        false,
      );
      expect(
        UnifiedDiagnosticsState(step: DiagnosticStep.checkingWanStatus)
            .isRunning,
        true,
      );
      expect(
        UnifiedDiagnosticsState(step: DiagnosticStep.runningSpeedTest)
            .isRunning,
        true,
      );
    });

    test('copyWith preserves values', () {
      final initial = UnifiedDiagnosticsState(
        step: DiagnosticStep.checkingWanStatus,
        flow: DiagnosticFlow.internet,
        error: const NetworkError(detail: 'test error'),
      );

      final copied = initial.copyWith(step: DiagnosticStep.pingGateway);

      expect(copied.step, DiagnosticStep.pingGateway);
      expect(copied.flow, DiagnosticFlow.internet);
      expect(copied.error, isA<NetworkError>());
    });

    test('copyWith clears error when requested', () {
      final initial = UnifiedDiagnosticsState(
        error: const NetworkError(detail: 'test error'),
      );

      final cleared = initial.copyWith(clearError: true);

      expect(cleared.error, isNull);
    });

    test('copyWith clears speedTest when requested', () {
      final speedTest = SpeedTestResult(
        serverHost: 'Test Server',
        latencyMs: 20,
        downloadStatus: 'Complete',
        downloadBps: 100000000,
        downloadBytes: 10000000,
        downloadDurationMs: 1000,
        uploadStatus: 'Complete',
        uploadBps: 50000000,
        uploadBytes: 5000000,
        uploadDurationMs: 1000,
      );

      final initial = UnifiedDiagnosticsState(speedTest: speedTest);
      final cleared = initial.copyWith(clearSpeedTest: true);

      expect(initial.speedTest, isNotNull);
      expect(cleared.speedTest, isNull);
    });

    test('equality works', () {
      final state1 = UnifiedDiagnosticsState(
        step: DiagnosticStep.idle,
        flow: DiagnosticFlow.internet,
      );
      final state2 = UnifiedDiagnosticsState(
        step: DiagnosticStep.idle,
        flow: DiagnosticFlow.internet,
      );
      final state3 = UnifiedDiagnosticsState(
        step: DiagnosticStep.idle,
        flow: DiagnosticFlow.deviceIssues,
      );

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });
  });
}
