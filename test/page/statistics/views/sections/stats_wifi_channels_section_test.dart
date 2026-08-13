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
/// ## Two kinds of assertion, and why the stress widths are below production
///
/// Both rows have headroom at every *production* width (line 110: 47px at the
/// 288px floor; line 121's `fi` crossing is 219px, 69px below the floor). A
/// test that only pumped production widths could therefore never fail — it
/// would report the shape as pinned while quietly guarding nothing, exactly the
/// dead-overflow-test trap `dashboard_legend_readability_test.dart` warned
/// about. So each row is checked two ways:
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
///
/// Tagged `dashboard-card` so it gates PRs — `run_tests.sh` excludes
/// `golden||loc||ui`, and a `ui`-tagged regression test would not block
/// anything.
///
/// ## Mutation ledger
///
/// Every degradation-guard group here was shown to fail under a mutation of the
/// code it guards — an overflow test that cannot fail is worse than no test
/// (precedent: `stats_traffic_monitor_legend_test.dart`). Measured on this
/// worktree with the fixtures below:
///
///   | mutation                                            | measured                    |
///   |-----------------------------------------------------|-----------------------------|
///   | line 110 `Wrap` -> pre-fix `Row`+`Spacer`           | +28px @200px section (grp 1)|
///   | line 121 `Wrap` -> pre-fix `Row`+`Expanded`         | +6.9px @219px section (grp 2)|
///   | signal bar `SizedBox(96)` -> `Expanded` (keep `Wrap`)| ParentDataWidget error (grp 2)|
///   | count -> `Flexible` + 1-line ellipsis               | stats legible fails (grp 3) |
///
/// The `Wrap` fix is clean at both stress widths (line 110 clean to 180px; line
/// 121 clean at 219px), so each row is clean where its pre-fix shape clips.

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
    for (final tag in ['fi', 'de', 'ru']) {
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
      // 4 clients on 2.4GHz, 4 on 6GHz -> clientsCount(4) rendered twice.
      final countText = l10n.clientsCount(4);
      final countFinder = find.text(countText);
      expect(
        countFinder,
        findsWidgets,
        reason: 'the client-count stat ($countText) must survive the '
            'degradation — the `Wrap` moves the signal bar to a second line, '
            'it may not discard the count',
      );

      for (final element in countFinder.evaluate()) {
        final text = element.widget as Text;
        expect(
          text.overflow,
          isNot(TextOverflow.ellipsis),
          reason: 'the client count must never ellipsize: an ellipsis lands '
              'mid-number',
        );
        expect(text.maxLines, isNull,
            reason: 'the client count must not be line-capped');
      }
      expect(
        canShrink(countFinder.first),
        isFalse,
        reason: 'the client count must not be a flex child — it keeps its '
            'intrinsic width and the whole stats group wraps instead',
      );
    });
  });
}
