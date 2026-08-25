@Tags(['layout-gate'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/detail_widgets.dart';
import 'package:privacy_gui/page/devices/views/components/usp_device_filter_panel.dart';
import 'package:privacy_gui/page/devices/views/components/usp_device_list_tile.dart';
import 'package:privacy_gui/page/devices/views/components/usp_signal_strength_indicator.dart';
import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_active_leases_card.dart';
import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_reservations_detail_card.dart';
import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_server_info_card.dart';
import 'package:privacy_gui/page/port_forwarding/views/components/usp_single_port_tab.dart';
import 'package:privacy_gui/page/topology/views/components/backhaul_signal_indicator.dart';
import 'package:privacy_gui/page/wifi_settings/views/components/wifi_network_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../util/dashboard/dashboard_card_probe.dart'
    show kMinSupportedScreenWidth;
import '../sweep.dart';
import 'page_surface_cases.dart';
import 'page_surface_family.dart';

/// The content box ui_kit grants a page at [screen] — the quantity the sweep's
/// widths are chosen against.
///
/// Calls `AppLayoutConfig.margin` rather than restating the six margins, for the
/// reason `stats_section_probe.dart:41` gives: a copy of production's numbers is a
/// second source of truth that goes stale without failing.
double _contentWidth(double screen) =>
    screen - AppLayoutConfig.margin(screen) * 2;

/// The page family's oracle (#1349).
///
/// `layout-gate` and **not** `overflow`, like the three oracles before it
/// (`ratchet_test.dart`, `sweep_test.dart`, `dashboard_card_gate_test.dart`): the
/// `overflow` tag means "pumps cells and asserts zero overflow", and this file
/// asserts things *about* a sweep. The arithmetic in the skill doc — `--tags
/// overflow` measures exactly what naming the sweep files measures — is what would
/// break if this joined the pre-commit selector.
///
/// ## What this file is for, and why the sweep cannot do its job
///
/// `page_surface_overflow_test.dart` is green when seven pages fit. It is *also*
/// green when seven pages never render: `PageSurfaceCase.requires` is what stands
/// between those, and a list is deletable in silence. That is #1364/#1366 stated
/// once more — three separate premises were emptied and 102, 1,368 and 80 tests
/// respectively stayed green — with the difference that this family was written
/// after the lesson, so the premise is a value from the first line. A value is only
/// enforceable if something pins it, and nothing in the sweep can: the sweep reads
/// the lists, so a sweep assertion over them would be the lists agreeing with
/// themselves.
///
/// So the three things pinned here are the three the sweep structurally cannot:
///
/// 1. **Each case's premise, by name.** Emptying or shrinking `requires` fails
///    here, at the list, not later at a page nobody noticed had stopped rendering.
/// 2. **That the premise is an assertion rather than coverage** — the one test
///    that pumps. A loader is measured: zero overflow, and red anyway.
/// 3. **That `kPageSweepWidths` is what its doc claims** — every width at which
///    the content box narrows, computed from ui_kit rather than read from the
///    table in the family's header, which is prose and cannot fail.
void main() {
  group('the gate sweeps seven pages, and which seven is a decision', () {
    test('kPageSurfaceCases holds the pilot two plus the five of wave 1', () {
      expect(
        kPageSurfaceCases.map((c) => c.id),
        [
          'dhcp',
          'wifi_settings',
          'device_list',
          'device_detail',
          'topology',
          'node_detail',
          'port_forwarding',
        ],
        // Updated by #1377, and the wording is the point of the test. This pin is
        // the epic's per-wave checkpoint: it goes red on every wave *by design*, so
        // that the wave has to say here which pages it added and on what grounds.
        // Trimming the list to whatever `kPageSurfaceCases` happens to hold is how
        // the checkpoint stops existing.
        //
        // **The pilot's two (#1349)**: a plain form page and a provider-heavy one,
        // bracketing the cost range §1.2 records.
        //
        // **Wave 1's five (#1377)**: every page whose `List<Override>` builder
        // already existed, so the wave's fixture cost is zero and what it buys is
        // the wave *process* at the lowest price the epic can pay. Six were
        // candidates; `usp_statistics_view` has a builder that does not get the
        // view past its loader, so it is re-queued into #1380 with a fixture scope
        // — which is `requires` making exactly the distinction it exists for.
        //
        // §8's graduation rule is paid, not repealed: four of the five were already
        // at zero, and `port_forwarding` was fixed in the widget
        // (`usp_single_port_tab.dart:30`, 9 cells, worst +70px) *before* it was
        // added here. No page in this list arrives carrying debt, and
        // `known_overflows.json` is still `{"tracking": {}, "allowlist": {}}`.
        //
        // The 38 that remain are in `test/fixtures/page_roster.tsv`, not here.
        reason: 'a wave adds pages to this list on purpose, so a mismatch is '
            'either a wave that has not updated its own checkpoint or a page '
            'that left the gate without one. Read the comment above before '
            'editing the expectation: the rule is fix to zero, then declare, '
            'then capture — never declare then allowlist.',
      );
    });

    test('every case has a distinct id, since the id is the sweep name', () {
      expect(
        kPageSurfaceCases.map((c) => c.id).toSet(),
        hasLength(kPageSurfaceCases.length),
        reason: 'the id becomes `page.<id>`, which namespaces the coverage '
            'baseline. Two cases sharing one would collide every cell of both.',
      );
    });
  });

  group('each case carries its premise as a value', () {
    // The generic half: whatever the cases are, none of them may be premise-free.
    // Written over the list rather than per case so a case added without a premise
    // fails here instead of sweeping 208 green cells over a spinner.
    for (final page in kPageSurfaceCases) {
      test('page.${page.id} requires at least one widget of the loaded page',
          () {
        expect(
          page.requires,
          isNotEmpty,
          reason: 'a page opens with `if (isLoading) return AppLoader()`, or — '
              'worse for this gate — with a `SizedBox.shrink()` or a not-found '
              'column. Every one of those fits at any width in any locale, so an '
              'empty `requires` does not turn the sweep red; it turns 208 cells '
              'green over nothing.',
        );
      });

      test('page.${page.id} forbids the loading path outright', () {
        expect(
          page.forbids,
          contains(AppLoader),
          reason: '`requires` already excludes a loader by implication; naming '
              'it here is what makes the failure say "this page is still '
              'loading" rather than "a card is missing".',
        );
      });
    }

    // The specific half: the lists themselves, by name. This is the assertion that
    // fails when a `requires` is quietly narrowed to one cheap widget — which is
    // the shape #1366 found, where the premise was still present and no longer
    // said anything.
    test('page.dhcp requires all three of its cards, not just the first', () {
      expect(
        kDhcpPageCase.requires,
        containsAll(<Type>[
          UspDhcpServerInfoCard,
          UspDhcpActiveLeasesCard,
          UspDhcpReservationsDetailCard,
        ]),
        reason: 'the three cards are three independent presentations fed by '
            'three different providers. Requiring only one leaves the other two '
            'free to fall back to a spinner while this sweep reports a clean '
            'page — and the reservations card is the one #1349 found overflowing '
            'at 320px and 601px, so dropping it drops the regression test for '
            'the fix that shipped with this sweep.',
      );
    });

    test('page.wifi_settings requires the card its widths actually stress', () {
      expect(
        kWifiSettingsPageCase.requires,
        contains(WifiNetworkCard),
        reason: 'quick-setup-off renders four of these, one per band, and they '
            'are the page content that responds to width. A premise naming only '
            'the page shell would hold against a shell with no cards in it.',
      );
    });

    // Wave 1's five (#1377). One pin per page, each naming the thing that would
    // otherwise be free to disappear — not a restatement of the list, which the
    // generic half above already covers.

    test('page.device_list requires both of its providers to have arrived', () {
      expect(
        kDeviceListPageCase.requires,
        containsAll(<Type>[UspDeviceListTile, UspDeviceStatusSegmented]),
        reason: 'the tile comes from `filteredDeviceListProvider` and the '
            'segmented filter from `deviceFilterOptionsProvider`. Requiring only '
            'the tile leaves the filter row free to vanish while the list still '
            'renders, which is a page measured at the wrong height in all 208 '
            'cells.',
      );
      expect(
        kDeviceListPageCase.requires,
        isNot(contains(UspDeviceFilterPanel)),
        reason: 'the panel is the desktop half of an `AppResponsiveLayout` and '
            '`UspDeviceFilterChipBar` is the mobile half, so neither can hold at '
            'all eight widths. A `requires` entry that is width-conditional turns '
            'the premise into a second, hidden width list — the failure would say '
            '"this page did not render" about a page that rendered correctly.',
      );
    });

    test('page.device_detail requires the two-card geometry #1302 needed', () {
      expect(
        kDeviceDetailPageCase.requires,
        containsAll(<Type>[UspSignalStrengthIndicator, DetailSpeedCard]),
        reason:
            'this page is the one place the gate reproduces #1302: a fixture '
            'with both an uplink and a downlink rate renders two speed cards at '
            'half width each, and a single-rate fixture renders one full-width '
            'card that cannot overflow. Dropping `DetailSpeedCard` from the '
            'premise is how that regression becomes invisible again — and this '
            'view has no `AppLoader` at all, so `forbids` cannot catch it.',
      );
    });

    test('page.topology requires the tree, not the page that would hold it',
        () {
      expect(
        kTopologyPageCase.requires,
        contains(AppTopology),
        reason: '`usp_topology_view.dart` returns `SizedBox.shrink()` when '
            '`systemInfoDataProvider` has no model — a zero-sized tree, which is '
            'greener than a loader and reports as clean at every width. Requiring '
            'the topology widget is what makes a dropped override fail instead of '
            'sweeping 208 empty cells.',
      );
    });

    test('page.node_detail requires one widget per card its fixture unlocks',
        () {
      expect(
        kNodeDetailPageCase.requires,
        containsAll(<Type>[BackhaulSignalIndicator, UspDeviceListTile]),
        reason: 'the backhaul card exists only for a slave node with a signal '
            'strength, and the connected-devices card only with clients. Two '
            'cards, two chances to notice the fixture went thin.',
      );
      expect(
        kNodeDetailPageCase.requires,
        isNot(contains(DetailSpeedCard)),
        reason: 'not an omission — the throughput row is gated on '
            '`uplinkRate != null || downlinkRate != null` '
            '(`usp_node_detail_view.dart:400`), and no existing '
            '`UspNodeDetailState` carries either rate, so no speed card renders '
            'on this page in any of the 208 cells. Requiring it fails all 26 '
            'locales of the first width, which is how #1377 found the assumption. '
            'Adding it back needs a fixture with rates first — that is a later '
            'wave\'s scope, and this pin is where the gap is recorded.',
      );
    });

    test('page.port_forwarding requires the tab it can actually reach', () {
      expect(
        kPortForwardingPageCase.requires,
        contains(UspSinglePortTab),
        reason: 'tab 0 is the only tab the sweep measures — the other two are '
            'behind a `TabController` and would each need a tap per cell. So this '
            'is both the premise and the surface under measurement, and it is on '
            'the loaded path only: `_buildTabContent` returns an `AppLoader` '
            'while loading and a `ServiceErrorView` on error.',
      );
    });
  });

  group('the premise is an assertion, not coverage', () {
    // One cell, pumped. The distinction cf91cddc named — a hook that opens the
    // surface runs without ever being able to fail — is only observable by
    // measuring a cell that *should* fail, so this is the one test here that pays
    // for a pump. It costs a `settleIgnoringAnimations` timeout, because a loader
    // animates forever and that is the point of it.
    testWidgets('a page that never left its loader is measured, and fails',
        (tester) async {
      // Deliberately not one of the seven real cases: this is the tree a drifted
      // fixture produces, and it has to be constructible without a drifted
      // fixture. `requires` is dhcp's, so the failure names a real card.
      final stuckOnLoader = PageSurfaceCase(
        id: 'loader_only',
        view: () => const Center(child: AppLoader()),
        overrides: () => const [],
        requires: kDhcpPageCase.requires,
        forbids: kDhcpPageCase.forbids,
      );
      final family = PageSurfaceFamily(stuckOnLoader);
      final cell = family.enumerateCells().first;

      final verdict = await measureOverflowCell(
        tester,
        family: family,
        cell: cell,
      );

      // Both halves matter, and the first is why the second is needed at all.
      expect(
        verdict.significant,
        isEmpty,
        reason:
            'a loader fits at 320px in every locale — which is exactly why a '
            'sweep that only asked "did a RenderFlex overflow" would call this '
            'cell clean and move on',
      );
      expect(
        verdict.error,
        isNotNull,
        reason:
            'the premise is what turns a clean-but-meaningless cell red. If '
            'this passes with a null error, `onCellSettled` has stopped '
            'asserting and all seven real sweeps are green over whatever renders.',
      );
      expect(
        verdict.error.toString(),
        contains('other than the loaded page'),
        reason: 'the failure has to say what went wrong with the fixture, not '
            'just that something did',
      );
    });

    testWidgets('a page that did render its premise is clean', (tester) async {
      // The control. Without it, the test above is satisfied by an `onCellSettled`
      // that throws unconditionally — which would fail every real cell, but only
      // after someone ran the real sweeps.
      final rendersItsPremise = PageSurfaceCase(
        id: 'premise_met',
        view: () => const Placeholder(),
        overrides: () => const [],
        requires: const [Placeholder],
        forbids: const [AppLoader],
      );
      final family = PageSurfaceFamily(rendersItsPremise);

      final verdict = await measureOverflowCell(
        tester,
        family: family,
        cell: family.enumerateCells().first,
      );

      expect(verdict.error, isNull, reason: verdict.summary);
      expect(verdict.significant, isEmpty);
    });
  });

  group('kPageSweepWidths is derived from ui_kit, not sampled', () {
    test('content narrows at every width the sweep calls a step-up', () {
      for (final width in const [601.0, 1241.0, 1441.0, 1681.0]) {
        expect(
          _contentWidth(width),
          lessThan(_contentWidth(width - 1)),
          reason: '$width is in the sweep because the page gets a *narrower* '
              'content box there than one pixel earlier. If ui_kit\'s margins '
              'changed, this width no longer means what the family\'s header '
              'table says and the list has to be re-derived.',
        );
        expect(kPageSweepWidths, contains(width));
      }
    });

    test('no step-up is missing from the list', () {
      // Enumerated, not sampled — #1225's lesson applied to a different axis. A
      // width list that missed a step-up would be a sweep whose worst case is
      // outside it, and no test of the widths it *does* hold could say so.
      final missed = <double>[];
      for (var width = kMinSupportedScreenWidth + 1; width <= 2560; width++) {
        final narrows = _contentWidth(width) < _contentWidth(width - 1);
        if (narrows && !kPageSweepWidths.contains(width)) missed.add(width);
      }
      expect(
        missed,
        isEmpty,
        reason: 'ui_kit narrows the content box at these widths and the sweep '
            'does not visit them, so each is a pinch the gate cannot see. Add '
            'them to kPageSweepWidths and re-pin both cell counts (each width '
            'is 26 cells per page).',
      );
    });

    test('every width golden CI is recorded sweeping is in the list', () {
      // §8's join key is `file:line`, but the join is only *checkable* where both
      // sides measured the same screen, so every coordinate golden CI visits has
      // to be here or the overlap is smaller than §8 claims.
      //
      // **Four, not two (#1370).** This test read "the two coordinates golden CI
      // shares", which conflated two different sets: `GoldenDevice.defaults` is
      // two (`phone480`, `desktop1280`, `golden_test_config.dart:33`), but golden
      // CI synthesises a device per `--dart-define=screens=<width>`
      // (`golden_runner.dart:43`) and §1.3 records it sweeping four. All four are
      // asserted here.
      //
      // `screen1080` arrived on 2026-08-24 (§5's note) and is **not** in the list;
      // it is the one real gap in §8's comparability and it is #1372's input, so it
      // is named here rather than asserted — a test cannot pin a width the sweep
      // does not visit without going red on a known, ticketed gap.
      expect(
        kPageSweepWidths,
        containsAll(<double>[320, 480, 1241, 1280]),
        reason: 'dropping any of these leaves "the gate found what golden CI '
            'missed" unfalsifiable at that width',
      );
    });

    test('the product floor is the floor the card sweep enumerates from', () {
      expect(
        kPageSweepWidths.first,
        kMinSupportedScreenWidth,
        reason: '320px is a product commitment (density design §2.3), not a '
            'number this family chose. Reading it from the card probe is what '
            'keeps the two sweeps agreeing about where the product ends.',
      );
    });
  });

  group('each page pins its own cell count', () {
    // The pins live in the suite, as `runOverflowSweep` requires. What is checkable
    // here is the arithmetic behind them: the suite says 208 seven times, and 208 is
    // 8 widths × 26 locales — so a locale added to the app fails the suite's pins
    // and this test says why.
    test('208 is 8 widths x 26 locales, for every page in the list', () {
      expect(
        kPageSweepWidths.length * AppLocalizations.supportedLocales.length,
        208,
        reason: 'every pin in page_surface_overflow_test.dart is this product '
            'spelled as a literal. If the app ships another locale, all seven '
            'pins move together — and that is a coverage change worth an '
            'explicit edit, which is why the pin is a literal in the first place.',
      );
      for (final page in kPageSurfaceCases) {
        expect(PageSurfaceFamily(page).enumerateCells(), hasLength(208));
      }
    });

    test('every cell measures the width its axis names', () {
      // The axis value is a string in the cell id and a double in the surface;
      // they are written from the same loop variable today, and a cell whose id
      // disagreed with its viewport would file every finding under the wrong
      // coordinate.
      for (final page in kPageSurfaceCases) {
        final family = PageSurfaceFamily(page);
        for (final cell in family.enumerateCells()) {
          expect(
            cell.axes['screen_px'],
            cell.surfaceSize.width.toStringAsFixed(0),
            reason: '${overflowSweepCellId(family, cell)} was laid out at '
                '${cell.surfaceSize.width}px',
          );
          expect(cell.surfaceSize.height, kPageSweepHeight);
        }
      }
    });
  });
}
