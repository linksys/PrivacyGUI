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
/// ## These tests are known to be capable of failing
///
/// Fixed upstream in ui_kit **v3.2.0** — `fix(expansion_panel): drop the tween
/// instead of handing AnimatedSize a zero`, ui_kit#88 — which is the ref this
/// repository now pins.
///
/// The three zero-duration cases were written first, against v3.1.0, and shipped
/// skipped. Measured there with `--run-skipped`: **3 fail, 3 pass** — reduce
/// motion, `pixel` and `terminal` each failed on the line above, while the
/// control, the sweep guard and a since-deleted pin tripwire passed. That is the
/// one thing a green test cannot establish about itself, and it is why the
/// control below is worth its lines: it fails if the panel or theme API moves,
/// which would otherwise make all four green for the wrong reason.
void main() {
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
  });
}
