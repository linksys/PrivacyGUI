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
              _LegendEntry(
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
            _LegendEntry(
              color: colorScheme.primary,
              label: loc(context).downlink,
            ),
            _LegendEntry(
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
// Legend primitives (shared by the Signal and Speed tabs)
// =============================================================================

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// One legend entry: colour dot, gap, label — the unit that must never split, so
/// a label never separates from the colour it explains (#1226 rule 2).
///
/// File-private on purpose, and this is now the **fifth** copy of the shape
/// (`usp_network_health_card`, `usp_system_status_card` as `_StatLegendEntry`,
/// `usp_traffic_analysis_card`, `device_analytics`). Extracting one shared
/// widget from them needs Article XIV approval, which #1245 is raised to have;
/// #1233 deliberately chose not to block on that conversation and #1229 follows
/// it, so the shape is replicated in place. #1245's inventory needs this file
/// added to it.
class _LegendEntry extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendEntry({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LegendDot(color: color),
        AppGap.xs(),
        // `Flexible`, because a `Row` hands non-flex children unbounded width: a
        // bare label takes its full intrinsic width on one line and overflows no
        // matter how the enclosing `Wrap` arranges the entries (§2.10a point 1).
        // Loose fit, so a short label still hugs and entries share a run.
        //
        // One-line ellipsis, unlike system_status/network_health: every label
        // here is a bare tier or series name keying an already-colour-coded bar
        // or chart, so a clipped label still communicates and the colour carries
        // the identification. Those two cards compose statistics into their
        // labels and therefore soft-wrap instead — an ellipsis would cut a
        // number in half (§2.10a point 2).
        Flexible(
          child: AppText.labelSmall(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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

    // Build band → radio index lookup from WifiRadioUIModel.band
    final bandToRadioIdx = <String, int>{};
    for (var i = 0; i < radios.length; i++) {
      bandToRadioIdx[radios[i].band] = i;
    }

    // Group clients by radio using resolved band from connectionDetailMap
    final clientsPerRadio = <int, int>{};
    final snrSumPerRadio = <int, double>{};
    final snrCountPerRadio = <int, int>{};

    for (final c in clients) {
      final radioIdx = bandToRadioIdx[c.band];
      if (radioIdx == null) continue;
      clientsPerRadio[radioIdx] = (clientsPerRadio[radioIdx] ?? 0) + 1;
      // Only clients with real noise data contribute to the average SNR.
      // Slave-node clients have no noise (they aren't in wifiClientMap), so
      // computeSNR returns 0; including them would deflate the per-radio
      // average once #1118 gives them a resolved band. Count them as clients
      // but exclude them from the SNR aggregation until noise is available.
      if (c.noise != 0) {
        final snr = computeSNR(c.signalStrength, c.noise);
        snrSumPerRadio[radioIdx] = (snrSumPerRadio[radioIdx] ?? 0) + snr;
        snrCountPerRadio[radioIdx] = (snrCountPerRadio[radioIdx] ?? 0) + 1;
      }
    }

    // Compute average SNR per radio
    final avgSnrPerRadio = <int, double>{};
    for (final key in snrSumPerRadio.keys) {
      avgSnrPerRadio[key] = snrSumPerRadio[key]! / snrCountPerRadio[key]!;
    }

    return Column(
      children: [
        // Per-radio info rows
        for (var i = 0; i < radios.length; i++) ...[
          Builder(builder: (context) {
            final radio = radios[i];
            final clientCount = clientsPerRadio[i] ?? 0;
            final snr = avgSnrPerRadio[i] ?? 0;
            final snrNorm = normalizeSNR(snr.toInt());

            return LayoutBlock(
              child: Column(
                // `stretch`, not `start`, and it is load-bearing for the `Wrap`
                // below: a `Wrap` under loose width constraints shrink-wraps to
                // its widest run, which leaves `spaceBetween` zero free space to
                // distribute — the alignment silently becomes a no-op and the
                // channel string sits one `spacing` gap after the band instead of
                // at the block's right edge. `stretch` hands both rows a tight
                // width, so `spaceBetween` reproduces what the old `Spacer` did.
                // (The second row is unaffected: its `Expanded` loader already
                // forced full width.)
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
                  // the real `channel` key the old `Row` overflowed at the 261px
                  // card in `th` (+17.0px) and `tr` (+4.1/+41.0px, and +14.0px
                  // even at the *preferred* 288px width), on the two-radio
                  // fixture the gate ships. Given a third tri-band radio —
                  // `Ch 233 (Auto) · 320MHz`, which the gate's fixture cannot
                  // produce — `en` (+8.3px), `fi` and `ja` break too. Measured
                  // per #1266; every incident attributed to this one row.
                  //
                  // The extra run is paid out of the donut's `Expanded` below,
                  // which yields it (contrast §2.10a point 3, where Network
                  // Health's fixed 120px gauge could not) — verified by
                  // re-measuring for bottom overflows, not assumed.
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.xxs,
                    children: [
                      AppText.labelLarge(radio.band),
                      AppText.bodySmall(
                        '${loc(context).channel} ${radio.channelDisplay}'
                        '  \u00b7  ${radio.channelBandwidth}',
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  AppGap.xs(),
                  Row(
                    children: [
                      AppText.bodySmall(loc(context).clientsCount(clientCount)),
                      AppGap.md(),
                      AppText.bodySmall(loc(context).snrValue(snr.toInt())),
                      AppGap.sm(),
                      Expanded(
                        child: AppLoader(
                          variant: LoaderVariant.linear,
                          value: snrNorm,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          if (i < radios.length - 1) AppGap.sm(),
        ],
        // Band distribution donut (if we have data)
        if (clients.isNotEmpty) ...[
          AppGap.md(),
          Expanded(
            child: _BandDistributionDonut(
              clientsPerRadio: clientsPerRadio,
              radios: radios,
            ),
          ),
        ],
      ],
    );
  }
}

class _BandDistributionDonut extends StatelessWidget {
  final Map<int, int> clientsPerRadio;
  final List<WifiRadioUIModel> radios;

  const _BandDistributionDonut({
    required this.clientsPerRadio,
    required this.radios,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final seriesColors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
    ];

    final sections = <AppPieSection>[];
    for (var i = 0; i < radios.length; i++) {
      final count = clientsPerRadio[i] ?? 0;
      if (count > 0) {
        sections.add(AppPieSection(
          value: count.toDouble(),
          label: radios[i].band,
          color: seriesColors[i % seriesColors.length],
        ));
      }
    }

    if (sections.isEmpty) return const SizedBox.shrink();

    final totalClients = clientsPerRadio.values.fold(0, (a, b) => a + b);

    return Center(
      child: AppPieChart(
        sections: sections,
        donut: true,
        centerWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText.titleMedium('$totalClients'),
            AppText.labelSmall(loc(context).clients,
                color: colorScheme.onSurfaceVariant),
          ],
        ),
        size: 120,
      ),
    );
  }
}
