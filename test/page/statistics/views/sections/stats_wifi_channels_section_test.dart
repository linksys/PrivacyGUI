@Tags(['dashboard-card'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/client_connection_detail.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/page/statistics/views/sections/stats_wifi_channels_section.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';

import '../../../../golden_test/golden_framework/mocks/mock_statistics.dart';
import '../../../../util/app_test_fonts.dart';
import '../../../../util/overflow_probe.dart';
import '../../../../util/statistics/stats_section_probe.dart';

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
///    `AppText.bodySmall('<Channel> <channel>  ·  <bandwidth>')`. `Spacer` is an
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
/// crossing), and three things could eat it — localizing the hardcoded `'Ch '`
/// literal, a 3-digit 6GHz channel (`Ch 233 (Auto)`), or simply a narrower
/// realization. The AC is therefore a measurement of the rows, not "N gate
/// coordinates removed".
///
/// **#1270 spent that headroom.** The prefix is now `loc(context).channel`, so the
/// widest `channel` translation is a layout input rather than a curiosity — and
/// **#1298 changed which locale that is**. `tr` used to ship
/// `'Channel (Kanal)'`, the English term with the Turkish glossed in parentheses,
/// and was the widest of the 26 at 212.5px; with the gloss removed it renders
/// 155.1px and `th` is now the widest at 188.4px. Either way the prefix is
/// affordable *only* because #1264 replaced the `Row` + `Spacer` with a `Wrap`:
/// the pre-fix shape overflows the production floor in `th` (and in `tr` too,
/// before #1298) and in all 26 locales at 224px and below. So line 110's guard is
/// not a courtesy sweep over a couple of locales — the AC-1 ladder group walks all
/// 26 of them, and the group above samples the four widest with the ranking
/// written down where a future ARB change has to re-take it.
///
/// ## Four kinds of assertion, and why the stress widths are below production
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
///      AC-1 names. A single degradation guard at one width can sit in a pocket
///      of cleanliness: this file's 219px guard passed while a nested `Row(min)`
///      clipped at 216px, 3px away. Walking the ladder is what closes that gap,
///      and it is the group that caught it. Line 121 walks it in the locales that
///      break first (`fi`, `ja`, `ko`, `vi`); line 110 walks it in **all 26**,
///      because since #1270 the widest `channel` translation is a layout input
///      and no other suite measures it (see that group's own header).
///   4. **Geometry guard (production widths).** The three above all read
///      `RenderFlex` overflow, which cannot see *where* a child landed. A
///      `Wrap` under a loose width constraint lays out visibly wrong and
///      overflows nothing, so the row's horizontal span is asserted directly.
///
/// Tagged `dashboard-card` so it gates PRs — `run_tests.sh` excludes
/// `golden||loc||ui`, and a `ui`-tagged regression test would not block
/// anything.
///
/// ## Mutation ledger
///
/// Every guard group here was shown to fail under a mutation of the code it
/// guards — an overflow test that cannot fail is worse than no test (precedent:
/// `stats_traffic_monitor_legend_test.dart`). Groups are numbered in declaration
/// order: **1** line 110 clean, **2** line 121 clean, **3** geometry, **4** stats
/// legible. Each mutation was applied alone against an otherwise clean tree, and
/// the whole table was **re-taken again for #1298** — the counts are of this
/// file's current 158 tests, not of the 43 it had when #1258 first measured it.
/// The `was` column is what the table read before that re-take, kept because
/// three rows moved and the reasons are the finding:
///
///   | mutation                                             | fails (of 158)              | was |
///   |------------------------------------------------------|-----------------------------|-----|
///   | line 110 `Wrap` -> pre-fix `Row`+`Spacer`            | 84 — grp 1: 70, 2: 11, 3: 3 | 87  |
///   | line 121 outer `Wrap` -> pre-fix `Row`+`Expanded`    | 5 — grp 1: 1, 2: 4          | 9   |
///   | stats `Wrap` -> `Row(min)`+`AppGap.md` (see below)   | 5 — grp 1: 1, 2: 4          | 7   |
///   | both of those at once (the real pre-fix line 121)    | 5 — grp 1: 1, 2: 4          | —   |
///   | signal bar `SizedBox(96)` -> `Expanded` (keep `Wrap`)| 34 — grp 2: 33, 4: 1        | 158 |
///   | count -> `Flexible` + 1-line ellipsis                | 158 — ParentDataWidget      | 158 |
///   | `snrValue` -> 1-line ellipsis (no `Flexible`)        | 1 — grp 4                   | 1   |
///   | `snrValue` -> `Flexible` + 1-line ellipsis           | 158 — ParentDataWidget      | 158 |
///   | `snrValue` -> 1-line ellipsis on **2.4GHz only**     | 1 — grp 4                   | 1   |
///   | per-radio `Column` `stretch` -> `start`              | 3 — grp 3                   | 3   |
///   | band+channel `Wrap`: drop `spaceBetween`             | 2 — grp 3                   | 2   |
///
/// Five things to read out of the attributions rather than guess at:
///
///  - **Row 1 moved because of #1298, and only by `tr`'s three cases.** Re-running
///    that mutation with the `tr` gloss put back reproduces the old 87 / grp 1: 73
///    exactly, so the row was accurate when taken; the three cases it loses are
///    this file's 288px `tr` sample case and the ladder's 288px and 256px `tr`
///    cases. See the ladder group's own table for the pixel figures.
///  - **Rows 2, 3 and 4 moved because of #1271, which was never re-taken.** #1271
///    made the signal bar conditional (`if (snr != null)`) and the readout
///    `snrUnavailable`, and `averageSnr` is null for a radio with no clients
///    (`core/utils/wifi.dart`, `averageSnr`'s own doc). Groups 1 and 3 pump
///    `_wideChannelWifiData`, which has **no clients** — so those groups now
///    render no bar at all, and a mutation of the bar or of the stats pair cannot
///    reach them. That is also why row 4 reads 34 and not 158: the
///    `Flexible`-inside-`Wrap` framework error throws only where the bar is
///    built, which after #1271 is groups 2 and 4 alone.
///  - **Line 121's pre-fix shape is caught at one rung, not at the degradation
///    width.** Rows 2 and 3 fail the *same* 5 cases, and so does applying both at
///    once (which is the actual pre-#1258 shape, not a half of it): the 192px rung
///    in `fi`, `ja`, `ko`, `vi`. Group 2's 219px degradation guard does not
///    discriminate for any of them, because the nested stats `Wrap` re-flows
///    internally there and leaves the `Expanded` bar something to shrink into. So
///    the ladder is what guards that row, not the degradation width — worth
///    knowing before #1297 touches the same bar.
///  - **Groups 1 and 2 do not have separate eyes.** The probe returns *every*
///    `RenderFlex` incident in the pumped tree, so a mutation to either row fails
///    whichever group pumps the section at a width where that row overflows. The
///    two groups differ in fixture and width ladder, not in what they can see —
///    which is why mutating line 121 still fails one of group 1's cases. A future
///    reader chasing one row's regression should read the incident text in the
///    failure, not the group name.
///  - **A `Flexible` inside a `Wrap` is a framework error, not an overflow.** The
///    two remaining 158-failure rows throw `Incorrect use of ParentDataWidget`,
///    which fails every test in the file including the unrelated ones. That is
///    loud but undiscriminating, and it is exactly why the two *bare*-ellipsis
///    mutations (1 failure each, group 4) are the ones that prove group 4 earns
///    its keep.
///
/// The last two rows are group 3, and they are a different *kind* of guard from
/// everything above them. Every other assertion in this file reads `RenderFlex`
/// overflow, which is blind to position — the `Wrap` was for one revision
/// laid out visibly wrong (channel string no longer right-aligned, whole radio
/// block drifted to the centre of the section) while all 43 overflow tests
/// stayed green. `spaceBetween` needs a **tight** width to have anything to
/// distribute, and the per-radio `Column`'s `CrossAxisAlignment.start` handed
/// the `Wrap` a loose one. Group 3 asserts the geometry directly; see its own
/// header for the measured before/after table.
///
/// Re-taking those two rows for #1270 is what exposed the two defects group 3
/// itself had. Both are fixed in this revision and the row counts above are the
/// numbers *after* the fix; before it, `stretch` -> `start` failed 1 case instead
/// of 3:
///
///  - the span assertion compared the `Wrap` against its **immediate parent**,
///    and `start` shrink-wraps the parent `Column` together with the `Wrap`
///    inside it, so the check passed on the one regression it exists to catch;
///  - the three widths were pumped as `sectionWidth: 288/537/841` on a **320px**
///    screen, and a section wider than the viewport is clamped to it, so the two
///    wide cases both measured 270px of content.
///
/// Group 3's `spaceBetween` row fails 2 of 3 rather than 3 of 3 for a reason that
/// is not a gap: at the 288px floor the channel string is expected on its own
/// run, and a `Wrap` whose runs each hold one child looks identical with and
/// without `spaceBetween`. That width is covered by the run-arrangement
/// assertions instead.
///
/// The `snrValue` rows are the reason group 4 asserts on **both** stats. An
/// earlier revision of this file checked only `clientsCount`, and the first two
/// of those mutations passed it: the group's own doc comment promised "the count
/// **and** SNR", while the SNR was unguarded.
///
/// The last row is the reason group 4 pins an **exact instance count per string**
/// and checks every element the finder returns. The two radios do not render the
/// same SNR — 2.4GHz averages to `snrValue(37)`, 6GHz to `snrValue(36)` — so a
/// revision that listed only `snrValue(36)` under `findsWidgets` (>= 1) matched
/// the 6GHz widget and never looked at 2.4GHz: an ellipsis on that radio alone
/// passed 43/43. A `Flexible` on one radio is caught only incidentally, by
/// `Flexible`-inside-`Wrap` throwing a ParentDataWidget error; the bare ellipsis
/// had nothing catching it.
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

  /// Pumps the real [StatsWifiChannelsSection] once with the section sized to
  /// [sectionWidth] on a [screenWidth] screen, and returns the RenderFlex
  /// overflows beyond the gate's own tolerance.
  ///
  /// [sectionWidth] defaults to what the Statistics page would give a section
  /// on that screen ([sectionWidthFor]); the degradation-guard tests pass an
  /// explicit narrower value to reach below the production floor while keeping
  /// the screen (and therefore ui_kit's layout regime) realistic.
  ///
  /// The scaffolding — margin arithmetic, `lib/app.dart`'s theme+locale wiring,
  /// the one-pump rule — is [probeSectionOverflow] since #1270; this wrapper only
  /// binds this file's section and swaps in the fixture under test, so every call
  /// below is unchanged.
  Future<List<OverflowIncident>> overflowsAt({
    required WidgetTester tester,
    required double screenWidth,
    required Locale locale,
    required WifiData wifiData,
    double? sectionWidth,
  }) =>
      probeSectionOverflow(
        tester,
        section: const StatsWifiChannelsSection(),
        screenWidth: screenWidth,
        locale: locale,
        overrides: statisticsOverrides(wifiData: wifiData),
        sectionWidth: sectionWidth,
      );

  String tagOf(Locale l) => l.countryCode == null || l.countryCode!.isEmpty
      ? l.languageCode
      : '${l.languageCode}_${l.countryCode}';

  Locale localeFor(String tag) =>
      AppLocalizations.supportedLocales.firstWhere((l) => tagOf(l) == tag);

  /// The narrow realizations that matter, and why — see [narrowStatsScreens].
  /// 320px yields the 288px section that is these rows' worst case: the
  /// production floor #1258 measured, where line 110 had 47px of headroom before
  /// #1270 spent it on the localized prefix.
  const narrowScreens = narrowStatsScreens;

  group('band + channel row (line 110) is clean under wide data (#1258)', () {
    // Two stressors, not one. `_wideChannelWifiData` carries a 3-digit 6GHz
    // channel in auto mode at 160MHz — the widest *data* #1258 named — and since
    // #1270 localized the prefix the row is locale-dependent too.
    //
    // WHICH FOUR, AND WHY THEY CHANGED IN #1298
    //
    // Until #1298 the sample was `en, de, th, tr`, because `tr` shipped
    // `'Channel (Kanal)'` — the English term with the Turkish glossed in
    // parentheses — and was the widest of the 26 by a wide margin. #1298 fixed
    // that ARB value to plain `'Kanal'`, which moved `tr` from first to
    // joint-16th and made the old sample's stated reason false. Re-measured on
    // this worktree (rendered width of the composed `bodySmall` string
    // `<channel> 233 (Auto)  ·  160MHz`, real fonts, 6GHz radio):
    //
    //   | locale | width   | note                                     |
    //   |--------|---------|------------------------------------------|
    //   | `th`   | 188.4px | widest; was second                       |
    //   | `ja`   | 171.8px | second                                   |
    //   | `en`   | 170.0px | third **and** the control                |
    //   | `fi`   | 164.8px | fourth                                   |
    //   | `tr`   | 155.1px | was 212.5px, first, before #1298         |
    //   | `de`   | 155.1px | tied with `tr`, `da`, `sv`, `nb`, `id`   |
    //   | `ko`   | 146.0px | narrowest                                |
    //
    // So the sample is now the top four, which happens to include `en`. `de`
    // (what #1258 originally pumped) and `tr` are dropped from *this* group
    // rather than kept for continuity: at 155.1px they are neither worst nor
    // representative, and the 26-locale ladder below covers them at four widths
    // regardless.
    //
    // These four are the worst cases, not the whole obligation: the full 26 × 4
    // ladder is the `AC-1 ladder` group below.
    for (final tag in ['en', 'th', 'ja', 'fi']) {
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
              'pre-fix `Row` + `Spacer` clips here: ${overflows.join(', ')}',
        );
      },
    );

    // #1270's AC-1: the localized prefix, re-measured clean at 288 / 256 / 224 /
    // 192px sections in **all 26 locales**.
    //
    // WHY ALL 26 AND NOT THE WORST FEW
    //
    // Before #1270 this row was locale-independent — both texts were data — so
    // the group above samples locales only as a courtesy. Localizing the prefix
    // makes the widest `channel` translation a *layout input*, and which locale
    // that is, is an ARB fact that loc can change without touching this repo.
    // Nothing else guards it: the section is not in `UspWidgetSpecs.all`, so the
    // #1183 gate never scans it, and the golden suite screenshots neither this
    // page at 320px nor 25 of these locales.
    //
    // Iterating `supportedLocales` rather than a hardcoded list also means a 27th
    // locale is covered the day it is added, without anyone remembering to.
    //
    // MEASURED (#1270, re-taken for #1298; one pump per case, real fonts, 2px
    // tolerance, `<channel> 233 (Auto)` / 160MHz data). The pre-fix rows are the
    // same mutation run twice, once with #1298's ARB fix and once with the `tr`
    // gloss put back, so the two are directly comparable:
    //
    //   | shape                              | 288px  | 256px    | 224 / 192px |
    //   |------------------------------------|--------|----------|-------------|
    //   | `Wrap` (shipped)                   | clean  | clean    | clean       |
    //   | pre-#1264 `Row`+`Spacer`, pre-1298 | tr, th | 16 of 26 | all 26      |
    //   | pre-#1264 `Row`+`Spacer`, now      | th     | 15 of 26 | all 26      |
    //
    // Two things to read out of it rather than guess at:
    //
    //  - **#1298 took `tr` off the pre-fix shape's failure list at the floor.**
    //    The three cases it removes are exactly `tr`'s (this group's 288px
    //    sample case, and the ladder's 288px and 256px cases), so at the
    //    production floor the pre-fix `Row` would now overflow in `th` alone
    //    (+3.0) instead of `th` plus `tr` (+27.0/+13.0). At 192px the worst
    //    locale is now `th` (+99.0/+85.0); it was `tr` (+123.0/+109.0), and `tr`
    //    reads +66.0/+52.0 with the gloss gone. What #1298 did *not* change is
    //    the shipped verdict: 26 clean at all four widths, before and after.
    //  - **The pre-#1298 form of this table over-claimed the 256px column.** It
    //    merged 256 / 224 / 192px into one cell reading "all 26". Re-running the
    //    mutation with the old ARB restored gives 16 of 26 at 256px — the 10
    //    narrowest locales are clean there — and only 224 / 192px are all 26.
    //    That correction is not #1298's doing; it is what re-taking a merged
    //    cell exposes, and it is why the column is split here.
    //
    // #1264's `Wrap` is still what makes the localized prefix a pure correctness
    // change, and this group is what records that it stays one.
    for (final locale in AppLocalizations.supportedLocales) {
      for (final section in [288.0, 256.0, 224.0, 192.0]) {
        testWidgets(
          'AC-1 ladder: clean at a ${section.toStringAsFixed(0)}px section '
          'in ${tagOf(locale)}',
          (tester) async {
            final overflows = await overflowsAt(
              tester: tester,
              // 320px keeps ui_kit's narrowest layout regime while the explicit
              // section width walks below the 288px production floor.
              screenWidth: 320.0,
              sectionWidth: section,
              locale: locale,
              wifiData: _wideChannelWifiData,
            );
            expect(
              overflows,
              isEmpty,
              reason: 'the localized channel prefix overflows the band+channel '
                  'row in ${tagOf(locale)} at a '
                  '${section.toStringAsFixed(0)}px section. If a `channel` '
                  'translation grew, the prefix no longer fits the width this '
                  'row is given and #1270\'s premise — that #1264\'s `Wrap` '
                  'absorbs the cost — has stopped holding: '
                  '${overflows.join(', ')}',
            );
          },
        );
      }
    }
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
    // re-deriving which locale dominates. `widestStatLocales` below covers the
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

  group('the band+channel row still spans the section (#1258)', () {
    // WHY THIS GROUP EXISTS
    //
    // Every other guard in this file reads `RenderFlex` overflow, which is blind
    // to *position*: a row can be laid out completely wrong and still be clean.
    // The `Wrap` that replaced the `Row` + `Spacer` was, for one revision,
    // exactly that — visually broken and green on all 43 tests.
    //
    // `WrapAlignment.spaceBetween` only has an effect when the `Wrap` gets a
    // **tight** width. The per-radio `Column` handed it `CrossAxisAlignment
    // .start`, i.e. a loose constraint, so the `Wrap` shrink-wrapped to its
    // intrinsic width, `spaceBetween` had no free space to distribute, and it
    // silently degraded to a plain `spacing: AppSpacing.lg` gap. Measured
    // against the pre-#1258 `Row` + `Spacer` at 288 / 537 / 841px sections:
    //
    //   |                        | band left      | channel right   |
    //   |------------------------|----------------|-----------------|
    //   | pre-fix `Row`+`Spacer` | 25 / 25 / 25   | 263 / 512 / 816 |
    //   | `Wrap` under `start`   | 30 / 154 / 306 | 238 / 363 / 515 |
    //   | `Wrap` under `stretch` | 25 / 25 / 25   | 263 / 512 / 816 |
    //
    // So under `start` the channel string stopped being right-aligned and the
    // whole radio block drifted to the centre of the section — at 841px the band
    // sat 281px from where it belonged. `stretch` restores the pre-fix geometry
    // exactly. Reverting either `stretch` or `spaceBetween` leaves every other
    // test in this file green (155 of 158 in the re-taken ledger), which is why
    // this is asserted directly.
    //
    // The assertion is "the row spans the section", not a pixel table: it pins
    // the property the `Spacer` provided without freezing font metrics, so a
    // theme or font change does not fail it. Two ways of writing that turned out
    // to be traps, both live in this group until #1270 re-measured it and both
    // now guarded in the body: comparing the `Wrap` to its **immediate parent**
    // (which shrink-wraps with it, so the check tracks the bug instead of
    // catching it), and pumping a section **wider than the screen** (which the
    // viewport clamps, collapsing three widths onto one layout).
    //
    // ## `oneRun`, and why #1270 had to add it
    //
    // Right-alignment is only a property of a row that *is* one run. Localizing
    // the prefix cost this row its last few pixels at the production floor: with
    // the wide-6GHz fixture in `en`, `Channel 11  ·  20/40MHz` (171.9px) plus the
    // band (2.4GHz) plus the `AppSpacing.lg` gap no longer fit the 238px the
    // `Wrap` gets from a 288px section — it misses by ~3.5px — so the channel
    // string drops to its own run and ends at 196.9px instead of flush at 263px.
    //
    // That is the fix doing its job, not a regression: the alternative at that
    // width is the pre-#1264 overflow. But it means "flush right" cannot be
    // asserted unconditionally any more, and skipping the assertion at 288px
    // would leave the floor — the width that matters most — with no geometry
    // guard at all. So each width states which arrangement it expects and the
    // test asserts *that*: still one run above the floor, stacked at it. A change
    // that shortens the string enough to fit one run at 288px fails here, which
    // is correct — the expectation is a measurement, and it has to be re-taken.
    // Stated as **screens**, not section widths, and that is load-bearing. The
    // probe sizes a section with `SizedBox(width: …)` inside the viewport, so a
    // section wider than the screen is clamped to the screen and the case
    // silently becomes a different, narrower measurement. The pre-#1270 form of
    // this group asked for 288 / 537 / 841px sections on a **320px** screen, so
    // the two wide cases both rendered 270px of content — three cases, two
    // layouts, and the names said otherwise. Each screen below is the one the
    // Statistics page actually produces that section on ([narrowStatsScreens]),
    // and the harness-sanity assertion in the body now fails if that ever stops
    // being true.
    const geometryCases = <({double screen, bool oneRun})>[
      (screen: 320.0, oneRun: false),
      (screen: 601.0, oneRun: true),
      (screen: 905.0, oneRun: true),
    ];
    for (final geometry in geometryCases) {
      final section = sectionWidthFor(geometry.screen);
      testWidgets(
        geometry.oneRun
            ? 'channel string stays right-aligned at a '
                '${section.toStringAsFixed(0)}px section'
            : 'channel string drops to its own run at a '
                '${section.toStringAsFixed(0)}px section',
        (tester) async {
          final overflows = await overflowsAt(
            tester: tester,
            screenWidth: geometry.screen,
            locale: localeFor('en'),
            wifiData: _wideChannelWifiData,
          );
          expect(overflows, isEmpty,
              reason: 'precondition: the row must be clean at this width');

          // The `Wrap` is the parent of the band text. Its own width is the
          // measurement that matters: shrink-wrapped means `spaceBetween` is
          // dead, tight means it is doing the `Spacer`'s job.
          final bandFinder = find.text('2.4GHz');
          expect(bandFinder, findsOneWidget);

          Element? wrapElement;
          bandFinder.evaluate().single.visitAncestorElements((a) {
            if (a.widget is Wrap) {
              wrapElement = a;
              return false;
            }
            return true;
          });
          expect(wrapElement, isNotNull,
              reason: 'the band text must sit inside the band+channel `Wrap`');

          final wrapBox = wrapElement!.renderObject as RenderBox;

          // A shrink-wrapped `Wrap` is narrower than the section content box; a
          // stretched one fills it. This is the `start`-vs-`stretch` difference,
          // expressed without hardcoding text widths.
          //
          // The reference is the **section box the probe built**, not the
          // `Wrap`'s immediate parent. Comparing against the parent reads like
          // the same check and is blind: `CrossAxisAlignment.start` shrink-wraps
          // the per-radio `Column` *together with* the `Wrap` inside it, so the
          // two stay equal and the assertion passes on precisely the regression
          // it exists to catch. Measured while re-taking the ledger for #1270:
          // in the parent-relative form the `stretch` -> `start` mutation failed
          // only the 288px case (via `oneRun` below, incidentally), leaving
          // 537/841px green.
          //
          // The insets between the two are summed off the tree rather than
          // hardcoded: `AppCard` and `LayoutBlock` each add an `AppSpacing.md`
          // today (`stats_section_card.dart:29,53`), and a ui_kit change to
          // either must not silently re-baseline this test.
          var inset = 0.0;
          RenderBox? sectionBox;
          wrapElement!.visitAncestorElements((a) {
            final w = a.widget;
            if (w is SizedBox && w.width == section) {
              sectionBox = a.renderObject as RenderBox;
              return false;
            }
            if (w is Padding) inset += w.padding.horizontal;
            return true;
          });
          expect(sectionBox, isNotNull,
              reason: 'the probe wraps every section in a '
                  '`SizedBox(width: sectionWidth)`; this test measures against '
                  'it');

          // Harness sanity, and the reason the cases above are screens: a
          // `SizedBox` wider than the viewport is clamped to the viewport, and a
          // clamped case measures a narrower layout than its own name claims.
          expect(
            sectionBox!.size.width,
            closeTo(section, 0.5),
            reason: 'the harness must really render a '
                '${section.toStringAsFixed(0)}px section on a '
                '${geometry.screen.toStringAsFixed(0)}px screen. If this fails '
                'the section is being clamped to the viewport, so this case is '
                'silently measuring some other width.',
          );

          expect(
            wrapBox.size.width,
            closeTo(section - inset, 1.0),
            reason: 'the band+channel `Wrap` must be stretched to the full '
                'section content width (${section - inset}px of the '
                '${section.toStringAsFixed(0)}px section, after ${inset}px of '
                'card insets), not shrink-wrapped to its intrinsic width — '
                'under a loose constraint `WrapAlignment.spaceBetween` has no '
                'free space to distribute and degrades to a plain `spacing` '
                'gap, which drifts the whole radio block to the centre of the '
                'section (measured: band at 154px instead of 25px on a 537px '
                'section). Check the per-radio `Column` is '
                '`CrossAxisAlignment.stretch`.',
          );

          // And the channel string is actually pushed to the far edge, which is
          // what the `Spacer` did. Guards `alignment: spaceBetween` itself:
          // removing it leaves the `Wrap` stretched but packs both texts left.
          //
          // The needle is built from the ARB key rather than hardcoded ('Ch 11'
          // until #1270 localized the prefix), so a `channel` translation change
          // cannot silently turn this into a `findsNothing` failure — or worse,
          // match some other text.
          final l10n = await AppLocalizations.delegate.load(const Locale('en'));
          final chanBox = tester.renderObject<RenderBox>(
              find.textContaining('${l10n.channel} 11').first);
          final wrapLeft = wrapBox.localToGlobal(Offset.zero).dx;
          final chanLeft = chanBox.localToGlobal(Offset.zero).dx;
          final chanRight = chanLeft + chanBox.size.width;
          final wrapRight = wrapLeft + wrapBox.size.width;

          if (geometry.oneRun) {
            expect(
              chanRight,
              closeTo(wrapRight, 1.0),
              reason:
                  'the channel string must end flush with the right edge of '
                  'the row, as it did under the pre-#1258 `Row` + `Spacer`. '
                  'Check `alignment: WrapAlignment.spaceBetween` is still on the '
                  'band+channel `Wrap`.',
            );
          } else {
            // Stacked: the string sits on a second run, so it starts at the left
            // edge of the `Wrap` and cannot also end flush right. Asserting both
            // edges is what keeps this a real check — a `Wrap` that had lost
            // `spaceBetween` *and* wrapped would still satisfy the left edge
            // alone, but then the band would not be flush left on run 1.
            final bandBox = tester.renderObject<RenderBox>(bandFinder);
            expect(
              chanLeft,
              closeTo(wrapLeft, 1.0),
              reason:
                  'at the production floor the channel string is expected on '
                  'its own run, flush with the left edge of the row.',
            );
            expect(
              bandBox.localToGlobal(Offset.zero).dx,
              closeTo(wrapLeft, 1.0),
              reason: 'the band must stay flush left on the first run.',
            );
            expect(
              chanBox.localToGlobal(Offset.zero).dy,
              greaterThan(bandBox.localToGlobal(Offset.zero).dy +
                  bandBox.size.height -
                  1.0),
              reason: 'the channel string must be *below* the band, i.e. on a '
                  'second run. If it is beside it, the row fits one run at a '
                  '288px section again — re-measure and flip `oneRun`, because '
                  'the flush-right guard should then cover this width too.',
            );
          }
        },
      );
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
    ///
    /// Takes the [Element] rather than a [Finder] so the caller can check
    /// **every** rendered instance. A `Finder`-shaped version invites
    /// `canShrink(finder.first)`, which checks one radio's widget and leaves the
    /// others unguarded — the same one-instance blind spot the `snrValue` fixture
    /// note below records.
    bool canShrink(Element stat) {
      var flexed = false;
      stat.visitAncestorElements((ancestor) {
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
      // ## Every rendered instance, and why the count matters
      //
      // The section renders one block per radio, so each stat appears **twice**.
      // The two radios do not necessarily render the *same* string, and the SNR
      // does not:
      //
      //   `computeSNR(signal, noise) = signal - noise` over a band's clients.
      //   `signalStrength: -55 - i` against `noise: -95` gives 40..33 dB, and
      //   the bands split by parity of `i`:
      //
      //     2.4GHz (even i = 0,2,4,6): 40, 38, 36, 34 -> avg 37 -> `snrValue(37)`
      //     6GHz   (odd  i = 1,3,5,7): 39, 37, 35, 33 -> avg 36 -> `snrValue(36)`
      //
      // An earlier revision listed only `snrValue(36)` and asserted with
      // `findsWidgets` (>= 1). That matched the 6GHz widget alone and left the
      // 2.4GHz SNR entirely unguarded: an `overflow: ellipsis` applied to just
      // that radio passed 43/43. Both strings are therefore listed, and each is
      // pinned with `findsNWidgets(1)` rather than `findsWidgets` — an exact
      // count is what makes a missing or reformatted instance fail here instead
      // of being absorbed by its sibling.
      //
      // `clientsCount(4)` is genuinely the same on both radios (4 clients each),
      // so it is the one stat that legitimately appears twice.
      final stats = <({String label, String text, int instances})>[
        (label: 'client count', text: l10n.clientsCount(4), instances: 2),
        (label: '2.4GHz SNR', text: l10n.snrValue(37), instances: 1),
        (label: '6GHz SNR', text: l10n.snrValue(36), instances: 1),
      ];

      for (final stat in stats) {
        final label = stat.label;
        final finder = find.text(stat.text);
        expect(
          finder,
          findsNWidgets(stat.instances),
          reason: 'the $label stat (${stat.text}) must survive the degradation '
              'exactly ${stat.instances}x — the `Wrap` moves the signal bar to '
              'its own run, it may not discard or reformat a stat',
        );

        // Every instance, not just the first: the radios are rendered by the
        // same builder but a per-radio conditional would only break one of them.
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
          expect(
            canShrink(element),
            isFalse,
            reason: 'the $label must not be a flex child — it keeps its '
                'intrinsic width and the stats group wraps instead',
          );
        }
      }
    });
  });
}
