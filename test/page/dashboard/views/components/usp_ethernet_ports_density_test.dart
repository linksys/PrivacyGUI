@Tags(['layout-gate'])
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/card_density_scope.dart';
import 'package:privacy_gui/page/_shared/components/card_popup_form.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/models/ethernet_port_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/local_network/cards/usp_ethernet_ports_card.dart';

import '../../../../util/app_test_fonts.dart';
import '../../../../util/dashboard/dashboard_card_probe.dart';
import '../../../../util/dashboard/text_readability_probe.dart';
import '../../../../util/overflow_probe.dart';

/// `ethernet_ports` density: which form the card selects, and what each form
/// owes the reader (#1290).
///
/// This card declares `normalAbove: 386` and it is the one card in the set whose
/// normal form does not fit at *any* width the grid can hand it. The other five
/// have a coordinate where their defect retires; this one does not, and that
/// negative result is what the compact form below is built on.
///
/// ## The measurement the ticket asked for, and why it came back empty
///
/// AC 1 asked for "the width at which the port grid seats inside the content
/// viewport". Pinned normal at `minHeightRows` = 2 — the height the gate pumps,
/// whose content viewport measures **121px** — a single port item is **82px**
/// tall and starts below a 96–136px block of summary tiles. So it lands outside
/// the viewport, and a **4px sweep of [200, 700] in `de`/`ru`/`en` seats 0 of 5
/// at every one of the 126 widths**, in all 26 locales at every realization.
/// Widening the card only reflows the `Wrap`; the bind is vertical.
///
/// That is why this ticket needed a form and not a threshold. A threshold alone
/// picks between two arrangements of the same content, and neither arrangement
/// of *this* content fits.
///
/// ## Why the existing suites cannot make this claim
///
///   - the #1183 gate asks whether a `RenderFlex` overflowed. Both
///     `ethernet_ports` keys left `known_overflows.json` at #1228, and the card
///     has been green ever since — while showing, at 191px, two stacked tiles and
///     0.0px of every port glyph. Green is a *report* of this defect.
///   - `ethernet_ports_summary_readability_test.dart` measures the two summary
///     tiles: that they stay whole, stay a matched pair, and keep a legible
///     label. Every one of its assertions is about the tiles, and the tiles are
///     exactly what the compact form drops. Since #1290 it pins
///     `CardDensity.normal`, so it now describes the *presented* normal form
///     (`showCardNormalForm` on a narrow phone) and says nothing about selection.
///   - `dashboard_card_popup_overflow_test.dart` pins `CardDensity.popup`, so it
///     proves the popup form fits, never that a card reaches it.
///
/// Nothing is pinned in the selection groups below: every case goes through
/// `UspWidgetFactory` and `CardDensityHost`'s own `LayoutBuilder`, which is the
/// production path. The pins are all in the last group, where they record *why*
/// the threshold sits where it does.
///
/// ## The criterion: every port item inside `cardContentViewport`
///
/// AC 7 names that helper and here it is the right instrument, unlike on
/// `network_health` (#1291 AC 6): this card is not tabbed, so
/// `DashboardCardTemplate` wraps its content in a scroll view and the helper's
/// "exactly two scroll views" precondition describes the tree it is asked
/// about. It also names the frame that matters — the template *scrolls*, so a
/// port item can sit 159px below the fold while overflowing nothing, which is
/// precisely the failure the gate cannot see.
///
/// ## Where 386 comes from, and why not 570
///
/// From a pinned-normal 1px sweep, two real coordinates, neither of them a
/// seating floor:
///
///   - **386** — where the content column first reaches `_kSideBySideMinWidth`
///     (352) and the tiles stop stacking: **stacked at 385, side by side at
///     386**, content being `cardWidth − 34`. Stacked, all five glyphs measure
///     0.0px inside the viewport; side by side, four measure their full 38px.
///     One coordinate, and the 41px → 0px regression sits on it.
///   - **570** — where all five 88px items fit one run (5 × 88 + 4 × 24 = 536px
///     of content), i.e. where the whole grid shows every glyph. **Rejected**:
///     it is above the 512px `desktopCaseFor` width, so declaring it would put
///     the desktop realization in compact and contradict AC 7's "the full grid
///     is intact at `desktopCaseFor`".
///
/// So 386 is the width at which the normal form stops *costing* the ports their
/// glyphs, which is the strongest claim a threshold can make on a card whose
/// content does not fit at any width, and it clears the ">288px" the ticket
/// requires for the ticket's own reason: 288 is a realization the grid produces
/// at which the normal form shows two tiles, a divider, and no ports at all.
///
/// ## What compact sheds, and what it refuses to shed
///
/// The two summary tiles go, and each port becomes a chip: a half-size (20×19)
/// glyph beside the label and the speed. Five chips take three runs of the 166px
/// content column a 200px card gives — 3 × 32 + 2 × 8 = **112px against a 121px
/// viewport** — and two runs (**72px**) from 269px up. A full-size item cannot
/// reach that anywhere in the band: five of them are 536px of content in one run
/// and five runs of 82px stacked.
///
/// Nothing is invented for the narrow band and no *state* reading is dropped:
/// the glyph tint is the same signal the normal item uses, and the speed stays
/// because it is the textual half of that state (`speedLabel` reads `—` for a
/// port that is down), so a colour-blind reader loses nothing the wide form gave
/// them. Only the connected-device line goes, and it is the one fact on this card
/// that the tap still shows in full.
///
/// ## One loss recorded, not fixed
///
/// At 512px desktop no port item seats whole either — the labels sit below the
/// fold and the fifth glyph is invisible. That is the pre-#1228 loss the density
/// design records at §2.12 point 3, it is unchanged by this ticket, and it
/// retires by *height*: at rows = 3 (this card's `HeightStrategy.strict(3)`
/// default, 257px of viewport) four of the five items seat. The last group pins
/// it as a measurement, because it is the price AC 7 charges for keeping the full
/// grid at desktop — the alternative was `normalAbove: 570`.
///
/// ## Mutation ledger
///
/// Every assertion below was run against a mutation of the code it guards and
/// observed to fail. Measured against this file's 18 tests, the full 1644-test
/// gate, and `ethernet_ports_summary_readability_test.dart`'s 14 — each mutation
/// applied alone and reverted before the next:
///
///   | mutation                                       | this file | the gate | tiles suite |
///   |------------------------------------------------|-----------|----------|-------------|
///   | A `normalAbove` deleted from the spec          | 12 fail   | green    | green       |
///   | B `popupValue` deleted from the card           | 3 fail    | green    | green       |
///   | C the `if (!compact)` guard removed            | 7 fail    | green    | green       |
///   | D `normalAbove` 386 → 288 (the realization)    | 10 fail   | green    | green       |
///   | E `_kCompactChipTextWidth` → `double.infinity` | 1 fail    | green    | green       |
///
/// Every row is green in both existing suites, which is the argument for this
/// file existing.
///
/// A is the ticket reverted: with no threshold every width selects normal, so the
/// declaration test, all three popup cases, all five compact-band cases and all
/// three dropped-whole cases go — and the card is back to painting two tiles and
/// no ports at 191px, which is exactly what the gate calls clean. The six
/// survivors are the cases that assert the *normal* form: the two desktop ones
/// and the four pinned derivation ones.
///
/// B is the narrowest: with no `popupValue` the popup form falls back to the card
/// *title*, so a 191px card reads "Ethernet Ports" and nothing else. It renders,
/// it fits, it is clean, and it does not say how many ports are up.
///
/// C keeps the threshold and reverts the form. The tiles come back inside the
/// compact band and take the ports back out of the viewport with them: all five
/// band cases fail on `seated`, and the two dropped-whole cases fail on the tile
/// count. This is the row that shows the threshold is not the fix by itself — and
/// the one dropped-whole case that survives it is the port-fact comparison, which
/// is about the chip and not the tiles.
///
/// D moves the threshold to the widest realization, the number a "declare it at
/// the coordinate that hurts" reading would pick. It fails the declaration bound
/// (`densityForWidth` is inclusive, so 288 leaves the 288px realization in the
/// normal form), takes the whole upper band with it, and then fails the flip
/// test: at 288px the content column is 254px, so the tiles are stacked and every
/// glyph is 0.0px at exactly the width the threshold called ready. The three popup
/// cases survive, which is the point — the popup band is fixed at 200px and says
/// nothing about where the compact band ends.
///
/// E is the one row that is not about selection, and the reason one test in this
/// file builds its own ports. Removing the chip's text cap leaves the compact
/// form fitting the dashboard fixture perfectly — every locale, every width —
/// because `LAN 1` is short, so the four band cases and the gate all stay green.
/// Only the case pumped with a label the fixture would never send sees it: the
/// chip goes from 96px to a run of its own, and five runs are 160px in a 121px
/// viewport.
void main() {
  setUpAll(() async {
    // Real fonts: under Ahem every glyph is one square em, so the chip widths
    // that decide how many runs the `Wrap` takes — and therefore whether the
    // compact form fits at all — are fiction.
    await loadAppFonts();
  });

  const cardId = 'ethernet_ports';
  final spec = UspWidgetSpecs.getById(cardId)!;
  final constraints = spec.getConstraints(DisplayMode.normal);
  final heightRows = constraints.minHeightRows;

  /// The declared threshold, and a literal fallback used **only** so the file
  /// can still enumerate its cases when the declaration is missing.
  ///
  /// `spec.normalAbove!` would throw here — before a single test registers — and
  /// mutation A above would have read as "the file fails to load" rather than as
  /// assertions about forms the card no longer selects. So the number is
  /// duplicated on purpose, and the first test is the one that asserts the spec
  /// still declares it.
  final normalAbove = spec.normalAbove ?? 386.0;

  /// The widths the gate realizes (191.375px, 288.000px) and the desktop width
  /// it never pumps (512px), from the same helpers the gate uses.
  final narrowCases = widthCasesFor(spec);
  final desktopCase = desktopCaseFor(spec);
  final widestRealization =
      narrowCases.map((c) => c.cardWidth).reduce(math.max);

  /// The widths that exercise the compact band: its two edges, the realization
  /// that lands inside it, and one interior sample.
  ///
  /// 288px is a realization. 200px and `normalAbove − 2` are the band's own
  /// edges, which the grid can produce (a 3-column span on a 700px screen is
  /// 228.5px) but never does for *this* card's realizations — and a band no test
  /// enters is a band whose contents were never seen. 330px is above the 269px
  /// run boundary, so the four widths cover both the three-run shape (112px) and
  /// the two-run one (72px).
  final compactWidths = <double>[kPopupBelow, 288.0, 330.0, normalAbove - 2];

  /// Same 2.0px tolerance as the #1183 gate, for the same reason: sub-pixel
  /// shaping differences between the mac and ubuntu rasterizers.
  const tolerancePx = 2.0;

  /// The compact chip's width bound: `20px` glyph + `AppSpacing.xs` + the card's
  /// 72px text cap. Duplicated from the card on purpose — the point of asserting
  /// it is that the chip is bounded by *something*, and a test that read the
  /// constant back out of the card could not fail when the constant is removed
  /// (mutation E).
  const chipWidthBound = 96.0;

  /// ## Which call sites keep the returned list, and why the rest drop it
  ///
  /// `probeCardOverflow` *intercepts* RenderFlex overflow into this list instead
  /// of failing the test, so a discarded return is a swallowed overflow and needs
  /// a reason (#1318). The discards are of three kinds, and none of them is a
  /// coverage hole:
  ///
  ///   * `pin: CardDensity.normal` below the threshold (the 288px widest
  ///     realization, `normalAbove - 1`) — the groups asserting those pumps exist
  ///     to show the normal form seats **0 of 5** ports there, so asserting no
  ///     overflow would contradict them.
  ///   * unpinned at 288px, where the grid selects compact — the gate's main sweep
  ///     measures that exact coordinate in all 26 locales.
  ///   * unpinned at `desktopCase`, where it selects normal — dominated by the
  ///     `[normal band]` sweep's 386px case, since overflow is monotonic *within*
  ///     a form and both pumps fix the height at `minHeightRows` (see
  ///     `normalBandCaseFor`).
  Future<List<OverflowIncident>> pumpAt(
    WidgetTester tester, {
    required double cardWidth,
    required String label,
    Locale locale = const Locale('en'),
    CardDensity? pin,
    List<EthernetPortUIModel>? ports,
  }) =>
      probeCardOverflow(
        tester,
        cardId: cardId,
        widthCase: CardWidthCase(
          // The screen is held at 1440px while the card width varies, which is
          // the same separation `CardDensityHost` makes: density comes from the
          // constraints the grid hands the card, never from the window.
          screenWidth: 1440,
          cardWidth: cardWidth,
          columnSpan: constraints.minColumns,
          label: label,
        ),
        cardHeightRows: heightRows,
        tabIndex: 0,
        locale: locale,
        density: pin,
        // Only when a specific port shape is needed — the fixture's labels are
        // `LAN 1`, and the chip's text cap cannot be measured against data that
        // was never going to reach it. The wrapper reproduces
        // `UspWidgetFactory.buildWidget` exactly (same `cardId`, same
        // `normalAbove` from the same spec), because the alternative is choosing
        // between production *selection* and controlled *data*, and that one test
        // needs both. Every other case in this file goes through the factory
        // untouched, so a card renamed or unregistered still fails loudly.
        cardOverride: ports == null
            ? null
            : CardDensityHost(
                cardId: cardId,
                normalAbove: spec.normalAbove,
                child: UspEthernetPortsCard(ports: ports),
              ),
      );

  /// Every port glyph in the pumped tree, in paint order.
  ///
  /// The port glyph is this card's only SVG in every form — the summary tiles use
  /// an icon font and the popup form has no artwork — so this counts ports, and
  /// counting them is how the two degraded forms are told apart: compact keeps
  /// all five, popup keeps none.
  Finder portGlyphs() => find.byType(SvgPicture);

  /// The box of each port item, in paint order.
  ///
  /// The item's own box, not the glyph's: what has to fit the viewport is the
  /// label and the speed as well. The two forms nest differently, so the
  /// enclosing widget is named per form rather than guessed — in compact the chip
  /// is a `Row` (the nearest `Column` above the glyph is the card's *content*
  /// column, which would measure the whole card), and in the normal form the item
  /// is the `Column` inside its 88px `SizedBox`.
  List<Rect> portItemRects(WidgetTester tester, {required bool compact}) {
    final glyphs = portGlyphs();
    final enclosing = compact ? find.byType(Row) : find.byType(Column);
    return [
      for (var i = 0; i < glyphs.evaluate().length; i++)
        tester.getRect(
            find.ancestor(of: glyphs.at(i), matching: enclosing).first),
    ];
  }

  /// How many of [rects] sit inside [viewport] — the reading AC 1 asked for and
  /// AC 7 asserts. Vertical only: horizontal is what the overflow incidents
  /// report, and the card's width is the axis the threshold is chosen on.
  int seatedCount(List<Rect> rects, Rect viewport) => rects
      .where((r) =>
          r.top >= viewport.top - tolerancePx &&
          r.bottom <= viewport.bottom + tolerancePx)
      .length;

  /// How many pixels of [rect] fall inside [viewport] vertically. Zero means the
  /// widget is laid out, painted, reported clean by every overflow probe, and
  /// invisible — the state this card was in at 191px and 288px before #1290.
  double visibleHeight(Rect rect, Rect viewport) => math.max(
      0.0,
      math.min(rect.bottom, viewport.bottom) -
          math.max(rect.top, viewport.top));

  void expectNoOverflow(List<OverflowIncident> incidents,
      {required String at}) {
    final significant = incidents.where((i) => i.pixels > tolerancePx).toList();
    expect(significant, isEmpty,
        reason: 'overflowed at $at:\n${significant.join('\n')}');
  }

  group('the card declares a threshold, and where', () {
    test('normalAbove is declared and bounded by both realizations', () {
      expect(spec.normalAbove, isNotNull,
          reason: 'without a threshold this card claims it needs no degraded '
              'form, which #1240 recorded and #1290 measured to be false: at '
              'every width the grid hands out, the normal form seats 0 of 5 port '
              'items inside its content viewport. Every group below asserts a '
              'form the card would no longer select.');

      expect(normalAbove, greaterThan(kPopupBelow),
          reason:
              'a threshold at or below $kPopupBelow leaves no compact band: '
              'every width under it selects popup, so the card drops straight '
              'from whole to one line with nothing in between '
              '(densityForWidth precedence rule 1).');

      // Strictly greater, not `>=`: 288 is a width the grid realizes, and
      // `densityForWidth` is inclusive at the boundary (`width >= normalAbove`
      // selects normal), so a threshold *at* 288 would leave that realization in
      // the form this ticket exists to take it out of.
      expect(normalAbove, greaterThan(widestRealization),
          reason:
              'a threshold at or below ${widestRealization.toStringAsFixed(1)}px '
              'leaves the widest realization the grid hands out in the normal '
              'form. #1290 measured what that realization shows: two stacked '
              'tiles, a divider, and 0.0px of all five port glyphs.');

      expect(normalAbove, lessThan(desktopCase.cardWidth),
          reason: 'a threshold at or above the ${desktopCase.cardWidth}px '
              'desktop width degrades a card that has room, and it is the reason '
              '570 was rejected: the whole grid must survive at '
              '`desktopCaseFor` (#1290 AC 7).');
    });
  });

  group('below 200px the card selects its popup form', () {
    final narrowest = narrowCases.first;

    for (final tag in ['en', 'de']) {
      testWidgets('@${narrowest.widthKey}px ($tag)', (tester) async {
        final locale = supportedLocaleFor(tag);
        final l10n = await AppLocalizations.delegate.load(locale);
        final at = '${narrowest.widthKey}px ($tag)';
        final incidents = await pumpAt(
          tester,
          cardWidth: narrowest.cardWidth,
          label: 'min',
          locale: locale,
        );
        expectNoOverflow(incidents, at: at);

        expect(find.byType(CardPopupForm), findsOneWidget,
            reason: 'at ${narrowest.cardWidth.toStringAsFixed(1)}px the card '
                'still rendered tiles or ports. That width is below '
                '$kPopupBelow, and #1290 measured what the ports get there: '
                '0.0px of every glyph inside a 121px viewport.');

        // The ports are gone, not merely smaller. This is what separates popup
        // from compact, and it is the assertion mutation A trips first.
        expect(portGlyphs(), findsNothing,
            reason: 'the popup form is still drawing port glyphs, so this is '
                'not the popup form');
        expect(find.byType(SummaryTile), findsNothing,
            reason: 'the popup form is still drawing a summary tile');

        final popup = tester.widget<CardPopupForm>(find.byType(CardPopupForm));
        expect(popup.value, isNotNull,
            reason: 'no popupValue declared, so the card degrades to its own '
                'title. A card that declares a threshold must also declare the '
                'one value the threshold is protecting (#1288 §2.1).');
        expect(popup.value, isNot(l10n.ethernetPorts),
            reason: 'the popup value is the card title, which the popup form '
                'already shows above it — a 191px card saying '
                '"${l10n.ethernetPorts}" twice and nothing else is a working '
                'form that says nothing');
        expect(popup.value, matches(RegExp(r'^\d+/\d+$')),
            reason: 'the popup value is "${popup.value}", not ports-up over '
                'ports-present. The WAN state alone would read "Connected" on a '
                'router with no LAN link, and a port list is what the tap is '
                'for (#1290 AC 3).');
        expect(find.text(popup.value!), findsOneWidget,
            reason: 'the declared value was not painted — declaring it and '
                'showing it are two different things');
      });
    }

    testWidgets('the popup value counts the ports the whole form shows',
        (tester) async {
      final narrow = await pumpAt(
        tester,
        cardWidth: narrowest.cardWidth,
        label: 'min',
      );
      expectNoOverflow(narrow, at: '${narrowest.widthKey}px');
      final value =
          tester.widget<CardPopupForm>(find.byType(CardPopupForm)).value!;
      final parts = value.split('/');
      expect(parts.length, 2, reason: 'the popup value is not a ratio');

      // Re-pumped wide rather than asserted against a fixture-derived number:
      // the claim worth making is that the two forms agree about the router, not
      // that either matches an arithmetic this test would have to duplicate.
      // `—` is `speedLabel`'s reading for a port that is down, and it is not
      // localized, so this counts the same thing in every locale.
      final wide = await pumpAt(
        tester,
        cardWidth: desktopCase.cardWidth,
        label: 'desktop',
      );
      expectNoOverflow(wide, at: '${desktopCase.widthKey}px');
      final present = portGlyphs().evaluate().length;
      final down = find.text('—').evaluate().length;

      expect(int.parse(parts[1]), present,
          reason: 'the popup form said "$value" but the whole form paints '
              '$present ports. The degraded form has to be the same reading in '
              'less space, not a different one (#1290 AC 3).');
      expect(int.parse(parts[0]), present - down,
          reason: 'the popup form said "$value" but the whole form shows $down '
              'of $present ports down, i.e. ${present - down} up');
    });
  });

  group('from 200px to the threshold the compact form seats every port', () {
    // `en` is the control; `de`/`ru`/`th` are the three locales whose chrome and
    // fallback fonts are widest elsewhere on the dashboard. The chip content is
    // ASCII device data (`LAN 1`, `1 Gbps`), so #1290 measured the chip box as
    // locale-invariant at 32px tall in all 26 — these four are here to keep that
    // invariance a measurement rather than an assumption.
    for (final tag in ['en', 'de', 'ru', 'th']) {
      testWidgets('($tag) every port chip is inside the content viewport',
          (tester) async {
        final locale = supportedLocaleFor(tag);
        final l10n = await AppLocalizations.delegate.load(locale);

        for (final width in compactWidths) {
          final at = '${width.toStringAsFixed(0)}px ($tag)';
          final incidents = await pumpAt(tester,
              cardWidth: width, label: 'compact', locale: locale);
          expectNoOverflow(incidents, at: at);

          expect(find.byType(CardPopupForm), findsNothing,
              reason:
                  'at $at the card gave up its ports entirely. $width is at '
                  'or above $kPopupBelow, so the compact form is what it owes '
                  'the user here — five chips that fit, not a single line '
                  '(#1290 AC 4).');

          final viewport = cardContentViewport(tester);
          final items = portItemRects(tester, compact: true);
          expect(items.length, greaterThanOrEqualTo(2),
              reason: 'only ${items.length} port items at $at');

          expect(seatedCount(items, viewport), items.length,
              reason: 'only ${seatedCount(items, viewport)} of ${items.length} '
                  'port chips fit the ${viewport.height.toStringAsFixed(0)}px '
                  'the card gives its content at $at. Chips of 32px take three '
                  'runs (112px) at the bottom of the band and two (72px) from '
                  '269px, so all five fit with 7px to spare at the tightest '
                  'point — a shortfall here means the chip grew or the tiles '
                  'came back (#1290 AC 4, AC 7).');

          // The chip's *bound* is deliberately not asserted here: the fixture's
          // labels are `LAN 1`, so every chip measures 62–79px whether or not
          // anything caps it, and an assertion that cannot fail is worse than no
          // assertion. The last test in this group is where the cap is measured.

          // The state reading survives the shrink: every chip keeps both of its
          // lines, the label and the speed.
          for (var i = 0; i < items.length; i++) {
            final texts = find.descendant(
                of: find
                    .ancestor(
                        of: portGlyphs().at(i), matching: find.byType(Row))
                    .first,
                matching: find.byType(Text));
            expect(texts, findsNWidgets(2),
                reason:
                    'chip $i shows ${texts.evaluate().length} lines at $at, '
                    'not the label and the speed. The speed is the *textual* '
                    'half of the up/down state — `speedLabel` reads `—` for a '
                    'port that is down — so dropping it would leave colour as '
                    'the only signal (#1290 AC 4).');
          }

          expect(find.text(l10n.lanConnected), findsNothing,
              reason: 'the summary tiles are still drawn at $at. They are what '
                  'pushed the port grid out of the viewport, and they are the '
                  'one thing on this card the tap shows in full (#1290 AC 4).');
        }
      });
    }

    testWidgets('a port label the router invents cannot widen the chip',
        (tester) async {
      // The one test in the file with hand-built data, and the only one that can
      // see the chip's text cap. A port label is device data — `LAN 1` today,
      // and nothing stops a future model from sending what this fixture sends —
      // so the cap is what keeps the `Wrap` bounded on hardware CI never sees.
      // Unbounded, each of these chips takes a whole run and the five of them are
      // 160px in a 121px viewport, which is why the seating assertion below is
      // half of the measurement.
      final ports = [
        for (var i = 1; i <= 5; i++)
          EthernetPortUIModel(
            name: 'eth$i',
            label: 'LAN $i — Guest VLAN uplink (2.5GBASE-T, PoE+)',
            isWan: i == 1,
            isUp: true,
            instancePath: 'Device.Ethernet.Interface.$i.',
            currentBitRate: 2500,
          ),
      ];

      const at = '288px (pathological labels)';
      final incidents = await pumpAt(tester,
          cardWidth: 288.0, label: 'compact', ports: ports);
      expectNoOverflow(incidents, at: at);

      final viewport = cardContentViewport(tester);
      final items = portItemRects(tester, compact: true);
      expect(items.length, ports.length,
          reason:
              'the card painted ${items.length} of ${ports.length} ports at '
              '$at');

      for (var i = 0; i < items.length; i++) {
        expect(items[i].width, lessThanOrEqualTo(chipWidthBound + tolerancePx),
            reason: 'chip $i is ${items[i].width.toStringAsFixed(1)}px wide at '
                '$at, past the ${chipWidthBound.toStringAsFixed(0)}px its text '
                'cap bounds it to. The label is allowed to ellipsize — it is '
                'unbounded router data with a tap that shows it in full — but it '
                'is not allowed to set the chip\'s width (#1290 AC 4).');
      }
      expect(seatedCount(items, viewport), items.length,
          reason: 'only ${seatedCount(items, viewport)} of ${items.length} '
              'chips fit the ${viewport.height.toStringAsFixed(0)}px viewport at '
              '$at. An uncapped chip takes a run of its own, and five runs are '
              '160px — the compact form would fit the fixture and fail the '
              'router.');
    });
  });

  group('the tiles are dropped whole, not shrunk', () {
    for (final tag in ['en', 'de']) {
      testWidgets('($tag) both tiles go, and nothing of them is left',
          (tester) async {
        final locale = supportedLocaleFor(tag);
        final l10n = await AppLocalizations.delegate.load(locale);

        await pumpAt(tester,
            cardWidth: desktopCase.cardWidth, label: 'desktop', locale: locale);
        expect(find.byType(SummaryTile), findsNWidgets(2),
            reason: 'the whole form is missing a summary tile, so the '
                'comparison below has nothing to measure against');
        final wholeTileTexts = [
          find.text(l10n.lanConnected).evaluate().length,
          find.text(l10n.connected).evaluate().length,
        ];

        await pumpAt(tester,
            cardWidth: widestRealization, label: 'compact', locale: locale);
        expect(find.byType(SummaryTile), findsNothing,
            reason:
                'the compact form kept a summary tile. Half a pair is worse '
                'than none: #1228 made the two tiles a matched pair precisely so '
                'no change could reach one without the other, and the 121px '
                'viewport has room for neither.');
        expect(wholeTileTexts.every((n) => n > 0), isTrue,
            reason: 'neither tile label was painted by the whole form, so this '
                'test would pass with the tiles shrunk to nothing');
        expect(find.text(l10n.lanConnected), findsNothing);
        expect(find.text(l10n.connected), findsNothing,
            reason: 'a tile label survives in the compact form, so the tiles '
                'were shortened rather than dropped');
      });
    }

    testWidgets('the connected-device line is the only port fact dropped',
        (tester) async {
      await pumpAt(tester, cardWidth: desktopCase.cardWidth, label: 'desktop');
      final wholeItems = portItemRects(tester, compact: false);
      final wholeLines = [
        for (var i = 0; i < wholeItems.length; i++)
          find
              .descendant(
                  of: find
                      .ancestor(
                          of: portGlyphs().at(i), matching: find.byType(Column))
                      .first,
                  matching: find.byType(Text))
              .evaluate()
              .length,
      ];

      await pumpAt(tester, cardWidth: widestRealization, label: 'compact');
      final chips = portItemRects(tester, compact: true);

      expect(chips.length, wholeItems.length,
          reason: 'the compact form shows ${chips.length} ports and the whole '
              'form ${wholeItems.length}. Compact drops facts about a port, '
              'never a port.');
      // The whole form paints a device line only for ports that have one, so
      // "some item had three lines" is the fixture-independent way to say the
      // compact chip's two lines are a *drop* and not a coincidence.
      expect(wholeLines.any((n) => n > 2), isTrue,
          reason:
              'no port in the whole form paints a connected-device line, so '
              'the fixture cannot show what compact drops. Check '
              '`testEthernetPorts` still gives at least one port a device.');
    });
  });

  group('above the threshold the card is whole', () {
    for (final tag in ['en', 'el']) {
      testWidgets('@${desktopCase.widthKey}px ($tag) everything is back',
          (tester) async {
        final locale = supportedLocaleFor(tag);
        final l10n = await AppLocalizations.delegate.load(locale);
        final at = '${desktopCase.widthKey}px ($tag)';
        final incidents = await pumpAt(
          tester,
          cardWidth: desktopCase.cardWidth,
          label: 'desktop',
          locale: locale,
        );
        expectNoOverflow(incidents, at: at);

        // A degradation that leaks upward is the failure mode a density
        // mechanism has and a fixed layout does not, so what compact sheds is
        // asserted back — and AC 7 asks for exactly this width.
        expect(find.byType(SummaryTile), findsNWidgets(2),
            reason: 'a summary tile is missing at $at, so the compact form '
                'leaked past its threshold — a 512px card has room for both');
        final tiles = layoutBlockRects(tester);
        expect(tiles.length, 2);
        expect(tiles[0].top, closeTo(tiles[1].top, 0.01),
            reason: 'the tiles are stacked at $at. Content there is '
                '${(desktopCase.cardWidth - 34).toStringAsFixed(0)}px, well past '
                'the 352px the side-by-side arrangement needs');
        expect(find.text(l10n.lanConnected), findsOneWidget);

        final items = portItemRects(tester, compact: false);
        expect(items.length, 5,
            reason: 'the whole form paints ${items.length} ports at $at');
        for (var i = 0; i < items.length; i++) {
          expect(items[i].width, closeTo(88, tolerancePx),
              reason: 'port item $i is ${items[i].width.toStringAsFixed(1)}px '
                  'wide at $at, not the 88px box the whole form declares — the '
                  'compact chip is bounded at '
                  '${chipWidthBound.toStringAsFixed(0)}px, so this looks like '
                  'the degraded form at a width that has room for the real one');
        }
        expect(tester.getSize(portGlyphs().first).width, closeTo(40, 0.01),
            reason: 'the glyph is not the whole form\'s 40px one');
      });
    }
  });

  group('why the threshold is ${normalAbove.toStringAsFixed(0)}', () {
    // The pinned cases, and the only ones in the file that record a *failure* as
    // the expected outcome: they are what make 386 a measurement rather than a
    // preference.

    testWidgets(
        'pinned normal @${widestRealization.toStringAsFixed(0)}px seats no port '
        'at all', (tester) async {
      await pumpAt(
        tester,
        cardWidth: widestRealization,
        label: 'normal-pinned',
        locale: supportedLocaleFor('de'),
        pin: CardDensity.normal,
      );

      final viewport = cardContentViewport(tester);
      final items = portItemRects(tester, compact: false);
      expect(items.length, 5, reason: 'the normal form lost a port item');

      expect(seatedCount(items, viewport), 0,
          reason: 'the normal form seated '
              '${seatedCount(items, viewport)} of ${items.length} port items at '
              'the widest realization the grid hands out. If that is no longer '
              '0, the vertical bind #1290 AC 1 measured has moved — re-run the '
              'sweep before touching the threshold, because the whole compact '
              'form was declared on it.');
      for (var i = 0; i < items.length; i++) {
        expect(visibleHeight(items[i], viewport), lessThan(1.0),
            reason: 'port item $i shows '
                '${visibleHeight(items[i], viewport).toStringAsFixed(1)}px '
                'inside the ${viewport.height.toStringAsFixed(0)}px viewport. '
                'One item is 82px tall and starts below a 96–136px block of '
                'tiles; anything visible here means the tiles shrank, and the '
                'threshold should be re-measured rather than assumed.');
      }
    });

    testWidgets(
        'pinned normal flips the tiles at exactly '
        '${normalAbove.toStringAsFixed(0)}px', (tester) async {
      final stacked = <double, bool>{};
      for (final width in [normalAbove - 1, normalAbove]) {
        await pumpAt(
          tester,
          cardWidth: width,
          label: 'normal-pinned',
          locale: supportedLocaleFor('en'),
          pin: CardDensity.normal,
        );
        final tiles = layoutBlockRects(tester);
        expect(tiles.length, 2, reason: 'not two tiles at ${width}px');
        stacked[width] = tiles[1].top >= tiles[0].bottom;
      }

      expect(stacked[normalAbove - 1], isTrue,
          reason: 'the tiles already sit side by side at '
              '${(normalAbove - 1).toStringAsFixed(0)}px, so the flip moved '
              'below the declared threshold. The threshold *is* the flip: it is '
              'the width at which the normal form stops costing the ports their '
              'glyphs (0.0px stacked, 38.0px side by side), so re-measure the '
              '1px sweep and move `normalAbove` with it (#1290 AC 2).');
      expect(stacked[normalAbove], isFalse,
          reason: 'the tiles are still stacked at exactly '
              '${normalAbove.toStringAsFixed(0)}px, so the threshold is a pixel '
              'low: the first width that selects the normal form is one where '
              'that form shows no port glyph at all. Content is '
              '`cardWidth − 34`, and the arrangement needs 352.');
    });

    testWidgets('@${normalAbove.toStringAsFixed(0)}px the card selects normal',
        (tester) async {
      final at = '${normalAbove.toStringAsFixed(0)}px';
      final incidents = await pumpAt(
        tester,
        cardWidth: normalAbove,
        label: 'threshold',
      );
      expectNoOverflow(incidents, at: at);

      // The width the threshold names, unpinned: one pixel of card width is the
      // difference between this and the top of the compact band, and it has to
      // be the *selection* that changes, not just the arrangement.
      expect(find.byType(SummaryTile), findsNWidgets(2),
          reason: 'the card is still in its compact form at exactly '
              'normalAbove — densityForWidth is inclusive at the boundary '
              '(width >= normalAbove selects normal)');
      final items = portItemRects(tester, compact: false);
      expect(items.length, 5);
      expect(items.first.width, closeTo(88, tolerancePx),
          reason: 'the ports are still chips at $at');
    });

    testWidgets('@${desktopCase.widthKey}px the desktop loss is unchanged',
        (tester) async {
      // Recorded, not endorsed. This is the price AC 7 charges: keeping the full
      // grid at `desktopCaseFor` means rejecting `normalAbove: 570`, the only
      // threshold under which a port item would seat at 512px. The loss predates
      // #1228 (density design §2.12 point 3) and retires by *height* — at
      // rows = 3, this card's own `HeightStrategy.strict(3)` default, four of the
      // five items seat.
      await pumpAt(tester, cardWidth: desktopCase.cardWidth, label: 'desktop');

      final viewport = cardContentViewport(tester);
      final items = portItemRects(tester, compact: false);
      expect(items.length, 5);

      expect(seatedCount(items, viewport), 0,
          reason: 'a port item now seats whole at '
              '${desktopCase.widthKey}px and rows = $heightRows, which #1290 '
              'measured as impossible and recorded as an out-of-scope loss. If '
              'this fires the card got *better* — re-read §2.12 point 3, and '
              'check whether `normalAbove` is still the right threshold now that '
              'the normal form fits something.');
      expect(visibleHeight(items.first, viewport),
          greaterThan(visibleHeight(items.last, viewport)),
          reason:
              'the first port item is no more visible than the last, so the '
              'ports are not laid out in runs down the card and this '
              'measurement no longer describes the loss it records');
    });
  });
}
