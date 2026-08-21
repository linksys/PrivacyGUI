@Tags(['layout-gate', 'overflow'])
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';

import '../../../layout_gate/ratchet.dart';
import '../../../util/app_test_fonts.dart';
import '../../../util/dashboard/card_data_profiles.dart';
import '../../../util/dashboard/dashboard_card_probe.dart';
import '../../../util/dashboard/dashboard_overflow_report_generator.dart';
import '../../../util/overflow_baseline.dart';
import '../../../util/overflow_probe.dart';

/// Defensive RenderFlex-overflow gate for every dashboard card (#1183).
///
/// WHY THIS TEST EXISTS
///   The golden pipeline already *detects* overflow, but it can't *gate* PRs:
///   goldens are excluded from the PR test command, and overflow is recorded as
///   a silent warning rather than a failure. It also has coverage holes — it
///   screenshots only the default tab, at fixed widths, and doesn't cover every
///   card. The #1145 Network Health legend overflow slipped through all three.
///
/// WHAT IT DOES DIFFERENTLY
///   * Data-driven over [UspWidgetSpecs.all] — the app's own card registry — so
///     new cards are gated automatically, including ones with no golden.
///   * Pumps each card at the **real pixel widths the production grid yields**
///     (see [widthCasesFor]): the narrowest realization of its min / preferred
///     / max column span. Overflow is monotonic in width and height-independent
///     (measured), so the narrowest realization of each span is that span's
///     worst case. That narrowest width is found by **enumerating** the
///     supported screen-width range (`kMinSupportedScreenWidth` upward), not by
///     sampling a list of screen widths — so the worst case is guaranteed by
///     construction rather than asserted (#1225).
///   * **Sweeps every tab** (via [cardTabIndexProvider], not geometric taps),
///     so overflow that only appears on a non-default tab is caught — several
///     cards overflow *worse* on a non-default tab than on tab 0.
///   * **One pump per test** — Flutter reports each RenderFlex's overflow only
///     once per render-object lifetime, so multi-pump sweeps silently drop all
///     but the first. Every (card, width, tab, locale) is its own test.
///   * Runs under **every shipped locale** (all 26), so script-specific width
///     blowups (German/Finnish compounds, CJK/Thai glyphs, Arabic RTL) are all
///     covered instead of a hand-picked Latin sample.
///   * Loads the **real fonts** first (see [loadAppFonts]) so text widths — and
///     therefore overflow — are measured accurately, not with the Ahem block.
///
/// WHY IT GATES PRs
///   Tagged `layout-gate`, which is NOT in `run_tests.sh`'s
///   `--exclude-tags="golden||loc||ui"` blacklist, so the PR gate runs it and a
///   failure blocks the PR. (Do not retag it golden/ui/loc — it would silently
///   drop out of the gate.) It also carries `overflow` (#1336), the narrower
///   selector `flutter test --tags overflow` uses to run the four sweeps alone.

/// Locale identity used as the allowlist's locale tag and in test names. Keeps
/// the country code so regional variants stay distinct (`zh` vs `zh_TW`, `fr` vs
/// `fr_CA`) — they can differ in label length and must be tracked separately.
///
/// Since #1341 the *key* is the overflow's `file:line`; the locale is the value
/// side of the entry. Both halves still have to be exact, and the tags are what
/// the ratchet compares against the run's covered locale set.
String _localeTag(Locale l) => l.countryCode == null || l.countryCode!.isEmpty
    ? l.languageCode
    : '${l.languageCode}_${l.countryCode}';

/// Target locales parsed from --dart-define=LOCALE=... or environment variables.
/// Defaults to all shipped locales if no filter is provided.
List<Locale> get _targetLocales {
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
    final tag = _localeTag(l).toLowerCase();
    final lang = l.languageCode.toLowerCase();
    return tags.contains(tag) || tags.contains(lang);
  }).toList();
}

/// The gate's tolerance, now shared with the satellite suites so the two cannot
/// drift apart — see [kOverflowTolerancePx] for why it is 2.0 (#1270).
const double _tolerancePx = kOverflowTolerancePx;

/// The allowlist, re-keyed on `file:line` at #1341.
///
/// Was ~80 lines of private, coordinate-keyed helpers in this file
/// (`_isAllowlisted` / `_failIfDeadExemption` / a `catch`-and-print loader); is
/// now [OverflowRatchet], which has its own oracle at
/// `test/layout_gate/ratchet_test.dart` and can be proved to report a dead entry
/// without standing a 1,898-cell sweep up. Read that class for why the key is a
/// source location, why a null site can never be exempted, and why the
/// dead-entry verdict is taken once for the whole run rather than per cell.
///
/// Not `late final`: [setUpAll] overwrites it, and if the fixture is malformed
/// that setUpAll throws — after which `tearDownAll` still runs, and a `late`
/// field would raise a LateInitializationError on top of the real failure.
/// Starting empty means the closing check finds nothing to say and the fixture
/// error stays the only message.
OverflowRatchet _ratchet = OverflowRatchet.empty();

/// Cells that consult the ratchet: counted as they are *declared* in `main()`,
/// and again as they are *measured* at run time.
///
/// The pair is the only mechanism this file has for noticing that a `--name`
/// filter (which `tool/run_overflow_test.sh -c <card>` passes) narrowed the run,
/// because a name filter is applied by the test runner and is invisible to the
/// suite. It also catches a cell that threw before it measured anything. Both
/// answers feed [_coverageGaps], and a gap is what stops the dead-entry verdict.
int _declaredCells = 0;
int _measuredCells = 0;

/// Every reason this run measured less than the full sweep, empty when it did
/// not.
///
/// Read once, in `tearDownAll`. The three sources are the three ways the sweep
/// can be narrowed — the two dump-tooling defines the architecture doc's §5
/// contract 3 pins, plus the runner-level name filter the counters detect — and
/// each is phrased in the operator's own vocabulary so the skip note names the
/// flag they typed.
List<String> _coverageGaps() {
  final allLocales = AppLocalizations.supportedLocales.length;
  return [
    if (_targetLocales.length != allLocales)
      '--dart-define=LOCALE selected ${_targetLocales.length} of $allLocales '
          'locales',
    if (minScreenFilter > 0)
      '--dart-define=MIN_SCREEN=${minScreenFilter.toStringAsFixed(0)} moved '
          'every width this sweep pumps',
    if (_measuredCells != _declaredCells)
      '$_measuredCells of $_declaredCells declared cells were measured (a '
          '--name / -c filter, or a cell that threw before measuring)',
  ];
}

/// `+41.0px right at lib/x.dart:9 — legend fix #1145` for each incident.
///
/// The tracking note is per **site**, not per card, because the key it hangs off
/// is: two sites in one card can be deferred under different tickets, and one
/// site — anything in `ui_kit_library`, any shared row widget — can be reached
/// from several cards, where a card-keyed note would print whichever card
/// happened to hit it.
String _trackedDetail(List<OverflowIncident> incidents) =>
    incidents.map((i) => '$i — ${_ratchet.trackingNote(i.site)}').join(', ');

/// The incidents the reader has to act on, and how many the fixture already
/// covers.
///
/// A cell can now hold a mix: one site deferred, another new. The failure quotes
/// the new ones — those are the work — but says the coordinate carries more, so
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

/// The "how to defer this" paragraph, in the `file:line` key shape.
///
/// It quotes the keys themselves and says where they came from: the incidents
/// printed immediately above already end in `at <file>:<line>`
/// ([OverflowIncident.toString]), so the failure hands the operator the exact
/// string to paste. That is deliberately the only place the key shape is
/// explained — deriving it from the incident is one fact to keep true, whereas a
/// worked example of the grammar would be a second.
String _remediation(List<OverflowIncident> blocking, String tag) {
  final sites = blocking.map((i) => i.site).whereType<String>().toSet().toList()
    ..sort();
  // Counted directly rather than as `blocking.length - sites.length`: `sites` is
  // deduplicated, so two blocking incidents at one site would have made the
  // difference claim an incident had no location when both did — the operator
  // would go looking for an incident the message above never printed.
  final unresolved = blocking.where((i) => i.site == null).length;
  if (sites.isEmpty) {
    return 'No incident above resolved a source location, so none of them can '
        'be allowlisted at all: the ratchet keys on `file:line` and a null '
        'location is not a key (deliberately — see OverflowRatchet). Fix the '
        'layout.';
  }
  return 'Fix the layout (Flexible/Expanded/maxLines/ellipsis), or if this is '
      'knowingly deferred, add "$tag" to the\n'
      '${sites.map((s) => "  '$s'").join('\n')}\n'
      'entr${sites.length == 1 ? 'y' : 'ies'} of the "allowlist" map in\n'
      '  $kKnownOverflowsFixturePath\n'
      'along with a "tracking" note under the same key. Each key is the source '
      'location the matching incident above ends in ("… at <file>:<line>") — '
      'not the card|width|tab coordinate this fixture used before #1341.'
      '${unresolved == 0 ? '' : '\n$unresolved further incident(s) resolved no '
          'source location and therefore cannot be exempted at all; those need '
          'the layout fixed.'}';
}

/// Report output mode. Set this in-file to dump locally without passing
/// `--dart-define=DUMP=...`; see [dumpMode] for the override precedence.
/// 0: default — emit nothing (fastest; what the PR gate runs)
/// 1: terse Markdown list only (build/overflow_testing/overflow_report.md)
/// 2: visual HTML report (build/overflow_testing/overflow_report.html) + PNGs
/// 3: both 1 and 2
const int _dumpMode = 0;

int get dumpMode {
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

bool get _shouldDumpPng => dumpMode == 2 || dumpMode == 3;
bool get _shouldDumpMd => dumpMode == 1 || dumpMode == 3;
bool get _shouldDumpHtml => dumpMode == 2 || dumpMode == 3;
bool get _shouldCollectReport => dumpMode > 0;

final List<OverflowReportItem> _collectedReportItems = [];

bool get _isListOnly {
  const d = String.fromEnvironment('LIST_CARDS');
  if (d == 'true' || d == '1') return true;
  final env = Platform.environment;
  return env['LIST_CARDS'] == 'true' || env['LIST_CARDS'] == '1';
}

void main() {
  if (_isListOnly) {
    test('list all registered dashboard cards', () {
      // ignore: avoid_print
      print('');
      // ignore: avoid_print
      print('================================================================');
      // ignore: avoid_print
      print(
          ' 📋 Registered Dashboard Cards in UspWidgetSpecs.all (${UspWidgetSpecs.all.length} cards)');
      // ignore: avoid_print
      print('================================================================');
      for (var i = 0; i < UspWidgetSpecs.all.length; i++) {
        final spec = UspWidgetSpecs.all[i];
        final c = spec.getConstraints(DisplayMode.normal);
        final tabCount = tabCountFor(spec.id);
        final tabInfo = tabCount > 1 ? ' | $tabCount tabs' : ' | single tab';
        // ignore: avoid_print
        print(
          '  ${(i + 1).toString().padLeft(2)}. ${spec.id.padRight(28)} (columns: min ${c.minColumns} / pref ${c.preferredColumns} / max ${c.maxColumns}$tabInfo)',
        );
      }
      // ignore: avoid_print
      print('================================================================');
    });
    return;
  }

  setUpAll(() async {
    // Throws on a fixture it cannot read — including one still carrying
    // pre-#1341 coordinate keys — and a throw here fails once, as `(setUpAll)`,
    // instead of 1,898 times. The old loader printed a warning and carried on
    // with an empty allowlist, which reads as a green gate.
    _ratchet = OverflowRatchet.fromFixture();
    await loadAppFonts();
  });

  tearDownAll(() async {
    if (_shouldCollectReport) {
      await DashboardOverflowReportGenerator.generateAll(
        _collectedReportItems,
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
    // not). A `tearDownAll` failure is reported as `(tearDownAll)` and fails the
    // suite without adding a test to the count — measured: 1,921 either way.
    // Verified on a full run at #1341: declared == measured == 1,898 and
    // therefore no gap, so the closing direction below is live on the gate and
    // on CI. A filtered run (`-c`, `-L`, `-m`) reports a gap and skips it.
    final gaps = _coverageGaps();
    final skipped = _ratchet.coverageSkipNote(gaps);
    if (skipped != null) {
      // ignore: avoid_print
      print(skipped);
    }
    final dead = _ratchet.deadEntryFailure(
      localesCovered: _targetLocales.map(_localeTag).toSet(),
      coverageGaps: gaps,
    );
    if (dead != null) fail(dead);
  });

  // Meta-test: the hardcoded tab counts in kTabbedCardTabCounts must match what
  // each card actually builds. If a card gains/loses a tab, this fails and
  // points at the registry to update (keeping the sweep exhaustive).
  //
  // Measured at the **desktop** width, not at the narrowest realization it used
  // to pump. A card that declares `normalAbove` renders its popup form below
  // 200px, and the popup form has no tab bar at all — `network_health` was the
  // first tabbed card to declare one (#1291) and this guard read its 0 visible
  // tabs as "the card lost its tabs". How many tabs a card *has* is a property
  // of its whole form; which form a given width selects is a density claim, and
  // it belongs to the per-card density suites rather than to a registry check
  // that happens to pump a narrow width (#1291).
  group('tab registry', () {
    for (final entry in kTabbedCardTabCounts.entries) {
      testWidgets('${entry.key} still has ${entry.value} tabs', (tester) async {
        final spec = UspWidgetSpecs.all.firstWhere((s) => s.id == entry.key);
        final wc = desktopCaseFor(spec);
        final rows = spec.getConstraints(DisplayMode.normal).minHeightRows;
        await probeCardOverflow(
          tester,
          cardId: entry.key,
          widthCase: wc,
          cardHeightRows: rows,
          tabIndex: 0,
          locale: const Locale('en'),
          // In the dataset even though the assertion below is about tab counts,
          // not about overflow: this pumps a real card and collects real
          // incidents, so it is a measured coordinate — and it is the guard that
          // decides how many tabs the sweeps cover. A port that dropped it would
          // otherwise diff clean while quietly taking the tab registry with it.
          cell: OverflowCell('card.tab_registry', {
            'card': entry.key,
            'px': wc.widthKey,
          }),
        );
        expect(
          visibleTabCount(tester),
          entry.value,
          reason:
              'Tab count for "${entry.key}" changed. Update kTabbedCardTabCounts '
              'in dashboard_card_probe.dart so the overflow sweep covers every '
              'tab.',
        );
      });
    }

    // The inverse claim, which is the half that decides coverage for a *new*
    // card: `tabCountFor` falls back to 1 for anything absent from the registry,
    // so a tabbed card nobody registered is swept at tab 0 and its other tabs
    // are never measured — silently, because every case it does run still
    // passes. Registering a card is therefore not bookkeeping, and the loop
    // above cannot say so: it only iterates ids that are already there.
    final registered = kTabbedCardTabCounts.keys.toSet();
    for (final spec
        in UspWidgetSpecs.all.where((s) => !registered.contains(s.id))) {
      testWidgets('${spec.id} is single-view, so tab 0 is full coverage',
          (tester) async {
        final wc = desktopCaseFor(spec);
        final rows = spec.getConstraints(DisplayMode.normal).minHeightRows;
        await probeCardOverflow(
          tester,
          cardId: spec.id,
          widthCase: wc,
          cardHeightRows: rows,
          tabIndex: 0,
          locale: const Locale('en'),
          cell: OverflowCell('card.single_view', {
            'card': spec.id,
            'px': wc.widthKey,
          }),
        );
        expect(
          visibleTabCount(tester),
          1,
          reason: '"${spec.id}" builds a tab bar but is absent from '
              'kTabbedCardTabCounts in dashboard_card_probe.dart, so the sweep '
              'measures tab 0 only and the rest of its tabs go unmeasured. Add '
              'it with its tab count.',
        );
      });
    }
  });

  for (final spec in UspWidgetSpecs.all) {
    final rows = spec.getConstraints(DisplayMode.normal).minHeightRows;
    final widthCases = widthCasesFor(spec);
    final tabCount = tabCountFor(spec.id);

    group('${spec.id} overflow', () {
      for (final wc in widthCases) {
        for (var tab = 0; tab < tabCount; tab++) {
          for (final locale in _targetLocales) {
            final tag = _localeTag(locale);
            final tabLabel = tabCount > 1 ? ' tab$tab' : '';
            _declaredCells++;
            testWidgets(
              'no overflow @${wc.label} ${wc.widthKey}px$tabLabel ($tag)',
              (tester) async {
                final repaintKey = _shouldDumpPng ? GlobalKey() : null;
                final incidents = await probeCardOverflow(
                  tester,
                  cardId: spec.id,
                  widthCase: wc,
                  cardHeightRows: rows,
                  tabIndex: tab,
                  locale: locale,
                  repaintKey: repaintKey,
                  cell: OverflowCell('card.width', {
                    'card': spec.id,
                    'width': wc.label,
                    'px': wc.widthKey,
                    'tab': tab,
                    'locale': tag,
                  }),
                );

                final significant =
                    incidents.where((i) => i.pixels > _tolerancePx).toList();
                // Counted before the early return, because a clean cell is a
                // measured one — that is exactly what makes the run's coverage
                // complete enough for the dead-entry verdict.
                _measuredCells++;
                if (significant.isEmpty) return;

                // One call per cell: it records every site as live debt *and*
                // answers which incidents are not exempt. Empty = the cell is
                // tolerated.
                final blocking = _ratchet.consultCell(significant, tag);

                final maxColsOnScreen = gridColumnsForWidth(wc.screenWidth);
                final currentColSpan = wc.columnSpan.clamp(1, maxColsOnScreen);

                final hasRightOverflow =
                    significant.any((i) => i.side == 'right');
                final hasBottomOverflow =
                    significant.any((i) => i.side == 'bottom');

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

                if (_shouldDumpPng && repaintKey != null) {
                  final tabSuffix = tabCount > 1 ? '_t$tab' : '';
                  final path =
                      'build/overflow_testing/png/${spec.id}/screen${wc.screenKey}_card${wc.widthKey}_${wc.columnSpan}x$rows${tabSuffix}_$tag.png';
                  await saveCardScreenshot(
                    tester,
                    repaintKey,
                    path,
                  );

                  final adjustPath =
                      'build/overflow_testing/png/adjust/${spec.id}/screen${wc.screenKey}_card${wc.widthKey}_${wc.columnSpan}x$rows${tabSuffix}_${tag}_adjusted.png';
                  adjustedIncidents = await captureAdjustedCardScreenshot(
                    tester,
                    cardId: spec.id,
                    screenWidth: wc.screenWidth,
                    recWidth: recWidth,
                    recHeight: recHeight,
                    tabIndex: tab,
                    locale: locale,
                    path: adjustPath,
                  );
                  isAdjustedClean = adjustedIncidents
                      .where((i) => i.pixels > _tolerancePx)
                      .isEmpty;
                }

                if (_shouldCollectReport) {
                  _collectedReportItems.add(OverflowReportItem(
                    cardId: spec.id,
                    screenWidth: wc.screenWidth,
                    cardWidth: wc.cardWidth,
                    cardHeight: origHeight,
                    columnSpan: wc.columnSpan,
                    rowSpan: rows,
                    widthLabel: wc.label,
                    tabIndex: tab,
                    tabCount: tabCount,
                    localeTag: tag,
                    incidents: significant,
                    // "The gate tolerated this row", i.e. **every** significant
                    // incident in it is exempt. It was a per-cell boolean while
                    // the allowlist was keyed per cell; under a site key
                    // exemption is a per-incident question, and "any" would let
                    // one known site colour a row green that the gate itself
                    // failed. The report has one row per coordinate, so the row
                    // must carry the coordinate's verdict, not a disjunction
                    // over its incidents. (Today no generator reads this field —
                    // it is declared and never used in
                    // `dashboard_overflow_report_generator.dart` — so the choice
                    // is about what the column will mean when someone renders
                    // it, not about current output.)
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

                if (blocking.isEmpty) {
                  // Documented + tracked: surface it but don't fail the gate.
                  // ignore: avoid_print
                  print(
                    'KNOWN OVERFLOW (allowlisted) ${spec.id} @${wc.label} '
                    '${wc.widthKey}px tab$tab $tag: '
                    '${_trackedDetail(significant)}',
                  );
                  return;
                }

                fail(
                  'Dashboard card "${spec.id}" overflows at ${wc.label} width '
                  '(${wc.widthKey}px), tab $tab, locale "$tag": '
                  '${_blockingDetail(blocking, significant)}.\n'
                  '${_remediation(blocking, tag)}',
                );
              },
            );
          }
        }
      }
    });
  }

  // ─── The normal band (#1318) ──────────────────────────────────────────────
  //
  // The sweep above pumps the widths the grid produces for each span, and claims
  // that is exhaustive because overflow is monotonic in width. Since #1288/#1290
  // six cards declare a `normalAbove`, so their narrowest realization renders a
  // *different form* — popup at 191.4px for all six, compact at 288.0px for the
  // three whose threshold is above it — and a different form is not a narrower
  // instance of the same one. For those three **this sweep is the only place the
  // grid's own widths reach the normal form at all**; what the gate had otherwise
  // is `dashboard_card_popup_overflow_test`'s two dialog groups, which render it at
  // the fixed `kCardPresentationWidth` (400px, above every threshold), tab 0 only,
  // in 3 locales, inside dialog chrome rather than a grid cell. That is not the
  // coordinate #1183's own motivating measurement lived at (`network_health`, Loss
  // tab, `de`, 500px, +41px): tab 2 in `de` used to be covered by transitivity from
  // the 191.4px normal case, and #1288 removed that without replacing it.
  //
  // So each of the six is swept once more, at [normalBandCaseFor] — the narrowest
  // width the grid produces at or above its own threshold. One width, because
  // monotonicity is intact *within* a form: see that function for the argument, and
  // `the gate's own widths cannot reach the normal band` below for the half of it
  // that is pinned rather than argued.
  //
  // No density is pinned. The coordinate is chosen so production's own selection
  // lands on normal, and each case asserts that it did — a pinned sweep would keep
  // passing after a threshold moved out from under it, measuring a form the width no
  // longer selects.
  //
  // Exemptions here are keyed on the overflow's own `file:line`, like every other
  // sweep since #1341 — this sweep needs no key grammar of its own, which is one of
  // the things the re-key bought. Unlike the forced-form sweep these coordinates
  // are *inherited* debt — the normal form was always rendered here in production,
  // only never measured — so grandfathering is the right mechanism if this finds
  // anything. Note the coarsening it comes with: a site exempted for the normal
  // band is exempted wherever else it overflows, including in the popup form the
  // main sweep pumps, because the key carries no width.
  //
  // No report collection, for a reason specific to this sweep: the report's
  // recommendation columns advise a wider span, and this coordinate sits exactly at
  // the width the card's own threshold names. "Use one more column" there reads as
  // "raise `normalAbove`", which is a design decision (#1288's measurement), not a
  // layout fix. The failure message carries everything triage needs.
  //
  // ## Mutation table
  //
  // Each assertion below was run against a mutation of the code it guards. Row 1 is
  // the one that justifies the sweep's existence rather than its shape: the main
  // 1698-case width sweep stayed **green** through it.
  //
  // | # | assertion | mutation | killed by |
  // |---|---|---|---|
  // | 1 | the per-case overflow `fail` | `usp_network_health_card`: the `if (!compact)` metric row gives its three `_MetricChip`s a fixed `width: 140` instead of `Expanded` — a width the desktop realization has room for and this card's own threshold does not | 26 of 26 `network_health` tab0 cases. Of the 3213 other cases carrying the `layout-gate` tag, the 1698-case main sweep saw **nothing**; only the two dialog groups (6, at 400px) and `usp_network_health_density_test`'s pinned-normal assertions (4) did |
  // | 2 | `the six cards that declare a threshold` + `each threshold is realizable` + the selected-form table | delete `normalAbove: 366` from `network_health`'s spec | all 3 meta-tests. The sweep itself goes 208 → 130 cases and stays green, which is exactly the silent narrowing they exist to convert into a failure |
  // | 3 | `selectedCardDensity(…) == normal` | `normalBandCaseFor` accepts widths 100px below the threshold | 208 of 208 sweep cases, plus `each threshold is realizable` |
  // | 4 | `widest lessThanOrEqualTo 288.0` | `kMinSupportedScreenWidth` 320 → 480 (the plausible version of this: dropping 320px support) | `the gate's own widths cannot reach the normal band` alone — `widest` becomes 448.0 |
  // | 5 | the 8-coordinate count | drop `'network_health': 3` from `kTabbedCardTabCounts` | `the six cards that declare a threshold` (8 → 6) |
  final normalBandSpecs =
      UspWidgetSpecs.all.where((s) => s.normalAbove != null).toList();

  group('normal band coverage', () {
    // The inventory, asserted rather than narrated — the counts in the comment
    // above are the whole justification for this sweep's existence and its size.
    test('the six cards that declare a threshold, at 8 card x tab coordinates',
        () {
      expect(
        {for (final s in normalBandSpecs) s.id: s.normalAbove},
        {
          'device_info': 262.0,
          'lan_info': 250.0,
          'ethernet_ports': 386.0,
          'connected_devices': 336.0,
          'time_settings': 256.0,
          'network_health': 366.0,
        },
        reason: 'a card that gains or loses a `normalAbove` changes what this '
            'sweep covers, so the list is pinned here rather than left to the '
            'loop below',
      );
      expect(
        normalBandSpecs.fold<int>(0, (n, s) => n + tabCountFor(s.id)),
        8,
        reason: 'five single-view cards plus network_health\'s three tabs',
      );
      // #1183's motivating coordinate, named so a change that drops it is a
      // failure rather than a silent narrowing.
      expect(tabCountFor('network_health'), 3,
          reason: 'the Loss tab is index 2; #1183 measured +41px there in de');
      expect(
        AppLocalizations.supportedLocales.map(_localeTag),
        contains('de'),
        reason: 'de is the locale #1183 measured the Loss-tab legend overflow '
            'in, so it has to be in the sweep this replaces it with',
      );
    });

    // Why one width per card is enough, in the direction that can rot: the
    // generator the main sweep uses tops out at 288.0px, because spans 5 upward all
    // realize 288.0px at the 320px screen floor — a card spanning the whole
    // 4-column mobile grid is full width. So no coordinate `widthCasesFor` can
    // produce reaches a threshold above 288, and the three cards below are outside
    // its range by construction rather than by sampling. If a wider realization
    // ever appears this fails, instead of the sweep quietly duplicating coverage.
    test('the gate\'s own widths cannot reach the normal band', () {
      // Every span any card declares — the generator's whole domain, taken from
      // the specs rather than from a hardcoded 1..12 so a new span comes with it.
      final spans = <int>{
        for (final s in UspWidgetSpecs.all) ...[
          s.getConstraints(DisplayMode.normal).minColumns,
          s.getConstraints(DisplayMode.normal).preferredColumns,
          s.getConstraints(DisplayMode.normal).maxColumns,
        ],
      };
      final widest = spans
          .map((span) => narrowestRealizationOf(span, minScreen: 0)!.cardWidth)
          .reduce(math.max);
      expect(widest, lessThanOrEqualTo(288.0),
          reason: 'widthCasesFor draws from narrowestRealizationOf, so 288.0px '
              'is the widest coordinate the main sweep can pump');

      // And the form each of those coordinates actually selects, per card. This is
      // the measurement the comment above quotes; asserting it means a threshold
      // change surfaces here with the numbers, rather than as an unexplained
      // failure in a satellite suite.
      final selected = {
        for (final spec in normalBandSpecs)
          spec.id: [
            for (final wc in widthCasesFor(spec))
              '${wc.widthKey}=${densityForWidth(width: wc.cardWidth, normalAbove: spec.normalAbove).name}',
          ],
      };
      expect(selected, {
        'device_info': ['191=popup', '288=normal'],
        'lan_info': ['191=popup', '288=normal'],
        'ethernet_ports': ['191=popup', '288=compact'],
        'connected_devices': ['191=popup', '288=compact'],
        'time_settings': ['191=popup', '288=normal'],
        'network_health': ['191=popup', '288=compact'],
      });
    });

    // The coordinate itself: derived from the spec, and a width the grid produces
    // rather than the bare threshold value.
    test('each threshold is realizable, so the sweep pumps a production width',
        () {
      expect(
        {
          for (final spec in normalBandSpecs)
            spec.id: '${normalBandCaseFor(spec)!.cardWidth.toStringAsFixed(1)}'
                '@${normalBandCaseFor(spec)!.screenWidth.toStringAsFixed(0)}'
                'x${normalBandCaseFor(spec)!.columnSpan}',
        },
        {
          'device_info': '262.0@1144x3',
          'lan_info': '250.0@1096x3',
          'ethernet_ports': '386.0@552x3',
          'connected_devices': '336.0@2096x3',
          'time_settings': '256.0@1120x3',
          'network_health': '366.0@2216x3',
        },
        reason:
            'every threshold happens to be exactly realizable at the card\'s '
            'minColumns — a consequence of the grid\'s near-continuity in screen '
            'width, pinned here because normalBandCaseFor searches for it rather '
            'than assuming it',
      );
    });
  });

  for (final spec in normalBandSpecs) {
    final rows = spec.getConstraints(DisplayMode.normal).minHeightRows;
    final wc = normalBandCaseFor(spec)!;
    final tabCount = tabCountFor(spec.id);

    group('${spec.id} overflow [normal band]', () {
      for (var tab = 0; tab < tabCount; tab++) {
        for (final locale in _targetLocales) {
          final tag = _localeTag(locale);
          final tabLabel = tabCount > 1 ? ' tab$tab' : '';
          _declaredCells++;
          testWidgets(
            'no overflow @normalAbove ${wc.widthKey}px$tabLabel ($tag)',
            (tester) async {
              final incidents = await probeCardOverflow(
                tester,
                cardId: spec.id,
                widthCase: wc,
                cardHeightRows: rows,
                tabIndex: tab,
                locale: locale,
                cell: OverflowCell('card.normal_band', {
                  'card': spec.id,
                  'width': wc.label,
                  'px': wc.widthKey,
                  'tab': tab,
                  'locale': tag,
                }),
              );

              expect(
                selectedCardDensity(tester),
                CardDensity.normal,
                reason:
                    '"${spec.id}" was pumped at ${wc.widthKey}px — the narrowest '
                    'width at or above its declared normalAbove '
                    '(${spec.normalAbove}) — but selected a degraded form, so '
                    'this case is no longer measuring the normal band. '
                    'normalBandCaseFor and densityForWidth have disagreed: check '
                    'whether the threshold moved or the selection rule changed.',
              );

              final significant =
                  incidents.where((i) => i.pixels > _tolerancePx).toList();
              _measuredCells++;
              if (significant.isEmpty) return;

              final blocking = _ratchet.consultCell(significant, tag);
              if (blocking.isEmpty) {
                // ignore: avoid_print
                print(
                  'KNOWN OVERFLOW (allowlisted) ${spec.id} @normalAbove '
                  '${wc.widthKey}px tab$tab $tag: '
                  '${_trackedDetail(significant)}',
                );
                return;
              }

              fail(
                'Dashboard card "${spec.id}" overflows in its **normal** form at '
                '${wc.widthKey}px — the narrowest width its own '
                'normalAbove (${spec.normalAbove}) admits — tab $tab, locale '
                '"$tag": ${_blockingDetail(blocking, significant)}.\n'
                'This width is above the threshold, so no degradation applies '
                'here: the fix is to the normal form itself, or to the threshold '
                'if the form cannot read at this width (#1288 measured it).\n'
                '${_remediation(blocking, tag)}',
              );
            },
          );
        }
      }
    });
  }

  // ─── Named data profiles (#1267) ──────────────────────────────────────────
  //
  // The sweep above is one router shape. `kCardDataProfileSweeps` adds the
  // (card, tab) pairs worth measuring on a second one — see
  // `card_data_profiles.dart` for why the list is opt-in per card rather than
  // all 18, and what that deliberately does not claim.
  //
  // Same widths, same 26 locales, same one-pump-per-test rule as above; only the
  // data differs. One thing is deliberately *not* shared with the default sweep:
  //
  //   * No report collection. `OverflowReportItem` has no profile dimension, so a
  //     second-profile item would render in the HTML report indistinguishable
  //     from a default-profile one at the same coordinate — a worse outcome than
  //     its absence. Profile sweeps are measured by reading the failure, which
  //     names the profile.
  //
  // The allowlist used to be the second item on that list, and losing it is worth
  // naming: keys carried an `@profile` suffix, so an exemption earned on this data
  // could not silence the default sweep. A `file:line` key has no profile axis (nor
  // a width or tab one), so an exemption granted for a profile overflow now covers
  // that same source location everywhere, default data included. The trade was made
  // knowingly at #1341 — the suffix bought separation, while the coordinate key it
  // was part of invalidated wholesale on any layout rearrangement — and the fixture
  // is empty today, so nothing is in fact widened. If a profile-only exemption is
  // ever needed the answer is a narrower key shape in `OverflowRatchet`, not a
  // second fixture.
  for (final sweep in kCardDataProfileSweeps) {
    final spec = UspWidgetSpecs.all.firstWhere((s) => s.id == sweep.cardId);
    final rows = spec.getConstraints(DisplayMode.normal).minHeightRows;
    final widthCases = widthCasesFor(spec);
    final tabCount = tabCountFor(spec.id);
    final profile = sweep.profile;

    group('${sweep.cardId} overflow [${profile.key}]', () {
      for (final tab in sweep.tabs) {
        // A profile pinned to a tab the card no longer has would silently sweep
        // nothing, which is the same failure mode `kTabbedCardTabCounts` exists
        // to prevent.
        test('tab $tab exists on ${sweep.cardId}', () {
          expect(tab, lessThan(tabCount),
              reason: 'the ${profile.key} profile sweeps ${sweep.cardId} tab '
                  '$tab, but the card has $tabCount tab(s). Update '
                  'kCardDataProfileSweeps in card_data_profiles.dart.');
        });

        // The profile's data must reach the tree, or the 52 cases below are
        // pumping the default fixture and reporting green — see
        // [CardDataProfile.markers]. Measured at the desktop width so nothing is
        // absent for a density reason, in `en` because the markers are
        // untranslated.
        testWidgets('${profile.key} data reaches the render (tab $tab)',
            (tester) async {
          final desktop = desktopCaseFor(spec);
          await probeCardOverflow(
            tester,
            cardId: sweep.cardId,
            widthCase: desktop,
            cardHeightRows: rows,
            tabIndex: tab,
            locale: const Locale('en'),
            extraOverrides: profile.overrides(),
            // The guard that keeps the 52 cases below honest, so it belongs in the
            // dataset as much as they do: without it they can pump the default
            // fixture and pass. A port that dropped it would diff clean here and
            // silently turn the profile sweeps into duplicates of the plain ones.
            cell: OverflowCell('card.profile_data', {
              'card': sweep.cardId,
              'profile': profile.key,
              'tab': tab,
              'px': desktop.widthKey,
            }),
          );
          for (final marker in profile.markers) {
            expect(find.textContaining(marker), findsWidgets,
                reason: '"$marker" is absent from ${sweep.cardId} tab $tab, so '
                    'the "${profile.key}" overrides did not reach the render. '
                    'The sweep below would then be measuring the default '
                    'fixture and passing for the wrong reason. Check which '
                    'provider the card reads and that '
                    'CardDataProfile.overrides layers over it.');
          }
        });

        for (final wc in widthCases) {
          for (final locale in _targetLocales) {
            final tag = _localeTag(locale);
            _declaredCells++;
            testWidgets(
              'no overflow @${wc.label} ${wc.widthKey}px tab$tab ($tag)',
              (tester) async {
                final incidents = await probeCardOverflow(
                  tester,
                  cardId: sweep.cardId,
                  widthCase: wc,
                  cardHeightRows: rows,
                  tabIndex: tab,
                  locale: locale,
                  extraOverrides: profile.overrides(),
                  cell: OverflowCell('card.profile', {
                    'card': sweep.cardId,
                    'profile': profile.key,
                    'width': wc.label,
                    'px': wc.widthKey,
                    'tab': tab,
                    'locale': tag,
                  }),
                );

                final significant =
                    incidents.where((i) => i.pixels > _tolerancePx).toList();
                _measuredCells++;
                if (significant.isEmpty) return;

                final blocking = _ratchet.consultCell(significant, tag);
                if (blocking.isEmpty) {
                  // ignore: avoid_print
                  print(
                    'KNOWN OVERFLOW (allowlisted) ${sweep.cardId} '
                    '[${profile.key}] @${wc.label} ${wc.widthKey}px tab$tab '
                    '$tag: ${_trackedDetail(significant)}',
                  );
                  return;
                }

                fail(
                  'Dashboard card "${sweep.cardId}" overflows on the '
                  '"${profile.key}" data profile (${profile.description}) at '
                  '${wc.label} width (${wc.widthKey}px), tab $tab, locale '
                  '"$tag": ${_blockingDetail(blocking, significant)}.\n'
                  'This coordinate is clean on the default profile — the data, '
                  'not the width, is what breaks it, so allowlisting it exempts '
                  'the same source location on the default data too (see the '
                  'note above this sweep).\n'
                  '${_remediation(blocking, tag)}',
                );
              },
            );
          }
        }
      }
    });
  }
}
