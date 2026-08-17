@Tags(['dashboard-card'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/client_connection_detail.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/page/statistics/views/components/stats_section_card.dart';
import 'package:privacy_gui/page/statistics/views/sections/stats_wifi_channels_section.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../golden_test/golden_framework/mocks/mock_statistics.dart';
import '../../../../util/app_test_fonts.dart';
import '../../../../util/dashboard/dashboard_card_probe.dart';
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
///  - **line 121** — the stats line. It was `clientsCount` + `snrValue` followed
///    by an `Expanded(AppLoader)`: the same cliff with the `Expanded` on the
///    progress bar instead of a `Spacer`. #1297 deleted the bar (and the section's
///    band-distribution donut) and moved the client count up beside the band, so
///    what is left is a lone `AppText` carrying the SNR — see `#1297 changed the
///    shape of both rows` below for what that leaves to guard.
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
/// ## #1297 changed the shape of both rows, and what this file guards
///
/// #1267 asked the dashboard twin whether its 96px SNR bar and its band
/// distribution donut said anything the numbers beside them did not, and deleted
/// both. #1297 asked the same two questions of *this* section and reached the same
/// answer, and then compressed the client count to the dashboard's icon + numeral
/// and moved it beside the band. The measurements are in
/// `stats_wifi_channels_section.dart`'s own comments. Four consequences here:
///
///  - **Line 121 is a lone text, so its guard changed kind.** The bar was the
///    fixed-width child the `Wrap` dropped to its own run when the stats stopped
///    fitting (old group-2 doc, point 4), and the count was the sibling that could
///    clip. With the bar deleted and the count moved up, nothing on this line can
///    collide with anything. The width guards therefore stopped measuring a live
///    cliff and became evidence *of the shape*: they pass because the line has one
///    child, and they fail if a second is put back — in `fi` the old pair measures
///    166.2px one-run against a `section - 50` content width, so its crossing is a
///    **216.2px** section. The degradation width moved twice for this: 219px, where
///    it measured the *bar* wrapping, then 200px, where it measures the pair. And
///    because a width guard only catches a sibling wide enough in the locale it
///    pumps, group 2 also asserts the structure directly — the first `Flex` or
///    `Wrap` above the SNR must be its radio block's `Column`.
///  - **The count is now the same shape on both surfaces.** #1297 first kept the
///    sentence here, on the measurement that it fitted; the user's call was that
///    fitting is not the same as being worth the width, and the compression is what
///    shipped. So `wifi_snr_render_parity_test.dart`'s `countIsCompact` flag is
///    `true` on both surfaces and its assertion is unconditional — the two surfaces
///    no longer diverge on anything that file tracks.
///  - **The 320px box scrolls now, and that is what the vertical group measures.**
///    Both deleted children lived inside the fixed `chartHeight` box, and nothing
///    in it scrolled: content taller than 320px was painted outside the card. The
///    compression made the *rows* taller, not shorter — moving the count beside the
///    band costs 27.2px there and takes the band row from one run to two in all 26
///    locales at the 288px floor, so a block costs 72px instead of 52px — which is
///    why the box was given `StatsSectionCard.scrollable`. Group 5 is now a scroll
///    budget: no radio count from 1 to 8 overflows, and the excess appears as a
///    measured `maxScrollExtent` instead.
///  - **Both removals are pinned, not merely done.** A `findsNothing` on
///    `AppLoader` / `InteractivePieChart` is the only thing that stops either
///    coming back as a "small addition" — the donut's real defect was invisible to
///    every width and height assertion in this file, because `AppPieChart` derives
///    its geometry from the `size` it is handed rather than the box it gets, so from
///    4 radios it painted *outside* its slot and `probeSectionOverflow` reported
///    nothing at all. The ledger below shows what each re-addition fails.
///
/// ## Five kinds of assertion, and why the stress widths are below production
///
/// Both rows have headroom at every *production* width (line 110: 47px at the
/// 288px floor; the post-#1297 stats line is a 69.8px text in a 238px box, and the
/// pair it replaced crossed at a 216.2px section, 71px below the floor). A test
/// that only pumped production widths could therefore never fail — it would report
/// the shape as pinned while quietly guarding nothing, exactly the
/// dead-overflow-test trap `dashboard_legend_readability_test.dart` warned about.
/// So each row is checked four ways, and the section as a whole a fifth:
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
///      and it is the group that caught it. Line 121 walks it in the locales whose
///      *pair* broke first (`fi`, `ja`, `ko`, `vi`); line 110 walks it in **all
///      26**, because since #1270 the widest `channel` translation is a layout
///      input and no other suite measures it (see that group's own header).
///   4. **Geometry guard (production widths).** The three above all read
///      `RenderFlex` overflow, which cannot see *where* a child landed. A
///      `Wrap` under a loose width constraint lays out visibly wrong and
///      overflows nothing, so the row's horizontal span is asserted directly.
///      Group 2's structural assertion is this kind too: a re-added sibling on the
///      stats line is a shape change that no width need reveal.
///   5. **Scroll budget (1..8 radios, #1297).** Everything above measures *width*.
///      The section's 320px `chartHeight` box is a height budget and per-radio
///      content is what spends it, so the failure is a function of radio count,
///      which no width ladder reaches. Since #1297 that box *scrolls*
///      (`StatsSectionCard.scrollable` + `CardScrollRegion`), so the group asserts
///      two things at once and they are not the same claim: **no** overflow at any
///      radio count from 1 to 8, and the measured `maxScrollExtent` the excess
///      became. The second is the load-bearing half — a scrolling region cannot
///      report `RenderFlex` overflow, so green on the first half alone would no
///      longer mean the content fits (see `cardContentScrollShortfall`).
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
/// order: **1** line 110 clean, **2** the stats line clean, **3** geometry, **4**
/// stats legible, **5** vertical budget, **6** removals stay removed. Each
/// mutation was applied alone against an otherwise clean tree, and the whole table
/// was **re-taken for the shipped #1297 shape** — 13 mutations against this file's
/// current **172** tests (43 at #1258, 158 at #1270, 168 at #1297's interim
/// revision, before the client count was compressed onto the band row). The
/// `parity` column is `wifi_snr_render_parity_test.dart` (2 tests), run under the
/// same mutation, because #1297 made both of that file's surface flags
/// unconditional and the two suites now overlap:
///
///   | mutation                                              | fails (of 172)                     | parity |
///   |-------------------------------------------------------|------------------------------------|--------|
///   | band+channel `Wrap` -> pre-#1258 `Row`+`Spacer`       | 117 — grp 1: 90, 2: 17, 3: 3, 5: 7 | 0 of 2 |
///   | count back on the SNR line as a sentence, plain `Row`  | 11 — grp 2: 6, 5: 3, 1: 1, 4: 1    | 1 of 2 |
///   | the same, `Row(mainAxisSize: min)` (see below)         | 11 — identical attribution         | 1 of 2 |
///   | `snrValue` -> 1-line ellipsis                         | 1 — grp 4                          | 0 of 2 |
///   | `snrValue` -> 1-line ellipsis on **2.4GHz only**       | 1 — grp 4                          | 0 of 2 |
///   | count numeral -> 1-line ellipsis                      | 1 — grp 4                          | 0 of 2 |
///   | count numeral -> `Flexible` + 1-line ellipsis          | 1 — grp 4                          | 0 of 2 |
///   | drop the count's `Semantics(label:)`                   | 1 — grp 4                          | 1 of 2 |
///   | per-radio `Column` `stretch` -> `start`                | 3 — grp 3                          | 0 of 2 |
///   | band+channel `Wrap`: drop `spaceBetween`               | 2 — grp 3                          | 0 of 2 |
///   | **re-add the 96px signal bar** (#1297 revert)          | 3 — grp 2: 1, 6: 2                 | 1 of 2 |
///   | **re-add the band donut** (#1297 revert)               | 48 — grp 2: 34, 4: 1, 5: 11, 6: 2  | 1 of 2 |
///   | **`scrollable: true` -> `false`** (#1297 revert)       | 11 — grp 5                         | 0 of 2 |
///
/// The dashboard twin's suite (`wifi_performance_readability_test.dart`, 15 tests)
/// stayed green under all 13. That is the expected result and it belongs in a
/// sentence rather than a column of identical values: these mutations are local to
/// this section, and `parity` is the only place the two surfaces meet.
///
/// Four rows left the table when the code they mutated did: `line 121 outer Wrap
/// -> Row+Expanded`, `signal bar SizedBox(96) -> Expanded`, `both at once`, and
/// the two ParentDataWidget rows that reported "all 168 fail" — a `Flexible` was
/// illegal because the mutated text sat directly in a `Wrap`. The numeral now
/// lives in a `Row`, so `Flexible` is legal there and `count numeral ->
/// Flexible` is a real one-case catch instead of a framework blow-up; the
/// #1297-revert rows at the bottom guard the deleted widgets from the other
/// direction.
///
/// Eight things to read out of the attributions rather than guess at:
///
///  - **Row 1 got much louder without changing, because the row it mutates now
///    carries the count.** It read 87 at #1270, 85 after #1298 took `tr`'s gloss
///    away (grp 1: 70), and **117** now (grp 1: 90). Nothing about the mutation
///    or the ladder moved: compressing the count onto the band row added 27.2px to
///    the row this mutation reverts, so the pre-#1258 `Row` + `Spacer` overflows
///    in far more locale × width cases than it used to. A ledger row is a
///    measurement of the tree, and this one is the cheapest possible reminder of
///    it — the number changed while the test and the mutation both stood still.
///  - **Row 1's group-5 cases are *vertical* catches and they read backwards.**
///    They fail because under a `Row` + `Spacer` the band row stops wrapping to
///    two runs, so every block drops from 72px to 52px and the measured scroll
///    extents (40 / 112 / 256px) are all wrong in the *smaller* direction. The
///    expectation is a measurement, so a change that makes the section shorter
///    fails it too; each case's reason text says what to do.
///  - **Rows 2 and 3 are the #1297 decision itself, reverted.** Putting the
///    `clientsCount` sentence back on the SNR line fails 11 cases whose spread is
///    the whole argument for the compression: the four 192px ladder rungs in `fi`,
///    `ja`, `ko`, `vi` and the 200px degradation guard (the pair clips where a
///    lone text does not), the structural assertion (the SNR gains a sibling), the
///    group-4 legibility case, one of group 1's rungs (shared eyes, below), and
///    three of group 5's — because a band row without the count fits one run, so
///    the section is 20px per radio shorter and the scroll extents stop
///    reproducing. **The horizontal saving and the vertical cost are guarded by
///    different groups, and reverting the decision fails both.**
///  - **Groups 1 and 2 do not have separate eyes.** The probe returns *every*
///    `RenderFlex` incident in the pumped tree, so a mutation to either row fails
///    whichever group pumps the section at a width where that row overflows. The
///    two groups differ in fixture and width ladder, not in what they can see —
///    which is why re-adding the count sentence fails one of group 1's rungs (the
///    192px `fi` one) as well as four of group 2's, and why row 1 reads 17 cases
///    in group 2 despite mutating the band row. A future
///    reader chasing one row's regression should read the incident text in the
///    failure, not the group name.
///  - **Group 4's four one-case rows are the ones that prove it earns its keep.**
///    An ellipsis or a `Flexible` on either stat fails exactly one test — the
///    "whole and unshrinkable at the narrowest width" case — and nothing else in
///    the file notices, because a truncated string is not a `RenderFlex` overflow.
///    The fifth row, dropping the count's `Semantics(label:)`, fails that same
///    case *and* the parity suite: an icon with a naked numeral and no accessible
///    name is a regression only a semantics assertion can see.
///  - **Re-adding the bar is caught by absence and by *shape*, never by width.**
///    The revert fails group 6's two `findsNothing` cases, the parity suite's
///    Statistics half, and — new in #1297 — the structural assertion, because the
///    bar's `Wrap` becomes the SNR text's first `Flex`/`Wrap` ancestor in place of
///    the per-radio `Column`. It still fails *nothing* on width or height: in `en`
///    the pair is 111.3px, so the bar's 104px fits the 238px row with no extra run.
///    Its cost was locale-dependent (7 of 26 at the floor) and groups 5 and 6 pump
///    `en`, which is why the removal needs assertions about the tree rather than
///    about pixels.
///  - **Re-adding the donut no longer overpaints — it throws.** Before #1297 this
///    revert cost 4 failures and the real defect (a 120px drawing in an 84px slot,
///    painting over the last radio) was invisible to a `RenderFlex` probe. Now the
///    same code fails **48** tests with `RenderFlex children have non-zero flex but
///    incoming height constraints are unbounded`: the chart's `Expanded` is inside
///    a `SingleChildScrollView`, and the two are mutually exclusive by
///    construction. The scroll net converted a silent overpaint into a loud
///    framework error, so the chart cannot come back *at all* while the box
///    scrolls — a stronger guarantee than any assertion here, and the reason
///    group 6's two `findsNothing` cases are now the cheap half of the guard.
///  - **The scroll net is load-bearing, and the two ways it fails read
///    differently.** `scrollable: true -> false` fails all 11 of group 5 and
///    nothing else. The four `fit` cases fail on `Expected: not null` — with no
///    `SingleChildScrollView` in the tree there is nothing to measure, which is
///    the assertion refusing to pass a card that cannot scroll. The other seven
///    fail on the overflow the scroll absorbs, at exactly the figure the case
///    names (`+256.0px bottom` at 8 radios). The parity suite does not move, which
///    is correct: it is a width oracle.
///  - **The parity column discriminates four rows, and only four.** It fails when
///    the count stops being a numeral (rows 2-3), when the count loses its
///    accessible name, when the bar comes back, and when the donut throws — the
///    four mutations that touch something both surfaces now claim. The nine
///    geometry rows leave it green, which is what a parity oracle should do: it
///    guards the *agreement*, not this section's layout. Taking this column has
///    its own trap, hit once on this branch: the runs for two rows were taken
///    while the helper was mid-edit, and the compile error reported `0 pass /
///    0 fail`. A suite that produces no results is not a suite with no failures,
///    so the column was re-taken with a **baseline row on the unmutated tree** in
///    front of it (2 pass / 0 fail).
///
/// The two group-3 rows are a different *kind* of guard from the width rows
/// around them. Every other horizontal assertion in this file reads `RenderFlex`
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
/// earlier revision of this file checked only `clientsCount`, and those mutations
/// passed it: the group's own doc comment promised "the count **and** SNR", while
/// the SNR was unguarded.
///
/// The `2.4GHz only` row is the reason group 4 pins an **exact instance count per
/// string** and checks every element the finder returns. The two radios do not
/// render the same SNR — 2.4GHz averages to `snrValue(37)`, 6GHz to `snrValue(36)`
/// — so a revision that listed only `snrValue(36)` under `findsWidgets` (>= 1)
/// matched the 6GHz widget and never looked at 2.4GHz: an ellipsis on that radio
/// alone passed 43/43. Until #1297 a `Flexible` on one radio was caught only
/// incidentally, by `Flexible`-inside-`Wrap` throwing; now that the numeral sits
/// in a `Row` nothing throws, and this group is the only thing that catches it.
///
/// The `Row(min)` row is the shape this file's first revision shipped. A
/// `Row(min)` hands its children unbounded width just as a `Row` does — it only
/// changes what the row asks of *its* parent — so nesting one inside the `Wrap`
/// reproduced #1258's own failure mode one level down: with the signal bar
/// already on its own run, the two stats clipped at a **216px** section in `fi`,
/// and at 192px in `fi`, `ja`, `ko` and `vi`. That is above the 192px floor AC-1
/// requires, and it sat 3px below the 219px degradation guard of the day, which
/// therefore never saw it. #1297 removed both the bar and the nesting, so the two
/// rows are now the same mutation — put a sentence back beside a lone text — and
/// the table records them failing the same 11 cases, one of which is the
/// degradation guard, because that width moved to where the *pair* crosses
/// (200px, `fi`) instead of where the bar did.

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
/// `clientsCount(n)` + `snrValue(n)` — the state #1258 measured (`+27px in fi at
/// a 192px section`), which then also drew a 96px signal bar until #1297 deleted
/// it. Two clients per band exercises the locale-dependent client-count string
/// that `fi` (`{count} asiakaslaitetta`) makes worst.
///
/// Non-zero clients are also what makes this fixture the one that renders the
/// stats pair at all: `averageSnr` is null for a radio with no client reporting a
/// noise floor (#1271), so `_wideChannelWifiData` renders `snrUnavailable` — a
/// shorter string than any `snrValue`, and therefore not the width to measure.
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

/// [n] radios on distinct bands, two clients each, for the vertical-budget group.
///
/// The bands past the third (`7GHz`, `8GHz`, …) are synthetic and deliberately
/// so: the quantity under test is how many per-radio blocks the fixed 320px
/// `chartHeight` box holds, not which bands a real router ships. `radioModels` is
/// whatever the WASM client reports, so the count is a data input this section has
/// no say over — 2 and 3 are today's hardware, 4 is already a bench build, and the
/// point of walking to 6 is that the box does not grow.
///
/// Distinct bands matter: `aggregateRadioClientStats` groups by band, so two
/// radios sharing one would leave the second with no clients and therefore
/// `snrUnavailable` (#1271) — a shorter row than the one being measured.
WifiData _radiosWithClients(int n) {
  final bands = [
    for (var i = 0; i < n; i++)
      switch (i) {
        0 => '2.4GHz',
        1 => '5GHz',
        2 => '6GHz',
        _ => '${i + 4}GHz',
      },
  ];
  return WifiData(
    codegenContext: WifiCodegenContext.empty,
    radioModels: [
      for (var i = 0; i < n; i++)
        WifiRadioUIModel(
          instancePath: 'Device.WiFi.Radio.${i + 1}.',
          band: bands[i],
          enable: true,
          transmitPower: -1,
          maxBitRate: 4800,
          // The widest data line 110 can carry (`<Channel> 233 (Auto)` at a
          // 3-digit bandwidth), so the first block wraps to two runs at the floor
          // exactly as the rest of this file measures it.
          channel: 233,
          autoChannelEnable: true,
          channelBandwidth: '320MHz',
          supportedStandards: 'a,n,ac,ax,be',
        ),
    ],
    wifiClientMap: {
      for (var i = 0; i < n * 2; i++)
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
      for (var i = 0; i < n * 2; i++)
        'mac$i': ClientConnectionDetail(
          band: bands[i % n],
          ssidName: 'Linksys',
        ),
    },
  );
}

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

  group('the stats line is clean, and the SNR is alone on it (#1258, #1297)',
      () {
    // This was "client + SNR row (line 121)", and #1297 dissolved the pair it
    // named: the client count moved up beside the band as an icon + numeral, and
    // the SNR is a lone `AppText` on its own line. `_wifiDataWithClients` still
    // gives both radios real, non-zero client counts, because that is what makes
    // the section render an SNR at all (`averageSnr` is null with no client
    // reporting a noise floor, #1271) and what puts a numeral beside the band.
    //
    // ## What is left to guard, now that there is no pair
    //
    // A lone text cannot clip a sibling, so the width story here is short:
    // measured intrinsic widths against the 238px content box at the 288px floor,
    // the widest SNR reading of the 26 locales is `zh` / `zh_TW`'s `snrValue` at
    // 69.8px (`snrUnavailable` is 41.4px in every locale — it is not translated),
    // so the line clears the floor with 168px to spare and wraps inside its own
    // paragraph if a translation ever grows.
    //
    // What the group therefore guards is that it *stays* alone. Put a second stat
    // back on this line and the pre-#1297 cliff returns exactly as #1258 measured
    // it: `clientsCount(4)` + `AppSpacing.md` + `snrValue(37)` — the fixture's own
    // strings — is 112.0px (`id`) to 166.2px (`fi`) one-run, so in `fi` a plain
    // `Row` clips at a 216.2px section, above the 192px floor AC-1 asks for. The
    // widths below are what catch that, and the structural assertion at the end of
    // the group catches it at *any* width, which is the reading that does not
    // depend on a locale staying widest.
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
              reason: 'the WiFi Channels stats line overflows in $tag at a '
                  '${screen.toStringAsFixed(0)}px screen '
                  '(${sectionWidthFor(screen).toStringAsFixed(0)}px section): '
                  '${overflows.join(', ')}',
            );
          },
        );
      }
    }

    // Degradation guard: the width at which a second stat on this line would
    // clip, so the line being clean here is evidence it is still a lone text.
    //
    // THIS WIDTH MOVED IN #1297, TWICE, AND WHY
    //
    // It was 219px, which is where the *bar* stopped fitting beside the stats:
    // the pre-fix `Row` + `Expanded(AppLoader)` measured +6.9px in `fi` there.
    // With the bar gone that crossing does not exist, and the shape to
    // discriminate became one level up — a `Row` handing two unconstrained stats
    // their intrinsic width. In `fi` that pair is 166.2px against a `section - 50`
    // content box, so its zero crossing is a **216.2px** section and the probe's
    // 2px tolerance puts the first *reportable* failure at 214px. A guard at 216px
    // would sit inside the tolerance and read clean under the very mutation it
    // exists to catch — the trap the AC-1 ladder caught the nested `Row(min)` in
    // (216px, 3px under the old guard). 200px in `fi` measures +16.2px under a
    // `Row`: unambiguous, and the same width line 110's degradation guard uses.
    //
    // Then the count moved off this line entirely, which is why the assertion at
    // the end of this group exists. A width guard can only catch a re-added
    // sibling that is *wide enough in the locale it pumps*; the structural one
    // catches it in every locale and at every width.
    testWidgets(
      'clean at a 200px section, where a second stat would clip (below floor, fi)',
      (tester) async {
        final overflows = await overflowsAt(
          tester: tester,
          screenWidth: 320.0,
          sectionWidth: 200.0,
          locale: localeFor('fi'),
          wifiData: _wifiDataWithClients,
        );
        expect(
          overflows,
          isEmpty,
          reason: 'the stats line must stay clean at a 200px section. A `Row` '
              'carrying the client count beside the SNR clips here '
              '(+16.2px in fi): ${overflows.join(', ')}',
        );
      },
    );

    // AC-1's own width ladder: 288px / 256px / 224px / 192px sections, "clean at
    // every width down to at least 192px".
    //
    // This is the group that caught the nested `Row(min)`: with the signal bar
    // (then still present) already dropped to its own run, `clientsCount` +
    // `snrValue` inside a `Row(min)` still took unbounded width and clipped at a
    // **216px** section in `fi` — above the 192px floor the AC asks for, and only
    // 3px below the 219px degradation guard of the day, which is why that guard
    // did not see it. A `Wrap` instead of a `Row(min)` moves the crossing off the
    // ladder entirely. #1297 removed the bar, so that mutation now reads as a
    // plain `Row` on the stats pair — the same clip at the same 216px, which is
    // why this ladder is still the guard that discriminates it and why the
    // degradation width above had to move rather than be deleted.
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
              reason: 'AC-1 requires the stats line to be clean down to a '
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

    // The structural reading of "alone on its line", which is the claim the whole
    // group rests on and the one no width can express.
    //
    // Every assertion above infers it: a lone text cannot clip, so cleanliness at
    // 200px is *evidence* the line has one child. That inference is only as good
    // as the locale it was measured in — put a narrow sibling back (a compact
    // count is 23.2px, not the sentence's 90.5px) and every width above stays
    // green while the line has quietly become a row again, with the pre-#1297
    // cliff waiting for the next ARB edit that widens either string.
    //
    // So walk up from the SNR text and require that the first ancestor doing
    // horizontal or vertical layout is the per-radio `Column`. A `Row` or `Wrap`
    // appearing before it is exactly the re-added sibling, in any locale, at any
    // width — which is why this is the case the ledger's `move the count back
    // onto the SNR line` row fails first.
    testWidgets('the SNR is the only child on its line (fi)', (tester) async {
      await overflowsAt(
        tester: tester,
        screenWidth: 320.0,
        locale: localeFor('fi'),
        wifiData: _wifiDataWithClients,
      );
      final l10n = await AppLocalizations.delegate.load(localeFor('fi'));

      // Both radios: 2.4GHz averages to snrValue(37), 6GHz to snrValue(36). The
      // count is per-radio too, so a revision that moved only one radio's back
      // would pass a single-radio check (the same trap group 4 documents).
      for (final reading in [l10n.snrValue(37), l10n.snrValue(36)]) {
        final snr = find.text(reading);
        expect(snr, findsOneWidget,
            reason: 'fixture no longer renders $reading');

        Widget? firstLayout;
        tester.element(snr).visitAncestorElements((element) {
          final widget = element.widget;
          if (widget is Flex || widget is Wrap) {
            firstLayout = widget;
            return false;
          }
          return true;
        });

        expect(
          firstLayout,
          isA<Column>(),
          reason: 'the SNR reading "$reading" sits inside a '
              '${firstLayout?.runtimeType} before reaching its radio block\'s '
              '`Column`, so something shares its line. #1297 moved the client '
              'count up beside the band precisely so this line carries one '
              'child: a sibling here restores the pair that clips a 216.2px '
              'section in `fi` (see the degradation guard above).',
        );
      }
    });
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
    // test in this file green (165 of 168 in the re-taken ledger), which is why
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

  group('client-count and SNR stats stay legible (#1258, #1297)', () {
    // The count and SNR are the section's content: an ellipsis lands mid-number,
    // and a half-shown statistic misinforms in a way a missing one does not
    // (design §2.10a point 2). So the AC is not "the stats are somewhere in the
    // tree" — it is that they are present, unellipsized, and not flex children
    // that could shrink.
    //
    // Until #1297 this doc opened by noting that the signal bar keyed nothing on
    // its own, so dropping it to a second line cost nothing readable. #1297 took
    // that observation to its conclusion and deleted the bar: a 96px track at
    // 1.92px per dB, with no tick and no unit, saturating at 50 dB, restated the
    // number beside it more coarsely than the number did.
    //
    // #1297 also compressed the count to the dashboard's icon + numeral and moved
    // it beside the band, so what this group asserts about it changed shape while
    // the obligation did not:
    //
    //  - the **numeral** is what has to stay whole. `'$clientCount'` is now the
    //    entire visible count, so an ellipsis on it would clip a digit — a worse
    //    failure than clipping the word "clients" ever was.
    //  - the **sentence** has to stay in the semantics tree. `Semantics(label:
    //    clientsCount(n), excludeSemantics: true)` is what makes this a *visual*
    //    compression rather than a dropped label, and it is what a screen reader
    //    and the E2E selector map read. Deleting it would leave a bare numeral
    //    beside a glyph with nothing naming it, which is why it is asserted here
    //    rather than left to the golden suite.

    /// True if a [Flexible] (or [Expanded], its subclass) sits between the stat
    /// and the layout that decides its width — i.e. the stat can be squeezed
    /// below its intrinsic width.
    ///
    /// Takes the [Element] rather than a [Finder] so the caller can check
    /// **every** rendered instance. A `Finder`-shaped version invites
    /// `canShrink(finder.first)`, which checks one radio's widget and leaves the
    /// others unguarded — the same one-instance blind spot the `snrValue` fixture
    /// note below records.
    bool canShrink(Element stat) {
      var flexed = false;
      stat.visitAncestorElements((ancestor) {
        // Stop at the enclosing layout: reaching it means "nothing between here
        // and the layout can squeeze this" — the property under test, not "not
        // found yet". Since #1297 the two stats have *different* enclosing
        // layouts — the count sits in the band `Wrap` (via two `Row`s), the SNR
        // is a lone child of the per-radio `Column` — so both are terminals. With
        // `Wrap` alone the SNR's walk would run to the root and trip over any
        // `Flexible` in the page scaffolding.
        if (ancestor.widget is Wrap || ancestor.widget is Column) return false;
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
      // The count is `'4'` since #1297, and it is genuinely the same numeral on
      // both radios (4 clients each), so it is the one stat that legitimately
      // appears twice. Its localized sentence is asserted separately below,
      // against the semantics tree.
      final stats = <({String label, String text, int instances})>[
        (label: 'client count', text: '4', instances: 2),
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
              'exactly ${stat.instances}x — the `Wrap` moves the SNR to its own '
              'run, it may not discard or reformat a stat',
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

      // The compressed count keeps its label, in the semantics tree (#1297).
      //
      // Asserted on `Semantics.label` rather than on a rendered string because
      // that is the whole point of the compression: the sentence is no longer
      // painted, so `find.text` cannot see it and its absence would otherwise be
      // invisible to this file. `bySemanticsLabel` reads the merged tree, so it
      // fails both if the wrapper is deleted and if `excludeSemantics: false`
      // lets the bare numeral shadow it.
      expect(
        find.bySemanticsLabel(l10n.clientsCount(4)),
        findsNWidgets(2),
        reason: 'each radio\'s compact count must still announce itself as '
            '"${l10n.clientsCount(4)}". #1297 replaced the printed sentence with '
            'a 14px `devices` glyph and a bare numeral, and the '
            '`Semantics(label: clientsCount(n), excludeSemantics: true)` around '
            'it is what makes that a visual compression rather than a dropped '
            'label — a screen reader hears the sentence and the E2E selector map '
            'still locates the count by it.',
      );
    });
  });

  group('the 320px chart box scrolls instead of overflowing (#1297)', () {
    // WHY THIS GROUP EXISTS
    //
    // Every group above measures width. This section's content lives in the fixed
    // `chartHeight: 320` box `StatsSectionCard` builds
    // (`stats_section_card.dart`: `LayoutBlock > SizedBox(height: chartHeight)`),
    // and what spends that budget is the number of per-radio blocks. So the
    // failure is a function of `radioModels.length` — a data input, reported by
    // the WASM client — and no width ladder can reach it.
    //
    // #1297 is what made this measurable. Before it the box also held the
    // band-distribution donut in an `Expanded`, and the donut is why the budget
    // was never visible: `AppPieChart` computes its geometry from the `size` it is
    // handed rather than the box it gets, so once the rows had eaten the slot the
    // chart simply painted **outside** it and `probeSectionOverflow` reported
    // nothing. Measured slot heights in `en` at the 288px section: 188px at 2
    // radios, 136px at 3, 84px at 4, 32px at 5, 0px at 6 — so from 4 radios the
    // 120px drawing exceeded its slot, at 5 it painted across the last radio's SNR
    // (8.0px reported, all of it the centre `Column`, none of it the circle) and at
    // 6 it drew a full circle straddling the card's bottom edge with **zero**
    // incidents. That is the same silent overpaint #1267 measured on the dashboard,
    // and it is the reason this epic's probes could not be trusted to have covered
    // this section (design §2.10f).
    //
    // ## Why the assertion is a scroll extent and not an overflow
    //
    // Removing the donut did not make the budget fit — it made the shortfall
    // *visible*, as a 12px bottom clip at 6 radios. Moving the client count up
    // beside the band then made it worse rather than better, and that is the
    // honest reading: the count adds 27.2px to the band row, which takes that row
    // from one run to two in **all 26** locales at the 288px floor (it was 3 of
    // 26), so a per-radio block costs 72px there instead of 52px. 5 radios need
    // 360px of a 320px box and 6 need 432px.
    //
    // A clip is not a fix, so `StatsSectionCard.scrollable` is what absorbs it
    // (#1297, the same `CardScrollRegion` #1267 gave the dashboard's Channels
    // tab). The box keeps its 320px so the page's sections still line up; content
    // taller than it scrolls inside it instead of painting over the card below.
    //
    // That changes what this group can read. A scrolling region cannot report a
    // `RenderFlex` overflow — there is no flex being overflowed — so green on the
    // probe no longer means "it fits", exactly the trap `cardContentScrollShortfall`
    // exists for. Both numbers are therefore asserted per case: **no** overflow
    // ever, and the scroll extent as a measurement.
    //
    // MEASURED (`en`, one pump per case, real fonts; block = one per-radio
    // `Padding`, 52px on one run, 72px on two):
    //
    //   | radios | 288px content | shortfall | 841px content | shortfall |
    //   |--------|---------------|-----------|---------------|-----------|
    //   | 1      | 72px          | 0         | 52px          | 0         |
    //   | 2      | 144px         | 0         | 104px         | 0         |
    //   | 3      | 216px         | 0         | 156px         | 0         |
    //   | 4      | 288px         | 0         | 208px         | 0         |
    //   | 5      | 360px         | **40**    | 260px         | 0         |
    //   | 6      | 432px         | **112**   | 312px         | 0         |
    //   | 8      | 576px         | **256**   | 416px         | **96**    |
    //
    // 8 radios is past any plausible router and is pumped for one reason: it is
    // the only case that reaches a shortfall at a *wide* section, which is what
    // proves the wide cases are not passing merely because the fixture is small.
    const budgetCases = <({int radios, double screen, double shortfall})>[
      (radios: 1, screen: 320.0, shortfall: 0.0),
      (radios: 2, screen: 320.0, shortfall: 0.0),
      (radios: 3, screen: 320.0, shortfall: 0.0),
      (radios: 4, screen: 320.0, shortfall: 0.0),
      (radios: 5, screen: 320.0, shortfall: 40.0),
      (radios: 6, screen: 320.0, shortfall: 112.0),
      (radios: 8, screen: 320.0, shortfall: 256.0),
      (radios: 2, screen: 905.0, shortfall: 0.0),
      (radios: 4, screen: 905.0, shortfall: 0.0),
      (radios: 6, screen: 905.0, shortfall: 0.0),
      (radios: 8, screen: 905.0, shortfall: 96.0),
    ];

    for (final budget in budgetCases) {
      final section = sectionWidthFor(budget.screen);
      testWidgets(
        budget.shortfall == 0.0
            ? '${budget.radios} radios fit the box at a '
                '${section.toStringAsFixed(0)}px section'
            : '${budget.radios} radios scroll by '
                '${budget.shortfall.toStringAsFixed(0)}px at a '
                '${section.toStringAsFixed(0)}px section',
        (tester) async {
          final overflows = await overflowsAt(
            tester: tester,
            screenWidth: budget.screen,
            locale: localeFor('en'),
            wifiData: _radiosWithClients(budget.radios),
          );

          expect(
            overflows,
            isEmpty,
            reason:
                '${budget.radios} radios must never overflow the 320px chart '
                'box at a ${section.toStringAsFixed(0)}px section — taller '
                'content scrolls inside it since #1297. An incident here means '
                '`StatsSectionCard.scrollable` was turned off, or a child was '
                'added that a scroll view cannot absorb (a vertical `Expanded`, '
                'like the band donut #1297 removed, asserts instead of '
                'scrolling): ${overflows.join(', ')}',
          );

          final shortfall = cardContentScrollShortfall(tester);
          expect(
            shortfall,
            isNotNull,
            reason: 'the section must have a scrolling content region at all. '
                '`null` means `StatsSectionCard.scrollable` is false again, in '
                'which case the ${budget.shortfall}px above is being painted '
                'outside the card instead of scrolled.',
          );
          expect(
            shortfall,
            closeTo(budget.shortfall, 4.0),
            reason: budget.shortfall == 0.0
                ? '${budget.radios} radios fit the 320px box exactly, so nothing '
                    'should scroll. A non-zero extent means the per-radio block '
                    'grew — re-measure the table in this group\'s header rather '
                    'than widening the tolerance.'
                : 'the user has to scroll ${budget.shortfall}px to reach the '
                    'last radio at this width. That is a deliberate, measured '
                    'cost (a block is 72px at the floor, 52px above it), not an '
                    'invisible one: if this figure moved, the block changed '
                    'height and the header table has to be re-taken.',
          );
        },
      );
    }
  });

  group('the SNR bar and the band donut stay removed (#1297)', () {
    // #1267 deleted both from the dashboard's WiFi Performance card; #1297 asked
    // the same two questions here and reached the same answer. The measurements
    // are in `stats_wifi_channels_section.dart`'s own comments — briefly: the bar
    // painted 1.92px per dB on a 96px unticked track and saturated at 50 dB, and
    // the donut was the *third* rendering of clients-per-band on this tab
    // (`StatsDeviceDistributionSection` already draws it as labelled bars) with
    // 40-60px slice titles printed on a 15px ring.
    //
    // A removal is only a decision if something fails when it is undone. The
    // group above catches the donut by its height; this one catches both by
    // absence, because the bar's cost was locale-dependent (7 of 26 locales) and
    // a re-added donut could be given a smaller `size` that fits the box while
    // still being redundant and still clipping its labels.
    //
    // Asserted on `AppLoader` and `InteractivePieChart` — the widgets this
    // section actually used — plus ui_kit's `AppPieChart` underneath, so a
    // re-addition that skips the app-local wrapper is caught too.
    for (final tag in ['en', 'fi']) {
      testWidgets('renders neither in $tag', (tester) async {
        await overflowsAt(
          tester: tester,
          screenWidth: 320.0,
          locale: localeFor(tag),
          wifiData: _wifiDataWithClients,
        );

        expect(
          find.byType(AppLoader),
          findsNothing,
          reason: 'the 96px linear `AppLoader` beside each SNR was removed in '
              '#1297: at `normalizeSNR` = `(snr / 50).clamp(0, 1)` it painted '
              '1.92px per dB with no tick, no scale and no unit, and 50 / 55 / '
              '60 / 70 dB all filled it identically. It also cost 104px of the '
              '238px content width at the production floor, which pushed it to '
              'its own run — and 8-9px of the fixed 320px box — in 7 of the 26 '
              'locales. If a signal bar is wanted back it needs a scale and a '
              'height budget, not a re-add.',
        );
        expect(
          find.byType(InteractivePieChart),
          findsNothing,
          reason: 'the band-distribution donut was removed in #1297: '
              '`StatsDeviceDistributionSection`, the first card of this same '
              'Devices tab, already draws clients-per-band as labelled '
              'horizontal bars, and this donut printed 40-60px slice titles on a '
              '15px ring at every width. What would earn the space is data this '
              'section does not already state (airtime, same-channel '
              'neighbours), which is #1295 and deferred.',
        );
        expect(find.byType(AppPieChart), findsNothing,
            reason: 'nor by reaching past `InteractivePieChart` to ui_kit '
                'directly');
      });
    }
  });
}
