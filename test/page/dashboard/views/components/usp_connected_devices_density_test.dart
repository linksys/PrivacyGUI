@Tags(['layout-gate'])
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/card_density_scope.dart';
import 'package:privacy_gui/page/_shared/components/card_popup_form.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/devices/cards/usp_connected_devices_card.dart';
import 'package:privacy_gui/page/devices/views/components/device_icon_with_badge.dart';

import '../../../../mocks/test_data/scenes/cards_scene_data.dart';
import '../../../../mocks/test_data/devices_test_data.dart';
import '../../../../util/app_test_fonts.dart';
import '../../../../util/dashboard/dashboard_card_probe.dart';
import '../../../../util/dashboard/text_readability_probe.dart';
import '../../../../util/overflow_probe.dart';

/// `connected_devices` density: which form the card selects, and what each form
/// owes the reader (#1289).
///
/// This card declares `normalAbove: 336`, and the number is unusual enough to be
/// the first thing worth stating: it is **above** the 288px realization the grid
/// hands out most often, where #1288's three hero cards all declared thresholds
/// *below* it. That is not an oversight in either direction. A hero card at 288px
/// reads fine and only needs help at the 191px floor; this card at 288px
/// ellipsizes four of its five device names in the normal form, so 288px is
/// precisely where the compact form has to be selected for it to be worth having.
/// The threshold is the measurement, and here the measurement came out the other
/// side of the realization.
///
/// ## Why the existing suites cannot make this claim
///
///   - the #1183 gate asks whether a `RenderFlex` overflowed. This card has been
///     green at both realizations since #1238 — a device name that ellipsizes
///     overflows nothing. Greenness is the premise of #1289, not a gap in it.
///   - `connected_devices_readability_test.dart` pins `CardDensity.normal` (a pin
///     #1289 had to add — see its `pumpAt`). It proves #1238's four removals still
///     hold when the normal form is selected; it deliberately says nothing about
///     when that is.
///   - `dashboard_card_popup_overflow_test.dart` pins `CardDensity.popup`, so it
///     proves the popup form fits, never that a card reaches it.
///
/// Nothing is pinned in the selection groups below: every case goes through
/// `UspWidgetFactory` and `CardDensityHost`'s own `LayoutBuilder`, which is the
/// production path. The one exception is the last group, and it pins normal
/// deliberately to record *why* the threshold sits where it does.
///
/// ## The criterion: a bounded token must never ellipsize, an unbounded one may
///
/// #1289 AC 1's measurement is that this card's "nothing ellipsizes" width is
/// 330px in all 26 locales, bound by the fixture name `Gaming-Console` — a device
/// *name*, which is unbounded router data. No width fixes an arbitrary name and
/// ellipsis on one is the designed behaviour: `MacBook-A…` still identifies a
/// device. `192.168.1.…` does not identify a host, so the address is the token the
/// threshold protects, and a full 15-character quad (93.1px) is what it is
/// measured against. Hence the fourth group: the *address*, never the name.
///
/// ## Mutation ledger
///
/// Every assertion below was run against a mutation of the code it guards and
/// observed to fail. Measured against this file's 19 tests, `connected_devices`'
/// 29 readability tests, and the full 1644-test gate — each mutation applied
/// alone and reverted before the next:
///
///   | mutation                                                  | this file | the gate | readability |
///   |-----------------------------------------------------------|-----------|----------|-------------|
///   | A `normalAbove` deleted from the spec                     | 15 fail   | green    | green       |
///   | B `popupValue` deleted from the card                      | 2 fail    | green    | green       |
///   | C `DeviceRow` ignores `compact`, always builds the icon    | 6 fail    | green    | green       |
///   | D the trailing's `compact` branch removed (badge + label)  | 5 fail    | green    | green       |
///   | E `_kStatusCountsSideBySideMinWidth` 297 → 296             | 1 fail    | green    | green       |
///
/// Every row is green in both existing suites, which is the whole argument for
/// this file existing.
///
/// A is the ticket reverted: with no threshold every width selects normal, so the
/// declaration test, both popup cases, all 8 compact-form cases and all 4
/// compact-band address cases go — and the card paints 23.3px device names at
/// 191px again, which is exactly what the gate calls clean. The 4 survivors are
/// the ones that assert the *normal* form (desktop, the address at 336px, the
/// pinned 288px case) plus the `el` status counts, which read no density at all.
///
/// B is the narrowest and the one worth reading twice: with no `popupValue` the
/// popup form falls back to the card *title*, which renders, fits, and is clean. A
/// 191px card reading "Connected Devices" and nothing else is a working form that
/// says nothing, and it is indistinguishable from a correct one in every other
/// test here.
///
/// C and D are the two halves of the compact form, and what their kill sets
/// disagree about is worth more than the counts. Each takes its own 4 structural
/// cases, as expected. But C also clips the address at **200px and 288px**, while
/// D clips it only at **200px** — even though D re-admits up to 116px of trailing
/// (a badge at its cap plus ui_kit's gap) against C's 60px of leading.
///
/// The badge's own drop rule is the difference, and it is the finding that set the
/// threshold. At 288px the trailing slot is too narrow to seat a capped node name
/// whole, so under D the rule fires and the badge goes — the address survives on
/// the width the rule handed back. The rule stops firing once the slot can seat
/// 100px, which is why the band it fails to protect is the *upper* one (a capped
/// badge measured 69.0px of address at 311px), and why 336 had to come from the
/// threshold rather than from another per-row rule. C's 60px is unconditional, so
/// it clips wherever the column was tight.
///
/// E is a half-pixel — 0.264px, in `el`, at one width — and the only mutation in
/// this table that was live in production before the ticket. It is the reason the
/// counts group asserts on *layout* rather than on overflow: the gate's 2.0px
/// tolerance cannot see it, and neither could a pixel assertion that has to
/// survive two rasterizers.
void main() {
  setUpAll(() async {
    // Real fonts: under Ahem every glyph is one square em, so which token is the
    // widest — the whole criterion above — is fiction.
    await loadAppFonts();
  });

  const cardId = 'connected_devices';
  final spec = UspWidgetSpecs.getById(cardId)!;
  final constraints = spec.getConstraints(DisplayMode.normal);
  final heightRows = constraints.minHeightRows;

  /// The declared threshold, and a literal fallback used **only** so the file can
  /// still enumerate its cases when the declaration is missing.
  ///
  /// `spec.normalAbove!` would throw here — before a single test registers — and
  /// mutation A in the ledger above would have read as "the file fails to load"
  /// rather than as 15 assertions about forms the card no longer selects. A test
  /// suite that cannot describe the bug it catches is not much better than one
  /// that misses it, so the number is duplicated on purpose, and the first test in
  /// the file is the one that asserts the spec still declares it.
  final normalAbove = spec.normalAbove ?? 336.0;

  /// The widths the gate realizes (191.375px, 288.000px) and the desktop width it
  /// never pumps (512px), from the same helpers the gate uses.
  final narrowCases = widthCasesFor(spec);
  final desktopCase = desktopCaseFor(spec);
  final widestRealization =
      narrowCases.map((c) => c.cardWidth).reduce(math.max);

  /// The three widths that exercise the compact band, and one that exercises a
  /// half-pixel inside it.
  ///
  /// 288px is a realization; 200px and `normalAbove − 2` are the band's own
  /// edges, which the grid can produce (a 3-column span on a 700px screen is
  /// 228.5px) but never does for *this* card's realizations. A band no test enters
  /// is a band whose contents were never seen.
  ///
  /// 330px is where the card's content is exactly 296px — the side-by-side status
  /// counts' old threshold, and the width at which `el` overflowed it by 0.264px
  /// before #1289 raised it to 297.
  const compactWidths = <double>[kPopupBelow, 288.0, 330.0];

  /// What the fixture makes true, derived rather than typed: 6 devices, 5 active.
  final onlineCount = testDevices.where((d) => d.isActive).length;
  final totalCount = testDevices.length;

  /// The most demanding row shapes the card can be handed — a full 15-character
  /// IPv4 quad on a WiFi row behind a mesh node, on a WiFi row with none, on a
  /// wired row (whose trailing is the interface label rather than bars), and on a
  /// row whose node name is at the 100px badge cap.
  ///
  /// The quad is the *bounded* token from the criterion above. `255.255.255.255`
  /// is not a client address; it is the widest 15-character rendering of one, and
  /// bounding the format is the point.
  final worstRows = <ClientDevice>[
    DevicesTestData.createWifiClient(
      mac: '00:11:22:33:44:01',
      ip: '255.255.255.255',
      hostName: 'Smart-Speaker',
      parentNodeName: 'MR7500',
    ),
    DevicesTestData.createWifiClient(
      mac: '00:11:22:33:44:02',
      ip: '255.255.255.255',
      hostName: 'iPhone-15',
    ),
    DevicesTestData.createWiredClient(
      mac: '00:11:22:33:44:03',
      ip: '255.255.255.255',
      hostName: 'Gaming-Console',
    ),
    DevicesTestData.createWifiClient(
      mac: '00:11:22:33:44:04',
      ip: '255.255.255.255',
      hostName: 'MacBook-Air',
      parentNodeName: 'Living-Room-Extender-2',
    ),
  ];

  /// Pumps at an arbitrary [cardWidth] and lets the card select its own form.
  ///
  /// The screen is held at 1440px while the card width varies, which is the same
  /// separation `CardDensityHost` makes: density comes from the constraints the
  /// grid hands the card, never from the window.
  Future<List<OverflowIncident>> pumpAt(
    WidgetTester tester, {
    required double cardWidth,
    required String label,
    Locale locale = const Locale('en'),
    List<ClientDevice>? devices,
    CardDensity? pin,
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
        locale: locale,
        density: pin,
        // Only when a specific row shape is needed. The wrapper reproduces
        // `UspWidgetFactory.buildWidget` exactly — same `cardId`, same
        // `normalAbove` read from the same spec — because the alternative is
        // choosing between production *selection* and controlled *data*, and the
        // quad cases need both. Everything else in this file goes through the
        // factory untouched, so a card renamed or unregistered still fails loudly.
        cardOverride: devices == null
            ? null
            : CardDensityHost(
                cardId: cardId,
                normalAbove: spec.normalAbove,
                // The same width the probe's `SizedBox` gets, because that is
                // what the factory would have been handed here (#1401).
                cardWidth: cardWidth,
                child: UspConnectedDevicesCard(devices: devices),
              ),
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

  /// Every IPv4 quad on screen, and whether the row it sits in let it stay whole.
  void expectQuadsWhole(WidgetTester tester, {required String at}) {
    final quads = find.text('255.255.255.255');
    final count = quads.evaluate().length;
    expect(count, worstRows.length,
        reason: 'expected one address per row at $at but found $count — the '
            'assertion below would pass by not looking at anything');

    for (var i = 0; i < count; i++) {
      final finder = quads.at(i);
      expect(tester.isTextClipped(finder), isFalse,
          reason: 'the address was ellipsized at $at: it needs '
              '${tester.widestTokenWidth(finder).toStringAsFixed(1)}px and the '
              'row granted '
              '${tester.paragraphOf(finder).size.width.toStringAsFixed(1)}px. '
              'An address is a bounded token and truncating it destroys the '
              'value rather than shortening it — 192.168.1.… names no host. '
              'Either the compact form is not shedding enough or the threshold '
              'is too low (#1289).');
    }
  }

  group('the card declares a threshold, and where', () {
    test('normalAbove is declared and bounded by both realizations', () {
      expect(spec.normalAbove, isNotNull,
          reason: 'without a threshold this card claims it needs no degraded '
              'form, which #1240 recorded and #1289 measured to be false. Every '
              'group below asserts a form the card would no longer select.');

      expect(normalAbove, greaterThan(kPopupBelow),
          reason:
              'a threshold at or below $kPopupBelow leaves no compact band: '
              'every width under it selects popup, so the card drops straight '
              'from whole to one line with nothing in between '
              '(densityForWidth precedence rule 1).');

      // The inversion of the bound `usp_hero_row_density_test.dart` asserts, and
      // the reason is in this file's header: at 288px the normal form ellipsizes
      // four of five device names, so this realization has to land in compact for
      // the compact form to be worth declaring.
      expect(normalAbove, greaterThanOrEqualTo(widestRealization),
          reason: 'a threshold below ${widestRealization.toStringAsFixed(1)}px '
              'leaves the widest realization the grid hands out in the normal '
              'form, which is the form #1289 measured as unreadable there.');

      expect(normalAbove, lessThan(desktopCase.cardWidth),
          reason: 'a threshold at or above the ${desktopCase.cardWidth}px '
              'desktop width degrades a card that has room — the compact form '
              'would ship to 1440px screens, dropping icons and mesh badges '
              'nobody was short of space for.');
    });
  });

  group('below 200px the card selects its popup form', () {
    final narrowest = narrowCases.first;

    for (final tag in ['en', 'el']) {
      testWidgets('@${narrowest.widthKey}px ($tag)', (tester) async {
        final l10n =
            await AppLocalizations.delegate.load(supportedLocaleFor(tag));
        final incidents = await pumpAt(
          tester,
          cardWidth: narrowest.cardWidth,
          label: 'min',
          locale: supportedLocaleFor(tag),
        );
        expectNoOverflow(incidents, at: '${narrowest.widthKey}px ($tag)');

        expect(find.byType(CardPopupForm), findsOneWidget,
            reason: 'at ${narrowest.cardWidth.toStringAsFixed(1)}px the card '
                'still rendered a device list. That width is below $kPopupBelow '
                'and #1238 measured what a row gets there: 23.3px of column for '
                'a name and an address both, i.e. one character and an ellipsis '
                'each (#1289).');

        // The list is gone, not merely narrower. This is what separates popup
        // from compact and it is the assertion mutation A trips first.
        expect(find.byType(DeviceRow), findsNothing,
            reason: 'the popup form is showing device rows, so this is not the '
                'popup form');

        final popup = tester.widget<CardPopupForm>(find.byType(CardPopupForm));
        expect(popup.value, isNotNull,
            reason: 'no popupValue declared, so the card degrades to its own '
                'title. A card that declares a threshold must also declare the '
                'one value the threshold is protecting (#1288 §2.1).');
        expect(popup.value, l10n.nOnlineOfTotal('$onlineCount', '$totalCount'),
            reason: 'the popup value is "${popup.value}", which is not the '
                'online-of-total reading. Both counts, not just the online one: '
                '"$onlineCount online" without a total says nothing about the '
                '${totalCount - onlineCount} that are not.');
        expect(find.text(popup.value!), findsOneWidget,
            reason: 'the declared value was not painted — declaring it and '
                'showing it are two different things');
      });
    }
  });

  group('from 200px to the threshold the card selects its compact form', () {
    for (final width in [...compactWidths, normalAbove - 2]) {
      final label = '${width.toStringAsFixed(0)}px';

      testWidgets('@$label the rows are there and the icon block is not',
          (tester) async {
        final incidents =
            await pumpAt(tester, cardWidth: width, label: 'compact');
        expectNoOverflow(incidents, at: label);

        expect(find.byType(CardPopupForm), findsNothing,
            reason:
                'at $label the card gave up its list entirely. $width is at '
                'or above $kPopupBelow, so the compact form is what it owes the '
                'user here — a list that fits, not a single line (#1289).');
        expect(find.byType(DeviceRow), findsWidgets,
            reason: 'no device rows at $label');

        // The 60px the address is spending: the 44px block plus the 16px gap
        // ui_kit adds for an occupied leading slot.
        expect(find.byType(DeviceIconWithBadge), findsNothing,
            reason: 'the icon block is still drawn at $label, so the row is '
                'still paying 60px for it — by far the largest lever the row '
                'has, and the one the compact form is (#1289 AC 3).');
      });

      testWidgets('@$label the unbounded trailing demands are dropped',
          (tester) async {
        await pumpAt(tester, cardWidth: width, label: 'compact');

        // `MR7500` is the fixture's node name on two rows. The badge renders a
        // node *name* — unbounded data capped at 100px — so keeping it would make
        // the address column a function of how the user named their extender.
        expect(find.text('MR7500'), findsNothing,
            reason:
                'the parent-node badge is still drawn at $label. Its demand '
                'is capped at 100px, so the badge always "fits" by its own '
                'per-row rule and only the threshold or this form can decline it '
                '(#1289 AC 3).');

        // The widest fixed trailing this row has (34.2px against the bars'
        // 22.0px) and the only one that is pure text.
        expect(find.text('Wired'), findsNothing,
            reason:
                'the interface label is still drawn at $label. It is a type '
                'statement the icon also makes in the normal form; the bars stay '
                'because nothing else on the row carries a signal reading '
                '(#1289 AC 3).');
      });
    }

    testWidgets('@330px (el) the status counts stack', (tester) async {
      const el = Locale('el');
      final l10n = await AppLocalizations.delegate.load(el);
      await pumpAt(tester, cardWidth: 330.0, label: 'compact', locale: el);

      // Layout, not pixels, and #1289's header says why: side by side here
      // overflows by 0.264px, which is inside the gate's 2.0px tolerance and
      // inside the noise a two-rasterizer pixel assertion has to absorb. Where
      // the second count *sits* is not.
      final online = tester.getTopLeft(find.text(l10n.online));
      final offline = tester.getTopLeft(find.text(l10n.offline));
      expect(offline.dy, greaterThan(online.dy),
          reason: 'the two status counts share a row at 330px, where this '
              "card's content is exactly 296px. `el` needs 296.264px to seat "
              '«${l10n.offline}» side by side — #1238 derived 289.4 and read the '
              'difference as slack, and #1289 measured it as a 0.264px overflow '
              'at exactly this width (#1289).');
    });
  });

  group('above the threshold the card is whole', () {
    testWidgets('@${desktopCase.widthKey}px everything is back',
        (tester) async {
      final incidents = await pumpAt(
        tester,
        cardWidth: desktopCase.cardWidth,
        label: 'desktop',
      );
      expectNoOverflow(incidents, at: '${desktopCase.widthKey}px');

      // A degradation that leaks upward is the failure mode a density mechanism
      // has and a fixed layout does not, so each thing the compact form sheds is
      // asserted back.
      expect(find.byType(DeviceIconWithBadge), findsWidgets,
          reason: 'the icon block is missing at ${desktopCase.widthKey}px, so '
              'the compact form leaked past its threshold');
      expect(find.text('MR7500'), findsWidgets,
          reason: 'the mesh badge is missing on a 512px card, which has room '
              'for it — dropping it here loses which node a device is on');
      expect(find.text('Wired'), findsWidgets,
          reason: 'the interface label is missing on a 512px card');
    });
  });

  group('the address stays whole across the compact band (#1289 AC 1)', () {
    for (final width in [...compactWidths, normalAbove - 2]) {
      final label = '${width.toStringAsFixed(0)}px';

      testWidgets('@$label all four worst-case rows keep their address',
          (tester) async {
        final incidents = await pumpAt(
          tester,
          cardWidth: width,
          label: 'compact-quad',
          devices: worstRows,
        );
        expectNoOverflow(incidents, at: '$label (worst rows)');
        expectQuadsWhole(tester, at: label);
      });
    }

    testWidgets(
        '@${normalAbove.toStringAsFixed(0)}px the normal form holds it '
        'too', (tester) async {
      final incidents = await pumpAt(
        tester,
        cardWidth: normalAbove,
        label: 'normal-quad',
        devices: worstRows,
      );
      expectNoOverflow(incidents,
          at: '${normalAbove.toStringAsFixed(0)}px (worst rows)');
      expectQuadsWhole(tester, at: '${normalAbove.toStringAsFixed(0)}px');
    });

    // The one pinned case in the file, and the only one that records a *failure*
    // as the expected outcome: it is what makes 336 a measurement rather than a
    // preference. If a future change lets the normal form seat the address at
    // 288px — a smaller badge cap, a narrower indicator — this test fails and the
    // threshold should come down with it.
    testWidgets('pinned normal @288px cannot, which is what 336 is for',
        (tester) async {
      await pumpAt(
        tester,
        cardWidth: widestRealization,
        label: 'normal-pinned',
        devices: worstRows,
        pin: CardDensity.normal,
      );

      final quads = find.text('255.255.255.255');
      expect(quads.evaluate(), isNotEmpty);
      final clipped = List.generate(quads.evaluate().length, (i) => i)
          .where((i) => tester.isTextClipped(quads.at(i)))
          .length;
      expect(clipped, greaterThan(0),
          reason: 'the normal form seated every address at '
              '${widestRealization.toStringAsFixed(0)}px, so the compact form is '
              'no longer buying anything at the realization it was declared for. '
              'Re-measure the floor (#1289 AC 1) and lower normalAbove rather '
              'than leaving a degraded form selected at a width that does not '
              'need it.');
    });
  });
}
