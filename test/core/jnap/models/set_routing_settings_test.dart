import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/get_routing_settings.dart';
import 'package:privacy_gui/core/jnap/models/set_routing_settings.dart';

const _route = NamedStaticRouteEntry(
  name: 'Router1',
  settings: StaticRouteEntry(
    destinationLAN: '192.0.2.50',
    gateway: '192.0.2.1',
    interface: 'LAN',
    networkPrefixLength: 24,
  ),
);

void main() {
  test('reads the SetRoutingSettings input off the wire', () {
    final settings = SetRoutingSettings.fromMap(jsonDecode('''
      {
        "isNATEnabled": false,
        "isDynamicRoutingEnabled": true,
        "entries": [
          {
            "name": "Router1",
            "settings": {
              "interface": "LAN",
              "destinationLAN": "192.0.2.50",
              "networkPrefixLength": 24,
              "gateway": "192.0.2.1"
            }
          }
        ]
      }''') as Map<String, dynamic>);

    expect(settings.isNATEnabled, isFalse);
    expect(settings.isDynamicRoutingEnabled, isTrue);
    expect(settings.entries.single.name, 'Router1');
    expect(settings.entries.single.settings.gateway, '192.0.2.1');
  });

  test('survives a trip through JSON text', () {
    // Built at run time, so the check compares by value, not by identity.
    final settings = SetRoutingSettings(
      isNATEnabled: true,
      isDynamicRoutingEnabled: false,
      entries: [_route.copyWith()],
    );

    expect(SetRoutingSettings.fromJson(settings.toJson()), settings);
  });

  test('writes the SetRoutingSettings input', () {
    const settings = SetRoutingSettings(
      isNATEnabled: true,
      isDynamicRoutingEnabled: false,
      entries: [_route],
    );

    expect(settings.toMap(), {
      'isNATEnabled': true,
      'isDynamicRoutingEnabled': false,
      'entries': [
        {
          'name': 'Router1',
          'settings': {
            'destinationLAN': '192.0.2.50',
            'gateway': '192.0.2.1',
            'interface': 'LAN',
            'networkPrefixLength': 24,
          },
        },
      ],
    });
  });

  test('encodes the same input as JSON text', () {
    const settings = SetRoutingSettings(
      isNATEnabled: false,
      isDynamicRoutingEnabled: true,
      entries: [],
    );

    expect(settings.toJson(),
        '{"isNATEnabled":false,"isDynamicRoutingEnabled":true,"entries":[]}');
    expect(settings.toString(), contains('false, true'));
  });

  test('copyWith changes only what it names', () {
    const settings = SetRoutingSettings(
      isNATEnabled: true,
      isDynamicRoutingEnabled: false,
      entries: [_route],
    );

    final changed = settings.copyWith(
        isNATEnabled: false, isDynamicRoutingEnabled: true, entries: []);

    expect(
        changed,
        const SetRoutingSettings(
          isNATEnabled: false,
          isDynamicRoutingEnabled: true,
          entries: [],
        ));
    expect(settings.copyWith(), settings);
  });
}
