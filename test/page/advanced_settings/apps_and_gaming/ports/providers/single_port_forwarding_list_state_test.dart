import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/single_port_forwarding_rule.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/single_port_forwarding_list_state.dart';

const _rule = SinglePortForwardingRule(
  isEnabled: true,
  externalPort: 3074,
  protocol: 'TCP',
  internalServerIPAddress: '192.168.1.150',
  internalPort: 3074,
  description: 'XBox Live (TM)',
);

void main() {
  test('survives a trip through JSON text', () {
    const state = SinglePortForwardingListState(
      rules: [_rule],
      maxRules: 20,
      maxDescriptionLength: 12,
      routerIp: '10.0.0.1',
      subnetMask: '255.255.0.0',
    );

    expect(SinglePortForwardingListState.fromJson(state.toJson()), state);
  });

  test('falls back to the defaults for what the map leaves out', () {
    final state = SinglePortForwardingListState.fromMap(const {'rules': []});

    expect(state, const SinglePortForwardingListState());
    expect(state.maxRules, 50);
    expect(state.maxDescriptionLength, 32);
    expect(state.routerIp, '192.168.1.1');
    expect(state.subnetMask, '255.255.255.0');
  });

  test('copyWith changes only what it names', () {
    const state = SinglePortForwardingListState(rules: [_rule]);

    expect(state.copyWith(maxRules: 5).maxRules, 5);
    expect(state.copyWith(), state);
  });
}
