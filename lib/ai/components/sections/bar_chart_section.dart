import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Bar chart section for displaying categorical data comparisons.
///
/// Supports single or multiple series, stacked or grouped bars.
class BarChartSection extends StatelessWidget {
  /// Data series to display.
  /// Each series is a map with 'label' (String) and 'data' (List<double>).
  final List<Map<String, dynamic>> series;

  /// Labels for X-axis categories.
  final List<String>? xLabels;

  /// Chart height in pixels (default: 200).
  final double height;

  /// Whether bars should be stacked (default: false).
  final bool stacked;

  /// Whether to display bars horizontally (default: false).
  final bool horizontal;

  const BarChartSection({
    super.key,
    required this.series,
    this.xLabels,
    this.height = 200,
    this.stacked = false,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(child: AppText.body('No data available')),
      );
    }

    final chartSeries = series.map((s) {
      final label = s['label'] as String? ?? 'Series';
      final data =
          (s['data'] as List?)?.cast<num>().map((n) => n.toDouble()).toList() ??
              [];
      return AppChartSeries(
        label: label,
        data: data,
      );
    }).toList();

    return SizedBox(
      height: height,
      child: AppBarChart(
        series: chartSeries,
        xLabels: xLabels,
        stacked: stacked,
        horizontal: horizontal,
      ),
    );
  }
}
