import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/get_routing_settings.dart';

/// `GetRoutingSettings` output, the spec's sample.
const _output = <String, dynamic>{
  'isNATEnabled': true,
  'isDynamicRoutingEnabled': false,
  'entries': [
    {
      'name': 'Router1',
      'settings': {
        'interface': 'LAN',
        'destinationLAN': '192.0.2.50',
        'networkPrefixLength': 24,
        'gateway': '192.0.2.1',
      },
    },
  ],
  'maxStaticRouteEntries': 20,
};

void main() {
  test('reads the mode, the limit and each named route', () {
    final settings = GetRoutingSettings.fromMap(_output);

    expect(settings.isNATEnabled, isTrue);
    expect(settings.isDynamicRoutingEnabled, isFalse);
    expect(settings.maxStaticRouteEntries, 20);
    expect(settings.entries.single.name, 'Router1');
    expect(
        settings.entries.single.settings,
        const StaticRouteEntry(
          destinationLAN: '192.0.2.50',
          gateway: '192.0.2.1',
          interface: 'LAN',
          networkPrefixLength: 24,
        ));
  });

  test('reads a route with no gateway', () {
    final route = StaticRouteEntry.fromMap(const {
      'interface': 'Internet',
      'destinationLAN': '10.20.0.0',
      'networkPrefixLength': 16,
    });

    expect(route.gateway, isNull);
  });

  test('writes the fields it read', () {
    expect(GetRoutingSettings.fromMap(_output).toMap(), _output);
  });

  test('survives a trip through JSON text', () {
    final settings = GetRoutingSettings.fromMap(_output);
    final route = settings.entries.single;

    expect(GetRoutingSettings.fromJson(settings.toJson()), settings);
    expect(NamedStaticRouteEntry.fromJson(route.toJson()), route);
    expect(StaticRouteEntry.fromJson(route.settings.toJson()), route.settings);
  });

  test('copyWith changes only what it names', () {
    final settings = GetRoutingSettings.fromMap(_output);
    final route = settings.entries.single;

    expect(
        settings.copyWith(maxStaticRouteEntries: 5).maxStaticRouteEntries, 5);
    expect(settings.copyWith(), settings);
    expect(route.copyWith(name: 'Lab').name, 'Lab');
    expect(route.copyWith(), route);
    expect(route.settings.copyWith(gateway: () => null).gateway, isNull);
    expect(route.settings.copyWith(), route.settings);
    expect(route.settings.toString(), contains('gateway: 192.0.2.1'));
  });
}
