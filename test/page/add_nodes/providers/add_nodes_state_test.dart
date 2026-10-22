import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/add_nodes/models/add_nodes_ui_models.dart';
import 'package:privacy_gui/page/add_nodes/providers/add_nodes_state.dart';

void main() {
  group('AddNodesState - phases', () {
    test('starts out checking, with nothing found', () {
      const state = AddNodesState();

      expect(state.phase, AddNodesPhase.checking);
      expect(state.nodes, isEmpty);
      expect(state.joinedNodeKeys, isEmpty);
      expect(state.sessionResult, isNull);
      expect(state.error, isNull);
    });

    test('is running only while a session this flow started is in progress',
        () {
      const running = {
        AddNodesPhase.starting,
        AddNodesPhase.searching,
        AddNodesPhase.onboarding,
      };
      for (final phase in AddNodesPhase.values) {
        expect(AddNodesState(phase: phase).isRunning, running.contains(phase),
            reason: phase.name);
      }
    });

    test('can start on entry and after a session that ended without a node',
        () {
      const startable = {
        AddNodesPhase.ready,
        AddNodesPhase.noNodesFound,
        AddNodesPhase.failed,
        // The page offers Try again after a stop, so start() must take it.
        AddNodesPhase.cancelled,
      };
      for (final phase in AddNodesPhase.values) {
        expect(AddNodesState(phase: phase).canStart, startable.contains(phase),
            reason: phase.name);
      }
    });
  });

  group('AddNodesState - copyWith', () {
    const node = AddNodesNodeUIModel(
      bleMacAddress: 'AA:BB:CC:00:00:01',
      status: OnboardingNodeStatus.onboarded,
    );
    const full = AddNodesState(
      phase: AddNodesPhase.joined,
      nodes: [node],
      joinedNodeKeys: {'AABBCC000002'},
      sessionResult: OnboardingSessionResult.success,
      error: NetworkError(),
    );

    test('keeps every field it is not given', () {
      expect(full.copyWith(), full);
    });

    test('replaces the fields it is given', () {
      final next = full.copyWith(
        phase: AddNodesPhase.failed,
        sessionResult: OnboardingSessionResult.timedOut,
      );

      expect(next.phase, AddNodesPhase.failed);
      expect(next.sessionResult, OnboardingSessionResult.timedOut);
      expect(next.nodes, [node]);
    });

    test('clears the session result and the error on request', () {
      final next = full.copyWith(clearSessionResult: true, clearError: true);

      expect(next.sessionResult, isNull);
      expect(next.error, isNull);
      expect(next.phase, AddNodesPhase.joined);
    });

    test('compares by value', () {
      expect(
        const AddNodesState(phase: AddNodesPhase.ready),
        const AddNodesState(phase: AddNodesPhase.ready),
      );
      expect(
        const AddNodesState(phase: AddNodesPhase.ready),
        isNot(const AddNodesState(phase: AddNodesPhase.busy)),
      );
    });
  });

  group('AddNodesNodeUIModel', () {
    AddNodesNodeUIModel withStatus(OnboardingNodeStatus status) =>
        AddNodesNodeUIModel(bleMacAddress: 'AA:BB:CC:00:00:01', status: status);

    test('is onboarded only once it reached the backhaul', () {
      for (final status in OnboardingNodeStatus.values) {
        expect(withStatus(status).isOnboarded,
            status == OnboardingNodeStatus.onboarded,
            reason: status.name);
      }
    });

    test('may still join only when the session gave up waiting for it', () {
      // Told to onboard, and either out of WPS time or off its BLE link — the
      // two failures the firmware corrects when the node joins late.
      const late = {
        OnboardingNodeStatus.failedWps,
        OnboardingNodeStatus.lostConnection,
      };
      for (final status in OnboardingNodeStatus.values) {
        expect(withStatus(status).mayStillJoin, late.contains(status),
            reason: status.name);
      }
    });
  });

  group('OnboardingSessionUIModel', () {
    OnboardingSessionUIModel read(
      OnboardingSessionStatus status,
      OnboardingSessionResult result,
    ) =>
        OnboardingSessionUIModel(status: status, result: result, session: 1);

    test('is running while scanning or onboarding, whatever the result', () {
      for (final status in OnboardingSessionStatus.values) {
        for (final result in OnboardingSessionResult.values) {
          expect(
            read(status, result).isRunning,
            status == OnboardingSessionStatus.scanning ||
                status == OnboardingSessionStatus.onboarding,
            reason: '${status.name} / ${result.name}',
          );
        }
      }
    });

    test('is unavailable when it is not running and says it cannot run', () {
      expect(
          read(OnboardingSessionStatus.idle,
                  OnboardingSessionResult.backendUnavailable)
              .isUnavailable,
          isTrue);
      expect(
          read(OnboardingSessionStatus.idle,
                  OnboardingSessionResult.unsupportedRole)
              .isUnavailable,
          isTrue);
      expect(
          read(OnboardingSessionStatus.idle, OnboardingSessionResult.none)
              .isUnavailable,
          isFalse);
      // A refusal written over a running session's result is not this router
      // being unable to run one.
      expect(
          read(OnboardingSessionStatus.scanning,
                  OnboardingSessionResult.unsupportedRole)
              .isUnavailable,
          isFalse);
    });
  });
}
