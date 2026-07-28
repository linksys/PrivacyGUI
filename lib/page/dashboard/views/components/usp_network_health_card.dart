import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/models/network_health_helpers.dart';
import 'package:privacy_gui/page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/page/_shared/providers/card_tab_state_provider.dart';
import 'package:privacy_gui/page/_shared/providers/usp_traffic_analysis_notifier.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Network Health Monitoring card — 3-tab card (F-022).
///
/// Reads data from [uspTrafficAnalysisProvider] (shared timer, no separate poll).
///
/// - Health: Composite score gauge + traffic light indicators
/// - Errors: Error/discard rate area chart over time
/// - Loss: Packet loss % line chart over time
class UspNetworkHealthCard extends ConsumerStatefulWidget {
  const UspNetworkHealthCard({super.key});

  @override
  ConsumerState<UspNetworkHealthCard> createState() =>
      _UspNetworkHealthCardState();
}

class _UspNetworkHealthCardState extends ConsumerState<UspNetworkHealthCard> {
  static const _cardId = 'network_health';

  @override
  Widget build(BuildContext context) {
    final trafficState = ref.watch(uspTrafficAnalysisProvider);
    final selectedTab = ref.watch(cardTabIndexProvider(_cardId));
    // Physical WAN link state — same signal the page-top connection banner
    // uses. Consulted so a disconnected WAN is not scored "Excellent" purely
    // because a down link carries no traffic (loss 0%). See #1143.
    final wanIsUp = ref.watch(wanDataProvider).valueOrNull?.model.isUp ?? true;

    return DashboardCardTemplate.tabbed(
      title: loc(context).networkHealth,
      titleBadge: trafficState.isFetching
          ? SizedBox(
              width: 14,
              height: 14,
              child: AppLoader(strokeWidth: 2),
            )
          : null,
      selectedTabIndex: selectedTab,
      onTabChanged: (index) =>
          ref.read(cardTabIndexProvider(_cardId).notifier).state = index,
      tabs: [
        CardTab(
          label: loc(context).health,
          content: _buildTabContent(context, trafficState, wanIsUp, 0),
        ),
        CardTab(
          label: loc(context).errors,
          content: _buildTabContent(context, trafficState, wanIsUp, 1),
        ),
        CardTab(
          label: loc(context).loss,
          content: _buildTabContent(context, trafficState, wanIsUp, 2),
        ),
      ],
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    TrafficAnalysisState state,
    bool wanIsUp,
    int selectedTab,
  ) {
    if (state.history.isEmpty) {
      return Center(
        child: AppText.bodyMedium(
          loc(context).enableTrafficMonitorForHealthData,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return switch (selectedTab) {
      0 =>
        _HealthOverview(state: state, wanIsUp: wanIsUp, parentContext: context),
      1 => _ErrorsChart(state: state, parentContext: context),
      2 => _LossChart(state: state, parentContext: context),
      _ => const SizedBox.shrink(),
    };
  }
}

// =============================================================================
// Tab 1: Health Overview (Gauge + Traffic Lights + Summary)
// =============================================================================

class _HealthOverview extends StatelessWidget {
  final TrafficAnalysisState state;
  final bool wanIsUp;
  final BuildContext parentContext;
  const _HealthOverview({
    required this.state,
    required this.wanIsUp,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final wan = state.latest?.interfaces[TrafficInterface.wan];
    final lan = state.latest?.interfaces[TrafficInterface.lan];

    // WAN score consults physical link state: a disconnected WAN scores 0
    // ("Critical") regardless of (absent) traffic, so it can no longer be
    // reported as "Excellent" while the connection banner says otherwise.
    // See #1143.
    final wanScore =
        NetworkHealthHelpers.computeWanScore(wan, wanIsUp: wanIsUp);
    final lanScore =
        lan != null ? NetworkHealthHelpers.computeHealthScore(lan) : 100;
    // Overall score = min of WAN and LAN
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
        // WAN / LAN traffic light row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TrafficLight(
              label: loc(parentContext).wan,
              tier: wanTier,
              colorScheme: colorScheme,
              // When the WAN link is physically down, show "Disconnected"
              // instead of a health tier so the card agrees with the
              // page-top connection banner. See #1143.
              statusOverride: wanIsUp ? null : loc(parentContext).disconnected,
            ),
            AppGap.xl(),
            _TrafficLight(
              label: loc(parentContext).lan,
              tier: lanTier,
              colorScheme: colorScheme,
            ),
          ],
        ),
        AppGap.md(),
        // Summary metrics
        Row(
          children: [
            Expanded(
              child: _MetricChip(
                label: loc(parentContext).errors,
                value: NetworkHealthHelpers.formatFaultRate(errorRate),
              ),
            ),
            AppGap.sm(),
            Expanded(
              child: _MetricChip(
                label: loc(parentContext).discards,
                value: NetworkHealthHelpers.formatFaultRate(discardRate),
              ),
            ),
            AppGap.sm(),
            Expanded(
              child: _MetricChip(
                label: loc(parentContext).loss,
                value: '${lossPercent.toStringAsFixed(2)}%',
              ),
            ),
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

  /// When non-null, replaces the health-tier label (e.g. "Disconnected"
  /// for a physically down WAN link). The dot color still follows [tier].
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
    return LayoutBlock(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.labelSmall(
            label,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          AppGap.xxs(),
          AppText.bodyMedium(value),
        ],
      ),
    );
  }
}

// =============================================================================
// Tab 2: Errors (Error/Discard Rate Over Time)
// =============================================================================

class _ErrorsChart extends StatelessWidget {
  final TrafficAnalysisState state;
  final BuildContext parentContext;
  const _ErrorsChart({required this.state, required this.parentContext});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final history = state.history;

    final errorData = history
        .map(
            (s) => s.interfaces[TrafficInterface.wan]?.totalErrorsPerSec ?? 0.0)
        .toList();
    final discardData = history
        .map((s) =>
            s.interfaces[TrafficInterface.wan]?.totalDiscardsPerSec ?? 0.0)
        .toList();

    // Compute stats
    final avgErr = errorData.isEmpty
        ? 0.0
        : errorData.reduce((a, b) => a + b) / errorData.length;
    final peakErr = errorData.isEmpty ? 0.0 : errorData.reduce(math.max);
    final avgDisc = discardData.isEmpty
        ? 0.0
        : discardData.reduce((a, b) => a + b) / discardData.length;

    // Auto Y-axis
    final allValues = [...errorData, ...discardData];
    final maxVal = allValues.isEmpty ? 1.0 : allValues.reduce(math.max);
    final yMax = maxVal < 0.1 ? 1.0 : maxVal * 1.3;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 8),
            child: AppLineChart(
              series: [
                AppChartSeries(
                  label: loc(parentContext).errors,
                  data: errorData,
                  filled: true,
                  color: colorScheme.error,
                ),
                AppChartSeries(
                  label: loc(parentContext).discards,
                  data: discardData,
                  color: Colors.orange,
                ),
              ],
              yAxis: AppChartAxis(min: 0, max: yMax),
              yLabelFormatter: (v) => v.toStringAsFixed(1),
              showTooltip: false,
            ),
          ),
        ),
        AppGap.sm(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: colorScheme.error),
            AppGap.xs(),
            AppText.labelSmall(
              loc(parentContext).avgValuePeakValue(
                NetworkHealthHelpers.formatFaultRate(avgErr),
                NetworkHealthHelpers.formatFaultRate(peakErr),
              ),
            ),
            AppGap.lg(),
            _LegendDot(color: Colors.orange),
            AppGap.xs(),
            AppText.labelSmall(
              loc(parentContext)
                  .avgValue(NetworkHealthHelpers.formatFaultRate(avgDisc)),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// Tab 3: Loss (Packet Loss % Over Time)
// =============================================================================

class _LossChart extends StatelessWidget {
  final TrafficAnalysisState state;
  final BuildContext parentContext;
  const _LossChart({required this.state, required this.parentContext});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final history = state.history;

    final lossData = history.map((s) {
      final wan = s.interfaces[TrafficInterface.wan];
      return wan != null ? NetworkHealthHelpers.computeLossPercent(wan) : 0.0;
    }).toList();

    final avgLoss = lossData.isEmpty
        ? 0.0
        : lossData.reduce((a, b) => a + b) / lossData.length;
    final peakLoss = lossData.isEmpty ? 0.0 : lossData.reduce(math.max);

    final maxVal = lossData.isEmpty ? 1.0 : lossData.reduce(math.max);
    final yMax = maxVal < 0.1 ? 1.0 : maxVal * 1.3;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 8),
            child: AppLineChart(
              series: [
                AppChartSeries(
                  label: loc(parentContext).loss,
                  data: lossData,
                  filled: true,
                  color: colorScheme.error,
                ),
              ],
              yAxis: AppChartAxis(min: 0, max: yMax),
              yLabelFormatter: (v) => '${v.toStringAsFixed(2)}%',
              showTooltip: false,
            ),
          ),
        ),
        AppGap.sm(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: colorScheme.error),
            AppGap.xs(),
            AppText.labelSmall(
              loc(parentContext).avgValuePeakValue(
                '${avgLoss.toStringAsFixed(3)}%',
                '${peakLoss.toStringAsFixed(3)}%',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// Shared
// =============================================================================

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
