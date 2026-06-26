import 'package:flutter/material.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/page/_shared/components/wifi_ui.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Visual signal strength indicator using 4 vertical bars.
///
/// Uses [getWifiSignalLevel] + [NodeSignalLevelExt.resolveColor] so thresholds
/// and colors match the node/topology surfaces and respect `AppColorScheme`
/// in both light and dark themes.
class UspSignalStrengthIndicator extends StatelessWidget {
  final int rssi;
  final double barWidth;
  final double barSpacing;
  final double maxBarHeight;
  final bool showLabel;

  const UspSignalStrengthIndicator({
    super.key,
    required this.rssi,
    this.barWidth = 4,
    this.barSpacing = 2,
    this.maxBarHeight = 16,
    this.showLabel = true,
  });

  /// Render level: 0 (poor) to 3 (excellent). Maps the project-wide
  /// [NodeSignalLevel] onto the four bars.
  int get _level {
    switch (getWifiSignalLevel(rssi)) {
      case NodeSignalLevel.excellent:
        return 3;
      case NodeSignalLevel.good:
        return 2;
      case NodeSignalLevel.fair:
        return 1;
      case NodeSignalLevel.poor:
      case NodeSignalLevel.none:
      case NodeSignalLevel.wired:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = getWifiSignalLevel(rssi);
    final color =
        level.resolveColor(context) ?? Theme.of(context).colorScheme.onSurface;
    final inactiveColor =
        Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4);
    final activeLevel = _level;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (int i = 0; i < 4; i++) ...[
          Container(
            width: barWidth,
            height: maxBarHeight * (0.25 + 0.25 * i),
            decoration: BoxDecoration(
              color: i <= activeLevel ? color : inactiveColor,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          if (i < 3) SizedBox(width: barSpacing),
        ],
        if (showLabel) ...[
          AppGap.xs(),
          AppText.labelSmall(
            '$rssi dBm',
            color: color,
          ),
        ],
      ],
    );
  }
}
