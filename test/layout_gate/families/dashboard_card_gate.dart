/// Everything the card sweeps do with a measurement that is not measuring it
/// (#1343): the ratchet consult, the PNG pair, the report row, the coverage
/// bookkeeping and the failure prose.
///
/// ## Why this is a second file, and an object
///
/// [runOverflowSweep] knows nothing about `known_overflows.json`,
/// `OverflowReportItem` or `build/overflow_testing/` — three of the four sweeps
/// carry none of them, and #1342's header says why an unused hook is a guess. So
/// the card port had to put them *somewhere*, and the choice was between the
/// families and here.
///
/// They are here because there are three families and one gate. `card.width`,
/// `card.normal_band` and `card.profile` share one allowlist, one report, one
/// locale set and one pair of coverage counters — the dead-entry verdict is a
/// property of the whole *run*, so it cannot be computed by any one of them (see
/// [OverflowRatchet] on why deadness is taken once). Three copies of this state
/// would be three ratchets, and an entry live in the width sweep would read as
/// dead to the profile sweep.
///
/// An object rather than the top-level fields it replaces, for one reason worth
/// the churn: the counters and the ratchet were file-private mutable globals, so
/// nothing outside a full 1,898-cell run could observe them. As an object they are
/// reachable from `dashboard_card_gate_test.dart`, which is where the arithmetic
/// of a narrowed run is now proved.
///
/// ## What deliberately stayed in the suite
///
/// `setUpAll` / `tearDownAll` and the `LIST_CARDS` early return. The gate says
/// *what* happens at the end of a run; a suite says *when*, and a helper that
/// registered its own hooks would be a second place hooks come from — the same
/// argument `page_chrome_family.dart` makes for keeping `prepareChromeHosts()` off
/// the family interface.
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';

import '../../util/dashboard/dashboard_card_probe.dart';
import '../../util/dashboard/dashboard_overflow_report_generator.dart';
import '../incident.dart';
import '../locale_tag.dart';
import '../ratchet.dart';
import '../sweep.dart';
import 'dashboard_card_family.dart';

/// Target locales parsed from `--dart-define=LOCALE=...` or the environment.
/// Defaults to all shipped locales when no filter is given.
///
/// A `final`, not a getter: the enumeration below reads it once per declared cell,
/// and as a getter that was ~1,900 walks of `Platform.environment` plus ~1,900
/// filtered copies of the supported-locale list before a single cell had been
/// pumped. A top-level `final` in Dart is lazily initialised, so the parse still
/// happens on first use rather than at load — which matters, because the
/// environment is what `tool/run_overflow_test.sh` sets.
///
/// Public since #1343, because the enumeration moved into the families while the
/// coverage arithmetic stayed with the gate, and both read the same list.
final List<Locale> cardSweepLocales = _parseTargetLocales();

List<Locale> _parseTargetLocales() {
  const d = String.fromEnvironment('LOCALE', defaultValue: '');
  const d2 = String.fromEnvironment('locale', defaultValue: '');
  final env = Platform.environment;
  final filterStr = d.isNotEmpty
      ? d
      : (d2.isNotEmpty ? d2 : (env['LOCALE'] ?? env['locale'] ?? ''));

  if (filterStr.isEmpty || filterStr == 'all') {
    return AppLocalizations.supportedLocales;
  }

  final tags = filterStr.split(',').map((s) => s.trim().toLowerCase()).toSet();
  return AppLocalizations.supportedLocales.where((l) {
    final tag = localeTag(l).toLowerCase();
    final lang = l.languageCode.toLowerCase();
    return tags.contains(tag) || tags.contains(lang);
  }).toList();
}

/// Report output mode. Set this in-file to dump locally without passing
/// `--dart-define=DUMP=...`; see [cardSweepDumpMode] for the override precedence.
/// 0: default — emit nothing (fastest; what the PR gate runs)
/// 1: terse Markdown list only (build/overflow_testing/overflow_report.md)
/// 2: visual HTML report (build/overflow_testing/overflow_report.html) + PNGs
/// 3: both 1 and 2
const int _dumpMode = 0;

int get cardSweepDumpMode {
  if (_dumpMode > 0) return _dumpMode;

  const defines = [
    String.fromEnvironment('DUMP'),
    String.fromEnvironment('dump'),
    String.fromEnvironment('DUMP_MODE'),
    String.fromEnvironment('dump_mode'),
  ];
  for (final d in defines) {
    final v = int.tryParse(d);
    if (v != null && v >= 0 && v <= 3) return v;
  }

  final env = Platform.environment;
  final keys = ['DUMP', 'dump', 'DUMP_MODE', 'dump_mode'];
  for (final k in keys) {
    final val = env[k];
    if (val != null) {
      final v = int.tryParse(val);
      if (v != null && v >= 0 && v <= 3) return v;
    }
  }

  return 0;
}

/// Whether a cell needs a `RepaintBoundary` key allocated for it.
///
/// Read at *enumeration* time, unlike the rest of the dump flags: the key has to
/// be in the host the cell builds, and the cell is built before any of this is
/// judged. In the gate's default mode it is false and no cell carries one.
bool get shouldDumpCardPng => cardSweepDumpMode == 2 || cardSweepDumpMode == 3;

/// The ratchet, the report and the two counters, for one run of the card sweeps.
class CardSweepGate {
  CardSweepGate();

  /// The allowlist, re-keyed on `file:line` at #1341.
  ///
  /// Assigned by the suite's `setUpAll` through [loadRatchet], and starts empty
  /// rather than `late`: a malformed fixture throws in `setUpAll`, after which
  /// `tearDownAll` still runs, and a `late` field would raise a
  /// LateInitializationError on top of the real failure. Empty means the closing
  /// check finds nothing to say and the fixture error stays the only message.
  OverflowRatchet ratchet = OverflowRatchet.empty();

  /// Cells each family declared, by family name. Written when the family
  /// enumerates, which [runOverflowSweep] does exactly once per sweep.
  ///
  /// Keyed rather than summed, and assigned rather than added, so a family that
  /// enumerated twice cannot double its own contribution — the map is idempotent
  /// where a counter would not be.
  final Map<String, int> _declared = {};

  /// Cells that reached [judge]. The runner calls it for every measured cell,
  /// clean ones included, which is what makes the pair below mean something.
  int _measured = 0;

  final List<OverflowReportItem> _reportItems = [];

  bool get _shouldDumpMd => cardSweepDumpMode == 1 || cardSweepDumpMode == 3;
  bool get _shouldDumpHtml => cardSweepDumpMode == 2 || cardSweepDumpMode == 3;
  bool get _shouldCollectReport => cardSweepDumpMode > 0;

  int get declaredCells => _declared.values.fold(0, (n, v) => n + v);
  int get measuredCells => _measured;

  /// Throws on a fixture it cannot read — including one still carrying pre-#1341
  /// coordinate keys — and a throw in `setUpAll` fails once, as `(setUpAll)`,
  /// instead of 1,898 times. The loader this replaced printed a warning and
  /// carried on with an empty allowlist, which reads as a green gate.
  void loadRatchet() => ratchet = OverflowRatchet.fromFixture();

  void declare(String familyName, int cells) => _declared[familyName] = cells;

  /// Why this run enumerated fewer cells than the sweeps pin, if it did.
  ///
  /// Only the narrowings that are known at *declaration* time, which is when the
  /// count test runs: the two dump-tooling defines of architecture doc §5 contract
  /// 3. The third gap — a `--name` filter, which the test runner applies and the
  /// suite cannot see — is invisible until the run is over, and lives in
  /// [coverageGaps].
  List<String> enumerationGaps() {
    final allLocales = AppLocalizations.supportedLocales.length;
    return [
      if (cardSweepLocales.length != allLocales)
        '--dart-define=LOCALE selected ${cardSweepLocales.length} of '
            '$allLocales locales',
      if (minScreenFilter > 0)
        '--dart-define=MIN_SCREEN=${minScreenFilter.toStringAsFixed(0)} moved '
            'every width this sweep pumps',
    ];
  }

  /// Every reason this run measured less than the full sweep, empty when it did
  /// not. Read once, in `tearDownAll`.
  ///
  /// [enumerationGaps] plus the one only the counters can find: a `--name` filter
  /// (`tool/run_overflow_test.sh -c <card>`) is applied by the test runner and is
  /// invisible to the suite, and a cell that threw before measuring anything looks
  /// the same from here. Both answers stop the dead-entry verdict, which is the
  /// point — an entry cannot be called dead by a run that never rendered its site.
  List<String> coverageGaps() {
    return [
      ...enumerationGaps(),
      if (_measured != declaredCells)
        '$_measured of $declaredCells declared cells were measured (a --name / '
            '-c filter, or a cell that threw before measuring)',
    ];
  }

  /// The verdict for one measured cell: `null` if the gate tolerates it, else the
  /// failure line this locale contributes.
  ///
  /// This is [OverflowSurfaceFamily.judgeCell]'s whole implementation for all
  /// three card families; each passes only the two things that differ, because the
  /// three sweeps say different things about the same overflow (a popup-form width,
  /// a threshold width, a second data profile) and the message is the only place
  /// triage reads which.
  ///
  /// [subject] names the coordinate in the operator's vocabulary — it is printed
  /// verbatim in the tolerated-overflow line. [failure] receives the blocking
  /// detail and returns everything above the remediation paragraph.
  ///
  /// [withReport] is the width sweep alone. The other two sweeps' reasons for
  /// staying out of the report are in their own headers, and both survive #1343:
  /// the report's recommendation columns would advise a wider span at a
  /// coordinate that *is* a threshold, and `OverflowReportItem` has no profile
  /// dimension.
  Future<String?> judge(
    WidgetTester tester,
    CardSweepCell cell,
    OverflowCellVerdict verdict, {
    required String subject,
    required String Function(String detail) failure,
    bool withReport = false,
  }) async {
    // Counted before the early return, because a clean cell is a measured one —
    // that is exactly what makes the run's coverage complete enough for the
    // dead-entry verdict.
    _measured++;
    final significant = verdict.significant;
    if (significant.isEmpty) return null;

    final tag = cell.tag;
    // One call per cell: it records every site as live debt *and* answers which
    // incidents are not exempt. Empty = the cell is tolerated.
    final blocking = ratchet.consultCell(significant, tag);

    // [shouldDumpCardPng] is not a second condition: it is modes 2 and 3, both of
    // which are already `> 0`. The PNG pair is written from inside the report row
    // because they describe the same measurement.
    if (withReport && _shouldCollectReport) {
      await _recordReport(tester, cell, significant, blocking,
          tolerancePx: verdict.tolerancePx);
    }

    if (blocking.isEmpty) {
      // Documented + tracked: surface it but don't fail the gate.
      // ignore: avoid_print
      print(
        'KNOWN OVERFLOW (allowlisted) $subject $tag: '
        '${_trackedDetail(significant)}',
      );
      return null;
    }

    return '${failure(_blockingDetail(blocking, significant))}\n'
        '${_remediation(blocking, tag)}';
  }

  /// Report generation and the ratchet's closing direction. Returns the dead-entry
  /// failure, or null.
  ///
  /// Returned rather than `fail`ed here so the suite's `tearDownAll` is the thing
  /// that fails the run — see the library header on hooks.
  Future<String?> close() async {
    if (_shouldCollectReport) {
      await DashboardOverflowReportGenerator.generateAll(
        _reportItems,
        baseDir: 'build/overflow_testing',
        markdown: _shouldDumpMd,
        html: _shouldDumpHtml,
      );
    }

    // The ratchet's closing direction, taken **here** rather than inside each
    // cell: under a `file:line` key deadness is a property of a site over the
    // whole run, and one site can be rendered by many cells, so a cell that
    // renders it cleanly proves nothing on its own (OverflowRatchet explains the
    // trade in full, including what the old per-cell check caught and this does
    // not). Verified on a full run at #1341: declared == measured == 1,898 and
    // therefore no gap, so the closing direction is live on the gate and on CI. A
    // filtered run (`-c`, `-L`, `-m`) reports a gap and skips it.
    final gaps = coverageGaps();
    final skipped = ratchet.coverageSkipNote(gaps);
    if (skipped != null) {
      // ignore: avoid_print
      print(skipped);
    }
    return ratchet.deadEntryFailure(
      localesCovered: cardSweepLocales.map(localeTag).toSet(),
      coverageGaps: gaps,
    );
  }

  /// The grid's advice for this coordinate, the before/after PNG pair, and the
  /// report row — all of which exist only for a dump run.
  Future<void> _recordReport(
    WidgetTester tester,
    CardSweepCell cell,
    List<OverflowIncident> significant,
    List<OverflowIncident> blocking, {
    required double tolerancePx,
  }) async {
    final wc = cell.widthCase;
    final rows = cell.rows;
    final tag = cell.tag;

    final maxColsOnScreen = gridColumnsForWidth(wc.screenWidth);
    final currentColSpan = wc.columnSpan.clamp(1, maxColsOnScreen);

    final hasRightOverflow = significant.any((i) => i.side == 'right');
    final hasBottomOverflow = significant.any((i) => i.side == 'bottom');

    bool isWidthExpandable = true;
    int recCols = currentColSpan;

    if (hasRightOverflow) {
      if (currentColSpan < maxColsOnScreen) {
        recCols = math.min(currentColSpan + 1, maxColsOnScreen);
        isWidthExpandable = true;
      } else {
        recCols = currentColSpan;
        isWidthExpandable = false;
      }
    }

    final origHeight = dashboardCardHeight(rows);
    int recRows = rows;
    if (hasBottomOverflow) {
      final maxBottom = significant
          .where((i) => i.side == 'bottom')
          .fold(0.0, (m, i) => math.max(m, i.pixels));
      final targetHeight = origHeight + maxBottom + 4.0;
      recRows = calcRecommendedRows(targetHeight);
    }

    final recWidth = cardWidthAt(wc.screenWidth, recCols);
    final recHeight = dashboardCardHeight(recRows);

    bool isAdjustedClean = true;
    List<OverflowIncident> adjustedIncidents = [];

    final repaintKey = cell.repaintKey;
    if (shouldDumpCardPng && repaintKey != null) {
      final tabSuffix = cell.tabCount > 1 ? '_t${cell.tab}' : '';
      final path =
          'build/overflow_testing/png/${cell.cardId}/screen${wc.screenKey}_card${wc.widthKey}_${wc.columnSpan}x$rows${tabSuffix}_$tag.png';
      await saveCardScreenshot(tester, repaintKey, path);

      final adjustPath =
          'build/overflow_testing/png/adjust/${cell.cardId}/screen${wc.screenKey}_card${wc.widthKey}_${wc.columnSpan}x$rows${tabSuffix}_${tag}_adjusted.png';
      adjustedIncidents = await captureAdjustedCardScreenshot(
        tester,
        cardId: cell.cardId,
        screenWidth: wc.screenWidth,
        recWidth: recWidth,
        recHeight: recHeight,
        tabIndex: cell.tab,
        locale: cell.locale,
        path: adjustPath,
      );
      // The sweep's own bar, not the constant: the row puts this verdict beside the
      // cell's, and two measurements in one row have to have been judged the same
      // way.
      isAdjustedClean =
          adjustedIncidents.where((i) => i.pixels > tolerancePx).isEmpty;
    }

    if (!_shouldCollectReport) return;
    _reportItems.add(OverflowReportItem(
      cardId: cell.cardId,
      screenWidth: wc.screenWidth,
      cardWidth: wc.cardWidth,
      cardHeight: origHeight,
      columnSpan: wc.columnSpan,
      rowSpan: rows,
      widthLabel: wc.label,
      tabIndex: cell.tab,
      tabCount: cell.tabCount,
      localeTag: tag,
      incidents: significant,
      // "The gate tolerated this row", i.e. **every** significant incident in it
      // is exempt. It was a per-cell boolean while the allowlist was keyed per
      // cell; under a site key exemption is a per-incident question, and "any"
      // would let one known site colour a row green that the gate itself failed.
      // The report has one row per coordinate, so the row must carry the
      // coordinate's verdict, not a disjunction over its incidents. (Today no
      // generator reads this field — it is declared and never used in
      // `dashboard_overflow_report_generator.dart` — so the choice is about what
      // the column will mean when someone renders it, not about current output.)
      isAllowed: blocking.isEmpty,
      recCols: recCols,
      recRows: recRows,
      recWidth: recWidth,
      recHeight: recHeight,
      isWidthExpandable: isWidthExpandable,
      isAdjustedClean: isAdjustedClean,
      adjustedIncidents: adjustedIncidents,
    ));
  }

  /// `+41.0px right at lib/x.dart:9 (allowed up to 41.0px …) — legend fix #1145`
  /// for each incident.
  ///
  /// The tracking note is per **site**, not per card, because the key it hangs off
  /// is: two sites in one card can be deferred under different tickets, and one
  /// site — anything in `ui_kit_library`, any shared row widget — can be reached
  /// from several cards, where a card-keyed note would print whichever card
  /// happened to hit it.
  ///
  /// The allowance is printed alongside it because this line is the only place a
  /// tolerated overflow is ever visible: without it, "+25.9px, allowed 26.0px" and
  /// "+2.5px, allowed 26.0px" read identically, and the first is one shaping
  /// difference away from failing CI.
  String _trackedDetail(List<OverflowIncident> incidents) => incidents.map((i) {
        final entry = ratchet.exemptionFor(i.site);
        return '$i'
            '${entry == null ? '' : ' (allowed up to ${entry.allowanceLabel})'}'
            ' — ${ratchet.trackingNote(i.site)}';
      }).join(', ');

  /// The incidents the reader has to act on, and how many the fixture already
  /// covers.
  ///
  /// A cell can hold a mix: one site deferred, another new. The failure quotes the
  /// new ones — those are the work — but says the coordinate carries more, so
  /// nobody reads a one-incident message as the whole story. Under the old
  /// coordinate key the mix could not arise, because the exemption covered the
  /// whole cell.
  String _blockingDetail(
    List<OverflowIncident> blocking,
    List<OverflowIncident> significant,
  ) {
    final exempt = significant.length - blocking.length;
    return '${blocking.join(', ')}'
        '${exempt == 0 ? '' : ' (plus $exempt already allowlisted here)'}';
  }

  /// The "how to defer this" paragraph — or two, because there are two ways to be
  /// blocked and they need opposite edits.
  ///
  /// The incidents printed immediately above already end in `at <file>:<line>`
  /// ([OverflowIncident.toString]), so the failure hands the operator the exact
  /// string to paste. Since #1356 an entry carries a magnitude too, and this
  /// renders the whole line — key, locale, ceiling — from the incidents it was
  /// handed. Still one fact rather than two: the example is *derived* from the
  /// measurement rather than written out beside the grammar, so it cannot drift
  /// from what the parser accepts.
  String _remediation(List<OverflowIncident> blocking, String tag) {
    final breaches = ratchet.ceilingBreaches(blocking, tag).toSet();
    final fresh = blocking.where((i) => !breaches.contains(i)).toList();
    return [
      if (breaches.isNotEmpty) _ceilingBreachAdvice(breaches, tag),
      if (fresh.isNotEmpty) _newExemptionAdvice(fresh, tag),
    ].join('\n');
  }

  /// What to do about an overflow at a site the fixture already exempts *here*.
  ///
  /// Its own paragraph because "add the tag" is wrong advice for an entry that
  /// already names it: whoever is holding the failure would open the fixture, find
  /// the tag, and conclude the gate is broken. What changed is the size.
  String _ceilingBreachAdvice(Set<OverflowIncident> breaches, String tag) {
    final lines = breaches.map((i) {
      // Non-null by construction: `ceilingBreaches` only returns incidents whose
      // site resolved to an entry.
      final entry = ratchet.exemptionFor(i.site)!;
      return '  ${i.site} — allowed up to ${entry.allowanceLabel}, measured '
          '+${i.pixels.toStringAsFixed(1)}px';
    }).toList()
      ..sort();
    return 'Already allowlisted for "$tag", and overflowing by more than the '
        'entry permits:\n'
        '${lines.join('\n')}\n'
        'That is what a "maxOverflowPx" is for: one `file:line` is rendered by '
        'every cell that reaches it, so this can be a second, larger defect at a '
        'line whose smaller one is deferred. Fix the layout, or — if the larger '
        'overflow is deferred too — raise the ceiling and say why in that '
        'entry\'s "tracking" note.';
  }

  /// What to do about an overflow nothing exempts yet: the entry to paste.
  String _newExemptionAdvice(List<OverflowIncident> fresh, String tag) {
    // The worst magnitude per site, which is what a single ceiling has to cover.
    final worstBySite = <String, double>{};
    for (final incident in fresh) {
      final site = incident.site;
      if (site == null || !incident.pixels.isFinite) continue;
      final worst = worstBySite[site];
      if (worst == null || incident.pixels > worst) {
        worstBySite[site] = incident.pixels;
      }
    }
    // Counted directly rather than as `fresh.length - worstBySite.length`: sites
    // are deduplicated, so two blocking incidents at one site would have made the
    // difference claim an incident had no location when both did — the operator
    // would go looking for an incident the message above never printed.
    final unresolved = fresh.where((i) => i.site == null).length;
    final unparseable =
        fresh.where((i) => i.site != null && !i.pixels.isFinite).length;
    final unexemptable = [
      if (unresolved > 0)
        '$unresolved resolved no source location, and the ratchet keys on '
            '`file:line` — a null location is not a key (deliberately, see '
            'OverflowRatchet)',
      if (unparseable > 0)
        '$unparseable reported an overflow this suite could not parse, which no '
            'finite "maxOverflowPx" can cover',
    ];
    if (worstBySite.isEmpty) {
      return 'None of the incident(s) above can be allowlisted at all: '
          '${unexemptable.join('; ')}. Fix the layout.';
    }
    final keys = worstBySite.keys.toList()..sort();
    return 'Fix the layout (Flexible/Expanded/maxLines/ellipsis), or if this is '
        'knowingly deferred, add to the "allowlist" map in\n'
        '  $kKnownOverflowsFixturePath\n'
        '${keys.map((s) => '  "$s": {"locales": ["$tag"], "maxOverflowPx": ${worstBySite[s]!.ceil()}}').join('\n')}\n'
        'plus a "tracking" note under each of the same keys — the fixture refuses '
        'an exemption that has none. Each key is the source location the matching '
        'incident above ends in ("… at <file>:<line>"), not the card|width|tab '
        'coordinate this fixture used before #1341; each ceiling is that '
        'incident\'s own magnitude rounded up, with '
        '${kOverflowTolerancePx.toStringAsFixed(1)}px of shaping slack allowed on '
        'top of it.'
        '${unexemptable.isEmpty ? '' : '\nAlso: ${unexemptable.join('; ')} — '
            'those need the layout fixed.'}';
  }
}
