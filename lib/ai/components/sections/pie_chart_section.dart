import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Pie chart section for displaying proportional data.
///
/// Can display as standard pie or donut chart.
class PieChartSection extends StatelessWidget {
  /// Sections of the pie chart.
  /// Each section is a map with 'label' (String) and 'value' (double).
  final List<Map<String, dynamic>> sections;

  /// Chart height in pixels (default: 200).
  final double height;

  /// Whether to display as donut chart (default: false).
  final bool donut;

  /// Whether to show section labels (default: true).
  final bool showLabels;

  const PieChartSection({
    super.key,
    required this.sections,
    this.height = 200,
    this.donut = false,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(child: AppText.body(loc(context).noDataAvailable)),
      );
    }

    final chartSections = sections.map((s) {
      final label = s['label'] as String? ?? loc(context).section;
      final value = (s['value'] as num?)?.toDouble() ?? 0;
      final color = s['color'] as Color?;
      return AppPieSection(
        label: label,
        value: value,
        color: color,
      );
    }).toList();

    return SizedBox(
      height: height,
      child: AppPieChart(
        sections: chartSections,
        donut: donut,
        showLabels: showLabels,
      ),
    );
  }
}
