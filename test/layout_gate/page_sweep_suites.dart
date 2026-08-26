/// The page sweep's suite register (#1371) — which suite pumps which page, what
/// that suite costs, and the measured rule for when it has to be split.
///
/// ## Two jobs, and the first one is not about splitting at all
///
/// **1. Close the hole that exists today.** Nothing in the gate asserts that a
/// declared `PageSurfaceCase` is actually *swept*. Delete one `runOverflowSweep`
/// call from `page_surface_overflow_test.dart` and every other record keeps
/// insisting the page is covered:
///
/// - `page_surface_family_test.dart` pins `kPageSurfaceCases` exactly, so a page
///   cannot leave the *declaration* unnoticed — but a case can stay declared while
///   nothing calls `runOverflowSweep` on it.
/// - `page_roster_test.dart` asserts every `swept` roster row has a declared case
///   and back, which joins the roster to `kPageSurfaceCases` — the same list, so
///   the same blind spot.
/// - `test/fixtures/overflow_baselines/page.tsv` *would* notice: 234 rows would
///   read `no longer measured`. Nothing in the PR gate runs that diff, which is
///   what makes it the wrong place for this to be caught.
///
/// **2. Hold #1371's split rule so the next wave applies it instead of guessing.**
/// The ticket asked where the page cells should run, and the honest answer came out
/// of a three-arm A/B rather than out of the intuition the question was built on
/// (§11.10). One suite runs its own tests in sequence, so the pages in one file
/// *are* a serial block — 89.66s measured at fifteen of them — but a serial block
/// only costs wall clock once it exceeds everything it
/// runs beside, and under `--tags layout-gate` that floor is
/// **149.8s** — compiling the whole test tree, because `@Tags` is read by loading a
/// suite, and then running the other 1,500 tests the tag selects. 90s fits
/// inside 150s, so splitting the file into four shards was measured at **+14.7s on
/// the gate and +61s on `./run_tests.sh`** — slower, not faster, because four
/// suites re-pay fonts, JIT and isolate startup four times (user CPU 88s → 207s,
/// sys 17s → 71s) on cores the rest of the run already wants.
///
/// So the model is a *ceiling on the critical path*, not a shard count: a page suite
/// projected heavier than [kGateFloorWithoutPagesMs] has become the run's long pole.
/// At fifteen pages the one suite modelled to 90s against a 149.8s floor, so one
/// suite was right. `page_sweep_suites_test.dart` computes the crossover from the
/// roster's own figures rather than from this paragraph's arithmetic.
///
/// ## The decision #1371 deferred, taken: **four suites**
///
/// **#1371 deferred the shard count to the end of #1380** — reported, not enforced —
/// so that it would be taken with all 45 pages measured instead of extrapolated from
/// fifteen. All 45 are now accounted for and 43 are swept, and the answer measured
/// 2026-08-27 on an idle 10-core box is that the page sweep **has to be split, into
/// four**:
///
/// | Arm | tests | wall | user | sys |
/// |---|---|---|---|---|
/// | this suite alone, warm | 448 | **558.2s** | 320.5s | 277.2s |
/// | `--tags layout-gate`, suite present | 2,041 | **583.0s** | 553.7s | 323.0s |
/// | `--tags layout-gate`, suite held aside | 1,573 | **145.2s** | 213.7s | 53.8s |
/// | `./run_tests.sh`, suite held aside | 5,566 | **195.0s** | 228.9s | 59.7s |
/// | `./run_tests.sh`, suite present | 6,034 | **586.2s** | 580.5s | 343.3s |
///
/// Read the middle two rows first: **run by itself this one file is 95% of the whole
/// PR gate's wall clock** — 558s of 586s, and taking it out leaves 195s, so it adds
/// 391s to a 195s baseline. The gate went 145.2s → 583.0s by adding it — ×4.01 — and
/// 583.0 is 25s more than the file's own serial chain, which is the long-pole model arriving
/// exactly as §11.10 wrote it, only inverted. At fifteen pages the page sweep hid
/// inside the floor. At 43 the floor hides inside the page sweep, and everything
/// else in the gate is now free.
///
/// **What splitting costs is CPU, and the CPU is sitting idle.** The suite alone
/// draws (320.5 + 277.2) / 558.2 = **1.07 cores of ten**; the whole gate with it draws
/// 1.50. So 8.5 cores watch one serial chain for nine minutes. #1371 measured four
/// shards at +119s of user CPU (88 → 207) and that cost is *per shard*, not per page
/// — it is fonts, JIT and isolate startup — so it is the same ~+120s at 43 pages,
/// where it buys back ~400s of wall clock instead of losing 14.7s. **The same
/// measurement, taken twice, reverses.** That is why #1371 rolled the split back and
/// why #1380 takes it.
///
/// **Four, and not five**, because the floor is what a shard may hide inside:
/// 558.2 / 145.2 = 3.84, so four shards put ~140s in each, just under the floor, and
/// the gate goes back to being floor-bound near 150–190s. A fifth shard would divide
/// work that no longer costs wall clock and pay another isolate for it.
///
/// **The four-shard arm is #1371's, restored, not a new design** — §11.10 records
/// what it looked like and `kPageSweepBalanceTolerance` and
/// [kReadabilityGuardPages] are the two things it needs that already exist. It is a
/// successor ticket rather than part of #1380: it is a structural change to where
/// every page cell runs, it owes its own measured A/B at 43 pages, and it moves the
/// suite and carrier counts in four documents. [kPageSweepSuiteCount] stays 1 until
/// it lands, because that constant describes the tree and not the plan.
///
/// **What the ceiling stays is reported, not enforced**, unchanged from #1371's
/// amendment: the oracle prints each suite's projection and its headroom on every run
/// and fails on neither. The reason has changed, though. It was "the end state is
/// already readable, so a red would be an alarm clock set for a time we can read";
/// it is now "the red would be correct and there is nothing a PR author could do
/// about it" — the fix is one restructuring ticket, not something to be demanded of
/// whoever next touches a page. What stays enforced is membership: a page
/// that silently loses its `runOverflowSweep` call is a coverage loss nothing else in
/// the PR gate can see, which is a different class of fact from a suite being slow.
/// The A/B above measured that too, by accident and usefully — holding this suite
/// aside removed **468** tests from the gate, the 448 above plus the 20 in
/// `page_sweep_suites_test.dart`, whose `setUpAll` throws when no file under
/// `test/page` sweeps a page. One red, and it is this register's.
///
/// ## How a suite is found
///
/// By **content**, not by a path list: any `*_test.dart` under
/// [kPageSweepSuiteRoot] that calls `PageSurfaceFamily(...)` is a page sweep suite.
/// A hard-coded path can go stale in silence — a wave that adds a second suite and
/// forgets to register it would be invisible, which is the same class of bug this
/// file exists to close. It reads them as **source**, for the reason
/// `page_roster.dart` gives about its own join: a test cannot see another suite's
/// `main()`, because each suite is its own isolate. Parsing what the file *says* is
/// the only static answer, and it is the technique already in use here —
/// `page_roster.dart` reads 45 view files to find where a class is declared.
///
/// ## The weighting rule, and what happens when a `-` row gains a figure
///
/// A suite's weight is the sum of its pages' measured `ms_per_cell` from
/// `test/fixtures/page_roster.tsv`, times the cells one page contributes (234),
/// plus [kReadabilityGuardWeightMs] per readability guard it holds. Nothing here is
/// interpolated: **a `-` row cannot enter a suite at all**, because
/// `page_roster.dart` refuses a `swept` row with no figure, so a page is measured
/// before it can be declared and is weighed by its own measurement from its first
/// green run.
///
/// What a queued `-` row gaining a figure moves is therefore *when the ceiling is
/// reached* — never a page's own contribution, which was always its own
/// measurement. **Since #1380 no row carries `-` at all**: 43 of the 45 are swept and
/// measured and the other two are excluded, so the median-substitution branch in
/// `page_sweep_suites_test.dart`'s end-state projection is now dead code kept for the
/// next family. Every figure the oracle prints is a measurement, and it was already
/// only ever adding up what was measured — the median never entered a suite's own
/// weight, only the projection.
library;

import 'dart:io';

/// Where a page sweep suite may live — the tree that holds tests named after the
/// code under test.
///
/// Deliberately not the repo root: `test/layout_gate/families/` also names
/// `PageSurfaceFamily`, in the family itself and in the family's oracle, and
/// neither pumps a sweep.
const String kPageSweepSuiteRoot = 'test/page';

/// Where the case constants are declared — the file the identifier → id map is
/// read out of.
const String kPageSurfaceCasesPath =
    'test/layout_gate/families/page_surface_cases.dart';

/// How many suites the page sweep runs in today.
///
/// Pinned rather than derived, the same way `kPageViewCount` is pinned in
/// `page_roster.dart`: the count is a decision taken against a measurement, so it
/// should be an edit that says so rather than a number the tree can change by
/// accident.
///
/// **One, and the next edit to this line is four.** #1371 measured the alternative
/// rather than assuming it: four cost-balanced shards cost +14.7s on
/// `--tags layout-gate` and +61s on `./run_tests.sh` at the fifteen pages of the
/// day it was measured,
/// because the page sweep's 90s of serial pumping already fits inside the 149.8s
/// the rest of that selection takes. Raising this number is only correct once
/// [kGateFloorWithoutPagesMs] is the binding constraint — and **since #1380 it is**:
/// 43 pages measure 558s against a 145.2s floor, so the header's decision is taken
/// and the count is four. It still reads 1 here because this constant describes the
/// tree, and the tree has one file until the restructuring ticket moves the
/// `runOverflowSweep` calls. Editing it before then turns assertion 1 red and moves
/// no cell.
const int kPageSweepSuiteCount = 1;

/// The wall clock `--tags layout-gate` spends with no page cells in it, in
/// milliseconds — the ceiling a page suite's serial time is reported against.
///
/// **Measured 2026-08-26 for #1371**, three arms in one session on an idle box:
/// with the page suite and its oracle held aside the gate is 1,500 tests in
/// **149.79s**; with the suite in place 1,652 tests in 195.41s and 197.69s. So the
/// page work costs +46.8s of wall and the floor is what it overlaps with — the whole
/// test tree to compile plus 1,500 other tests to run.
///
/// This is the right ceiling because it is what a page suite *competes* with. A
/// suite lighter than the floor is hidden by it and costs only CPU; a suite heavier
/// than the floor is the run's long pole and every second of it is a second on the
/// gate. Splitting converts wall clock into CPU at a poor rate (§11.10's four-shard
/// arm), so it is worth doing exactly when the thing being converted has become the
/// constraint, and not before.
///
/// Re-measure it rather than trusting it if the *rest* of the gate changes shape —
/// the number is a property of the whole test tree and the other 1,500 tests, both
/// of which grow. A floor that rose without being re-measured would hide a page
/// suite that had genuinely become the long pole.
///
/// **Re-measured 2026-08-27 for #1380 and kept unchanged**: the same arm is now
/// 1,573 tests in **145.20s** — 4.6s *lower* at 73 more tests, which is inside the
/// ±14s session noise §1.2 measures and is the opposite of the direction the
/// paragraph above worries about. So the floor did not rise while the suite grew,
/// and the constant stays at #1371's figure rather than being edited to the newer
/// reading: it is the more conservative of the two, every projection published in
/// this epic is stated against it, and re-baselining a ceiling to a 3% noise band
/// would make two tickets' numbers incomparable for nothing.
const double kGateFloorWithoutPagesMs = 149790;

/// What one readability guard group adds to its suite, in milliseconds.
///
/// **Re-derived for #1380's thirteen groups.** The unit underneath it is unchanged:
/// §11.2's measurement of the pilot's guard, 52 pumps in 3.57s, **68.7ms a pump** —
/// twice a swept cell, because a guard pumps only the narrowest content boxes this
/// family visits. What changed is the multiplier. [pageSweepSuiteWeightMs] bills this
/// once per guard *group*, and a group is no longer one test: the thirteen groups hold
/// **eighteen tests and 845 pumps**, and 845 / 13 = 65 pumps a group, so 65 × 68.7 =
/// 4,465. The pump counts are each `widths × locales`, readable in the guard's own
/// loops: 52 for `dhcp`, `port_forwarding`, `advanced_settings`, `internet_settings`
/// and `local_network`; 34 for `unified_diagnostics`, `firmware_update`,
/// `router_assistant` and `test_console`, which read all 26 locales at 320px and one
/// locale at each of the other eight widths; 78 for `instant_privacy` and
/// `system_log`; 133 across `admin`'s three tests and 160 across `apps`' four.
///
/// So this is a **mean, not a bound**, and it is exact at the only granularity the
/// file uses it: 13 × 4,465 = 58.0s, which is what 845 pumps cost. Per group it is
/// wrong in both directions — `apps` runs 2.5× it, the four 34-pump guards about half
/// — and that starts to matter only when a split puts guards in different suites,
/// which is what [kReadabilityGuardPages] exists to make survivable.
///
/// This doc used to promise the other fix: "if a future wave puts three guards in one
/// group, correct this rather than widening the note." Wave 4 put three in `admin` and
/// four in `apps`, and the promised correction — a per-group pump count in this
/// register — was **reconsidered and not taken.** A pump count is a hand-copied
/// integer with no verifier, and this wave's own finding is that an unverified column
/// drifts: §11.12 records #1370's `needs_fixture` reading 13 where the truth was 18.
/// A mean re-derived from arithmetic anyone can redo from the guards' loops keeps the
/// suite total exact and adds nothing new to drift. The previous value, 3,570, was
/// this same unit at one pump count per group; re-derive it again when the guard set
/// changes shape rather than trusting it.
const double kReadabilityGuardWeightMs = 4465;

/// Which page each readability guard pumps, keyed by the guard's `group` title.
///
/// Keyed by prose, which is brittle on purpose: a guard pumps one page's fixture,
/// so its weight belongs to whichever suite holds that page, and if the title is
/// reworded the pairing has to be re-stated rather than quietly lost. The oracle
/// asserts every entry here is found, so a reword fails loudly in one place.
///
/// This is also the map that makes a future split safe. Rule 4 pairs a guard with
/// the *site* an overflow fix changed, so when the sweep is finally split the guard
/// has to travel with its page — otherwise it measures a page that is no longer
/// beside it, and its 4.5s is charged to the wrong suite. That stops being
/// hypothetical at the four suites #1380 decided on: thirteen groups over four shards
/// is 58.0s that has to land in the shard holding each guard's page.
/// Wave 4 fixed fourteen coordinates on eleven pages and so declares **eleven
/// groups holding sixteen tests** — thirteen groups and eighteen tests below, with the
/// pilot's and wave 1's. The count of groups follows the count of *pages*, not of
/// coordinates, and that is not a naming
/// choice: this map holds one page per title, and a group is billed once by
/// [pageSweepSuiteWeightMs] — so sixteen tests under one wave-level title would be
/// unregisterable *and* would bill eleven fixtures as one, while one group per
/// coordinate would bill `admin`'s fixture twice and `apps`' three times.
const Map<String, String> kReadabilityGuardPages = {
  'readability at the site the pilot fixed': 'kDhcpPageCase',
  'readability at the site wave 1 fixed': 'kPortForwardingPageCase',
  'readability at the site wave 4 fixed in advanced_settings':
      'kAdvancedSettingsPageCase',
  'readability at the site wave 4 fixed in unified_diagnostics':
      'kUnifiedDiagnosticsPageCase',
  'readability at the site wave 4 fixed in firmware_update':
      'kFirmwareUpdatePageCase',
  'readability at the site wave 4 fixed in router_assistant':
      'kRouterAssistantPageCase',
  'readability at the site wave 4 fixed in test_console':
      'kTestConsolePageCase',
  // Two guards, one page: `admin` is where the wave's sixth and seventh fixes both
  // landed, and they are in one group because the register keys on the group name
  // rather than on the test. Splitting them into two groups would say the page had
  // two independent reasons to be guarded, when it has one page and two sites.
  'readability at the site wave 4 fixed in admin': 'kAdminPageCase',
  // Four guards, one page, and the plural in the group name is deliberate: `apps`
  // took three `lib/` fixes — a tablet band, a mobile card extent and a heading row
  // — plus the column-count shape guard that keeps the first of them honest. Same
  // reason as `admin` for keeping them in one group: the register bills one fixture
  // per group title, so four groups would bill this page four times.
  'readability at the sites wave 4 fixed in apps': 'kAppsPageCase',
  'readability at the site wave 4 fixed in instant_privacy':
      'kInstantPrivacyPageCase',
  'readability at the site wave 4 fixed in internet_settings':
      'kInternetSettingsPageCase',
  'readability at the site wave 4 fixed in local_network':
      'kLocalNetworkPageCase',
  'readability at the site wave 4 fixed in system_log': 'kSystemLogPageCase',
};

/// How far suites may sit from each other's weight once there is more than one.
///
/// ±25%, and the number is a decision rather than a measurement: it is loose
/// enough that a page's own ±40% cost noise (`page_roster.tsv`'s `# basis-note`)
/// cannot trip it on its own, and tight enough that no suite can quietly grow into
/// the run's long pole while the others idle. Vacuous at
/// [kPageSweepSuiteCount] == 1 — one suite is its own mean — and that is the point:
/// it starts binding on the day the split happens, with no edit needed then.
const double kPageSweepBalanceTolerance = 0.25;

/// A suite register that cannot be read.
///
/// Separate from [FormatException] for the reason `page_roster.dart` gives about
/// its own exception: a caller can tell "the page suites are unreadable" apart from
/// any other parse failure in the same run — and an unreadable suite must never be
/// read as a suite with no pages, which would satisfy every assertion below.
class PageSweepSuiteFormatException implements Exception {
  PageSweepSuiteFormatException(this.message);

  final String message;

  @override
  String toString() => 'PageSweepSuiteFormatException: $message';
}

/// One page sweep suite, as its source declares itself.
class PageSweepSuite {
  PageSweepSuite({
    required this.path,
    required this.tags,
    required this.caseIdentifiers,
    required this.guards,
  });

  /// Repo-relative, posix-separated.
  final String path;

  /// What `@Tags([...])` lists. `layout-gate` is what makes the suite PR-blocking
  /// and `overflow` is what puts it in the pre-commit selector, so an omission here
  /// is a suite that runs somewhere smaller than it claims.
  final List<String> tags;

  /// The `kXxxPageCase` identifiers this suite passes to `PageSurfaceFamily`, in
  /// source order.
  final List<String> caseIdentifiers;

  /// The readability-guard group titles this suite declares, in source order.
  final List<String> guards;

  /// `page_surface_overflow_test.dart` — what a failure calls this suite.
  String get label => path.split('/').last;
}

final RegExp _tagsPattern = RegExp(r'@Tags\(\s*\[([^\]]*)\]\s*\)');
final RegExp _familyPattern = RegExp(r'PageSurfaceFamily\(\s*(k\w+)\s*\)');
final RegExp _guardPattern = RegExp(r"group\(\s*'([^']*readability[^']*)'");
final RegExp _casePattern = RegExp(
  r"^final (k\w+) = PageSurfaceCase\(\s*\n\s*id: '([^']+)'",
  multiLine: true,
);

/// Every page sweep suite under [root], in path order.
///
/// A suite is a `*_test.dart` file that calls `PageSurfaceFamily(...)`. Found by
/// content so that a second suite cannot arrive unregistered — see the header.
List<PageSweepSuite> discoverPageSweepSuites({
  String root = kPageSweepSuiteRoot,
}) {
  final directory = Directory(root);
  if (!directory.existsSync()) {
    throw PageSweepSuiteFormatException(
      '$root does not exist, so this ran somewhere other than the app root. An '
      'empty result here would read as "no page is swept", which every assertion '
      'in page_sweep_suites_test.dart would then pass vacuously.',
    );
  }

  final suites = <PageSweepSuite>[];
  final paths = directory
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .map((f) => f.path.replaceAll('\\', '/'))
      .where((p) => p.endsWith('_test.dart'))
      .toList()
    ..sort();

  for (final path in paths) {
    final source = File(path).readAsStringSync();
    final identifiers =
        _familyPattern.allMatches(source).map((m) => m.group(1)!).toList();
    if (identifiers.isEmpty) continue;

    final tagsMatch = _tagsPattern.firstMatch(source);
    if (tagsMatch == null) {
      throw PageSweepSuiteFormatException(
        '$path sweeps pages and declares no @Tags(...). A suite with no '
        '`layout-gate` runs in no selection at all — not the PR gate, not the '
        'pre-commit selector — and its pages would read as swept in every record '
        'that lists them.',
      );
    }
    final tags = tagsMatch
        .group(1)!
        .split(',')
        .map((t) => t.trim().replaceAll("'", '').replaceAll('"', ''))
        .where((t) => t.isNotEmpty)
        .toList();

    final seen = <String>{};
    for (final identifier in identifiers) {
      if (!seen.add(identifier)) {
        throw PageSweepSuiteFormatException(
          '$path sweeps $identifier twice. Two calls for one page emit the same '
          'cell ids twice, which the baseline extractor rejects as "measured '
          'twice" — but only at capture time, and nothing in the PR gate '
          'captures.',
        );
      }
    }

    suites.add(PageSweepSuite(
      path: path,
      tags: tags,
      caseIdentifiers: identifiers,
      guards: _guardPattern.allMatches(source).map((m) => m.group(1)!).toList(),
    ));
  }

  if (suites.isEmpty) {
    throw PageSweepSuiteFormatException(
      'no *_test.dart under $root calls PageSurfaceFamily(...). Either the page '
      'sweep moved out of that tree, or the call spelling changed — this file '
      'parses `PageSurfaceFamily(kXxxPageCase)`. Every page it swept is out of '
      'the gate either way.',
    );
  }
  return suites;
}

/// `kDhcpPageCase` → `dhcp`, read out of [path].
///
/// The oracle needs the *id* to reach a page's roster row (via the case's widget
/// type), and a suite file names only the identifier. One regex over one file, with
/// the oracle asserting every declared case resolves — so a change to how the cases
/// are written fails loudly here instead of silently shrinking the map.
Map<String, String> pageCaseIdsByIdentifier({
  String path = kPageSurfaceCasesPath,
}) {
  final file = File(path);
  if (!file.existsSync()) {
    throw PageSweepSuiteFormatException(
      '$path does not exist, so no suite\'s membership can be resolved to a '
      'page. If the cases moved, move kPageSurfaceCasesPath with them.',
    );
  }
  final source = file.readAsStringSync();
  final byIdentifier = <String, String>{};
  for (final match in _casePattern.allMatches(source)) {
    byIdentifier[match.group(1)!] = match.group(2)!;
  }
  if (byIdentifier.isEmpty) {
    throw PageSweepSuiteFormatException(
      '$path declares no `final kXxx = PageSurfaceCase(\\n  id: \'…\'` at all. '
      'The declaration shape changed; this map is what joins a suite to a roster '
      'row, and an empty one would make every membership assertion pass against '
      'nothing.',
    );
  }
  return byIdentifier;
}

/// What a membership check found — the answer to "is every declared page swept
/// exactly once, and does every swept page exist".
///
/// Returned as three lists rather than thrown one at a time so a wave that moved
/// several pages sees every fault in one run. All three empty is the only healthy
/// state.
class PageSweepMembership {
  PageSweepMembership({
    required this.unswept,
    required this.duplicated,
    required this.undeclared,
  });

  /// Declared in `kPageSurfaceCases` and swept by no suite — the hole this file
  /// exists to close. Formatted `id (`identifier`)`.
  final List<String> unswept;

  /// Swept by more than one suite: id → the suite labels holding it.
  final Map<String, List<String>> duplicated;

  /// Swept by a suite and not declared as a case — a sweep nothing pins, so the
  /// family oracle's exact-list check never sees it.
  final List<String> undeclared;

  bool get isClean =>
      unswept.isEmpty && duplicated.isEmpty && undeclared.isEmpty;
}

/// Join [suites] to the declared cases, both directions.
///
/// [idByIdentifier] is [pageCaseIdsByIdentifier]'s output; [declaredIds] is
/// `kPageSurfaceCases.map((c) => c.id)`. Kept as a function over its inputs rather
/// than reading the tree itself, so `page_sweep_suites_test.dart` can drive it over
/// a register that is wrong in exactly one way — the discipline
/// `page_roster_test.dart` records under *Red before green, permanently*.
PageSweepMembership pageSweepMembership({
  required List<PageSweepSuite> suites,
  required Map<String, String> idByIdentifier,
  required Set<String> declaredIds,
}) {
  final holdersByIdentifier = <String, List<String>>{};
  for (final suite in suites) {
    for (final identifier in suite.caseIdentifiers) {
      holdersByIdentifier.putIfAbsent(identifier, () => []).add(suite.label);
    }
  }
  final identifierById = {
    for (final entry in idByIdentifier.entries) entry.value: entry.key,
  };

  final unswept = <String>[];
  final duplicated = <String, List<String>>{};
  for (final id in declaredIds) {
    final identifier = identifierById[id];
    final holders = holdersByIdentifier[identifier] ?? const <String>[];
    if (holders.isEmpty) {
      unswept.add('$id (`$identifier`)');
    } else if (holders.length > 1) {
      duplicated[id] = holders;
    }
  }

  final undeclared = <String>[];
  for (final suite in suites) {
    for (final identifier in suite.caseIdentifiers) {
      final id = idByIdentifier[identifier];
      if (id == null || !declaredIds.contains(id)) {
        undeclared.add('`$identifier` in ${suite.label}');
      }
    }
  }

  return PageSweepMembership(
    unswept: unswept..sort(),
    duplicated: duplicated,
    undeclared: undeclared..sort(),
  );
}

/// Everything wrong with where the readability guards sit.
class PageSweepGuardFaults {
  PageSweepGuardFaults({
    required this.unregistered,
    required this.misplaced,
    required this.uncalled,
  });

  /// A guard group found in a suite and absent from [kReadabilityGuardPages], so
  /// nothing knows which page it pumps.
  final List<String> unregistered;

  /// A guard in a suite that does not sweep the page the guard pumps.
  final List<String> misplaced;

  /// Registered and declared by no suite — the readability half of a fix that left
  /// the gate while the overflow half stayed green, because a wrap does not
  /// overflow.
  final List<String> uncalled;

  bool get isClean =>
      unregistered.isEmpty && misplaced.isEmpty && uncalled.isEmpty;
}

/// Check every guard against the page it pumps.
///
/// Vacuous-looking at one suite and deliberately kept anyway: it is what makes a
/// split safe on the day it happens, and a reworded group title has to fail
/// somewhere.
PageSweepGuardFaults pageSweepGuardFaults(
  List<PageSweepSuite> suites, {
  Map<String, String> guardPages = kReadabilityGuardPages,
}) {
  final unregistered = <String>[];
  final misplaced = <String>[];
  for (final suite in suites) {
    for (final guard in suite.guards) {
      final identifier = guardPages[guard];
      if (identifier == null) {
        unregistered.add("'$guard' in ${suite.label}");
        continue;
      }
      if (!suite.caseIdentifiers.contains(identifier)) {
        misplaced.add("'$guard' pumps $identifier and runs in ${suite.label}, "
            'which does not sweep it');
      }
    }
  }
  final declared = suites.expand((s) => s.guards).toSet();
  return PageSweepGuardFaults(
    unregistered: unregistered..sort(),
    misplaced: misplaced..sort(),
    uncalled: guardPages.keys.where((g) => !declared.contains(g)).toList()
      ..sort(),
  );
}

/// What [suite] is projected to spend serially, in milliseconds.
///
/// [msPerCellByIdentifier] comes from the roster, keyed the way a suite names its
/// pages. A missing key throws rather than counting as zero: a page whose cost is
/// unknown would make its suite read lighter than it is, and a reported number that
/// understates itself is worse than one that is absent.
double pageSweepSuiteWeightMs(
  PageSweepSuite suite, {
  required Map<String, double> msPerCellByIdentifier,
  required int cellsPerPage,
}) {
  var total = suite.guards.length * kReadabilityGuardWeightMs;
  for (final identifier in suite.caseIdentifiers) {
    final msPerCell = msPerCellByIdentifier[identifier];
    if (msPerCell == null) {
      throw PageSweepSuiteFormatException(
        '${suite.path} sweeps $identifier and nothing measured it. A swept page '
        'always carries a figure — page_roster.dart rejects a `swept` row '
        'without one — so this is a join that broke, not a page that is cheap.',
      );
    }
    total += msPerCell * cellsPerPage;
  }
  return total;
}
