import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/card_density_scope.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/models/network_health_helpers.dart';
import 'package:privacy_gui/page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/page/_shared/providers/card_tab_state_provider.dart';
import 'package:privacy_gui/page/_shared/providers/usp_traffic_analysis_notifier.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Placeholder shown for traffic metrics that carry no meaningful value while
/// the WAN link is down (a disconnected link carries no traffic, so 0%/0/s
/// would be misleading). Language-neutral, so no localization key is needed.
const String _kNoTrafficPlaceholder = '--';

/// The three health scores, computed once for the two places that need them:
/// the Health tab's gauge and traffic lights, and the card's `popupValue`.
///
/// WAN consults physical link state: a disconnected WAN scores 0 ("Critical")
/// regardless of (absent) traffic, so it can no longer be reported as
/// "Excellent" while the connection banner says otherwise. See #1143.
({int wan, int lan, int overall}) _scores(
  TrafficAnalysisState state, {
  required bool wanIsUp,
}) {
  final wan = state.latest?.interfaces[TrafficInterface.wan];
  final lan = state.latest?.interfaces[TrafficInterface.lan];
  final wanScore = NetworkHealthHelpers.computeWanScore(wan, wanIsUp: wanIsUp);
  final lanScore =
      lan != null ? NetworkHealthHelpers.computeHealthScore(lan) : 100;
  return (
    wan: wanScore,
    lan: lanScore,
    // Overall score = min of WAN and LAN.
    overall: math.min(wanScore, lanScore),
  );
}

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
    final wanIsUp = ref.watch(wanIsUpProvider);

    return DashboardCardTemplate.tabbed(
      title: loc(context).networkHealth,
      // The popup form's one value is the **score**, not the tier (#1291).
      //
      // Both were on the table. The score wins on two counts: it is the finer
      // reading of the same fact, and the popup form's own title already names
      // the metric, so "82" under "Network Health" needs no other word. The tier
      // would also import the exact problem the popup form exists to escape —
      // `Mittelmäßig` / `Удовлетворительный` are the widest strings this card
      // owns, and the popup slot is the narrowest place it has.
      //
      // Both no-data states speak the vocabulary the gauge centre speaks, for
      // the same reason it does (#1143): a down link carries no traffic, so a
      // score would be a number about nothing.
      popupValue: !wanIsUp
          ? loc(context).disconnected
          : trafficState.history.isEmpty
              ? _kNoTrafficPlaceholder
              : '${_scores(trafficState, wanIsUp: wanIsUp).overall}',
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
      1 => _ErrorsChart(state: state, wanIsUp: wanIsUp, parentContext: context),
      2 => _LossChart(state: state, wanIsUp: wanIsUp, parentContext: context),
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
    final compact = CardDensityScope.of(context) == CardDensity.compact;
    final wan = state.latest?.interfaces[TrafficInterface.wan];

    final scores = _scores(state, wanIsUp: wanIsUp);
    final wanScore = scores.wan;
    final lanScore = scores.lan;
    final overallScore = scores.overall;
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
              // The centre is a non-positioned `Stack` child inside `AppGauge`,
              // so it is handed the gauge's *laid* box loose — and that box is
              // not 120×120 here. `AppGauge` respects its incoming constraints,
              // and this `Expanded` is squeezed hard enough that the gauge lays
              // out at 120×67 in `en` and 120×**23** in `de`. The centre column
              // needs 44px (28 for the score, 16 for the tier), so it reported
              // +21.0px (`de`), +11.0px (`ru`) and +9.0px (`th`) — #1235's three
              // coordinates. Bottom overflow, not the too-wide tier label the
              // ticket assumed; measuring first is what turned that up.
              //
              // The squeeze comes from `_MetricChip`, three columns of ~23.1px
              // of text at this width, whose labels soft-wrap: `Discards` takes
              // 3 lines (48px) and `Verworfene Pakete` takes **6** (96px). So
              // the height left for the gauge is a function of translation
              // length, and the three failing locales are exactly the three with
              // the longest metric labels — #1183's premise ("translation length
              // must not decide whether the layout is valid") violated one level
              // up from where it showed.
              //
              // `BoxFit.scaleDown` is the fix that fits AC 4 as written: "a tier
              // abbreviated past recognition is worse than a smaller font". It
              // never drops or truncates the tier — in `ru` it stops the label
              // wrapping to two lines and shrinks it 3% instead — and it scales
              // nothing at any width where the centre already fitted, so the
              // wide layouts are byte-identical. It is also self-relaxing: the
              // moment the metric row stops eating the height (Track B), the
              // scale returns to 1.0 with no code change, which a hardcoded
              // abbreviation or a dropped label would not.
              //
              // What it does NOT fix, deliberately: at 191px those metric labels
              // are illegible in every locale, `en` included — `Discards` breaks
              // mid-word across 3 lines today. That is this card being rendered
              // at 191px when §1.2 measures its fit width at 420px, so it is a
              // threshold question for #1240 and not something to paper over
              // here by ellipsizing a label to `V…`. The worst scale this leaves
              // is 0.52 in `de`, and that number is the density defect's
              // measurement, not a design choice.
              centerBuilder: (ctx, v) => FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // When the WAN is down the score gauge shows the neutral
                    // placeholder + "Disconnected" so it speaks the same
                    // vocabulary as the traffic-light row and the banner, rather
                    // than "0 / Critical". See #1143.
                    AppText.titleLarge(
                        wanIsUp ? '$overallScore' : _kNoTrafficPlaceholder),
                    AppText.labelSmall(
                      wanIsUp
                          ? tier.resolveLabel(ctx)
                          : loc(parentContext).disconnected,
                      color: tierClr,
                    ),
                  ],
                ),
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
        // #1143 reached for that same `Wrap` for a different reason — to fit the
        // longer "WAN: Disconnected" label — and #1227 replaced it with this
        // `Row`. That label is still shown, via [_TrafficLight.statusOverride];
        // it just degrades horizontally now like every other label here.
        //
        // So the row stays a `Row` and gives horizontally instead: both lights
        // are `Flexible`, so the row's height is exactly one line at every width
        // and the gauge keeps its space. What gives is label length — sound here
        // because the tier is *also* the dot's colour, so a clipped word still
        // reads (#1226 rule 2). Widest case is `ru`: 'Глобальная сеть' +
        // 'Удовлетворительный', longer than any override.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: _TrafficLight(
                label: loc(parentContext).wan,
                tier: wanTier,
                colorScheme: colorScheme,
                // When the WAN link is physically down, show "Disconnected"
                // instead of a health tier so the card agrees with the
                // page-top connection banner. See #1143.
                statusOverride:
                    wanIsUp ? null : loc(parentContext).disconnected,
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
        // Summary metrics — dropped **whole** below the card's threshold (#1291).
        //
        // This row is what starves the gauge. The two are exactly complementary:
        // measured across 26 locales, `gauge + row == 165px` at every width, and
        // the row's height is a function of translation length, so `de` takes
        // 142px of it (`Verworfene Pakete` on 6 lines) and leaves the gauge 23px
        // for a centre column that needs 44 — the 0.52 scale #1235 absorbed with
        // `BoxFit.scaleDown` and handed here.
        //
        // Dropping it returns the whole 165px, so the gauge lays out at its full
        // 120x120 — a ring rather than a 120x23 sliver — and the centre scales at
        // 1.000 in all 26 locales (`ru` 0.973, which is its centre being 123px
        // wide against a 120px gauge: a *width* bind, present at desktop too, and
        // no threshold can pay for it).
        //
        // Dropped rather than degraded, and #1275's narrow `InfoGrid` measured
        // rather than assumed, because this ticket was told to check it first:
        //
        //   | compact form                      | row   | gauge | worst scale |
        //   |-----------------------------------|-------|-------|-------------|
        //   | this one (dropped)                | 0     | 120   | 1.000       |
        //   | #1275 stacked InfoGrid, 25 locales| 112   | 53    | 1.000       |
        //   | #1275 stacked InfoGrid, `de`      | 128   | 37    | 0.841       |
        //
        // The stacked form gives every label the full width, so no label wraps in
        // 25 locales — but `VERWORFENE PAKETE` still needs two lines at 200-215px,
        // and 3 tiles cost 112px even at one line each. It buys legibility with
        // height, which is the right trade for `firewall_overview`'s *width*
        // defect and the wrong one here.
        //
        // What the reader loses is nothing this card does not already show
        // better one tab across: the Errors tab carries errors **and** discards
        // as avg + peak, and the Loss tab carries loss the same way. That is why
        // the whole row can go rather than one metric of three — there is no
        // metric here whose only home is this row.
        if (!compact) ...[
          AppGap.md(),
          Row(
            children: [
              Expanded(
                child: _MetricChip(
                  label: loc(parentContext).errors,
                  value: errorText,
                ),
              ),
              AppGap.sm(),
              Expanded(
                child: _MetricChip(
                  label: loc(parentContext).discards,
                  value: discardText,
                ),
              ),
              AppGap.sm(),
              Expanded(
                child: _MetricChip(
                  label: loc(parentContext).loss,
                  value: lossText,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// One WAN/LAN status light: tier-coloured dot, gap, one-line label.
///
/// Deliberately **not** migrated to `AppChartLegendEntry` by #1245, even though
/// the shape rhymes with the legend entries the chart tabs now share. The kit's
/// mark occupies a 16px-wide box (a 10px disc centred in it), so each light
/// would gain 6px of width — and this is the one row in the card where width is
/// not free: §2.10a point 3, the row that once held 26 overflow coordinates.
/// #1245's "not in scope" is explicit that a refactor may not change which rows
/// overflow, and AC 4 requires `dashboard_legend_readability_test.dart` to pass
/// unmodified. Its dot is 10px, not the legends' 8px, for the same reason it is
/// a separate widget: a status light is not a series key.
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
        // `Flexible` so the label can give at all: a `Row` gives non-flex
        // children unbounded width, so without it 'Глобальная сеть:
        // Удовлетворительный' overflows however the caller arranges the lights.
        //
        // One line + ellipsis, unlike the chart-tab legends which soft-wrap. Two
        // reasons. The tier is *also* encoded as the dot's colour
        // (`NetworkHealthHelpers.tierColor`), so a clipped word still reads —
        // this is #1226 rule 2, not a statistic being cut. And this tab is the
        // one place where extra height is not free: the gauge above sits in an
        // `Expanded` with a fixed 120px size, so a taller row here pushes the
        // gauge's own centre column into a bottom overflow (measured: letting
        // these labels wrap turns 3 bottom-overflowing coordinates into 15).
        //
        // [status], not `tier.resolveLabel(context)` directly: a physically down
        // WAN reads "Disconnected" rather than a health tier (#1143), and the
        // ellipsis has to apply to whichever of the two is showing.
        Flexible(
          child: AppText.labelSmall(
            '$label: $status',
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
  final bool wanIsUp;
  final BuildContext parentContext;
  const _ErrorsChart({
    required this.state,
    required this.wanIsUp,
    required this.parentContext,
  });

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
        if (!wanIsUp) _DisconnectNotice(parentContext: parentContext),
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
            // `.statistic` on both, so the composed 'Errors  Avg: … Peak: …'
            // soft-wraps rather than ellipsizing a number away (§2.10a point 2).
            // The marks mirror the chart above: errors is `filled: true`, so
            // `lineFilled`; discards is a plain line. Dots on both, because
            // `AppLineChart.showDots` defaults to true.
            AppChartLegendEntry.statistic(
              mark: const ChartMark.lineFilled(dot: true),
              color: colorScheme.error,
              label: loc(parentContext).seriesAvgValuePeakValue(
                loc(parentContext).errors,
                NetworkHealthHelpers.formatFaultRate(avgErr),
                NetworkHealthHelpers.formatFaultRate(peakErr),
              ),
            ),
            AppChartLegendEntry.statistic(
              mark: const ChartMark.line(dot: true),
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
  final bool wanIsUp;
  final BuildContext parentContext;
  const _LossChart({
    required this.state,
    required this.wanIsUp,
    required this.parentContext,
  });

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
        if (!wanIsUp) _DisconnectNotice(parentContext: parentContext),
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
        // run-breaking, it just bounds the entry's width so its internal
        // `Flexible` can soft-wrap the label.
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          children: [
            AppChartLegendEntry.statistic(
              mark: const ChartMark.lineFilled(dot: true),
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

/// Inline notice shown above the Errors/Loss charts when the WAN link is down.
///
/// The historical chart still renders (past data is real), but a down link
/// carries no current traffic, so this makes clear that the flat-lining series
/// reflect a disconnect rather than a perfectly healthy link — keeping the
/// chart tabs consistent with the banner and the Health tab. See #1143.
class _DisconnectNotice extends StatelessWidget {
  final BuildContext parentContext;
  const _DisconnectNotice({required this.parentContext});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(top: 4, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon.font(
            Icons.wifi_off,
            size: 14,
            color: colorScheme.error,
          ),
          AppGap.xs(),
          AppText.labelSmall(
            loc(parentContext).disconnected,
            color: colorScheme.error,
          ),
        ],
      ),
    );
  }
}
