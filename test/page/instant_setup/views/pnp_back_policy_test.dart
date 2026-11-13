import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_flow_plan.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_flow_shell.dart';

/// The PnP shell's back policy (#1511 P4 AC 5): one pure function from the
/// flow and a destination inside the shell to "let it through" or "go here
/// instead", over every (state, target) pair the plan allows.
void main() {
  const entry = '/pnp';
  const config = '/pnp/pnpConfig';
  String step(String id) => '$config/$id';
  const addNodes = '/pnp/pnpConfig/network/pnpAddNodes';

  String? policy(PnpState flow, String target) =>
      pnpBackPolicy(flow, Uri.parse(target));

  const withGuest = PnpFlowPlan(settingStepIds: ['wifi', 'guest']);
  const noGuest = PnpFlowPlan(settingStepIds: ['wifi']);

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

    test('every step in the plan is open, in either direction', () {
      for (final id in withGuest.stepIds) {
        expect(policy(editing, step(id)), isNull, reason: id);
      }
      expect(policy(editing, addNodes), isNull,
          reason: 'adding nodes is part of Your Network');
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
      expect(policy(failed, step('guest')), isNull);
    });
  });

  group('past editing', () {
    // In flight (saving, reconnect testing, the firmware stage) or past the
    // irreversible point (reconnect, done): the user stays where Save was
    // pressed — Your Network, until #1511 P5 moves Save.
    const pastEditing = <PnpPhase>[
      WizardSaving(),
      WizardSaved(),
      WizardNeedsReconnect(newSsid: 'n', newPassword: 'p'),
      WizardTestingReconnect(attemptCount: 1, maxAttempts: 5),
      WizardCheckingFirmware(),
      WizardUpdatingFirmware(),
      WizardWifiReady(ssid: 'n', password: 'p'),
    ];

    for (final phase in pastEditing) {
      final flow = PnpState(phase: phase, plan: withGuest);

      test('${phase.runtimeType}: the save step stays open', () {
        expect(policy(flow, step('network')), isNull);
      });

      test('${phase.runtimeType}: everything else goes back to the save step',
          () {
        for (final target in [entry, config, step('wifi'), step('guest')]) {
          expect(policy(flow, target), step('network'), reason: target);
        }
      });
    }
  });

  test('a location outside the PnP tree is not the policy\'s', () {
    const editing = PnpState(phase: WizardSaving(), plan: withGuest);

    expect(policy(editing, '/uspDashboard'), isNull);
    expect(policy(editing, '/pnpNoInternetConnection/pnp'), isNull);
  });
}
