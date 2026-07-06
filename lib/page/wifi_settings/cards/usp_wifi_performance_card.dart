import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/components/wifi_ui.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
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
    if (wifiData == null) return const CardSkeleton.chart();
    final devicesData = ref.watch(devicesDataProvider).valueOrNull;
    final selectedTab = ref.watch(cardTabIndexProvider(_cardId));

    // Collect active WiFi clients with their device names and band info
    final activeClients = <_ClientInfo>[];
    for (final entry in wifiData.wifiClientMap.entries) {
      final client = entry.value;
      if (!client.active) continue;
      // Resolve display name from clientDevices
      final device = devicesData?.clientDevices
          .where((d) => d.mac.toUpperCase() == entry.key.toUpperCase())
          .firstOrNull;
      final displayName = device?.hostName ?? entry.key;
      // Resolve band from connectionDetailMap (AP → SSID → Radio chain)
      final detail = wifiData.connectionDetailMap[entry.key];
      activeClients.add(_ClientInfo(
        mac: entry.key,
        displayName: displayName,
        client: client,
        band: detail?.band ?? '',
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
            separatorBuilder: (_, __) => AppGap.sm(),
            itemBuilder: (context, index) {
              final c = clients[index];
              final rssi = c.client.signalStrength;
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
      final snr = computeSNR(c.client.signalStrength, c.client.noise);
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
