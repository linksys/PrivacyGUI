import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../util/app_test_fonts.dart';

/// What a switched-off [NetworkRow] must keep, now that it dims through
/// `AppLowEmphasis` rather than `Opacity(0.5)` (#1456).
///
/// The substitution changed mechanism, not just the number: `AppLowEmphasis`
/// composites with `ColorFiltered`, chosen upstream over `RenderOpacity` because
/// that one drops the child's semantics. Nothing in the suite asserted either
/// half of what that has to preserve, so a later "disabled means disabled"
/// refactor could wrap the row in an `IgnorePointer` or `ExcludeSemantics` and
/// break the only affordance for switching a network back on, while every
/// existing test stayed green — the row still lays out, the switch is still
/// found, the label is still there to `find.text`.
///
/// **A switched-off network is not a disabled control.** It is listed, operable,
/// and its switch is how you turn it on again; low emphasis says "lower
/// priority", nothing more. That is why `row_blocks.dart` passes `onChanged`
/// through untouched on both branches.
///
/// The two other `AppLowEmphasis` sites from #1456 mean the opposite and are
/// deliberately not here: `_ChipGroupRow` and `_FilterChip` in
/// `usp_device_filter_panel.dart` *do* refuse input when disabled, and each says
/// so structurally at the call site — an enclosing `IgnorePointer(ignoring:
/// disabled)` and `onSelected: null`. Both are private, both need the panel's
/// providers, and neither's contract rests on what the wrapper does.
///
/// Untagged on purpose: this belongs to the unit job. It is not a layout gate
/// carrier, and `dart_test.yaml` counts those.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  /// The wrapper this file is about, told apart from the kit's own.
  ///
  /// `find.byType(AppLowEmphasis)` is not the right question: `AppSwitch` wraps
  /// its *own* track in one whenever `onChanged` is null (`app_switch.dart:201`),
  /// as does `AppIconButton`, so a bare count answers "how many de-emphasised
  /// things are on screen" — one for a row that is not de-emphasised at all, two
  /// for one that is. The row's wrapper is the one above the tile.
  Finder rowWrapper() => find.ancestor(
        of: find.byType(AppListTile),
        matching: find.byType(AppLowEmphasis),
      );

  /// Everything a screen reader can observe about the row, as one comparable
  /// value: the label of every node in the tile's semantics subtree, in order.
  ///
  /// Measured at v3.1.0, that is **one** node reading `"List tile"` — and it is
  /// the same node on both branches, which is what this file asserts. Two
  /// separate facts sit behind that one string, and only the first belongs to
  /// #1456:
  ///
  /// * `AppLowEmphasis` subtracts nothing. Swap it for `Opacity`, or add an
  ///   `ExcludeSemantics` while "fixing" the disabled look, and the disabled
  ///   capture stops matching the enabled one. Measured, not assumed: wrapping
  ///   the disabled branch in `ExcludeSemantics` turns this into `"List tile"`
  ///   vs `""`, so an equality assertion over a one-node tree is not a
  ///   tautology.
  /// * The label is not the network's name. `AppListTile` wraps its content in
  ///   `ExcludeSemantics` on purpose (`app_list_tile.dart:182`) and publishes
  ///   `semanticLabel ?? SemanticRoleLabel.listTile`, whose English default is
  ///   the literal `'List tile'` (`semantic_role_labels.dart:167`). `NetworkRow`
  ///   passes no `semanticLabel`, so the SSID, the band badges, the client count
  ///   and the switch are all unreachable, and the one thing announced is an
  ///   untranslated role name. That is a real defect, it is identical before and
  ///   after this PR, and fixing it is a `semanticLabel:` at the call site plus
  ///   an upstream decision about the role default — neither of which is a bump.
  ///   Asserting the current label here would pin the defect; asserting equality
  ///   across the two branches does not, and still fails the day someone passes
  ///   a label and only one branch gets it.
  String rowSemantics(WidgetTester tester) {
    final labels = <String>[];
    void walk(SemanticsNode node) {
      labels.add('"${node.label}"');
      node.visitChildren((child) {
        walk(child);
        return true;
      });
    }

    walk(tester.getSemantics(find.byType(AppListTile)));
    return labels.join(' > ');
  }

  Future<void> pumpNetworkRow(
    WidgetTester tester, {
    required bool isEnabled,
    ValueChanged<bool>? onChanged,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        // `AppLowEmphasis` reads `Theme.of(context).extension<AppDesignTheme>()!`
        // with a bang — under a bare `ThemeData` the disabled branch throws a
        // null-check error rather than picking a fallback. So a host for this
        // widget has to carry the extension, which `AppTheme.create` is what
        // supplies.
        theme: AppTheme.create(
          brightness: Brightness.light,
          seedColor: Colors.blue,
          designThemeBuilder: (c) =>
              CustomDesignTheme.fromJson({'style': 'flat'}),
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: NetworkRow(
            ssidName: 'Living Room',
            bands: const ['5GHz'],
            isEnabled: isEnabled,
            clientCount: 3,
            onChanged: onChanged,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('low emphasis is applied to exactly one of the two states', () {
    testWidgets('an enabled row is not wrapped at all', (tester) async {
      await pumpNetworkRow(tester, isEnabled: true, onChanged: (_) {});

      // The ternary, not `Opacity(opacity: isEnabled ? 1.0 : ...)`: an enabled
      // row now costs no wrapper rather than a no-op one.
      expect(rowWrapper(), findsNothing);
      expect(find.text('Living Room'), findsOneWidget);
    });

    testWidgets('a switched-off row is wrapped once, around the whole tile',
        (tester) async {
      await pumpNetworkRow(tester, isEnabled: false, onChanged: (_) {});

      expect(
        rowWrapper(),
        findsOneWidget,
        reason: 'the whole tile is the low-emphasis subtree, not the label '
            'alone — that is the difference from tinting one colour',
      );
    });
  });

  group('what dimming must not take away', () {
    testWidgets('the switch of a switched-off row still toggles it back on',
        (tester) async {
      final calls = <bool>[];
      await pumpNetworkRow(
        tester,
        isEnabled: false,
        onChanged: calls.add,
      );

      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();

      expect(
        calls,
        [true],
        reason: 'a switched-off network is operable — the low-emphasis wrapper '
            'is a visual treatment and must stay hit-testable',
      );
    });

    testWidgets('dimming subtracts nothing from the semantics tree',
        (tester) async {
      // Disposed inline rather than through `addTearDown`: tear-downs run
      // *after* the framework's end-of-test check for live handles, so the
      // deferred form fails the test it was meant to clean up after.
      final handle = tester.ensureSemantics();

      await pumpNetworkRow(tester, isEnabled: true, onChanged: (_) {});
      final enabled = rowSemantics(tester);

      await pumpNetworkRow(tester, isEnabled: false, onChanged: (_) {});

      expect(
        rowSemantics(tester),
        enabled,
        reason: 'this is why ui_kit composites with ColorFiltered instead of '
            'RenderOpacity — wrapping the row must not cost a node or a label',
      );

      handle.dispose();
    });
  });
}
