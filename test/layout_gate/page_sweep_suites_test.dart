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
/// assuming it: the page sweep **stays one file**, because four cost-balanced shards
/// cost +14.7s on `--tags layout-gate` and +61s on `./run_tests.sh` at today's
/// fifteen pages (§11.10). So this oracle is not the bookkeeping a split needed — it
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
/// Delete one of the fifteen calls today and every record above still calls the page
/// covered. That is what assertion 2 is for.
///
/// ## The five assertions
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
/// 5. **One suite is still under the measured ceiling.** The gate spends 149.79s
///    with no page cells in it; a page suite lighter than that is hidden inside it
///    and costs only CPU, and a heavier one is the run's long pole where every
///    second is a second on the gate. This is the assertion that says *split now*,
///    at roughly 23 pages, instead of leaving a future wave to re-derive #1371.
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
    test('$kPageSweepSuiteRoot holds exactly $kPageSweepSuiteCount page sweep '
        'suite(s)', () {
      expect(
        suites.map((s) => s.path).toList(),
        hasLength(kPageSweepSuiteCount),
        reason: 'kPageSweepSuiteCount is pinned because the number is a decision '
            'taken against a measurement (§11.10), not a property of the tree. '
            'Found: ${suites.map((s) => s.path).join(', ')}. If a suite was added '
            'deliberately, move the constant and read assertion 5 — the count '
            'follows the ceiling. If one appeared by accident, it is a second '
            'sweep of pages nobody registered.',
      );
    });

    test('every suite carries layout-gate and overflow', () {
      for (final suite in suites) {
        expect(
          suite.tags,
          containsAll(<String>['layout-gate', 'overflow']),
          reason: '${suite.path} lists ${suite.tags}. `layout-gate` is what makes '
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
        reason: 'these pages are swept more than once, which emits the same cell '
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
            'page across a split, and its 3.6s is charged to whichever suite '
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
            reason: '$identifier is swept by ${suite.label} and has no measured '
                'ms/cell in ${roster.source}. A `swept` row cannot omit the '
                'figure — page_roster.dart rejects that — so this is a join that '
                'broke rather than a page that is free.',
          );
        }
      }
    });

    test('every suite is within '
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
        // cannot be split and gets a suite to itself. `usp_sliver_dashboard_view` at
        // 315.4ms/cell — 1m14s alone — is the page this exists for, and the reason
        // §11.10 cannot promise balance at 43 pages.
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

  group('assertion 5: one suite is still under the measured ceiling', () {
    test('no page suite is heavier than the gate without pages '
        '(${(kGateFloorWithoutPagesMs / 1000).toStringAsFixed(0)}s)', () {
      for (final suite in suites) {
        final weight = pageSweepSuiteWeightMs(
          suite,
          msPerCellByIdentifier: msPerCellByIdentifier,
          cellsPerPage: cellsPerPage,
        );
        final needed = (weight / kGateFloorWithoutPagesMs).ceil();
        expect(
          weight,
          lessThanOrEqualTo(kGateFloorWithoutPagesMs),
          reason: '${suite.label} projects to '
              '${(weight / 1000).toStringAsFixed(0)}s of serial pumping over '
              '${suite.caseIdentifiers.length} pages, and `--tags layout-gate` '
              'takes ${(kGateFloorWithoutPagesMs / 1000).toStringAsFixed(0)}s '
              'with no page cells in it (measured 2026-08-26, #1371). Past that '
              'floor the suite stops hiding inside the rest of the run and '
              'becomes its long pole, so splitting starts to buy wall clock '
              'instead of only spending CPU — which is the one condition §11.10 '
              'set for splitting. Split it into about $needed suites of similar '
              'measured weight, keep each guard with its page, raise '
              'kPageSweepSuiteCount, and record the new figures in §11.10.',
        );
      }
    });

    test('the 43-page end state still needs more than one suite', () {
      // Not a tautology and not decoration: if this ever goes the other way, every
      // page the epic will ever onboard fits under the ceiling, and §11.10's split
      // rule is dead rather than pending — which is a paragraph to delete, not a
      // number to edit. It is also where a queued `-` row gaining a large figure
      // shows up: the projection moves, this stays red, and the ceiling assertion
      // above is what eventually trips.
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
      // measurements. See page_sweep_suites.dart's header.
      final projectedMs =
          inScope.fold<double>(0, (sum, r) => sum + (r.msPerCell ?? median)) *
              cellsPerPage;

      expect(
        projectedMs,
        greaterThan(kGateFloorWithoutPagesMs),
        reason: 'at ${inScope.length} pages the sweep projects to '
            '${(projectedMs / 1000).toStringAsFixed(0)}s against a '
            '${(kGateFloorWithoutPagesMs / 1000).toStringAsFixed(0)}s floor — '
            'that is why §11.10 keeps a split rule at all rather than declaring '
            'one file permanent. ${measured.length} of ${inScope.length} rows are '
            'measured; the rest are projected at the ${median}ms/cell median, and '
            'the heaviest measured page alone is '
            '${(measured.last * cellsPerPage / 1000).toStringAsFixed(0)}s and '
            'indivisible.',
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
        throwsA(isA<PageSweepSuiteFormatException>().having((e) => e.message,
            'message', contains('calls PageSurfaceFamily'))),
      );
    });

    test('assertion 2 sees a declared page that nothing sweeps', () {
      final membership = pageSweepMembership(
        suites: [suiteOf(cases: const ['kDhcpPageCase'])],
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

    test('assertion 3 sees an unregistered guard, a misplaced one, and one that '
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
        throwsA(isA<PageSweepSuiteFormatException>().having((e) => e.message,
            'message', contains('nothing measured it'))),
      );
    });

    test('assertion 5 trips once a suite outgrows the ceiling', () {
      // 26 pages at the measured 26.2ms/cell median: 159s against a 149.8s floor.
      // The arithmetic §11.10 calls "roughly 23 pages", driven rather than asserted
      // in prose.
      final heavy = suiteOf(
          cases: List.generate(26, (i) => 'kPage${i}Case'), guards: const []);
      final weight = pageSweepSuiteWeightMs(
        heavy,
        msPerCellByIdentifier: {
          for (final identifier in heavy.caseIdentifiers) identifier: 26.2
        },
        cellsPerPage: 234,
      );
      expect(weight, greaterThan(kGateFloorWithoutPagesMs));

      // ...and today's fifteen, at the same median, are comfortably under it.
      final today = suiteOf(cases: List.generate(15, (i) => 'kPage${i}Case'));
      expect(
        pageSweepSuiteWeightMs(
          today,
          msPerCellByIdentifier: {
            for (final identifier in today.caseIdentifiers) identifier: 26.2
          },
          cellsPerPage: 234,
        ),
        lessThan(kGateFloorWithoutPagesMs),
      );
    });
  });
}
