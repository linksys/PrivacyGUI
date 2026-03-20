import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Visual signal strength indicator using 4 vertical bars.
///
/// Maps RSSI dBm to signal level (0-3) and renders colored bars.
/// Used in device list tiles and the device detail connection card.
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

  /// Signal level: 0 (poor) to 3 (excellent).
  int get _level {
    if (rssi >= -50) return 3;
    if (rssi >= -65) return 2;
    if (rssi >= -80) return 1;
    return 0;
  }

  Color _barColor(BuildContext context) {
    switch (_level) {
      case 3:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 1:
        return Colors.orange;
      default:
        return Theme.of(context).colorScheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _barColor(context);
    final inactiveColor =
        Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 4 bars with increasing height
        for (int i = 0; i < 4; i++) ...[
          Container(
            width: barWidth,
            height: maxBarHeight * (0.25 + 0.25 * i),
            decoration: BoxDecoration(
              color: i <= _level ? color : inactiveColor,
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
