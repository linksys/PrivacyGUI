@Tags(['dashboard-card'])
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/components/card_popup_form.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_client_ui_model.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/local_network/providers/dhcp_data_provider.dart';

import '../../../../golden_test/golden_framework/mocks/mock_dashboard_cards.dart';
import '../../../../golden_test/page/dashboard/cards/fixtures/cards_test_data.dart';
import '../../../../util/app_test_fonts.dart';
import '../../../../util/dashboard/dashboard_card_probe.dart';
import '../../../../util/overflow_probe.dart';

/// `dhcp_reservations` density: what the Active Leases row owes the reader at
/// every width, and where the threshold that guarantees it comes from (#1321).
///
/// ## Why this file exists next to a green gate
///
/// #1183's gate asks one question — did a `RenderFlex` report overflow — against
/// one fixture. #1321 is the ticket that showed both halves of that can be true
/// and still measure the wrong row: the fixture's leases had expired in 2024, so
/// `leaseTimeFormatted` returned the empty string, the trailing slot rendered
/// IP-only, and two swept widths reported clean while a real router clipped the
/// duration off the right edge.
///
/// The fix (a stacked trailing pair below `normalAbove`) makes the gate's own
/// coordinates clean. What the gate still cannot say is *why those widths and not
/// others*, and whether the row that fits is the row a user needs. Both are this
/// file's job:
///
///  - the gate pumps `widthCasesFor` — 260.5px and 288.0px here — plus
///    `normalBandCaseFor`. Every width in between, and the band's own edges, are
///    widths the grid can produce and the gate never realizes.
///  - the gate measures the *fixture*. This file measures the widest row the
///    product can hand the card, which is what the threshold is derived from.
///
/// ## The criterion: both operands are bounded, so both are measured at the bound
///
/// #1289 states it as "a bounded token must never ellipsize, an unbounded one
/// may" — a device *name* is router data no width can accommodate, so `MacBook-A…`
/// is the designed trade. This row has no unbounded operand at all:
///
///  - **the IP** is bounded by its format at 15 characters. `255.255.255.255` is
///    not a client address; it is the widest rendering of one, and the pool is
///    user-editable, so `192.168.100.200` is ordinary. The fixture's
///    `192.168.1.102` is two characters short of the bound, and those two
///    characters are 25 of the 40px that moved the threshold.
///  - **the lease** is bounded by the product's own validator:
///    `validateLeaseTime` caps a pool's lease at 525600 minutes
///    (`usp_local_network_service.dart:197`), so `364d 23h` is the widest string
///    `leaseTimeFormatted` can render for a lease this app will accept.
///
/// Neither can be clipped, and neither ellipsizes if it is — the trailing texts
/// set no `maxLines`, so the row overflows instead. That is why this file asserts
/// **both** no-overflow and painted-inside-the-card: a `ClipRect` anywhere above
/// the row would silence the first while cutting the glyphs, which is the
/// "green but unreadable" failure the epic keeps finding (#1240 AC 1).
///
/// ## What is deliberately not here
///
/// **The popup form.** `minColumns: 4` floors this card at 260.5px, well above
/// `kPopupBelow`, so no width the grid produces selects popup — only #1299's
/// explicit pick reaches it, and
/// `test/page/dashboard/cards/dashboard_card_forced_form_overflow_test.dart`
/// pumps exactly that at 122px. A popup group here would restate it.
///
/// **Twenty-three locales.** Both operands are digits and both are measured at
/// their format bound, so the trailing slot's demand does not move with the
/// string table; the locale dimension belongs to the gate, which sweeps all 26.
/// The threshold's own floor was verified in all 26 before it was declared (369px
/// normal, 367px compact, worst-case rows, all clean) — that measurement is
/// recorded in the spec comment rather than re-run here, because a per-locale
/// sweep of a locale-independent demand is 52 cases that can only fail together.
///
/// ## Mutation ledger
///
/// Each mutation applied alone, reverted before the next, and run against this
/// file and the full `dashboard-card` tag:
///
///   | mutation                                                  | this file | the tag |
///   |-----------------------------------------------------------|-----------|---------|
///   | A `normalAbove: 369` deleted from the spec                 | 9 fail    | 66 fail |
///   | B `normalAbove: 369` → `329` (the fixture-measured floor)  | 1 fail    | 3 fail  |
///   | C the trailing's `compact` branch removed (side by side)   | 4 fail    | 4 fail  |
///   | D `DeviceRow` ignores `compact`, always builds the icon    | 4 fail    | 10 fail |
///
/// **A** is the loud one and belongs to the gate: without a threshold the card has
/// no compact form, so #1183 pumps the original defect again — 52 of its 55
/// failures are 260.5px and 288.0px across all 26 locales, the exact coordinates
/// #1321 was filed for. The other 3 there, plus 1 in the popup file and 1 in the
/// forced-form file, are inventory meta-tests noticing the card left the set.
///
/// **B is the row worth reading.** 329 is a real measurement — of the fixture — and
/// the gate's 1698-case sweep stays green under it, because the gate pumps that same
/// fixture. Its 3 failures are `@329.0px` here plus the two pinned-threshold maps in
/// `dashboard_card_overflow_test.dart`, and those maps only record the number, they
/// do not check it. So one assertion in this file — the worst-case pair at the
/// declared floor — is the only thing in the repo that can tell 369 from 329. That
/// is the whole argument for measuring content at its bound.
///
/// **C and D separate the two halves of the compact form**, and the split is the
/// reason the card's docstring credits the stacking rather than the icon. C kills
/// only the four `both are whole, and stacked` cases; D kills only the four
/// `the icon block is not drawn` cases (plus 6 in
/// `usp_connected_devices_density_test.dart`, which shares `DeviceRow`) — and
/// under D no width in this file overflows, because the row's own title is
/// unbounded and absorbs the 60px the icon takes back. The icon is spent for
/// clarity; the stacking is what makes 200px declarable.
void main() {
  setUpAll(() async {
    // Real fonts: under Ahem every glyph is one square em, so an address measured
    // against a lease string is fiction.
    await loadAppFonts();
  });

  const cardId = 'dhcp_reservations';
  final spec = UspWidgetSpecs.getById(cardId)!;
  final constraints = spec.getConstraints(DisplayMode.normal);
  final heightRows = constraints.minHeightRows;

  /// The declared threshold, with a literal fallback used **only** so the file can
  /// still enumerate its cases when the declaration is missing: `spec.normalAbove!`
  /// would throw before a single test registered, and mutation A would read as
  /// "the file fails to load" rather than as nine assertions about forms the card
  /// no longer selects. The first test is the one that asserts the declaration.
  final normalAbove = spec.normalAbove ?? 369.0;

  final narrowCases = widthCasesFor(spec);
  final desktopCase = desktopCaseFor(spec);
  final widestRealization =
      narrowCases.map((c) => c.cardWidth).reduce(math.max);

  /// The widths that exercise the compact band: its floor, both realizations, and
  /// its top edge. `kPopupBelow` and `normalAbove - 2` are the edges — widths the
  /// grid can hand this card (a 4-column span sizes anywhere between them) but
  /// which no realization the gate enumerates lands on.
  final compactWidths = <double>[
    kPopupBelow,
    ...narrowCases.map((c) => c.cardWidth),
    normalAbove - 2,
  ];

  /// The widest row the product can produce: a 15-character quad and the longest
  /// lease `validateLeaseTime` permits, on every row rather than one, so a fix
  /// that happens to seat the first row is not enough.
  const quad = '255.255.255.255';
  const maxLease = Duration(days: 364, hours: 23, minutes: 59, seconds: 59);

  /// `364d 23h`, derived rather than typed so the expectation cannot drift from
  /// the getter. The trailing `seconds: 59` in [maxLease] is load-bearing for the
  /// same reason the fixture carries it: without it the milliseconds between
  /// construction and layout drop the string to a narrower one.
  final maxLeaseText = DhcpClientUIModel(
    mac: 'AA:BB:CC:DD:EE:02',
    ip: quad,
    leaseActive: true,
    isOnline: true,
    leaseExpiry: DateTime.now().add(maxLease),
  ).leaseTimeFormatted;

  final worstClients = [
    for (final host in ['iPhone-15', 'MacBook-Air', 'Smart-Speaker'])
      DhcpClientUIModel(
        mac: 'AA:BB:CC:DD:EE:0${host.length % 9}',
        ip: quad,
        leaseActive: true,
        isOnline: true,
        hostName: host,
        leaseExpiry: DateTime.now().add(maxLease),
      ),
  ];

  /// Reservations are left at the fixture's three, so the Active Leases section
  /// is under the same vertical load production gives it — the widest row is a
  /// horizontal claim and shortening the card would weaken the vertical one.
  final worstOverrides = cardOverrides(
    dhcpData: DhcpData(
      reservationModels: testDhcpReservations,
      clientModels: worstClients,
    ),
  );

  /// Pumps at an arbitrary [cardWidth] and, unless [pin] says otherwise, lets the
  /// card select its own form through `CardDensityHost`'s `LayoutBuilder` — the
  /// production path. The screen is held at 1440px while the card width varies,
  /// which is the same separation the host makes: density comes from the
  /// constraints the grid hands the card, never from the window.
  Future<List<OverflowIncident>> pumpAt(
    WidgetTester tester, {
    required double cardWidth,
    required String label,
    CardDensity? pin,
    bool worstCase = true,
  }) =>
      probeCardOverflow(
        tester,
        cardId: cardId,
        widthCase: CardWidthCase(
          screenWidth: 1440,
          cardWidth: cardWidth,
          columnSpan: constraints.minColumns,
          label: label,
        ),
        cardHeightRows: heightRows,
        tabIndex: 0,
        locale: const Locale('en'),
        density: pin,
        extraOverrides: worstCase ? worstOverrides : const [],
      );

  /// Same 2.0px tolerance as the #1183 gate, for the same reason: sub-pixel
  /// shaping differences between the mac and ubuntu rasterizers.
  const tolerancePx = 2.0;

  void expectNoOverflow(List<OverflowIncident> incidents,
      {required String at}) {
    final significant = incidents.where((i) => i.pixels > tolerancePx).toList();
    expect(significant, isEmpty,
        reason: 'overflowed at $at:\n${significant.join('\n')}');
  }

  /// Both operands, on all three rows, painted inside the card's own box.
  ///
  /// The rect check is not a restatement of [expectNoOverflow]. Overflow is a
  /// `RenderFlex` diagnostic; a clip is a paint one, and the two are independent —
  /// a `Wrap`, a `ClipRect`, or an `OverflowBox` above this row would report no
  /// overflow while cutting glyphs at the card edge. That combination is what
  /// makes a gate green and a card unreadable, so it is asserted separately.
  void expectBothOperandsWhole(WidgetTester tester, {required String at}) {
    final card = tester.getRect(find.byType(DashboardCardTemplate));

    for (final entry in {'address': quad, 'lease': maxLeaseText}.entries) {
      final finder = find.text(entry.value);
      final found = finder.evaluate().length;
      expect(found, worstClients.length,
          reason: 'expected one ${entry.key} per lease row at $at but found '
              '$found. The assertion below would pass by not looking at '
              'anything, which is exactly how #1321 shipped: the fixture stopped '
              'rendering the lease and every sweep kept reporting clean');

      for (var i = 0; i < found; i++) {
        final text = tester.getRect(finder.at(i));
        expect(text.right, lessThanOrEqualTo(card.right + tolerancePx),
            reason: 'the ${entry.key} on row $i is painted past the card\'s '
                'right edge at $at (text ends at ${text.right.toStringAsFixed(1)}'
                ', card ends at ${card.right.toStringAsFixed(1)}). Both operands '
                'of this row are bounded tokens — a truncated address names no '
                'host and a truncated duration is not a duration');
        expect(text.left, greaterThanOrEqualTo(card.left - tolerancePx),
            reason:
                'the ${entry.key} on row $i starts left of the card at $at, '
                'so the row is being pushed out of its own box rather than '
                'shedding anything');
      }
    }
  }

  group('the card declares a threshold, and where', () {
    test('normalAbove is declared, and bounded on both sides', () {
      expect(spec.normalAbove, isNotNull,
          reason: 'without a threshold every width selects the normal form, '
              'which is the row #1321 measured overflowing by 51.0px at '
              '260.5px on a real router. Every group below asserts a form the '
              'card would no longer select');

      expect(normalAbove, greaterThan(kPopupBelow),
          reason:
              'a threshold at or below $kPopupBelow leaves no compact band: '
              'every width under it selects popup, so the card would drop from '
              'the whole list straight to one number with nothing in between '
              '(densityForWidth precedence rule 1)');

      // The same inversion `connected_devices` declares, and for the same kind of
      // reason: both realizations have to land in compact, because the normal row
      // does not fit at either of them.
      expect(normalAbove, greaterThan(widestRealization),
          reason: 'a threshold at or below '
              '${widestRealization.toStringAsFixed(1)}px leaves the widest width '
              'the grid realizes for this card in the normal form, which is the '
              'form that was clipping the lease there (#1321)');

      expect(normalAbove, lessThan(desktopCase.cardWidth),
          reason: 'a threshold at or above the ${desktopCase.cardWidth}px '
              'desktop width degrades a card that has room: the stacked trailing '
              'and the dropped status dot would ship to 1440px screens');
    });
  });

  group('across the compact band the row keeps both operands', () {
    for (final width in compactWidths) {
      final label = '${width.toStringAsFixed(1)}px';

      testWidgets('@$label both are whole, and stacked', (tester) async {
        final incidents = await pumpAt(tester, cardWidth: width, label: 'band');
        expectNoOverflow(incidents, at: label);

        expect(find.byType(CardPopupForm), findsNothing,
            reason:
                'at $label the card gave up its list. $width is at or above '
                '$kPopupBelow, so the compact form is what it owes the user '
                'here — a list that fits, not a single count');
        expectBothOperandsWhole(tester, at: label);

        // The mechanism, asserted rather than inferred from the fact that it
        // fits: stacking is what turns the slot's demand from `IP + gap + lease`
        // into `max(IP, lease)`, and it is the only reason 200px is declarable.
        final address = tester.getRect(find.text(quad).first);
        final lease = tester.getRect(find.text(maxLeaseText).first);
        expect(lease.top, greaterThanOrEqualTo(address.bottom),
            reason:
                'the lease is still beside the address at $label rather than '
                'under it. Side by side the slot needs ~166px at this content '
                'and the row does not have it — the fit here would be a '
                'coincidence of this fixture rather than the compact form doing '
                'its job (#1321)');
      });

      testWidgets('@$label the icon block is not drawn', (tester) async {
        await pumpAt(tester, cardWidth: width, label: 'band');

        final dots = find.descendant(
          of: find.byType(DeviceRow),
          matching: find.byWidgetPredicate((w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).shape == BoxShape.circle),
        );
        expect(dots, findsNothing,
            reason:
                'the status dot is still drawn at $label, so `DeviceRow` is '
                'still paying 60px for the leading block — the 44px box plus the '
                '16px gap ui_kit adds per occupied slot. Every row here is '
                'online by construction (`build` filters on `isOnline`), so the '
                'dot is the one thing on this row that can be spent');
      });
    }
  });

  group('above the threshold the row is one line again', () {
    for (final width in [normalAbove, desktopCase.cardWidth]) {
      final label = '${width.toStringAsFixed(1)}px';

      testWidgets('@$label the pair is side by side and whole', (tester) async {
        final incidents =
            await pumpAt(tester, cardWidth: width, label: 'normal');
        // Zero, not "under the tolerance": the threshold is defined as the first
        // width at which the row clips nothing, so at the threshold itself the
        // 2.0px allowance must be entirely unspent and available for rasterizer
        // drift. The paired case in the last group asserts the other half — that
        // 2px lower it is not.
        expect(incidents.where((i) => i.pixels > 0), isEmpty,
            reason: 'the row clips at $label, inside the gate\'s tolerance: '
                '${incidents.map((i) => i.pixels.toStringAsFixed(1)).join(', ')}'
                'px. A threshold that only passes because of the tolerance has '
                'nothing left for the drift the tolerance is for');
        expectBothOperandsWhole(tester, at: label);

        final address = tester.getRect(find.text(quad).first);
        final lease = tester.getRect(find.text(maxLeaseText).first);
        expect(lease.top, address.top,
            reason: 'the lease is stacked under the address at $label, so the '
                'compact form has leaked past its own threshold — a degradation '
                'that leaks upward is the failure mode a density mechanism has '
                'and a fixed layout does not');

        final dots = find.descendant(
          of: find.byType(DeviceRow),
          matching: find.byWidgetPredicate((w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).shape == BoxShape.circle),
        );
        expect(dots, findsNWidgets(worstClients.length),
            reason: 'the status dots are missing at $label, which has room for '
                'them: the compact form is being selected above its threshold');
      });
    }
  });

  group('the threshold is a measurement, not a preference', () {
    // The only cases in the suite where a *failure* is the expected outcome. If a
    // future change lets the normal form seat a 15-character quad and a
    // `364d 23h` lease at these widths — a narrower gap, a smaller text style —
    // these fail and the threshold should come down with them.
    //
    // The two use different standards on purpose, and the difference is the
    // spec's "why 369 and not 368" argument made executable.
    testWidgets(
        'pinned normal @${widestRealization.toStringAsFixed(1)}px overflows '
        'the gate\'s own standard', (tester) async {
      final incidents = await pumpAt(
        tester,
        cardWidth: widestRealization,
        label: 'normal-pinned',
        pin: CardDensity.normal,
      );

      final significant =
          incidents.where((i) => i.pixels > tolerancePx).toList();
      expect(significant, isNotEmpty,
          reason: 'the normal form fits the widest row the product can produce '
              'at the widest width the grid realizes for this card, so the '
              'compact form is buying nothing at the coordinate it was declared '
              'for. Re-measure the floor and lower `normalAbove` rather than '
              'leaving a degraded form selected where it is not needed (#1321)');
    });

    testWidgets(
        'pinned normal @${(normalAbove - 2).toStringAsFixed(1)}px still clips, '
        'inside the tolerance', (tester) async {
      final incidents = await pumpAt(
        tester,
        cardWidth: normalAbove - 2,
        label: 'normal-pinned-edge',
        pin: CardDensity.normal,
      );

      // Any clipping at all, not clipping over `tolerancePx`. Two pixels below
      // the threshold the row clips by ~1.4px, which the gate's 2.0px tolerance
      // absorbs — so "the gate would pass here" is true and irrelevant. The
      // tolerance exists for rasterizer drift between the mac and ubuntu font
      // stacks; a threshold placed inside it spends the margin it is there to
      // provide, and 1.4px locally is a failure on CI at the first 0.7px of
      // drift. This is what makes the threshold 369 rather than 367 or 368.
      expect(incidents.where((i) => i.pixels > 0), isNotEmpty,
          reason: 'the normal form clips nothing 2px below the threshold, so '
              '`normalAbove` is 2px higher than the measurement supports. Lower '
              'it to the first width that clips nothing at all — that width, not '
              'the widest one the tolerance forgives, is what the number means '
              'here (#1321)');
    });

    testWidgets('and the fixture alone cannot tell 369 from 329',
        (tester) async {
      // Why the ledger's mutation B is invisible to the gate, pinned so the claim
      // is measured rather than asserted in prose: at 329px the fixture's own
      // rows fit the normal form. A threshold set from them is a real
      // measurement of the wrong content.
      final incidents = await pumpAt(
        tester,
        cardWidth: 329,
        label: 'fixture-pinned',
        pin: CardDensity.normal,
        worstCase: false,
      );
      expectNoOverflow(incidents, at: '329.0px (fixture rows)');
    });
  });
}
