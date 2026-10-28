import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/add_nodes/models/add_nodes_ui_models.dart';

void main() {
  group('AddNodesNodeUIModel', () {
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

  group('outcomeOf (#1738)', () {
    const alMac = 'aa:bb:cc:00:00:02';
    const bleMac = 'AA:BB:CC:00:00:01';

    AddNodesNodeUIModel node(OnboardingNodeStatus status,
            {String? al = alMac}) =>
        AddNodesNodeUIModel(
            bleMacAddress: bleMac, status: status, alMacAddress: al);

    AddNodesNodeOutcome outcome(
      OnboardingNodeStatus status,
      AddNodesStage stage, {
      String? al = alMac,
      bool joined = false,
      bool interrupted = false,
    }) =>
        outcomeOf(
          node(status, al: al),
          stage: stage,
          isJoined: (_) => joined,
          interrupted: interrupted ? const {bleMac} : const {},
        );

    const running = AddNodesStage.running;
    const awaiting = AddNodesStage.awaiting;
    const settled = AddNodesStage.settled;
    const added = AddNodesNodeOutcome.added;
    const joining = AddNodesNodeOutcome.joining;
    const failed = AddNodesNodeOutcome.failed;
    const notTried = AddNodesNodeOutcome.notTried;

    // #1738's table, for a node with an AL MAC that DataElements does not list
    // yet. Every status at every stage, so a status added to the enum fails
    // here until it is placed.
    const table =
        <OnboardingNodeStatus, Map<AddNodesStage, AddNodesNodeOutcome>>{
      OnboardingNodeStatus.pending: {
        running: notTried,
        awaiting: notTried,
        settled: notTried
      },
      OnboardingNodeStatus.notTargeted: {
        running: notTried,
        awaiting: notTried,
        settled: notTried
      },
      OnboardingNodeStatus.connecting: {
        running: joining,
        awaiting: failed,
        settled: failed
      },
      OnboardingNodeStatus.onboarding: {
        running: joining,
        awaiting: failed,
        settled: failed
      },
      OnboardingNodeStatus.onboarded: {
        running: joining,
        awaiting: joining,
        settled: failed
      },
      OnboardingNodeStatus.failedConnect: {
        running: failed,
        awaiting: failed,
        settled: failed
      },
      OnboardingNodeStatus.failedRegistrar: {
        running: failed,
        awaiting: failed,
        settled: failed
      },
      OnboardingNodeStatus.failedWps: {
        running: joining,
        awaiting: joining,
        settled: failed
      },
      OnboardingNodeStatus.lostConnection: {
        running: joining,
        awaiting: joining,
        settled: failed
      },
      OnboardingNodeStatus.cancelled: {
        running: notTried,
        awaiting: notTried,
        settled: notTried
      },
      OnboardingNodeStatus.unknown: {
        running: failed,
        awaiting: failed,
        settled: failed
      },
    };

    test('the table names every status', () {
      expect(table.keys.toSet(), OnboardingNodeStatus.values.toSet());
    });

    for (final row in table.entries) {
      for (final cell in row.value.entries) {
        test('${row.key.name} while ${cell.key.name} is ${cell.value.name}',
            () {
          expect(outcome(row.key, cell.key), cell.value);
        });
      }
    }

    test('a node DataElements lists is added, whatever the router reads', () {
      for (final status in OnboardingNodeStatus.values) {
        for (final stage in AddNodesStage.values) {
          expect(outcome(status, stage, joined: true), added,
              reason: '${status.name} / ${stage.name}');
        }
      }
    });

    test('a node the flow stopped at its limit is failed, unless it joined',
        () {
      for (final status in OnboardingNodeStatus.values) {
        for (final stage in AddNodesStage.values) {
          expect(outcome(status, stage, interrupted: true), failed,
              reason: '${status.name} / ${stage.name}');
          expect(outcome(status, stage, interrupted: true, joined: true), added,
              reason: 'joined anyway: ${status.name} / ${stage.name}');
        }
      }
    });

    group('with no AL MAC, so nothing can look it up in DataElements', () {
      test('onboarded is taken at the session\'s word', () {
        for (final stage in AddNodesStage.values) {
          expect(
              outcome(OnboardingNodeStatus.onboarded, stage, al: null), added,
              reason: stage.name);
        }
      });

      test('a node that may join late is joining only while the session runs',
          () {
        for (final status in [
          OnboardingNodeStatus.failedWps,
          OnboardingNodeStatus.lostConnection,
        ]) {
          expect(outcome(status, running, al: null), joining,
              reason: status.name);
          expect(outcome(status, awaiting, al: null), failed,
              reason: '${status.name}: no AL MAC to wait for');
          expect(outcome(status, settled, al: null), failed,
              reason: status.name);
        }
      });
    });
  });
}
