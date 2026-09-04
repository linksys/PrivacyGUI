import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The transition #1471 is about, asserted instead of photographed.
///
/// ## The defect
///
/// `AppExpansionPanel`'s full mode feeds the panel style's animation duration
/// straight into `AnimatedSize` (`app_expansion_panel.dart`, `_buildFullPanel`),
/// and `AnimatedSize` cannot take `Duration.zero`: expanding throws
///
/// > A RenderAnimatedSize was mutated in its own performLayout implementation.
///
/// which is a debug-only re-entrancy check — hence a failing test rather than a
/// red screen in a release build, and hence something only a test can report.
/// Two independent paths produce zero:
///
/// - **The theme.** `pixel` and `terminal` author `AnimationSpec.instant`
///   deliberately — the instant snap *is* those styles — and both are public
///   entries in `CustomDesignTheme.availableStyles`. The set is derived below
///   rather than named, so a style that turns instant tomorrow is covered.
/// - **Reduce motion.** `AnimationSpec.durationFor` resolves to `Duration.zero`
///   wherever `MediaQuery.disableAnimationsOf` is true (WCAG 2.3.3), for *every*
///   style. That is not an exotic setting here: `golden_runner.dart:365` turns it
///   on for every golden in the suite, which is why the support page's
///   `all_expanded` interaction throws — in all 26 locales.
///
/// ## Why nothing already sees it
///
/// It needs a *transition*. The throw happens while the panel is laid out during
/// a tap-driven expand, so a golden that renders the panel already expanded — the
/// way ui_kit's own matrix does, via `initialExpandedIndices` — never reaches it.
/// The screenshot suite is blind to this by construction, which is #1475's
/// blindness in its other form: there, a fact too small to move enough pixels;
/// here, a fact that is not in any frame a golden captures.
///
/// Three app surfaces build the affected full mode: `faq_list_view.dart`,
/// `usp_support_view.dart` and `step_result_tile.dart`.
/// `login_local_view.dart` uses `compactSingle`, whose `_buildCompactPanel` has
/// no `AnimatedSize` at all, and is unaffected.
///
/// ## What is skipped, and what is not
///
/// The zero-duration arms are red until ui_kit v3.1.1 (fixed upstream as
/// `linksys/privacyGUI-UI-kit#88`), so they ship skipped. The control and the
/// pin tripwire do not: the control keeps the harness honest — if the panel or
/// theme API moves, it fails now rather than at un-skip time — and the tripwire
/// fails the moment the ui_kit ref leaves v3.1.0, which is the only event that
/// makes the skips wrong.
///
/// Measured at v3.1.0 with `flutter test <this file> --run-skipped`: **3 pass, 3
/// fail** — the control, the sweep guard and the tripwire pass; reduce motion,
/// `pixel` and `terminal` fail, each on the line above. That is the reading that
/// makes the red attributable to `Duration.zero` rather than to the harness, and
/// it is how to check the fix when the pin moves.
void main() {
  /// The ui_kit ref the skips below are waiting on. See the tripwire.
  const blockedAtRef = 'v3.1.0';
  const blockedBy =
      'AnimatedSize cannot take Duration.zero — fixed upstream in '
      'privacyGUI-UI-kit#88, lands in v3.1.1 (#1471)';

  const header = 'What is a mesh node?';
  const content = 'A node extends the network.';

  AppDesignTheme designThemeOf(String style) =>
      CustomDesignTheme.fromJson({'style': style});

  ThemeData themeOf(String style) => AppTheme.create(
        brightness: Brightness.light,
        seedColor: Colors.blue,
        designThemeBuilder: (_) => designThemeOf(style),
      );

  /// A panel in the shape the three affected pages build it, under [style], with
  /// reduce motion applied the way `golden_runner.dart` applies it: inside the
  /// app, so the panel actually observes it.
  Widget host(String style, {required bool reduceMotion}) => MaterialApp(
        theme: themeOf(style),
        builder: (context, child) => MediaQuery(
          data:
              MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: AppExpansionPanel.single(
            headerTitle: header,
            content: const Text(content),
          ),
        ),
      );

  /// Taps the header and lets the size transition run. Deliberately not
  /// `pumpAndSettle`: a throw during layout has to surface as an exception this
  /// test reads, not as a settle that never happens.
  Future<void> expand(WidgetTester tester) async {
    await tester.tap(find.text(header));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // The expand icon is a `flutter_animate` subtree whose `initState` schedules
    // a zero-duration restart timer, and the tap remounts it. The timer is
    // created *during* the pump above, so it needs a frame that elapses the clock
    // — `pump()` with no duration does not, and the test would then fail on a
    // pending timer instead of on what it is about.
    await tester.pump(const Duration(milliseconds: 1));
  }

  /// Every shipped style whose expansion panel authors a zero duration with no
  /// help from reduce motion.
  final instantStyles = [
    for (final style in CustomDesignTheme.availableStyles)
      if (designThemeOf(style).expansionPanelStyle.animation.duration ==
          Duration.zero)
        style,
  ];

  test('at least one shipped style snaps instantly', () {
    // Not a claim about which ones: this only keeps the per-style arm below from
    // becoming a silent no-op. If it ever fails, no style authors zero any more
    // and that arm should be deleted — reduce motion is then the only path, and
    // it is covered on its own.
    expect(
      instantStyles,
      isNotEmpty,
      reason: 'the per-style arm generates one test per instant style, so an '
          'empty set makes it vacuous rather than green',
    );
  });

  testWidgets('a panel expands when the transition has a duration',
      (tester) async {
    // The control, and it is not skipped. Everything the two arms below rely on
    // — the panel API, the theme plumbing, the tap target, the finders — is
    // exercised here on the one path that works today, so a red arm means
    // Duration.zero and not a stale harness.
    await tester.pumpWidget(host('flat', reduceMotion: false));
    expect(find.text(content), findsNothing);

    await expand(tester);

    expect(tester.takeException(), isNull);
    expect(find.text(content), findsOneWidget);
  });

  // Grouped so the skip carries a reason: `testWidgets` narrows `skip` to
  // `bool?`, while `group` keeps package:test's `Object?` and prints the string.
  group('a zero-duration transition', () {
    testWidgets('expands the panel under reduce motion', (tester) async {
      // The path the whole golden suite takes, on the app's own style. Zero comes
      // from the accessibility setting here, not from the theme, so this holds
      // for every style the app can be built with.
      await tester.pumpWidget(host('flat', reduceMotion: true));

      await expand(tester);

      expect(tester.takeException(), isNull,
          reason: 'reduce motion means no transition, not no expansion — WCAG '
              '2.3.3 asks for the end state, immediately');
      expect(find.text(content), findsOneWidget);
    });

    for (final style in instantStyles) {
      testWidgets('expands the panel under the $style style\'s instant snap',
          (tester) async {
        // No reduce motion: the style itself authors Duration.zero, so this is
        // the theme half of the same defect, and it reaches users who never
        // touched an accessibility setting.
        await tester.pumpWidget(host(style, reduceMotion: false));

        await expand(tester);

        expect(tester.takeException(), isNull);
        expect(find.text(content), findsOneWidget);
      });
    }
  }, skip: blockedBy);

  test('the skips above expire when ui_kit moves', () {
    // A skip with a reason still proves nothing, and this one is only correct
    // while the fix is unreleased. `ui_kit_pin_test.dart` guards the ref's shape
    // and parity; this guards its *value*, and only for as long as #1471 is
    // open — the failure message is the instruction, and deleting this test is
    // part of taking the skips off.
    final pubspec = File('pubspec.yaml');
    expect(pubspec.existsSync(), isTrue,
        reason: 'run from the package root, or this guard passes vacuously');

    final ref = RegExp(r'^ +ref: *"?([^"\n]+?)"? *$', multiLine: true)
        .allMatches(pubspec.readAsStringSync())
        .map((m) => m.group(1))
        .toSet();

    expect(
      ref,
      contains(blockedAtRef),
      reason:
          'ui_kit no longer resolves to $blockedAtRef, so the skips in this '
          'file may be hiding a fix: drop `skip: blockedBy` from both arms, run '
          'this file, and delete this test if they pass',
    );
  });
}
