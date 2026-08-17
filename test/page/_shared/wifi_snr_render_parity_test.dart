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
/// on 2.4GHz is what says so. Since #1267 the two surfaces *render* that count
/// differently — the card as an icon plus a numeral beside the band, the section
/// still as a sentence — so the assertion is parameterized rather than dropped;
/// see `countIsCompact` on [expectChannelsReadouts].
///
/// ## Mutation ledger
///
/// Both halves of the fix were reverted in `aggregateRadioClientStats` and the
/// suites re-run, because a parity test that passes on the drifted code is worth
/// nothing — and because the interesting column is the right-hand one:
///
///   | mutation                                    | here   | channels overflow | perf readability |
///   |---------------------------------------------|--------|-------------------|------------------|
///   | drop the `noise == 0` guard (the drift)     | 2 fail | 158 pass          | 13 pass          |
///   | `averageSnr` returns 0 instead of `null`    | 2 fail | 158 pass          | 13 pass          |
///   | drop the card's icon + client count (#1267) | 1 fail | 158 pass          | 15 pass          |
///
/// The third row was added when #1267 compressed the card's count to an icon plus
/// a numeral: the count left the readability suite's field of view entirely, and
/// neither overflow suite ever had it (a *shorter* row is a cleaner layout), so
/// this file is now the only place that fails if a radio stops reporting how many
/// clients are on it. The card's own 211 gate cases — 157 default-profile plus the
/// 54 tri-band ones #1267 added — are green under the mutation too.
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
  /// [hasSignalBar] and [countIsCompact] are the only places the two surfaces are
  /// allowed to differ, and only because what parity is *about* is the number.
  ///
  /// [hasSignalBar]: the dashboard card dropped its linear `AppLoader` in #1267
  /// (an unlabelled `snr / 50` restating the value printed beside it), while the
  /// Statistics section keeps its 96px bar. Where a bar is drawn, the #1271 claim
  /// it carries still holds — an unmeasured radio gets no bar rather than one at
  /// zero — so this flag switches the assertion off, it does not weaken it.
  ///
  /// [countIsCompact]: the card renders the count as an icon plus a bare numeral
  /// beside the band, the section still renders `clientsCount` as a sentence.
  /// Either way the assertion is that *this radio's block* reports *this radio's
  /// count*; only the locator changes, and the compact branch checks both halves
  /// (the visible numeral **and** the semantics label), because an icon with a
  /// naked number and no accessible name would be a regression this test is
  /// exactly positioned to catch.
  void expectChannelsReadouts(WidgetTester tester, AppLocalizations l,
      {required String surface,
      required bool hasSignalBar,
      required bool countIsCompact}) {
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
      for (final locator in countIsCompact
          ? [
              find.text('$count'),
              find.byWidgetPredicate(
                  (w) => w is Semantics && w.properties.label == sentence),
            ]
          : [find.text(sentence)]) {
        expect(find.descendant(of: block, matching: locator), findsOneWidget,
            reason:
                'radio $i on $surface should report $count client(s) beside '
                '"${snrs[i].data}" — as ${countIsCompact ? '"$count" with '
                    '"$sentence" in its semantics' : '"$sentence"'}. A client '
                'with no noise reading is excluded from the average, not from '
                'the network. Missing locator: '
                '${locator.describeMatch(Plurality.one)}');
      }

      final bars = find.descendant(of: block, matching: find.byType(AppLoader));
      if (!hasSignalBar) {
        expect(bars, findsNothing,
            reason: 'radio $i on $surface draws a signal bar. This surface '
                'dropped it (#1267): an unlabelled bar beside the number it '
                'encodes adds nothing, and a reappearing one is a revert.');
      } else if (snrs[i].data == l.snrUnavailable) {
        expect(bars, findsNothing,
            reason: 'radio $i on $surface draws a signal bar with no SNR to '
                'draw. A linear loader at 0 is indistinguishable from a real '
                'reading at the noise floor, which is the claim this state '
                'exists to avoid.');
      } else {
        expect(bars, findsOneWidget,
            reason: 'radio $i on $surface has an SNR reading '
                '("${snrs[i].data}") but no bar rendering it.');
      }
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

    expectChannelsReadouts(tester, l,
        surface: 'the Statistics section',
        hasSignalBar: true,
        countIsCompact: false);
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

    expectChannelsReadouts(tester, l,
        surface: 'the WiFi Performance card',
        hasSignalBar: false,
        countIsCompact: true);
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
