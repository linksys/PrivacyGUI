import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/network_health_helpers.dart';
import 'package:privacy_gui/page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/page/_shared/providers/usp_traffic_analysis_notifier.dart';
import 'package:privacy_gui/page/statistics/views/components/stats_section_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Composite health score gauge + WAN/LAN traffic lights + summary metrics.
class StatsHealthScoreSection extends ConsumerWidget {
  const StatsHealthScoreSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uspTrafficAnalysisProvider);

    return StatsSectionCard(
      title: loc(context).networkHealthScore,
      subtitle: loc(context).networkHealthSubtitle,
      chartHeight: 240,
      child: state.history.isEmpty
          ? Center(
              child: AppText.bodyMedium(
                loc(context).enableTrafficMonitorForHealthData,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : _buildChart(context, state),
    );
  }

  Widget _buildChart(BuildContext context, TrafficAnalysisState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final wan = state.latest?.interfaces[TrafficInterface.wan];
    final lan = state.latest?.interfaces[TrafficInterface.lan];

    final wanScore =
        wan != null ? NetworkHealthHelpers.computeHealthScore(wan) : 100;
    final lanScore =
        lan != null ? NetworkHealthHelpers.computeHealthScore(lan) : 100;
    final overallScore = math.min(wanScore, lanScore);
    final tier = NetworkHealthHelpers.tierFromScore(overallScore);
    final tierClr = NetworkHealthHelpers.tierColor(tier, colorScheme);

    final wanTier = NetworkHealthHelpers.tierFromScore(wanScore);
    final lanTier = NetworkHealthHelpers.tierFromScore(lanScore);

    final lossPercent =
        wan != null ? NetworkHealthHelpers.computeLossPercent(wan) : 0.0;
    final errorRate = wan?.totalErrorsPerSec ?? 0;
    final discardRate = wan?.totalDiscardsPerSec ?? 0;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: AppGauge(
              value: overallScore.toDouble(),
              size: 120,
              centerBuilder: (ctx, v) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText.titleLarge('$overallScore'),
                  AppText.labelSmall(
                    tier.resolveLabel(ctx),
                    color: tierClr,
                  ),
                ],
              ),
            ),
          ),
        ),
        AppGap.sm(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TrafficLight(
                label: loc(context).wan,
                tier: wanTier,
                colorScheme: colorScheme),
            AppGap.xl(),
            _TrafficLight(
                label: loc(context).lan,
                tier: lanTier,
                colorScheme: colorScheme),
          ],
        ),
        AppGap.md(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _MetricChip(
                label: loc(context).errors,
                value: NetworkHealthHelpers.formatFaultRate(errorRate)),
            _MetricChip(
                label: loc(context).discards,
                value: NetworkHealthHelpers.formatFaultRate(discardRate)),
            _MetricChip(
                label: loc(context).loss,
                value: '${lossPercent.toStringAsFixed(2)}%'),
          ],
        ),
      ],
    );
  }
}

class _TrafficLight extends StatelessWidget {
  final String label;
  final HealthTier tier;
  final ColorScheme colorScheme;
  const _TrafficLight(
      {required this.label, required this.tier, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final color = NetworkHealthHelpers.tierColor(tier, colorScheme);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        AppGap.xs(),
        AppText.labelSmall('$label: ${tier.resolveLabel(context)}'),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText.labelSmall(label,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        AppText.bodyMedium(value),
      ],
    );
  }
}
