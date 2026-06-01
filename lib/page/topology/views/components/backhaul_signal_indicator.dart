import 'package:flutter/material.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/page/_shared/components/wifi_ui.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Backhaul signal strength indicator with horizontal bar and quality label.
///
/// Shows: [####----] -45 dBm
///        Good
class BackhaulSignalIndicator extends StatelessWidget {
  final int rssi;

  const BackhaulSignalIndicator({super.key, required this.rssi});

  @override
  Widget build(BuildContext context) {
    final level = getWifiSignalLevel(rssi);
    final color = level.resolveColor(context) ?? Colors.grey;
    final label = level.resolveLabel(context);
    // Normalize RSSI (-100 to -30 dBm) to 0.0-1.0
    final norm = ((rssi + 100) / 70).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _ColoredLinearBar(value: norm, color: color),
            ),
            AppGap.sm(),
            AppText.bodyMedium('$rssi dBm'),
          ],
        ),
        AppGap.xs(),
        AppText.labelSmall(label, color: color),
      ],
    );
  }
}

class _ColoredLinearBar extends StatelessWidget {
  final double value;
  final Color color;

  const _ColoredLinearBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
