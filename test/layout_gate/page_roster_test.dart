@Tags(['layout-gate'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'families/page_surface_cases.dart';
import 'page_roster.dart';

/// The roster's oracle (#1382).
///
/// `layout-gate` and **not** `overflow`, like the four oracles before it
/// (`ratchet_test.dart`, `sweep_test.dart`, `dashboard_card_gate_test.dart`,
/// `page_surface_family_test.dart`): the `overflow` tag means "pumps cells and
/// asserts zero overflow", and this file pumps nothing at all — it is one
/// directory walk and one file parse.
///
/// **That is also why #1371 could not move it.** That ticket kept the page
/// family's cells in one file (architecture doc §11.10), but the reasoning never
/// depended on the outcome: an oracle that runs on a schedule cannot stop a page
/// added this afternoon from escaping this afternoon. The tag stays `layout-gate`
/// and the file stays inside `./run_tests.sh`, which excludes `golden||loc||ui`
/// and therefore includes this — and the same holds for #1371's own register,
/// `page_sweep_suites_test.dart`, which guards the other half of the same risk.
///
/// ## The three assertions, and what each one alone would let through
///
/// 1. **Every page view has a roster row.** Without it, a page view added to the
///    app appears nowhere and "not yet onboarded" reads exactly like "does not
///    exist". The discovered count is pinned at [kPageViewCount] on top of the
///    set comparison, because the rule has three plausible spellings that give
///    44, 45 and 49 — so a change to the walk that narrowed the roster's
///    obligation would otherwise satisfy the set comparison trivially.
/// 2. **Every roster row names a file that exists.** Without it, a deleted or
///    renamed view leaves a row claiming coverage of nothing — and a `swept` row
///    claiming coverage of nothing still counts toward "45 of 45".
/// 3. **`swept` ⟺ declared in `kPageSurfaceCases`, both directions.** Without it
///    the roster is decorative: a row marked `swept` while no case declares it is
///    a record claiming more than the gate covers, which is the precise failure
///    the epic's final AC guards against at 45 of 45 — made checkable here at 2,
///    and first exercised for real by #1377's wave 1, which flipped five rows and
///    had to declare five cases to keep this green. #1378's wave 2 flipped eight
///    more, and was the first wave to leave a page **measured but queued**: a
///    fixture that renders `pnp_setup` existed, and a ui_kit defect was what kept it
///    out. That lasted a day — ui_kit v2.40.2 fixed it and the ninth row flipped —
///    so what the state proved is that the register can hold the distinction, not
///    that it had to hold it for long.
///
/// ## Red before green, permanently
///
/// This repo has been burned twice by a guard nobody watched fail: `flutter test
/// --tags dashboard-card` returned "No tests ran" after #1336 renamed the tag — a
/// pass-shaped result for an unrun gate — and a drifted fixture renders
/// `AppLoader()`, which cannot overflow at any width in any locale, so 208 cells
/// went green over a spinner (#1364/#1366).
///
/// So each assertion was watched red against the committed fixture, one at a time,
/// by hand (the PR records it). The hand check proves the wiring once; the
/// `each assertion can fail` group below is what keeps proving it, by driving the
/// same three checks over synthetic rosters that are wrong in exactly one way. A
/// hand check that happened last August is not a guard.
///
/// **Re-confirmed at #1379's close** — the wave's last AC, because this oracle is the
/// only thing standing between "45 of 45" and a number nobody re-checks. Deleting
/// `auto_parent_first_login_view.dart`'s row from the committed fixture and *also*
/// correcting `# pages`, `# swept` and `# measured` to match — the shape a deletion
/// takes when someone tidies the header after it, and the only shape that gets past
/// `_rejectStaleHeader` — turned **7** tests red, assertion 1's set comparison first:
///
/// ```
/// assertion 1 ... no discovered page view is absent from the roster [E]
///   Expected: empty
///     Actual: ['lib/page/login/auto_parent/views/auto_parent_first_login_view.dart']
/// ```
///
/// Assertion 3 caught it from the other side (a declared case with no swept row), and
/// the `kPageViewCount` pin caught the narrowed denominator. Leaving the header at 45
/// is caught one layer earlier still, in `setUpAll` — `declares '# pages 45' and holds
/// 44 rows` — which is why both spellings were run. The fixture was restored and
/// checksummed identical afterwards.
void main() {
  // Read in `setUpAll` and not at declaration time, deliberately. A malformed
  // roster throws, and a throw out here fails the suite to *load* — "Failed to
  // load page_roster_test.dart: PageRosterFormatException" against no test name,
  // which is a shape this gate has twice found unreadable. From `setUpAll` the
  // same exception is attributed to every test below with its message intact.
  late final List<String> discovered;
  late final PageRoster roster;

  /// Sweep name → the widget type that sweep pumps. The type is what a case
  /// unambiguously determines; its `id` is a sweep group name and not a file
  /// (`instant_setup` alone holds ten views).
  late final Map<String, String> typeBySweep;

  /// ...and where each of those types is declared. Resolved from the source rather
  /// than snake-cased from the type name, because one page already breaks that
  /// convention — see `the swept-case join is resolved from the source` below.
  late final Map<String, List<String>> declaringPaths;
  late final Set<String> declaredPaths;

  setUpAll(() {
    discovered = discoverPageViews();
    roster = PageRoster.fromFixture();
    typeBySweep = {
      for (final page in kPageSurfaceCases)
        page.sweepName: page.view().runtimeType.toString(),
    };
    declaringPaths = pageViewPathsDeclaring(typeBySweep.values, discovered);
    declaredPaths = declaringPaths.values.expand((p) => p).toSet();
  });

  group('assertion 1: every page view has a roster row', () {
    test('the rule finds exactly $kPageViewCount page views', () {
      expect(
        discovered,
        hasLength(kPageViewCount),
        reason: 'the count is pinned because the rule has three spellings and '
            'they disagree: `lib/page/*/views/*_view.dart` finds 44 (it misses '
            '`lib/page/login/auto_parent/views/auto_parent_first_login_view.dart`), '
            'a file directly inside a `views/` dir at any depth finds 45, and '
            '`find -path \'*/views/*_view.dart\'` finds 49 because `*` crosses '
            '`/` there. If this moved because the app gained a page, add its row '
            'and move kPageViewCount. If it moved because discoverPageViews '
            'changed, say why here — a wider rule would demand rows for the four '
            'composed widgets in unified_diagnostics/views/widgets/ and make '
            '"45 of 45" unreachable; a narrower one would let a page escape.',
      );
    });

    test('the four composed widgets one level deeper are not page views', () {
      // The concrete false positives, named. A rule that admitted these would
      // claim 49 pages exist; none of the four classes appears anywhere under
      // `lib/route/`, so none of them is a page.
      for (final widget in const [
        'diagnostic_start_view',
        'diagnostic_running_view',
        'diagnostic_results_view',
        'diagnostic_manual_tools_view',
      ]) {
        final path = 'lib/page/unified_diagnostics/views/widgets/$widget.dart';
        expect(File(path).existsSync(), isTrue,
            reason: '$path was the point of this test; if it moved, re-derive '
                'the false-positive list rather than deleting the test');
        expect(isPageViewPath(path), isFalse);
        expect(discovered, isNot(contains(path)));
      }
    });

    test('the 45th page — the one a one-level glob misses — is discovered', () {
      expect(
        discovered,
        contains(
          'lib/page/login/auto_parent/views/auto_parent_first_login_view.dart',
        ),
        reason: 'this is the file that makes the difference between 44 and 45, '
            'and it sits two levels under lib/page/ rather than one. It is also '
            'exactly the kind of page a coverage record forgets.',
      );
    });

    test('no discovered page view is absent from the roster', () {
      expect(
        roster.unrecordedPages(discovered),
        isEmpty,
        reason: 'a page view the roster has never heard of is a page that can '
            'never be reported as queued, swept or excluded — it simply is not '
            'in the epic. Add a row with disposition `queued` and `-` for '
            'ms/cell, and move the `# pages` header.',
      );
    });

    test('the roster holds one row per discovered page view and no others', () {
      // The reverse direction. A row for something the rule does not find would
      // inflate the denominator of "45 of 45" without anything ever sweeping it.
      expect(roster.undiscoveredRows(discovered), isEmpty);
      expect(roster.rows, hasLength(kPageViewCount));
      expect(roster.paths, discovered.toSet());
    });
  });

  group('assertion 2: every roster row names a file that exists', () {
    test('no row claims coverage of a file that is not on disk', () {
      expect(
        roster.phantomRows(),
        isEmpty,
        reason: 'a deleted or renamed view leaves a row claiming coverage of '
            'nothing — and a `swept` row claiming coverage of nothing still '
            'counts toward "45 of 45". If a page was deleted, delete its row and '
            'move both the `# pages` header and kPageViewCount; if it was '
            'renamed, rename the row.',
      );
    });
  });

  group('assertion 3: swept <-> declared in kPageSurfaceCases, both ways', () {
    test('every case resolves to exactly one page view file', () {
      // Checked before the two directions below, because a type that resolved to
      // nothing would make both of them pass vacuously — the empty set is a
      // subset of everything. This is the assertion that makes the join a join.
      for (final entry in typeBySweep.entries) {
        expect(
          declaringPaths[entry.value],
          hasLength(1),
          reason: '${entry.key} pumps a ${entry.value}, and exactly one page '
              'view file must declare that class. Zero means the case pumps a '
              'widget that is not a page view under this roster\'s rule — and '
              'an unresolved type turns both directions below into vacuous '
              'subset checks. Two means the join is a coin flip.',
        );
      }
    });

    test('every swept row is declared by a case', () {
      expect(
        roster.sweptPaths.difference(declaredPaths),
        isEmpty,
        reason: 'a row marked `swept` while no case declares its view is a '
            'record claiming more than the gate covers. This is the assertion '
            'that stops the roster becoming decorative: without it, 45 rows '
            'could read swept while seven pages are measured. Declared today: '
            '${typeBySweep.keys.join(', ')}.',
      );
    });

    test('every case has a swept row', () {
      expect(
        declaredPaths.difference(roster.sweptPaths),
        isEmpty,
        reason: 'the other direction, and the one a wave gets wrong: a page '
            'onboarded into kPageSurfaceCases without its roster row moving from '
            '`queued` to `swept` is progress the record does not show, so the '
            'epic under-reports itself and the next wave re-does the work. '
            'Move the row and give it the ms/cell the run measured.',
      );
    });
  });

  group('the swept-case join is resolved from the source, not from a name', () {
    test('one page already breaks the file-name-matches-class convention', () {
      // The concrete reason `pageViewPathsDeclaring` reads sources instead of
      // snake-casing the type name. If this page is ever renamed the join does
      // not care — but the argument in that function's doc would need a new
      // example, and a reader who found none would be entitled to simplify it
      // back into the bug.
      const path = 'lib/page/instant_safety/views/instant_safety_view.dart';
      expect(discovered, contains(path));
      expect(
        File(path).readAsStringSync(),
        contains('class UspInstantSafetyView'),
        reason: 'the file is instant_safety_view.dart and the class is '
            'UspInstantSafetyView, so a name-derived join would look for '
            'usp_instant_safety_view.dart',
      );
      expect(
        discovered,
        isNot(contains(
            'lib/page/instant_safety/views/usp_instant_safety_view.dart')),
        reason:
            'the file a name-derived join would look for does not exist, so '
            'that join resolves this page to nothing — and nothing is a subset '
            'of everything, which is how the assertion would have passed',
      );
      expect(
        pageViewPathsDeclaring(const ['UspInstantSafetyView'], discovered),
        {
          'UspInstantSafetyView': [path]
        },
        reason: 'the source-resolved join finds it anyway',
      );
    });

    test('a state class is not mistaken for its view', () {
      // `\b` in the pattern, asserted: `UspDhcpDetailView` must not match
      // `_UspDhcpDetailViewState` or any other prefix-sharing declaration.
      final resolved =
          pageViewPathsDeclaring(const ['UspDhcpDetailVie'], discovered);
      expect(
        resolved['UspDhcpDetailVie'],
        isEmpty,
        reason: 'a prefix must not resolve, or a case pumping one widget could '
            'be joined to the file of another',
      );
    });

    test('a class named only in a comment is not a declaration', () {
      // The pattern is anchored at the line start. `page_surface_cases.dart`
      // references [UspDhcpDetailView] in prose; a page view file could equally
      // mention another page's class in its own header.
      final resolved =
          pageViewPathsDeclaring(const ['PageSurfaceCase'], discovered);
      expect(resolved['PageSurfaceCase'], isEmpty);
    });
  });

  group('the record is honest about what was measured', () {
    test('every swept row carries the figure its own ticket measured', () {
      // Not 37.7ms. That is the mean of the pilot's two over one combined run, and
      // section 11.2's second finding is that the bracket *inverted* — the page
      // picked as the cheap end costs 1.5x the one picked as expensive — so the
      // mean describes neither page and predicts no third one. Wave 1's five bear
      // that out: they span 21.6 to 44.0 and four of the five come in under the
      // mean.
      // Keyed on the full path, not the file name: nothing stops two features
      // from each having a `views/x_view.dart`, and a map keyed on the name would
      // silently collapse them and check whichever row came last.
      final byPath = {for (final r in roster.rows) r.path: r};
      expect(
        byPath['lib/page/dhcp/views/usp_dhcp_detail_view.dart']!.msPerCell,
        44.8,
      );
      expect(
        byPath['lib/page/wifi_settings/views/usp_wifi_settings_view.dart']!
            .msPerCell,
        29.2,
      );

      // Wave 1's five, re-measured by #1377 on this file's own basis rather than
      // copied from #1370 — the memory rule is that a ticket's counts expire, so
      // the figure committed here is the one this ticket observed. #1370's numbers
      // are in the comment so the drift stays readable: 49.5 / 33.7 / 28.7 / 33.5
      // / 22.5, against which four of five landed inside the ±7% noise floor and
      // `device_list` came in 11% *cheaper*. Cheaper is not a scope risk, and
      // #1370's finding that there is no cost ceiling stands either way.
      expect(
          byPath['lib/page/devices/views/usp_device_list_view.dart']!.msPerCell,
          44.0); // #1370: 49.5, -11.1%
      expect(
          byPath['lib/page/devices/views/usp_device_detail_view.dart']!
              .msPerCell,
          33.4); // #1370: 33.7, -0.9%
      expect(
          byPath['lib/page/topology/views/usp_topology_view.dart']!.msPerCell,
          28.0); // #1370: 28.7, -2.4%
      expect(
          byPath['lib/page/topology/views/usp_node_detail_view.dart']!
              .msPerCell,
          31.6); // #1370: 33.5, -5.7%
      expect(
          byPath['lib/page/port_forwarding/views/usp_port_forwarding_detail_view.dart']!
              .msPerCell,
          21.6); // #1370: 22.5, -4.0%

      // Wave 2's eight (#1378), on the same basis and with one addition to it:
      // three runs, median committed. Four passes over `pnp_entry` read 21.2, 18.5,
      // 11.6 and 10.9 — the first coordinate test of a run absorbs the font load and
      // the first pump, and on a page whose 208 cells cost ~2.4s that fixed cost is
      // most of the total. So the figures below are medians and the drift against
      // #1370 is *not* readable as a ±7% agreement the way wave 1's was: only
      // `pnp_modem_lights_off` landed inside that floor.
      //
      // The finding, recorded here and in the fixture's `# basis-note` block: below
      // ~20ms/cell the two bases disagree by more than they agree, so #1369 should
      // plan against these medians and treat any queued figure under ~20ms/cell as
      // ±40%. `pnp_static_ip` is the one drift with a *cause* rather than a noise
      // band — this wave's fixture expands the DNS rows, so five IPv4 fields render
      // where #1370's default state rendered three, and +63% is the fixture being
      // wider rather than the harness being noisy.
      const pnp = 'lib/page/instant_setup/views';
      expect(byPath['$pnp/pnp_entry_view.dart']!.msPerCell,
          11.6); // #1370: 38.6, -70.0%
      expect(byPath['$pnp/pnp_no_internet_view.dart']!.msPerCell,
          14.7); // #1370: 12.5, +17.6%
      expect(byPath['$pnp/pnp_isp_settings_view.dart']!.msPerCell,
          12.7); // #1370: 13.7, -7.3%
      expect(byPath['$pnp/pnp_pppoe_view.dart']!.msPerCell,
          20.8); // #1370: 16.3, +27.6%
      expect(byPath['$pnp/pnp_static_ip_view.dart']!.msPerCell,
          59.6); // #1370: 36.5, +63.3% — the DNS rows, not noise
      expect(byPath['$pnp/pnp_unplug_modem_view.dart']!.msPerCell,
          13.5); // #1370: 18.1, -25.4%
      expect(byPath['$pnp/pnp_modem_lights_off_view.dart']!.msPerCell,
          12.9); // #1370: 13.2, -2.3% — the only one inside the floor
      expect(byPath['$pnp/pnp_waiting_modem_view.dart']!.msPerCell,
          11.7); // #1370 had no fixture for it, so this is the first measurement

      // The ninth, and the row this register carried as measured-but-queued for a
      // day. Its figure was never fixture debt — #1378 pumped all 208 cells through
      // `pnpWizardConfiguringState`; what it could not do was pass them, because
      // ui_kit v2.40.1's `AppStepper` bar variant overflowed by `stepCount × 4` at
      // every width in every locale and all 208 failed at +12.0px on this page's
      // 3-step wizard. §8's graduation rule kept it out until the fix landed
      // (`linksys/privacyGUI-UI-kit#70` → `936c1da6` → v2.40.2), and the figure is
      // #1378's own measurement, unchanged by the bump: what moved is the verdict on
      // those cells, not their cost.
      expect(byPath['$pnp/pnp_setup_view.dart']!.msPerCell, 34.3);
      expect(
        byPath['$pnp/pnp_setup_view.dart']!.disposition,
        PageRosterDisposition.swept,
        reason:
            'this row read `queued` for one day. If it reads `queued` again, a '
            'page left the gate — which is a deletion from kPageSurfaceCases that '
            'assertion 3 below would also catch, and one nobody should be able to '
            'make quietly.',
      );
    });

    test('every swept row carries a number and no excluded row does', () {
      // #1382 shipped this as "nothing but a swept row carries a number", which
      // was true of a register in which nothing had been measured. #1370 then
      // measured 25 queued pages on §11.2's own basis, so the invariant is not
      // "only swept rows have costs" — it is that **a figure here was measured**.
      // The parser holds the two ends it can hold, and this asserts them over the
      // committed file.
      //
      // Yes, the parser already rejects both, so this cannot fail against a roster
      // that parsed — and it is kept anyway, because the mutation it guards is the
      // one #1370 just performed: **narrowing the parser rule**. Half of what this
      // asserted stopped being enforced upstream this ticket, and an assertion over
      // the committed file is what would have noticed if the wrong half had gone.
      // The falsifiable versions are the synthetic rosters below.
      for (final row in roster.rows) {
        switch (row.disposition) {
          case PageRosterDisposition.swept:
            expect(row.msPerCell, isNotNull, reason: row.path);
          case PageRosterDisposition.excluded:
            expect(row.msPerCell, isNull, reason: row.path);
          case PageRosterDisposition.queued:
            break; // measured or not; the next test but one pins which.
        }
      }
    });

    test('the queued column is empty: 0 measured-and-waiting, 0 fixture debt',
        () {
      // The distinction #1370 bought, and the one every wave estimated against —
      // recorded here at the end because the two counts reaching zero together is
      // the epic's actual finish line, and because the *path* they took is the
      // reusable part.
      //
      // The epic inferred "37 of 44 need a fixture written" from which builders
      // exist in test/mocks/provider_overrides/; #1370's run found the shared mock
      // alone carries 21 unfixtured pages past their loader, so the measured
      // fixture debt was **16**, not 37 — and one of those 16 was a page whose
      // builder *does* exist.
      //
      // The two counts then moved independently, which is the whole reason they are
      // two counts. `measured` (queued pages some fixture already gets past their
      // loader) went 25 -> 20 -> 14 -> 13 -> 8 -> 0; `needsFixture` went
      // 16 -> 16 -> 14 -> 14 -> 13 -> 0. Wave 1 took five *measured* queued pages,
      // so it moved the first and left the second alone. Wave 2 was the first to
      // move both. Wave 3 took the largest bite out of `measured` and paid down
      // exactly one unit of debt. Wave 4 (#1380) had to clear both columns at once,
      // and the split inside its 21 pages was 8 measured against 13 debt — the
      // inverse of wave 1's, which is why it was the wave that had to write
      // fixtures rather than the wave that could pick them up.
      //
      // What the 13 cost, and why it is the wrong number to estimate the next
      // family from: **18 of the 21 pages needed a fixture, not 13.** This column
      // counts pages nothing could measure, and that is a narrower set than the
      // pages that owe a fixture. The five it missed are pages whose *unpinned*
      // render was good enough to time — `firmware_update`, whose only builder sat
      // in `test/golden_test/` where #1361 forbids the gate from importing it;
      // `support`, `router_assistant` and `remote_assistance`, which had no builder
      // anywhere and would have measured whatever a live service returned; and
      // `usp_sliver_dashboard_view`, whose fixture-less 315.4ms/cell was the
      // artefact of being unpinned. A cost figure is evidence of neither
      // reachability nor a usable fixture.
      //
      // The 18 were served by 16 files, two of which serve two pages each: nine
      // builders moved verbatim out of `test/golden_test/golden_framework/mocks/`
      // (eight 1:1; `admin` moved and then grew from 2 declarations to 6), ten
      // fixture files moved — one more than the builders, because
      // `usp_statistics_view`'s fixtures moved while its builder already lived in
      // `test/mocks/` — six authored from nothing, and one superset wrapper
      // (`gateStatisticsOverrides()`) written beside a builder that already worked,
      // because the golden fixtures are split across three tab states and the gate
      // pumps tab 0 and cannot tap. So the shape is roughly half relocation and
      // half authoring, not 11 to 2. Architecture doc §11.12 carries the breakdown.
      final measured = roster
          .withDisposition(PageRosterDisposition.queued)
          .where((r) => r.msPerCell != null);
      expect(measured, isEmpty);
      expect(roster.needsFixture, isEmpty);

      // Both counts are zero, so every `isNot(contains(...))` over `needsFixture`
      // is now a tautology. The four pages those assertions were written about are
      // asserted from the other end instead — they are swept — which is the claim
      // that still has content once the debt column is empty.
      const paidDown = {
        // Wave 3's one unit of debt: #1370's glob found this file one directory
        // deeper than the other login views and could not measure it at all,
        // because its opening state is the only state it has.
        'lib/page/login/auto_parent/views/auto_parent_first_login_view.dart',
        // #1370 recorded this as needing a fixture and #1378 wrote it — one
        // composed `NoInternet` state, shared with three other pages in the flow.
        'lib/page/instant_setup/views/pnp_waiting_modem_view.dart',
        // The subtler one: queued for a day, so it was *sweep* debt, never fixture
        // debt — its fixture got all 208 cells past the loader on the first
        // attempt and a ui_kit defect is what held it.
        'lib/page/instant_setup/views/pnp_setup_view.dart',
        // #1377 counted this page as fixture-free because `statisticsOverrides()`
        // exists. It was debt anyway: the populated state lived in
        // `test/golden_test/`, which #1361 forbids importing from here, and the
        // all-defaulted builder renders no section at all. #1380 moved the
        // fixtures out and added `gateStatisticsOverrides()`. A builder that
        // exists is not a builder that gets a view past its loader.
        'lib/page/statistics/views/usp_statistics_view.dart',
      };
      final sweptPaths = roster
          .withDisposition(PageRosterDisposition.swept)
          .map((r) => r.path)
          .toSet();
      for (final path in paidDown) {
        expect(sweptPaths, contains(path),
            reason: 'this row was fixture or sweep debt at some point in the '
                'epic and the debt column is now empty, so it has to be swept — '
                'the alternative is that it left the column by being dropped');
      }

      expect(
        roster.rows
            .firstWhere((r) =>
                r.path ==
                'lib/page/dashboard/views/usp_sliver_dashboard_view.dart')
            .msPerCell,
        58.6,
        reason:
            'not the 315.4 #1370 read, and the correction matters more than the '
            'number: that figure made this "the most expensive page in the app by '
            '6x" and 66s of pump CPU on its own, which is what put a #1371 re-open '
            'on the table. Three runs on #1377\'s basis read 58.6, so it is the '
            '4th most expensive page and 4.9% of the sweep. The roster\'s '
            '`# basis-note` block has the other six re-readings; every one of them '
            'moved down too. Pin it so a wall-clock figure cannot come back in.',
      );
    });

    test('the register reads 43 swept, 0 queued, 2 excluded', () {
      // 2/41/2 when #1382 shipped it; wave 1 (#1377) moved five from queued to
      // swept, wave 2 (#1378) nine — eight on the day, and `pnp_setup` the day
      // after, when ui_kit v2.40.2 unblocked it — wave 3 (#1379) six, and wave 4
      // (#1380) the remaining twenty-one. The excluded pair is #1370's and is not a
      // number a wave may move: a wave onboards pages, and deciding a page
      // unreachable is a separate judgement with its own reason column. Wave 4
      // inherited four exclusion *candidates* and excluded none of them — the
      // roster's `# verdict` block is where each of the four is argued, and the
      // short version is that unreachability is the only reason this epic accepts
      // and none of the four is unreachable.
      //
      // 43 + 2 = 45, which is the whole point: the count this epic set out to reach
      // is not "43 swept" but "45 accounted for", and the two are the same claim
      // only while `# queued 0` holds.
      expect(
          roster.withDisposition(PageRosterDisposition.swept), hasLength(43));
      expect(roster.withDisposition(PageRosterDisposition.queued), isEmpty);
      expect(
        roster
            .withDisposition(PageRosterDisposition.excluded)
            .map((r) => r.path)
            .toList(),
        const [
          'lib/page/instant_setup/views/pnp_complete_view.dart',
          'lib/page/unified_diagnostics/views/speed_test_view.dart',
        ],
        reason: '#1382 shipped 0 excluded on purpose and #1370 decided exactly '
            'two of the five candidates on its reachability check: '
            'pnp_complete_view (no route builds it and nothing under lib/ '
            'constructs it) and speed_test_view (its only route is commented out '
            'at lib/route/route_usp_dashboard.dart:223). The other three plus '
            'router_assistant_view were #1380\'s, and it kept all four — note that '
            'usp_sliver_dashboard_view is NOT routed and still not excludable, '
            'because usp_dashboard_view.dart:64 constructs it and so a user '
            'reaches it. Routed and reachable are different questions, which is '
            'why the check that decided these two is named in the reason column. '
            'usp_test_console_view is the sharpest case: route_usp_dashboard.dart'
            ':201 gates it behind `kDebugMode || enableTestConsole`, so it is '
            'absent from a default release build and present in every debug one — '
            'reachable, therefore in, and it carried the epic\'s largest single '
            'find (52 cells, +109px, the only `en` break in all 45 pages).',
      );
      for (final row
          in roster.withDisposition(PageRosterDisposition.excluded)) {
        expect(row.exclusionReason, contains('not reachable'),
            reason: row.path);
        expect(row.exclusionReason, contains('#1370'), reason: row.path);
      }
    });

    test('the committed roster declares every count the parser can check', () {
      // Closes the one place the header check is deliberately weaker than
      // `# pages`: the parser skips an absent count, so deleting `# swept 2` from
      // the fixture would disable its check in silence rather than fail. It is
      // optional there for the synthetic rosters' sake and required here, which is
      // where the count anyone reads actually lives.
      final text = File(kPageRosterFixturePath).readAsStringSync();
      for (final key in PageRoster.countedHeaderKeys) {
        expect(
          RegExp('^# $key \\d+\$', multiLine: true).hasMatch(text),
          isTrue,
          reason:
              'test/fixtures/page_roster.tsv has no `# $key <n>` header, so '
              'PageRoster._rejectStaleHeader silently checks nothing for it. '
              'Every count in the header block has to be falsifiable by the rows '
              'or it is decoration — and a count that only used to be checked is '
              'worse than one that never was.',
        );
      }
    });

    test('the excluded pair is still unreachable, re-checked this wave', () {
      // #1378 sweeps the flow `pnp_complete_view` belongs to, so "no route builds
      // it and nothing under lib/ constructs it" is a claim this ticket had to
      // re-check rather than inherit: a wave that added the page's siblings is
      // exactly when a route to it would have appeared. Re-run: the class name
      // occurs once under lib/, at its own constructor.
      //
      // Asserted rather than noted, because the exclusion is a page permanently
      // outside "45 of 45" and the reason column is the only thing holding it
      // there. `_$` and `(` bound the match to a declaration or a call site so the
      // string in this test's own name cannot satisfy it.
      final referenced = <String, int>{};
      for (final entry in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final hits = RegExp(r'\bPnpCompleteView\s*\(')
            .allMatches(entry.readAsStringSync())
            .length;
        if (hits > 0) referenced[entry.path] = hits;
      }
      expect(
        referenced.keys,
        const ['lib/page/instant_setup/views/pnp_complete_view.dart'],
        reason: 'something under lib/ now constructs PnpCompleteView, so it is '
            'reachable and the exclusion reason in the roster is stale. Move the '
            'row to `queued` and move the `# excluded` and `# queued` headers.',
      );
      expect(
        referenced.values.single,
        1,
        reason: 'the one occurrence is the widget\'s own const constructor; a '
            'second in the same file would be a call site inside the flow',
      );
    });

    test('swept is 43 of 45 — every page but the two unreachable ones', () {
      // Written out rather than counted, and that is the point of the test. This is
      // the roster half of the join assertion 3 checks both directions of, so a
      // length check would pass against 43 rows that are not these 43.
      //
      // #1370's own AC is the fact this test was opened to protect. That run pumped
      // 45 pages and 22 of them were at zero across all 208 cells, and it flipped
      // **none** of them: nothing about it was committed, declared in
      // kPageSurfaceCases, or capable of failing a PR. `swept` means the gate covers
      // the page, which is a claim only a declaration can make. For three waves the
      // two numbers could be confused — after wave 3 both read 22, of which only 18
      // were shared — and the test kept the sets apart by writing them out. That
      // particular trap is now closed by arithmetic, since 43 > 22 and the inventory
      // never had 43 clean pages. The habit is kept anyway: the next family will
      // start with its own clean-at-zero count and its own declared count, and they
      // will be confusable again.
      //
      // How the 43 arrived, since the shape of the epic is the reusable part:
      // 2 pilot (#1349) + 5 wave 1 (#1377) + 9 wave 2 (#1378) + 6 wave 3 (#1379) +
      // 21 wave 4 (#1380). Waves 1-3 needed **one** widget fix between them, in
      // `usp_port_forwarding_detail_view`, plus one in ui_kit
      // (`linksys/privacyGUI-UI-kit#70`, v2.40.2) that held `pnp_setup` back a day —
      // and wave 3 was filed predicting finds it did not get. Wave 4 needed
      // **fourteen**, which is what the epic was opened on and what the last twenty-one
      // pages were expected to produce: never-swept feature surfaces at 320px and
      // 601px in 26 locales. Not one of the 43 entered on an allowlist entry;
      // `known_overflows.json` is still `{"tracking": {}, "allowlist": {}}`.
      expect(roster.sweptPaths, {
        'lib/page/admin/views/usp_admin_view.dart',
        'lib/page/advanced_settings/views/usp_advanced_settings_view.dart',
        'lib/page/ai_assistant/views/router_assistant_view.dart',
        'lib/page/apps/views/usp_apps_view.dart',
        'lib/page/dashboard/views/usp_dashboard_view.dart',
        'lib/page/dashboard/views/usp_sliver_dashboard_view.dart',
        'lib/page/devices/views/usp_device_detail_view.dart',
        'lib/page/devices/views/usp_device_list_view.dart',
        'lib/page/dhcp/views/usp_dhcp_detail_view.dart',
        'lib/page/dmz/views/usp_dmz_view.dart',
        'lib/page/firewall/views/usp_firewall_view.dart',
        'lib/page/firmware_update/views/firmware_update_view.dart',
        'lib/page/instant_privacy/views/instant_privacy_view.dart',
        'lib/page/instant_safety/views/instant_safety_view.dart',
        'lib/page/instant_setup/views/pnp_entry_view.dart',
        'lib/page/instant_setup/views/pnp_isp_settings_view.dart',
        'lib/page/instant_setup/views/pnp_modem_lights_off_view.dart',
        'lib/page/instant_setup/views/pnp_no_internet_view.dart',
        'lib/page/instant_setup/views/pnp_pppoe_view.dart',
        'lib/page/instant_setup/views/pnp_setup_view.dart',
        'lib/page/instant_setup/views/pnp_static_ip_view.dart',
        'lib/page/instant_setup/views/pnp_unplug_modem_view.dart',
        'lib/page/instant_setup/views/pnp_waiting_modem_view.dart',
        'lib/page/internet_settings/views/usp_internet_settings_view.dart',
        'lib/page/ipv6_port_service/views/usp_ipv6_port_service_view.dart',
        'lib/page/landing/views/home_view.dart',
        'lib/page/local_network/views/usp_local_network_view.dart',
        'lib/page/login/auto_parent/views/auto_parent_first_login_view.dart',
        'lib/page/login/views/local_reset_router_password_view.dart',
        'lib/page/login/views/local_router_recovery_view.dart',
        'lib/page/login/views/login_local_view.dart',
        'lib/page/menu/views/usp_menu_view.dart',
        'lib/page/port_forwarding/views/usp_port_forwarding_detail_view.dart',
        'lib/page/remote_assistance/views/remote_assistance_confirm_view.dart',
        'lib/page/static_routing/views/usp_static_routing_view.dart',
        'lib/page/statistics/views/usp_statistics_view.dart',
        'lib/page/support/views/usp_support_view.dart',
        'lib/page/system_log/views/usp_system_log_view.dart',
        'lib/page/test_console/views/usp_test_console_view.dart',
        'lib/page/topology/views/usp_node_detail_view.dart',
        'lib/page/topology/views/usp_topology_view.dart',
        'lib/page/unified_diagnostics/views/unified_diagnostics_view.dart',
        'lib/page/wifi_settings/views/usp_wifi_settings_view.dart',
      });
    });
  });

  group('each assertion can fail', () {
    // The permanent half of "red before green". Each case takes the committed
    // roster, breaks it in exactly one way, and drives the same check the group
    // above drives — so the three assertions cannot decay into three tautologies
    // the way three emptied `requires` lists did in #1364/#1366.
    //
    // The mutations are built from `roster.rows` through [PageRosterRow.line]
    // rather than by searching the file's text, and the header is recomputed from
    // the row count, so a mutation fails for the reason under test rather than at
    // the parser. `the committed fixture round-trips through the row writer`
    // below is what says those rows really are the committed file.
    //
    // Nothing here runs at group-declaration time. It did in the first draft — a
    // `firstWhere` over the file's lines — and a deleted row then failed the whole
    // suite to *load* rather than failing the assertion under test, which is the
    // same shape of unhelpful red the gate keeps learning about.
    const dhcpPath = 'lib/page/dhcp/views/usp_dhcp_detail_view.dart';
    // The row assertion 3's forward direction is mutated. It was `usp_admin_view`
    // while that page was queued; #1380 swept it along with the other twenty, and
    // once `# queued 0` holds there is no queued row left to promote. So the
    // mutation moves to an **excluded** row — which is the stronger case anyway,
    // and the one the register will keep having: a row can be claimed swept while
    // no case declares it either by being promoted out of the queue or by being
    // promoted out of an exclusion, and the second is the shape a later reader is
    // more likely to produce, because an exclusion looks like a decision already
    // made rather than like work not yet done.
    const undeclaredPath =
        'lib/page/instant_setup/views/pnp_complete_view.dart';

    String rosterOf(Iterable<String> rowLines) {
      final rows = rowLines.toList();
      return ['# page-roster 1', '# pages ${rows.length}', ...rows].join('\n');
    }

    test('assertion 1 goes red when a row is deleted', () {
      final without = PageRoster.parse(rosterOf(
        roster.rows.where((r) => r.path != dhcpPath).map((r) => r.line),
      ));
      expect(without.unrecordedPages(discovered), [dhcpPath]);
      // And the same check over the real fixture is empty, so the mutation is
      // what produced the finding rather than the check always producing one.
      expect(roster.unrecordedPages(discovered), isEmpty);
    });

    test('assertion 2 goes red on a row naming a file that does not exist', () {
      // `aaa_` so the row still sorts first and the ordering rule is not what
      // fails; `queued` so the swept assertions are not what fails either.
      const gone = 'lib/page/aaa_deleted/views/aaa_deleted_view.dart';
      expect(File(gone).existsSync(), isFalse);
      final withPhantom = PageRoster.parse(rosterOf([
        '$gone\tqueued\t-',
        ...roster.rows.map((r) => r.line),
      ]));
      expect(withPhantom.phantomRows(), [gone]);
      expect(roster.phantomRows(), isEmpty);
    });

    test('assertion 3 goes red when an undeclared page is marked swept', () {
      // `pnp_complete_view` is excluded as unreachable and no case declares it.
      // Marked swept it needs an ms/cell to get past the parser at all, which is
      // the point: the number is fabricated, and this is the assertion that catches
      // the claim anyway. Its exclusion reason goes with the disposition, so this
      // also covers the reader dropping a reason it no longer has a column for.
      final mutated = PageRoster.parse(rosterOf(roster.rows.map((r) =>
          r.path == undeclaredPath ? '$undeclaredPath\tswept\t44.8' : r.line)));
      expect(mutated.sweptPaths.difference(declaredPaths), {undeclaredPath});
      expect(roster.sweptPaths.difference(declaredPaths), isEmpty);
    });

    test('assertion 3 goes red in the other direction too', () {
      // A case declared while its row still reads `queued` — the shape a wave
      // produces when it onboards a page and forgets the record.
      final mutated = PageRoster.parse(rosterOf(roster.rows
          .map((r) => r.path == dhcpPath ? '$dhcpPath\tqueued\t-' : r.line)));
      expect(declaredPaths.difference(mutated.sweptPaths), {dhcpPath});
      expect(declaredPaths.difference(roster.sweptPaths), isEmpty);
    });
  });

  group('the reader refuses a roster that would read as well-formed', () {
    // Every rejection here is a way the record could claim something untrue while
    // parsing cleanly, which is the only failure mode a coverage record has.
    const good = 'lib/page/dhcp/views/usp_dhcp_detail_view.dart';
    String one(String row, {int pages = 1}) => '# pages $pages\n$row';

    test('a row for a composed widget one level deeper is rejected', () {
      expect(
        () => PageRoster.parse(one(
          'lib/page/unified_diagnostics/views/widgets/diagnostic_start_view.dart\tqueued\t-',
        )),
        throwsA(isA<PageRosterFormatException>()),
        reason:
            'the shape check is the structural half of holding the roster to '
            '45; without it the count pin is the only thing standing between the '
            'record and a 49-page denominator',
      );
    });

    test('a missing ms/cell field is rejected, not read as unmeasured', () {
      expect(
        () => PageRoster.parse(one('$good\tqueued')),
        throwsA(isA<PageRosterFormatException>()),
      );
    });

    test('an empty ms/cell field is rejected in favour of `-`', () {
      // A trailing tab is invisible in a diff and any hook that strips trailing
      // whitespace turns this row into the two-field row above.
      expect(
        () => PageRoster.parse(one('$good\tqueued\t')),
        throwsA(isA<PageRosterFormatException>()),
      );
    });

    test('a swept row with no measurement is rejected', () {
      expect(
        () => PageRoster.parse(one('$good\tswept\t-')),
        throwsA(isA<PageRosterFormatException>()),
      );
    });

    test('a queued row may carry a measured number', () {
      // #1382 rejected this, on the argument that a number on an unswept page was
      // necessarily fabricated. #1370 falsified the premise by measuring 25 of
      // them on §11.2's basis, and the figures are the ticket's whole output — so
      // the rule now bites where the parser can still tell truth from fiction
      // (below), and the file's `# basis` header carries the provenance the parser
      // cannot check.
      final parsed = PageRoster.parse(one('$good\tqueued\t22.5'));
      expect(parsed.rows.single.disposition, PageRosterDisposition.queued);
      expect(parsed.rows.single.msPerCell, 22.5);
      expect(parsed.needsFixture, isEmpty);
    });

    test('a queued row with no number is the fixture-debt marker', () {
      final parsed = PageRoster.parse(one('$good\tqueued\t-'));
      expect(parsed.rows.single.msPerCell, isNull);
      expect(parsed.needsFixture, [good],
          reason: 'after #1370 a `-` on a queued row is a finding — no fixture '
              'gets that view past its loader — and not merely a default');
    });

    test('an excluded row carrying a number is rejected', () {
      expect(
        () => PageRoster.parse(one('$good\texcluded:not reachable\t7.6')),
        throwsA(isA<PageRosterFormatException>()),
        reason:
            'pnp_complete_view really does cost 7.6ms/cell — the run measured '
            'it before deciding it — but nothing will ever pump it, so carrying '
            'the figure would make the remaining-work total read high by one page '
            'per exclusion',
      );
    });

    test('a header count that disagrees with the rows is rejected', () {
      // Every counted header besides `# pages`, driven red one at a time rather
      // than a sample of them: `needs_fixture` is the newest and the one whose
      // predicate is not a plain disposition count, so a sample that skipped it
      // would be a sample that skipped the fragile one. The row below is queued
      // with no figure — one page, zero swept, one queued, zero excluded, zero
      // measured, one needing a fixture — so every claim here is off by one.
      for (final key
          in PageRoster.countedHeaderKeys.where((k) => k != 'pages')) {
        final wrong = '# $key 9';
        expect(
          () => PageRoster.parse('# pages 1\n$wrong\n$good\tqueued\t-'),
          // The message has to name the header that disagreed, not merely throw:
          // every mutation here is one line away from a well-formed roster, and a
          // bare `throwsA` would pass just as happily on a parse error somewhere
          // else in the synthetic file.
          throwsA(isA<PageRosterFormatException>()
              .having((e) => e.message, 'message', contains('# $key 9'))),
          reason: '`$wrong` disagrees with the single row and parsed anyway',
        );
      }
      // Absent is fine — the synthetic rosters above are two lines long, and
      // demanding five more headers of them would make every mutation in `each
      // assertion can fail` fail at the parser instead of at its assertion. What
      // stops that tolerance from reaching the committed file is `the committed
      // roster declares every count the parser can check`, above.
      expect(
          PageRoster.parse('# pages 1\n$good\tqueued\t-').rows, hasLength(1));
    });

    test('an unknown disposition is rejected', () {
      expect(
        () => PageRoster.parse(one('$good\tdone\t-')),
        throwsA(isA<PageRosterFormatException>()),
      );
    });

    test('`excluded` is a valid disposition and carries its reason', () {
      final parsed =
          PageRoster.parse(one('$good\texcluded:no route reaches it\t-'));
      expect(parsed.rows.single.disposition, PageRosterDisposition.excluded);
      expect(parsed.rows.single.exclusionReason, 'no route reaches it');
      expect(parsed.rows.single.msPerCell, isNull);
    });

    test('`excluded` with no reason is rejected', () {
      expect(
        () => PageRoster.parse(one('$good\texcluded:\t-')),
        throwsA(isA<PageRosterFormatException>()),
        reason:
            'an exclusion without a written reason is indistinguishable from '
            'a page someone forgot, which is the state this roster ends',
      );
    });

    test('a duplicated path is rejected', () {
      expect(
        () => PageRoster.parse(
            one('$good\tqueued\t-\n$good\tqueued\t-', pages: 2)),
        throwsA(isA<PageRosterFormatException>()),
      );
    });

    test('rows out of path order are rejected', () {
      expect(
        () => PageRoster.parse(one(
          'lib/page/wifi_settings/views/usp_wifi_settings_view.dart\tqueued\t-\n'
          '$good\tqueued\t-',
          pages: 2,
        )),
        throwsA(isA<PageRosterFormatException>()),
        reason: 'path order keeps adding a page a one-line diff and keeps two '
            'waves from colliding on the same line',
      );
    });

    test('a `# pages` header that disagrees with the rows is rejected', () {
      expect(
        () => PageRoster.parse(one('$good\tqueued\t-', pages: 45)),
        throwsA(isA<PageRosterFormatException>()),
        reason: 'a record whose own header disagrees with it is the shape of '
            'every stale count in this epic',
      );
    });

    test('a roster with no `# pages` header is rejected', () {
      expect(
        () => PageRoster.parse('$good\tqueued\t-'),
        throwsA(isA<PageRosterFormatException>()),
      );
    });

    test('an absent fixture is an error, not an empty roster', () {
      expect(
        () => PageRoster.fromFixture('test/fixtures/_absent_roster.tsv'),
        throwsA(isA<PageRosterFormatException>()),
        reason: 'an absent roster read as empty would make the <-> assertion '
            'vacuous in one direction, which is the pass-shaped result for an '
            'unrun guard this gate has already shipped twice',
      );
    });

    test('the committed fixture round-trips through the row writer', () {
      // Cheap, and it is what says the parser understood the file rather than
      // tolerating it: a field the reader silently dropped would not come back.
      final body = File(kPageRosterFixturePath)
          .readAsLinesSync()
          .where((l) => !l.startsWith('#') && l.trim().isNotEmpty);
      expect(roster.rows.map((r) => r.line), body);
    });
  });
}
