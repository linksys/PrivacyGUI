import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Line chart section for displaying time-series or continuous data.
///
/// Supports single or multiple series with configurable appearance.
class LineChartSection extends StatelessWidget {
  /// Data series to display.
  /// Each series is a map with 'label' (String) and 'data' (List<double>).
  final List<Map<String, dynamic>> series;

  /// Chart height in pixels (default: 200).
  final double height;

  /// Whether to show grid lines (default: true).
  final bool showGrid;

  /// Whether to show dots on data points (default: true).
  final bool showDots;

  /// Whether to fill the area under the line (default: false).
  final bool filled;

  /// Y-axis minimum value (optional).
  final double? yMin;

  /// Y-axis maximum value (optional).
  final double? yMax;

  /// Y-axis label formatter suffix (e.g., '%', 'Mbps').
  final String? yUnit;

  const LineChartSection({
    super.key,
    required this.series,
    this.height = 200,
    this.showGrid = true,
    this.showDots = true,
    this.filled = false,
    this.yMin,
    this.yMax,
    this.yUnit,
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
      final isFilled = s['filled'] as bool? ?? filled;
      return AppChartSeries(
        label: label,
        data: data,
        filled: isFilled,
      );
    }).toList();

    // Calculate Y-axis range if not provided
    final allData = chartSeries.expand((s) => s.data).toList();
    final minVal =
        yMin ?? (allData.isEmpty ? 0 : allData.reduce((a, b) => a < b ? a : b));
    final maxVal = yMax ??
        (allData.isEmpty ? 100 : allData.reduce((a, b) => a > b ? a : b));

    return SizedBox(
      height: height,
      child: AppLineChart(
        series: chartSeries,
        yAxis: AppChartAxis(
          min: minVal,
          max: maxVal,
          interval: (maxVal - minVal) / 4,
        ),
        yLabelFormatter: yUnit != null ? (v) => '${v.toInt()}$yUnit' : null,
        showDots: showDots,
        showGrid: showGrid,
      ),
    );
  }
}
