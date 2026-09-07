import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/network_health_helpers.dart';
import 'package:privacy_gui/page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/page/_shared/providers/usp_traffic_analysis_notifier.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:privacy_gui/page/statistics/views/components/stats_section_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Placeholder shown for traffic metrics that carry no meaningful value while
/// the WAN link is down. Language-neutral, so no localization key is needed.
const String _kNoTrafficPlaceholder = '--';

/// Composite health score gauge + WAN/LAN traffic lights + summary metrics.
class StatsHealthScoreSection extends ConsumerWidget {
  const StatsHealthScoreSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uspTrafficAnalysisProvider);
    // Physical WAN link state — the same signal the dashboard's Network Health
    // card and connection banner use. A disconnected WAN must not be scored
    // "Excellent" just because a down link carries no traffic. See #1143.
    final wanIsUp = ref.watch(wanIsUpProvider);

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
          : _buildChart(context, state, wanIsUp),
    );
  }

  Widget _buildChart(
      BuildContext context, TrafficAnalysisState state, bool wanIsUp) {
    final colorScheme = Theme.of(context).colorScheme;
    final wan = state.latest?.interfaces[TrafficInterface.wan];
    final lan = state.latest?.interfaces[TrafficInterface.lan];

    final wanScore =
        NetworkHealthHelpers.computeWanScore(wan, wanIsUp: wanIsUp);
    final lanScore =
        lan != null ? NetworkHealthHelpers.computeHealthScore(lan) : 100;
    final overallScore = math.min(wanScore, lanScore);
    final tier = NetworkHealthHelpers.tierFromScore(overallScore);
    final tierClr = NetworkHealthHelpers.tierColor(tier, colorScheme);

    final wanTier = NetworkHealthHelpers.tierFromScore(wanScore);
    final lanTier = NetworkHealthHelpers.tierFromScore(lanScore);

    // A down WAN link carries no traffic, so loss/error/discard would all read
    // 0 and contradict the "Disconnected" status. Show a neutral placeholder
    // instead of a misleading zero. See #1143.
    final lossText = wanIsUp
        ? '${(wan != null ? NetworkHealthHelpers.computeLossPercent(wan) : 0.0).toStringAsFixed(2)}%'
        : _kNoTrafficPlaceholder;
    final errorText = wanIsUp
        ? NetworkHealthHelpers.formatFaultRate(wan?.totalErrorsPerSec ?? 0)
        : _kNoTrafficPlaceholder;
    final discardText = wanIsUp
        ? NetworkHealthHelpers.formatFaultRate(wan?.totalDiscardsPerSec ?? 0)
        : _kNoTrafficPlaceholder;

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
                  AppText.titleLarge(
                      wanIsUp ? '$overallScore' : _kNoTrafficPlaceholder),
                  AppText.labelSmall(
                    wanIsUp
                        ? tier.resolveLabel(ctx)
                        : loc(context).disconnected,
                    color: tierClr,
                  ),
                ],
              ),
            ),
          ),
        ),
        AppGap.sm(),
        // Wrap (not Row) so the longer "WAN: Disconnected" label flows to a
        // second line on narrow layouts instead of overflowing. See #1143.
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.xs,
          children: [
            _TrafficLight(
                label: loc(context).wan,
                tier: wanTier,
                colorScheme: colorScheme,
                statusOverride: wanIsUp ? null : loc(context).disconnected),
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
            _MetricChip(label: loc(context).errors, value: errorText),
            _MetricChip(label: loc(context).discards, value: discardText),
            _MetricChip(label: loc(context).loss, value: lossText),
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

  /// When non-null, replaces the health-tier label (e.g. "Disconnected" for a
  /// physically down WAN link). The dot color still follows [tier]. See #1143.
  final String? statusOverride;

  const _TrafficLight({
    required this.label,
    required this.tier,
    required this.colorScheme,
    this.statusOverride,
  });

  @override
  Widget build(BuildContext context) {
    final color = NetworkHealthHelpers.tierColor(tier, colorScheme);
    final status = statusOverride ?? tier.resolveLabel(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        AppGap.xs(),
        AppText.labelSmall('$label: $status'),
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
