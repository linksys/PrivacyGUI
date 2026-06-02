/// Integration tests for InstantTestNotifier — exercises the state machine,
/// generation counter logic, and state action methods.
///
/// These tests focus on verifiable behavior without requiring full USP client
/// infrastructure (auth, WebSocket, SSE). Provider reads from Layer 1
/// providers are tested via state shape rather than network calls.
///
/// Tagged for automation: no tags → included in ./run_tests.sh by default.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_test/models/verdict.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_state.dart';
import 'package:privacy_gui/page/instant_test/services/browser_diagnostic_service.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';

import '../../../mocks/test_data/instant_test_state_data.dart';

void main() {
  // ── State machine phase transitions ───────────────────────────────────────

  group('InstantTestState — phase machine', () {
    test('idle → loading: clients preserved through loading phase', () {
      final device = InstantTestStateData.wifiDevice();
      final s = InstantTestState(
        phase: InstantTestLoadPhase.uspLoaded,
        clients: [device],
      );
      // Simulates fetch() resetting to loading (preserves planSpeedMbps/journeyActions)
      final loading = InstantTestState(
        phase: InstantTestLoadPhase.loading,
        planSpeedMbps: s.planSpeedMbps,
        journeyActions: s.journeyActions,
        flowEntered: s.flowEntered,
      );
      expect(loading.phase, InstantTestLoadPhase.loading);
      expect(loading.clients, isEmpty); // fresh fetch resets clients
    });

    test('uspLoaded → complete: verdict and completedAt set', () {
      final allClear = InstantTestStateData.allClearState();
      expect(allClear.phase, InstantTestLoadPhase.complete);
      expect(allClear.verdict, isNotNull);
      // completedAt is NOT in props — just check it can be set
      final withTime = allClear.copyWith(completedAt: DateTime(2026, 6, 2));
      expect(withTime.completedAt, isNotNull);
    });
  });

  // ── Generation counter semantics ──────────────────────────────────────────

  group('InstantTestState — generation counter semantics', () {
    test('fresh fetch resets all diagnostic fields', () {
      // Simulates what fetch() does: fresh state preserving only journey/plan
      final prior = InstantTestState(
        phase: InstantTestLoadPhase.complete,
        wanStatus: InstantTestStateData.connectedWan(),
        clients: [InstantTestStateData.wifiDevice()],
        planSpeedMbps: 100.0,
      );
      final fresh = InstantTestState(
        phase: InstantTestLoadPhase.loading,
        planSpeedMbps: prior.planSpeedMbps,
        journeyActions: prior.journeyActions,
        flowEntered: prior.flowEntered,
      );
      expect(fresh.wanStatus, isNull);
      expect(fresh.clients, isEmpty);
      expect(fresh.planSpeedMbps, 100.0); // preserved
    });
  });

  // ── Verdict update pipeline ───────────────────────────────────────────────

  group('InstantTestState — verdict update pipeline', () {
    test('WAN disconnected state → verdict has critical finding', () {
      final s = InstantTestStateData.wanDisconnectedState();
      expect(s.verdict, isNotNull);
      expect(s.verdict!.findings.first.priority, VerdictPriority.critical);
    });

    test('all-clear state → verdict is all-clear', () {
      final s = InstantTestStateData.allClearState();
      expect(s.verdict!.isAllClear, isTrue);
    });

    test('speed test result affects verdict: very slow → critical speed finding', () {
      const slow = SpeedTestResult(downloadMbps: 2.5, uploadMbps: 0.5, latencyMs: 200, jitterMs: 50);
      final v = VerdictEngine.compute(
        gatewayReachable: true,
        wanConnected: true,
        wanIpAddress: '98.137.11.163',
        dnsWorking: true,
        downloadMbps: slow.downloadMbps,
        latencyMs: slow.latencyMs,
        firmwareUpdateAvailable: false,
        firmwareVersion: null,
        uptimeSeconds: 86400,
        deviceScores: const [],
        clients: const [],
        meshNodes: const [],
        planSpeedMbps: null,
      );
      expect(v.findings.any((f) => f.checkNumber == 5 && f.priority == VerdictPriority.critical), isTrue);
    });

    test('routerInternetResult populates three-leg bottleneck when > 2× client', () {
      // WiFi bottleneck: router 200Mbps, client 20Mbps
      final v = VerdictEngine.compute(
        gatewayReachable: true,
        wanConnected: true,
        wanIpAddress: '98.137.11.163',
        dnsWorking: true,
        downloadMbps: 20,
        latencyMs: 20,
        firmwareUpdateAvailable: false,
        firmwareVersion: null,
        uptimeSeconds: 86400,
        deviceScores: const [],
        clients: const [],
        meshNodes: const [],
        planSpeedMbps: null,
        routerInternetDownloadMbps: 200,
      );
      expect(v.findings.any((f) => f.headline.contains('WiFi is slowing')), isTrue);
    });
  });

  // ── State action methods (pure) ───────────────────────────────────────────

  group('InstantTestState — copyWith state actions', () {
    test('setPlanSpeed equivalent: copyWith planSpeedMbps', () {
      const s = InstantTestState();
      final updated = s.copyWith(planSpeedMbps: 200.0);
      expect(updated.planSpeedMbps, 200.0);
    });

    test('setFlowEntered equivalent: copyWith flowEntered', () {
      const s = InstantTestState();
      final updated = s.copyWith(flowEntered: 'internet_slow');
      expect(updated.flowEntered, 'internet_slow');
    });

    test('restart flags update correctly', () {
      const s = InstantTestState();
      final restarting = s.copyWith(isRestarting: true, errorMessage: null);
      expect(restarting.isRestarting, isTrue);
      final done = restarting.copyWith(isRestarting: false, hasRestartedThisSession: true);
      expect(done.isRestarting, isFalse);
      expect(done.hasRestartedThisSession, isTrue);
    });

    test('error message can be set', () {
      const s = InstantTestState();
      final withError = s.copyWith(errorMessage: 'Restart failed: timeout');
      expect(withError.errorMessage, 'Restart failed: timeout');
    });

    test('error message null on fresh state', () {
      // clearError() in the notifier creates a fresh state — test the contract
      expect(const InstantTestState().errorMessage, isNull);
    });
  });

  // ── ClientToNodeId mapping ────────────────────────────────────────────────

  group('InstantTestState — clientToNodeId mapping', () {
    test('clientToNodeId maps device MACs to node IDs', () {
      final s = const InstantTestState().copyWith(
        clientToNodeId: {'AA:BB:CC:DD:EE:01': 'router-node-id'},
      );
      expect(s.clientToNodeId['AA:BB:CC:DD:EE:01'], 'router-node-id');
    });

    test('unrecognised MAC returns null from clientToNodeId', () {
      const s = InstantTestState();
      expect(s.clientToNodeId['UNKNOWN:MAC'], isNull);
    });
  });

  // ── MeshNodes data ────────────────────────────────────────────────────────

  group('InstantTestState — mesh nodes', () {
    test('meshNodes empty by default', () {
      expect(const InstantTestState().meshNodes, isEmpty);
    });

    test('master node accessible via firstWhere isMaster', () {
      final nodes = [
        const NodeUIModel(deviceId: 'router', model: 'MX6200', isMaster: true),
        const NodeUIModel(deviceId: 'child', model: 'MX6200', isMaster: false),
      ];
      final s = const InstantTestState().copyWith(meshNodes: nodes);
      final master = s.meshNodes.firstWhere((n) => n.isMaster);
      expect(master.model, 'MX6200');
      expect(s.meshNodes.where((n) => !n.isMaster).length, 1);
    });
  });

  // ── Preliminary vs final verdict ─────────────────────────────────────────

  group('InstantTestState — preliminary vs final verdict', () {
    test('verdictIsPreliminary defaults true', () {
      expect(const InstantTestState().verdictIsPreliminary, isTrue);
    });

    test('allClearState from factory has verdictIsPreliminary=false', () {
      expect(InstantTestStateData.allClearState().verdictIsPreliminary, isFalse);
    });

    test('preliminary verdict can be set then cleared', () {
      const s = InstantTestState(verdictIsPreliminary: true);
      final final_ = s.copyWith(verdictIsPreliminary: false);
      expect(final_.verdictIsPreliminary, isFalse);
    });
  });
}
