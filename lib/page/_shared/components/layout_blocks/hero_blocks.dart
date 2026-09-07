import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'base_blocks.dart';
import 'block_constants.dart';

// =============================================================================
// HeroBlock - A card's opening row (identifying icon + the value it exists for)
// =============================================================================

/// The block a dashboard card opens with: an identifying icon beside the one
/// value the card exists to show, with any secondary lines under it.
///
/// Three cards hand-rolled this shape before #1288 — `usp_device_info_card.dart`,
/// `usp_lan_info_card.dart` and `usp_time_settings_card.dart` — down to the same
/// `AppGap.lg`, the same `EdgeInsets.all(AppSpacing.md)` and the same
/// `CrossAxisAlignment.start` column. It came out the same three times because
/// the constraint is the same: the icon says which card this is at a glance, and
/// the column beside it carries everything the card actually reports.
///
/// ## Why the icon leaves the row in [compact]
///
/// The icon's width is fixed and the value's is not, so at narrow widths the icon
/// is charged to the value. Measured on this branch (#1288, worst locale, at the
/// gate's own realizations): at the 191.4px realization the icon and its gap take
/// 112–136px of a 157.4px block, leaving the value **21.4px** on `device_info` and
/// 61.4px on the other two — `MR7500` renders one glyph per line, and 122px of the
/// hero falls below the card's content viewport.
///
/// At 200px, the bottom of the compact band, the block has 142.0px for its row.
/// The three values need 91.6 / 119.2 / 124.6px, which leaves 50.4 / 22.8 / 17.4px
/// for icon plus gap — so no icon small enough to help exists: even 32px plus an
/// 8px gap fails two of the three. Taking the icon out of the row is the only
/// arrangement that clears all three, and it also removes the hero's vertical
/// floor (`device_info`'s hero is 120.0px tall against a 122.0px viewport purely
/// because of its 96px icon container).
///
/// The icon is not dropped from the card — the three cards move it to the
/// template's header `leading` slot for exactly the widths where this block hides
/// it, so the popup form has the icon §2.1 promises it and the header keeps the
/// card identifiable. Above the threshold nothing changes.
class HeroBlock extends StatelessWidget {
  const HeroBlock({
    super.key,
    required this.leading,
    required this.children,
    this.compact = false,
  });

  /// The card's identifying icon — a sized container, not a bare glyph, since
  /// each card draws its own (a circle, a rounded plate, a device image).
  ///
  /// Built by the caller even when [compact] hides it: it is `const`-cheap in all
  /// three cards, and a builder callback would buy nothing but indirection.
  final Widget leading;

  /// The value column: the hero value first, then any secondary lines.
  ///
  /// A list rather than named value/subtitle slots because the three cards differ
  /// exactly here — two lines, a line plus a status row, a line plus a badge —
  /// and inventing a slot per variant is how the shape got hand-rolled three
  /// times.
  final List<Widget> children;

  /// Whether to render the narrow form: no icon, the column full width.
  ///
  /// Passed in rather than read from `CardDensityScope` so this block stays usable
  /// outside a dashboard card, which is true of every block in this directory —
  /// the density read belongs to the card, which needs it for its header anyway.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );

    return LayoutBlock(
      padding: BlockConstants.paddingMd,
      child: compact
          ? column
          : Row(
              children: [
                leading,
                AppGap.lg(),
                Expanded(child: column),
              ],
            ),
    );
  }
}

/// The [HeroBlock.leading] two of the three cards draw: one glyph centred in a
/// `primaryContainer` circle.
///
/// `usp_lan_info_card` and `usp_time_settings_card` had this byte-identical apart
/// from the glyph, which is the shape of duplication that survives a review
/// precisely because each copy is short. `usp_device_info_card` is deliberately
/// not a caller — it draws a padded rounded plate around a router *image*, and
/// bending this to cover that would produce a widget with a shape flag.
///
/// The two sizes stay hardcoded rather than moving to [BlockConstants]: they are
/// not part of that file's icon scale (16/20/24/48) but a measured pair. 56px is
/// what the hero row was tuned around — the #1288 note above quotes the 61.4px
/// left for the value column at the gate's narrowest realization, which is that
/// 56 plus `AppGap.lg`. Changing either number moves the overflow baseline.
class HeroCircleIcon extends StatelessWidget {
  const HeroCircleIcon({
    super.key,
    required this.icon,
    this.diameter = 56,
    this.iconSize = 28,
  });

  final IconData icon;
  final double diameter;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: AppIcon.font(
        icon,
        color: colorScheme.primary,
        size: iconSize,
      ),
    );
  }
}
