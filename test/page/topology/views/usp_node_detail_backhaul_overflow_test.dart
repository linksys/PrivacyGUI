@Tags(['dashboard-card'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/topology/providers/node_detail_provider.dart';
import 'package:privacy_gui/page/topology/views/usp_node_detail_view.dart';

import '../../../golden_test/golden_framework/mocks/mock_topology.dart';
import '../../../golden_test/page/topology/fixtures/topology_test_data.dart';
import '../../../util/app_test_fonts.dart';
import '../../../util/detail_view_probe.dart';
import '../../../util/overflow_probe.dart';

/// Overflow tests for the node-detail backhaul card's half-width tile captions
/// (#1302).
///
/// ## Why this file exists
///
/// Two captions in `_buildBackhaulCard` were built as `Row(children: [Icon(size:
/// 16), AppGap.xs(), AppText.labelSmall(caption)])` — unconstrained, sized to
/// their natural width. Both tiles share a `Row` as two `Expanded`s, so each
/// caption gets half the card and no more, 99dp at 1280px:
///
/// - **interface** — `fi` needs 102.6dp for `Käyttöliittymä`; worst case is `ja`
///   at 1241px, 19dp over.
/// - **last contact** — 21 of the 26 locales overflow, `ru` by 39dp at 1241px and
///   **`en` by 2.4dp**, so this one is not a long-translation edge case at all.
///
/// Nothing else fails on either. The #1183 gate sweeps the dashboard's
/// `UspWidgetSpecs.all` registry, which does not contain this page; the golden
/// suite renders the interface tile and compares byte-equal against a baseline
/// PNG with the overflow stripe baked in, and it never renders the last-contact
/// tile at all — no fixture set `lastContactTime` until this file added one, which
/// is why that overflow was missing from #1302's report. Hence a test, and hence
/// the `dashboard-card` tag: `run_tests.sh` excludes `golden||loc||ui`, so a
/// `ui`-tagged test would not block a PR.
///
/// ## The Ethernet branch is out of scope, and measured safe
///
/// `_buildBackhaulCard` has a third caption row in its `else` branch (Ethernet
/// backhaul, `usp_node_detail_view.dart:383`) with the same unguarded shape, left
/// untouched **by decision**. It is also the one place where the shape is
/// harmless: that `LayoutBlock` is a direct child of the card's `Column`, not a
/// half-width `Expanded`, so it has ~2× the room. Sweeping an Ethernet fixture
/// across all 26 locales × 320/480/601/905/1241/1280px produced zero overflows.
/// Do not add an Ethernet fixture here to "complete" the matrix: it would pump
/// untouched code that cannot fail.
///
/// The throughput cards in the same card are `DetailSpeedCard`s, guarded by
/// `usp_device_detail_speed_card_overflow_test.dart`; neither fixture here sets
/// `uplinkRate`/`downlinkRate`, so they do not render.
///
/// ## Mutation ledger
///
/// Every group was shown to fail against a mutation of the code it guards. An
/// overflow test that cannot fail is worse than no test, because it reports the
/// row as pinned.
///
///   | mutation                                      | what failed                  |
///   |-----------------------------------------------|------------------------------|
///   | interface caption's `Expanded` removed (pre-fix shape) | clean interface tile: ja +19px@1241, +12px@1280, +8px@320; fi +10px@1241, +3.6px@1280; da +2.5px@1241 |
///   | last-contact caption's `Expanded` removed (pre-fix shape) | clean last-contact tile: ru +39px@1241, +33px@1280, +29px@320; fi +22px@1241, +15px@1280, +11px@320; da +12px@1241, +5.3px@1280; en +2.4px@1241 |
///   | interface value given `maxLines: 1` + ellipsis | interface value stays whole |
///   | last-contact caption's `maxLines`/ellipsis dropped (`Expanded` kept) | caption-shortens-value-does-not, and last-contact-matches-sibling-height (81dp against the sibling's 64dp in `ru`@320) — the clean groups all still pass, because wrapping trades the overflow for a taller tile rather than fixing it |
void main() {
  setUpAll(() async {
    // Real fonts: under the Ahem block font every glyph is square and the
    // measured widths — the whole subject of this file — are fiction.
    await loadAppFonts();
  });

  // The interface tile renders for any Wi-Fi backhaul; the last-contact tile
  // needs a fixture that carries a lastContactTime, which only this one does.
  final interfaceState = slaveNodeWithDevices;
  final interfaceNode = interfaceState.node as SlaveNode;
  final timingState = slaveNodeWithBackhaulTiming;
  final timingNode = timingState.node as SlaveNode;

  test('both fixtures render the rows under test', () {
    // The interface row is behind `if (isWifiBackhaul)` and the last-contact row
    // behind `if (backhaul.lastContactTime != null)`. If either fixture drifts,
    // the tests below would pass without rendering the row at all, so assert the
    // preconditions rather than assume them.
    expect(
      interfaceNode.backhaul.isEthernet,
      isFalse,
      reason: 'slaveNodeWithDevices must keep a Wi-Fi backhaul — the interface '
          'tile is only built for one',
    );
    expect(
      timingNode.backhaul.isEthernet,
      isFalse,
      reason: 'slaveNodeWithBackhaulTiming must keep a Wi-Fi backhaul, so the '
          'last-contact tile is measured in the same half-width layout the fix '
          'was made for',
    );
    expect(
      timingNode.backhaul.lastContactTime,
      isNotNull,
      reason: 'slaveNodeWithBackhaulTiming must keep a lastContactTime — the '
          'last-contact tile is built only when it has one',
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

  group('backhaul last-contact tile is clean (#1302)', () {
    /// Same three widths as the interface tile, and the same 1241px pinch. This
    /// caption is the worse of the two: 21 of 26 locales overflow it, so the four
    /// below are a spread rather than the whole failing set — the worst (`ru`,
    /// +39px@1241), a mid case (`fi`), the tightest margin (`da`, +5.3px@1280),
    /// and `en`, which overflows by 2.4px at 1241px and is the reason this is a
    /// layout bug rather than a translation-length one.
    ///
    /// 9 of these 12 cells fail against the pre-fix shape; `en` at 320/1280 and
    /// `da` at 320 currently fit and are held against a font or copy change.
    const widths = <double>[1241.0, 1280.0, 320.0];

    for (final tag in ['ru', 'fi', 'da', 'en']) {
      for (final width in widths) {
        testWidgets(
          'no overflow at ${width.toStringAsFixed(0)}px in $tag',
          (tester) async {
            final overflows = await overflowsAt(
              tester: tester,
              state: timingState,
              screenWidth: width,
              tag: tag,
            );
            // The interface caption in the same card is fixed and gated by the
            // group above, so an incident here is this tile's.
            expect(
              overflows,
              isEmpty,
              reason: 'the backhaul last-contact tile overflows in $tag at '
                  '${width.toStringAsFixed(0)}px: ${overflows.join(', ')}',
            );
          },
        );
      }
    }
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

  testWidgets('the last-contact tile matches its sibling in height (#1302)',
      (tester) async {
    // Why the caption is capped at one line rather than left to wrap: wrapping
    // clears the overflow but makes this tile taller than the PHY Rate tile
    // beside it, and `Row` centres them, so the pair reads as misaligned cards.
    // `ru` at 320px is the widest caption in the narrowest tile.
    await overflowsAt(
      tester: tester,
      state: timingState,
      screenWidth: 320.0,
      tag: 'ru',
    );

    final phyRateTile = find.ancestor(
      of: find.byIcon(Icons.speed),
      matching: find.byType(LayoutBlock),
    );
    final lastContactTile = find.ancestor(
      of: find.byIcon(Icons.access_time),
      matching: find.byType(LayoutBlock),
    );
    expect(phyRateTile, findsOneWidget,
        reason: 'the PHY Rate tile is the sibling this height is compared to');
    expect(lastContactTile, findsOneWidget);

    // Not exact equality: `ru` renders through a Cyrillic fallback font whose
    // line metrics run 1dp taller than the primary font used for the
    // hardcoded-English `PHY Rate` caption beside it (in `en` the two are equal
    // to the pixel). The failure this guards is a whole wrapped line — ~14dp —
    // so a 2dp window separates the two cases without pinning font metrics.
    expect(
      tester.getSize(lastContactTile).height,
      closeTo(tester.getSize(phyRateTile).height, 2.0),
      reason: 'the two tiles share a Row and must stay the same height — a '
          'wrapped caption grows one of them and the pair reads as misaligned',
    );
  });

  testWidgets('the interface value stays whole (#1302)', (tester) async {
    // Why the caption is allowed to ellipsize: the interface itself is spelled
    // out on the line below. That argument only holds while *that* line is never
    // clipped in turn — `Wi-Fi` shortened to `W…` names no interface.
    final expected =
        interfaceNode.backhaul.linkType ?? interfaceNode.backhaul.mediaType;

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
