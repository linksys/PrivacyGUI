import 'package:flutter/material.dart';
import 'package:privacy_gui/core/utils/device_classifier.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/components/usp_status_dot.dart';
import 'package:privacy_gui/page/devices/views/components/usp_signal_strength_indicator.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Visual variant for [UspDeviceListTile].
enum DeviceListTileVariant {
  /// Wrapped in AppCard with border (default, for standalone lists).
  card,

  /// Flat with bottom divider (for embedded lists inside a card).
  flat,

  /// Flat without divider (for last item in embedded lists).
  flatLast,
}

/// A tappable tile showing device summary info for the device list.
///
/// Layout (Direction A — two-row hierarchy):
///   [•] [device-icon]  Name                            IP      >
///                      band · SSID · via Node    ▇▇▇ -38 dBm
///
/// Design notes:
/// - The device icon is derived from [DeviceClassifier] based on hostname and
///   MAC OUI to show the device type (phone, computer, TV, etc.).
/// - MAC is intentionally omitted — it belongs on the detail page.
/// - Offline devices dim the entire tile via Opacity so "offline" reads as a
///   single visual cue instead of threading through colors.
/// - Set [variant] to [DeviceListTileVariant.flat] for embedded lists (e.g.
///   inside a card) to avoid double card borders.
class UspDeviceListTile extends StatelessWidget {
  final DeviceUIModel device;
  final VoidCallback? onTap;
  final DeviceListTileVariant variant;

  const UspDeviceListTile({
    super.key,
    required this.device,
    this.onTap,
    this.variant = DeviceListTileVariant.card,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = _buildSubtitle();
    final hasSignal =
        device.isActive && device.isWifi && device.signalStrength != null;

    final deviceCategory = DeviceClassifier.classify(
      hostname: device.hostName,
      mac: device.mac,
    );

    // Offline devices are not tappable
    final effectiveOnTap = device.isActive ? onTap : null;

    final content = Row(
      children: [
        UspStatusDot(isActive: device.isActive),
        AppGap.sm(),
        Icon(
          deviceCategory.icon,
          size: 20,
          color: scheme.onSurface,
        ),
        AppGap.sm(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Primary row: name ↔ IP
              Row(
                children: [
                  Expanded(
                    child: AppText.bodyMedium(
                      device.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppGap.sm(),
                  AppText.bodySmall(
                    device.ip,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
              AppGap.xs(),
              // Secondary row: subtitle ↔ signal (always render for consistent height)
              Row(
                children: [
                  Expanded(
                    child: AppText.bodySmall(
                      subtitle.isNotEmpty ? subtitle : ' ',
                      color: scheme.onSurfaceVariant,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasSignal) ...[
                    AppGap.sm(),
                    UspSignalStrengthIndicator(
                      rssi: device.signalStrength!,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        // Only show chevron for online (tappable) devices
        if (device.isActive) ...[
          AppGap.sm(),
          AppIcon.font(
            Icons.chevron_right,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ],
    );

    final Widget tile;
    if (variant == DeviceListTileVariant.card) {
      tile = AppCard(onTap: effectiveOnTap, child: content);
    } else {
      final flatContent = InkWell(
        onTap: effectiveOnTap,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: content,
        ),
      );
      tile = variant == DeviceListTileVariant.flatLast
          ? flatContent
          : Column(
              children: [
                flatContent,
                Divider(height: 1, color: scheme.outlineVariant),
              ],
            );
    }

    return device.isActive ? tile : Opacity(opacity: 0.5, child: tile);
  }

  String _buildSubtitle() {
    final parts = <String>[];
    if (device.isWifi) {
      final bandSsid = [
        if (device.band != null && device.band!.isNotEmpty) device.band!,
        if (device.ssidName != null && device.ssidName!.isNotEmpty)
          device.ssidName!,
      ].join(' · ');
      if (bandSsid.isNotEmpty) parts.add(bandSsid);
    } else {
      parts.add('Ethernet');
    }
    if (device.parentNodeName != null) {
      parts.add('via ${device.parentNodeName}');
    }
    return parts.join(' · ');
  }
}
