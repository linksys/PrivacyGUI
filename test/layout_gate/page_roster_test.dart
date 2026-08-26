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
        reason: 'this row read `queued` for one day. If it reads `queued` again, a '
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

    test('13 queued pages are measured and 14 still need a fixture', () {
      // The distinction #1370 bought, and the one the waves estimate against. The
      // epic inferred "37 of 44 need a fixture written" from which builders exist
      // in test/mocks/provider_overrides/; the run found the shared mock alone
      // carries 21 unfixtured pages past their loader, so the fixture debt it
      // measured was **16**, not 37 — and one of those 16 was a page whose builder
      // *does* exist.
      //
      // Both counts have moved since, and they are different counts:
      // `measured` (queued pages a fixture already gets past their loader) went
      // 25 → 20 → 14 → 13, and `needsFixture` went 16 → 16 → 14 → 14. Wave 1 took
      // five *measured* queued pages, which is what "the fixture is already written"
      // selected for, so it moved the first and left the second alone. Wave 2 is
      // the first wave to move both: it took seven measured pages **and wrote a
      // fixture**, so the debt fell 16 → 14 — `pnp_waiting_modem` was swept with
      // the phase it needed, and `pnp_setup` spent a day measured-but-queued on a
      // ui_kit defect rather than unmeasured for want of a fixture. The bump to
      // ui_kit v2.40.2 then swept `pnp_setup`, which is why `measured` fell one more
      // and `needsFixture` did not move at all: that page was never in it.
      final measured = roster
          .withDisposition(PageRosterDisposition.queued)
          .where((r) => r.msPerCell != null);
      expect(measured, hasLength(13));
      expect(roster.needsFixture, hasLength(14));
      expect(
        roster.needsFixture,
        isNot(contains(
            'lib/page/instant_setup/views/pnp_waiting_modem_view.dart')),
        reason: '#1370 recorded this page as needing a fixture and #1378 wrote '
            'it — one composed `NoInternet` state, shared with three other pages '
            'in the same flow. It is swept, so it is not debt.',
      );
      expect(
        roster.needsFixture,
        isNot(contains('lib/page/instant_setup/views/pnp_setup_view.dart')),
        reason: 'the other half of the same correction, and the subtler one: this '
            'page was queued for a day, so it was *sweep* debt — but its fixture '
            'was written and got all 208 cells past the loader, so counting it as '
            'fixture debt would have made #1369 budget for work already done. It is '
            'swept now, and this assertion is kept because the shape it guards '
            'against (a swept page still counted as fixture debt) is the same '
            'mistake read from the other end.',
      );
      expect(
        roster.needsFixture,
        contains('lib/page/statistics/views/usp_statistics_view.dart'),
        reason: 'statisticsOverrides() exists, which is why #1377 counted this '
            'page as fixture-free — but its populated state lives in '
            'test/golden_test/, which #1361 forbids importing from here, and the '
            'all-defaulted builder renders no StatsHealthScoreSection. A builder '
            'that exists is not a builder that gets this view past its loader.',
      );
      expect(
        roster.rows
            .firstWhere((r) =>
                r.path ==
                'lib/page/dashboard/views/usp_sliver_dashboard_view.dart')
            .msPerCell,
        315.4,
        reason:
            'the most expensive page in the app by 6x, and the reason 37.7ms '
            'is a mean rather than a planning constant: 208 cells of this one '
            'page is 66s, a third of every measured queued page combined',
      );
    });

    test('the register reads 16 swept, 27 queued, 2 excluded', () {
      // 2/41/2 when #1382 shipped it; wave 1 (#1377) moved five from queued to
      // swept and wave 2 (#1378) nine — eight on the day, and `pnp_setup` the day
      // after, when ui_kit v2.40.2 unblocked it — and nothing else in either. The
      // excluded pair is #1370's and is not a number a wave may move: a wave onboards
      // pages, and deciding a page unreachable is a separate judgement with its own
      // reason column.
      expect(roster.withDisposition(PageRosterDisposition.swept), hasLength(16));
      expect(
          roster.withDisposition(PageRosterDisposition.queued), hasLength(27));
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
            'router_assistant_view are #1380\'s — and note that '
            'usp_sliver_dashboard_view is NOT routed and still not excludable, '
            'because usp_dashboard_view.dart:64 constructs it and so a user '
            'reaches it. Routed and reachable are different questions, which is '
            'why the check that decided these two is named in the reason column.',
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

    test('swept is the pilot two, wave 1 and wave 2 — not the inventory\'s 22',
        () {
      // #1370's own AC, kept as a repo fact and now the sharper half of this test.
      // That run pumped 45 pages and 22 of them were at zero across all 208 cells,
      // and it flipped **none** of them: nothing about it was committed, declared
      // in kPageSurfaceCases, or capable of failing a PR. `swept` means the gate
      // covers the page, which is a claim only a declaration can make.
      //
      // So the five #1377 added and the nine #1378 added are here for a different
      // reason than "the inventory said they were clean". Each is a
      // `PageSurfaceCase` with a premise, each is pinned at 234 cells in the suite
      // (208 until #1372 widened every page by one width),
      // and each is in the committed `page` coverage baseline — and the one of
      // wave 1's five that was *not* at zero was fixed in the widget before it
      // arrived. The set below is the join assertion 3 checks both directions of, so
      // this is the roster half of it stated by name.
      //
      // Eight of wave 2's nine measured at zero on the first sweep, so nothing in
      // the instant_setup flow needed a widget fix *here* to enter — but the wave
      // still shipped one, in `pnp_setup_view.dart`'s controller lifecycle, which is
      // a crash rather than an overflow and is why that page's own suite is untagged
      // and PR-blocking. The ninth needed a fix in ui_kit rather than here
      // (`linksys/privacyGUI-UI-kit#70`, v2.40.2), which is the same rule met from
      // outside the repo: `pnp_setup` entered the day the overflow reached zero, not
      // the day it was measurable.
      expect(roster.sweptPaths, {
        'lib/page/devices/views/usp_device_detail_view.dart',
        'lib/page/devices/views/usp_device_list_view.dart',
        'lib/page/dhcp/views/usp_dhcp_detail_view.dart',
        'lib/page/instant_setup/views/pnp_entry_view.dart',
        'lib/page/instant_setup/views/pnp_isp_settings_view.dart',
        'lib/page/instant_setup/views/pnp_modem_lights_off_view.dart',
        'lib/page/instant_setup/views/pnp_no_internet_view.dart',
        'lib/page/instant_setup/views/pnp_pppoe_view.dart',
        'lib/page/instant_setup/views/pnp_setup_view.dart',
        'lib/page/instant_setup/views/pnp_static_ip_view.dart',
        'lib/page/instant_setup/views/pnp_unplug_modem_view.dart',
        'lib/page/instant_setup/views/pnp_waiting_modem_view.dart',
        'lib/page/port_forwarding/views/usp_port_forwarding_detail_view.dart',
        'lib/page/topology/views/usp_node_detail_view.dart',
        'lib/page/topology/views/usp_topology_view.dart',
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
    const adminPath = 'lib/page/admin/views/usp_admin_view.dart';

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

    test('assertion 3 goes red when a queued page is marked swept', () {
      // admin is queued and no case declares it. Marked swept it needs an
      // ms/cell to get past the parser at all, which is the point: the number is
      // fabricated, and this is the assertion that catches the claim anyway.
      final mutated = PageRoster.parse(rosterOf(roster.rows.map(
          (r) => r.path == adminPath ? '$adminPath\tswept\t44.8' : r.line)));
      expect(mutated.sweptPaths.difference(declaredPaths), {adminPath});
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
