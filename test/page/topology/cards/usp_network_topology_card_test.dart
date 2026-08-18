@Tags(['ui'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/topology/helpers/node_identifier.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../util/dashboard/dashboard_card_probe.dart';

/// Tapping a node on the dashboard topology card must not throw.
///
/// ## What throws, and at exactly which width
///
/// `ui_kit`'s graph view positions its node-detail panel with
/// `panelLeft.clamp(32.0, stackWidth - panelWidth - 32)`
/// (`topology_graph_view.dart:810`, v2.38.0), where `panelWidth` is 320. Neither
/// limit is guarded, so as soon as the graph view is narrower than **384px** the
/// upper limit falls below the lower one and `clamp` throws
/// `ArgumentError.value(32.0)` — reported as `Invalid argument: 32`, from inside
/// a `LayoutBuilder` during layout, on every frame until the panel is dismissed.
///
/// Measured by sweeping this card at 8px steps: a graph view of 385px is clean
/// and 384px is the boundary; the card is 35px wider than the graph view it
/// contains, so **a card narrower than 419px cannot be tapped**. Every width the
/// grid can give this card at or below 4 columns is in that band — its narrowest
/// realizations are 261px and 288px — which is why this is not an edge case.
///
/// The same function has the same bug on the other axis one line up:
/// `(nodeY - 50).clamp(60.0, stackHeight - 200)` (`:798`) throws
/// `Invalid argument: 60` for a graph view shorter than 260px, when the tapped
/// node sits in the upper 60% of the view. The grid cannot reach it today: this
/// card's declared floor of `minHeightRows: 3` is a 392px card, and that is a
/// 260px graph view — the boundary value exactly. One row shorter and the height
/// twin fires too, so the case below pumps that floor deliberately rather than
/// the 5 rows the card's `strict(5)` strategy hands it on a real dashboard.
///
/// ## What the card does about it
///
/// The kit's clamps are guarded upstream (`fix/topology-detail-panel-clamp`), but
/// a guard can only make the panel *yield*: at 261px of card the panel it can
/// still place is 197px wide, inside a `ClipRect`. So the card decides the
/// presentation from its own box — the panel where the panel fits, a dialog where
/// it does not — and that decision is what these tests measure. The two branches
/// answer exactly the same taps, which is why a client tap has a case of its own.
///
/// ## Why the assertion is `takeException`, not an overflow count
///
/// [probeCardOverflow] collects RenderFlex overflows and forwards everything
/// else to the framework's own handler, so a genuine exception raised inside
/// [probeCardOverflow]'s `after` hook lands in the binding's pending list. Taking
/// it explicitly is what turns "the tap threw" into a named failure rather than a
/// teardown surprise.
///
/// ## Mutation table (Article II AC13)
///
/// Applied to `usp_network_topology_card.dart`, each verified to fail the tests
/// named — and only those:
///
/// | Mutation | Killed by |
/// |---|---|
/// | `hasRoomForPanel` forced `true` (the fix reverted) | 261px, 288px, and the under-floor case — `ArgumentError: Invalid argument(s): 32.0` / `60.0` |
/// | the height half of the predicate dropped | the under-floor case |
/// | `hasRoomForPanel` forced `false` (dialog everywhere) | 512px desktop — a dialog where the panel has room |
/// | the `isClient || isInternet` skip dropped | the client case — a dialog the wide card never shows |
void main() {
  final spec = UspWidgetSpecs.getById('topology')!;
  final rows = spec.getConstraints(DisplayMode.normal).minHeightRows;

  // Every width the grid can realize this card at, plus the desktop width. The
  // desktop one is not decoration: it is the only case where the in-place panel
  // is the expected presentation, so it is what stops "always open the dialog"
  // from passing as a fix.
  final cases = [...widthCasesFor(spec), desktopCaseFor(spec)];

  Future<void> tapMaster(WidgetTester tester) async {
    final master = find.bySemanticsIdentifier(kTopologyMasterIdentifier);
    expect(master, findsOneWidget, reason: 'no master node on the card to tap');
    await tester.tap(master, warnIfMissed: false);
    // Two frames, not one: the narrow branch pushes a dialog route, and the
    // second frame is where its content is built.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('tapping a node', () {
    for (final wc in cases) {
      testWidgets('shows the master detail at ${wc.widthKey}px (${wc.label})',
          (tester) async {
        final handle = tester.ensureSemantics();
        await probeCardOverflow(
          tester,
          cardId: 'topology',
          widthCase: wc,
          cardHeightRows: rows,
          tabIndex: 0,
          locale: const Locale('en'),
          after: tapMaster,
        );
        handle.dispose();

        expect(tester.takeException(), isNull);
        // The positive control, on every width rather than only the wide one: a
        // fix that simply stopped opening anything would satisfy the no-throw
        // assertion above at every narrow width and be indistinguishable from a
        // working card. `S/N` is rendered by nothing on this card except the node
        // detail — in the panel where there is room for it, in a dialog where
        // there is not.
        expect(
          find.text('S/N'),
          findsOneWidget,
          reason: 'the node detail did not appear',
        );

        // And *which* presentation appeared, so "always use the dialog" is a
        // distinguishable outcome rather than an equally green one. Every width
        // the grid gives this card at or below its 12-column ceiling is under the
        // panel's minimum — measured, 261px and 288px — while the desktop
        // realization at 512px is over it. If the grid's arithmetic moves, this is
        // the assertion that says so.
        expect(
          find.byType(AppDialog),
          wc.label == 'desktop' ? findsNothing : findsOneWidget,
          reason: wc.label == 'desktop'
              ? 'a card with room for the panel should not open a dialog'
              : 'a card too narrow for the panel should open a dialog',
        );
      });
    }

    // The dialog answers exactly the taps the panel would have answered, and no
    // more: a client gets no detail on a card with room either — the graph view
    // fires `onNodeTap` for clients and skips its own panel — so the narrow
    // branch must not invent one for them.
    testWidgets('opens nothing for a client', (tester) async {
      final narrowest = widthCasesFor(spec).first;
      final handle = tester.ensureSemantics();
      await probeCardOverflow(
        tester,
        cardId: 'topology',
        widthCase: narrowest,
        cardHeightRows: rows,
        tabIndex: 0,
        locale: const Locale('en'),
        after: (tester) async {
          // By pattern rather than by name: the client identifiers carry a MAC
          // suffix from the fixture, and which client is tapped does not matter.
          final client =
              find.bySemanticsIdentifier(RegExp('^topology-node-client-'));
          expect(client, findsWidgets,
              reason: 'no client node on the card to tap');
          await tester.tap(client.first, warnIfMissed: false);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
        },
      );
      handle.dispose();

      expect(tester.takeException(), isNull);
      expect(find.byType(AppDialog), findsNothing);
      expect(find.text('S/N'), findsNothing);
    });

    // The other axis, at a width that has room to spare — so the height half of
    // the card's predicate is the only thing that can decide this case, and
    // dropping it is a distinguishable mutation rather than a silent one.
    //
    // One row under this card's declared floor, which the grid cannot hand it
    // today: three rows is 392px, whose content region is 260px, and 260 is the
    // boundary exactly. The row below it is where the panel's vertical `clamp`
    // inverts, so this pumps the size a spec change would produce rather than
    // waiting for the spec change to produce a red screen.
    testWidgets('shows the master detail one row under the declared floor',
        (tester) async {
      final handle = tester.ensureSemantics();
      await probeCardOverflow(
        tester,
        cardId: 'topology',
        widthCase: desktopCaseFor(spec),
        cardHeightRows: rows - 1,
        tabIndex: 0,
        locale: const Locale('en'),
        after: tapMaster,
      );
      handle.dispose();

      expect(tester.takeException(), isNull);
      expect(
        find.text('S/N'),
        findsOneWidget,
        reason: 'the node detail did not appear',
      );
      expect(
        find.byType(AppDialog),
        findsOneWidget,
        reason: 'a card too short for the panel should open a dialog',
      );
    });
  });
}
