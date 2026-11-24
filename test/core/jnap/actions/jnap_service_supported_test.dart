// Pins every ServiceHelper gate: each one opens on exactly the services it
// checks. Every isServiceSupport gate stays (#1923):
// - removing a gate fails to compile here, through service_helper_gates.dart;
// - adding a gate fails "every gate is listed" until it is listed there.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';

import 'service_helper_gates.dart';

/// Gates known to answer wrong, with the issue that fixes them.
const _brokenGates = {
  'isSupportWANExternal': 'it ignores its services argument; #1906 deletes it '
      'together with GetWANExternal',
};

void main() {
  stubTempDirectory();

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

  test('every known broken gate is still listed', () {
    expect(serviceHelperGates.keys, containsAll(_brokenGates.keys));
  });
}
