import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_flow_plan.dart';

/// The plan's own reading of its steps — what Next, Back and Save placement are
/// derived from (#1511 P4).
void main() {
  const withGuest = PnpFlowPlan(settingStepIds: ['wifi', 'guest']);
  const noGuest = PnpFlowPlan(settingStepIds: ['wifi']);

  test('Your Network follows the setting steps, and holds Save', () {
    expect(withGuest.stepIds, ['wifi', 'guest', 'network']);
    expect(withGuest.firstStepId, 'wifi');
    expect(withGuest.saveStepId, 'network');
    expect(noGuest.stepIds, ['wifi', 'network']);
  });

  test('Next goes to the step after, and the last step has none', () {
    expect(withGuest.stepAfter('wifi'), 'guest');
    expect(withGuest.stepAfter('guest'), 'network');
    expect(withGuest.stepAfter('network'), isNull);
    expect(noGuest.stepAfter('wifi'), 'network');
  });

  test('Back goes to the step before, and the first step has none', () {
    expect(withGuest.stepBefore('network'), 'guest');
    expect(withGuest.stepBefore('guest'), 'wifi');
    expect(withGuest.stepBefore('wifi'), isNull);
    expect(noGuest.stepBefore('network'), 'wifi');
  });

  test('a step the plan does not have has no neighbours', () {
    expect(noGuest.stepAfter('guest'), isNull);
    expect(noGuest.stepBefore('guest'), isNull);
  });
}
