import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/utils/usp_formatters.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/_shared/providers/usp_system_monitor_notifier.dart';
import 'package:privacy_gui/page/_shared/components/usp_info_row.dart';
import 'package:privacy_gui/page/statistics/views/components/stats_section_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// CPU & Memory gauges + uptime info.
class StatsSystemGaugesSection extends ConsumerWidget {
  const StatsSystemGaugesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(systemInfoDataProvider).valueOrNull?.model;
    final monitorState = ref.watch(uspSystemMonitorProvider);

    return StatsSectionCard(
      title: loc(context).cpuAndMemory,
      subtitle: loc(context).currentResourceUtilization,
      chartHeight: 240,
      child: info == null
          ? Center(
              child: AppText.bodyMedium(
                loc(context).loading,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : _buildChart(context, info, monitorState),
    );
  }

  Widget _buildChart(BuildContext context, dynamic info, dynamic monitorState) {
    final colorScheme = Theme.of(context).colorScheme;
    final latest = monitorState.latest;
    final cpuPercent = latest?.cpuPercent ?? info.cpuPercent;
    final memPercent = latest?.memoryPercent ?? info.memoryPercent;
    final memUsedStr = latest != null
        ? UspFormatters.formatBytes(latest.usedMemoryKb * 1024)
        : info.formattedUsedMemory;
    final memTotalStr = latest != null
        ? UspFormatters.formatBytes(latest.totalMemoryKb * 1024)
        : info.formattedTotalMemory;

    return Column(
      children: [
        UspInfoRow(label: loc(context).uptime, value: info.formattedUptime),
        AppGap.md(),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              AppGauge(
                value: cpuPercent.toDouble(),
                size: 100,
                centerBuilder: (ctx, v) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText.titleMedium('$cpuPercent%'),
                    AppText.bodySmall(loc(context).cpu),
                  ],
                ),
              ),
              AppGauge(
                value: memPercent.toDouble(),
                size: 100,
                centerBuilder: (ctx, v) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText.titleMedium('$memPercent%'),
                    AppText.bodySmall(loc(context).memory),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppGap.sm(),
        Center(
          child: AppText.bodySmall(
            loc(context).memoryUsed(memUsedStr, memTotalStr),
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        AppGap.md(),
        Row(
          children: [
            StatsLegendDot(color: colorScheme.primary),
            AppGap.xs(),
            AppText.labelSmall(
                loc(context).cpuPercent('${latest?.cpuPercent ?? '--'}')),
            AppGap.lg(),
            StatsLegendDot(color: colorScheme.secondary),
            AppGap.xs(),
            AppText.labelSmall(
                loc(context).memoryPercent('${latest?.memoryPercent ?? '--'}')),
          ],
        ),
      ],
    );
  }
}
