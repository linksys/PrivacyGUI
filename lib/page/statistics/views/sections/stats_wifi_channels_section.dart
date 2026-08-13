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
              // `stretch`, not `start`, and it is load-bearing for the `Wrap`
              // below. `start` hands children a *loose* width constraint, so a
              // `Wrap` shrink-wraps to its intrinsic width and
              // `WrapAlignment.spaceBetween` has no free space to distribute —
              // it silently degrades to `spacing` and the whole block sits
              // centred in the section instead of spanning it. `stretch` makes
              // the width tight, which is what the pre-#1258 `Row` + `Spacer`
              // had, so `spaceBetween` reproduces the `Spacer` exactly.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Band + channel string.
                //
                // DEGRADATION SHAPE (#1258, the third instance of the #1226 /
                // #1252 shape on this page) — design §2.10, §2.10a:
                //
                //  1. A `Wrap`, not a `Row` + `Spacer`. While the content fits it
                //     renders exactly as before: one run, `spaceBetween` puts the
                //     band left and the channel string right, which is what the
                //     `Spacer` did — but only because the `Column` above
                //     stretches it. Under a loose width `spaceBetween` is a
                //     no-op; see the `crossAxisAlignment` note there. When it
                //     does not fit — a localized `'Ch '` prefix or a 3-digit
                //     6GHz channel would eat the 47px of headroom #1258
                //     measured — the channel string drops to a second line
                //     instead of overflowing.
                //  2. Neither side yields to an ellipsis: the band is the
                //     identity of the block and the channel string is composed
                //     data (§2.10a point 2). Both are content, not chrome, so
                //     they keep their intrinsic width and the row wraps as a
                //     unit — an ellipsis mid-channel-string misinforms.
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.xs,
                  children: [
                    AppText.labelLarge(radio.band),
                    AppText.bodySmall(
                      'Ch ${radio.channelDisplay}  \u00b7  ${radio.channelBandwidth}',
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                AppGap.xs(),
                // Client count + SNR + signal bar.
                //
                //  1. A `Wrap`, not a `Row` + `Expanded`. The `Expanded` on the
                //     progress bar is the same cliff as the `Spacer` above: it
                //     absorbs slack while the stats fit and collapses to zero
                //     when they do not, at which point the unconstrained stats
                //     overflow right (#1258 measured +27px in `fi` at a 192px
                //     section).
                //  2. The two stats never shrink: no `Flexible`, no `maxLines`,
                //     no ellipsis (§2.10a point 2) — a half-shown count or SNR
                //     misinforms.
                //  3. The stats group is itself a nested `Wrap`, not a
                //     `Row(min)`. A `Row(min)` still hands its children
                //     unbounded width, so it reintroduces the very shape this
                //     ticket removes one level down: with the signal bar already
                //     on its own run, `clientsCount` + `snrValue` alone overflow
                //     a 216px section in `fi` (and 192px in `fi`/`ja`/`ko`/`vi`),
                //     which is above the 192px floor AC-1 asks for. As a `Wrap`
                //     the SNR drops to a third run instead, and each stat still
                //     keeps its full intrinsic width — nothing is clipped or
                //     ellipsized, which is what §2.10a point 2 actually
                //     requires. Splitting the pair across runs is a weaker cost
                //     than clipping a number: both labels stay attached to their
                //     own values.
                //  4. The signal bar is the decoration and the thing that yields
                //     first (§2.10a point 2): it takes a fixed intrinsic width
                //     via a `SizedBox`, and when the stats no longer leave room
                //     for it the outer `Wrap` drops it to its own run rather
                //     than overflowing.
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xs,
                      children: [
                        AppText.bodySmall(
                            loc(context).clientsCount(clientCount)),
                        AppText.bodySmall(loc(context).snrValue(snr.toInt())),
                      ],
                    ),
                    SizedBox(
                      width: 96,
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
            AppText.labelSmall(loc(context).clients,
                color: colorScheme.onSurfaceVariant),
          ],
        ),
        touchedCenterLabel: (section, _) => '${section.value.toInt()}',
        size: 120,
      ),
    );
  }
}
