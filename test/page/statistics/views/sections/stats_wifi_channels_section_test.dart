@Tags(['dashboard-card'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/localization/fallback_font_resolver.dart';
import 'package:privacy_gui/page/_shared/models/client_connection_detail.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/page/statistics/views/sections/stats_wifi_channels_section.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../golden_test/golden_framework/mocks/mock_statistics.dart';
import '../../../../util/app_test_fonts.dart';
import '../../../../util/overflow_probe.dart';

/// Overflow tests for the two rows the WiFi Channels section renders per radio
/// (#1258 — the third instance of the #1226 / #1252 shape on the Statistics
/// page).
///
/// ## Why this file exists
///
/// `StatsWifiChannelsSection` renders one block per radio, each with two
/// unconstrained rows (`stats_wifi_channels_section.dart`):
///
///  - **line 110** — `AppText.labelLarge(radio.band)` + `const Spacer()` +
///    `AppText.bodySmall('Ch <channel>  ·  <bandwidth>')`. `Spacer` is an
///    `Expanded`, so it absorbs slack while the content fits and collapses to
///    zero when it does not, at which point both unconstrained texts take their
///    intrinsic width and overflow right.
///  - **line 121** — client count + SNR + `Expanded(AppLoader)`. Same cliff
///    with the `Expanded` on the progress bar instead of a `Spacer`.
///
/// Unlike the dashboard cards, this section is **not** in `UspWidgetSpecs.all`,
/// so the #1183 overflow gate never scans it — there is no ratchet entry and no
/// gate failure. This is a hardening ticket: #1258 measured **47px of
/// headroom** on line 110 at the 288px production floor (241px is the zero
/// crossing), and three things can eat it — localizing the hardcoded `'Ch '`
/// literal, a 3-digit 6GHz channel (`Ch 233 (Auto)`), or simply a narrower
/// realization. The AC is therefore a measurement of the rows, not "N gate
/// coordinates removed".
///
/// ## Three kinds of assertion, and why the stress widths are below production
///
/// Both rows have headroom at every *production* width (line 110: 47px at the
/// 288px floor; line 121's pre-fix `fi` crossing is 219px, 69px below the
/// floor). A test that only pumped production widths could therefore never fail
/// — it would report the shape as pinned while quietly guarding nothing, exactly
/// the dead-overflow-test trap `dashboard_legend_readability_test.dart` warned
/// about. So each row is checked three ways:
///
///   1. **Regression guard (production widths).** The `Wrap` renders identically
///      to the old `Row` while content fits, so these pin that the current data
///      and locales stay clean across the real screen range — a future wider
///      string that eats the headroom trips here.
///   2. **Degradation guard (a documented sub-production stress width).** Below
///      the floor the pre-fix `Row` clips and the `Wrap` drops the yielding
///      child to a second line instead. This width is where the fix's *value*
///      lives, and it is the width the mutation ledger below fails at. It is
///      deliberately narrower than any supported screen — the point is not that
///      this width ships, but that the shape degrades by wrapping rather than
///      clipping when the headroom is finally spent.
///   3. **AC-1 ladder (288 / 256 / 224 / 192px sections).** The widths #1258's
///      AC-1 names, in the locales that break first. A single degradation guard
///      at one width can sit in a pocket of cleanliness: this file's 219px guard
///      passed while a nested `Row(min)` clipped at 216px, 3px away. Walking the
///      ladder is what closes that gap, and it is the group that caught it.
///
/// Tagged `dashboard-card` so it gates PRs — `run_tests.sh` excludes
/// `golden||loc||ui`, and a `ui`-tagged regression test would not block
/// anything.
///
/// ## Mutation ledger
///
/// Every guard group here was shown to fail under a mutation of the code it
/// guards — an overflow test that cannot fail is worse than no test (precedent:
/// `stats_traffic_monitor_legend_test.dart`). Measured on this worktree with the
/// fixtures below; each mutation was applied alone, against an otherwise clean
/// tree:
///
///   | mutation                                             | measured                     |
///   |------------------------------------------------------|------------------------------|
///   | line 110 `Wrap` -> pre-fix `Row`+`Spacer`            | 10 tests fail (grp 1, 3)     |
///   | line 121 outer `Wrap` -> pre-fix `Row`+`Expanded`    | 5 tests fail (grp 2)         |
///   | stats `Wrap` -> `Row(min)`+`AppGap.md` (see below)   | 4 tests fail (grp 2 ladder)  |
///   | signal bar `SizedBox(96)` -> `Expanded` (keep `Wrap`)| ParentDataWidget error, all  |
///   | count -> `Flexible` + 1-line ellipsis                | all fail (grp 3 + layout)    |
///   | `snrValue` -> 1-line ellipsis (no `Flexible`)        | grp 3 fails                  |
///   | `snrValue` -> `Flexible` + 1-line ellipsis           | all fail (grp 3 + layout)    |
///
/// The two `snrValue` rows are the reason group 3 asserts on **both** stats. An
/// earlier revision of this file checked only `clientsCount`, and both of those
/// mutations passed it: the group's own doc comment promised "the count **and**
/// SNR", while the SNR was unguarded.
///
/// The `Row(min)` row is the shape this file's first revision shipped. A
/// `Row(min)` hands its children unbounded width just as a `Row` does — it only
/// changes what the row asks of *its* parent — so nesting one inside the `Wrap`
/// reproduced #1258's own failure mode one level down: with the signal bar
/// already on its own run, the two stats clipped at a **216px** section in `fi`,
/// and at 192px in `fi`, `ja`, `ko` and `vi`. That is above the 192px floor AC-1
/// requires, and it sat 3px below the 219px degradation guard, which therefore
/// never saw it.

/// Two radios whose channel string is the widest #1258 named: a 3-digit 6GHz
/// channel in auto mode (`Ch 233 (Auto)`) at a 3-digit bandwidth. This is the
/// "wider data" stressor from the issue — line 110's overflow is
/// locale-independent (both texts are data, not localized strings), so the way
/// to break it is wider data, not a wider locale.
const _wideChannelWifiData = WifiData(
  codegenContext: WifiCodegenContext.empty,
  radioModels: [
    WifiRadioUIModel(
      instancePath: 'Device.WiFi.Radio.1.',
      band: '2.4GHz',
      enable: true,
      transmitPower: -1,
      maxBitRate: 300,
      channel: 11,
      autoChannelEnable: true,
      channelBandwidth: '20/40MHz',
      supportedStandards: 'b,g,n',
    ),
    WifiRadioUIModel(
      instancePath: 'Device.WiFi.Radio.3.',
      band: '6GHz',
      enable: true,
      transmitPower: -1,
      maxBitRate: 4800,
      channel: 233,
      autoChannelEnable: true,
      channelBandwidth: '160MHz',
      supportedStandards: 'a,n,ac,ax,be',
    ),
  ],
);

/// The same two radios, plus a full client map so line 121 renders a non-zero
/// `clientsCount(n)` + `snrValue(n)` + signal bar — the state #1258 measured
/// (`+27px in fi at a 192px section`). Two clients per band exercises the
/// locale-dependent client-count string that `fi`
/// (`{count} asiakaslaitetta`) makes worst.
final _wifiDataWithClients = WifiData(
  codegenContext: WifiCodegenContext.empty,
  radioModels: _wideChannelWifiData.radioModels,
  wifiClientMap: {
    for (var i = 0; i < 8; i++)
      'mac$i': WifiClientUIModel(
        macAddress: 'AA:BB:CC:DD:EE:0$i',
        signalStrength: -55 - i,
        noise: -95,
        lastDataDownlinkRate: 866000,
        lastDataUplinkRate: 433000,
        active: true,
      ),
  },
  connectionDetailMap: {
    for (var i = 0; i < 8; i++)
      'mac$i': ClientConnectionDetail(
        band: i.isEven ? '2.4GHz' : '6GHz',
        ssidName: 'Linksys',
      ),
  },
);

void main() {
  setUpAll(() async {
    // Real fonts: text widths — and therefore overflow — are meaningless under
    // the Ahem block font.
    await loadAppFonts();
  });

  /// The width a single Statistics section renders to on a [screenWidth]
  /// screen: full content width minus the page margin on both edges. Mirrors
  /// `stats_traffic_monitor_legend_test.dart` — the Statistics page pads each
  /// section by `context.layoutMargin` (`usp_statistics_view.dart`), which is
  /// ui_kit's own [AppLayoutConfig.margin], so this reads it from the source of
  /// truth rather than a copied breakpoint table.
  double sectionWidthFor(double screenWidth) =>
      screenWidth - AppLayoutConfig.margin(screenWidth) * 2;

  final baseTheme = ThemeJsonConfig.defaultConfig().createLightTheme();

  /// Pumps the real [StatsWifiChannelsSection] once with the section sized to
  /// [sectionWidth] on a [screenWidth] screen, and returns the RenderFlex
  /// overflows beyond a 2px tolerance (the gate's own tolerance).
  ///
  /// [sectionWidth] defaults to what the Statistics page would give a section
  /// on that screen ([sectionWidthFor]); the degradation-guard tests pass an
  /// explicit narrower value to reach below the production floor while keeping
  /// the screen (and therefore ui_kit's layout regime) realistic.
  ///
  /// One pump per call: Flutter reports a given RenderFlex's overflow only once
  /// per render-object lifetime, so a second pump in the same test would report
  /// a genuinely overflowing width as clean.
  Future<List<OverflowIncident>> overflowsAt({
    required WidgetTester tester,
    required double screenWidth,
    required Locale locale,
    required WifiData wifiData,
    double? sectionWidth,
  }) async {
    final surface = Size(screenWidth, 900.0);
    final width = sectionWidth ?? sectionWidthFor(screenWidth);

    var theme = baseTheme;
    final cjkFallback = FallbackFontResolver.prefixedFallbackFor(locale);
    if (cjkFallback != null) {
      theme = theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamilyFallback: cjkFallback),
      );
    }

    return runWithOverflowCollection((sink) async {
      await tester.binding.setSurfaceSize(surface);
      tester.view.physicalSize = surface;
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: statisticsOverrides(wifiData: wifiData),
          child: MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: theme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child ?? const SizedBox.shrink(),
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: width,
                    child: const StatsWifiChannelsSection(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await settleIgnoringAnimations(tester);
      return sink.where((i) => i.pixels > 2.0).toList();
    });
  }

  Locale localeFor(String tag) =>
      AppLocalizations.supportedLocales.firstWhere((l) {
        final t = l.countryCode == null || l.countryCode!.isEmpty
            ? l.languageCode
            : '${l.languageCode}_${l.countryCode}';
        return t == tag;
      });

  /// The Statistics page is a single-column scroll list, so a section spans the
  /// full content width. These are the narrow realizations that matter (same
  /// set as `stats_traffic_monitor_legend_test.dart`):
  ///
  /// - 1241px: the D1 desktop-large pinch — 200px margins open just above
  ///   1240px, so 1241px yields a *narrower* section (841px) than 1240px.
  /// - 905px tablet: 32px margins, 841px section.
  /// - 601px: the tablet floor (32px margins), 537px section.
  /// - 320px: the framework's narrowest supported screen, 16px margins, 288px
  ///   section — the absolute worst case for these rows (the production floor
  ///   #1258 measured, where line 110 has only 47px of headroom).
  const narrowScreens = <double>[1241.0, 905.0, 601.0, 320.0];

  group('band + channel row (line 110) is clean under wide data (#1258)', () {
    // Line 110's overflow is locale-independent — both texts are data, not
    // localized strings — so the stressor is wider data, not a wider locale.
    // `_wideChannelWifiData` carries a 3-digit 6GHz `Ch 233 (Auto)` at 160MHz,
    // the widest channel string #1258 named. `de` ("Kanal") is pumped too as a
    // guard against anyone localizing the `'Ch '` prefix without re-checking.
    for (final tag in ['en', 'de']) {
      for (final screen in narrowScreens) {
        testWidgets(
          'no overflow at ${sectionWidthFor(screen).toStringAsFixed(0)}px '
          'section (${screen.toStringAsFixed(0)}px screen) in $tag',
          (tester) async {
            final overflows = await overflowsAt(
              tester: tester,
              screenWidth: screen,
              locale: localeFor(tag),
              wifiData: _wideChannelWifiData,
            );
            expect(
              overflows,
              isEmpty,
              reason: 'WiFi Channels band+channel row overflows in $tag at a '
                  '${screen.toStringAsFixed(0)}px screen '
                  '(${sectionWidthFor(screen).toStringAsFixed(0)}px section) '
                  'with a 3-digit 6GHz channel: ${overflows.join(', ')}',
            );
          },
        );
      }
    }

    // Degradation guard: below the production floor, the pre-fix `Row` + `Spacer`
    // clips the channel string, the `Wrap` drops it to a second line. 200px
    // section is where that difference is unambiguous with the wide 6GHz data:
    // measured +28px right under the pre-fix shape on this worktree, clean under
    // the `Wrap`. This is the test the "line 110 -> Row+Spacer" mutation fails.
    testWidgets(
      'wraps instead of clipping at a 200px section (below floor, en)',
      (tester) async {
        final overflows = await overflowsAt(
          tester: tester,
          screenWidth: 320.0,
          sectionWidth: 200.0,
          locale: localeFor('en'),
          wifiData: _wideChannelWifiData,
        );
        expect(
          overflows,
          isEmpty,
          reason: 'the band+channel row must wrap the channel string to a '
              'second line at a 200px section rather than overflow — the '
              'pre-fix `Row` + `Spacer` clips here (+28px): '
              '${overflows.join(', ')}',
        );
      },
    );
  });

  group('client + SNR + signal-bar row (line 121) is clean (#1258)', () {
    // Line 121's overflow is locale-dependent, and `fi`
    // (`{count} asiakaslaitetta`) is the worst. `_wifiDataWithClients` gives it
    // real, non-zero client counts across both radios so the row renders the
    // state #1258 measured overflowing (+27px in `fi` at a 192px section).
    //
    // `nl` is the fourth locale #1258's AC-1 names. It is dominated by `fi` and
    // `de` here (`{count} clients`, the same string as `en`), so it adds no
    // coverage at these widths — it is pumped because the AC names it, and
    // because a future ARB edit could make it the worst without anyone
    // re-deriving which locale dominates. `_widestStatLocales` below covers the
    // locales that actually break first.
    for (final tag in ['fi', 'de', 'ru', 'nl']) {
      for (final screen in narrowScreens) {
        testWidgets(
          'no overflow at ${sectionWidthFor(screen).toStringAsFixed(0)}px '
          'section (${screen.toStringAsFixed(0)}px screen) in $tag',
          (tester) async {
            final overflows = await overflowsAt(
              tester: tester,
              screenWidth: screen,
              locale: localeFor(tag),
              wifiData: _wifiDataWithClients,
            );
            expect(
              overflows,
              isEmpty,
              reason: 'WiFi Channels client+SNR row overflows in $tag at a '
                  '${screen.toStringAsFixed(0)}px screen '
                  '(${sectionWidthFor(screen).toStringAsFixed(0)}px section): '
                  '${overflows.join(', ')}',
            );
          },
        );
      }
    }

    // Degradation guard: below the production floor, the pre-fix `Row` +
    // `Expanded(AppLoader)` clips the stats; the `Wrap` drops the fixed-width
    // signal bar to its own run. 219px section in `fi` (the worst locale, with
    // real clients) is the exact crossing: measured +6.9px right under the
    // pre-fix shape on this worktree, clean under the `Wrap`. This is the test
    // the "line 121 -> Row+Expanded" and "signal bar -> Expanded" mutations
    // fail.
    testWidgets(
      'drops the signal bar to its own run at a 219px section (below floor, fi)',
      (tester) async {
        final overflows = await overflowsAt(
          tester: tester,
          screenWidth: 320.0,
          sectionWidth: 219.0,
          locale: localeFor('fi'),
          wifiData: _wifiDataWithClients,
        );
        expect(
          overflows,
          isEmpty,
          reason: 'the client+SNR row must move the signal bar to a second '
              'line at a 219px section rather than overflow — the pre-fix '
              '`Row` + `Expanded` clips here (+6.9px in fi): '
              '${overflows.join(', ')}',
        );
      },
    );

    // AC-1's own width ladder: 288px / 256px / 224px / 192px sections, "clean at
    // every width down to at least 192px".
    //
    // This is the group that caught the nested `Row(min)`: with the signal bar
    // already dropped to its own run, `clientsCount` + `snrValue` inside a
    // `Row(min)` still took unbounded width and clipped at a **216px** section in
    // `fi` — above the 192px floor the AC asks for, and only 3px below the 219px
    // degradation guard above, which is why that guard did not see it. Nesting a
    // `Wrap` instead of a `Row(min)` moves the crossing off the ladder entirely.
    //
    // The locale list is not AC-1's four. `fi` is the worst of those, but the
    // stats row's real worst cases are `ja`, `ko` and `vi`, which the AC does not
    // name and which broke at 192px alongside `fi` under the `Row(min)`. They are
    // pumped here so the ladder is guarded by whatever actually breaks first
    // rather than by the four locales the ticket happened to sample.
    const widestStatLocales = <String>['fi', 'ja', 'ko', 'vi'];
    for (final tag in widestStatLocales) {
      for (final section in [288.0, 256.0, 224.0, 192.0]) {
        testWidgets(
          'AC-1 ladder: clean at a ${section.toStringAsFixed(0)}px section '
          'in $tag',
          (tester) async {
            final overflows = await overflowsAt(
              tester: tester,
              // 320px keeps ui_kit's narrowest layout regime while the explicit
              // section width walks below the 288px production floor.
              screenWidth: 320.0,
              sectionWidth: section,
              locale: localeFor(tag),
              wifiData: _wifiDataWithClients,
            );
            expect(
              overflows,
              isEmpty,
              reason: 'AC-1 requires the client+SNR row to be clean down to a '
                  '192px section: it overflows in $tag at '
                  '${section.toStringAsFixed(0)}px. A `Row(min)` anywhere in '
                  'this subtree hands its children unbounded width and '
                  'reintroduces the shape #1258 removes: '
                  '${overflows.join(', ')}',
            );
          },
        );
      }
    }
  });

  group('client-count and SNR stats stay legible (#1258)', () {
    // The signal bar keys nothing on its own — a client that drops it to a
    // second line still reads. The count and SNR are the section's content: an
    // ellipsis lands mid-number, and a half-shown statistic misinforms in a way
    // a missing one does not (design §2.10a point 2). So the AC is not "the
    // stats are somewhere in the tree" — it is that they are present,
    // unellipsized, and not flex children that could shrink.

    /// True if a [Flexible] (or [Expanded], its subclass) sits between the stat
    /// and its enclosing [Wrap] — i.e. the stat can be squeezed below its
    /// intrinsic width.
    bool canShrink(Finder statFinder) {
      var flexed = false;
      statFinder.evaluate().single.visitAncestorElements((ancestor) {
        // Stop at the `Wrap`: it is the layout that decides this stat's width,
        // so reaching it means "nothing between here and the layout can squeeze
        // it" — the property under test, not "not found yet".
        if (ancestor.widget is Wrap) return false;
        if (ancestor.widget is Flexible) {
          flexed = true;
          return false;
        }
        return true;
      });
      return flexed;
    }

    testWidgets(
        'the client count and SNR are whole and unshrinkable at the narrowest '
        'width', (tester) async {
      const locale = Locale('fi');
      await overflowsAt(
        tester: tester,
        screenWidth: 320.0,
        locale: locale,
        wifiData: _wifiDataWithClients,
      );

      // Every AppText.bodySmall in the two rows is a Text; the count and SNR
      // strings are the localized stats. Assert on every rendered stat rather
      // than one exact value so the check does not encode the fixture's counts.
      final l10n = await AppLocalizations.delegate.load(locale);

      // Both stats are checked, not just the count. AC-2 names `clientsCount`
      // **and** `snrValue`, and the two are independently editable: a `maxLines`
      // or an `Expanded` added to one is invisible to a check on the other, so
      // asserting on the count alone leaves the SNR unguarded (a mutation adding
      // `Flexible` + `overflow: ellipsis` to `snrValue` passed the count-only
      // version of this test).
      //
      // 4 clients on 2.4GHz, 4 on 6GHz -> each stat is rendered twice, once per
      // radio, with the same value.
      //
      // The SNR is the average of `computeSNR(signalStrength, noise)` over a
      // band's clients: signal -55..-62 against noise -95 gives 40..33 dB, and
      // the per-band averages land on `snrValue(36)` for both radios (2.4GHz
      // takes the even indices, 6GHz the odd). Asserting the exact string keeps
      // the finder honest — a stat rendered as something else would read as
      // "absent" and fail below rather than silently pass.
      final stats = <String, String>{
        'client count': l10n.clientsCount(4),
        'SNR': l10n.snrValue(36),
      };

      for (final entry in stats.entries) {
        final label = entry.key;
        final text = entry.value;
        final finder = find.text(text);
        expect(
          finder,
          findsWidgets,
          reason: 'the $label stat ($text) must survive the degradation — the '
              '`Wrap` moves the signal bar to its own run, it may not discard '
              'or reformat a stat',
        );

        for (final element in finder.evaluate()) {
          final widget = element.widget as Text;
          expect(
            widget.overflow,
            isNot(TextOverflow.ellipsis),
            reason: 'the $label must never ellipsize: an ellipsis lands '
                'mid-number',
          );
          expect(widget.maxLines, isNull,
              reason: 'the $label must not be line-capped');
        }
        expect(
          canShrink(finder.first),
          isFalse,
          reason: 'the $label must not be a flex child — it keeps its '
              'intrinsic width and the stats group wraps instead',
        );
      }
    });
  });
}
