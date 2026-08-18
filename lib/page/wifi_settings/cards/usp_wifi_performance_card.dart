import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/components/wifi_ui.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/page/_shared/providers/card_tab_state_provider.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// WiFi Performance Analytics card — 3-tab view.
///
/// - Signal: Per-client RSSI bar chart with tier coloring
/// - Speed: Grouped DL/UL bar chart per client
/// - Channels: Radio channel info + per-band client distribution
class UspWifiPerformanceCard extends ConsumerWidget {
  const UspWifiPerformanceCard({super.key});

  static const _cardId = 'wifi_performance';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wifiData = ref.watch(wifiDataProvider).valueOrNull;
    final devicesData = ref.watch(devicesDataProvider).valueOrNull;
    // Wait for both providers to load — devicesData contains meshNetwork with
    // slave node clients, wifiData contains radioModels for Channels tab
    if (wifiData == null || devicesData == null) {
      return const CardSkeleton.chart();
    }
    final selectedTab = ref.watch(cardTabIndexProvider(_cardId));

    // Collect backhaul MACs from slave nodes to filter out mesh node STAs
    final backhaulMacs = <String>{};
    for (final slave in devicesData.meshNetwork.slaves) {
      final mac = slave.backhaul.backhaulMacAddress;
      if (mac != null && mac.isNotEmpty) {
        backhaulMacs.add(mac.toUpperCase());
      }
    }

    // Collect active WiFi clients from MeshNetwork (includes slave node clients)
    // Also enrich with master-only data (noise, rates) from wifiClientMap
    final activeClients = <_ClientInfo>[];
    final allWifiClients = devicesData.meshNetwork.allClients
        .where((c) => c.isWifi && c.isActive)
        .where((c) => !backhaulMacs.contains(c.mac.toUpperCase()))
        .toList();

    for (final client in allWifiClients) {
      // Get additional data from wifiClientMap (only available for master clients)
      final masterData = wifiData.wifiClientMap[client.mac.toUpperCase()];
      activeClients.add(_ClientInfo(
        mac: client.mac,
        displayName: client.displayName,
        signalStrength: client.signalStrength ?? -100,
        noise: masterData?.noise ?? 0,
        downlinkRate:
            client.downlinkRate ?? masterData?.lastDataDownlinkRate ?? 0,
        uplinkRate: client.uplinkRate ?? masterData?.lastDataUplinkRate ?? 0,
        band: client.band ?? '',
      ));
    }

    return DashboardCardTemplate.tabbed(
      title: loc(context).wifiPerformance,
      titleBadge:
          AppBadge(label: loc(context).clientsCount(activeClients.length)),
      tabs: [
        CardTab(
          label: loc(context).signal,
          content: _SignalTab(clients: activeClients),
        ),
        CardTab(
          label: loc(context).speed,
          content: _SpeedTab(clients: activeClients),
        ),
        CardTab(
          label: loc(context).channels,
          // The one tab of this card whose content shrink-wraps, so the one that
          // can scroll (#1267). A router with a third radio, or a locale with a
          // long word for "Channel", makes three blocks taller than the card —
          // the state that used to paint outside the box.
          scrollable: true,
          content: _ChannelsTab(
            radios: wifiData.radioModels,
            clients: activeClients,
          ),
        ),
      ],
      selectedTabIndex: selectedTab,
      onTabChanged: (index) =>
          ref.read(cardTabIndexProvider(_cardId).notifier).state = index,
    );
  }
}

// =============================================================================
// Helper class for client info
// =============================================================================

class _ClientInfo {
  final String mac;
  final String displayName;
  final int signalStrength;
  final int noise;
  final int downlinkRate; // kbps
  final int uplinkRate; // kbps
  final String band; // "2.4GHz", "5GHz", "6GHz", or ""

  const _ClientInfo({
    required this.mac,
    required this.displayName,
    required this.signalStrength,
    this.noise = 0,
    this.downlinkRate = 0,
    this.uplinkRate = 0,
    this.band = '',
  });

  /// Whether this client has rate data (master node clients have it, slaves don't).
  bool get hasRateData => downlinkRate > 0 || uplinkRate > 0;
}

// =============================================================================
// Tab 1: Signal — per-client RSSI bar chart
// =============================================================================

class _SignalTab extends StatelessWidget {
  final List<_ClientInfo> clients;
  const _SignalTab({required this.clients});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (clients.isEmpty) {
      return Center(
        child: AppText.bodyMedium(
          'No WiFi clients connected',
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    // Show per-client signal rows with tier-colored linear bars
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: clients.length,
            separatorBuilder: (_, __) => AppGap.sm(),
            itemBuilder: (context, index) {
              final c = clients[index];
              final rssi = c.signalStrength;
              final tier = getSignalTier(rssi);
              final color = tier.resolveColor(colorScheme);
              // Normalize: -100 dBm → 0.0, -30 dBm → 1.0
              final norm = ((rssi + 100) / 70).clamp(0.0, 1.0);

              return LayoutBlock(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: AppText.labelSmall(
                            c.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AppGap.sm(),
                        AppText.bodySmall(
                            loc(context).signalStrengthDbm(rssi.toString())),
                      ],
                    ),
                    AppGap.xs(),
                    AppLoader(
                      variant: LoaderVariant.linear,
                      value: norm,
                      color: color,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        AppGap.sm(),
        // Legend. Degradation shape per #1226 (the full reasoning lives in
        // usp_traffic_analysis_card.dart), adapted as #1233 adapted it: there
        // are no totals to keep at full size, so every child is a legend entry
        // and the `Wrap` is centred rather than `spaceBetween`.
        //
        // Four entries at this card's narrowest realization (261px) is the
        // widest legend in the epic — `ru` overflowed the old `Row` by 149px —
        // so entries wrap to a second run here routinely rather than
        // exceptionally. The `Expanded` above holds a `ListView`, which yields
        // that height freely (contrast §2.10a point 3, where a fixed 120px
        // gauge could not).
        //
        // Two spacing deltas, both deliberate. The old `Row` emitted a trailing
        // `AppGap.md()` after the *last* entry, so `MainAxisAlignment.center`
        // was centring 12px of empty space along with the content; `Wrap`'s
        // `spacing` has no trailing run, so the legend shifts slightly right.
        // And the gap between entries goes 12px → 16px, because `AppSpacing.lg`
        // is what all six #1233 legends and #1226's use — conforming to the
        // shared shape matters more here than preserving this one row's 12px,
        // and the measurement says 16px is affordable even at 261px.
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          children: [
            for (final tier in [
              SignalTier.excellent,
              SignalTier.good,
              SignalTier.fair,
              SignalTier.weak,
            ])
              // `.seriesName`, so the label ellipsizes on one line: a tier name
              // keys an already-colour-coded bar, so a clipped label still
              // communicates and the swatch carries the identification. Contrast
              // the cards whose labels compose a statistic and therefore use
              // `.statistic` (§2.10a point 2, and see #1245).
              //
              // `.swatch()`, not `.block()`: these four entries key a tier
              // palette applied to bar segments, not a bar series of their own.
              AppChartLegendEntry.seriesName(
                mark: const ChartMark.swatch(),
                color: tier.resolveColor(colorScheme),
                label: tier.resolveLabel(context),
              ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// Tab 2: Speed — grouped DL/UL bar chart per client
// =============================================================================

class _SpeedTab extends StatelessWidget {
  final List<_ClientInfo> clients;
  const _SpeedTab({required this.clients});

  static String _truncateName(String name, [int maxLen = 10]) =>
      name.length > maxLen ? '${name.substring(0, maxLen)}…' : name;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Filter to only clients with rate data (master node clients)
    final clientsWithRates = clients.where((c) => c.hasRateData).toList();

    if (clientsWithRates.isEmpty) {
      return Center(
        child: AppText.bodyMedium(
          'No WiFi clients connected',
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    // Convert kbps to Mbps for chart display
    final dlData = clientsWithRates.map((c) => c.downlinkRate / 1000).toList();
    final ulData = clientsWithRates.map((c) => c.uplinkRate / 1000).toList();
    final xLabels =
        clientsWithRates.map((c) => _truncateName(c.displayName)).toList();

    return Column(
      children: [
        Expanded(
          child: AppBarChart(
            series: [
              AppChartSeries(
                label: loc(context).downlink,
                data: dlData,
                color: colorScheme.primary,
              ),
              AppChartSeries(
                label: loc(context).uplink,
                data: ulData,
                color: colorScheme.secondary,
              ),
            ],
            xLabels: xLabels,
            yLabelFormatter: (v) => '${v.toInt()} Mbps',
            showValueLabels: clientsWithRates.length <= 4,
            valueLabelFormatter: (v) => '${v.toInt()}',
            showTooltip: false,
          ),
        ),
        AppGap.sm(),
        // Legend — the Signal tab's shape with two entries instead of four.
        // Only the long-translation locales overflowed the old `Row` here
        // (`es`, `fr`, `pt_PT`, `ru`, `tr`), which is what two entries versus
        // four looks like: this one is translation-length bound where the
        // Signal tab's is geometry bound (it overflowed in `en` too).
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          children: [
            // `.block()` here, unlike the Signal tab: each of these two entries
            // *is* an `AppBarChart` series above, so the mark mirrors the bar.
            AppChartLegendEntry.seriesName(
              mark: const ChartMark.block(),
              color: colorScheme.primary,
              label: loc(context).downlink,
            ),
            AppChartLegendEntry.seriesName(
              mark: const ChartMark.block(),
              color: colorScheme.secondary,
              label: loc(context).uplink,
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// Tab 3: Channels — radio info + band distribution
// =============================================================================

class _ChannelsTab extends StatelessWidget {
  final List<WifiRadioUIModel> radios;
  final List<_ClientInfo> clients;

  const _ChannelsTab({
    required this.radios,
    required this.clients,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (radios.isEmpty) {
      return Center(
        child: AppText.bodyMedium(
          'No WiFi radios available',
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    // Group clients by radio using the resolved band from connectionDetailMap.
    // The loop that used to live here — including its `noise == 0` guard, which
    // the Statistics twin lacked — is now shared (#1271); see
    // `aggregateRadioClientStats` for why the guard exists and why one copy.
    final stats = aggregateRadioClientStats(
      bands: [for (final radio in radios) radio.band],
      clients: [
        for (final c in clients)
          (band: c.band, signalStrength: c.signalStrength, noise: c.noise),
      ],
    );

    return Column(
      children: [
        // Per-radio info rows
        for (var i = 0; i < radios.length; i++) ...[
          Builder(builder: (context) {
            final radio = radios[i];
            final clientCount = stats.clientCount(i);
            // `null` when no client on this radio reported a noise floor — a
            // distinct state from 0 dB, and rendered as one below (#1271).
            final snr = stats.averageSnr(i);

            return LayoutBlock(
              child: Column(
                // `stretch`, not `start`, and it is load-bearing for the `Wrap`
                // below: a `Wrap` under loose width constraints shrink-wraps to
                // its widest run, which leaves `spaceBetween` zero free space to
                // distribute — the alignment silently becomes a no-op and the
                // channel string sits one `spacing` gap after the band instead of
                // at the block's right edge. `stretch` hands both rows a tight
                // width, so `spaceBetween` reproduces what the old `Spacer` did.
                // (The SNR line below is unaffected either way — it is a single
                // left-aligned text.)
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Band + channel. The #1226 shape, and `spaceBetween` is what
                  // makes it a drop-in: with both children on one run a `Wrap`
                  // spaces them to the edges exactly as the old `Spacer` did, so
                  // nothing moves at the widths where the row already fit.
                  //
                  // Neither side yields, because neither is chrome: `band` is the
                  // block's identity and the channel string is composed data
                  // (§2.10a point 2 — an ellipsis landing inside `320MHz`
                  // misinforms in a way a wrapped line does not). So both keep
                  // their intrinsic width and the row spends a second run.
                  //
                  // Why this changed now, when the row shipped clean for months:
                  // `'Ch '` was a hardcoded English abbreviation, and it was
                  // hiding a geometry problem rather than not having one. With
                  // the real `channel` key the old `Row` + `Spacer` overflows
                  // this row nearly everywhere. Re-measured for #1298 by
                  // restoring that shape on today's tree — the #1266 figures no
                  // longer apply on two counts: #1267 moved the client count
                  // inside the first `Wrap` child (so child 1 is wider than the
                  // bare band it measured), and #1298 dropped `tr`'s
                  // `'Channel (Kanal)'` gloss (so `tr` is no longer the loudest
                  // locale):
                  //
                  //  * two-radio, the profile the gate ships: 25 of 26 locales
                  //    overflow the 261px card — `th` +44.0px, `ja` +28.0,
                  //    `en` +26.0, `fi` +21.0, down to `zh` +3.8; only `ko` is
                  //    clean. At the *preferred* 288px width only `th` (+17.0)
                  //    still breaks.
                  //  * tri-band, `Ch 233 (Auto) · 320MHz` — the fixture #1266
                  //    could only produce by hand-editing, and which the gate
                  //    now sweeps as its `[triband]` profile (#1267): all 26
                  //    break at 261px (`th` +55.0, mildest `ko` +12.0), and four
                  //    still break at 288px — `th` +27.0, `ja` +11.0, `en` +8.8,
                  //    `fi` +3.6. The third radio's row costs ~10px on top of
                  //    every locale's two-radio figure.
                  //
                  // Every incident is attributed to this one row; under the
                  // `Wrap` all 210 cases of both profiles are clean.
                  //
                  // The extra run used to be paid out of the donut's `Expanded`
                  // below; with the donut gone (#1267) the tab scrolls instead,
                  // so a second run costs height the card can now give.
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.xxs,
                    children: [
                      // Band + its client count, as **one** `Wrap` child: the
                      // count belongs to this radio, so it reads better beside
                      // the band than on a line of its own, and keeping the two
                      // of them in a `Row` preserves the two-child
                      // `spaceBetween` shape measured above \u2014 a third top-level
                      // child would have the alignment distribute slack
                      // *between* band and count too, pulling them apart.
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppText.labelLarge(radio.band),
                          AppGap.xs(),
                          // Icon + number, not "N clients": the word costs
                          // ~50px of a 235px content width on every radio, and
                          // what it names is already the tab's subject. The
                          // string stays in the semantics tree, so a screen
                          // reader still hears "3 clients" and E2E can still
                          // locate the count by it \u2014 an icon with a bare
                          // numeral beside it is the *visual* compression, not
                          // a loss of the label.
                          Semantics(
                            label: loc(context).clientsCount(clientCount),
                            excludeSemantics: true,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // `devices`, not `genericDevice`: the latter is
                                // an abstract four-square glyph that reads as
                                // "grid" at 14px, while this one is the
                                // phone-plus-laptop pictogram the rest of the
                                // app uses for clients.
                                AppIcon.font(
                                  AppFontIcons.devices,
                                  size: 14,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                AppGap.xxs(),
                                AppText.bodySmall(
                                  '$clientCount',
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      AppText.bodySmall(
                        '${loc(context).channel} ${radio.channelDisplay}'
                        '  \u00b7  ${radio.channelBandwidth}',
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  AppGap.xs(),
                  // The SNR, alone on its line, and both of the things that used
                  // to share it are gone (#1267).
                  //
                  // The linear `AppLoader` that followed it drew
                  // `normalizeSNR(snr)` — `snr / 50`, clamped — with no axis, no
                  // scale and no units, immediately after the number it encodes,
                  // so it restated the value it sat beside and taught nothing
                  // about it. Removing it also removes the `Expanded`/`Spacer`
                  // pair that made this row's width behaviour depend on whether
                  // a radio happened to have an SNR reading, and the branch that
                  // had to exist so an unmeasured radio was not drawn as a bar
                  // at zero (#1271). The Statistics page's twin kept its own 96px
                  // bar until #1297 asked the same question there and removed it
                  // on the same grounds, so neither surface draws one now.
                  //
                  // The client count moved up beside the band, which is where it
                  // belongs, and that is what lets this be a plain `AppText`
                  // rather than the `Wrap` an interim revision needed: a lone
                  // text has no sibling to collide with, so there is no #1258
                  // cliff to wrap away from — a long translation of "SNR" simply
                  // wraps inside its own paragraph.
                  AppText.bodySmall(snr == null
                      ? loc(context).snrUnavailable
                      : loc(context).snrValue(snr.toInt())),
                ],
              ),
            );
          }),
          if (i < radios.length - 1) AppGap.sm(),
        ],
        // Where the band-distribution donut used to be (#1267).
        //
        // It plotted clients-per-*band* — one slice per radio, sized by that
        // radio's client count. Every one of those numbers is printed above it,
        // in the block for the same radio and now on the same line as the band
        // and its channel, so on a tab whose subject is each radio's channel and
        // width the donut was a second rendering of data the tab already stated,
        // and the only thing it added that the text did not was a total.
        //
        // Re-slicing it per *channel* was considered and does not help: a radio
        // has one channel, so channel-keyed slices are band-keyed slices with a
        // different legend. What would earn this space is something the tab does
        // not say — airtime utilization or same-channel neighbours
        // (`…DataElements.Network.Device.{i}.Radio.{i}.Utilization`), which no
        // provider fetches and `WifiRadioUIModel` has no field for. Follow-up
        // ticket, not a layout fix.
        //
        // It is also what broke the card. Fixed at 120px inside an `Expanded`,
        // it took whatever height the blocks left; on a tri-band router at the
        // 261px card in `tr` that was ~40px, and a `Center` spills its
        // oversized child in *both* directions — so the donut painted over the
        // 6GHz block above it (hiding that radio's SNR entirely) and reported
        // only the 9px that happened to fall past the bottom edge. Screenshots
        // in the #1267 thread; the `+9.0px bottom` the gate saw understated it.
        //
        // Removing it is what lets the rest be honest: with no vertical flex
        // child left, the tab shrink-wraps, so it can scroll, so a fourth radio
        // or a longer locale has somewhere to go instead of over the text.
      ],
    );
  }
}
