// Pins the URL each JNAP action resolves to, for a set of service lists, so
// that #1923's P1 (one declaration per action) can show it changes no version.
//
// The expected values are test/test_data/better_action_snapshot.json. They
// were written from the code as it was, by test_scripts/better_action_snapshot.dart:
// this test detects change, it does not say the mapping is right. Whether it
// is right is better_action_spec_test.dart's job, against the JNAP spec.
//
// A PR that means to change a mapping regenerates the file, and its
// description lists the actions that changed.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';

import 'better_action_resolution.dart';

void main() {
  final snapshot =
      jsonDecode(File(snapshotPath).readAsStringSync()) as Map<String, dynamic>;
  final inputs = (snapshot['inputs'] as Map<String, dynamic>)
      .map((name, services) => MapEntry(name, List<String>.from(services)));
  final results = snapshot['results'] as Map<String, dynamic>;
  final seed = Map<String, String?>.from(results['seed']);

  Map<String, String?> expectedFor(String name) => {
        ...seed,
        ...Map<String, String?>.from(results[name] ?? const {}),
      };

  test('the snapshot names every action and gives every service an input', () {
    expect(seed.keys.toSet(), JNAPAction.values.map((a) => a.name).toSet(),
        reason: 'an action was added or removed: regenerate the snapshot');
    expect(
      appServices.where((service) => !inputs.containsKey(onlyInput(service))),
      isEmpty,
      reason: 'a service was added: regenerate the snapshot',
    );
    // A result whose input is gone, renamed say, would never be checked.
    expect(results.keys.where((name) => !inputs.containsKey(name)), isEmpty,
        reason: 'an input was renamed or removed: regenerate the snapshot');
  });

  for (final name in inputs.keys) {
    test('each action resolves as recorded, for "$name"', () async {
      final actual = await resolveActions(inputs[name]!);
      final expected = expectedFor(name);
      final changed = [
        for (final action in expected.keys)
          if (actual[action] != expected[action])
            '$action: ${expected[action]} -> ${actual[action]}',
      ];
      expect(changed, isEmpty);
    });
  }
}
