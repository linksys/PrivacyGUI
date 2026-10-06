@Tags(['layout-gate'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/detail_widgets.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/topology/providers/node_detail_provider.dart';
import 'package:privacy_gui/page/topology/views/usp_node_detail_view.dart';

import '../../../mocks/provider_overrides/mock_topology.dart';
import '../../../mocks/test_data/scenes/topology_scene_data.dart';
import '../../../util/app_test_fonts.dart';
import '../../../util/detail_view_probe.dart';
import '../../../util/overflow_probe.dart';

/// Overflow tests for the node-detail backhaul card's tile captions (#1302),
/// re-measured after #1555 changed which of them are still at risk.
///
/// ## Why this file exists
///
/// Two captions in `_buildBackhaulCard` were built as `Row(children: [Icon(size:
/// 16), AppGap.xs(), AppText.labelSmall(caption)])` — unconstrained, sized to
/// their natural width. Each shared a `Row` with a sibling as two `Expanded`s, so
/// each caption got half the card and no more, 99dp at 1280px:
///
/// - **interface** — still half-width, because the signal indicator is still its
///   sibling. `fi` needs 102.6dp for `Käyttöliittymä`; worst case is `ja` at
///   1241px, 19dp over. This is the group that carries the file.
/// - **last contact** — *was* the worse of the two, 21 of 26 locales over, `ru`
///   by 39dp at 1241px and **`en` by 2.4dp**. Its sibling was the PHY Rate tile,
///   which #1555 deleted (`BackhaulPHYRate` is not in the prplMesh schema and has
///   no replacement), so the tile is now a full-width child of the card's
///   `Column` and the overflow is closed structurally rather than by the guard.
///   Measured below, and the group that used to sweep it is gone.
///
/// Nothing else fails on either. The #1183 gate sweeps the dashboard's
/// `UspWidgetSpecs.all` registry, which does not contain this page. The golden
/// suite does render both tiles now — `slave_backhaul_timing` was added for the
/// last-contact one, whose absence is why that overflow was missing from #1302's
/// report — but it cannot gate either: it compares byte-equal against a baseline
/// PNG with the overflow stripe already baked in, and it runs neither of the
/// widths that overflow. Hence a test, and hence the `layout-gate` tag:
/// `run_tests.sh` excludes `golden||loc||ui`, so a `ui`-tagged test would not
/// block a PR. (Written as `dashboard-card`, which is what the tag was called on
/// `dev-2.7.0`; #1336 renamed it to say in the name what it is, and the merge on
/// 2026-08-24 left this file naming a tag `dart_test.yaml` no longer declares —
/// so it blocked a PR by luck rather than by selection.)
///
/// ## What #1555 did to the last-contact group, and why 12 cells went away
///
/// The 12 cells that swept `ru`/`fi`/`da`/`en` × 320/1241/1280px were re-run
/// against the pre-fix shape (caption's `Expanded` stripped) after the PHY Rate
/// tile went, and **none of the 12 failed** — not even with `maxLines` and the
/// ellipsis dropped as well. They had become 12 green cells reporting a row as
/// pinned that nothing was holding, which is the failure mode the ledger below
/// exists to prevent, so they are replaced by one test that can fail.
///
/// The numbers, measured at 1241px (the pinch width — the page's 200px desktop
/// margins open just above 1240px, so the row is *narrower* there than at 320px:
/// 217dp against 238dp):
///
///   | locale | caption natural width | available |
///   |--------|----------------------|-----------|
///   | `ru`   | 111.8dp (widest of all 26) | 197dp |
///   | `sv`   | 94.8dp               | 197dp |
///   | `el`   | 94.3dp               | 197dp |
///   | `fi`   | 94.1dp               | 197dp |
///   | `en`   | 74.9dp               | 197dp |
///
/// So the worst locale has 1.76× the room it needs. The replacement test asserts
/// that ratio directly rather than sweeping widths: it reds if a sibling tile is
/// ever added back to that row (measured: the ratio falls to 0.65), and it reds
/// if the `lastContact` copy grows past the headroom — the two ways this can
/// return. `_buildBackhaulCard`'s comment at the tile says the same thing from
/// the code side.
///
/// ## The Ethernet branch is out of scope, and measured safe
///
/// `_buildBackhaulCard` has a third caption row in its `else if` branch (Ethernet
/// backhaul) with the same unguarded shape, left untouched **by decision**. It is
/// also the one place where the shape is harmless: that `LayoutBlock` is a direct
/// child of the card's `Column`, not a half-width `Expanded`, so it has ~2× the
/// room — the same reason the last-contact tile is now safe. Sweeping an Ethernet
/// fixture across all 26 locales × 320/480/601/905/1241/1280px produced zero
/// overflows. Do not add an Ethernet fixture here to "complete" the matrix: it
/// would pump untouched code that cannot fail.
///
/// ## The throughput row, added by #1442
///
/// It used to be out of reach here: the two `DetailSpeedCard`s are behind
/// `uplinkRate != null || downlinkRate != null` and no `UspNodeDetailState`
/// carried either rate, so this file said they were "guarded by
/// `usp_device_detail_speed_card_overflow_test.dart`". That was true of the
/// *widget* and never of this page: the two pages pass different `label`s into it
/// and grant it different widths — 70.5dp per caption here at 1241px against
/// 172dp there — so the device page's nine cells said nothing about this one.
///
/// #1442 needed a fixture with rates (`slaveNodeWithBackhaulRates`) to place its
/// qualifier, so the row is now reachable and measured here for the first time.
/// Its own sweep is below, and the ledger records what fails without the caption
/// fix: 13 of 16 cells, `fr` by 65px at 1241px — more than double the +30px the
/// device page measured, which is the geometry difference stated as a number.
///
/// ## Mutation ledger
///
/// Every group was shown to fail against a mutation of the code it guards. An
/// overflow test that cannot fail is worse than no test, because it reports the
/// row as pinned. Re-measured in full on this branch — the interface row's count
/// moved, so the old numbers were not carried over on trust.
///
///   | mutation                                      | what failed                  |
///   |-----------------------------------------------|------------------------------|
///   | interface caption's `Expanded` removed (pre-fix shape) | clean interface tile: **9 of 9 cells** — every locale at every width. Was 6 of 9 when #1302 wrote this table |
///   | interface value given `maxLines: 1` + ellipsis | interface value stays whole |
///   | last-contact caption's `Expanded` removed | **nothing** — 24 of 24 green. The measurement that retired the 12-cell group |
///   | last-contact caption's `Expanded`, `maxLines` and ellipsis all removed | only caption-shortens-value-does-not, which reads the widget's properties rather than measuring the layout. Still zero overflow cells |
///   | last-contact tile given a sibling `Expanded` in its `Row` (the pre-#1555 shape) | the full-width headroom test: 72.5dp granted against 111.8dp needed, a ratio of 0.65 |
///   | speed-card caption's `Expanded` removed (the pre-#1302 shape) | **13 of 16 throughput cells** — `fr` at all four widths (+65px at 1241, +59px at 1280, +55px at 320, +11px at 480), `fr_CA` / `pl` / `tr` at 1241 / 1280 / 320 and clean at 480 |
///   | the #1442 qualifier moved into the cards' `Row` as a third `Expanded` | the full-width test: the sentence is granted a third of the row instead of all of it |
void main() {
  setUpAll(() async {
    // Real fonts: under the Ahem block font every glyph is square and the
    // measured widths — the whole subject of this file — are fiction.
    await loadAppFonts();
  });

  // The interface tile renders for any Wi-Fi backhaul; the last-contact tile
  // needs a fixture that carries a lastContactTime, which only this one does.
  final interfaceState = slaveNodeOffline;
  final interfaceNode = interfaceState.node as SlaveNode;
  final timingState = slaveNodeWithBackhaulTiming;
  final timingNode = timingState.node as SlaveNode;
  // The only scene that carries both backhaul rates, and therefore the only one
  // that reaches the throughput row (#1442).
  final ratesState = slaveNodeWithBackhaulRates;
  final ratesNode = ratesState.node as SlaveNode;

  test('both fixtures render the rows under test', () {
    // The interface row is behind `if (isWifiBackhaul)` and the last-contact row
    // behind `if (backhaul.lastContactTime != null)`. If either fixture drifts,
    // the tests below would pass without rendering the row at all, so assert the
    // preconditions rather than assume them.
    expect(
      interfaceNode.backhaul.isEthernet,
      isFalse,
      reason: 'slaveNodeOffline must keep a Wi-Fi backhaul — the interface '
          'tile is only built for one',
    );
    expect(
      interfaceNode.backhaul.linkType,
      isNotNull,
      reason: 'the interface tile prints `linkType` and falls back to the '
          'localized `unknown` when it is null — a null here would make the '
          'value test below assert against the fallback string',
    );
    expect(
      timingNode.backhaul.isEthernet,
      isFalse,
      reason: 'slaveNodeWithBackhaulTiming must keep a Wi-Fi backhaul: the '
          'Ethernet arm builds neither of the tiles this file measures',
    );
    expect(
      timingNode.backhaul.lastContactTime,
      isNotNull,
      reason: 'slaveNodeWithBackhaulTiming must keep a lastContactTime — the '
          'last-contact tile is built only when it has one',
    );
  });

  test('the rates fixture reaches the throughput row (#1442)', () {
    // Same argument as the test above: the row is behind the two rates, and a
    // fixture that lost them would make every cell in the sweep below pass
    // against a page that renders no speed card at all. The sweep's own premise
    // cannot catch that — an absent row overflows nothing.
    expect(ratesNode.backhaul.uplinkRate, isNotNull);
    expect(ratesNode.backhaul.downlinkRate, isNotNull);
    expect(
      ratesNode.backhaul.isEthernet,
      isFalse,
      reason: 'the Ethernet arm builds no throughput row either',
    );
  });

  /// Pumps the real node-detail page for [state] once at [screenWidth] and
  /// returns the RenderFlex overflows beyond the gate's own tolerance.
  Future<List<OverflowIncident>> overflowsAt({
    required WidgetTester tester,
    required UspNodeDetailState state,
    required double screenWidth,
    required String tag,
  }) =>
      probeViewOverflow(
        tester,
        view: UspNodeDetailView(deviceId: state.node!.deviceId),
        overrides: nodeDetailOverrides(state),
        screenWidth: screenWidth,
        locale: localeForTag(tag),
      );

  group('throughput row is clean (#1442)', () {
    /// All four widths carry signal here, unlike the interface tile's three:
    /// `fr` fails at 480px too (+11px), because two captions share the row rather
    /// than one caption sharing it with a signal indicator.
    ///
    /// - **1241px** — the desktop pinch (the page's 200px margins open just above
    ///   1240px, so the row is laid out *narrower* here than at 1240px). Worst
    ///   case: `fr` +65px.
    /// - **1280px** — the golden suite's desktop coordinate. `fr` +59px.
    /// - **480px** — the golden suite's phone coordinate, and the only width where
    ///   the caption has real room (161dp against 70.5dp at 1241px).
    /// - **320px** — the narrowest supported screen. `fr` +55px.
    const widths = <double>[1241.0, 1280.0, 480.0, 320.0];

    // The four locales that overflow the pre-fix caption shape on this page,
    // measured by sweeping all 26 across all four widths (104 cells, zero
    // overflows as shipped; 13 red under the mutation). They are the same four the
    // device-detail suite sweeps, which is a measured result and not an
    // assumption carried over: #1442 did not lengthen the `label`, so the ranking
    // of the captions did not move — only the room they get did.
    //
    // The full cross-product, for the reason the sibling group gives: the three
    // cells that pass under the mutation (`fr_CA`, `pl`, `tr` at 480px) are the
    // near misses, held against a translation growing later.
    for (final tag in ['fr', 'fr_CA', 'pl', 'tr']) {
      for (final width in widths) {
        testWidgets('no overflow at ${width.toStringAsFixed(0)}px in $tag', (
          tester,
        ) async {
          final overflows = await overflowsAt(
            tester: tester,
            state: ratesState,
            screenWidth: width,
            tag: tag,
          );
          expect(
            overflows,
            isEmpty,
            reason: 'the backhaul throughput row overflows in $tag at '
                '${width.toStringAsFixed(0)}px: ${overflows.join(', ')}',
          );
        });
      }
    }
  });

  testWidgets(
      'the not-internet-speed qualifier gets the whole card width (#1442)',
      (tester) async {
    // The property that makes the sentence readable, asserted instead of the
    // absence of an overflow stripe — a full-width `Text` with no line cap cannot
    // overflow, so a width sweep can never fail on this row and would report it
    // as pinned.
    //
    // This is also where the placement decision is held. #1442's AC2 put the
    // qualifier inside `DetailSpeedCard`'s `label`; measured, that slot is 70.5dp
    // at this width while `Download` alone needs 297dp in `fr`, so the sentence
    // would be ellipsized away in about twenty locales. Moving it into the cards'
    // `Row` as a third `Expanded` is the same mistake in a new shape, and is what
    // this test fails on.
    //
    // `ru` at 1241px: the longest qualifier translation at the narrowest desktop
    // row. Measured there, the sentence needs more than the row is wide and wraps
    // to two lines — which is why the companion assertion in
    // `usp_node_detail_backhaul_rate_test.dart` (no `maxLines`, no ellipsis) is
    // load-bearing rather than defensive.
    await overflowsAt(
      tester: tester,
      state: ratesState,
      screenWidth: 1241.0,
      tag: 'ru',
    );

    final loc = await AppLocalizations.delegate.load(localeForTag('ru'));
    final qualifier = find.text(loc.backhaulRateNotInternetSpeed);
    expect(
      qualifier,
      findsOneWidget,
      reason: 'the qualifier must render beside the rates it qualifies',
    );

    // Asserted structurally rather than by comparing widths. A wrapped paragraph
    // reports its box as the full constraint, so `width == row.width` does hold
    // here (197dp at this coordinate against 400dp+ of `ru` text) — but it holds
    // *because* the sentence is long, and a shorter translation would fail it
    // while sitting in exactly the right place. The property is where the widget
    // is, not how wide its glyphs happen to run.
    final cardsRow = find
        .ancestor(
            of: find.byType(DetailSpeedCard).first, matching: find.byType(Row))
        .first;
    expect(
      find.descendant(of: cardsRow, matching: qualifier),
      findsNothing,
      reason: 'the qualifier is inside the cards\' Row, so it is granted a '
          'fraction of the width instead of all of it — the same mistake as '
          'putting it in the card caption, which is what this placement exists '
          'to avoid (see the comment above)',
    );
    expect(
      find.descendant(
        of: find.ancestor(of: cardsRow, matching: find.byType(Column)).first,
        matching: qualifier,
      ),
      findsOneWidget,
      reason: 'it must still be in the card that holds the rates: a sentence '
          'elsewhere on the page qualifies nothing',
    );
  });

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
              state: interfaceState,
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

  // The replacement for the 12-cell last-contact sweep, which #1555 made
  // unfailable — see the header. Measured at the worst locale and the worst
  // width, and asserting the property that closed the overflow (the tile is
  // full-width) rather than the absence of a stripe.
  testWidgets(
      'the last-contact caption has room to spare at full width (#1555)',
      (tester) async {
    // `ru` at 1241px: the widest `lastContact` of all 26 locales, at the width
    // where the row is narrowest (the 200px desktop margins open just above
    // 1240px, so 1241px lays this row out at 217dp against 320px's 238dp).
    await overflowsAt(
      tester: tester,
      state: timingState,
      screenWidth: 1241.0,
      tag: 'ru',
    );

    final tile = find
        .ancestor(
          of: find.byIcon(Icons.access_time),
          matching: find.byType(LayoutBlock),
        )
        .first;
    final caption =
        find.descendant(of: tile, matching: find.byType(Text)).first;

    // What the caption was granted. Under the `Expanded` this is the room
    // available to it, which is the number a sibling tile would halve.
    final granted = tester.getSize(caption).width;

    // What it needs. Taken off the render object rather than the `Text` widget
    // so the style is the resolved one — `AppText.labelSmall` supplies its own,
    // and reading `Text.style` would measure a null style at the default size.
    final paragraph = tester.renderObject<RenderParagraph>(caption);
    final painter = TextPainter(
      text: paragraph.text,
      textDirection: paragraph.textDirection,
      textScaler: paragraph.textScaler,
      maxLines: null,
    )..layout();
    final needed = painter.width;

    expect(
      granted,
      greaterThan(needed * 1.25),
      reason:
          'the last-contact caption has $granted dp for $needed dp of text. '
          'It is safe because #1555 deleted the PHY Rate tile that shared its '
          'Row, leaving it full-width — measured at 197dp against 111.8dp, a '
          '1.76x margin. Below 1.25x either a sibling tile is back in that Row '
          '(which puts the 21-locale overflow of #1302 back with it) or the '
          'copy has outgrown the room; re-read this file\'s header before '
          'relaxing the threshold',
    );
  });

  testWidgets(
      'the last-contact caption shortens but its value does not (#1302)',
      (tester) async {
    // The caption may ellipsize because the timestamp is spelled out below it;
    // the timestamp itself must not, since a clipped relative time reads as a
    // different time. Asserted structurally rather than by string: the tile is
    // the LayoutBlock around Icons.access_time, and its two Texts are the caption
    // (line-capped) and the value (not), so this also catches the two being
    // swapped.
    await overflowsAt(
      tester: tester,
      state: timingState,
      screenWidth: 320.0,
      tag: 'ru',
    );

    final tile = find
        .ancestor(
          of: find.byIcon(Icons.access_time),
          matching: find.byType(LayoutBlock),
        )
        .first;
    final texts = find.descendant(of: tile, matching: find.byType(Text));
    expect(
      texts,
      findsNWidgets(2),
      reason: 'the last-contact tile should hold exactly a caption and a value',
    );

    final caption = tester.widget<Text>(texts.at(0));
    final value = tester.widget<Text>(texts.at(1));
    expect(
      caption.maxLines,
      1,
      reason:
          'the caption must stay on one line, or this half-width tile grows '
          'taller than its sibling',
    );
    expect(
      caption.overflow,
      TextOverflow.ellipsis,
      reason: 'the caption must shorten with an ellipsis rather than overflow',
    );
    expect(
      value.overflow,
      isNot(TextOverflow.ellipsis),
      reason:
          'the last-contact value must never ellipsize — a clipped relative '
          'time reads as a different time',
    );
    expect(value.maxLines, isNull,
        reason: 'the last-contact value must not be line-capped');
  });

  testWidgets('the interface value stays whole (#1302)', (tester) async {
    // Why the caption is allowed to ellipsize: the interface itself is spelled
    // out on the line below. That argument only holds while *that* line is never
    // clipped in turn — `Wi-Fi` shortened to `W…` names no interface.
    final expected = interfaceNode.backhaul.linkType!;

    await overflowsAt(
      tester: tester,
      state: interfaceState,
      screenWidth: 320.0,
      tag: 'ja',
    );

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
