@Tags(['dashboard-card'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/client_connection_detail.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_connection_info.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/statistics/views/sections/stats_wifi_channels_section.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
// `hide ConnectionType`: ui_kit's topology models declare their own, and this
// file needs the client model's. Only `AppLoader` is wanted from ui_kit here.
import 'package:ui_kit_library/ui_kit.dart' hide ConnectionType;

import '../../golden_test/golden_framework/mocks/mock_dashboard_cards.dart';
import '../../golden_test/golden_framework/mocks/mock_statistics.dart';
import '../../util/app_test_fonts.dart';
import '../../util/dashboard/dashboard_card_probe.dart';
import '../../util/overflow_probe.dart';
import '../../util/statistics/stats_section_probe.dart';

/// The per-radio SNR readout, rendered from one client set on **both** surfaces
/// that show it (#1271).
///
/// ## Why this file exists, and why it is not under either page
///
/// The statistic shipped twice: `stats_wifi_channels_section.dart` (Statistics
/// page) and `usp_wifi_performance_card.dart` (dashboard, Channels tab) each had
/// their own copy of the same per-radio loop. The copies then drifted — the card
/// grew a `noise == 0` guard and the section did not — so the *same clients*
/// averaged lower on Statistics than on the dashboard, and no test noticed
/// because every fixture in the repo gave every client a real noise floor.
///
/// #1271 replaced both loops with `aggregateRadioClientStats`, which is unit
/// tested in `test/core/utils/radio_client_stats_test.dart`. That file pins the
/// arithmetic. This one pins the thing the arithmetic was extracted *for*: that
/// what the user reads is the same on both surfaces. Neither page's own suite can
/// carry that claim, because a claim about two surfaces agreeing cannot live
/// inside one of them — so it sits beside the shared helper's owner (`_shared`),
/// not under `statistics/` or `dashboard/`.
///
/// ## How agreement is asserted, given one pump per test
///
/// A `RenderFlex` reports its overflow once per render-object lifetime, so both
/// probes enforce one pump per `testWidgets` (see `probeSectionOverflow`). Two
/// surfaces therefore cannot be pumped into the same test and compared against
/// each other directly.
///
/// Instead both are compared against **one shared oracle**: `expectedReadouts`
/// is defined once from the fixture and consumed by both tests. Equality of the
/// two surfaces follows from both matching the same list, and each surface fails
/// on its own with a diagnosable message — which a cross-test comparison through
/// a shared mutable variable would not give.
///
/// ## Why this fixture, and what it would have caught
///
/// The client set is chosen for the one property no existing fixture had: a
/// client with **no** noise reading sitting next to clients that have one.
///
///   | radio  | clients                          | guarded | unguarded |
///   |--------|----------------------------------|---------|-----------|
///   | 2.4GHz | 40 dB, 35 dB, and one at noise 0 | 37 dB   | 25 dB     |
///   | 5GHz   | one client, noise 0              | `—`     | 0 dB      |
///
/// So one pump carries both halves of the fix. The 2.4GHz row fails on the
/// pre-#1271 section (`SNR: 25 dB`), and the 5GHz row fails on *both* pre-#1271
/// surfaces (`SNR: 0 dB` plus a bar drawn empty — a claim of the worst possible
/// link quality for a radio nothing was measured on).
///
/// The client counts are asserted alongside, in the same blocks: the guard
/// removes a client from the SNR *average*, not from the network, and 3 clients
/// on 2.4GHz is what says so. From #1267 to #1297 the two surfaces *rendered* that
/// count differently — the card as an icon plus a numeral beside the band, the
/// section as a `clientsCount` sentence on the line below — so the assertion was
/// parameterized by a `countIsCompact` flag rather than dropped.
///
/// #1297 removed the divergence instead of inheriting it, and both flags this
/// helper carried are gone: the section compressed its count to the same icon plus
/// numeral and deleted its 96px signal bar (§2.10i). Neither assertion was
/// relaxed to match — both became **unconditional**, which is strictly stronger
/// than the flag was, and is why re-adding either widget on either surface now
/// fails this file. What the section's own measurement said, for the record: the
/// count + SNR pair was 112.0-166.2px of a 238px content box, so it *fitted* —
/// 71.8px of headroom in its worst locale (`fi`) at the production floor. The
/// compression is not a width rescue on this surface; it is that a word naming the
/// tab's own subject, repeated on every radio, is not worth 36.3-90.5px when 23.2px
/// says the same thing. A flag here records a divergence, and the fix for one is
/// for the two surfaces to agree.
///
/// ## Mutation ledger
///
/// Both halves of the fix were reverted in `aggregateRadioClientStats` and all
/// three suites re-run, because a parity test that passes on the drifted code is
/// worth nothing — and because the interesting columns are the right-hand two.
/// Re-taken for #1297, when the channels suite grew to 172 tests and the section
/// gained two revertible decisions of its own:
///
///   | mutation                                       | here   | channels overflow | perf readability |
///   |------------------------------------------------|--------|-------------------|------------------|
///   | drop the `noise == 0` guard (the drift)        | 2 fail | 172 pass          | 15 pass          |
///   | `averageSnr` returns 0 instead of `null`       | 2 fail | 172 pass          | 15 pass          |
///   | drop the **card's** icon + count (#1267)       | 1 fail | 172 pass          | 15 pass          |
///   | drop the **section's** icon + count (#1297)    | 1 fail | 4 fail            | 15 pass          |
///   | re-add the **section's** 96px bar (#1297)      | 1 fail | 3 fail            | 15 pass          |
///
/// Rows 3 and 4 are the same mutation on either surface and each fails **only its
/// own half** of this file — which is what makes the parity claim testable rather
/// than decorative. Row 3 fails nothing anywhere else: the count left the
/// readability suite's field of view when #1267 compressed it, and no overflow
/// suite ever had it, because a *shorter* row is a cleaner layout. Row 4 costs the
/// channels suite 4 cases, and not for a width reason either — one legibility case
/// plus three of its vertical-budget cases, because a band row without the count
/// fits one run and the section is then 20px per radio shorter than the scroll
/// extents those cases measured. Row 5 is caught here, by a `findsNothing` and by a
/// structural assertion in the channels suite, and by nothing that measures pixels:
/// in `en` the pair is 111.3px, so a 104px bar still fits the row.
///
/// So this file remains the only place that fails if *either* surface stops saying
/// how many clients are on a radio, and the only place that fails if they stop
/// saying it the same way. The card's own 211 gate cases — 157 default-profile plus
/// the 54 tri-band ones #1267 added — are green under every row above; the section
/// has no gate cases at all, which is why its two rows exist.
///
/// Neither surface's own suite notices either mutation. The overflow suites
/// cannot: both mutations make the strings *shorter* (`SNR: 25 dB`, `SNR: 0 dB`
/// versus `SNR: 37 dB`), and a shorter string is a cleaner layout. The
/// readability suite cannot either — it asserts that every radio has *an* SNR
/// readout, which a wrong one satisfies. Only a test that knows what the number
/// should be can see this class of defect, which is why the bug shipped.
void main() {
  setUpAll(() async {
    // Real fonts: under Ahem every glyph is one square em, so the rows this
    // pumps would lay out to fictional widths.
    await loadAppFonts();
  });

  /// Both surfaces render `en` here. The parity claim is about *data*, not
  /// translation; the locale sweeps live in each page's own overflow suite.
  final locale = AppLocalizations.supportedLocales
      .firstWhere((l) => l.languageCode == 'en');

  // ─── The shared oracle ─────────────────────────────────────────────────────

  /// The SNR readouts [_wifiData] must produce, in radio order.
  ///
  /// `snrValue(37)`: (40 + 35) / 2 = 37.5, truncated for display. Unguarded it
  /// is (40 + 35 + 0) / 3 = 25.
  ///
  /// `snrUnavailable`: the 5GHz radio has a client but no noise reading from it,
  /// so there is no average to show. It renders as "not measured" rather than as
  /// 0 dB, which is a real reading a router can report.
  List<String> expectedReadouts(AppLocalizations l) =>
      [l.snrValue(37), l.snrUnavailable];

  /// Clients per radio, in the same order — the guard's other half.
  List<int> expectedCounts() => [3, 1];

  // ─── Assertions, run identically against either surface ────────────────────

  List<Text> renderedTexts(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .where((t) => t.data != null && t.data!.isNotEmpty)
      .toList();

  /// The per-radio block containing [text]: the innermost enclosing `Column`.
  ///
  /// Ancestor finders walk outward, so `.first` is the innermost — which on both
  /// surfaces is the block's own `Column` (`AppText` introduces none of its own,
  /// as `wifi_performance_readability_test.dart` already relies on). Scoping by
  /// block is what makes "this radio has a bar" a per-radio claim instead of a
  /// count over the whole card, where the Signal tab has one `AppLoader` per
  /// client.
  Finder blockOf(Text text) => find
      .ancestor(of: find.byWidget(text), matching: find.byType(Column))
      .first;

  /// Asserts the pumped surface renders exactly the oracle, radio by radio.
  ///
  /// **This helper now takes no per-surface flags at all**, and it took two to
  /// begin with. Both were retired the same way — by the second surface adopting
  /// what the first had measured, not by the assertion being relaxed:
  ///
  ///  - `hasSignalBar` existed because #1267 dropped the card's linear `AppLoader`
  ///    — an unlabelled `snr / 50` restating the value printed beside it — while
  ///    the section still drew its 96px bar. #1297 asked the same question of the
  ///    section and measured the same answer (1.92px per dB, saturating at 50 dB),
  ///    so the bar is gone from both and the assertion is unconditional.
  ///  - `countIsCompact` existed because #1267 compressed the card's count to an
  ///    icon plus a numeral while the section still printed `clientsCount` as a
  ///    sentence. #1297 first inherited that divergence on a headroom argument, and
  ///    then dropped it: fitting is not the same as being worth the width, so the
  ///    section compressed too and both surfaces are located the same way.
  ///
  /// Both retirements are strictly stronger than the flags were. A bar re-added to
  /// *either* surface fails here, and so does a count that stops being compact on
  /// either — where a flag could simply have been flipped back to describe the
  /// regression as a configuration.
  ///
  /// The compact locator deliberately checks **both** halves, the visible numeral
  /// *and* the semantics label: an icon beside a naked number with no accessible
  /// name is the failure mode a compression invites, and this file is positioned
  /// exactly where it would show up on either surface.
  ///
  /// What the old `hasSignalBar: true` branch carried is not lost either. It
  /// asserted #1271's claim that an unmeasured radio gets *no* bar rather than one
  /// at zero; with no bar anywhere, that claim is carried by the oracle's
  /// `snrUnavailable` entry, which is the assertion that made the branch worth
  /// having in the first place.
  void expectChannelsReadouts(WidgetTester tester, AppLocalizations l,
      {required String surface}) {
    final texts = renderedTexts(tester);
    final snrs = texts.where((t) => t.data!.contains(_snrMarker)).toList()
      ..sort((a, b) => tester
          .getRect(find.byWidget(a))
          .top
          .compareTo(tester.getRect(find.byWidget(b)).top));

    expect(snrs.map((t) => t.data).toList(), expectedReadouts(l),
        reason: '$surface does not render the SNR the shared aggregation '
            'computes for this client set. A "${l.snrValue(25)}" here is the '
            'unguarded average — a client that reported no noise floor was '
            'counted as a 0 dB sample. A "${l.snrValue(0)}" on the second radio '
            'is the same defect in its terminal form: an unmeasured radio '
            'reported as the worst possible link. Rendered: '
            '${texts.map((t) => t.data).toList()}');

    // Each block's own count and bar, so a readout cannot be right while
    // belonging to the wrong radio.
    for (var i = 0; i < snrs.length; i++) {
      final block = blockOf(snrs[i]);
      final count = expectedCounts()[i];
      final sentence = l.clientsCount(count);
      // `byWidgetPredicate` on the `Semantics` widget, not `bySemanticsLabel`:
      // the latter reads the semantics *tree*, which a widget test only builds
      // under `tester.ensureSemantics()`. The label is a property of the widget
      // either way, and this keeps the pump identical on both surfaces.
      for (final locator in [
        find.text('$count'),
        find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.label == sentence),
      ]) {
        expect(find.descendant(of: block, matching: locator), findsOneWidget,
            reason:
                'radio $i on $surface should report $count client(s) beside '
                '"${snrs[i].data}" — as "$count" with "$sentence" in its '
                'semantics. A client with no noise reading is excluded from the '
                'average, not from the network. Missing locator: '
                '${locator.describeMatch(Plurality.one)}');
      }

      final bars = find.descendant(of: block, matching: find.byType(AppLoader));
      expect(bars, findsNothing,
          reason: 'radio $i on $surface draws a signal bar. Both surfaces '
              'dropped it — the card in #1267, the section in #1297 — because an '
              'unlabelled bar beside the number it encodes adds nothing: '
              '`normalizeSNR` is `(snr / 50).clamp(0, 1)`, which on the '
              'section\'s 96px track resolved 1.92px per dB and painted 50, 55, '
              '60 and 70 dB identically. A reappearing one is a revert on '
              'whichever surface it appears, which is why this is asserted '
              'unconditionally rather than behind a per-surface flag.');
    }
  }

  // ─── Surface 1: the Statistics page's WiFi Channels section ────────────────

  testWidgets('Statistics WiFi Channels renders the guarded average',
      (tester) async {
    final l = await AppLocalizations.delegate.load(locale);
    // 905px tablet — an 841px section, comfortably above the widths where this
    // section's rows start degrading (those are `stats_wifi_channels_section_test`'s
    // subject). The overflows are asserted anyway: a parity test that measured a
    // broken layout would be reading the right strings off the wrong render.
    final overflows = await probeSectionOverflow(
      tester,
      section: const StatsWifiChannelsSection(),
      screenWidth: 905.0,
      locale: locale,
      overrides: statisticsOverrides(wifiData: _wifiData),
    );
    expect(overflows, isEmpty,
        reason:
            'the section overflowed on this fixture: ${overflows.join(', ')}');

    expectChannelsReadouts(tester, l, surface: 'the Statistics section');
  });

  // ─── Surface 2: the dashboard's WiFi Performance card, Channels tab ────────

  testWidgets('WiFi Performance Channels renders the same average',
      (tester) async {
    final l = await AppLocalizations.delegate.load(locale);
    const cardId = 'wifi_performance';
    final constraints = UspWidgetSpecs.all
        .firstWhere((s) => s.id == cardId)
        .getConstraints(DisplayMode.normal);
    // The narrowest realization of the card's *preferred* span: the width the
    // grid gives it by default, where every per-radio block is one clean run.
    final narrowest =
        narrowestRealizationOf(constraints.preferredColumns, minScreen: 0)!;
    final height = dashboardCardHeight(constraints.minHeightRows);

    // Pumped through `buildDashboardCardApp` rather than `probeCardOverflow`
    // because this needs `extraOverrides`: the gate's kitchen-sink fixture gives
    // every client a noise floor, which is exactly the data that hid the bug.
    // Overflows are not collected here, so any the fixture caused would fail the
    // test as an unhandled Flutter error — which is the behaviour wanted.
    final surface = Size(narrowest.screenWidth, height);
    await tester.binding.setSurfaceSize(surface);
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(buildDashboardCardApp(
      cardId: cardId,
      locale: locale,
      screenWidth: narrowest.screenWidth,
      cardWidth: narrowest.cardWidth,
      cardHeight: height,
      // The Channels tab, pinned rather than tapped — a tap would need the tab
      // strip's own geometry to cooperate at this width.
      tabIndex: 2,
      extraOverrides:
          cardOverrides(wifiData: _wifiData, devicesData: _devicesData),
    ));
    await settleIgnoringAnimations(tester);

    expectChannelsReadouts(tester, l, surface: 'the WiFi Performance card');
  });
}

/// The SNR readout's literal prefix, shared by `snrValue` ("SNR: {value} dB")
/// and `snrUnavailable` ("SNR: —") and untranslated in all 26 locales.
const _snrMarker = 'SNR';

/// One client's reading, as the two surfaces' providers each carry it.
typedef _Sample = ({String mac, String band, int signal, int noise});

/// The client set both surfaces render. See the file header's table.
const _clients = <_Sample>[
  (mac: 'AA:BB:CC:00:00:01', band: '2.4GHz', signal: -55, noise: -95), // 40 dB
  (mac: 'AA:BB:CC:00:00:02', band: '2.4GHz', signal: -60, noise: -95), // 35 dB
  (mac: 'AA:BB:CC:00:00:03', band: '2.4GHz', signal: -70, noise: 0), // no noise
  (mac: 'AA:BB:CC:00:00:04', band: '5GHz', signal: -50, noise: 0), // no noise
];

/// What the Statistics section reads: radios, plus `wifiClientMap` for the
/// readings and `connectionDetailMap` for the band.
///
/// It is also half of what the card reads — the card takes each client's noise
/// from this same map (`wifiClientMap[mac]?.noise ?? 0`), which is why a client
/// with `noise: 0` here is unmeasured on both surfaces rather than only one.
final _wifiData = WifiData(
  codegenContext: WifiCodegenContext.empty,
  radioModels: const [
    WifiRadioUIModel(
      instancePath: 'Device.WiFi.Radio.1.',
      band: '2.4GHz',
      enable: true,
      transmitPower: -1,
      maxBitRate: 300,
      channel: 6,
      autoChannelEnable: false,
      channelBandwidth: '20/40MHz',
      supportedStandards: 'b,g,n',
    ),
    WifiRadioUIModel(
      instancePath: 'Device.WiFi.Radio.2.',
      band: '5GHz',
      enable: true,
      transmitPower: -1,
      maxBitRate: 2400,
      channel: 36,
      autoChannelEnable: false,
      channelBandwidth: '160MHz',
      supportedStandards: 'a,n,ac,ax',
    ),
  ],
  wifiClientMap: {
    for (final c in _clients)
      c.mac: WifiClientUIModel(
        macAddress: c.mac,
        signalStrength: c.signal,
        noise: c.noise,
        lastDataDownlinkRate: 866000,
        lastDataUplinkRate: 433000,
        active: true,
      ),
  },
  connectionDetailMap: {
    for (final c in _clients)
      c.mac: ClientConnectionDetail(band: c.band, ssidName: 'Linksys'),
  },
);

/// What the card reads for the same clients: the mesh network's client list,
/// carrying the band and signal strength. Both must match [_wifiData]'s
/// readings — the two surfaces agreeing about the average is only meaningful if
/// they were given the same `(band, signal, noise)` triples to average.
final _devicesData = DevicesData(
  meshNetwork: MeshNetwork(
    master: MasterNode(
      deviceId: 'GATEWAY',
      model: 'Test Router',
      connectedClients: [
        for (final c in _clients)
          ClientDevice(
            mac: c.mac,
            ip: '192.168.1.1${_clients.indexOf(c)}',
            hostName: 'client-${_clients.indexOf(c)}',
            isActive: true,
            connectionType: ConnectionType.wifi,
            wifi: WifiConnectionInfo(
              signalStrength: c.signal,
              band: c.band,
              ssidName: 'Linksys',
            ),
          ),
      ],
    ),
  ),
);
