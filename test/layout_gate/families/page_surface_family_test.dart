@Tags(['layout-gate'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/components/customs/circular_countdown_widget.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/detail_widgets.dart';
import 'package:privacy_gui/page/devices/views/components/usp_device_filter_panel.dart';
import 'package:privacy_gui/page/devices/views/components/usp_device_list_tile.dart';
import 'package:privacy_gui/page/devices/views/components/usp_signal_strength_indicator.dart';
import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_active_leases_card.dart';
import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_reservations_detail_card.dart';
import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_server_info_card.dart';
import 'package:privacy_gui/page/instant_setup/views/components/pnp_isp_saving_progress.dart';
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
/// `page_surface_overflow_test.dart` is green when fifteen pages fit. It is *also*
/// green when fifteen pages never render: `PageSurfaceCase.requires` is what stands
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
  group('the gate sweeps fifteen pages, and which fifteen is a decision', () {
    test(
        'kPageSurfaceCases holds the pilot two, wave 1\'s five and wave 2\'s eight',
        () {
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
          'pnp_entry',
          'pnp_no_internet',
          'pnp_isp_settings',
          'pnp_pppoe',
          'pnp_static_ip',
          'pnp_unplug_modem',
          'pnp_modem_lights_off',
          'pnp_waiting_modem',
        ],
        // Updated by #1377 and #1378, and the wording is the point of the test.
        // This pin is the epic's per-wave checkpoint: it goes red on every wave
        // *by design*, so that the wave has to say here which pages it added and
        // on what grounds. Trimming the list to whatever `kPageSurfaceCases`
        // happens to hold is how the checkpoint stops existing.
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
        // **Wave 2's eight (#1378)**: the instant_setup flow, which is a different
        // kind of wave — nine views over one `pnpProvider`, where a fixture is a
        // *phase* rather than a payload. Six of the nine need one pinned, three need
        // nothing, and all six are served by one override builder over three
        // composed states. That corrects #1370's "2 of 9" in both directions: more
        // pages need a phase than it predicted, at a lower fixture cost.
        //
        // Eight, not nine: `pnp_setup` renders ui_kit's `AppStepper`, whose bar
        // variant overflows by `stepCount × 4` at every width in every locale
        // (`AppFocusIndicator` pads each bar unconditionally while
        // `_buildBarStepper` divides the raw width). The fix is in ui_kit, not
        // here, and the finding is pinned as a tripwire in
        // `test/page/instant_setup/views/pnp_setup_view_test.dart`. The one fixture
        // that would render this page clean is a single-step wizard — i.e. one with
        // no `AppStepper` in it — which is the fixture workaround #1378 forbids.
        // `pnp_complete_view` stays excluded as unreachable.
        //
        // The 30 that remain are in `test/fixtures/page_roster.tsv`, not here.
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
              'empty `requires` does not turn the sweep red; it turns 234 cells '
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
            'on this page in any of the 234 cells. Requiring it fails all 26 '
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

    // Wave 2's eight (#1378). Grouped rather than one pin per page, because what
    // is worth pinning about this wave is not eight separate widget lists — the
    // generic half already holds those non-empty — it is the two things a
    // state-machine flow gets wrong that a data-fed page cannot: a `forbids` that
    // names only `AppLoader` while the page's real waiting state is something
    // else, and a phase pinned on a page that never reads one.

    test('the three ISP-form pages forbid the overlay, not just the loader', () {
      // None of these three renders an `AppLoader` while saving. `PnpIspSettingsView`
      // and both forms hand the whole surface to `PnpIspSavingProgress` — a
      // full-page progress screen that lays out clean at every width, so a cell
      // showing it is green and measures nothing about the form underneath. Naming
      // only `AppLoader` in `forbids` would leave exactly that hole, and it is a
      // hole the fixture can fall into by accident: `_dhcpSaving`, `_pppoeSaving`
      // and `_staticSaving` are plain widget state, so any override that let a save
      // start would swap the surface out mid-sweep.
      for (final page in <PageSurfaceCase>[
        kPnpIspSettingsPageCase,
        kPnpPppoePageCase,
        kPnpStaticIpPageCase,
      ]) {
        expect(
          page.forbids,
          contains(PnpIspSavingProgress),
          reason: 'page.${page.id} would measure a progress screen as a clean '
              'page. `AppLoader` alone is not this flow\'s waiting state.',
        );
      }
    });

    test('page.pnp_waiting_modem forbids the stage it is not measuring', () {
      expect(
        kPnpWaitingModemPageCase.forbids,
        contains(CircularCountdownWidget),
        reason: 'three stages share this one view and the phase picks between '
            'them: `NoInternet` renders the plug-back-in instruction this case '
            'measures, `ModemRestartCountdown` renders a countdown ring and '
            '`ModemRestartCheckingInternet` a spinner. The other two are a ring '
            'and a spinner in a `Center` — clean at every width — so without this '
            'a phase drift would move the page to a different screen and report '
            '208 green cells for the one it was declared to cover.',
      );
    });

    test('the two ISP forms require the fields their fixture unlocks', () {
      expect(
        kPnpPppoePageCase.requires,
        containsAll(<Type>[AppTextField, AppPasswordInput]),
        reason: 'the username and password fields are the width-sensitive '
            'content, and the password one is the reason the pair is named '
            'rather than just `AppTextField`: `AppPasswordInput` carries a '
            'trailing reveal button inside the same row as the label, which is '
            'the narrower box of the two.',
      );
      expect(
        kPnpStaticIpPageCase.requires,
        contains(AppIpv4TextField),
        reason: 'five labelled IPv4 fields is this page at its widest, and the '
            'last two exist only because the fixture\'s `dnsServer1`/'
            '`dnsServer2` flip `_showDns`. A premise naming a plain '
            '`AppTextField` would hold against a form with the DNS rows '
            'collapsed, which is three fields and a narrower page.',
      );
    });

    test('five of wave 2\'s eight pin a phase and three deliberately do not',
        () {
      // The fixture story as a value. #1370 predicted 2 of the 9 instant_setup
      // pages would need a fixture; reading the views gives **6** — the five here
      // plus `pnp_setup`, which is queued on a ui_kit defect — all six served by
      // one override builder over three composed states. The three with an empty
      // list are empty because the view reads no provider on the path swept, not
      // because nobody wrote one, and that distinction is only checkable while it
      // is written down: an empty `overrides` that *should* have pinned a phase is
      // how a page silently renders a different screen than the one it names.
      final pinned = <String>[];
      final unpinned = <String>[];
      for (final page in <PageSurfaceCase>[
        kPnpEntryPageCase,
        kPnpNoInternetPageCase,
        kPnpIspSettingsPageCase,
        kPnpPppoePageCase,
        kPnpStaticIpPageCase,
        kPnpUnplugModemPageCase,
        kPnpModemLightsOffPageCase,
        kPnpWaitingModemPageCase,
      ]) {
        (page.overrides().isEmpty ? unpinned : pinned).add(page.id);
      }
      expect(
        unpinned,
        const ['pnp_isp_settings', 'pnp_unplug_modem', 'pnp_modem_lights_off'],
        reason: 'these three read no `pnpProvider` state on the path this sweep '
            'measures — the ISP hub watches it only while `_dhcpSaving`, and the '
            'two modem-restart steps are plain StatelessWidgets. Any *other* page '
            'appearing here is a phase that stopped being pinned, and the page it '
            'then renders is whatever `PnpState.initial()` selects: '
            '`AdminCheckingInternet`, which is a spinner on most of this flow.',
      );
      expect(pinned, hasLength(5));
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
      // Deliberately not one of the real cases: this is the tree a drifted
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
            'asserting and every real sweep is green over whatever renders.',
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
      // (`golden_runner.dart:43`) and §1.3 records it sweeping four.
      //
      // **Five since #1372 (2026-08-26).** `screen1080` arrived in golden CI on
      // 2026-08-24 (§5's note) and used to be named here as a ticketed gap rather
      // than asserted, because a test cannot pin a width the sweep does not visit.
      // The sweep visits it now, so it is asserted like the rest.
      expect(
        kPageSweepWidths,
        containsAll(<double>[320, 480, 1080, 1241, 1280]),
        reason: 'dropping any of these leaves "the gate found what golden CI '
            'missed" unfalsifiable at that width',
      );
    });

    test('the widest content box the list renders, and the band left over', () {
      // 1080's own pin, and the only one it has. It is not a step-up, so the two
      // tests above cannot hold it: `no step-up is missing` walks the widths where
      // the content box *narrows*, and 1080 is in the middle of a band where it
      // widens. Golden CI's `containsAll` does hold it today, but that couples a
      // coverage decision to another repo's screen set — if golden CI ever drops
      // 1080, the reason it is here would vanish with it.
      //
      // The reason it is here is stated as arithmetic instead: before #1372 the
      // widest content box any swept width granted was 1681's 977px, while the app
      // grants 1192px at 1240px and 1856px at 2560px. Every other width in the list
      // was chosen for a *narrow*-side reason, so a defect needing a wide box was
      // outside the sweep by construction.
      final widestSwept =
          kPageSweepWidths.map(_contentWidth).reduce((a, b) => a > b ? a : b);
      expect(
        widestSwept,
        1032.0,
        reason: 'This is 1080\'s content box, and it is the widest the sweep '
            'renders. If it fell back to 977 someone removed 1080 and reopened '
            'the wide-side band #1372 narrowed; if it rose, a wider width was '
            'added and the header table and the cell-count pins both need it.',
      );

      // The residual band, pinned so it stays a stated gap rather than a forgotten
      // one. #1372 narrowed it from 977→1856 to 1032→1856; it did not close it, and
      // no page has ever been swept at a content box above 1032px.
      expect(
        _contentWidth(1240),
        1192.0,
        reason: 'the widest content box below the 1241px pinch, and 160px wider '
            'than anything the sweep renders',
      );
      expect(
        _contentWidth(2560),
        1856.0,
        reason: 'ui_kit stops growing the margin at 1681px, so above it the '
            'content box grows without bound — the far end of the band the '
            'sweep still does not reach',
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
    // here is the arithmetic behind them: the suite says 234 once per page, and 234 is
    // 9 widths × 26 locales — so a locale added to the app fails the suite's pins
    // and this test says why.
    //
    // 208 until #1372 added 1080 on 2026-08-26. Fifteen literals moved with it, and
    // so did every row of the committed `page` baseline (3,120 → 3,510) — which is
    // the cost the ticket weighed and the reason it had to be decided before the
    // remaining waves capture anything.
    test('234 is 9 widths x 26 locales, for every page in the list', () {
      expect(
        kPageSweepWidths.length * AppLocalizations.supportedLocales.length,
        234,
        reason: 'every pin in page_surface_overflow_test.dart is this product '
            'spelled as a literal. If the app ships another locale, every '
            'pins move together — and that is a coverage change worth an '
            'explicit edit, which is why the pin is a literal in the first place.',
      );
      for (final page in kPageSurfaceCases) {
        expect(PageSurfaceFamily(page).enumerateCells(), hasLength(234));
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
