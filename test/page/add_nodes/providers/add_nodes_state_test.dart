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
}
