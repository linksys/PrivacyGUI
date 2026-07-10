import 'package:flutter/material.dart';
import 'package:privacy_gui/core/utils/oui_lookup.dart';

/// A device icon with optional badge overlays.
///
/// Supports two badge positions:
/// - Bottom-right: multi-interface indicator (WiFi + Ethernet)
/// - Bottom-left: private MAC indicator (randomized address)
class DeviceIconWithBadge extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? iconColor;
  final bool showBadge;
  final IconData badgeIcon;
  final Color? badgeColor;
  final Color? badgeBackgroundColor;
  final bool showPrivateMacBadge;

  const DeviceIconWithBadge({
    super.key,
    required this.icon,
    this.size = 20,
    this.iconColor,
    this.showBadge = false,
    this.badgeIcon = Icons.hub,
    this.badgeColor,
    this.badgeBackgroundColor,
    this.showPrivateMacBadge = false,
  });

  /// Creates a device icon with multi-interface and/or private MAC badges.
  factory DeviceIconWithBadge.multiInterface({
    Key? key,
    required IconData icon,
    double size = 20,
    Color? iconColor,
    required bool hasMultipleInterfaces,
    bool isPrivateMac = false,
    Color? badgeColor,
    Color? badgeBackgroundColor,
  }) {
    return DeviceIconWithBadge(
      key: key,
      icon: icon,
      size: size,
      iconColor: iconColor,
      showBadge: hasMultipleInterfaces,
      badgeIcon: Icons.hub,
      badgeColor: badgeColor,
      badgeBackgroundColor: badgeBackgroundColor,
      showPrivateMacBadge: isPrivateMac,
    );
  }

  /// Creates a device icon from MAC address, auto-detecting private MAC.
  factory DeviceIconWithBadge.fromMac({
    Key? key,
    required IconData icon,
    required String mac,
    double size = 20,
    Color? iconColor,
    bool hasMultipleInterfaces = false,
    Color? badgeColor,
    Color? badgeBackgroundColor,
  }) {
    return DeviceIconWithBadge(
      key: key,
      icon: icon,
      size: size,
      iconColor: iconColor,
      showBadge: hasMultipleInterfaces,
      badgeIcon: Icons.hub,
      badgeColor: badgeColor,
      badgeBackgroundColor: badgeBackgroundColor,
      showPrivateMacBadge: OuiLookup.isRandomizedMac(mac),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveIconColor = iconColor ?? scheme.onSurface;
    final effectiveBadgeColor = badgeColor ?? scheme.primary;
    final effectiveBadgeBg = badgeBackgroundColor ?? scheme.surface;

    if (!showBadge && !showPrivateMacBadge) {
      return Icon(icon, size: size, color: effectiveIconColor);
    }

    final badgeSize = size * 0.6;

    return SizedBox(
      width: size + badgeSize * 0.4,
      height: size + badgeSize * 0.4,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Icon(icon, size: size, color: effectiveIconColor),
          ),
          // Multi-interface badge (bottom-right)
          if (showBadge)
            Positioned(
              right: 0,
              bottom: 0,
              child: _BadgeCircle(
                size: badgeSize,
                icon: badgeIcon,
                iconColor: effectiveBadgeColor,
                backgroundColor: effectiveBadgeBg,
              ),
            ),
          // Private MAC badge (bottom-left)
          if (showPrivateMacBadge)
            Positioned(
              left: 0,
              bottom: 0,
              child: _BadgeCircle(
                size: badgeSize,
                icon: Icons.shuffle,
                iconColor: scheme.tertiary,
                backgroundColor: effectiveBadgeBg,
              ),
            ),
        ],
      ),
    );
  }
}

class _BadgeCircle extends StatelessWidget {
  final double size;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  const _BadgeCircle({
    required this.size,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: backgroundColor,
          width: 1.5,
        ),
      ),
      child: Icon(
        icon,
        size: size * 0.7,
        color: iconColor,
      ),
    );
  }
}
