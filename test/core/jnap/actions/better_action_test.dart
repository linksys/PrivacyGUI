import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';

import '../../../test_data/device_info_test_data.dart';
import 'better_action_resolution.dart';

/// A service's family, the part of its name before the version:
/// router13 → router.
String _family(JNAPService service) =>
    RegExp(r'^[a-zA-Z]+?(?=\d|$)').firstMatch(service.name)!.group(0)!;

/// A service's version: router13 → 13. A name without a number is the first.
int _version(JNAPService service) =>
    int.tryParse(RegExp(r'\d+$').firstMatch(service.name)?.group(0) ?? '') ?? 1;

void main() {
  test('test update better actions', () {
    initBetterActions();
    final services =
        List<String>.from(jsonDecode(testDeviceInfo)['output']['services']);
    buildBetterActions(services);
    expect('http://linksys.com/jnap/router/GetWANSettings5',
        JNAPAction.getWANSettings.actionValue);
    expect(
      'http://linksys.com/jnap/core/SetAdminPassword3',
      JNAPAction.pnpSetAdminPassword.actionValue,
    );
  });

  test(
      'a router that reports no service the app knows gets the lowest versions',
      () async {
    final seed = await resolveActions(const []);
    final unknown =
        await resolveActions(const ['http://linksys.com/jnap/unknown/Unknown']);
    expect(unknown, seed);
  });

  group('refreshBetterActions', () {
    const core = 'http://linksys.com/jnap/core/Core';
    const wirelessAP5 = 'http://linksys.com/jnap/wirelessap/WirelessAP5';

    String? clientDeauth() {
      try {
        return JNAPAction.clientDeauth.actionValue;
      } on TypeError {
        return null;
      }
    }

    tearDown(initBetterActions);

    test('follows a router whose services changed, as after a firmware update',
        () {
      buildBetterActions(const [core]);
      expect(clientDeauth(), isNull);

      refreshBetterActions(const [core, wirelessAP5]);
      expect(clientDeauth(), 'http://linksys.com/jnap/wirelessap/ClientDeauth');
      expect(routerServices, {core, wirelessAP5});

      refreshBetterActions(const [core]);
      expect(clientDeauth(), isNull);
      expect(routerServices, {core});
    });

    test('leaves the table alone while the services stay the same', () {
      buildBetterActions(const [core, wirelessAP5]);
      final before = routerServices;

      refreshBetterActions(const [wirelessAP5, core]);

      expect(identical(routerServices, before), isTrue,
          reason: 'the same services in another order are no change');
    });
  });

  // buildBetterActions applies a router's services in JNAPService order, so
  // that a newer version's URL wins. That holds while each family is declared
  // from its lowest version up, and while no action takes a URL from two
  // families.
  test('JNAPService lists each family from its lowest version up', () {
    final byFamily = <String, List<JNAPService>>{};
    for (final service in JNAPService.values) {
      byFamily.putIfAbsent(_family(service), () => []).add(service);
    }
    final outOfOrder = [
      for (final MapEntry(key: family, value: services) in byFamily.entries)
        for (var i = 1; i < services.length; i++)
          if (_version(services[i]) <= _version(services[i - 1]))
            '$family: ${services[i - 1].name} before ${services[i].name}',
    ];
    expect(outOfOrder, isEmpty);
  });

  test('no action takes a URL from two families of services', () async {
    final seed = await resolveActions(const []);
    final families = <String, Set<String>>{};
    for (final service in JNAPService.values) {
      final alone = await resolveActions([service.value]);
      for (final MapEntry(key: action, value: url) in alone.entries) {
        if (url != seed[action]) {
          families.putIfAbsent(action, () => {}).add(_family(service));
        }
      }
    }
    expect(
      {
        for (final MapEntry(key: action, value: names) in families.entries)
          if (names.length > 1) action: names,
      },
      isEmpty,
    );
  });
}
