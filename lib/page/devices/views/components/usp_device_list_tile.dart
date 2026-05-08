import 'package:flutter/material.dart';
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
///   [•] [type-icon]  Name                            IP      >
///                    band · SSID · via Node    ▇▇▇ -38 dBm
///
/// Design notes:
/// - The type icon only encodes connection type (WiFi vs. Ethernet). Signal
///   strength lives exclusively in the right-hand bars+dBm cluster to avoid
///   the duplication we had when the icon also varied with RSSI.
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

    final content = Row(
      children: [
        UspStatusDot(isActive: device.isActive),
        AppGap.sm(),
        _ConnectionTypeIcon(isWifi: device.isWifi),
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
              if (subtitle.isNotEmpty || hasSignal) ...[
                AppGap.xs(),
                // Secondary row: subtitle ↔ signal
                Row(
                  children: [
                    Expanded(
                      child: AppText.bodySmall(
                        subtitle,
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
            ],
          ),
        ),
        AppGap.sm(),
        AppIcon.font(
          Icons.chevron_right,
          size: 18,
          color: scheme.onSurfaceVariant,
        ),
      ],
    );

    final Widget tile;
    if (variant == DeviceListTileVariant.card) {
      tile = AppCard(onTap: onTap, child: content);
    } else {
      final flatContent = InkWell(
        onTap: onTap,
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

class _ConnectionTypeIcon extends StatelessWidget {
  const _ConnectionTypeIcon({required this.isWifi});

  final bool isWifi;

  @override
  Widget build(BuildContext context) {
    return Icon(
      isWifi ? Icons.wifi : Icons.settings_ethernet,
      size: 18,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }
}
