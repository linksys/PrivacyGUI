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
          content: _buildTabContent(context, trafficState, 0),
        ),
        CardTab(
          label: loc(context).errors,
          content: _buildTabContent(context, trafficState, 1),
        ),
        CardTab(
          label: loc(context).loss,
          content: _buildTabContent(context, trafficState, 2),
        ),
      ],
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    TrafficAnalysisState state,
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
      0 => _HealthOverview(state: state, parentContext: context),
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
  final BuildContext parentContext;
  const _HealthOverview({required this.state, required this.parentContext});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final wan = state.latest?.interfaces[TrafficInterface.wan];
    final lan = state.latest?.interfaces[TrafficInterface.lan];

    final wanScore =
        wan != null ? NetworkHealthHelpers.computeHealthScore(wan) : 100;
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
        // WAN / LAN traffic light row.
        //
        // DELIBERATE DEVIATION from #1226's shape, which the other five rows in
        // this ticket follow. #1226 uses a `Wrap` and pays for the extra run with
        // height, explicitly because "the chart above is `Expanded`, so it yields
        // the height". That precondition fails here: what sits above is an
        // `Expanded` holding a gauge of **fixed** 120px, so it yields nothing —
        // a second run just pushes the gauge's own centre column past its
        // circle. Measured: a `Wrap` here trades this row's 26 right-overflowing
        // coordinates for 12 *new* bottom-overflowing ones at the gauge
        // (`_HealthOverview` gauge centre, 3 → 15), which is a fix on paper only.
        //
        // So the row stays a `Row` and gives horizontally instead: both lights
        // are `Flexible`, so the row's height is exactly one line at every width
        // and the gauge keeps its space. What gives is label length — sound here
        // because the tier is *also* the dot's colour, so a clipped word still
        // reads (#1226 rule 2). Widest case is `ru`: 'Глобальная сеть' +
        // 'Удовлетворительный'.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: _TrafficLight(
                label: loc(parentContext).wan,
                tier: wanTier,
                colorScheme: colorScheme,
              ),
            ),
            AppGap.xl(),
            Flexible(
              child: _TrafficLight(
                label: loc(parentContext).lan,
                tier: lanTier,
                colorScheme: colorScheme,
              ),
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

  const _TrafficLight({
    required this.label,
    required this.tier,
    required this.colorScheme,
  });

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
        // `Flexible` so the label can give at all: a `Row` gives non-flex
        // children unbounded width, so without it 'Глобальная сеть:
        // Удовлетворительный' overflows however the enclosing `Wrap` arranges the
        // lights.
        //
        // One line + ellipsis, unlike the chart-tab legends which soft-wrap. Two
        // reasons. The tier is *also* encoded as the dot's colour
        // (`NetworkHealthHelpers.tierColor`), so a clipped word still reads —
        // this is #1226 rule 2, not a statistic being cut. And this tab is the
        // one place where extra height is not free: the gauge above sits in an
        // `Expanded` with a fixed 120px size, so a taller row here pushes the
        // gauge's own centre column into a bottom overflow (measured: letting
        // these labels wrap turns 3 bottom-overflowing coordinates into 15).
        Flexible(
          child: AppText.labelSmall(
            '$label: ${tier.resolveLabel(context)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
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
                  color: colorScheme.tertiary,
                ),
              ],
              yAxis: AppChartAxis(min: 0, max: yMax),
              yLabelFormatter: (v) => v.toStringAsFixed(1),
              showTooltip: false,
            ),
          ),
        ),
        AppGap.sm(),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          children: [
            _LegendEntry(
              color: colorScheme.error,
              label: loc(parentContext).seriesAvgValuePeakValue(
                loc(parentContext).errors,
                NetworkHealthHelpers.formatFaultRate(avgErr),
                NetworkHealthHelpers.formatFaultRate(peakErr),
              ),
            ),
            _LegendEntry(
              color: colorScheme.tertiary,
              label: loc(parentContext).seriesAvgValue(
                loc(parentContext).discards,
                NetworkHealthHelpers.formatFaultRate(avgDisc),
              ),
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
        // A single entry, but its composed 'Loss  Avg: 0.00%  Peak: 0.00%' label
        // is the longest legend string in the card, so it needs the same `Wrap`
        // as the Errors tab (#1226) — with one child the `Wrap` contributes no
        // run-breaking, it just lets the entry keep its intrinsic width while
        // `_LegendEntry` soft-wraps the label.
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          children: [
            _LegendEntry(
              color: colorScheme.error,
              label: loc(parentContext).seriesAvgValuePeakValue(
                loc(parentContext).loss,
                '${avgLoss.toStringAsFixed(2)}%',
                '${peakLoss.toStringAsFixed(2)}%',
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

/// One legend entry: colour dot, gap, label — the unit that must never split, so
/// a label never separates from the colour it explains (#1226 rule 2).
///
/// File-private on purpose. The same shape exists in `usp_system_status_card` (as
/// `_StatLegendEntry`) and `usp_traffic_analysis_card`, and extracting one shared
/// widget from the four copies needs Article XIV approval — #1233 deliberately
/// does not block on that conversation, so the shape is replicated in place and
/// the extraction raised separately.
class _LegendEntry extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendEntry({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LegendDot(color: color),
        AppGap.xs(),
        // `Flexible`, because a `Row` hands non-flex children unbounded width: a
        // bare label takes its full intrinsic width on one line and overflows no
        // matter how the enclosing `Wrap` arranges the entries. Loose fit, so a
        // short label still hugs and two entries share one run when they fit.
        //
        // No ellipsis, unlike #1226's bare series names: every label here is the
        // composed 'series, average, peak' string, so clipping it would cut a
        // statistic in half — an unreadable number is worse than a second line,
        // and the chart above is `Expanded` so it yields the height.
        Flexible(child: AppText.labelSmall(label)),
      ],
    );
  }
}
