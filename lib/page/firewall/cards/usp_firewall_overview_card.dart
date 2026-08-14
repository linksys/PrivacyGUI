import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/providers/card_tab_state_provider.dart';
import 'package:privacy_gui/page/_shared/components/usp_status_dot.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
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
/// Below this [_TargetDonut] draws nothing — a 140px square with this theme's
/// 60px hole. Two things make suppression the right call rather than shrinking:
///
/// * **The caption.** ui_kit v2.34.11 derives both radii from the box, and in a
///   box too small for the themed hole it shrinks the *hole* rather than the
///   ring — so a `centerWidget` sized against the themed value can overhang a
///   tight one, which ui_kit documents on `centerWidget` itself. This card's
///   caption is a 40px-tall count and word, and this floor is what keeps it
///   inside the hole it is centred in.
/// * **The overflow.** Suppression is also what makes that caption unreachable
///   at the realizations that used to overflow it: the caption is 40px tall, and
///   the `Expanded` holding it was 20-25px in the 8 locales that reported there
///   (`ar el fr fr_CA pt pt_PT tr vi`), so the overflow was exactly `40 − slot`
///   — +15px to +21px.
///
/// The other 7 (`es es_AR fi id nb pl ru`) never reported here at all: their grid
/// grew to 156-173px, which starves this `Expanded` to 0, and `RenderFlex` skips
/// an empty box — so the outer `Column` reported instead, by +7px to +26px. One
/// site per locale, never both, which is why the two sites sum to 15 coordinates
/// over 15 locales rather than 26 (#1230).
///
/// ## What this guard used to also carry
///
/// ui_kit ≤ v2.34.10 took the section radius from the call site but the
/// centre-hole radius from the theme, so the drawn diameter was
/// `2 × (centre + ring)` and did **not** follow the `size` box: `size: 160` with
/// the default 40px ring drew a 200px donut — measured, 200px at every `size`
/// from 120 to 300 — and the card surface clipped 20px off every side. Filed as
/// linksys/privacyGUI-UI-kit#22 and fixed in v2.34.11, which derives the drawing
/// from the box. The `sectionRadius: diameter / 2 - centreRadius` this card
/// carried against the old behaviour is gone with the bump: the drawn diameter is
/// the box by construction now, and the only thing left to decide here is whether
/// a donut is worth drawing at all.
const double _kDonutMinRingThickness = 10;

/// Ring thickness the donut is drawn with when the slot allows it, in logical px.
///
/// The donut's diameter is `2 × (centre + this)` — 160px against this theme's
/// 60px hole, the card's designed size — capped by the slot it is given.
///
/// Written as a ring rather than as a flat 160px diameter so it cannot contradict
/// [_kDonutMinRingThickness]: both are measured outward from the same themed hole,
/// so the cap is always the wider of the two. A flat 160 silently narrows the
/// window instead — a 65px hole under `neumorphic` would leave only 150-160px —
/// and past a 70px hole closes it altogether, drawing no donut in any locale at
/// any width with nothing failing to say so (#1230).
const double _kDonutDesignRingThickness = 20;

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
          loc(context).noFirewallRulesConfigured,
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
///
/// Composition-wise this is `_InfoGridTile` in a `Row` at 8px padding, which
/// `layout_blocks` has no variant for; `usp_ethernet_ports_card.dart`'s
/// `_SummaryTile` is the same shape again. Folding all three into a shared
/// compact variant is #1275.
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
/// Absent rather than shrunk because below ~140px what is left is not a smaller
/// donut but an outline with a caption spilling out of its hole (see
/// [_kDonutMinRingThickness]). The legend underneath keeps carrying every target
/// and its count, so nothing is lost but the picture.
class _TargetDonut extends StatelessWidget {
  const _TargetDonut({required this.sections, required this.total});

  final List<AppPieSection> sections;

  /// Rule count shown in the centre of the donut.
  final String total;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Read here rather than in the outer build so the size the donut asks
        // for and the floor that admits it come off the same theme in the same
        // place — they are two readings of one hole and must not drift apart.
        final centreRadius =
            AppDesignTheme.of(context).chartStyle.pieCenterRadius;
        final diameter = math.min(
          math.min(constraints.maxWidth, constraints.maxHeight),
          2 * (centreRadius + _kDonutDesignRingThickness),
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
            // No `sectionRadius`: since v2.34.11 ui_kit derives the ring from
            // this box, so asking for one only makes it thinner than it needs to
            // be — see [_kDonutMinRingThickness].
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
  final List<PortForwardingRuleUIModel> portForwardingRules;
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
      final proto = rule.protocol;
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
