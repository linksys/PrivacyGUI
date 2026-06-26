import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'block_constants.dart';

// =============================================================================
// DeviceRow - Device list item block
// =============================================================================

/// Device row block with icon, title, subtitle, and optional trailing widget.
///
/// Uses [AppListTile] from UI Kit with custom icon container styling.
/// Use in device lists, connected devices sections, etc.
class DeviceRow extends StatelessWidget {
  final Widget icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const DeviceRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppListTile(
      backgroundColor: colorScheme.surfaceContainerHighest
          .withValues(alpha: BlockConstants.backgroundAlpha),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(BlockConstants.borderRadius),
        ),
        child: Center(child: icon),
      ),
      title: AppText.bodyLarge(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle != null
          ? AppText.bodySmall(
              subtitle!,
              color: colorScheme.onSurfaceVariant,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

// =============================================================================
// NetworkBadge - Band/feature badge for WiFi networks
// =============================================================================

/// Badge data for WiFi network rows.
class NetworkBadge {
  final String label;
  final Color? color;
  final IconData? icon;

  const NetworkBadge({
    required this.label,
    this.color,
    this.icon,
  });

  const NetworkBadge.band2g()
      : label = '2.4G',
        color = const Color(0xFF4A9EFF),
        icon = null;

  const NetworkBadge.band5g()
      : label = '5G',
        color = const Color(0xFF4ADE80),
        icon = null;

  const NetworkBadge.band6g()
      : label = '6G',
        color = const Color(0xFFA78BFA),
        icon = null;

  const NetworkBadge.guest()
      : label = 'Guest',
        color = null,
        icon = null;

  /// Create badge from band string (e.g., "2.4GHz", "5GHz", "6GHz").
  static NetworkBadge fromBand(String band) {
    final b = band.toLowerCase();
    if (b.contains('2.4')) return const NetworkBadge.band2g();
    if (b.contains('6')) return const NetworkBadge.band6g();
    if (b.contains('5')) return const NetworkBadge.band5g();
    return NetworkBadge(label: band);
  }
}

/// Visual widget for [NetworkBadge].
///
/// Uses [AppBadge] from UI Kit for consistent badge styling.
class NetworkBadgeWidget extends StatelessWidget {
  final NetworkBadge badge;

  const NetworkBadgeWidget({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: badge.label,
      color: badge.color,
      icon: badge.icon != null ? Icon(badge.icon, size: 12) : null,
    );
  }
}
