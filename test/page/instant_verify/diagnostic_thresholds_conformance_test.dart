import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_verify/models/diagnostic_thresholds.dart';

/// Instant Test's shared-finding cutoffs must match the boundaries decided in
/// the shared threshold table (linksys/linksys-ai-msdm
/// `docs/contracts/thresholds.v0.json`, vendored from msdm `dev` @ 13c67d1 into
/// `contracts/thresholds.v0.json`). The engine side pins its own values to the
/// same table in `tests/test_diagnostic_thresholds.py`.
///
/// To change a cutoff: change the table in ai-msdm, re-vendor it here, and
/// change `diagnostic_thresholds.dart`, each in one reviewed change.
void main() {
  final table = jsonDecode(
    File('test/page/instant_verify/contracts/thresholds.v0.json')
        .readAsStringSync(),
  ) as Map<String, dynamic>;
  final rules = {
    for (final r in (table['rules'] as List).cast<Map<String, dynamic>>())
      r['id'] as String: r,
  };

  /// Every shared rule Instant Test evaluates, mapped to its Dart predicate.
  final predicates = <String, bool Function(int)>{
    'router.uptime.restart_hint': uptimeSuggestsRestart,
    'wifi.client_signal.weak': isWeakClientSignal,
    'wifi.client_signal.strong': isStrongClientSignal,
    'mesh.backhaul.weak': isWeakBackhaulSignal,
    'system.memory.high': isMemoryHigh,
    'internet.latency.high': isLatencyHigh,
  };

  bool apply(String op, int x, int value) => switch (op) {
        '>' => x > value,
        '>=' => x >= value,
        '<' => x < value,
        '<=' => x <= value,
        _ => throw ArgumentError('unknown comparator $op'),
      };

  /// The boundary this side must implement: the decided one where a decision
  /// was recorded, otherwise the engine's (only valid when both sides agree).
  Map<String, dynamic> target(Map<String, dynamic> rule) {
    final decided = rule['decided'] as Map<String, dynamic>?;
    if (decided != null) return decided;
    expect(rule['agreed'], isTrue,
        reason: '${rule['id']}: no decision recorded and the sides disagree');
    return rule['engine'] as Map<String, dynamic>;
  }

  test('the vendored table is the v0 contract', () {
    expect(table['contract'], 'diagnostic-thresholds/v0');
  });

  test('every rule in the table is mapped to an Instant Test predicate', () {
    expect(predicates.keys.toSet(),
        containsAll(rules.keys.where((id) => id != 'mesh.backhaul.good')),
        reason: 'a new shared rule needs a predicate in '
            'diagnostic_thresholds.dart (mesh.backhaul.good is display-only '
            'in Instant Test today)');
  });

  for (final entry in predicates.entries) {
    test('${entry.key} matches the decided boundary at value-1, value, value+1',
        () {
      final rule = rules[entry.key];
      expect(rule, isNotNull, reason: '${entry.key} is not in the table');
      final t = target(rule!);
      final op = t['op'] as String;
      final value = t['value'] as int;
      for (final x in [value - 1, value, value + 1]) {
        expect(entry.value(x), apply(op, x, value),
            reason: '${entry.key} at $x: table says "$op $value"');
      }
    });
  }
}
