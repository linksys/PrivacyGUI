import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/get_routing_settings.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_rule_state.dart';

const _route = NamedStaticRouteEntry(
  name: 'Lab',
  settings: StaticRouteEntry(
    destinationLAN: '192.168.50.0',
    gateway: '192.168.1.254',
    interface: 'LAN',
    networkPrefixLength: 24,
  ),
);

const _state = StaticRoutingRuleState(
  rules: [_route],
  rule: _route,
  editIndex: 0,
  routerIp: '192.168.1.1',
  subnetMask: '255.255.255.0',
);

void main() {
  test('survives a trip through JSON text', () {
    expect(StaticRoutingRuleState.fromJson(_state.toJson()), _state);
  });

  test('reads an add, with no route or place yet', () {
    final state = StaticRoutingRuleState.fromMap(const {'rules': []});

    expect(state.rule, isNull);
    expect(state.editIndex, isNull);
    expect(state.routerIp, '');
  });

  test('copyWith can clear the route and its place', () {
    final cleared = _state.copyWith(rule: () => null, editIndex: () => null);

    expect(cleared.rule, isNull);
    expect(cleared.editIndex, isNull);
    expect(cleared.rules, [_route]);
    expect(_state.copyWith(), _state);
    expect(_state.toString(), contains('editIndex: 0'));
  });
}
