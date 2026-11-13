import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_flow_plan.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_flow_shell.dart';

/// The PnP shell's back policy (#1511 P4 AC 5): one pure function from the
/// flow and a destination inside the shell to "let it through" or "go here
/// instead", over every (state, target) pair the plan allows. Since #1511 P5
/// Save is on the last setting step and Your Network comes after it, so the
/// table has a row for each side of the save.
void main() {
  const entry = '/pnp';
  const config = '/pnp/pnpConfig';
  String step(String id) => '$config/$id';
  const addNodes = '/pnp/pnpConfig/network/pnpAddNodes';

  String? policy(PnpState flow, String target) =>
      pnpBackPolicy(flow, Uri.parse(target));

  const withGuest = PnpFlowPlan(settingStepIds: ['wifi', 'guest']);
  const noGuest = PnpFlowPlan(settingStepIds: ['wifi']);
  const ready = WizardWifiReady(ssid: 'n', password: 'p');

  group('no wizard yet', () {
    // A reload on a step, or a step's URL typed in: nothing restarts the flow
    // there, so the page would wait on a spinner forever. The entry does.
    const fresh = PnpState(phase: AdminCheckingInternet());

    test('the entry is open', () {
      expect(policy(fresh, entry), isNull);
    });

    test('anything in the wizard goes to the entry', () {
      for (final target in [
        config,
        step('wifi'),
        step('guest'),
        step('network'),
        addNodes,
      ]) {
        expect(policy(fresh, target), entry, reason: target);
      }
    });
  });

  group('editing', () {
    const editing = PnpState(phase: WizardConfiguring(), plan: withGuest);

    test('every setting step in the plan is open, in either direction', () {
      for (final id in withGuest.settingStepIds) {
        expect(policy(editing, step(id)), isNull, reason: id);
      }
    });

    test('Your Network is not open yet: it comes after Save (#1511 P5)', () {
      expect(policy(editing, step('network')), step('wifi'));
      expect(policy(editing, addNodes), step('wifi'),
          reason: 'adding nodes is Your Network\'s');
    });

    test('the entry is open: leaving the wizard is config\'s exit to decide',
        () {
      // Back from the first step. `/pnp/pnpConfig`'s onExit asks whether to
      // log out; the policy does not decide that.
      expect(policy(editing, entry), isNull);
    });

    test('a step the plan does not have goes to the first step', () {
      const editingNoGuest =
          PnpState(phase: WizardConfiguring(), plan: noGuest);

      expect(policy(editingNoGuest, step('guest')), step('wifi'));
      expect(policy(editing, step('nightMode')), step('wifi'));
    });

    test('the wizard itself, with no step, goes to the first step', () {
      expect(policy(editing, config), step('wifi'));
    });

    test('a failed save is still editing', () {
      const failed = PnpState(
        phase: WizardConfiguring(saveError: null),
        plan: withGuest,
      );
      expect(policy(failed, step('wifi')), isNull);
    });
  });

  group('saving: the user stays where Save was pressed', () {
    // In flight, up to Your Network: the write, the reconnect it may need, and
    // the moment between the acknowledge and Your Network. The URL is the save
    // step's — the last setting step's.
    const inFlight = <PnpPhase>[
      WizardSaving(),
      WizardSaved(),
      WizardNeedsReconnect(newSsid: 'n', newPassword: 'p'),
      WizardTestingReconnect(attemptCount: 1, maxAttempts: 5),
    ];

    for (final phase in inFlight) {
      for (final plan in [withGuest, noGuest]) {
        final flow = PnpState(phase: phase, plan: plan);
        final saveStep = step(plan.saveStepId);

        test(
            '${phase.runtimeType}, ${plan.stepIds.join(' → ')}: the save '
            'step stays open, and everything else goes back to it', () {
          expect(policy(flow, saveStep), isNull);
          for (final target in {
            entry,
            config,
            ...plan.stepIds.map(step),
            addNodes,
          }..remove(saveStep)) {
            expect(policy(flow, target), saveStep, reason: target);
          }
        });
      }
    }
  });

  group('on Your Network (#1511 P5)', () {
    for (final plan in [withGuest, noGuest]) {
      final onYourNetwork =
          PnpState(phase: const WizardYourNetwork(ready: ready), plan: plan);
      final steps = plan.stepIds.join(' → ');

      test('$steps: Your Network and adding nodes are open', () {
        expect(policy(onYourNetwork, step('network')), isNull);
        expect(policy(onYourNetwork, addNodes), isNull);
      });

      test(
          '$steps: Back to a setting step is refused — the save is behind '
          'the user', () {
        for (final target in [
          entry,
          config,
          ...plan.settingStepIds.map(step),
        ]) {
          expect(policy(onYourNetwork, target), step('network'),
              reason: target);
        }
      });
    }
  });

  group('after Your Network: the firmware stage and the completion screen', () {
    const finishing = <PnpPhase>[
      WizardCheckingFirmware(),
      WizardUpdatingFirmware(),
      ready,
    ];

    for (final phase in finishing) {
      for (final plan in [withGuest, noGuest]) {
        final flow = PnpState(phase: phase, plan: plan);

        test(
            '${phase.runtimeType}, ${plan.stepIds.join(' → ')}: Your Network '
            'stays open, and nothing else', () {
          expect(policy(flow, step('network')), isNull);
          for (final target in [
            entry,
            config,
            ...plan.settingStepIds.map(step),
            // Adding nodes ended with Your Network's Done.
            addNodes,
          ]) {
            expect(policy(flow, target), step('network'), reason: target);
          }
        });
      }
    }
  });

  test('a location outside the PnP tree is not the policy\'s', () {
    const saving = PnpState(phase: WizardSaving(), plan: withGuest);

    expect(policy(saving, '/uspDashboard'), isNull);
    expect(policy(saving, '/pnpNoInternetConnection/pnp'), isNull);
  });
}
