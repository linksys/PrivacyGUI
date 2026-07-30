@Tags(['dashboard-card'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';

import '../../../util/app_test_fonts.dart';
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
///     / max column span across every breakpoint. Overflow is monotonic in
///     width and height-independent (measured), so the narrowest realization of
///     each span is that span's worst case.
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
  final filterStr = d.isNotEmpty ? d : (d2.isNotEmpty ? d2 : (env['LOCALE'] ?? env['locale'] ?? ''));

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

/// Small tolerance for sub-pixel shaping differences between the mac (local) and
/// ubuntu (CI) font rasterizers. The project bundles fixed font files so the two
/// load the same glyphs, but borderline cases (~1px) can still flip; anything
/// meaningfully clipped is many pixels over.
const double _tolerancePx = 2.0;

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
bool _isAllowlisted(String card, String width, int tab, String tag) {
  final locales = _knownOverflowAllowlist['$card|$width|$tab'];
  if (locales == null) return false;
  return locales.contains('*') || locales.contains(tag);
}

/// 改為 true 即可在檔案內直接開啟截圖輸出至 `build/overflow_png/`
/// 0: 預設 — 不產出任何檔案 (最高效模式)
/// 1: 產出精簡 Markdown 條列式報告 (build/overflow_report.md) — 無圖片、無總覽
/// 2: 產出 HTML 詳盡視覺報告 (build/overflow_report.html) + PNG 截圖 (build/overflow_png/...)
/// 3: 產出 1 + 2 (Markdown 條列 + HTML 視覺報告 + PNG 截圖)
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
      );
    }
  });

  // Meta-test: the hardcoded tab counts in kTabbedCardTabCounts must match what
  // each card actually builds. If a card gains/loses a tab, this fails and
  // points at the registry to update (keeping the sweep exhaustive).
  group('tab registry', () {
    for (final entry in kTabbedCardTabCounts.entries) {
      testWidgets('${entry.key} still has ${entry.value} tabs', (tester) async {
        final spec = UspWidgetSpecs.all.firstWhere((s) => s.id == entry.key);
        final wc = widthCasesFor(spec).first;
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
                if (significant.isEmpty) return;

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
                      'build/overflow_testing/png/${spec.id}/screen${wc.screenKey}_card${wc.widthKey}_${wc.columnSpan}x${rows}${tabSuffix}_$tag.png';
                  await saveCardScreenshot(
                    tester,
                    repaintKey,
                    path,
                  );

                  final adjustPath =
                      'build/overflow_testing/png/adjust/${spec.id}/screen${wc.screenKey}_card${wc.widthKey}_${wc.columnSpan}x${rows}${tabSuffix}_${tag}_adjusted.png';
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
                  'entry in _knownOverflowAllowlist with the tracking issue.',
                );
              },
            );
          }
        }
      }
    });
  }
}
