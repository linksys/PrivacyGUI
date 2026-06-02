// Tests for flow step transitions and key state changes.
// Uses pure Dart — no Flutter widgets, no network.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/instant_test/models/verdict.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_state.dart';
import 'package:privacy_gui/page/instant_test/services/browser_diagnostic_service.dart';

import '../../../mocks/test_data/instant_test_state_data.dart';

void main() {
  // ── InstantTestState transitions ──────────────────────────────────────────

  group('InstantTestState — phase transitions', () {
    test('idle → loading via copyWith', () {
      const s = InstantTestState();
      final loading = s.copyWith(phase: InstantTestLoadPhase.loading);
      expect(loading.phase, InstantTestLoadPhase.loading);
      expect(loading.verdict, isNull);
    });

    test('loading → uspLoaded adds clients and wanStatus', () {
      const s = InstantTestState(phase: InstantTestLoadPhase.loading);
      final wan = InstantTestStateData.connectedWan();
      final clients = <DeviceUIModel>[InstantTestStateData.wifiDevice()];
      final loaded = s.copyWith(
        phase: InstantTestLoadPhase.uspLoaded,
        wanStatus: wan,
        clients: clients,
      );
      expect(loaded.phase, InstantTestLoadPhase.uspLoaded);
      expect(loaded.wanStatus?.isUp, isTrue);
      expect(loaded.clients, hasLength(1));
    });

    test('complete phase sets completedAt', () {
      final s = InstantTestState(
        phase: InstantTestLoadPhase.uspLoaded,
        wanStatus: InstantTestStateData.connectedWan(),
      );
      final now = DateTime(2026, 6, 2);
      final complete = s.copyWith(
        phase: InstantTestLoadPhase.complete,
        completedAt: now,
        verdictIsPreliminary: false,
      );
      expect(complete.phase, InstantTestLoadPhase.complete);
      expect(complete.completedAt, now);
      expect(complete.verdictIsPreliminary, isFalse);
    });
  });

  // ── VerdictEngine integration in state ───────────────────────────────────

  group('InstantTestState — verdict computed from WAN state', () {
    test('allClearState has non-null passing verdict', () {
      final s = InstantTestStateData.allClearState();
      expect(s.verdict, isNotNull);
      expect(s.verdict!.isAllClear, isTrue);
      expect(s.verdict!.checksRun, greaterThan(0));
    });

    test('wanDisconnectedState has critical finding', () {
      final s = InstantTestStateData.wanDisconnectedState();
      expect(s.verdict, isNotNull);
      expect(s.verdict!.findings.first.priority, VerdictPriority.critical);
    });

    test('allClearState verdict checksRun >= 5', () {
      final s = InstantTestStateData.allClearState();
      expect(s.verdict!.checksRun, greaterThanOrEqualTo(5));
    });
  });

  // ── Speed test result accumulation ────────────────────────────────────────

  group('InstantTestState — speed test results', () {
    test('speedTest copyWith updates download/upload/latency', () {
      const s = InstantTestState();
      const result = SpeedTestResult(
          downloadMbps: 95.5, uploadMbps: 40.2, latencyMs: 18, jitterMs: 3);
      final updated = s.copyWith(speedTest: result);
      expect(updated.speedTest?.downloadMbps, 95.5);
      expect(updated.speedTest?.uploadMbps, 40.2);
      expect(updated.speedTest?.latencyMs, 18);
    });

    test('routerInternetResult copyWith is independent from speedTest', () {
      const s = InstantTestState();
      const speedResult = SpeedTestResult(
          downloadMbps: 95.5, uploadMbps: 40.0, latencyMs: 18, jitterMs: 2);
      final updated = s.copyWith(speedTest: speedResult);
      expect(updated.routerInternetResult, isNull);
      expect(updated.speedTest?.downloadMbps, 95.5);
    });
  });

  // ── Browser test step tracking ────────────────────────────────────────────

  group('InstantTestState — browser test steps', () {
    test('browserTestStep progresses through expected values', () {
      const steps = ['gateway', 'dns', 'speed', 'speed:router-internet', 'complete'];
      InstantTestState s = const InstantTestState();
      for (final step in steps) {
        s = s.copyWith(browserTestStep: step);
        expect(s.browserTestStep, step);
      }
    });
  });

  // ── Restart tracking ──────────────────────────────────────────────────────

  group('InstantTestState — restart tracking', () {
    test('hasRestartedThisSession starts false', () {
      expect(const InstantTestState().hasRestartedThisSession, isFalse);
    });

    test('copyWith can set hasRestartedThisSession', () {
      const s = InstantTestState();
      final updated = s.copyWith(hasRestartedThisSession: true);
      expect(updated.hasRestartedThisSession, isTrue);
    });

    test('isRestarting transitions correctly', () {
      const s = InstantTestState();
      final restarting = s.copyWith(isRestarting: true);
      expect(restarting.isRestarting, isTrue);
      final done = restarting.copyWith(isRestarting: false, hasRestartedThisSession: true);
      expect(done.isRestarting, isFalse);
      expect(done.hasRestartedThisSession, isTrue);
    });
  });

  // ── Device scores ─────────────────────────────────────────────────────────

  group('InstantTestState — device scores', () {
    test('allClearState has device scores for wifi devices', () {
      final s = InstantTestStateData.allClearState();
      expect(s.deviceScores, isNotEmpty);
      expect(s.deviceScores.first.device.isWifi, isTrue);
    });

    test('device scores are non-empty and bucket is computed', () {
      final s = InstantTestStateData.allClearState();
      // wifiDevice() has signal -52 dBm, 450 Mbps → at-risk bucket (score ≈ 49)
      expect(s.deviceScores.first.bucket, isNotNull);
      expect(s.deviceScores.first.score, greaterThan(0));
    });
  });
}
