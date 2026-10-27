import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/add_nodes/models/add_nodes_ui_models.dart';

void main() {
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

    test('is never both onboarded and still to join', () {
      for (final status in OnboardingNodeStatus.values) {
        final node = withStatus(status);
        expect(node.isOnboarded && node.mayStillJoin, isFalse,
            reason: status.name);
      }
    });

    test('compares by value', () {
      const a = AddNodesNodeUIModel(
        bleMacAddress: 'AA:BB:CC:00:00:01',
        status: OnboardingNodeStatus.onboarded,
        modelNumber: 'M60',
        rssi: -40,
        alMacAddress: 'aa:bb:cc:00:00:02',
      );
      const same = AddNodesNodeUIModel(
        bleMacAddress: 'AA:BB:CC:00:00:01',
        status: OnboardingNodeStatus.onboarded,
        modelNumber: 'M60',
        rssi: -40,
        alMacAddress: 'aa:bb:cc:00:00:02',
      );
      const otherAlMac = AddNodesNodeUIModel(
        bleMacAddress: 'AA:BB:CC:00:00:01',
        status: OnboardingNodeStatus.onboarded,
        modelNumber: 'M60',
        rssi: -40,
        alMacAddress: 'aa:bb:cc:00:00:03',
      );

      expect(a, same);
      expect(a, isNot(otherAlMac));
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

    test('is unavailable only when stopped and refusing to run', () {
      // The two answers that say this router cannot run a session, as opposed
      // to how its last one went.
      const refusals = {
        OnboardingSessionResult.backendUnavailable,
        OnboardingSessionResult.unsupportedRole,
      };
      for (final status in OnboardingSessionStatus.values) {
        for (final result in OnboardingSessionResult.values) {
          final session = read(status, result);
          expect(
            session.isUnavailable,
            !session.isRunning && refusals.contains(result),
            reason: '${status.name} / ${result.name}',
          );
        }
      }
    });

    test('is never unavailable while a session runs', () {
      // A refusal written over a running session's result is a request this
      // router turned away, not this router being unable to run one.
      for (final status in [
        OnboardingSessionStatus.scanning,
        OnboardingSessionStatus.onboarding,
      ]) {
        for (final result in OnboardingSessionResult.values) {
          expect(read(status, result).isUnavailable, isFalse,
              reason: '${status.name} / ${result.name}');
        }
      }
    });

    test('compares by value, the session counter included', () {
      expect(
        read(OnboardingSessionStatus.complete, OnboardingSessionResult.success),
        read(OnboardingSessionStatus.complete, OnboardingSessionResult.success),
      );
      expect(
        const OnboardingSessionUIModel(
            status: OnboardingSessionStatus.complete,
            result: OnboardingSessionResult.success,
            session: 1),
        isNot(const OnboardingSessionUIModel(
            status: OnboardingSessionStatus.complete,
            result: OnboardingSessionResult.success,
            session: 2)),
      );
    });
  });
}
