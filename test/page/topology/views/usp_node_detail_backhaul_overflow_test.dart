@Tags(['dashboard-card'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/topology/views/usp_node_detail_view.dart';

import '../../../golden_test/golden_framework/mocks/mock_topology.dart';
import '../../../golden_test/page/topology/fixtures/topology_test_data.dart';
import '../../../util/app_test_fonts.dart';
import '../../../util/detail_view_probe.dart';
import '../../../util/overflow_probe.dart';

/// Overflow tests for the node-detail backhaul interface tile (#1302).
///
/// ## Why this file exists
///
/// The tile's caption row was `Row(children: [Icon(size: 16), AppGap.xs(),
/// AppText.labelSmall(labelInterface)])` — an unconstrained caption sized to its
/// natural width. The tile shares a `Row` with the signal indicator as two
/// `Expanded`s, so the caption gets half the card and no more: `fi` needs 102.6dp
/// for `Käyttöliittymä` where the row has 99dp at 1280px.
///
/// Nothing else fails on this. The #1183 gate sweeps the dashboard's
/// `UspWidgetSpecs.all` registry, which does not contain this page; the golden
/// suite renders the tile and compares byte-equal against a baseline PNG that has
/// the overflow stripe baked in. Hence a test, and hence the `dashboard-card`
/// tag — `run_tests.sh` excludes `golden||loc||ui`, so a `ui`-tagged test would
/// not block a PR.
///
/// ## Only the Wi-Fi branch is guarded, deliberately
///
/// `_buildBackhaulCard` has a second caption row in its `else` branch (Ethernet
/// backhaul, `usp_node_detail_view.dart:383`) with exactly the same unguarded
/// shape. It is **out of scope for #1302 by decision**, not by oversight, so
/// these tests pump a Wi-Fi-backhaul fixture only. Do not "fix" the matrix by
/// adding an Ethernet fixture here: it would fail on untouched code. The Ethernet
/// row is only reachable at all when `backhaul.isEthernet`, and it is full-width
/// rather than half-width there, so it has 2× the room this one does.
///
/// The throughput cards below the tile are `DetailSpeedCard`s, guarded by
/// `usp_device_detail_speed_card_overflow_test.dart`; this fixture carries no
/// backhaul rates, so they do not render here.
///
/// ## Mutation ledger
///
/// Both groups were shown to fail against a mutation of the code they guard. An
/// overflow test that cannot fail is worse than no test, because it reports the
/// row as pinned.
///
///   | mutation                                    | what failed                    |
///   |---------------------------------------------|--------------------------------|
///   | caption's `Expanded` removed (pre-fix shape) | clean tile: ja +19px@1241, +12px@1280, +8px@320; fi +10px@1241, +3.6px@1280; da +2.5px@1241 |
///   | interface value given `maxLines: 1` + ellipsis | value stays whole |
void main() {
  setUpAll(() async {
    // Real fonts: under the Ahem block font every glyph is square and the
    // measured widths — the whole subject of this file — are fiction.
    await loadAppFonts();
  });

  final state = slaveNodeWithDevices;
  final node = state.node as SlaveNode;

  test('the fixture is a Wi-Fi backhaul node', () {
    // The guarded row is behind `if (isWifiBackhaul)`. If the fixture ever
    // becomes an Ethernet node, every test below would pass without rendering
    // the row at all, so assert the precondition instead of assuming it.
    expect(
      node.backhaul.isEthernet,
      isFalse,
      reason: 'slaveNodeWithDevices must keep a Wi-Fi backhaul — the interface '
          'tile these tests measure is only built for one',
    );
  });

  /// Pumps the real node-detail page once at [screenWidth] and returns the
  /// RenderFlex overflows beyond the gate's own tolerance.
  Future<List<OverflowIncident>> overflowsAt({
    required WidgetTester tester,
    required double screenWidth,
    required String tag,
  }) =>
      probeViewOverflow(
        tester,
        view: UspNodeDetailView(deviceId: node.deviceId),
        overrides: nodeDetailOverrides(state),
        screenWidth: screenWidth,
        locale: localeForTag(tag),
      );

  group('backhaul interface tile is clean (#1302)', () {
    /// The widths that carry signal, from sweeping all 26 locales against the
    /// pre-fix shape:
    ///
    /// - **1241px** — worst case (ja +19px). The page's 200px desktop margins
    ///   open just above 1240px, so a 1241px screen lays this row out *narrower*
    ///   than a 1240px one does.
    /// - **1280px** — the golden suite's desktop coordinate, where #1302 was
    ///   reported (ja +12px, fi +3.6px).
    /// - **320px** — the narrowest supported screen (ja +8px).
    ///
    /// 480px is absent on purpose: the tile is clean there in every locale, in
    /// the pre-fix shape too, so a test at that width could never fail.
    const widths = <double>[1241.0, 1280.0, 320.0];

    // Every locale that overflowed the pre-fix shape anywhere in the sweep.
    // `da` only breaks at 1241px and only by 2.5px — kept because it is the
    // margin this fix has to hold, not just the loudest case.
    //
    // The cross-product is deliberate: 6 of these 9 cells fail against the
    // pre-fix shape (the ledger lists which), and the other 3 are the same
    // near-miss locales at a width where they currently fit, held against a
    // translation growing later.
    for (final tag in ['ja', 'fi', 'da']) {
      for (final width in widths) {
        testWidgets(
          'no overflow at ${width.toStringAsFixed(0)}px in $tag',
          (tester) async {
            final overflows = await overflowsAt(
              tester: tester,
              screenWidth: width,
              tag: tag,
            );
            expect(
              overflows,
              isEmpty,
              reason: 'the backhaul interface tile overflows in $tag at '
                  '${width.toStringAsFixed(0)}px: ${overflows.join(', ')}',
            );
          },
        );
      }
    }
  });

  testWidgets('the interface value stays whole (#1302)', (tester) async {
    // Why the caption is allowed to ellipsize: the interface itself is spelled
    // out on the line below. That argument only holds while *that* line is never
    // clipped in turn — `Wi-Fi` shortened to `W…` names no interface.
    final expected = node.backhaul.linkType ?? node.backhaul.mediaType;

    await overflowsAt(tester: tester, screenWidth: 320.0, tag: 'ja');

    final finder = find.text(expected);
    expect(
      finder,
      findsOneWidget,
      reason: 'the interface value ($expected) must survive the degradation',
    );

    final text = tester.widget<Text>(finder);
    expect(
      text.overflow,
      isNot(TextOverflow.ellipsis),
      reason: 'the interface value must never ellipsize — it is the only place '
          'the medium is named once the caption is allowed to shorten',
    );
    expect(text.maxLines, isNull,
        reason: 'the interface value must not be line-capped');
  });
}
