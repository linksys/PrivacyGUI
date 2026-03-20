import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_performance_helpers.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/page/_shared/providers/card_tab_state_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
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

  static const _tabs = [
    TabItem(label: 'Signal'),
    TabItem(label: 'Speed'),
    TabItem(label: 'Channels'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wifiData = ref.watch(wifiDataProvider).valueOrNull;
    if (wifiData == null) return const CardSkeleton.chart();
    final devicesData = ref.watch(devicesDataProvider).valueOrNull;
    final selectedTab = ref.watch(cardTabIndexProvider(_cardId));

    // Collect active WiFi clients with their device names and band info
    final activeClients = <_ClientInfo>[];
    for (final entry in wifiData.wifiClientMap.entries) {
      final client = entry.value;
      if (!client.active) continue;
      // Resolve display name from deviceModels
      final device = devicesData?.deviceModels
          .where((d) => d.mac.toUpperCase() == entry.key.toUpperCase())
          .firstOrNull;
      final name = device?.hostName ?? entry.key;
      final displayName =
          name.length > 10 ? '${name.substring(0, 9)}\u2026' : name;
      // Resolve band from connectionDetailMap (AP → SSID → Radio chain)
      final detail = wifiData.connectionDetailMap[entry.key];
      activeClients.add(_ClientInfo(
        mac: entry.key,
        displayName: displayName,
        client: client,
        band: detail?.band ?? '',
      ));
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.titleMedium('WiFi Performance'),
              AppText.labelLarge('${activeClients.length} clients'),
            ],
          ),
          AppGap.md(),
          AppTabs(
            tabs: _tabs,
            initialIndex: selectedTab,
            displayMode: TabDisplayMode.segmented,
            showBorder: false,
            onTabChanged: (index) =>
                ref.read(cardTabIndexProvider(_cardId).notifier).state = index,
          ),
          AppGap.md(),
          Expanded(
            child: switch (selectedTab) {
              0 => _SignalTab(clients: activeClients),
              1 => _SpeedTab(clients: activeClients),
              2 => _ChannelsTab(
                  radios: wifiData.radioModels,
                  clients: activeClients,
                ),
              _ => const SizedBox.shrink(),
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Helper class for client info
// =============================================================================

class _ClientInfo {
  final String mac;
  final String displayName;
  final WifiClientUIModel client;
  final String band; // "2.4GHz", "5GHz", "6GHz", or ""

  const _ClientInfo({
    required this.mac,
    required this.displayName,
    required this.client,
    this.band = '',
  });
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
            separatorBuilder: (_, __) => AppGap.xs(),
            itemBuilder: (context, index) {
              final c = clients[index];
              final rssi = c.client.signalStrength;
              final tier = WifiPerformanceHelpers.signalTier(rssi);
              final color = WifiPerformanceHelpers.tierColor(tier, colorScheme);
              // Normalize: -100 dBm → 0.0, -30 dBm → 1.0
              final norm = ((rssi + 100) / 70).clamp(0.0, 1.0);

              return Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: AppText.labelSmall(c.displayName),
                  ),
                  AppGap.sm(),
                  Expanded(
                    child: _ColoredLinearBar(value: norm, color: color),
                  ),
                  AppGap.sm(),
                  SizedBox(
                    width: 60,
                    child: AppText.bodySmall(
                      '$rssi dBm',
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        AppGap.sm(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final entry in [
              (SignalTier.excellent, 'Excellent'),
              (SignalTier.good, 'Good'),
              (SignalTier.fair, 'Fair'),
              (SignalTier.weak, 'Weak'),
            ]) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color:
                      WifiPerformanceHelpers.tierColor(entry.$1, colorScheme),
                  shape: BoxShape.circle,
                ),
              ),
              AppGap.xs(),
              AppText.labelSmall(entry.$2),
              AppGap.md(),
            ],
          ],
        ),
      ],
    );
  }
}

class _ColoredLinearBar extends StatelessWidget {
  final double value;
  final Color color;
  const _ColoredLinearBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 12,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: constraints.maxWidth * value,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// Tab 2: Speed — grouped DL/UL bar chart per client
// =============================================================================

class _SpeedTab extends StatelessWidget {
  final List<_ClientInfo> clients;
  const _SpeedTab({required this.clients});

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

    // Convert kbps to Mbps for chart display
    final dlData =
        clients.map((c) => c.client.lastDataDownlinkRate / 1000).toList();
    final ulData =
        clients.map((c) => c.client.lastDataUplinkRate / 1000).toList();
    final xLabels = clients.map((c) => c.displayName).toList();

    return Column(
      children: [
        Expanded(
          child: AppBarChart(
            series: [
              AppChartSeries(
                label: 'Downlink',
                data: dlData,
                color: colorScheme.primary,
              ),
              AppChartSeries(
                label: 'Uplink',
                data: ulData,
                color: colorScheme.secondary,
              ),
            ],
            xLabels: xLabels,
            yLabelFormatter: (v) => '${v.toInt()} Mbps',
            showValueLabels: clients.length <= 4,
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
            AppText.labelSmall('Downlink'),
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
            AppText.labelSmall('Uplink'),
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
      final snr = WifiPerformanceHelpers.computeSNR(
          c.client.signalStrength, c.client.noise);
      snrSumPerRadio[radioIdx] = (snrSumPerRadio[radioIdx] ?? 0) + snr;
      snrCountPerRadio[radioIdx] = (snrCountPerRadio[radioIdx] ?? 0) + 1;
    }

    // Compute average SNR per radio
    final avgSnrPerRadio = <int, double>{};
    for (final key in snrSumPerRadio.keys) {
      avgSnrPerRadio[key] = snrSumPerRadio[key]! / snrCountPerRadio[key]!;
    }

    return Column(
      children: [
        // Per-radio info rows
        ...List.generate(radios.length, (i) {
          final radio = radios[i];
          final clientCount = clientsPerRadio[i] ?? 0;
          final snr = avgSnrPerRadio[i] ?? 0;
          final snrNorm = WifiPerformanceHelpers.normalizeSNR(snr.toInt());

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
                    AppText.bodySmall('$clientCount clients'),
                    AppGap.md(),
                    AppText.bodySmall('SNR: ${snr.toInt()} dB'),
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
        // Band distribution donut (if we have data)
        if (clients.isNotEmpty) ...[
          AppGap.sm(),
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
            AppText.labelSmall('clients', color: colorScheme.onSurfaceVariant),
          ],
        ),
        size: 120,
      ),
    );
  }
}
