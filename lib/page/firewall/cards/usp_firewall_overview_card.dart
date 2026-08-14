import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/providers/card_tab_state_provider.dart';
import 'package:privacy_gui/page/_shared/components/usp_status_dot.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_forwarding_data_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Firewall Configuration Overview card — 2-tab security overview.
///
/// - Rules: Firewall rule target distribution (donut) + summary stats
/// - Ports: Port forwarding list + protocol distribution bar chart
class UspFirewallOverviewCard extends ConsumerWidget {
  const UspFirewallOverviewCard({super.key});

  static const _cardId = 'firewall_overview';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Firewall rules + DMZ from domain data provider (Layer 1).
    final firewallData = ref.watch(firewallDataProvider).valueOrNull;
    // Port forwarding from domain data provider (Layer 1).
    final pfData = ref.watch(portForwardingDataProvider).valueOrNull;
    if (firewallData == null) return const CardSkeleton.chart();
    final selectedTab = ref.watch(cardTabIndexProvider(_cardId));

    return DashboardCardTemplate.tabbed(
      title: loc(context).firewallOverview,
      detailRoute: RouteNamed.uspFirewall,
      selectedTabIndex: selectedTab,
      onTabChanged: (index) =>
          ref.read(cardTabIndexProvider(_cardId).notifier).state = index,
      tabs: [
        CardTab(
          label: loc(context).rules,
          content: _RulesTab(
            ruleSummaries: firewallData.ruleSummaries,
            portForwardingCount: pfData?.ruleModels.length ?? 0,
            dmzCount: firewallData.dmzSummaries.where((d) => d.enable).length,
          ),
        ),
        CardTab(
          label: loc(context).ports,
          content: _PortsTab(
            portForwardingRules: pfData?.ruleModels ?? [],
            dmzSummaries: firewallData.dmzSummaries,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Tab 1: Rules — target distribution donut + summary
// =============================================================================

/// Content width below which the three rule metrics stack into full-width rows
/// instead of sitting three across.
///
/// Derived, not chosen. `InfoGrid` spends 8px between tiles and each tile spends
/// 24px on [LayoutBlock] padding, so a tile's text column is
/// `(content − 16) / 3 − 24`.
///
/// The binding label is not the widest one. `ru`'s "ПРАВИЛА БРАНДМАУЭРА" is the
/// longest single line at 143.2px, but it breaks between its two words and fits
/// two lines from **71.8px**; the tightest two-line fit belongs to `es`
/// "REENVÍO DE PUERTOS" at **73.8px**. Three tiles of that need 310px of
/// content, so this sits at 328 — 80.0px of text per tile, ~6px of slack so a
/// string change cannot silently drop a label onto a third line.
///
/// Below that the grid does not merely get tight, it stops being readable and
/// stops fitting. At the narrowest width the grid ever yields — a 191px card,
/// 157.4px of content — a tile is 47.1px wide and has **23.1px** of text, which
/// is one character per line in every locale (`ru` takes 8 lines, 129px, and `es`
/// 5). Measured, that grid stood 108px tall in `en` and up to **173px** in `ru`,
/// against a tab viewport of **205px** (203px where the tab bar wraps) that also
/// owes 20px to the two gaps and 36px to the legend. 15 of the 26 locales
/// overflowed — the 15 `firewall_overview|min|0` coordinates (#1230) — and which
/// site reported depended on how tall the grid grew: see
/// [_kDonutMinRingThickness].
///
/// Stacked, the same 157px card gives each label 111.4-127.6px on one line plus
/// a second line to wrap into, which holds every locale unbroken except `fi`
/// (PALOMUURISÄÄNNÖT, 131.0px) and `nb` (BRANNMURREGLER, 118.6px) — single-word
/// labels that wrap mid-word rather than clip mid-glyph. No value of this
/// threshold buys those two an unbroken line: the grid wraps `fi` mid-word as
/// well at the width it actually runs at (a 1440px desktop leaves each tile
/// 130.0px for a 131.0px word), while the stacked form already holds it unbroken
/// from a 288px card. A single-word label that outgrows a full-width row is
/// #1240's compact-forms problem, not this constant's.
///
/// This threshold decides *arrangement*, not survival: both forms are
/// overflow-safe on their own, so getting it wrong costs a wrap, never a clip.
/// It is a local degradation, not a form selection — Track B (#1240) may later
/// replace it with a declared `normalAbove` threshold.
const double _kMetricsSideBySideMinWidth = 328;

/// Thinnest ring the target-distribution donut is drawn with, in logical px.
///
/// ui_kit's `AppPieChart` takes the section radius from the call site but the
/// centre-hole radius from the theme (`ChartStyle.pieCenterRadius`, 60px here),
/// so the drawn diameter is `2 × (centre + ring)` and does **not** follow the
/// `size` box. The old `size: 160` with the default 40px ring therefore drew a
/// 200px donut into a 160px box and the `Stack` clipped 20px off every side.
/// [_TargetDonut] sizes the ring from the slot it is actually given instead, and
/// draws nothing once that slot cannot hold this much ring — a 140px square with
/// this theme. That guard is also what makes the donut's `centerWidget` Column
/// unreachable at the realizations that used to overflow it: the caption is 40px
/// tall, and the `Expanded` holding it was 20-25px in the 8 locales that reported
/// there (`ar el fr fr_CA pt pt_PT tr vi`), so the overflow was exactly
/// `40 − slot` — +15px to +21px.
///
/// The other 7 (`es es_AR fi id nb pl ru`) never reported here at all: their grid
/// grew to 156-173px, which starves this `Expanded` to 0, and `RenderFlex` skips
/// an empty box — so the outer `Column` reported instead, by +7px to +26px. One
/// site per locale, never both, which is why the two sites sum to 15 coordinates
/// over 15 locales rather than 26 (#1230).
const double _kDonutMinRingThickness = 10;

/// Diameter the donut is drawn at when the slot is at least this big, preserving
/// the card's designed size.
const double _kDonutMaxDiameter = 160;

/// Localizes a firewall rule target value for display. The raw value (from the
/// device) is still used as the aggregation map key; only the legend label is
/// translated. Unknown targets (e.g. vendor-specific) fall back to the raw value.
String _localizeTarget(BuildContext context, String target) {
  // TR-181 Device.Firewall.Chain.{i}.Rule.{i}.Target enum values.
  switch (target) {
    case 'Accept':
      return loc(context).accept;
    case 'Drop':
      return loc(context).drop;
    case 'Reject':
      return loc(context).reject;
    case 'Return':
      return loc(context).returnTarget;
    case 'TargetChain':
      return loc(context).targetChain;
    case 'Other':
      return loc(context).other;
    default:
      return target;
  }
}

class _RulesTab extends StatelessWidget {
  final List<FirewallRuleSummary> ruleSummaries;
  final int portForwardingCount;
  final int dmzCount;

  const _RulesTab({
    required this.ruleSummaries,
    required this.portForwardingCount,
    required this.dmzCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (ruleSummaries.isEmpty) {
      return Center(
        child: AppText.bodyMedium(
          'No firewall rules configured',
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    // Aggregate by target
    final targetCounts = <String, int>{};
    int activeCount = 0;
    for (final rule in ruleSummaries) {
      final target = rule.target.isNotEmpty ? rule.target : 'Other';
      targetCounts[target] = (targetCounts[target] ?? 0) + 1;
      if (rule.enabled) activeCount++;
    }

    final seriesColors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      Colors.orange,
      Colors.purple,
    ];

    final sections = targetCounts.entries.indexed.map((e) {
      final (i, entry) = e;
      return AppPieSection(
        value: entry.value.toDouble(),
        label: _localizeTarget(context, entry.key),
        color: seriesColors[i % seriesColors.length],
      );
    }).toList();

    final metrics = <_RuleMetric>[
      _RuleMetric(
        label: loc(context).fwRules,
        value: '$activeCount/${ruleSummaries.length}',
      ),
      _RuleMetric(label: loc(context).portFwd, value: '$portForwardingCount'),
      _RuleMetric(label: 'DMZ', value: '$dmzCount'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          // Summary stats — three across while the labels have room for it, and
          // stacked full-width rows below that (see
          // [_kMetricsSideBySideMinWidth]).
          if (constraints.maxWidth >= _kMetricsSideBySideMinWidth)
            InfoGrid(
              items: [
                for (final m in metrics)
                  InfoGridItem(label: m.label, value: m.value),
              ],
              crossAxisCount: 3,
            )
          else
            _StackedMetrics(metrics: metrics),
          AppGap.md(),
          // Donut chart — drawn only when the slot left over can hold one.
          Expanded(
            child: _TargetDonut(
              sections: sections,
              total: '${ruleSummaries.length}',
            ),
          ),
          AppGap.sm(),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < targetCounts.length; i++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: seriesColors[i % seriesColors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    AppGap.xs(),
                    AppText.labelSmall(
                      '${_localizeTarget(context, targetCounts.keys.elementAt(i))}: ${targetCounts.values.elementAt(i)}',
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One Rules-tab metric. The label and the value travel together through both
/// arrangements, so they are one type rather than two parallel lists.
class _RuleMetric {
  const _RuleMetric({required this.label, required this.value});

  final String label;
  final String value;
}

/// The three metrics as full-width rows, for cards narrower than
/// [_kMetricsSideBySideMinWidth].
///
/// Label left, value right, and the label is what yields: the number *is* the
/// metric, while a wrapped or ellipsized label still names which one it is.
class _StackedMetrics extends StatelessWidget {
  const _StackedMetrics({required this.metrics});

  final List<_RuleMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < metrics.length; i++) ...[
          if (i > 0) AppGap.sm(),
          LayoutBlock(
            // 8px, not the block's default 12px: three rows, the 20px of gaps
            // after them and the 36px legend all have to fit the 205px the tab
            // gets at the card's 3-row minimum (203px where the tab bar wraps).
            // At 8px the stack measures 112px (`en`) to 130px (`ru`, where one
            // label takes two lines); the donut's `Expanded` absorbs the
            // remaining 17-37px and draws nothing in it, which is why the legend
            // lands exactly on the content edge. At the block's 12px default each
            // row grows 8px, the stack becomes 136-154px, and the legend is
            // pushed 3-7px past that edge onto the footer the template does not
            // scroll (#1230).
            padding: BlockConstants.paddingSm,
            child: Row(
              children: [
                Expanded(
                  child: AppText.labelSmall(
                    metrics[i].label.toUpperCase(),
                    color: colorScheme.onSurfaceVariant,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AppGap.sm(),
                AppText.labelMedium(metrics[i].value),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// The target-distribution donut, sized to the slot the tab has left for it —
/// and absent when that slot is too small to draw a ring in.
///
/// Absent rather than shrunk because the centre-hole radius is a theme value the
/// call site cannot lower (see [_kDonutMinRingThickness]), so below ~140px there
/// is no donut to draw, only a clipped arc. The legend underneath keeps carrying
/// every target and its count, so nothing is lost but the picture.
class _TargetDonut extends StatelessWidget {
  const _TargetDonut({required this.sections, required this.total});

  final List<AppPieSection> sections;

  /// Rule count shown in the centre of the donut.
  final String total;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final centreRadius = AppDesignTheme.of(context).chartStyle.pieCenterRadius;

    return LayoutBuilder(
      builder: (context, constraints) {
        final diameter = math.min(
          math.min(constraints.maxWidth, constraints.maxHeight),
          _kDonutMaxDiameter,
        );
        if (diameter < 2 * (centreRadius + _kDonutMinRingThickness)) {
          return const SizedBox.shrink();
        }
        return Center(
          child: AppPieChart(
            sections: sections,
            donut: true,
            // The legend already names every slice; a title painted inside a
            // 20px ring would be a clipped duplicate of it.
            showLabels: false,
            // Keeps the drawn diameter equal to the box, which the ui_kit
            // default does not — see [_kDonutMinRingThickness].
            sectionRadius: diameter / 2 - centreRadius,
            size: diameter,
            centerWidget: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.titleMedium(total),
                AppText.labelSmall(loc(context).rules,
                    color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// Tab 2: Ports — forwarding list + protocol bar chart
// =============================================================================

/// Slot height below which the protocol bar chart is not drawn.
///
/// Derived from what the chart spends before it draws a single bar:
///
/// * **22px** for the bottom axis strip. That is fl_chart's `SideTitles`
///   default `reservedSize`, and `AppBarChart`'s vertical path does not override
///   it — so the strip asks for 22px whatever the chart's height is, and its own
///   `Flex` (fl_chart `side_titles_widget.dart:245`) overflows by `22 − slot`
///   when the slot is shorter. That is exactly the 6 `firewall_overview|min|1`
///   coordinates: +5px in `da`/`pl`/`pt`/`pt_PT`/`sv` (17px slots) and +10px in
///   `ru` (12px) (#1230).
/// * **24px** for the always-on value labels, which fl_chart paints above the
///   tallest bar (`tooltipMargin: 4` + 2×2 padding + a 16px label line).
/// * **24px** of bars, which is `AppBarChart`'s own `minBarArea` — the number its
///   horizontal path uses to decide when a chart has room for axis labels at all.
///
/// Measured slots: 12-37px at the card's 3-row minimum (at both 191px and 288px,
/// the only two widths the grid realizes for it) and 148-173px at the 4 rows its
/// `HeightStrategy.strict(4)` actually gives it. So this suppresses the chart at
/// the minimum height, keeps it at the shipped height, and no locale sits near
/// the boundary.
///
/// #1230's plan preferred suppressing the *axis labels* rather than the chart, and
/// that lever does exist: `AppBarChart.xLabels` is nullable and its vertical path
/// passes `showTitles: xLabels != null`, so `xLabels: null` removes the 22px strip
/// entirely. Measured — with no height guard at all, that alone takes every one of
/// the card's 105 gate cases green. It is not taken because of what it leaves on
/// screen: the value axis keeps drawing, so at `ru`'s 12px slot its "2" and "0"
/// labels overlap each other above two 8px pills, and the only threshold that
/// would admit the labelless chart where it does read (`en`, 37px) and reject it
/// where it does not (`da`, 17px) sits between 37 and 40px — a knife edge between
/// two shipped locales, where 70px leaves every locale 33px clear. The picture is
/// dropped and the list above it keeps the information.
const double _kProtocolChartMinHeight = 70;

class _PortsTab extends StatelessWidget {
  final List portForwardingRules;
  final List<DmzEntrySummary> dmzSummaries;

  const _PortsTab({
    required this.portForwardingRules,
    required this.dmzSummaries,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (portForwardingRules.isEmpty && dmzSummaries.isEmpty) {
      return Center(
        child: AppText.bodyMedium(
          loc(context).noPortMappingsConfigured,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    // Protocol distribution
    final protocolCounts = <String, int>{};
    for (final rule in portForwardingRules) {
      final proto = rule.protocol as String;
      protocolCounts[proto] = (protocolCounts[proto] ?? 0) + 1;
    }

    // Active DMZ entries
    final activeDmz = dmzSummaries.where((d) => d.enable).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Port forwarding list (top 5)
        if (portForwardingRules.isNotEmpty) ...[
          AppText.labelLarge(
              loc(context).portForwardingWithCount(portForwardingRules.length)),
          AppGap.sm(),
          ...portForwardingRules.take(5).map((rule) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    UspStatusDot(isActive: rule.enabled),
                    AppGap.sm(),
                    _ProtocolBadge(protocol: rule.protocol),
                    AppGap.sm(),
                    Expanded(
                      child: MapsToRow(
                        source: rule.portRangeDisplay,
                        target: rule.internalTargetDisplay,
                      ),
                    ),
                  ],
                ),
              )),
        ],
        // DMZ section
        if (activeDmz.isNotEmpty) ...[
          AppGap.md(),
          AppText.labelLarge('DMZ'),
          AppGap.sm(),
          ...activeDmz.map((d) => Row(
                children: [
                  UspStatusDot(isActive: true),
                  AppGap.sm(),
                  AppText.bodySmall(loc(context).targetIp(d.destIp)),
                ],
              )),
        ],
        // Protocol distribution bar chart — only when the list above leaves a
        // slot that can hold one (see [_kProtocolChartMinHeight]).
        if (protocolCounts.isNotEmpty) ...[
          AppGap.md(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxHeight < _kProtocolChartMinHeight) {
                  return const SizedBox.shrink();
                }
                return AppBarChart(
                  series: [
                    AppChartSeries(
                      label: loc(context).rules,
                      data: protocolCounts.values
                          .map((v) => v.toDouble())
                          .toList(),
                      color: colorScheme.primary,
                    ),
                  ],
                  xLabels: protocolCounts.keys.toList(),
                  showValueLabels: true,
                  valueLabelFormatter: (v) => '${v.toInt()}',
                  showTooltip: false,
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// Shared widgets
// =============================================================================

class _ProtocolBadge extends StatelessWidget {
  final String protocol;
  const _ProtocolBadge({required this.protocol});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: AppText.labelSmall(
        protocol,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }
}
