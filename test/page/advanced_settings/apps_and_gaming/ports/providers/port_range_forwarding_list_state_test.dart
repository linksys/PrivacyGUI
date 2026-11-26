import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/port_range_forwarding_rule.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/port_range_forwarding_list_state.dart';

const _rule = PortRangeForwardingRule(
  isEnabled: true,
  firstExternalPort: 6888,
  lastExternalPort: 6900,
  protocol: 'Both',
  internalServerIPAddress: '192.168.1.150',
  description: 'BitTorrent',
);

void main() {
  test('survives a trip through JSON text', () {
    const state = PortRangeForwardingListState(
      rules: [_rule],
      maxRules: 15,
      maxDescriptionLength: 12,
      routerIp: '10.0.0.1',
      subnetMask: '255.255.0.0',
    );

    expect(PortRangeForwardingListState.fromJson(state.toJson()), state);
  });

  test('reads what the map leaves out as zero or empty', () {
    // Unlike the single-port list, this one has no fallback limits.
    final state = PortRangeForwardingListState.fromMap(const {'rules': []});

    expect(state.maxRules, 0);
    expect(state.maxDescriptionLength, 0);
    expect(state.routerIp, '');
    expect(state.subnetMask, '');
  });

  test('copyWith changes only what it names', () {
    const state = PortRangeForwardingListState(rules: [_rule]);

    expect(state.copyWith(maxRules: 5).maxRules, 5);
    expect(state.copyWith(), state);
    expect(state.toString(), contains('maxRules: 50'));
  });
}
