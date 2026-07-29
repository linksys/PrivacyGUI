@Tags(['dashboard-card'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';

import '../../../util/app_test_fonts.dart';
import '../../../util/dashboard/dashboard_card_probe.dart';

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

/// Every locale the app ships — the same list the running app offers, so this
/// gate tracks all of them (and any future language) automatically.
const List<Locale> _allLocales = AppLocalizations.supportedLocales;

/// Locale identity used as the allowlist key and in test names. Keeps the
/// country code so regional variants stay distinct (`zh` vs `zh_TW`, `fr` vs
/// `fr_CA`) — they can differ in label length and must be tracked separately.
String _localeTag(Locale l) => l.countryCode == null || l.countryCode!.isEmpty
    ? l.languageCode
    : '${l.languageCode}_${l.countryCode}';

/// Small tolerance for sub-pixel shaping differences between the mac (local) and
/// ubuntu (CI) font rasterizers. The project bundles fixed font files so the two
/// load the same glyphs, but borderline cases (~1px) can still flip; anything
/// meaningfully clipped is many pixels over.
const double _tolerancePx = 2.0;

/// Why a card's overflows are tolerated + where the fix is tracked. Cited in
/// test output. Keyed by card id since a card's debt shares one tracking ref.
const Map<String, String> _trackingByCard = {
  'network_health': 'legend fix #1145/#1174',
};

String _trackingFor(String card) => _trackingByCard[card] ?? 'baseline #1183';

/// Baseline of overflows that already exist and must NOT fail this gate yet.
///
/// This is a *ratchet*, not a dumping ground. It was measured across the real
/// production grid widths × all 26 shipped locales × every tab when the gate was
/// introduced on `dev-2.7.0` (#1183): 12 of 18 cards overflow at their narrowest
/// realizations (460 (card, width, tab, locale) coordinates). The gate ships
/// green by tolerating exactly these, while:
///   * any NEW overflow — a different card/width/tab/locale — fails immediately,
///     and
///   * removing a card's layout debt makes its entries stale; delete them so a
///     regression re-fails.
///
/// KEY is `'<cardId>|<widthLabel>|<tabIndex>'` (widthLabel ∈ {min, preferred,
/// max}); VALUE is the set of overflowing locale tags, or `{'*'}` meaning **all**
/// shipped locales. A `{'*'}` entry is a *structural* overflow — the card
/// overflows regardless of language (a fixed-width element, not long text), and
/// is the highest-value thing to fix. Anything else is text-length dependent.
///
/// Fixing these cards' layouts and shrinking this map is the follow-up work
/// #1183 exists to track. `network_health` specifically is addressed by the
/// #1145/#1174 legend fix — drop its entries once that lands on this base.
const Map<String, Set<String>> _knownOverflowAllowlist = {
  'stats_panel|min|0': {'*'}, // structural — all locales
  'device_info|min|0': {
    'ar',
    'da',
    'de',
    'el',
    'en',
    'es',
    'es_AR',
    'fi',
    'fr',
    'fr_CA',
    'id',
    'it',
    'ja',
    'nb',
    'nl',
    'pl',
    'pt',
    'pt_PT',
    'ru',
    'sv',
    'th',
    'tr',
    'vi',
  },
  'device_info|preferred|0': {'fi', 'id', 'pl', 'sv'},
  'network_status|min|0': {
    'ar',
    'da',
    'de',
    'el',
    'en',
    'es',
    'es_AR',
    'fi',
    'fr',
    'fr_CA',
    'id',
    'it',
    'ja',
    'nb',
    'nl',
    'pl',
    'pt',
    'pt_PT',
    'sv',
    'th',
    'tr',
    'vi',
  },
  'network_status|preferred|0': {'es_AR'},
  'lan_info|min|0': {'*'}, // structural — all locales
  'lan_info|preferred|0': {
    'ar',
    'da',
    'de',
    'el',
    'es',
    'es_AR',
    'fi',
    'fr',
    'fr_CA',
    'it',
    'nb',
    'nl',
    'pl',
    'pt',
    'pt_PT',
    'tr',
    'vi',
  },
  'ethernet_ports|min|0': {'*'}, // structural — all locales
  'ethernet_ports|preferred|0': {
    'ar',
    'da',
    'de',
    'el',
    'en',
    'es',
    'es_AR',
    'fi',
    'fr',
    'fr_CA',
    'id',
    'it',
    'nb',
    'nl',
    'pl',
    'pt',
    'pt_PT',
    'ru',
    'sv',
    'th',
    'tr',
    'vi',
  },
  'system_status|min|0': {'*'}, // structural — all locales
  'system_status|min|1': {'*'}, // structural — all locales
  'system_status|min|2': {
    'de',
    'es',
    'es_AR',
    'fi',
    'fr',
    'fr_CA',
    'id',
    'it',
    'nl',
    'pt',
    'pt_PT',
    'ru',
    'sv',
    'tr',
  },
  'system_status|min|3': {'de', 'fi', 'fr', 'fr_CA', 'it', 'nb'},
  'system_status|preferred|0': {'fr', 'fr_CA'},
  'system_status|preferred|1': {'de', 'fi', 'id', 'nb'},
  'system_status|preferred|2': {'fr', 'fr_CA'},
  'connected_devices|min|0': {'*'}, // structural — all locales
  'connected_devices|preferred|0': {'el'},
  'time_settings|min|0': {
    'da',
    'de',
    'el',
    'en',
    'es',
    'es_AR',
    'fi',
    'fr',
    'fr_CA',
    'id',
    'it',
    'nb',
    'nl',
    'pl',
    'pt',
    'pt_PT',
    'ru',
    'sv',
    'th',
    'tr',
    'vi',
  },
  'port_forwarding|min|0': {'es', 'fr', 'fr_CA', 'pt', 'pt_PT'},
  'port_forwarding|preferred|0': {'pt', 'pt_PT'},
  'network_health|min|0': {
    'ar',
    'da',
    'de',
    'el',
    'en',
    'es',
    'es_AR',
    'fi',
    'fr',
    'fr_CA',
    'id',
    'it',
    'ja',
    'nb',
    'nl',
    'pl',
    'pt',
    'pt_PT',
    'ru',
    'sv',
    'th',
    'tr',
    'vi',
  },
  'network_health|min|1': {
    'ar',
    'da',
    'de',
    'el',
    'en',
    'es',
    'es_AR',
    'fi',
    'fr',
    'fr_CA',
    'id',
    'it',
    'ja',
    'nb',
    'nl',
    'pl',
    'pt',
    'pt_PT',
    'ru',
    'sv',
    'th',
    'tr',
    'vi',
  },
  'network_health|min|2': {
    'ar',
    'da',
    'de',
    'el',
    'en',
    'es',
    'es_AR',
    'fi',
    'fr',
    'fr_CA',
    'id',
    'it',
    'nb',
    'nl',
    'pl',
    'pt',
    'pt_PT',
    'ru',
    'sv',
    'th',
    'tr',
    'vi',
  },
  'network_health|preferred|0': {'fr_CA', 'pl', 'ru'},
  'network_health|preferred|1': {'id'},
  'network_health|preferred|2': {'id'},
  'wifi_performance|min|0': {
    'da',
    'de',
    'el',
    'en',
    'es',
    'es_AR',
    'fi',
    'fr',
    'fr_CA',
    'id',
    'it',
    'nl',
    'pl',
    'pt',
    'pt_PT',
    'ru',
    'sv',
    'th',
  },
  'wifi_performance|min|1': {'es', 'es_AR', 'fr', 'fr_CA', 'pt_PT', 'tr'},
  'wifi_performance|preferred|0': {
    'de',
    'es',
    'es_AR',
    'fi',
    'fr',
    'id',
    'it',
    'nl',
    'pl',
    'pt',
    'pt_PT',
    'ru',
    'sv',
    'th',
  },
  'wifi_performance|preferred|1': {'es', 'fr', 'fr_CA', 'pt_PT'},
  'traffic_analysis|min|0': {
    'ar',
    'da',
    'de',
    'el',
    'en',
    'es',
    'es_AR',
    'fi',
    'fr',
    'fr_CA',
    'id',
    'it',
    'ja',
    'nb',
    'nl',
    'pl',
    'pt',
    'pt_PT',
    'ru',
    'sv',
    'th',
    'tr',
    'vi',
  },
  'traffic_analysis|preferred|0': {
    'da',
    'de',
    'en',
    'es',
    'es_AR',
    'fi',
    'fr',
    'fr_CA',
    'id',
    'it',
    'nb',
    'nl',
    'pl',
    'pt',
    'pt_PT',
    'ru',
    'sv',
    'th',
    'tr',
    'vi',
  },
};

/// True if (card, widthLabel, tab, locale) is in the baseline — either its
/// locale set lists [tag] explicitly, or the set is `{'*'}` (all locales).
bool _isAllowlisted(String card, String width, int tab, String tag) {
  final locales = _knownOverflowAllowlist['$card|$width|$tab'];
  if (locales == null) return false;
  return locales.contains('*') || locales.contains(tag);
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  // Meta-test: the hardcoded tab counts in kTabbedCardTabCounts must match what
  // each card actually builds. If a card gains/loses a tab, this fails and
  // points at the registry to update (keeping the sweep exhaustive).
  group('tab registry', () {
    for (final entry in kTabbedCardTabCounts.entries) {
      testWidgets('${entry.key} still has ${entry.value} tabs', (tester) async {
        final spec = UspWidgetSpecs.all.firstWhere((s) => s.id == entry.key);
        final wc = widthCasesFor(spec).first;
        final rows = spec.getConstraints(DisplayMode.normal).maxHeightRows;
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
    final rows = spec.getConstraints(DisplayMode.normal).maxHeightRows;
    final widthCases = widthCasesFor(spec);
    final tabCount = tabCountFor(spec.id);

    group('${spec.id} overflow', () {
      for (final wc in widthCases) {
        for (var tab = 0; tab < tabCount; tab++) {
          for (final locale in _allLocales) {
            final tag = _localeTag(locale);
            final tabLabel = tabCount > 1 ? ' tab$tab' : '';
            testWidgets(
              'no overflow @${wc.label} ${wc.widthKey}px$tabLabel ($tag)',
              (tester) async {
                final incidents = await probeCardOverflow(
                  tester,
                  cardId: spec.id,
                  widthCase: wc,
                  cardHeightRows: rows,
                  tabIndex: tab,
                  locale: locale,
                );

                final significant =
                    incidents.where((i) => i.pixels > _tolerancePx).toList();
                if (significant.isEmpty) return;

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
