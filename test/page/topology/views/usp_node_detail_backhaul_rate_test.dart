import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/detail_widgets.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/topology/providers/node_detail_provider.dart';
import 'package:privacy_gui/page/topology/views/usp_node_detail_view.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../layout_gate/surface.dart';
import '../../../mocks/provider_overrides/mock_topology.dart';
import '../../../mocks/test_data/scenes/topology_scene_data.dart';
import '../../../util/settle.dart';

/// The backhaul rate is never shown as a bare number (#1442, PM#124 REQ-12).
///
/// ## Why this file exists
///
/// The number is a **link rate between two mesh nodes** — 2882 Mbps on the bench.
/// A customer reading that next to their router will read it as their internet
/// connection, which is typically one or two orders of magnitude lower. So the
/// figure has to arrive with the statement that it is not internet speed.
///
/// ## Why the qualifier is a row of its own, and not part of the card's caption
///
/// The ticket's AC2 put it in `DetailSpeedCard`'s `label`, on the grounds that
/// that caption row already has a mutation-proven overflow guard while a new row
/// would have none. Measured, that placement cannot carry the sentence: the
/// caption slot on this page is **70.5dp at 1241px** (77dp at 1280, 81dp at 320,
/// 161dp at 480), and today's `Download` label already needs 297dp in `fr`,
/// 176dp in `fr_CA`, 154dp in `tr` and 143dp in `pl` — so that slot is *already*
/// ellipsized in about twenty locales at desktop widths, and `en` has roughly
/// 30dp of headroom left, about five characters.
///
/// An ellipsized caption is fine for `Upload`, because the number below carries
/// the reading (#1302). It is not fine for a qualifier: truncate it and the
/// information REQ-12 asks for is the part that disappears. The guard objection is
/// answerable — `usp_node_detail_backhaul_overflow_test.dart` now sweeps this row
/// — and legibility is not, so the placement moved with that measurement on the
/// record. Austin decided it on 2026-09-21.
///
/// ## Not a golden
///
/// AC4 asks for a widget test in those words, and this repo's goldens cannot serve
/// as one: baselines are gitignored so there is no shared baseline, and both CI
/// jobs exclude the `golden` tag. This file is untagged, so it runs in
/// `run_tests.sh`'s unit job.
void main() {
  final withRates = slaveNodeWithBackhaulRates;
  final withoutRates = slaveNodeWithBackhaulTiming;

  Future<void> pump(WidgetTester tester, UspNodeDetailState state) async {
    await setLayoutSurface(tester, const Size(1280, 1800));
    await tester.pumpWidget(pageSurfaceHost(
      view: UspNodeDetailView(deviceId: (state.node as SlaveNode).deviceId),
      locale: const Locale('en'),
      overrides: nodeDetailOverrides(state),
    ));
    // The node card's `AppImage.provider` stream never completes under the test
    // binding, so `pumpAndSettle` would time out on it.
    await settleIgnoringAnimations(tester);
  }

  late AppLocalizations loc;
  setUpAll(() async {
    loc = await AppLocalizations.delegate.load(const Locale('en'));
  });

  testWidgets('the fixture is the state the throughput row needs', (
    tester,
  ) async {
    // Asserted rather than assumed: the row is gated on the two rates, and a
    // drifted fixture would make every assertion below pass against a page that
    // renders no rate at all.
    final backhaul = (withRates.node as SlaveNode).backhaul;
    expect(backhaul.uplinkRate, isNotNull);
    expect(backhaul.downlinkRate, isNotNull);

    await pump(tester, withRates);
    expect(find.byType(DetailSpeedCard), findsNWidgets(2));
  });

  testWidgets('the rate is shown with the not-internet-speed qualifier', (
    tester,
  ) async {
    await pump(tester, withRates);

    expect(
      find.text(loc.backhaulRateNotInternetSpeed),
      findsOneWidget,
      reason: 'the rate must not appear as a bare number',
    );
  });

  testWidgets('the qualifier sits with the rates, not elsewhere on the page', (
    tester,
  ) async {
    // Located relative to the cards rather than anywhere on the page: a sentence
    // at the bottom of a long scroll does not qualify a number at the top, and an
    // unscoped `find.text` cannot tell the two apart.
    await pump(tester, withRates);

    // `.first` is the innermost `Column` above the card — the backhaul card's own
    // — and that is the point: the outermost one is the page body, where this
    // assertion would hold with the sentence parked at the bottom of the scroll.
    final cardColumn = find
        .ancestor(
          of: find.byType(DetailSpeedCard).first,
          matching: find.byType(Column),
        )
        .first;
    expect(
      find.descendant(
        of: cardColumn,
        matching: find.text(loc.backhaulRateNotInternetSpeed),
      ),
      findsOneWidget,
    );
  });

  testWidgets('no rates, no qualifier', (tester) async {
    // The qualifier qualifies a number. With no number it is an unexplained
    // sentence in a card about something else, and — the reason this is a test
    // rather than an observation — it would put copy on the page in the one state
    // the layout gate's `node_detail` cells actually render.
    await pump(tester, withoutRates);

    expect(find.byType(DetailSpeedCard), findsNothing);
    expect(find.text(loc.backhaulRateNotInternetSpeed), findsNothing);
  });

  testWidgets('the qualifier is never truncated', (tester) async {
    // The whole reason it is not in the card caption. Full width and free to
    // wrap: a line cap or an ellipsis here removes exactly the words REQ-12 asks
    // for, and does it silently.
    await pump(tester, withRates);

    final text = tester.widget<Text>(
      find.text(loc.backhaulRateNotInternetSpeed),
    );
    expect(text.maxLines, isNull, reason: 'it must be free to wrap');
    expect(text.overflow, isNot(TextOverflow.ellipsis));
  });
}
