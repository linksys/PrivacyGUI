import 'package:flutter/material.dart';

/// A device icon with an optional badge overlay in the bottom-right corner.
///
/// Used to indicate multi-interface devices (WiFi + Ethernet) in device lists.
class DeviceIconWithBadge extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? iconColor;
  final bool showBadge;
  final IconData badgeIcon;
  final Color? badgeColor;
  final Color? badgeBackgroundColor;

  const DeviceIconWithBadge({
    super.key,
    required this.icon,
    this.size = 20,
    this.iconColor,
    this.showBadge = false,
    this.badgeIcon = Icons.hub,
    this.badgeColor,
    this.badgeBackgroundColor,
  });

  /// Creates a device icon with multi-interface badge.
  factory DeviceIconWithBadge.multiInterface({
    Key? key,
    required IconData icon,
    double size = 20,
    Color? iconColor,
    required bool hasMultipleInterfaces,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveIconColor = iconColor ?? scheme.onSurface;
    final effectiveBadgeColor = badgeColor ?? scheme.primary;
    final effectiveBadgeBg = badgeBackgroundColor ?? scheme.surface;

    if (!showBadge) {
      return Icon(icon, size: size, color: effectiveIconColor);
    }

    final badgeSize = size * 0.5;

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
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: effectiveBadgeBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: effectiveBadgeBg,
                  width: 1.5,
                ),
              ),
              child: Icon(
                badgeIcon,
                size: badgeSize * 0.7,
                color: effectiveBadgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
