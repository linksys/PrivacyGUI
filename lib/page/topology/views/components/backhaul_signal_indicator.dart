import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/wifi_ui.dart';
import 'package:privacy_gui/page/devices/views/components/usp_signal_strength_indicator.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Backhaul signal strength indicator with visual bar design.
///
/// Matches the Device Detail "Signal & Speed" card style with a themed
/// background container containing signal bars, dBm value, and quality label.
/// Fully theme-aware - adapts to both light and dark themes.
class BackhaulSignalIndicator extends StatelessWidget {
  final int rssi;

  const BackhaulSignalIndicator({super.key, required this.rssi});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final level = getWifiSignalLevel(rssi);
    final color = level.resolveColor(context) ?? colorScheme.onSurfaceVariant;
    final label = level.resolveLabel(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        children: [
          UspSignalStrengthIndicator(
            rssi: rssi,
            maxBarHeight: 24,
            barWidth: 6,
            barSpacing: 3,
            showLabel: false,
          ),
          AppGap.lg(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleMedium(
                    loc(context).signalStrengthDbm(rssi.toString())),
                AppText.labelSmall(label, color: color),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
