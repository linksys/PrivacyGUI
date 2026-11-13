import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_flow_plan.dart';

/// The plan's own reading of its steps — what Next, Back and Save placement are
/// derived from (#1511 P4), with Save before Your Network (#1511 P5).
void main() {
  const withGuest = PnpFlowPlan(settingStepIds: ['wifi', 'guest']);
  const noGuest = PnpFlowPlan(settingStepIds: ['wifi']);

  test('Your Network follows the setting steps', () {
    expect(withGuest.stepIds, ['wifi', 'guest', 'network']);
    expect(withGuest.firstStepId, 'wifi');
    expect(noGuest.stepIds, ['wifi', 'network']);
  });

  test('the last setting step holds Save, whichever it is (#1511 P5)', () {
    expect(withGuest.saveStepId, 'guest');
    expect(noGuest.saveStepId, 'wifi');
  });

  test('Next moves between setting steps, and stops at the one that saves', () {
    expect(withGuest.stepAfter('wifi'), 'guest');
    expect(withGuest.stepAfter('guest'), isNull,
        reason:
            'the save step saves; the flow, not a Next, opens Your Network');
    expect(noGuest.stepAfter('wifi'), isNull);
    expect(withGuest.stepAfter('network'), isNull);
  });

  test('Back moves between setting steps, and never across Save', () {
    expect(withGuest.stepBefore('guest'), 'wifi');
    expect(withGuest.stepBefore('wifi'), isNull);
    expect(withGuest.stepBefore('network'), isNull,
        reason: 'Your Network is past the irreversible point (D7)');
    expect(noGuest.stepBefore('network'), isNull);
  });

  test('a step the plan does not have has no neighbours', () {
    expect(noGuest.stepAfter('guest'), isNull);
    expect(noGuest.stepBefore('guest'), isNull);
  });
}
