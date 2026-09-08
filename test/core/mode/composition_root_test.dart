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

  test(
      'the page root takes its mode from the profile, not from appModeProvider',
      () {
    final src = code('lib/page/_shared/mode/surface_strategy_provider.dart');

    expect(src, contains('ref.watch(appModeProfileProvider).mode'),
        reason: 'the page root must derive its mode from the profile. Reading '
            '`appModeProvider` directly here is the equivalent-looking edit that '
            'silently breaks acceptance 3 of #1493: one '
            '`appModeProfileProvider.overrideWithValue(const '
            'RemoteModeProfile())` is supposed to put the WHOLE stack in remote, '
            'and a root on the raw provider opts cause 5 out of it — transport, '
            'credentials, session and proximity move, the surfaces stay local. '
            'Every transport assertion still passes, so only a test that reads '
            'surfaceStrategyProvider under a profile-only override can see it '
            '(app_mode_profile_test.dart has one). Going through the profile '
            'keeps both levers live, because the profile is derived from '
            'appModeProvider.');
    expect(src, isNot(contains('ref.watch(appModeProvider)')),
        reason: 'and it must not read the raw provider as well — two sources '
            'for one answer is how the two roots come to disagree.');
  });

  test('appModeProvider is named in exactly three places', () {
    final mentions = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => f
            .readAsStringSync()
            .split('\n')
            .where((l) => !l.trimLeft().startsWith('//'))
            .any((l) => l.contains('appModeProvider')))
        .map((f) => f.path)
        .toList()
      ..sort();

    // Deliberately every *mention*, not just `ref.watch(...)`. The narrower
    // scan this replaced let `ref.read`, `container.read`, a `.select` and a
    // bare `AppMode.resolve()` through — so the census enforced a spelling
    // rather than the rule, which is that one file decides the mode.
    expect(
      mentions,
      [
        // The provider's own declaration.
        'lib/core/mode/app_mode.dart',
        // The one composition root that consumes it. The page root reaches the
        // mode through appModeProfileProvider — see the test above.
        'lib/core/mode/app_mode_profile.dart',
        // An override, not a read: the demo build pins AppMode.demo.
        'lib/demo/providers/demo_overrides.dart',
      ],
      reason: 'found $mentions. A feature that reads the mode directly is '
          'writing the 14th `if` — the shape #1474 exists to remove — and it '
          'will be correct today and wrong the day a mode is added. The intended '
          'answer is a member on the strategy for the *cause* the feature '
          'actually depends on: how bytes travel, who holds the credential, what '
          'session end means, whether the operator is next to the router, or '
          'which surfaces the mode has. If a fourth entry here is another '
          'legitimate override, add it with a comment saying so; if it is a '
          'read, it belongs on a strategy instead.',
    );
  });

  // ===========================================================================
  // #1497 acceptance 7 and 5c
  // ===========================================================================
  //
  // The census above covers `appModeProvider`, the *new* spelling. These cover the
  // two old ones, and they live here rather than in the phase-7 test directory
  // because this file already owns the question "who may read the mode" and holds
  // the pre-epic 11 + 4 measurement the acceptance numbers are counted against.
  //
  // Two spellings, not one. #1497 states acceptance 7 as `grep -rn
  // "remote\.isActive" lib/page/ lib/components/` returning 0, and taken literally
  // that is satisfiable by changing one character: `GlobalConfig.remote.isActive`
  // and `BuildConfig.isRemote()` are the same read — the former is a one-line
  // forward to the latter — and the pre-epic 15 sites were split 11/4 between them.
  // A guard on one spelling would pass a page that switched to the other, which is
  // the mistake the `appModeProvider` census above already records having made
  // once.
  group('#1497 acceptance 7: no surface asks which mode it is in', () {
    /// Every `lib/` file under [roots] whose *code* mentions any of [needles].
    ///
    /// Comment lines are stripped, for the same reason `code()` strips them and
    /// then one more. The epic's habit is to record the shape a member replaced —
    /// `local_surface.dart` and `bridge_config.dart` both quote the `if
    /// (GlobalConfig.remote.isActive)` they removed — and that is documentation
    /// worth keeping, not a violation. A scan that counted prose would make the
    /// comment the thing to delete.
    List<String> readers(List<String> roots, List<String> needles) => [
          for (final root in roots)
            ...Directory(root)
                .listSync(recursive: true)
                .whereType<File>()
                .where((f) => f.path.endsWith('.dart'))
                .where((f) => f
                    .readAsStringSync()
                    .split('\n')
                    .where((l) => !l.trimLeft().startsWith('//'))
                    .any((l) => needles.any(l.contains)))
                .map((f) => f.path)
        ]..sort();

    const modeReads = ['remote.isActive', 'BuildConfig.isRemote()'];

    test('lib/page/ and lib/components/ hold none of them', () {
      expect(
        readers(['lib/page', 'lib/components'], modeReads),
        isEmpty,
        reason: 'acceptance 7 of #1497: this was 7 at the phase-6 tip and must '
            'stay 0. A surface that reads the mode is deciding a UI question '
            'from a transport fact, and the two come apart — the SSE banner is '
            'the measured case: it hid itself in RA because "SSE is not '
            'supported via the proxy", which was false, so a support engineer '
            'had a dashboard that silently stopped updating. Add a '
            'SurfaceStrategy member returning the widget/callback/list instead; '
            'a member that returns a bool is the same `if` with a longer name.',
      );
    });

    // The forcing function for phase 9, and the reason this is a `==` and not a
    // "no more than": when #1498 removes the `/usp*` redirect's read, this test
    // fails as "expected 5 got 4" and the list has to be edited. That edit is the
    // moment someone notices the census is now short enough to delete outright.
    test('the remaining reads are the two phase 9 owns, and the declarations',
        () {
      expect(
        readers(['lib'], modeReads),
        [
          // `GlobalConfig.remote.isActive`'s own declaration, which is a
          // one-line forward to `BuildConfig.isRemote()`. It stays: the mode has
          // to be resolved from *somewhere*, and `AppMode.resolve()` is built on
          // it.
          //
          // `build_config.dart` is absent for a reason worth knowing rather than
          // patching around. Its declaration reads `static bool isRemote()`,
          // unqualified, so the qualified needle above does not match it. That is
          // the right trade: an unqualified `isRemote()` needle would match every
          // declaration and every unrelated method of that name, and the thing
          // being counted is *call sites*, not definitions.
          'lib/config/global_config.dart',
          // Phase 9 (#1498). The `/usp*` redirect and the SSE bootstrap gate are
          // the last two, and both are about routing/transport rather than a
          // surface, which is why phase 7 left them.
          'lib/core/usp/providers/sse_providers.dart',
          'lib/di.dart',
          'lib/route/router_provider.dart',
        ],
        reason:
            'the set of files still reading the mode directly changed. If a '
            'file was added, it is the 8th `if` and belongs on a strategy; if one '
            'was removed, shorten this list and check whether phase 9 is done.',
      );
    });

    // Pinned so the two tests above cannot be read as more than they say.
    // `GlobalConfig.remote` has two members left and acceptance 7 only counted
    // `isActive`; a green suite above says nothing about the other one, and it is
    // still read from `lib/page/`.
    test('the other GlobalConfig.remote member, and why it is still read', () {
      expect(
        readers(['lib/page', 'lib/components'], ['GlobalConfig.remote.']),
        [
          // `mascotEnabled`, twice — the overlay and its General Settings
          // toggle, gated by the same flag on purpose so a visible toggle for a
          // hidden mascot cannot happen. NOT a mode read to migrate: it is
          // `!isActive && !BuildConfig.e2eMock`, two axes, and cause 5 answers
          // only the first. `SurfaceStrategy.ambientCoordinators()` took the
          // mascot's *timer* for that reason and left the overlay alone.
          'lib/components/styled/general_settings_widget/general_settings_widget.dart',
          'lib/page/shell/usp_dashboard_shell.dart',
        ],
        reason: 'a `GlobalConfig.remote` read appeared or disappeared under a '
            'surface directory. Neither is wrong by itself — what is wrong is '
            'this list not saying which it is. Update it with the reason, the '
            'way the two entries above are annotated.',
      );
    });

    // `forcedPreset` used to be pinned here, at
    // `usp_layout_controller.dart` and `usp_layout_preferences_provider.dart`,
    // with a note that #1497 had scoped it out. It was folded back in on
    // 2026-09-08 and is now `SurfaceStrategy.fixedDashboardLayout()`; the getter
    // is gone, and with it this class's only `lib/config/` -> `lib/page/` import.
    //
    // Kept as a `isEmpty` rather than deleted, because the interesting part was
    // never the count. Neither of those two sites was asking which *preset* the
    // mode gets — both were asking whether the dashboard in front of the viewer
    // is theirs to keep, and each answered it from the flag separately. A member
    // per site would have passed acceptance 7 and left the same defect.
    test('and no surface asks which dashboard preset the mode forces', () {
      expect(
        readers(['lib'], ['forcedPreset']),
        isEmpty,
        reason:
            'a mode-forced dashboard preset came back. The question belongs '
            'to `SurfaceStrategy.fixedDashboardLayout()`, which answers it for '
            'the grid and for the layout preferences at once — a second answer '
            'here is how those two come to disagree.',
      );
    });
  });

  group('#1497 acceptance 5c: no page decides where an ending session lands',
      () {
    test('returnToLoginPage is not named under lib/page/', () {
      final pages = Directory('lib/page')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => f.readAsStringSync().contains('returnToLoginPage'))
          .map((f) => f.path)
          .toList()
        ..sort();

      expect(pages, isEmpty,
          reason:
              'found $pages. This was 2 — both recovery dialogs authored the '
              'label inline, so each one also had to know that the remote build '
              'wanted a different one. The label now lives in '
              'ReturnToLoginAction and reaches the dialog through '
              'SurfaceStrategy.sessionExitAction(); a page naming it again is a '
              'page that has an opinion about the exit, which is the thing being '
              'removed. Comments are NOT stripped here: unlike a mode read, '
              'there is no reason for a page to discuss this string either.');
    });

    test('and it is still named where the exit action lives', () {
      // Guards the cheap way to pass the test above. `grep == 0` is also what a
      // deleted feature looks like, and "the operator can no longer leave the
      // modal" would satisfy acceptance 5c while breaking the dialog —
      // `showRecoveryDialog` sets `barrierDismissible: false`.
      expect(
        File('lib/components/session/session_exit_actions.dart')
            .readAsStringSync(),
        contains('loc(context).returnToLoginPage'),
        reason: 'the local exit action no longer offers the login page. If it '
            'moved again, re-point this test; if it was removed, the local '
            'recovery dialog has no way out and surface_strategies_test.dart\'s '
            '"neither exit action is null" should have caught it first.',
      );
    });
  });
}
