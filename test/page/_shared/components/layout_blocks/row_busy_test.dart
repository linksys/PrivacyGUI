import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../util/app_test_fonts.dart';

/// What [ToggleRow] and [NetworkRow] must show while a USP write is in flight,
/// now that busy is the kit's own state (`AppSwitch.isLoading`, ui_kit v3.3.0)
/// rather than a spinner these rows swapped in for the switch (#1542).
///
/// The two facts below are the ones the hand-rolled version could not hold, and
/// neither was asserted anywhere before this file:
///
/// * **The switch does not move or resize.** Both rows used to replace it with a
///   hard-coded box, and neither box was the size of the switch it stood in for.
///   Measured across three design styles (flat / neo / glass): [ToggleRow]'s
///   switch is `44 × 48`, `44 × 48`, `44 × 44` against a `44 × 26` loader slot,
///   and [NetworkRow]'s is `56 × 48`, `56 × 48`, `52 × 44` against a box
///   hard-coded to `52 × 32`. So the slot changed size the moment a write
///   started — in [NetworkRow] by a different amount per style, since the box was
///   a literal while the switch's footprint is
///   `max(44, 52 × spacingFactor)` by `max(44, 32 × spacingFactor)` plus the
///   style's focus-ring allowance. ([ToggleRow] escapes the per-style part only
///   because `scale: 0.8` *replaces* `theme.spacingFactor` rather than
///   multiplying it.) The kit draws over its own control, so there is no second
///   footprint to keep in sync with any of that.
/// * **Busy is not the same picture as unavailable.** The rows now hand the
///   switch the localised `processing` string, which the replaced `AppLoader`
///   never carried in either row. Not yet *announced*, though — see the last
///   case: `AppListTile` excludes its whole content from the semantics tree, so
///   the assertions are on the property the row passes rather than on the node.
///
/// Untagged on purpose: this is the unit job, not a layout gate carrier.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // The rows size their label column from real glyph metrics, and these
    // assertions compare pixel rects.
    await loadAppFonts();
  });

  Future<void> pumpRow(WidgetTester tester, Widget row) async {
    await tester.pumpWidget(
      MaterialApp(
        // `AppLowEmphasis` and `BusyFigureLayer` both read
        // `Theme.of(context).extension<AppDesignTheme>()!` with a bang, so the
        // host has to carry the extension — a bare `ThemeData` throws.
        theme: AppTheme.create(
          brightness: Brightness.light,
          seedColor: Colors.blue,
          designThemeBuilder: (c) =>
              CustomDesignTheme.fromJson({'style': 'flat'}),
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // `Column(stretch)` rather than a bare `Scaffold(body: row)`, and it is
        // the rect assertions below that need it: a row handed a tight height
        // stretches [AppListTile]'s slots to fill it, so the switch measured
        // 44 × **576** and an equality on that rect could not see the vertical
        // half of what it claims to check. One row in a stretched column is also
        // how the cards actually lay these out.
        home: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [row],
          ),
        ),
      ),
    );
    // Bounded, not `pumpAndSettle`: the busy figure animates forever.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  AppSwitch theSwitch(WidgetTester tester) =>
      tester.widget<AppSwitch>(find.byType(AppSwitch));

  group('ToggleRow', () {
    testWidgets('a busy row keeps the switch, at the same rect',
        (tester) async {
      await pumpRow(tester, ToggleRow(value: true, title: 'HTTP'));
      final idleRect = tester.getRect(find.byType(AppSwitch));
      expect(theSwitch(tester).isLoading, isFalse);

      await pumpRow(
        tester,
        ToggleRow(value: true, title: 'HTTP', isLoading: true),
      );

      expect(find.byType(AppLoader), findsNothing,
          reason: 'busy is the kit\'s own layer over the track now; a separate '
              'AppLoader in a row means the spinner swap came back');
      expect(find.byType(AppSwitch), findsOneWidget);
      expect(theSwitch(tester).isLoading, isTrue);
      expect(tester.getRect(find.byType(AppSwitch)), idleRect,
          reason: 'the busy treatment must not resize or displace the switch');
    });

    testWidgets('a busy switch swallows taps', (tester) async {
      // What lets a call site stop passing `onChanged: isLoading ? null : …`:
      // the control refuses input for the duration on its own.
      final calls = <bool>[];
      await pumpRow(
        tester,
        ToggleRow(
          value: false,
          title: 'HTTP',
          isLoading: true,
          onChanged: calls.add,
        ),
      );

      await tester.tap(find.byType(AppSwitch));
      await tester.pump();

      expect(calls, isEmpty);
    });

    testWidgets('the busy hint is the localised string, not the kit fallback',
        (tester) async {
      await pumpRow(
        tester,
        ToggleRow(value: true, title: 'HTTP', isLoading: true),
      );

      expect(theSwitch(tester).busySemanticLabel, 'Processing...');
    });
  });

  group('NetworkRow', () {
    Widget networkRow({bool isLoading = false}) => NetworkRow(
          ssidName: 'Living Room',
          bands: const ['5GHz'],
          isEnabled: true,
          clientCount: 3,
          isLoading: isLoading,
        );

    testWidgets('a busy row keeps the switch, at the same rect',
        (tester) async {
      await pumpRow(tester, networkRow());
      final idleRect = tester.getRect(find.byType(AppSwitch));
      expect(theSwitch(tester).isLoading, isFalse);

      await pumpRow(tester, networkRow(isLoading: true));

      expect(find.byType(AppLoader), findsNothing);
      expect(find.byType(AppSwitch), findsOneWidget);
      expect(theSwitch(tester).isLoading, isTrue);
      expect(tester.getRect(find.byType(AppSwitch)), idleRect,
          reason: 'the busy treatment must not resize or displace the switch');
    });

    testWidgets('the busy hint is the localised string, not the kit fallback',
        (tester) async {
      await pumpRow(tester, networkRow(isLoading: true));

      expect(theSwitch(tester).busySemanticLabel, 'Processing...');
    });

    testWidgets('nothing in the row reaches the semantics tree to say it',
        (tester) async {
      // Measured, and the reason the two assertions above are on the widget
      // rather than on the rendered node: `AppListTile` wraps its content in
      // `ExcludeSemantics` and publishes only its own role label, so the switch
      // — busy or not — is not in the semantics tree at all. That is the same
      // pre-existing defect `network_row_low_emphasis_test.dart` measured for
      // the SSID, the band badges and the client count, it is a kit-side
      // decision, and it is identical before and after #1542. Stated here so a
      // later "the hint is announced" claim has to come with the fix.
      // `try`/`finally` rather than `addTearDown`: tear-downs run *after* the
      // framework's live-handle check, so a leaked handle would add a second
      // failure on top of whichever assertion actually regressed.
      final handle = tester.ensureSemantics();
      try {
        await pumpRow(tester, networkRow(isLoading: true));

        expect(tester.getSemantics(find.byType(AppSwitch)).hint, isEmpty);
      } finally {
        handle.dispose();
      }
    });
  });
}
