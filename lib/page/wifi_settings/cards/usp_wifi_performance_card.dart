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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final tier in [
              SignalTier.excellent,
              SignalTier.good,
              SignalTier.fair,
              SignalTier.weak,
            ]) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: tier.resolveColor(colorScheme),
                  shape: BoxShape.circle,
                ),
              ),
              AppGap.xs(),
              AppText.labelSmall(tier.resolveLabel(context)),
              AppGap.md(),
            ],
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            AppGap.xs(),
            AppText.labelSmall(loc(context).downlink),
            AppGap.lg(),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: colorScheme.secondary,
                shape: BoxShape.circle,
              ),
            ),
            AppGap.xs(),
            AppText.labelSmall(loc(context).uplink),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppText.labelLarge(radio.band),
                      const Spacer(),
                      AppText.bodySmall(
                        'Ch ${radio.channelDisplay}  \u00b7  ${radio.channelBandwidth}',
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
