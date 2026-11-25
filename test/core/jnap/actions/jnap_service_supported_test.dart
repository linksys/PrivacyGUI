// Pins every ServiceHelper gate: each one opens on exactly the services it
// checks. Every isServiceSupport gate stays, unless its action is deleted
// (#1923):
// - removing a gate fails to compile here, through service_helper_gates.dart;
// - adding a gate fails "every gate is listed" until it is listed there.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';

import '../../../test_data/device_info_test_data.dart';
import 'service_helper_gates.dart';

/// Gates known to answer wrong, with the issue that fixes them.
const _brokenGates = <String, String>{};

void main() {
  test('every gate ServiceHelper declares is listed', () {
    final source = File('lib/core/jnap/actions/jnap_service_supported.dart')
        .readAsStringSync();
    final declared = RegExp(r'bool (isSupport\w+)\(')
        .allMatches(source)
        .map((match) => match.group(1))
        .toSet();
    expect(declared, serviceHelperGates.keys.toSet());
  });

  for (final MapEntry(key: name, value: gate) in serviceHelperGates.entries) {
    final services = gate.services.map((s) => s.name).join(', ');

    test(
      '$name opens on exactly $services, each on its own',
      () {
        final opening = {
          for (final service in JNAPService.values)
            if (gate.isOpen([service.value])) service,
        };
        expect(opening, gate.services);
        expect(gate.isOpen(const []), isFalse);
      },
      skip: _brokenGates[name],
    );
  }

  // Most call sites ask a gate without services. It then answers for the
  // router the action table was last built for, so the two never disagree
  // (#1923 P2).
  group('called without services', () {
    final ln16 = List<String>.from(
        (jsonDecode(testDeviceInfo) as Map)['output']['services'] as List);

    setUp(() => buildBetterActions(ln16));
    tearDown(initBetterActions);

    for (final MapEntry(key: name, value: gate) in serviceHelperGates.entries) {
      test('$name answers for the router the actions were built for', () {
        expect(gate.isOpen(), gate.isOpen(ln16));
      });
    }

    test('every gate is shut before any router is known', () {
      initBetterActions();
      expect(
        [
          for (final MapEntry(key: name, value: gate)
              in serviceHelperGates.entries)
            if (gate.isOpen()) name,
        ],
        isEmpty,
      );
    });
  });

  test('every known broken gate is still listed', () {
    expect(serviceHelperGates.keys, containsAll(_brokenGates.keys));
  });
}
