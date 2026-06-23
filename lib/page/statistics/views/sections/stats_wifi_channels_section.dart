import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/wifi_ui.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/page/statistics/views/components/stats_section_card.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Radio channel info + per-band client distribution donut.
class StatsWifiChannelsSection extends ConsumerWidget {
  const StatsWifiChannelsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wifiData = ref.watch(wifiDataProvider).valueOrNull;
    if (wifiData == null) {
      return StatsSectionCard(
        title: loc(context).wifiChannels,
        subtitle: loc(context).wifiChannelsSubtitle,
        chartHeight: 320,
        child: Center(
          child: AppText.bodyMedium(
            loc(context).loading,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final radios = wifiData.radioModels;
    final activeClients = _buildClientList(wifiData);

    return StatsSectionCard(
      title: loc(context).wifiChannels,
      subtitle: loc(context).wifiChannelsSubtitle,
      chartHeight: 320,
      child: radios.isEmpty
          ? Center(
              child: AppText.bodyMedium(
                loc(context).noWifiRadiosAvailable,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : _buildChart(context, radios, activeClients),
    );
  }

  List<_ClientInfo> _buildClientList(WifiData wifiData) {
    final clients = <_ClientInfo>[];
    for (final entry in wifiData.wifiClientMap.entries) {
      final client = entry.value;
      if (!client.active) continue;
      final detail = wifiData.connectionDetailMap[entry.key];
      clients.add(_ClientInfo(client: client, band: detail?.band ?? ''));
    }
    return clients;
  }

  Widget _buildChart(BuildContext context, List<WifiRadioUIModel> radios,
      List<_ClientInfo> clients) {
    final colorScheme = Theme.of(context).colorScheme;

    // Build band → radio index lookup
    final bandToRadioIdx = <String, int>{};
    for (var i = 0; i < radios.length; i++) {
      bandToRadioIdx[radios[i].band] = i;
    }

    // Group clients by radio
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

    final avgSnrPerRadio = <int, double>{};
    for (final key in snrSumPerRadio.keys) {
      avgSnrPerRadio[key] = snrSumPerRadio[key]! / snrCountPerRadio[key]!;
    }

    final seriesColors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
    ];

    return Column(
      children: [
        // Per-radio info rows
        ...List.generate(radios.length, (i) {
          final radio = radios[i];
          final clientCount = clientsPerRadio[i] ?? 0;
          final snr = avgSnrPerRadio[i] ?? 0;
          final snrNorm = normalizeSNR(snr.toInt());

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
        // Band distribution donut
        if (clients.isNotEmpty) ...[
          AppGap.sm(),
          Expanded(
            child: _BandDistributionDonut(
              clientsPerRadio: clientsPerRadio,
              radios: radios,
              seriesColors: seriesColors,
            ),
          ),
        ],
      ],
    );
  }
}

class _ClientInfo {
  final WifiClientUIModel client;
  final String band;
  const _ClientInfo({required this.client, this.band = ''});
}

class _BandDistributionDonut extends StatelessWidget {
  final Map<int, int> clientsPerRadio;
  final List<WifiRadioUIModel> radios;
  final List<Color> seriesColors;
  const _BandDistributionDonut({
    required this.clientsPerRadio,
    required this.radios,
    required this.seriesColors,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
      child: InteractivePieChart(
        sections: sections,
        defaultCenter: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText.titleMedium('$totalClients'),
            AppText.labelSmall('clients', color: colorScheme.onSurfaceVariant),
          ],
        ),
        touchedCenterLabel: (section, _) => '${section.value.toInt()}',
        size: 120,
      ),
    );
  }
}
