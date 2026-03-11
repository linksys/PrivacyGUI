import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/generated/transforms.g.dart';
import 'package:privacy_gui/usp_page/dashboard/models/traffic_analysis_state.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_traffic_analysis_notifier.dart';
import 'package:privacy_gui/usp_page/statistics/views/components/stats_section_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Cumulative traffic distribution donut + per-interface breakdown bars.
class StatsTrafficDistributionSection extends ConsumerWidget {
  const StatsTrafficDistributionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uspTrafficAnalysisProvider);

    return StatsSectionCard(
      title: 'Traffic Distribution',
      subtitle: 'Cumulative traffic proportion by interface',
      chartHeight: 320,
      child: state.latest == null
          ? Center(
              child: AppText.bodyMedium(
                'Waiting for data...',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : _buildChart(context, state.latest!),
    );
  }

  Widget _buildChart(BuildContext context, MultiInterfaceSnapshot snapshot) {
    final colorScheme = Theme.of(context).colorScheme;
    final wan = snapshot.interfaces[TrafficInterface.wan];
    final lan = snapshot.interfaces[TrafficInterface.lan];
    final wanTotal = wan?.totalBytes ?? 0;
    final lanTotal = lan?.totalBytes ?? 0;
    final grandTotal = wanTotal + lanTotal;

    return Column(
      children: [
        Flexible(
          child: Center(
            child: AppPieChart(
              sections: [
                AppPieSection(
                    value: wanTotal.toDouble(),
                    label: 'WAN',
                    color: colorScheme.primary),
                AppPieSection(
                    value: lanTotal.toDouble(),
                    label: 'LAN',
                    color: colorScheme.secondary),
              ],
              donut: true,
              centerWidget: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText.titleSmall(Transforms.formatBytes(grandTotal)),
                  AppText.labelSmall('total',
                      color: colorScheme.onSurfaceVariant),
                ],
              ),
              size: 180,
            ),
          ),
        ),
        AppGap.sm(),
        if (wan != null || lan != null)
          _InterfaceBreakdownBars(wan: wan, lan: lan),
        AppGap.sm(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StatsLegendDot(color: colorScheme.primary),
            AppGap.xs(),
            AppText.labelSmall('WAN: ${Transforms.formatBytes(wanTotal)}'),
            AppGap.lg(),
            StatsLegendDot(color: colorScheme.secondary),
            AppGap.xs(),
            AppText.labelSmall('LAN: ${Transforms.formatBytes(lanTotal)}'),
          ],
        ),
      ],
    );
  }
}

class _InterfaceBreakdownBars extends StatelessWidget {
  final InterfaceTrafficSnapshot? wan;
  final InterfaceTrafficSnapshot? lan;
  const _InterfaceBreakdownBars({this.wan, this.lan});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final entries = <(String, int, int, Color)>[];
    if (wan != null) {
      entries.add(
          ('WAN', wan!.totalBytesSent, wan!.totalBytesReceived, colorScheme.primary));
    }
    if (lan != null) {
      entries.add(
          ('LAN', lan!.totalBytesSent, lan!.totalBytesReceived, colorScheme.secondary));
    }
    final maxBytes = entries.fold(0, (a, e) => math.max(a, e.$2 + e.$3));

    return Column(
      children: [
        for (final (label, sent, recv, color) in entries)
          Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: AppText.labelSmall(label, textAlign: TextAlign.end),
                ),
                AppGap.sm(),
                Expanded(child: _DualBar(sent: sent, recv: recv, maxValue: maxBytes, color: color)),
              ],
            ),
          ),
      ],
    );
  }
}

class _DualBar extends StatelessWidget {
  final int sent;
  final int recv;
  final int maxValue;
  final Color color;
  const _DualBar({required this.sent, required this.recv, required this.maxValue, required this.color});

  @override
  Widget build(BuildContext context) {
    final total = sent + recv;
    final fraction = maxValue > 0 ? total / maxValue : 0.0;
    final sentFraction = total > 0 ? sent / total : 0.5;

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth * fraction;
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: barWidth,
            height: 12,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                Container(width: barWidth * sentFraction, color: color),
                Expanded(child: Container(color: color.withValues(alpha: 0.4))),
              ],
            ),
          ),
        );
      },
    );
  }
}
