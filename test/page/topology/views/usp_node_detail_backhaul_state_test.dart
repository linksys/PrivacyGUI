import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/topology/views/components/backhaul_signal_indicator.dart';
import 'package:privacy_gui/page/topology/views/usp_node_detail_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../layout_gate/surface.dart';
import '../../../mocks/provider_overrides/mock_topology.dart';
import '../../../mocks/test_data/scenes/topology_scene_data.dart';
import '../../../util/settle.dart';

/// Behaviour of the node-detail backhaul card when the backhaul reports **no
/// medium** (#1430 review, W7/qodo#1).
///
/// ## Why this file exists
///
/// `_buildBackhaulCard` branched on two states — `if (backhaul.isWifi)` /
/// `else if (backhaul.isEthernet)` — and `BackhaulInfo` has three: `hasInfo`
/// false is neither. In that third state every block in the card was gated off
/// (no parent row, no upload/download because both rates are null, no PHY-rate or
/// last-contact row because `phyRate` is 0 and `lastContactTime` is null), so the
/// card rendered as a title and nothing else, with nothing on screen saying why.
///
/// It is not a hypothetical state. #1430's liveness change makes a node whose
/// DataElements subtree never arrived stay **online** and therefore navigable
/// (`SlaveNode.livenessKnown`), and that is precisely the node with no backhaul —
/// the backhaul is read from the same DataElements subtree. So the third arm was
/// added with the C1 fix that made it reachable, and this file is what keeps it.
///
/// ## Not the overflow suite next door
///
/// `usp_node_detail_backhaul_overflow_test.dart` measures *widths* of the same
/// card, is `layout-gate`-tagged, loads real fonts and owns a mutation ledger for
/// captions. This file asserts *which arm builds* and is untagged, so it runs in
/// `run_tests.sh`'s unit job (`--exclude-tags="golden||loc||ui||layout-gate"`).
/// Neither belongs in the other: the overflow file's header explicitly refuses
/// fixtures that "pump untouched code that cannot fail", and a fixture that
/// renders one short label in a full-width block is exactly that for a width
/// sweep. The new arm's caption row is also the Ethernet arm's shape, which that
/// file records as measured clean across all 26 locales × 6 widths, so there is
/// no width question left to ask here.
///
/// ## Mutation
///
/// Measured, not assumed. Narrowing the arm to `else if (backhaul.hasInfo)` —
/// which is the arm still present but never reached — fails all three widget
/// tests: the interface block is not found, `Icons.help_outline` is not found, and
/// the card is back to `Found 0 widgets with type "LayoutBlock" descending from`
/// its own header, which is the regression stated in the words the user would use.
/// The precondition test stays green, as it must: it is about the fixture, not the
/// arm.
void main() {
  final state = slaveNodeNoBackhaul;
  final node = state.node as SlaveNode;

  test('the fixture is the no-medium state the arm exists for', () {
    // Asserted rather than assumed: every test below reads a green result from a
    // fixture that still carries no medium, and a drifted fixture would route
    // through the Wi-Fi arm and pass on the wrong branch.
    expect(node.backhaul.hasInfo, isFalse,
        reason: 'the third arm is reached only when `hasInfo` is false');
    expect(node.backhaul.isWifi, isFalse);
    expect(node.backhaul.isEthernet, isFalse);

    // The bare-header premise: these four are what the rest of the card is gated
    // on, so with the arm removed there is nothing left in it but the title.
    expect(state.parentNode, isNull);
    expect(node.backhaul.uplinkRate, isNull);
    expect(node.backhaul.downlinkRate, isNull);
    expect(node.backhaul.phyRate, 0);
    expect(node.backhaul.lastContactTime, isNull);

    // Why the page is reachable at all in this state (#1430 review, C1).
    expect(node.livenessKnown, isFalse);
    expect(node.isOnline, isTrue,
        reason:
            'a node with no DataElements liveness information stays online, '
            'which is what puts a detail page in front of this backhaul');
  });

  /// Pumps the real node-detail page for [state] at a desktop surface.
  ///
  /// [pageSurfaceHost] rather than a local tree: it is the repo's one answer to
  /// "how do I pump a real view" (`test/util/detail_view_probe.dart`'s header
  /// argues the case, and `test/util/settle.dart`'s says the unit lane pumps the
  /// same pages to assert behaviour). A copy here would be the drift both warn
  /// about.
  Future<void> pumpNodeDetail(WidgetTester tester) async {
    await setLayoutSurface(tester, const Size(1280, 1800));
    await tester.pumpWidget(pageSurfaceHost(
      view: UspNodeDetailView(deviceId: node.deviceId),
      locale: const Locale('en'),
      overrides: nodeDetailOverrides(state),
    ));
    // The node card renders an `AppImage.provider` whose stream never completes
    // under the test binding, so `pumpAndSettle` would time out on it.
    await settleIgnoringAnimations(tester);
  }

  Finder interfaceBlock() => find.ancestor(
        of: find.text('Interface'),
        matching: find.byType(LayoutBlock),
      );

  testWidgets(
      'a backhaul with no medium renders the interface block as Unknown',
      (tester) async {
    await pumpNodeDetail(tester);

    expect(interfaceBlock(), findsOneWidget,
        reason: 'the third arm must build an interface block — `Interface` is '
            'rendered nowhere else on this page');
    expect(
      find.descendant(of: interfaceBlock(), matching: find.text('Unknown')),
      findsOneWidget,
      reason: 'the medium is unreported, and the block must say so rather than '
          'naming one',
    );
  });

  testWidgets('the no-medium block is neither the Wi-Fi nor the Ethernet arm',
      (tester) async {
    await pumpNodeDetail(tester);

    // The icon is what tells the three arms apart on screen: `Icons.wifi`,
    // `Icons.settings_ethernet`, `Icons.help_outline`. Scoped to the block
    // because the connected-device rows below carry their own `Icons.wifi`.
    expect(
      find.descendant(
          of: interfaceBlock(), matching: find.byIcon(Icons.help_outline)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: interfaceBlock(), matching: find.byIcon(Icons.wifi)),
      findsNothing,
    );
    expect(
      find.descendant(
          of: interfaceBlock(), matching: find.byIcon(Icons.settings_ethernet)),
      findsNothing,
    );

    // `BackhaulSignalIndicator` is the Wi-Fi arm's other half and has no reading
    // to show here; it is gated on `signalStrength != null`, which is a second,
    // independent way the Wi-Fi arm could have leaked in.
    expect(find.byType(BackhaulSignalIndicator), findsNothing);
  });

  testWidgets('the backhaul card is no longer a bare header', (tester) async {
    await pumpNodeDetail(tester);

    // The regression stated as the user sees it: the card has a title, and with
    // the arm removed that title is all it has.
    final card = find.ancestor(
      of: find.text('Backhaul Connection'),
      matching: find.byType(AppCard),
    );
    expect(card, findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.byType(LayoutBlock)),
      findsOneWidget,
      reason: 'the card must carry content under its header, and exactly one '
          'block — a second would mean another arm built as well',
    );
  });
}
