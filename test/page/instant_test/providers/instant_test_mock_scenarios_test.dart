// Tests that core state factory variants produce the expected verdict shape.
// Uses InstantTestStateData factories directly — no loadMockScenario() needed,
// since the USP provider doesn't have network-call-based mock scenarios.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_test/models/verdict.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_state.dart';
import 'package:privacy_gui/page/instant_test/services/browser_diagnostic_service.dart';

import '../../../mocks/test_data/instant_test_state_data.dart';

void main() {
  group('InstantTestStateData — allClearState', () {
    late InstantTestState state;
    setUp(() => state = InstantTestStateData.allClearState());

    test('phase is complete', () {
      expect(state.phase, InstantTestLoadPhase.complete);
    });

    test('verdict is not null', () {
      expect(state.verdict, isNotNull);
    });

    test('verdict is all-clear', () {
      expect(state.verdict!.isAllClear, isTrue);
    });

    test('verdictIsPreliminary is false', () {
      expect(state.verdictIsPreliminary, isFalse);
    });
  });

  group('InstantTestStateData — wanDisconnectedState', () {
    late InstantTestState state;
    setUp(() => state = InstantTestStateData.wanDisconnectedState());

    test('phase is complete', () {
      expect(state.phase, InstantTestLoadPhase.complete);
    });

    test('verdict is not null', () {
      expect(state.verdict, isNotNull);
    });

    test('verdict has critical WAN finding', () {
      final findings = state.verdict!.findings;
      expect(findings, isNotEmpty);
      expect(findings.first.priority, VerdictPriority.critical);
      expect(findings.first.headline.toLowerCase(), contains('internet'));
    });

    test('wanStatus reports not connected', () {
      expect(state.wanStatus?.isUp, isFalse);
    });
  });

  group('InstantTestStateData — idleState', () {
    late InstantTestState state;
    setUp(() => state = InstantTestStateData.idleState());

    test('phase is idle', () {
      expect(state.phase, InstantTestLoadPhase.idle);
    });

    test('verdict is null', () {
      expect(state.verdict, isNull);
    });

    test('clients is empty', () {
      expect(state.clients, isEmpty);
    });
  });

  group('InstantTestState — copyWith smoke test', () {
    test('phase update propagates', () {
      final s = InstantTestStateData.idleState();
      final updated = s.copyWith(phase: InstantTestLoadPhase.loading);
      expect(updated.phase, InstantTestLoadPhase.loading);
      expect(updated.verdict, isNull); // other fields unchanged
    });

    test('speedTest update propagates', () {
      final s = InstantTestStateData.allClearState();
      const newSpeed = SpeedTestResult(
          downloadMbps: 200, uploadMbps: 80, latencyMs: 8, jitterMs: 1);
      final updated = s.copyWith(speedTest: newSpeed);
      expect(updated.speedTest?.downloadMbps, 200);
      expect(updated.phase, s.phase); // phase unchanged
    });
  });
}
