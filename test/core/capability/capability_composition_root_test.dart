// #1635: the capability composition root stays exhaustive.
//
// THE DECISION GUARDED. That adding a `DeviceCapability` is a *compile error* in
// `capabilityProbePath` — the one `switch (capability)` that assigns each
// capability its probe path — so a new capability cannot ship without a rule.
//
// HOW IT COULD SILENTLY REVERT. A catch-all arm. A developer adds a capability,
// gets a compile error in the switch, and the fastest way to silence it is a
// `_ =>`. The code then compiles and every capability except the new one
// resolves correctly, while the new one silently inherits the catch-all's path —
// the compiler pointed at the right place and offered the wrong fix. This mirrors
// the mode-strategy guard (`test/core/mode/composition_root_test.dart`,
// constitution Article XVII Rule 1); see it for the full rationale of why a
// source scan is the only thing that can see a `default:`.
//
// The root is a switch *expression*, so the live form of the escape hatch is
// `_ =>`; `default:` is only reachable if it is rewritten as a statement. Both
// tokens are checked.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';

const _root = 'lib/core/capability/capability_resolver.dart';
const _what = 'capabilityProbePath (DeviceCapability → probe path)';

void main() {
  /// [path]'s source with comment lines removed — the root's doc comment
  /// discusses `default:`, so a scan that kept comments could never fail.
  String code(String path) => File(path)
      .readAsStringSync()
      .split('\n')
      .where((l) => !l.trimLeft().startsWith('//'))
      .join('\n');

  /// The `switch (capability) { ... }` block of [path], comments stripped, or
  /// null if the anchors are missing — so a moved switch fails as "not found"
  /// rather than as a silently empty search.
  String? switchBlock(String path) {
    final lines = code(path).split('\n');
    final start = lines.indexWhere((l) => l.contains('switch (capability)'));
    if (start < 0) return null;
    final end = lines.indexWhere((l) => l.trim() == '};', start);
    if (end < 0) return null;
    return lines.sublist(start, end + 1).join('\n');
  }

  test('$_what exists and switches on DeviceCapability', () {
    expect(File(_root).existsSync(), isTrue,
        reason: '$_root moved or was split. Re-point this scan.');
    expect(switchBlock(_root), isNotNull,
        reason: 'no `switch (capability)` in $_root. If the root now selects a '
            'path some other way — a map, a factory — the exhaustiveness '
            'guarantee is gone: only a switch over the enum makes a new '
            'DeviceCapability a compile error.');
  });

  test('$_what has no escape hatch', () {
    final block = switchBlock(_root)!;

    expect(block, isNot(contains('default:')),
        reason:
            'the $_what root has a `default:` arm. That silences the compile '
            'error a new DeviceCapability produces, and the new capability then '
            'inherits whichever path the catch-all names. Give it its own arm.');
    expect(block, isNot(matches(RegExp(r'^\s*_\s*=>', multiLine: true))),
        reason:
            'the $_what root has a `_ =>` wildcard arm, which is `default:` '
            'in switch-expression clothing. Same objection.');
  });

  test('every DeviceCapability is named in the root', () {
    final block = switchBlock(_root)!;
    for (final capability in DeviceCapability.values) {
      expect(block, contains('DeviceCapability.${capability.name}'),
          reason: 'DeviceCapability.${capability.name} has no arm in $_root. '
              'Every capability needs a probe path.');
    }
  });
}
