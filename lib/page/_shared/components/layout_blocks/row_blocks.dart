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

// =============================================================================
// MapsToRow - "source maps to target" pair
// =============================================================================

/// A "maps to" pair — `8080 -> 192.168.1.100:80` — drawn with an arrow icon
/// instead of a U+2192 character.
///
/// U+2192 has no glyph in the primary font, in any of the nine fallbacks under
/// `assets/fonts/fallback/`, or in the union of all eleven; the app's declared
/// font set cannot render it, and browsers only do so by resolving a host font
/// outside that set — the exact dependency those fallbacks exist to remove.
/// [AppIcon.font] draws from the icon font, so coverage is guaranteed offline.
///
/// [source] and [target] stay Strings: the arrow is composed here in the widget
/// layer, so UI models keep returning Strings rather than widgets.
///
/// Sized to match the surrounding [AppText.bodySmall]. [target] is the part
/// that ellipsizes, since the source (a port or port range) is short and
/// bounded while the target (an IP, optionally with a port) is not.
class MapsToRow extends StatelessWidget {
  final String source;
  final String target;
  final Color? color;

  const MapsToRow({
    super.key,
    required this.source,
    required this.target,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // The arrow must track the text, and text and icons resolve colour from
    // different inherited widgets: [AppText] reads [DefaultTextStyle] while
    // [AppIcon] falls back to `IconTheme.of(context).color ?? Colors.black`.
    // Containers commonly set only one of the two — `AppListTile` wraps its
    // subtitle in a `DefaultTextStyle` and no `IconTheme` — so leaving the icon
    // to its own chain lets it pick up an ambient icon colour, or black, while
    // the text beside it renders in the container's content colour. Resolving
    // one colour here and passing it to both keeps the pair consistent.
    final effectiveColor = color ?? DefaultTextStyle.of(context).style.color;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: AppText.bodySmall(
            source,
            color: effectiveColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppGap.xs(),
        AppIcon.font(Icons.arrow_forward, size: 12, color: effectiveColor),
        AppGap.xs(),
        Flexible(
          child: AppText.bodySmall(
            target,
            color: effectiveColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// ToggleRow - Row with leading switch toggle
// =============================================================================

/// Toggle row block with leading switch, title, subtitle, and optional trailing.
///
/// Uses [AppListTile] from UI Kit for consistent styling.
/// Use for DHCP reservations, port forwarding rules, etc.
///
/// When [isLoading] is true, displays a spinner in place of the switch.
class ToggleRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String title;
  final String? subtitle;

  /// Widget subtitle, for rows whose subtitle is not plain text (e.g. a
  /// [MapsToRow] with an arrow icon). Mutually exclusive with [subtitle] —
  /// passing both is asserted against, and in release builds this one wins.
  final Widget? subtitleContent;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isLoading;

  const ToggleRow({
    super.key,
    required this.value,
    this.onChanged,
    required this.title,
    this.subtitle,
    this.subtitleContent,
    this.trailing,
    this.onTap,
    this.isLoading = false,
  }) : assert(subtitle == null || subtitleContent == null,
            'ToggleRow: pass subtitle or subtitleContent, not both');

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppListTile(
      backgroundColor: colorScheme.surfaceContainerHighest
          .withValues(alpha: BlockConstants.backgroundAlpha),
      leading: SizedBox(
        width: 44,
        child: Center(
          child: isLoading
              ? SizedBox.square(
                  dimension: 26,
                  child: AppLoader(strokeWidth: 2),
                )
              : AppSwitch(
                  value: value,
                  onChanged: onChanged,
                  scale: 0.8,
                ),
        ),
      ),
      title: AppText.bodyMedium(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitleContent ??
          (subtitle != null
              ? AppText.bodySmall(
                  subtitle!,
                  color: colorScheme.onSurfaceVariant,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

// =============================================================================
// NetworkRow - WiFi network row with badges and switch
// =============================================================================

/// Network row block for WiFi networks with band badges, client count, and toggle.
///
/// Uses [AppListTile] from UI Kit for consistent styling.
///
/// When [isLoading] is true, displays a spinner in place of the switch.
class NetworkRow extends StatelessWidget {
  final String ssidName;
  final List<String> bands;
  final bool isGuest;
  final bool isEnabled;
  final int clientCount;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onShareTap;
  final bool isLoading;

  const NetworkRow({
    super.key,
    required this.ssidName,
    required this.bands,
    this.isGuest = false,
    required this.isEnabled,
    required this.clientCount,
    this.onChanged,
    this.onShareTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: isEnabled ? 1.0 : BlockConstants.disabledAlpha,
      child: AppListTile(
        backgroundColor: colorScheme.surfaceContainerHighest
            .withValues(alpha: BlockConstants.backgroundAlpha),
        title: Row(
          children: [
            Flexible(
              child: AppText.bodyLarge(
                ssidName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isGuest) ...[
              AppGap.sm(),
              _GuestBadge(),
            ],
          ],
        ),
        subtitle: Row(
          children: [
            ...bands.map((band) => Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: NetworkBadgeWidget(badge: NetworkBadge.fromBand(band)),
                )),
            AppGap.sm(),
            Icon(
              Icons.devices,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            AppGap.xxs(),
            AppText.labelSmall(
              '$clientCount',
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isLoading && isEnabled && onShareTap != null) ...[
              _ShareButton(onTap: onShareTap!),
              AppGap.sm(),
            ],
            isLoading
                ? SizedBox(
                    width: 52,
                    height: 32,
                    child: Center(
                      child: SizedBox.square(
                        dimension: 24,
                        child: AppLoader(strokeWidth: 2),
                      ),
                    ),
                  )
                : AppSwitch(
                    value: isEnabled,
                    onChanged: onChanged,
                  ),
          ],
        ),
      ),
    );
  }
}

class _GuestBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: 'Guest',
      color: Theme.of(context).colorScheme.secondary,
    );
  }
}

class _ShareButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ShareButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: AppIcon.font(Icons.qr_code_2, size: 24),
      onTap: onTap,
    );
  }
}

// =============================================================================
// ProtocolBadge - Protocol indicator badge (TCP/UDP/Both)
// =============================================================================

/// Protocol badge for port forwarding/triggering rules.
class ProtocolBadge extends StatelessWidget {
  final String protocol;

  const ProtocolBadge({super.key, required this.protocol});

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: protocol,
      color: Theme.of(context).colorScheme.primary,
    );
  }
}
