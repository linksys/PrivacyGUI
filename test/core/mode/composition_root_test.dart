// Phase 3 of epic #1474 / #1493: both composition roots stay exhaustive, and
// they stay the only two places that read the mode.
//
// THE DECISION GUARDED. That adding an `AppMode` is a *compile error* in exactly
// two files, and that those two files are the only ones that ask "which mode is
// this?".
//
// This is the mechanism the whole epic rests on. Before it, 15 separate reads
// each answered the question independently — 11 `GlobalConfig.remote.isActive`
// and 4 direct `BuildConfig.isRemote()`, measured at the phase-2 tip — so a third
// mode would have been mis-answered by however many of them nobody remembered to
// visit, silently, because `isActive` is a bool and every one of those sites had a
// perfectly sensible `else`. Replacing them with a `switch` that has no
// `default:` converts that from a review problem into a build failure.
//
// HOW IT COULD SILENTLY REVERT. A catch-all arm — and this is not a
// hypothetical, it is the *predictable* next step. A developer adds an `AppMode`
// value, gets a compile error in two switches, and the fastest way to make the
// error go away is a catch-all. The code then compiles, the app behaves correctly
// for the three old modes, and the new mode silently inherits whichever profile
// the catch-all names. The compiler pointed at the right place and offered the
// wrong fix.
//
// Both roots are switch *expressions* today, so the live form of that fix is
// `_ =>`; `default:` is only reachable if a root is rewritten as a switch
// statement. Both tokens are checked, and `_ =>` is the one the mutation check
// exercised.
//
// The second half is drift by addition: a new feature that needs mode-dependent
// behaviour reads `appModeProvider` directly and writes its own `if`, which is the
// pre-#1474 shape returning one site at a time. The census below is what makes
// that visible; a strategy member is the intended answer instead.
//
// WHY THIS TEST TYPE. A source scan, because there is nothing else that can see
// it. The exhaustiveness itself is enforced by the compiler and needs no test —
// but the compiler cannot object to `default:`, since a switch WITH a catch-all is
// valid Dart, and no runtime observation distinguishes "exhaustive" from
// "exhaustive plus an unreachable default". A behavioural test would need a fifth
// AppMode value to exist in order to detect that it was being swallowed, which is
// exactly the situation this file is meant to prevent from arising unnoticed.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/mode/app_mode.dart';

/// The two composition roots, each mapped to the strategy it yields — used in
/// failure messages so the reader knows which root they are looking at.
const _roots = <String, String>{
  'lib/core/mode/app_mode_profile.dart': 'AppModeProfile (causes 1-4)',
  'lib/page/_shared/mode/surface_strategy_provider.dart':
      'SurfaceStrategy (cause 5)',
};

void main() {
  /// [path]'s source with comment lines removed.
  ///
  /// Load-bearing, not tidiness: every root's doc comment discusses `default:`
  /// at length — it has to, that is the decision being recorded — so a scan that
  /// kept comments would find the forbidden token in prose and could never fail.
  /// Verified by adding a real `default:` arm with the comments included: green.
  String code(String path) => File(path)
      .readAsStringSync()
      .split('\n')
      .where((l) => !l.trimLeft().startsWith('//'))
      .join('\n');

  /// The `switch (mode) { ... }` block of [path], comments stripped, or null if
  /// the anchors are missing — so a moved switch fails as "not found" rather than
  /// as a silently empty search.
  String? switchBlock(String path) {
    final lines = code(path).split('\n');
    final start = lines.indexWhere((l) => l.contains('switch (mode)'));
    if (start < 0) return null;
    final end = lines.indexWhere((l) => l.trim() == '};', start);
    if (end < 0) return null;
    return lines.sublist(start, end + 1).join('\n');
  }

  group('both composition roots exist and switch on AppMode', () {
    for (final entry in _roots.entries) {
      final path = entry.key;
      final what = entry.value;

      test(what, () {
        expect(File(path).existsSync(), isTrue,
            reason: '$path moved or was split. Re-point this scan; if a root '
                'was removed, that is a design change and constitution Article '
                'XVII Rule 2 has to move with it.');
        expect(switchBlock(path), isNotNull,
            reason: 'no `switch (mode)` in $path. If the root now selects its '
                'strategy some other way — a map, a factory — the exhaustiveness '
                'guarantee is gone: only a switch statement over an enum makes a '
                'new AppMode a compile error.');
      });
    }
  });

  group('neither root has an escape hatch', () {
    for (final entry in _roots.entries) {
      final path = entry.key;
      final what = entry.value;

      test(what, () {
        final block = switchBlock(path)!;

        expect(block, isNot(contains('default:')),
            reason: 'the $what root has a `default:` arm. That is the fastest '
                'way to silence the compile error a new AppMode produces, and it '
                'is the wrong one: the new mode then silently inherits whichever '
                'profile the catch-all names, and the app behaves correctly for '
                'every mode except the one just added. Give the new mode its own '
                'arm.');
        expect(block, isNot(matches(RegExp(r'^\s*_\s*=>', multiLine: true))),
            reason: 'the $what root has a `_ =>` wildcard arm, which is '
                '`default:` in switch-expression clothing. Same objection.');
      });
    }
  });

  group('every AppMode is named in every root', () {
    for (final entry in _roots.entries) {
      final path = entry.key;
      final what = entry.value;

      test(what, () {
        final block = switchBlock(path)!;

        for (final mode in AppMode.values) {
          expect(block, contains('AppMode.${mode.name}'),
              reason: 'the $what root does not name AppMode.${mode.name}. With '
                  'no `default:` this should not compile, so seeing it here means '
                  'an escape hatch was added in the same edit — check the test '
                  'above.');
        }
      });
    }
  });

  test('nothing outside the two roots reads the mode', () {
    final readers = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => f
            .readAsStringSync()
            .split('\n')
            .where((l) => !l.trimLeft().startsWith('//'))
            .any((l) => l.contains('ref.watch(appModeProvider)')))
        .map((f) => f.path)
        .toList()
      ..sort();

    expect(
      readers,
      _roots.keys.toList()..sort(),
      reason: 'only the two composition roots may read appModeProvider; found '
          '$readers. A feature that reads the mode directly is writing the '
          '14th `if` — the shape #1474 exists to remove — and it will be correct '
          'today and wrong the day a mode is added. The intended answer is a '
          'member on the strategy for the *cause* the feature actually depends '
          'on: how bytes travel, who holds the credential, what session end '
          'means, whether the operator is next to the router, or which surfaces '
          'the mode has. `overrideWithValue` in demo_overrides.dart is not a '
          'read and is deliberately not counted.',
    );
  });
}
