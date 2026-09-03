import 'package:flutter/material.dart';
import 'package:privacy_gui/core/utils/oui_lookup.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/utils/device_classifier.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/components/usp_status_dot.dart';
import 'package:privacy_gui/page/devices/views/components/device_icon_with_badge.dart';
import 'package:privacy_gui/page/devices/views/components/usp_signal_strength_indicator.dart';
import 'package:privacy_gui/page/topology/helpers/node_identifier.dart';
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
  final ClientDevice device;
  final VoidCallback? onTap;
  final DeviceListTileVariant variant;

  const UspDeviceListTile({
    super.key,
    required this.device,
    this.onTap,
    this.variant = DeviceListTileVariant.card,
  });

  /// Stable, data-derived E2E `identifier` key for this row's arrival anchor
  /// (`device-row-<key>`), consumed by the E2E suite via `byIdentifier()`
  /// against the CanvasKit Semantics tree.
  ///
  /// Derived from the device's MAC via [normalizeMac] (`aa:bb:cc:…` →
  /// `AABBCC…`), so it is stable across list reordering and independent of the
  /// human-visible hostname. The FULL normalized MAC is used (not a
  /// shortest-unique suffix) because this tile is a standalone per-device
  /// widget with no knowledge of its sibling rows: the full MAC is globally
  /// unique on its own and needs no cross-row context. Mirrors the per-instance
  /// getter precedent in `DhcpReservationUIModel.identifierKey`.
  String get identifierKey => normalizeMac(device.mac);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = _buildSubtitle(context);

    final deviceCategory = DeviceClassifier.classify(
      hostname: device.hostName,
      mac: device.mac,
    );

    final effectiveOnTap = device.isInteractive ? onTap : null;

    final content = Row(
      children: [
        UspStatusDot(isActive: device.isActive),
        AppGap.sm(),
        DeviceIconWithBadge.multiInterface(
          icon: deviceCategory.icon,
          size: 20,
          iconColor: scheme.onSurface,
          hasMultipleInterfaces: device.hasMultipleInterfaces,
          isPrivateMac: OuiLookup.isRandomizedMac(device.mac),
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
                  if (device.hasSignalDisplay) ...[
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
        // Only show chevron for interactive (online) devices
        if (device.isInteractive) ...[
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

    // Per-row E2E arrival anchor (`device-row-<normalized-mac>`). Outermost so
    // the identifier node wraps the whole row (incl. its tap sensor), giving the
    // E2E suite a stable, MAC-derived handle to open each device's detail page.
    // The `${...}` braces are REQUIRED by the E2E generator's DYNAMIC_RE
    // (`prefix-${expr}$`): a bare `$identifierKey` at an inline `identifier:`
    // site is not matched and the hook is silently dropped, so the analyzer's
    // unnecessary-brace lint is suppressed here rather than removing the braces.
    return Semantics(
      // ignore: unnecessary_brace_in_string_interps
      identifier: 'device-row-${identifierKey}',
      container: true,
      child: Opacity(opacity: device.displayOpacity, child: tile),
    );
  }

  String _buildSubtitle(BuildContext context) {
    final parts = <String>[];

    // Connection type - for multi-interface show both types
    if (device.hasMultipleInterfaces) {
      final hasWifi =
          device.isWifi || device.additionalInterfaces.any((i) => i.isWifi);
      final hasEthernet =
          !device.isWifi || device.additionalInterfaces.any((i) => !i.isWifi);
      if (hasWifi && hasEthernet) {
        parts.add(loc(context).wifiPlusEthernet);
      } else if (hasWifi) {
        parts.add(loc(context).wifi);
      } else {
        parts.add(loc(context).ethernet);
      }
    } else if (device.isWifi) {
      final bandSsid = [
        if (device.band != null && device.band!.isNotEmpty) device.band!,
        if (device.ssidName != null && device.ssidName!.isNotEmpty)
          device.ssidName!,
      ].join(' · ');
      // Show "WiFi" fallback when no band/SSID data available.
      parts.add(bandSsid.isNotEmpty ? bandSsid : loc(context).wifi);
    } else {
      parts.add(loc(context).ethernet);
    }
    // An unattributed device (no resolvable parent node — issue #1439) is
    // marked explicitly instead of being drawn as if it were on a node. The
    // marker is driven by the isUnattributed flag, not by an empty node name.
    if (device.isUnattributed) {
      parts.add(loc(context).unattributedDevice);
    } else if (device.parentNodeName != null) {
      parts.add(loc(context).viaNode(device.parentNodeName!));
    }
    return parts.join(' · ');
  }
}
