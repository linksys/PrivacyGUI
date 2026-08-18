@Tags(['dashboard-card'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/devices/cards/usp_connected_devices_card.dart';
import 'package:privacy_gui/page/devices/views/components/usp_signal_strength_indicator.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../mocks/test_data/devices_test_data.dart';
import '../../../../util/app_test_fonts.dart';
import '../../../../util/dashboard/dashboard_card_probe.dart';
import '../../../../util/overflow_probe.dart';

/// Connected Devices readability (#1238).
///
/// ## Why this file exists alongside the #1183 gate
///
/// #1238 clears all 27 of this card's coordinates: the two status counts stack
/// once the card cannot hold them side by side, the device row drops its
/// `-NN dBm` label at the one realization that cannot seat the indicator, and it
/// drops the parent-node badge on the rows whose slot could only ellipsize it.
/// All three are **removals**, and the gate rewards a removal exactly as much as
/// a fix:
///
///   - A `showLabel: false` hardcoded at the call site takes all 26 coordinates
///     green while deleting the signal reading on every screen size, desktop
///     included. Nothing in `known_overflows.json` can express "the dBm value is
///     still there where it fits".
///   - Same for the parent-node badge: absent content never overflows.
///   - Stacking is invisible to the gate in the other direction too. A threshold
///     raised past the desktop realization leaves the gate green and the counts
///     stacked on a 1440px screen — 235px of block holding 67px of text.
///   - A stacked pair occupies 96px of a 261px content viewport — 52px more than
///     the 44px it takes side by side. The template *scrolls*,
///     so a stacked pair that pushed the device list out of view would overflow
///     nothing at all.
///
/// So each group below asserts on the rendered tree. Every assertion here was
/// run against a mutation of the code it guards and observed to fail — these are
/// the runs, with the tests each one killed:
///
///   | mutation                                        | tests killed             |
///   |-------------------------------------------------|--------------------------|
///   | A `_kSignalLabelContentMinWidth` 231 → 0        | label suppressed @min (1) |
///   | B `_kSignalLabelContentMinWidth` 231 → 9999     | every reading labelled @preferred+@desktop (2) |
///   | C `SummaryTile.inline` gains `EdgeInsets.all(60)` | el fits @min, list visible @min+@preferred, nothing overflows @between 209px (4) |
///   | D interface label gated on `showSignalLabel`    | Wired labelled @min (1) |
///   | E `_kStatusCountsSideBySideMinWidth` 296 → 0    | counts stack @min+@preferred, el fits @min+@preferred (4) |
///   | F `_kStatusCountsSideBySideMinWidth` 296 → 600  | counts share a row @desktop (1) |
///   | G badge gated on the label's threshold          | badge shown @desktop, short name kept ×3, long name kept @desktop (5) |
///   | H badge always shown                            | badge dropped @min, long name dropped @min (2) |
///   | J device name dropped from the tile             | name still drawn @min+@preferred (2) |
///   | K badge never shown                             | same 5 as G |
///   | M indicator dropped at every narrow width       | bars drawn @min+@preferred, every reading labelled @preferred+@desktop (4) |
///   | N label decided from the slot, not the card     | every reading labelled @preferred+@desktop (2) |
///   | P interface label removed                       | Wired labelled @min+@preferred+@desktop (3) |
///   | Q `_kSignalLabelContentMinWidth` 231 → 175      | nothing overflows @between 209+234+250+264 (4) |
///
/// N is the one worth reading twice, because it is what the first cut of this fix
/// actually did. ui_kit v2.34.10 hands the trailing slot a finite cap, so reading
/// it looks like reading a budget — but the cap is the row's *own demand*, so a
/// longer device name lowers it. Measured on the gate's fixture at a 512px card:
/// `iPhone-15` got 75.0px and kept its `-45 dBm`, `MacBook-Air` got 64.8px and
/// `Smart-Speaker` 22.0px, and both lost theirs on a 1440px screen. Nothing
/// overflowed, so the gate called it fixed; the screenshot did not. Hence the
/// label is decided once from the card's content width and only the badge — the
/// one thing whose own width *is* the demand — is decided per row.
///
/// Q is the same lesson from the other side, and it is the value this fix
/// actually shipped with first: 175 is what the tile's 25% content floor implies
/// on its own, and it holds at both realizations while overflowing by up to
/// +33.0px at every width between them. The gate pumps only the *narrowest*
/// realization of each span, so all 1644 of its checks stayed green.
///
/// Of the fourteen, only A, C and E leave overflow behind at a width the gate
/// pumps, so only those three would also fail it. Q leaves overflow the gate is
/// structurally unable to see; the other ten take content away or move it out of
/// view, which is exactly what the gate rewards. That is why this file exists.
///
/// Row C named a private widget in the card until #1275 moved the tile onto
/// `layout_blocks`' [SummaryTile]; the mutation is now applied to
/// `SummaryTile.inline`. Re-running it killed a fourth test — the 209px `@between`
/// one — which the row had not recorded: replaying the same mutation against the
/// pre-#1275 card kills the identical four, so that is a stale count in the row,
/// not a behaviour change from the extraction.
///
/// ## What this file does NOT claim
///
/// The device rows are legible only in the sense that nothing is clipped. At the
/// 191px realization the tile gives the device name **23-27px** — one glyph and
/// an ellipsis — because a 44px leading icon and the signal bars take 66px of a
/// 141px row before the name is measured at all. That is the row *shape*, not the
/// overflow, and it is what #1240 owns; the numbers are recorded in
/// `doc/dashboard/dashboard_density_design.md` section 2.6 so the compact-forms
/// work has them. Asserting the 23px here would pin a value nobody wants, so
/// this file asserts only that the name is drawn and that the trailing yields
/// first — the parts #1238 is responsible for.
///
/// Nothing here re-measures overflow — that is the gate's job, and both
/// `connected_devices` keys are gone from `known_overflows.json`.
///
/// Tagged `dashboard-card` so it gates PRs: `run_tests.sh` excludes
/// `golden||loc||ui`, so a `ui`-tagged test here would block nothing.
void main() {
  setUpAll(() async {
    // Real fonts: under the Ahem block font every glyph is one square em, so
    // what does and does not fit — and therefore what ellipsizes — is fiction.
    await loadAppFonts();
  });

  const cardId = 'connected_devices';
  final spec = UspWidgetSpecs.all.firstWhere((s) => s.id == cardId);
  final heightRows = spec.getConstraints(DisplayMode.normal).minHeightRows;

  /// Pumps the card at one width, as the gate does — one pump, real fonts.
  ///
  /// Density is pinned to [CardDensity.normal], added by #1289 and the same pin
  /// `usp_hero_row_readability_test.dart` took for the same reason. This card now
  /// declares `normalAbove: 336`, which is above *both* widths the gate realizes,
  /// so unpinned this helper would render the popup form at 191.4px and the
  /// compact form at 288px — and 7 of the assertions below would fail on content
  /// that is no longer on screen rather than on content that stopped fitting. The
  /// honest reading of those 7 failures is "this width no longer shows this", not
  /// "the readability regressed", and a test that cannot tell those apart is
  /// worse than no test.
  ///
  /// The assertions keep their meaning under the pin: 191.4px is the narrowest
  /// width the *normal* form can be asked for, so it stays the strictest test of
  /// #1238's four removals, and those still govern every width from 336px up —
  /// where the card is now most of the time it is not on a phone. What #1289
  /// changed is which form is *selected*; `usp_connected_devices_density_test.dart`
  /// is the file that asserts that, and it pins nothing.
  Future<void> pumpAt(
    WidgetTester tester, {
    required CardWidthCase widthCase,
    required Locale locale,
  }) =>
      probeCardOverflow(
        tester,
        cardId: cardId,
        widthCase: widthCase,
        cardHeightRows: heightRows,
        tabIndex: 0,
        locale: locale,
        density: CardDensity.normal,
      );

  /// The widths the gate measures — the narrowest realization of the card's min
  /// and preferred spans. Sourced from the helper the gate uses, so this test
  /// cannot drift from the widths that are actually enforced.
  final narrowCases = widthCasesFor(spec);

  /// The one width the gate never pumps: the card with room.
  final desktopCase = desktopCaseFor(spec);

  /// Pumps the card at one width with a hand-picked device list, through the
  /// same harness — not merely the same geometry — that [pumpAt] uses.
  ///
  /// The gate's fixture is the whole dashboard's kitchen sink, so it cannot be
  /// asked for a specific row shape. The card takes its devices as a parameter
  /// for exactly this reason, and `cardOverride` is the one thing here that does
  /// not go through the factory — everything else must, so that a card renamed or
  /// re-registered breaks loudly. Going through [probeCardOverflow] rather than
  /// re-building the app is what keeps the two in step: an earlier version of this
  /// re-implemented `buildDashboardCardApp` and silently lost the `Portal`, the
  /// `disableAnimations` wrapper, the locale fallback fonts and the settle, so
  /// "the same geometry" was true and "the same rendering" was not.
  ///
  /// Overflows are collected rather than thrown, exactly as [probeCardOverflow]
  /// does for the gate's own pumps, and returned. Without the collection an
  /// overflow anywhere in this fixture fails these tests with a `RenderFlex
  /// overflowed` error, and a group that says "the badge is kept" would be
  /// reporting something else entirely. Returning them is what lets the
  /// in-between widths — the ones the gate never pumps — assert on overflow here.
  Future<List<OverflowIncident>> pumpDevices(
    WidgetTester tester, {
    required CardWidthCase widthCase,
    required List<ClientDevice> devices,
    Locale locale = const Locale('en'),
  }) =>
      probeCardOverflow(
        tester,
        cardId: cardId,
        widthCase: widthCase,
        cardHeightRows: heightRows,
        tabIndex: 0,
        locale: locale,
        cardOverride: UspConnectedDevicesCard(devices: devices),
      );

  /// The `-NN dBm` readings currently on screen.
  Finder signalLabels() => find.byWidgetPredicate(
        (w) => w is Text && (w.data?.contains('dBm') ?? false),
      );

  /// The signal-strength bar groups — the part that must survive the label being
  /// dropped, because it is what still carries the reading.
  Finder signalIndicators() => find.byType(UspSignalStrengthIndicator);

  group('the status counts stack where they do not fit (#1238)', () {
    for (final wc in narrowCases) {
      testWidgets('@${wc.label} ${wc.widthKey}px the counts stack',
          (tester) async {
        await pumpAt(tester, widthCase: wc, locale: const Locale('el'));

        final blocks = layoutBlockRects(tester);
        expect(blocks.length, 2,
            reason: 'expected exactly the online and offline count blocks');
        expect(
          blocks[1].top,
          greaterThanOrEqualTo(blocks[0].bottom),
          reason: 'at ${wc.widthKey}px the card gives its content '
              '${blocks[0].width.toStringAsFixed(1)}px, and side by side that '
              'leaves each count half of it — less than the dot, the number and '
              'the word need in any locale. The counts must stack (#1238).',
        );
      });
    }

    testWidgets('@desktop ${desktopCase.widthKey}px the counts share a row',
        (tester) async {
      // The stacking is a narrow-width degradation, not a redesign. A threshold
      // raised past the desktop realization would fail here and nowhere else.
      await pumpAt(tester, widthCase: desktopCase, locale: const Locale('el'));

      final blocks = layoutBlockRects(tester);
      expect(blocks.length, 2);
      expect(blocks[0].top, closeTo(blocks[1].top, 0.01),
          reason: 'at ${desktopCase.widthKey}px the counts must still sit side '
              'by side');
      expect(blocks[1].left, greaterThan(blocks[0].right),
          reason: 'the offline count must start after the online count ends');
    });
  });

  group('each count keeps its word whole (#1238)', () {
    // `el` is the locale to assert on: «Χωρίς σύνδεση» is the widest `offline`
    // rendering of the 26 (116.7px all in, against `en`'s 66.8px and `zh`'s
    // 52.2px), so it is the one that binds the threshold. A locale whose word
    // fits with room to spare cannot detect a shrinking block at all.
    //
    // This is a legibility claim, not an overflow one: the two texts are
    // unwrapped, so a block too narrow for them overflows rather than truncating
    // — which is the gate's business. What is measured here is that the content
    // sits *inside* the block it was given, with the same 2px tolerance the gate
    // uses, so a count cannot be declared fixed while resting on the tolerance.
    for (final wc in narrowCases) {
      testWidgets('@${wc.label} ${wc.widthKey}px el fits both counts',
          (tester) async {
        await pumpAt(tester, widthCase: wc, locale: const Locale('el'));

        final blocks = layoutBlockRects(tester);
        expect(blocks.length, 2);

        for (var i = 0; i < 2; i++) {
          final texts = find.descendant(
            of: find.byType(LayoutBlock).at(i),
            matching: find.byType(Text),
          );
          expect(texts.evaluate().length, 2,
              reason: 'count block $i must render the number and the word');

          for (var j = 0; j < 2; j++) {
            final r = tester.getRect(texts.at(j));
            expect(
              r.right,
              lessThanOrEqualTo(blocks[i].right + 2.0),
              reason: 'count block $i text $j ends at '
                  '${r.right.toStringAsFixed(1)} but its block ends at '
                  '${blocks[i].right.toStringAsFixed(1)}. Stacking exists to '
                  'give the pair the full content width instead of making the '
                  'text give way (#1238).',
            );
          }
        }
      });
    }
  });

  group('stacking does not push the device list out of view (#1238)', () {
    // Stacking adds 52px, taking the pair from 44px to 96px of a 261px content
    // viewport. The template scrolls, so a pair
    // that grew until the list was below the fold would overflow nothing — the
    // gate cannot trade a right overflow for an invisible list, but a careless
    // padding change can.
    for (final wc in narrowCases) {
      testWidgets(
          '@${wc.label} ${wc.widthKey}px both counts and a device row are '
          'visible', (tester) async {
        await pumpAt(tester, widthCase: wc, locale: const Locale('en'));

        final viewport = cardContentViewport(tester);
        final blocks = layoutBlockRects(tester);
        expect(blocks.length, 2);

        for (var i = 0; i < 2; i++) {
          expect(
            blocks[i].bottom,
            lessThanOrEqualTo(viewport.bottom),
            reason: 'count block $i ends at ${blocks[i].bottom} but the card '
                'only shows content down to ${viewport.bottom}',
          );
        }

        final tiles = find.byType(AppListTile);
        expect(tiles.evaluate(), isNotEmpty,
            reason: 'the card rendered no device rows');
        final firstRow = tester.getRect(tiles.first);
        expect(
          firstRow.bottom,
          lessThanOrEqualTo(viewport.bottom),
          reason: 'the first device row ends at ${firstRow.bottom}, below the '
              'card\'s ${viewport.bottom} content bottom — the counts have '
              'taken the whole viewport and the list is only reachable by '
              'scrolling (#1238).',
        );
      });
    }
  });

  group('the signal reading degrades, it does not disappear (#1238)', () {
    // Where there is room, *every* reading is labelled — not merely one of them.
    // Counting is the whole point: a label decided from the tile's trailing cap
    // instead of the card's content width leaves `iPhone-15` with `-45 dBm` and
    // `MacBook-Air`, one row below on the same 1440px screen, with bare bars,
    // because the cap is that row's own demand and a longer name lowers it
    // (measured: 75.0px against 64.8px against 22.0px). Nothing overflows either
    // way, so the gate reports both as fixed.
    for (final wc in [narrowCases.last, desktopCase]) {
      testWidgets('@${wc.label} ${wc.widthKey}px every reading is labelled',
          (tester) async {
        await pumpAt(tester, widthCase: wc, locale: const Locale('en'));

        final indicators = signalIndicators().evaluate().length;
        expect(indicators, greaterThan(0),
            reason: 'the fixture must have WiFi rows to read');
        expect(
          signalLabels().evaluate().length,
          indicators,
          reason: 'at ${wc.widthKey}px the content is '
              '${wc.cardWidth.toStringAsFixed(0)}px wide for every row alike, so '
              'either all $indicators readings carry their `-NN dBm` or none do. '
              'A per-row answer here is a per-row answer the user cannot '
              'explain (#1238).',
        );
      });
    }

    for (final wc in narrowCases) {
      testWidgets('@${wc.label} ${wc.widthKey}px the bars are drawn',
          (tester) async {
        await pumpAt(tester, widthCase: wc, locale: const Locale('en'));

        // At the min realization the trailing slot is capped at 35.0px and the
        // labelled indicator wants 75.0-80.8px, so it is the label that goes —
        // but the four bars are 22.0px and keep their design size, carrying the
        // strength on their own. A trailing that dropped both would also be
        // gate-green.
        expect(signalIndicators().evaluate(), isNotEmpty,
            reason: 'the signal bars must still be drawn at ${wc.widthKey}px — '
                'they are what is left of the reading (#1238)');
      });
    }

    testWidgets(
        '@min ${narrowCases.first.widthKey}px the label is suppressed, not '
        'clipped', (tester) async {
      // Narrowest realization only: 157.4px of content leaves the trailing slot
      // 35.0px, against 75.0px for a 2-digit reading and 80.8px for `-100 dBm`.
      // Asserting absence at the preferred width would pin the wrong thing —
      // 254px gives the slot 98.5px and the label is drawn there.
      await pumpAt(tester,
          widthCase: narrowCases.first, locale: const Locale('en'));

      expect(signalLabels().evaluate(), isEmpty,
          reason:
              'at ${narrowCases.first.widthKey}px the label must be dropped '
              'rather than left to overflow (#1238)');
    });
  });

  group('the parent-node badge yields before the device name (#1238)', () {
    testWidgets('@desktop ${desktopCase.widthKey}px the badge is shown',
        (tester) async {
      await pumpAt(tester, widthCase: desktopCase, locale: const Locale('en'));

      expect(find.text('MR7500').evaluate(), isNotEmpty,
          reason:
              'the node a client is attached to is real information and the '
              'slot has room for it at ${desktopCase.widthKey}px');
    });

    for (final wc in narrowCases) {
      testWidgets(
          '@${wc.label} ${wc.widthKey}px the device name is still drawn',
          (tester) async {
        await pumpAt(tester, widthCase: wc, locale: const Locale('en'));

        // Before ui_kit v2.34.10 the tile absorbed a too-wide trailing by
        // starving its title column to 0px — a row with no name. The trailing
        // now gives way instead; this pins the consequence rather than the
        // mechanism.
        final title = find.text('Desktop-PC');
        expect(title.evaluate(), isNotEmpty,
            reason: 'the first device row rendered no name at all');
        expect(
          tester.getRect(title.first).width,
          greaterThan(0),
          reason: 'the device name was allocated no width at ${wc.widthKey}px. '
              'The trailing must yield to the name, not the other way round '
              '(#1238). How much it gets is #1240\'s problem — that it gets any '
              'is this one\'s.',
        );
      });
    }

    testWidgets('@min ${narrowCases.first.widthKey}px the badge is dropped',
        (tester) async {
      await pumpAt(tester,
          widthCase: narrowCases.first, locale: const Locale('en'));

      // Dropped rather than ellipsized: a node name clipped to three characters
      // and a dash names nothing, and it would cost the name beside it.
      expect(find.text('MR7500').evaluate(), isEmpty,
          reason:
              'at ${narrowCases.first.widthKey}px the badge must be dropped '
              '(#1238)');
    });
  });

  group('a badge is dropped for being truncated, not for being short (#1238)',
      () {
    // The gate fixture has one badge, `MR7500` on a WiFi row, so it cannot see
    // the case that matters here: the trailing slot's cap is the row's *own*
    // demand, so a two-letter node name is granted only what it asked for at
    // every card width. Any fixed floor high enough to reject a squeezed
    // `Extender-1` also rejects `N1` on a 1440px screen — the badge has to be
    // measured against its own label, and the gate stays green either way because
    // a dropped badge overflows nothing.
    //
    // These two rows separate the two reasons a badge can be narrow, measured:
    //   - `N1` is narrow because the name is short — 30.1px natural, and its row
    //     is handed 32.6px at 191px, 288px and 512px alike (the wired row's
    //     `Wired` label is the wider of the two, and there is no signal indicator
    //     to raise the demand further), so the badge is always whole.
    //   - `Extender-1` is narrow only when squeezed — 78.3px natural, granted
    //     78.3px at 288px and 512px but only 22.0px at the min realization.
    final devices = [
      DevicesTestData.createSlaveConnectedClient(
          isWifi: false, parentNodeName: 'N1'),
      DevicesTestData.createWifiClient(parentNodeName: 'Extender-1'),
    ];

    for (final wc in [...narrowCases, desktopCase]) {
      testWidgets('@${wc.label} ${wc.widthKey}px a short name is kept',
          (tester) async {
        await pumpDevices(tester, widthCase: wc, devices: devices);

        expect(find.text('N1').evaluate(), isNotEmpty,
            reason:
                'the badge fits whole in the 30.1px its own label asks for, '
                'at every width. Rejecting it against anything but its own '
                'width loses the node name on a 1440px screen (#1238).');
      });
    }

    testWidgets('@desktop ${desktopCase.widthKey}px a long name is kept',
        (tester) async {
      await pumpDevices(tester, widthCase: desktopCase, devices: devices);

      expect(find.text('Extender-1').evaluate(), isNotEmpty);
    });

    testWidgets('@min ${narrowCases.first.widthKey}px a long name is dropped',
        (tester) async {
      await pumpDevices(tester, widthCase: narrowCases.first, devices: devices);

      expect(find.text('Extender-1').evaluate(), isEmpty,
          reason:
              'at 22.0px of slot the 78.3px badge could only ellipsize, and '
              '`Ex…` names nothing (#1238)');
    });
  });

  group('the widths between the realizations stay clean (#1238)', () {
    // The gate pumps the *narrowest* realization of each span and nothing else:
    // 191px (content 157.4) and 288px (content 254.0). A user dragging the card
    // reaches every width in between, and the trailing slot's cap grows linearly
    // through them — so a label threshold can sit in that gap, pass the gate at
    // both ends, and overflow in the middle. That is not hypothetical: the first
    // version of this fix used 175, derived from the tile's 25% content floor
    // alone, and overflowed +33.0px at content 175, +17.0px at 200 and +5.0px at
    // 216 while the gate stayed green at 1644 tests.
    //
    // The real cap is a lend-back of what the leading did not want —
    // `0.75 × (content − 64) − 44` — so seating the widest reading (`-100 dBm`,
    // 80.8px) needs 230.4px of content, hence 231. These widths bracket that:
    // three that must suppress the label and one just past it.
    //
    // The worst-case reading matters as much as the width. A 2-digit `-45 dBm` is
    // 75.0px and clears at content 223; the 3-digit one is 80.8px and does not
    // clear until 231. A fixture that only ever shows -45 would call 223 clean.
    final devices = [
      DevicesTestData.createWifiClient(
        hostName: 'iPhone-15',
        wifi: DevicesTestData.createWifiInfo(signalStrength: -100),
        parentNodeName: 'N1',
      ),
      DevicesTestData.createWifiClient(
        hostName: 'MacBook-Air-of-Someone',
        wifi: DevicesTestData.createWifiInfo(signalStrength: -100),
        parentNodeName: 'Extender-1',
      ),
      DevicesTestData.createWifiClient(
        hostName: 'Smart-Speaker',
        wifi: DevicesTestData.createWifiInfo(signalStrength: -100),
      ),
    ];

    // Card width, and the content width it produces (card − 34).
    for (final cardWidth in <double>[209, 234, 250, 264, 265]) {
      testWidgets(
          '@between ${cardWidth.toStringAsFixed(0)}px '
          '(content ${(cardWidth - 34).toStringAsFixed(0)}px) nothing overflows',
          (tester) async {
        final incidents = await pumpDevices(
          tester,
          widthCase: CardWidthCase(
            label: 'between',
            cardWidth: cardWidth,
            screenWidth: cardWidth + 40,
            columnSpan: spec.getConstraints(DisplayMode.normal).minColumns,
          ),
          devices: devices,
        );

        expect(
          incidents,
          isEmpty,
          reason:
              'at ${cardWidth.toStringAsFixed(0)}px the card gives its rows '
              '${(cardWidth - 34).toStringAsFixed(0)}px of content and the '
              'trailing slot only `0.75 × (content − 64) − 44` of that. '
              'Overflowing here means the `-NN dBm` label was kept at a width '
              'that cannot seat it — invisible to the gate, which never pumps '
              'this width (#1238). Got: '
              '${incidents.map((i) => '+${i.pixels.toStringAsFixed(1)}px ${i.side}').join(', ')}',
        );
      });
    }
  });

  group('wired rows keep their interface label (#1238)', () {
    // The compact path drops the dBm label and the badge; the wired/WiFi
    // fallback is the *only* thing a row without a signal reading has in its
    // trailing, so it is not part of that bargain. Ellipsized, never absent.
    for (final wc in [...narrowCases, desktopCase]) {
      testWidgets('@${wc.label} ${wc.widthKey}px Wired is labelled',
          (tester) async {
        await pumpAt(tester, widthCase: wc, locale: const Locale('en'));

        final wired = find.text('Wired');
        expect(wired.evaluate(), isNotEmpty,
            reason: 'a row with no signal reading has nothing else in its '
                'trailing, so the interface label must stay (#1238)');
        expect(tester.getRect(wired.first).width, greaterThan(0));
      });
    }
  });
}
