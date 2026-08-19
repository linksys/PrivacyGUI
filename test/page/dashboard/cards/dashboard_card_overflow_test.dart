@Tags(['dashboard-card'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';

import '../../../util/app_test_fonts.dart';
import '../../../util/dashboard/card_data_profiles.dart';
import '../../../util/dashboard/dashboard_card_probe.dart';
import '../../../util/dashboard/dashboard_overflow_report_generator.dart';
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
///   Tagged `dashboard-card`, which is NOT in `run_tests.sh`'s
///   `--exclude-tags="golden||loc||ui"` blacklist, so the PR gate runs it and a
///   failure blocks the PR. (Do not retag it golden/ui/loc — it would silently
///   drop out of the gate.)

/// Locale identity used as the allowlist key and in test names. Keeps the
/// country code so regional variants stay distinct (`zh` vs `zh_TW`, `fr` vs
/// `fr_CA`) — they can differ in label length and must be tracked separately.
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

Map<String, String> _trackingByCard = {};
Map<String, Set<String>> _knownOverflowAllowlist = {};

String _trackingFor(String card) => _trackingByCard[card] ?? 'baseline #1183';

void _loadKnownOverflowsFixture() {
  final file = File('test/fixtures/known_overflows.json');
  if (!file.existsSync()) return;

  try {
    final content = file.readAsStringSync();
    final Map<String, dynamic> json = jsonDecode(content);

    if (json.containsKey('tracking')) {
      _trackingByCard = Map<String, String>.from(json['tracking']);
    }
    if (json.containsKey('allowlist')) {
      final Map<String, dynamic> allowMap = json['allowlist'];
      _knownOverflowAllowlist = allowMap.map((key, value) {
        return MapEntry(key, Set<String>.from(value as List));
      });
    }
  } catch (e) {
    // ignore: avoid_print
    print('⚠️ Failed to load known overflows fixture: $e');
  }
}

/// True if (card, widthLabel, tab, locale) is in the baseline — either its
/// locale set lists [tag] explicitly, or the set is `{'*'}` (all locales).
///
/// [profileKey] is null for the default data profile, keeping every pre-#1267 key
/// byte-identical. A named profile's cases live under `card|width|tab@profile`, so
/// the default profile's entry count — the number every closed ticket in this epic
/// quotes as "N coordinates cleared" — cannot be moved by a second profile's
/// findings (design §2.7).
bool _isAllowlisted(String card, String width, int tab, String tag,
    {String? profileKey}) {
  final suffix = profileKey == null ? '' : '@$profileKey';
  final locales = _knownOverflowAllowlist['$card|$width|$tab$suffix'];
  if (locales == null) return false;
  return locales.contains('*') || locales.contains(tag);
}

/// Fails a *clean* case whose coordinate the baseline still exempts.
///
/// Without this the ratchet only turns one way: an overflow that gets fixed
/// leaves its exemption behind, and the next reader cannot tell a deferred
/// defect from a dead entry — which is how this epic came to retire 46 stale
/// coordinates by hand (#1273). Runs on the clean path, so it reads one map
/// entry and returns for every card that isn't listed.
void _failIfDeadExemption(String card, String width, int tab, String tag,
    {String? profileKey}) {
  final suffix = profileKey == null ? '' : '@$profileKey';
  final key = '$card|$width|$tab$suffix';
  final locales = _knownOverflowAllowlist[key];
  if (locales == null) return;

  if (locales.contains(tag)) {
    fail(
      'Dead exemption: \'$key\' lists "$tag" in\n'
      '  test/fixtures/known_overflows.json\n'
      'but this coordinate no longer overflows. Remove "$tag" from that entry '
      '— and the entry itself, plus its "tracking" note, once the locale list '
      'empties.',
    );
  }
  if (locales.contains('*')) {
    fail(
      'Over-broad exemption: \'$key\' is marked "*" — overflows in every '
      'locale — in\n'
      '  test/fixtures/known_overflows.json\n'
      'but locale "$tag" renders clean, so the overflow is text-dependent, not '
      'structural. Replace "*" with the explicit locale tags that still '
      'overflow (`./tool/run_overflow_test.sh -c $card -d 1` lists them), or '
      'delete the entry if none do.',
    );
  }
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
    _loadKnownOverflowsFixture();
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
        );
        expect(
          visibleTabCount(tester),
          1,
          reason:
              '"${spec.id}" builds a tab bar but is absent from '
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
                );

                final significant =
                    incidents.where((i) => i.pixels > _tolerancePx).toList();
                if (significant.isEmpty) {
                  _failIfDeadExemption(spec.id, wc.label, tab, tag);
                  return;
                }

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
                    isAllowed: _isAllowlisted(spec.id, wc.label, tab, tag),
                    recCols: recCols,
                    recRows: recRows,
                    recWidth: recWidth,
                    recHeight: recHeight,
                    isWidthExpandable: isWidthExpandable,
                    isAdjustedClean: isAdjustedClean,
                    adjustedIncidents: adjustedIncidents,
                  ));
                }

                final allowed = _isAllowlisted(spec.id, wc.label, tab, tag);
                final detail = significant.join(', ');

                if (allowed) {
                  // Documented + tracked: surface it but don't fail the gate.
                  // ignore: avoid_print
                  print(
                    'KNOWN OVERFLOW (allowlisted) ${spec.id} @${wc.label} '
                    '${wc.widthKey}px tab$tab $tag: $detail '
                    '— ${_trackingFor(spec.id)}',
                  );
                  return;
                }

                fail(
                  'Dashboard card "${spec.id}" overflows at ${wc.label} width '
                  '(${wc.widthKey}px), tab $tab, locale "$tag": $detail.\n'
                  'Fix the layout (Flexible/Expanded/maxLines/ellipsis), or if '
                  'this is knowingly deferred, add "$tag" to the\n'
                  "  '${spec.id}|${wc.label}|$tab'\n"
                  'entry of the "allowlist" map in\n'
                  '  test/fixtures/known_overflows.json\n'
                  'along with a "tracking" note for the card.',
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
  // Allowlist keys are `card|normalAbove|tab`, which the existing grammar and the
  // dead-exemption check already handle. Unlike the forced-form sweep these
  // coordinates are *inherited* debt — the normal form was always rendered here in
  // production, only never measured — so grandfathering is the right mechanism if
  // this finds anything.
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
  // | 1 | the per-case overflow `fail` | `usp_network_health_card`: the `if (!compact)` metric row gives its three `_MetricChip`s a fixed `width: 140` instead of `Expanded` — a width the desktop realization has room for and this card's own threshold does not | 26 of 26 `network_health` tab0 cases. Of the 3213 other cases carrying the `dashboard-card` tag, the 1698-case main sweep saw **nothing**; only the two dialog groups (6, at 400px) and `usp_network_health_density_test`'s pinned-normal assertions (4) did |
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
        for (final s in UspWidgetSpecs.all)
          ...[
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
        reason: 'every threshold happens to be exactly realizable at the card\'s '
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
              if (significant.isEmpty) {
                _failIfDeadExemption(spec.id, wc.label, tab, tag);
                return;
              }

              final detail = significant.join(', ');
              if (_isAllowlisted(spec.id, wc.label, tab, tag)) {
                // ignore: avoid_print
                print(
                  'KNOWN OVERFLOW (allowlisted) ${spec.id} @normalAbove '
                  '${wc.widthKey}px tab$tab $tag: $detail '
                  '— ${_trackingFor(spec.id)}',
                );
                return;
              }

              fail(
                'Dashboard card "${spec.id}" overflows in its **normal** form at '
                '${wc.widthKey}px — the narrowest width its own '
                'normalAbove (${spec.normalAbove}) admits — tab $tab, locale '
                '"$tag": $detail.\n'
                'This width is above the threshold, so no degradation applies '
                'here: the fix is to the normal form itself, or to the threshold '
                'if the form cannot read at this width (#1288 measured it).\n'
                'If knowingly deferred, add "$tag" to the\n'
                "  '${spec.id}|${wc.label}|$tab'\n"
                'entry of the "allowlist" map in\n'
                '  test/fixtures/known_overflows.json\n'
                'along with a "tracking" note for the card.',
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
  // data differs. Two things are deliberately *not* shared with the default
  // sweep:
  //
  //   * Allowlist keys carry an `@profile` suffix, so the default profile's
  //     arithmetic is untouched by anything found here (see `_isAllowlisted`).
  //   * No report collection. `OverflowReportItem` has no profile dimension, so a
  //     second-profile item would render in the HTML report indistinguishable
  //     from a default-profile one at the same coordinate — a worse outcome than
  //     its absence. Profile sweeps are measured by reading the failure, which
  //     names the profile.
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
          await probeCardOverflow(
            tester,
            cardId: sweep.cardId,
            widthCase: desktopCaseFor(spec),
            cardHeightRows: rows,
            tabIndex: tab,
            locale: const Locale('en'),
            extraOverrides: profile.overrides(),
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
                );

                final significant =
                    incidents.where((i) => i.pixels > _tolerancePx).toList();
                if (significant.isEmpty) {
                  _failIfDeadExemption(sweep.cardId, wc.label, tab, tag,
                      profileKey: profile.key);
                  return;
                }

                if (_isAllowlisted(sweep.cardId, wc.label, tab, tag,
                    profileKey: profile.key)) {
                  // ignore: avoid_print
                  print(
                    'KNOWN OVERFLOW (allowlisted) ${sweep.cardId} '
                    '[${profile.key}] @${wc.label} ${wc.widthKey}px tab$tab '
                    '$tag: ${significant.join(', ')} '
                    '— ${_trackingFor(sweep.cardId)}',
                  );
                  return;
                }

                fail(
                  'Dashboard card "${sweep.cardId}" overflows on the '
                  '"${profile.key}" data profile (${profile.description}) at '
                  '${wc.label} width (${wc.widthKey}px), tab $tab, locale '
                  '"$tag": ${significant.join(', ')}.\n'
                  'This coordinate is clean on the default profile — the data, '
                  'not the width, is what breaks it.\n'
                  'Fix the layout, or if knowingly deferred add "$tag" to the\n'
                  "  '${sweep.cardId}|${wc.label}|$tab@${profile.key}'\n"
                  'entry of the "allowlist" map in\n'
                  '  test/fixtures/known_overflows.json\n'
                  'along with a "tracking" note for the card.',
                );
              },
            );
          }
        }
      }
    });
  }
}
