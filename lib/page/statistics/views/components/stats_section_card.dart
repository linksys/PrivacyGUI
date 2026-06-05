import 'package:flutter/material.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Shared wrapper for each chart section in the Statistics page.
///
/// Displays a title row (with optional subtitle and trailing action)
/// above a fixed-height chart area wrapped in an [AppCard] with Block.
class StatsSectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double chartHeight;
  final Widget child;
  final Widget? trailing;

  const StatsSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.chartHeight,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.titleSmall(title),
                    if (subtitle != null)
                      AppText.bodySmall(
                        subtitle!,
                        color: colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          AppGap.md(),
          LayoutBlock(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SizedBox(
              height: chartHeight,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared legend dot — 8×8 colored circle for chart legends.
class StatsLegendDot extends StatelessWidget {
  final Color color;
  const StatsLegendDot({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ---------------------------------------------------------------------------
// Interactive Pie Chart — shows section details on hover/tap in donut center
// ---------------------------------------------------------------------------

/// Wraps [AppPieChart] with touch interaction.
///
/// On hover/tap, replaces the donut center widget with the touched section's
/// label + percentage. Reverts to [defaultCenter] when touch exits.
class InteractivePieChart extends StatefulWidget {
  final List<AppPieSection> sections;
  final bool donut;
  final Widget? defaultCenter;
  final double size;
  final String Function(AppPieSection section, double total)?
      touchedCenterLabel;

  const InteractivePieChart({
    super.key,
    required this.sections,
    this.donut = true,
    this.defaultCenter,
    this.size = 180,
    this.touchedCenterLabel,
  });

  @override
  State<InteractivePieChart> createState() => _InteractivePieChartState();
}

class _InteractivePieChartState extends State<InteractivePieChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = widget.sections.fold(0.0, (sum, s) => sum + s.value);

    Widget? center;
    if (_touchedIndex != null && _touchedIndex! < widget.sections.length) {
      final section = widget.sections[_touchedIndex!];
      final pct = total > 0 ? (section.value / total * 100) : 0.0;
      final label = widget.touchedCenterLabel?.call(section, total) ??
          '${pct.toStringAsFixed(1)}%';
      center = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.titleSmall(label),
          AppText.labelSmall(
            section.label ?? '',
            color: section.color ?? colorScheme.onSurfaceVariant,
          ),
        ],
      );
    } else {
      center = widget.defaultCenter;
    }

    return AppPieChart(
      sections: widget.sections,
      donut: widget.donut,
      centerWidget: center,
      size: widget.size,
      onTouch: (event) {
        setState(() {
          if (event.type == AppChartTouchType.exit ||
              event.touchedPoints.isEmpty) {
            _touchedIndex = null;
          } else {
            _touchedIndex = event.touchedPoints.first.dataIndex;
          }
        });
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Shared tooltip formatters
// ---------------------------------------------------------------------------

/// Formats bytes/sec for chart tooltips (e.g. "Upload: 1.2 KB/s").
String statsFormatSpeedTooltip(String label, double bytesPerSec) {
  const units = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
  var value = bytesPerSec;
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }
  return '$label: ${value.toStringAsFixed(value < 10 ? 1 : 0)} ${units[unitIndex]}';
}

/// Formats percentage for chart tooltips (e.g. "CPU: 42.5%").
String statsFormatPercentTooltip(String label, double value) {
  return '$label: ${value.toStringAsFixed(1)}%';
}

/// Formats fault rate for chart tooltips (e.g. "Errors: 0.5/s").
String statsFormatRateTooltip(String label, double value) {
  return '$label: ${value.toStringAsFixed(2)}/s';
}
