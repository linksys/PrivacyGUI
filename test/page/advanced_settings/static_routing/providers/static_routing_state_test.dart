import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/get_routing_settings.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_state.dart';

const _state = StaticRoutingState(
  setting: GetRoutingSettings(
    isNATEnabled: false,
    isDynamicRoutingEnabled: true,
    maxStaticRouteEntries: 20,
    entries: [
      NamedStaticRouteEntry(
        name: 'Lab',
        settings: StaticRouteEntry(
          destinationLAN: '192.168.50.0',
          gateway: '192.168.1.254',
          interface: 'LAN',
          networkPrefixLength: 24,
        ),
      ),
    ],
  ),
  routerIp: '10.0.0.1',
  subnetMask: '255.255.0.0',
);

void main() {
  test('starts empty, on the default LAN', () {
    final empty = StaticRoutingState.empty();

    expect(empty.setting.entries, isEmpty);
    expect(empty.setting.maxStaticRouteEntries, 0);
    expect(empty.routerIp, '192.168.1.1');
    expect(empty.subnetMask, '255.255.255.0');
  });

  test('survives a trip through JSON text', () {
    expect(StaticRoutingState.fromJson(_state.toJson()), _state);
  });

  test('copyWith changes only what it names', () {
    final changed = _state.copyWith(routerIp: '10.0.0.2');

    expect(changed.routerIp, '10.0.0.2');
    expect(changed.copyWith(routerIp: '10.0.0.1'), _state);
    expect(_state.toString(), contains('routerIp: 10.0.0.1'));
  });

  test('reads an interface by its router name, LAN when unknown', () {
    expect(RoutingSettingInterface.resolve('LAN'), RoutingSettingInterface.lan);
    expect(RoutingSettingInterface.resolve('Internet'),
        RoutingSettingInterface.internet);
    expect(RoutingSettingInterface.resolve(null), RoutingSettingInterface.lan);
    expect(RoutingSettingInterface.internet.value, 'Internet');
  });
}
