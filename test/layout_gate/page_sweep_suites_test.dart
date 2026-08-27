@Tags(['layout-gate'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';

import 'families/page_surface_cases.dart';
import 'families/page_surface_family.dart';
import 'page_roster.dart';
import 'page_sweep_suites.dart';

/// The page sweep register's oracle (#1371).
///
/// `layout-gate` and **not** `overflow`, like the six oracles before it: the
/// `overflow` tag means "pumps cells and asserts zero overflow", and this file pumps
/// nothing — it reads the page tree as text, one case file as text, and the
/// committed roster. It is in the PR gate for the reason `page_roster_test.dart`
/// gives about itself: an oracle that runs on a schedule cannot stop a page from
/// escaping this afternoon.
///
/// ## What this closes, and why it is not a consolation prize
///
/// #1371 asked where the page cells should run and measured the answer instead of
/// assuming it: the page sweep **stayed one file**, because four cost-balanced shards
/// cost +14.7s on `--tags layout-gate` and +61s on `./run_tests.sh` at the fifteen
/// pages of the day it was measured (§11.10). At the 43 of #1380 the same measurement
/// reverses on the laptop — one file is 558s against a 145.2s floor, ×4.01 on the
/// gate — and then **reverses back on the runner that blocks the PR**, which has two
/// test lanes to the laptop's five: 508s total, the page sweep alone for only its
/// last 53s, so a split buys ~50s and costs ~87s. **One file stays** (§11.12), and
/// `kPageSweepSuiteCount` reads 1 for the second time. Either way this oracle is not
/// the bookkeeping a split needed — it
/// is the hole that was already open with one file, and would have stayed open if
/// the split had shipped:
///
/// - `page_surface_family_test.dart` pins `kPageSurfaceCases` exactly, so no page
///   leaves the *declaration* unseen — and a case can sit there while no
///   `runOverflowSweep` call names it.
/// - `page_roster_test.dart` joins the roster's `swept` rows to that same list, so
///   it inherits the same blind spot.
/// - `page.tsv` would notice, as 234 rows reading `no longer measured`, and nothing
///   in the PR gate runs that diff.
///
/// Delete one of the 43 calls today and every record above still calls the
/// page covered. That is what assertion 2 is for — and #1380's A/B measured it from
/// the other side: holding the whole suite aside takes **468** tests out of
/// `--tags layout-gate` (its 448, plus these 20, which cannot load without it) and
/// produces exactly one red, this file's `setUpAll`.
///
/// ## The five checks — four assertions and one report
///
/// 1. **Exactly [kPageSweepSuiteCount] suites, and each is tagged.** A suite with no
///    `layout-gate` runs in no selection while its pages read as swept everywhere
///    else.
/// 2. **Declared ⟺ swept in exactly one suite**, both directions — the hole above.
/// 3. **Every guard sits with the page it pumps.** Vacuous at one suite by
///    construction, and kept because it is what makes the eventual split safe with
///    no edit on the day, and because a reworded group title must fail somewhere.
/// 4. **No suite's weight is guessed, and suites stay balanced** once there is more
///    than one, from the roster's own `ms_per_cell` column.
/// 5. **Each suite's projection against the measured ceiling — printed, not
///    asserted.** The gate spends 149.79s with no page cells in it; a page suite
///    lighter than that is hidden inside it and costs only CPU, and a heavier one is
///    the run's long pole where every second is a second on the gate. This shipped as
///    an assertion and **Austin downgraded it to a print the same day** (§11.10's
///    amendment), so that the decision would be taken once, with all 45 pages
///    measured. **#1380 took it twice: four suites on the 10-core box, then one suite
///    once the same gate was measured on the 4-vCPU runner that blocks the PR** — two
///    test lanes there instead of five, both ~90% busy, so the 3.84 that chose four reads
///    1.12 (§11.12, and `page_sweep_suites.dart`'s header carries both). The print stays
///    a print either way, for a reason that has changed rather than lapsed — the red
///    would now be *correct*, and there would still be nothing the author of an unrelated
///    PR could do about it, because the fix is one restructuring ticket.
///
/// ## Red before green, permanently
///
/// This repo has been burned twice by a guard nobody watched fail — `--tags
/// dashboard-card` returning "No tests ran" after #1336 renamed the tag, and 208
/// cells going green over an `AppLoader()` spinner (#1364/#1366). Every assertion
/// below was watched red by hand against the real tree before it was green (the PR
/// records the six failures and their messages). The `each assertion can fail` group
/// is what keeps proving it, driving the same checks over synthetic registers that
/// are wrong in exactly one way. A hand check that happened this afternoon is not a
/// guard.
void main() {
  late final List<PageSweepSuite> suites;
  late final Map<String, String> idByIdentifier;
  late final PageRoster roster;

  /// Case identifier → measured ms/cell, joined identifier → id → widget type →
  /// declaring file → roster row. The middle steps are `page_roster.dart`'s, and the
  /// join is on where the class is *declared* rather than on a name derived from the
  /// type, for the reason recorded there: `instant_safety_view.dart` declares
  /// `UspInstantSafetyView`, so a name-derived join resolves one real page to
  /// nothing — and nothing satisfies a subset check.
  late final Map<String, double> msPerCellByIdentifier;

  late final int cellsPerPage;

  setUpAll(() {
    // Read here and not at declaration time: an unreadable register throws, and a
    // throw outside a test fails the suite to *load*, which is a shape this gate has
    // twice found unreadable. From `setUpAll` the message reaches every test.
    suites = discoverPageSweepSuites();
    idByIdentifier = pageCaseIdsByIdentifier();
    roster = PageRoster.fromFixture();
    cellsPerPage =
        kPageSweepWidths.length * AppLocalizations.supportedLocales.length;

    final typeById = {
      for (final page in kPageSurfaceCases)
        page.id: page.view().runtimeType.toString(),
    };
    final declaringPaths =
        pageViewPathsDeclaring(typeById.values, discoverPageViews());
    final msPerCellByPath = {
      for (final row in roster.rows)
        if (row.msPerCell != null) row.path: row.msPerCell!,
    };

    msPerCellByIdentifier = {};
    for (final entry in idByIdentifier.entries) {
      final type = typeById[entry.value];
      if (type == null) continue; // a declared constant nothing sweeps
      final paths = declaringPaths[type] ?? const <String>[];
      if (paths.length != 1) continue; // assertion 2's job to report
      final ms = msPerCellByPath[paths.single];
      if (ms != null) msPerCellByIdentifier[entry.key] = ms;
    }
  });

  group('assertion 1: the suites exist and each one runs in the gate', () {
    test(
        '$kPageSweepSuiteRoot holds exactly $kPageSweepSuiteCount page sweep '
        'suite(s)', () {
      expect(
        suites.map((s) => s.path).toList(),
        hasLength(kPageSweepSuiteCount),
        reason:
            'kPageSweepSuiteCount is pinned because the number is a decision '
            'taken against a measurement (§11.10), not a property of the tree. '
            'Found: ${suites.map((s) => s.path).join(', ')}. If a suite was added '
            'deliberately, move the constant and read check 5 — it prints what '
            'each suite is projected to cost. If one appeared by accident, it is '
            'a second sweep of pages nobody registered.',
      );
    });

    test('every suite carries layout-gate and overflow', () {
      for (final suite in suites) {
        expect(
          suite.tags,
          containsAll(<String>['layout-gate', 'overflow']),
          reason:
              '${suite.path} lists ${suite.tags}. `layout-gate` is what makes '
              'it PR-blocking (run_tests.sh excludes golden||loc||ui and neither '
              'is here) and `overflow` is what puts it in the pre-commit '
              'selector. A suite missing either still holds its pages, so every '
              'other record in this gate keeps calling them swept.',
        );
      }
    });
  });

  group('assertion 2: declared and swept are the same set', () {
    late final PageSweepMembership membership;

    setUpAll(() {
      membership = pageSweepMembership(
        suites: suites,
        idByIdentifier: idByIdentifier,
        declaredIds: kPageSurfaceCases.map((c) => c.id).toSet(),
      );
    });

    test('every declared case is swept somewhere', () {
      expect(
        membership.unswept,
        isEmpty,
        reason: 'these declared pages are swept by nothing, while '
            'kPageSurfaceCases, the roster\'s `swept` rows and the committed '
            'page.tsv all still say they are covered: '
            '${membership.unswept.join(', ')}. This is the escape that exists '
            'with one file as much as with four, and the reason this oracle was '
            'kept when the split was not.',
      );
    });

    test('no declared case is swept twice', () {
      expect(
        membership.duplicated,
        isEmpty,
        reason:
            'these pages are swept more than once, which emits the same cell '
            'ids twice — rejected by the baseline extractor as "measured twice", '
            'but only at capture time, and nothing in the PR gate captures: '
            '${membership.duplicated.entries.map((e) => '${e.key} in ${e.value.join(' and ')}').join(', ')}',
      );
    });

    test('every swept identifier is a declared case', () {
      expect(
        membership.undeclared,
        isEmpty,
        reason: 'these identifiers are swept and are not declared in '
            '$kPageSurfaceCasesPath: ${membership.undeclared.join(', ')}. A sweep '
            'outside kPageSurfaceCases is a sweep '
            'page_surface_family_test.dart\'s exact-list pin never sees, so its '
            'cell count, its roster row and its baseline rows are all '
            'unaccounted for.',
      );
    });
  });

  group('assertion 3: every readability guard sits with its page', () {
    late final PageSweepGuardFaults faults;

    setUpAll(() => faults = pageSweepGuardFaults(suites));

    test('every guard a suite declares names a page', () {
      expect(
        faults.unregistered,
        isEmpty,
        reason: 'these guard groups are not in kReadabilityGuardPages: '
            '${faults.unregistered.join(', ')}. Register each with the page it '
            'pumps — a guard whose page is unknown cannot be kept beside that '
            'page across a split, and its 4.5s is charged to whichever suite '
            'happens to hold it.',
      );
    });

    test('every guard runs in the suite that sweeps its page', () {
      expect(
        faults.misplaced,
        isEmpty,
        reason: '${faults.misplaced.join('; ')}. Rule 4 pairs a guard with the '
            'site an overflow fix changed; separated from its page the guard '
            'measures a fixture another suite is responsible for.',
      );
    });

    test('every registered guard is declared by some suite', () {
      expect(
        faults.uncalled,
        isEmpty,
        reason: 'these guards are registered and declared nowhere: '
            '${faults.uncalled.join(', ')}. A guard that runs in no suite is the '
            'readability half of a fix silently leaving the gate — and the '
            'overflow half stays green, because a wrap does not overflow. If a '
            'group title was reworded, reword it here too.',
      );
    });
  });

  group('assertion 4: the weights are real, and stay balanced', () {
    test('no suite weight is guessed', () {
      // The direction the ceiling assertion cannot catch: a page whose cost is
      // unknown makes its suite read lighter than it is.
      for (final suite in suites) {
        for (final identifier in suite.caseIdentifiers) {
          expect(
            msPerCellByIdentifier,
            contains(identifier),
            reason:
                '$identifier is swept by ${suite.label} and has no measured '
                'ms/cell in ${roster.source}. A `swept` row cannot omit the '
                'figure — page_roster.dart rejects that — so this is a join that '
                'broke rather than a page that is free.',
          );
        }
      }
    });

    test(
        'every suite is within '
        '${(kPageSweepBalanceTolerance * 100).round()}% of the mean', () {
      // Trivially satisfied at one suite — one suite is its own mean — and written
      // now so the split needs no new assertion on the day it happens.
      final weights = {
        for (final suite in suites)
          suite.label: pageSweepSuiteWeightMs(
            suite,
            msPerCellByIdentifier: msPerCellByIdentifier,
            cellsPerPage: cellsPerPage,
          ),
      };
      final mean = weights.values.reduce((a, b) => a + b) / weights.length;
      final report = weights.entries
          .map((e) => '${e.key}=${(e.value / 1000).toStringAsFixed(1)}s '
              '(${((e.value / mean - 1) * 100).toStringAsFixed(1)}%)')
          .join(', ');

      for (final suite in suites) {
        final weight = weights[suite.label]!;
        // The one exemption, and it is a floor rather than a loophole: 234 cells of
        // one page are one `runOverflowSweep` call, so a page heavier than the mean
        // cannot be split and gets a suite to itself. It was written for
        // `usp_sliver_dashboard_view` at #1370's 315.4ms/cell — 1m14s alone — and
        // #1380 re-measured that page at **58.6**, so the heaviest page in the roster
        // is now `usp_local_network_view` at 104.7ms/cell, **24.5s**. That is 29% of a
        // quarter-suite rather than most of one, so §11.10's "cannot promise balance
        // at 43 pages" no longer holds and a four-way split would be balanceable — on a
        // machine with a spare lane to run it in, which the PR runner is not (§11.12).
        // The exemption stays: it costs nothing at one suite, and the next family's
        // heaviest page is not this one.
        if (suite.caseIdentifiers.length == 1 && weight > mean) continue;
        expect(
          (weight / mean - 1).abs(),
          lessThanOrEqualTo(kPageSweepBalanceTolerance),
          reason: '${suite.label} is ${(weight / 1000).toStringAsFixed(1)}s '
              'against a ${(mean / 1000).toStringAsFixed(1)}s mean. Once the '
              'sweep is split it must be split by measured cost, because the '
              'heaviest suite is the run\'s long pole no matter how many cores '
              'exist — an unbalanced split gives back the wall clock it bought. '
              'Today: $report',
        );
      }
    });
  });

  group('check 5: the ceiling is reported, not enforced', () {
    // Austin's call, 2026-08-26, and it reversed what #1371 shipped: this used to
    // fail the build once a suite outgrew the floor. Three reasons were given, and
    // #1380's measurement retired two of them and confirmed the third.
    // (1) "The end state is already known" — it was, and the next test still projects
    // it, but the projection under-read: 43 pages model to 336.1s and the file
    // measures 558s.
    // (2) "#1371 measured splitting as a bad trade" (+14.7s gate, +60.8s suite,
    // x2.36 CPU) — at fifteen pages. At 43 the same trade is ~-400s of wall clock for
    // the same ~+120s of CPU, on eight idle cores, so #1380 decided to split into four —
    // and then unwound that hours later, because eight idle cores is a laptop fact. The
    // 4-vCPU runner gives `flutter test` two lanes, both ~90% busy, so the wall clock a
    // split could buy back there is ~50s against ~+87s of fixed cost: **one suite**
    // (page_sweep_suites.dart's header has the five arms and the runner's numbers).
    // (3) The floor is a laptop measurement whose divisor is the rest of the test
    // tree, so it should *rise* as the suite grows — looser with age, the wrong
    // direction for a gate. Re-measured at 1,573 tests it read 145.2s, 4.6s *below*
    // #1371's, so it has not risen yet. It bit on the other axis instead: the divisor
    // also scales with the machine's lane count, and 145.2s is a five-lane figure that
    // reads ~455s on two. The concern was right about the number being fragile and wrong
    // about which way it would move.
    //
    // The print stays a print anyway, and the reason is now a different one: the red
    // would be correct, and the fix is a restructuring ticket that no PR author can
    // perform on the way past. What stays enforced is assertions 1-4 — a page silently
    // losing its `runOverflowSweep` call is a coverage loss no other test in the PR
    // gate can see, which is a different class of fact from a suite being slow.
    test(
        'reports each suite\'s projected weight against the '
        '${(kGateFloorWithoutPagesMs / 1000).toStringAsFixed(0)}s floor', () {
      for (final suite in suites) {
        // Still called, not just printed: `pageSweepSuiteWeightMs` throws on a page
        // nothing measured (assertion 4), so this line remains the check that every
        // page in the register carries a real figure.
        final weight = pageSweepSuiteWeightMs(
          suite,
          msPerCellByIdentifier: msPerCellByIdentifier,
          cellsPerPage: cellsPerPage,
        );
        expect(weight, greaterThan(0));

        final headroom = kGateFloorWithoutPagesMs - weight;
        final needed = (weight / kGateFloorWithoutPagesMs).ceil();
        // ignore: avoid_print
        print('[page sweep] ${suite.label}: '
            '${suite.caseIdentifiers.length} pages project to '
            '${(weight / 1000).toStringAsFixed(1)}s of serial pumping against a '
            '${(kGateFloorWithoutPagesMs / 1000).toStringAsFixed(1)}s floor — '
            '${headroom >= 0 ? '${(headroom / 1000).toStringAsFixed(1)}s of '
                'headroom' : 'over by ${(-headroom / 1000).toStringAsFixed(1)}s, '
                'which is at least $needed suites of similar weight'}. '
            'A projection is a floor on the cost, not an estimate: it sums measured '
            'per-page figures, and #1380 measured this file at 558s where the sum '
            'reads 336.1s. Reported only, and no split follows from it: this floor is a '
            'five-lane laptop figure, and on the 4-vCPU PR runner the whole gate is 508s '
            'with this suite alone for just its last 53s, so sharding buys ~50s and '
            'costs ~87s (§11.12).');
      }
    });

    test('the 43-page end state outgrows the modelled floor', () {
      // This one stays an assertion, because it cannot fire as a nuisance: it goes
      // red only if the pages turn out *cheap* enough that the whole split question
      // is moot — which is news worth a red, and a paragraph to delete rather than a
      // number to edit. It carried the end-state figure the deferred decision was
      // taken on. Renamed from "needs more than one suite" once #1380 measured the gate
      // on the PR runner: outgrowing the modelled floor is what this arithmetic shows,
      // and whether that means more than one suite depends on a lane count the roster
      // cannot see (§11.12). It stays because the *next* family will ask the same
      // question of its own roster.
      final inScope = roster.rows
          .where((r) => r.disposition != PageRosterDisposition.excluded)
          .toList();
      final measured = inScope
          .where((r) => r.msPerCell != null)
          .map((r) => r.msPerCell!)
          .toList()
        ..sort();
      expect(measured, isNotEmpty);
      final median = measured[measured.length ~/ 2];

      // A `-` row is weighed at the median of the measured rows for the projection
      // only — never for a suite's own weight, which is always its own pages' own
      // measurements. Dead since #1380, when the last `-` row gained a figure, and
      // kept for the next family. See page_sweep_suites.dart's header.
      final projectedMs =
          inScope.fold<double>(0, (sum, r) => sum + (r.msPerCell ?? median)) *
              cellsPerPage;

      expect(
        projectedMs,
        greaterThan(kGateFloorWithoutPagesMs),
        reason: 'at ${inScope.length} pages the sweep projects to '
            '${(projectedMs / 1000).toStringAsFixed(0)}s against a '
            '${(kGateFloorWithoutPagesMs / 1000).toStringAsFixed(0)}s floor — which '
            'is what says the split question is live, and it is a '
            'floor rather than an estimate: the file itself measured 558s the day '
            'this landed, 1.65x the model, because a page in company costs 0.45x to '
            '4.47x what it costs alone (§11.12). Live is not the same as answered: this '
            'floor is a five-lane laptop figure, and on the 4-vCPU PR runner the ratio '
            'is 1.12, so #1380 left the sweep in one suite. ${measured.length} of ${inScope.length} rows are '
            'measured — all of them, since #1380 — and '
            'the heaviest single page is '
            '${(measured.last * cellsPerPage / 1000).toStringAsFixed(1)}s and '
            'indivisible, which is 4% of the suite where #1370 read it as most of '
            'a shard.',
      );
    });
  });

  group('each assertion can fail', () {
    // Six drives over registers wrong in exactly one way. The real tree is green by
    // construction once a wave lands, so these are the only place the failure paths
    // are exercised on every run — and the discovery drives use a temp directory
    // because the shapes they check (no tag, two calls for one page) must not exist
    // in `test/page`.
    PageSweepSuite suiteOf({
      String path = 'test/page/_shared/page_surface_overflow_test.dart',
      List<String> tags = const ['layout-gate', 'overflow'],
      List<String> cases = const ['kDhcpPageCase', 'kWifiSettingsPageCase'],
      List<String> guards = const [],
    }) =>
        PageSweepSuite(
            path: path, tags: tags, caseIdentifiers: cases, guards: guards);

    late Directory temp;
    setUp(() => temp = Directory.systemTemp.createTempSync('page_sweep_'));
    tearDown(() => temp.deleteSync(recursive: true));

    test('a suite that sweeps pages with no @Tags is rejected', () {
      File('${temp.path}/rogue_test.dart').writeAsStringSync(
        'void main() { runOverflowSweep(PageSurfaceFamily(kDhcpPageCase)); }',
      );
      expect(
        () => discoverPageSweepSuites(root: temp.path),
        throwsA(isA<PageSweepSuiteFormatException>().having(
            (e) => e.message, 'message', contains('declares no @Tags'))),
      );
    });

    test('a suite that sweeps one page twice is rejected', () {
      // Double quotes in the synthetic tag list, deliberately. §4's carrier counts
      // are taken by grepping the tag annotation with its single-quoted tag names,
      // so writing that exact string anywhere in this file — in a fixture or even
      // in a comment about the fixture — makes this oracle read as an `overflow`
      // carrier it is not. Double quotes keep the count honest and prove the parser
      // accepts either quote.
      File('${temp.path}/double_test.dart').writeAsStringSync('''
@Tags(["layout-gate", "overflow"])
void main() {
  runOverflowSweep(PageSurfaceFamily(kDhcpPageCase));
  runOverflowSweep(PageSurfaceFamily(kDhcpPageCase));
}
''');
      expect(
        () => discoverPageSweepSuites(root: temp.path),
        throwsA(isA<PageSweepSuiteFormatException>()
            .having((e) => e.message, 'message', contains('twice'))),
      );
    });

    test('a tree with no page sweep at all is rejected, not read as empty', () {
      File('${temp.path}/unrelated_test.dart')
          .writeAsStringSync("void main() { test('x', () {}); }");
      expect(
        () => discoverPageSweepSuites(root: temp.path),
        throwsA(isA<PageSweepSuiteFormatException>().having(
            (e) => e.message, 'message', contains('calls PageSurfaceFamily'))),
      );
    });

    test('assertion 2 sees a declared page that nothing sweeps', () {
      final membership = pageSweepMembership(
        suites: [
          suiteOf(cases: const ['kDhcpPageCase'])
        ],
        idByIdentifier: const {
          'kDhcpPageCase': 'dhcp',
          'kWifiSettingsPageCase': 'wifi_settings',
        },
        declaredIds: {'dhcp', 'wifi_settings'},
      );
      expect(membership.unswept, ['wifi_settings (`kWifiSettingsPageCase`)']);
      expect(membership.duplicated, isEmpty);
      expect(membership.undeclared, isEmpty);
    });

    test('assertion 2 sees a page swept twice, and one swept but undeclared',
        () {
      final membership = pageSweepMembership(
        suites: [
          suiteOf(path: 'a_test.dart', cases: const ['kDhcpPageCase']),
          suiteOf(
              path: 'b_test.dart',
              cases: const ['kDhcpPageCase', 'kGhostPageCase']),
        ],
        idByIdentifier: const {'kDhcpPageCase': 'dhcp'},
        declaredIds: {'dhcp'},
      );
      expect(membership.duplicated, {
        'dhcp': ['a_test.dart', 'b_test.dart']
      });
      expect(membership.undeclared, ['`kGhostPageCase` in b_test.dart']);
      expect(membership.unswept, isEmpty);
    });

    test(
        'assertion 3 sees an unregistered guard, a misplaced one, and one that '
        'runs nowhere', () {
      final faults = pageSweepGuardFaults(
        [
          suiteOf(
            path: 'a_test.dart',
            cases: const ['kDhcpPageCase'],
            guards: const ['readability at a site nobody registered'],
          ),
          suiteOf(
            path: 'b_test.dart',
            cases: const ['kWifiSettingsPageCase'],
            guards: const ['readability at the site the pilot fixed'],
          ),
        ],
        guardPages: const {
          'readability at the site the pilot fixed': 'kDhcpPageCase',
          'readability at the site wave 1 fixed': 'kPortForwardingPageCase',
        },
      );
      expect(faults.unregistered,
          ["'readability at a site nobody registered' in a_test.dart"]);
      expect(faults.misplaced, hasLength(1));
      expect(faults.misplaced.single, contains('b_test.dart'));
      expect(faults.uncalled, ['readability at the site wave 1 fixed']);
    });

    test('assertion 4 refuses to weigh a page nothing measured', () {
      expect(
        () => pageSweepSuiteWeightMs(
          suiteOf(cases: const ['kDhcpPageCase', 'kUnmeasuredPageCase']),
          msPerCellByIdentifier: const {'kDhcpPageCase': 21.6},
          cellsPerPage: 234,
        ),
        throwsA(isA<PageSweepSuiteFormatException>().having(
            (e) => e.message, 'message', contains('nothing measured it'))),
      );
    });

    test('the modelled crossover is 30 pages, and the model is a floor', () {
      // 30 pages at the final 21.5ms/cell median: 150.9s against a 149.8s floor, and
      // 29 are under it at 145.9s. Both margins are ~1-4s, so this drive flips on any
      // edit to the median — which is the intended behaviour, because a median that
      // moved is a crossover that moved. Driven rather than asserted in prose. It
      // outlived the assertion it used to drive: the ceiling is reported now, but the
      // report is only worth reading if the arithmetic under it is pinned, and this is
      // the only place the over-the-floor branch runs at all.
      //
      // The median is 21.5 — an exact middle element of an odd 43, not a mean of two
      // middles as wave 3's even 30 forced (22.4, and 23.0 if you took the upper).
      // #1371 read 26.2 at 29 pages, wave 3 read 22.4 at 30, and #1380 reads 21.5 at
      // 43: every wave has pushed the *modelled* crossover further out, because every
      // wave added pages cheaper than the running median.
      //
      // **And every one of those readings under-states the cost, increasingly.** The
      // model sums per-page figures measured one page at a time, and until #1380 it
      // over-read by a small margin in the safe direction: at 15 pages it modelled
      // 98.6s against a measured 89.66s, 10% high. At 43 it models 336.1s against a
      // measured 558s — 40% low. The sign flipped. What #1380's per-test json shows is
      // that this is not a uniform per-cell surcharge: 30 of the 43 pages are *cheaper*
      // in company than alone (median ratio 0.70) and nine are 1.8x to 4.5x dearer,
      // with no correlation to position in the run (Pearson 0.29) and no explanation
      // (§11.12). So the real crossover is earlier than 30, this drive cannot say
      // where, and #1380's decision was taken against a measured file rather than
      // against this arithmetic.
      final heavy = suiteOf(
          cases: List.generate(30, (i) => 'kPage${i}Case'), guards: const []);
      final weight = pageSweepSuiteWeightMs(
        heavy,
        msPerCellByIdentifier: {
          for (final identifier in heavy.caseIdentifiers) identifier: 21.5
        },
        cellsPerPage: 234,
      );
      expect(weight, greaterThan(kGateFloorWithoutPagesMs));

      final under = suiteOf(cases: List.generate(29, (i) => 'kPage${i}Case'));
      expect(
        pageSweepSuiteWeightMs(
          under,
          msPerCellByIdentifier: {
            for (final identifier in under.caseIdentifiers) identifier: 21.5
          },
          cellsPerPage: 234,
        ),
        lessThan(kGateFloorWithoutPagesMs),
      );
    });
  });
}
