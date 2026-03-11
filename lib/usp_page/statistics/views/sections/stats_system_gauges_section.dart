import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/generated/transforms.g.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_notifier.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_system_monitor_notifier.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_info_row.dart';
import 'package:privacy_gui/usp_page/statistics/views/components/stats_section_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// CPU & Memory gauges + uptime info.
class StatsSystemGaugesSection extends ConsumerWidget {
  const StatsSystemGaugesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info =
        ref.watch(uspDashboardProvider).valueOrNull?.systemInfoModel;
    final monitorState = ref.watch(uspSystemMonitorProvider);

    return StatsSectionCard(
      title: 'CPU & Memory',
      subtitle: 'Current resource utilization',
      chartHeight: 240,
      child: info == null
          ? Center(
              child: AppText.bodyMedium(
                'Loading...',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : _buildChart(context, info, monitorState),
    );
  }

  Widget _buildChart(
      BuildContext context, dynamic info, dynamic monitorState) {
    final colorScheme = Theme.of(context).colorScheme;
    final latest = monitorState.latest;
    final cpuPercent = latest?.cpuPercent ?? info.cpuPercent;
    final memPercent = latest?.memoryPercent ?? info.memoryPercent;
    final memUsedStr = latest != null
        ? Transforms.formatBytes(latest.usedMemoryKb * 1024)
        : info.formattedUsedMemory;
    final memTotalStr = latest != null
        ? Transforms.formatBytes(latest.totalMemoryKb * 1024)
        : info.formattedTotalMemory;

    return Column(
      children: [
        UspInfoRow(label: 'Uptime', value: info.formattedUptime),
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
                    AppText.bodySmall('CPU'),
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
                    AppText.bodySmall('Memory'),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppGap.sm(),
        Center(
          child: AppText.bodySmall(
            '$memUsedStr / $memTotalStr used',
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        AppGap.md(),
        Row(
          children: [
            StatsLegendDot(color: colorScheme.primary),
            AppGap.xs(),
            AppText.labelSmall('CPU: ${latest?.cpuPercent ?? '--'}%'),
            AppGap.lg(),
            StatsLegendDot(color: colorScheme.secondary),
            AppGap.xs(),
            AppText.labelSmall('Memory: ${latest?.memoryPercent ?? '--'}%'),
          ],
        ),
      ],
    );
  }
}
