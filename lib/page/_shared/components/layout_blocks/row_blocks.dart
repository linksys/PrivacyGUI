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

  /// Drops the icon block, handing its width to the text column.
  ///
  /// `ListTileContentLayout` sizes the content column as whatever the leading
  /// and trailing slots do not take, so removing the block returns its 44px
  /// *plus* the 16px gap ui_kit adds per occupied slot — 60px, which is by far
  /// the largest lever this row has. Everything else in it is either ui_kit's
  /// own padding or content the row exists to show.
  ///
  /// The [icon] is still required, because a card that degrades must be able to
  /// come back: the caller passes the same row description at every density and
  /// only the selected form differs (#1289).
  final bool compact;

  const DeviceRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppListTile(
      backgroundColor: colorScheme.surfaceContainerHighest
          .withValues(alpha: BlockConstants.backgroundAlpha),
      leading: compact
          ? null
          : Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius:
                    BorderRadius.circular(BlockConstants.borderRadius),
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
///
/// **One paragraph, not two [Flexible]s (#1286).** This used to be a `Row` of
/// two equal-flex halves, which contradicted the sentence above: `RenderFlex`
/// splits free space evenly between equal flex factors and never hands back what
/// the shorter child declines, so the target was capped at **half the row**
/// however short the source was. Measured on the firewall Ports tab at 191px: the
/// pair gets 77.0px, the source `8080` uses 30.7px of its 38.5px allocation, the
/// remaining 7.8px went nowhere, and `192.168.1.105:27015` (103.7px) was
/// ellipsized against a 38.5px ceiling — reading it whole would have needed
/// 227.4px of mapping, wider than the entire card.
///
/// As a single [AppText.rich] run with `overflow: ellipsis`, the source takes its
/// intrinsic width by document order, the target gets everything left, and there
/// is one ellipsis at the end of the last line. That also keeps the docstring's
/// promise about which half gives: an ellipsis at the end of the run can only eat
/// the source once the *whole* row is narrower than the source itself, which no
/// shipping width is. A caller whose row has a line to spare can go further than
/// that and give up no glyphs at all — see [maxLines].
///
/// Spans, not markup: [source] and [target] are router-supplied, and
/// `AppStyledText`'s parser would interpret a paired tag inside a device name as
/// markup. [AppText.rich] takes spans the caller has already built, so nothing
/// device-supplied passes through a parser. The arrow rides along as a
/// [WidgetSpan] because it must come from the icon font (see above).
///
/// One consequence for callers and tests: the pair is **one** [Text], not two.
/// `find.text(source)` no longer matches it — the paragraph's plain text is
/// `source`, U+FFFC for the placeholder, then `target`.
class MapsToRow extends StatelessWidget {
  final String source;
  final String target;
  final Color? color;

  /// Lines the pair may take before the target ellipsizes. Defaults to 1, which
  /// is what a row shared with other widgets can afford.
  ///
  /// Raise it where the pair has a line to itself and the alternative is cutting
  /// the target. Both operands are machine-generated and unbounded above: a
  /// target is an IP with an optional port, so 21 characters
  /// (`192.168.100.100:65535`) is reachable, and the firewall card's Ports tab at
  /// its narrowest realization already spends 157.0px of a 157.4px row on the
  /// 19-character `27015 → 192.168.1.105:27015`.
  ///
  /// 2 is worth more than the extra room suggests, because of *where* the break
  /// lands. The arrow is a [WidgetSpan], i.e. U+FFFC, which UAX #14 treats as a
  /// contingent break — so the second line starts at the target rather than
  /// mid-token. Measured at 141.4px of room: `27015 →` on the first line and
  /// `192.168.1.105:27015` whole on the second, not `...192.168.1.1` / `05:27015`.
  /// That is what makes a tight one-line fit safe to ship — overshooting it costs
  /// a line, not a glyph — and it costs that line only on the rows that overshoot.
  final int maxLines;

  const MapsToRow({
    super.key,
    required this.source,
    required this.target,
    this.color,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return AppText.rich(
      [
        TextSpan(text: source),
        WidgetSpan(
          // The two `AppGap.xs()`s the `Row` used, moved inside the span so the
          // spacing survives the change and stays symmetric around the glyph.
          // `middle` is what keeps a 12px icon optically centred on bodySmall's
          // x-height; the default (bottom-of-baseline) sits it low.
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: AppIcon.font(Icons.arrow_forward, size: 12),
          ),
        ),
        TextSpan(text: target),
      ],
      variant: AppTextVariant.bodySmall,
      // No local colour resolution, and the arrow is deliberately left
      // colourless. The arrow must track the text, and text and icons read
      // different inherited widgets — [AppText] resolves against
      // [DefaultTextStyle], [AppIcon] against `IconTheme.of(context).color ??
      // Colors.black` — so the `Row` version had to resolve one colour here and
      // hand it to both, or the icon would pick up an ambient icon colour, or
      // black, next to text in the container's content colour. [AppText.rich]
      // closes that gap itself: it publishes its own resolved colour as an
      // `IconTheme` around the paragraph, so a `WidgetSpan`'d [AppIcon] agrees
      // with the run it punctuates by construction. Resolving it again here
      // would only re-derive the same chain, less completely — this widget
      // cannot see ui_kit's final `surfaceBase.contentColor` fallback.
      color: color,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
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

    final tile = AppListTile(
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
    );

    // A switched-off network is still listed and still operable, so it reads as
    // lower priority rather than dimmer by a number this file picked.
    return isEnabled ? tile : AppLowEmphasis(child: tile);
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
