import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'base_blocks.dart';
import 'block_constants.dart';

// =============================================================================
// InfoList - Vertical key-value list
// =============================================================================

/// Vertical list of key-value pairs with optional copy support.
///
/// Use for displaying device info, server settings, etc.
class InfoList extends StatelessWidget {
  final List<InfoListItem> items;

  const InfoList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBlock(
      padding: EdgeInsets.zero,
      child: Column(
        children: items.asMap().entries.map((entry) {
          final isLast = entry.key == items.length - 1;
          final item = entry.value;
          return Container(
            padding: BlockConstants.paddingListItem,
            decoration: isLast
                ? null
                : BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: colorScheme.surfaceContainer),
                    ),
                  ),
            child: Row(
              children: [
                if (item.leading != null) ...[
                  item.leading!,
                  AppGap.sm(),
                ],
                SizedBox(
                  width: 120,
                  child: AppText.labelMedium(
                    item.label,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: item.copyable
                      ? _CopyableText(text: item.value)
                      : AppText.bodyMedium(item.value),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Item for [InfoList].
class InfoListItem {
  final String label;
  final String value;
  final bool copyable;
  final Widget? leading;

  const InfoListItem({
    required this.label,
    required this.value,
    this.copyable = false,
    this.leading,
  });
}

// =============================================================================
// InfoGrid - 2-column key-value grid
// =============================================================================

/// Grid layout for key-value pairs.
///
/// Supports full-width items and copyable values.
///
/// `crossAxisCount: 1` + [axis] `horizontal` + [compact] is the narrow form: a
/// column of full-width label-left/value-right rows, which is what a dashboard
/// card falls back to when it is too narrow to read tiles side by side. Three
/// cards hand-rolled that shape before #1275.
class InfoGrid extends StatelessWidget {
  final List<InfoGridItem> items;
  final int crossAxisCount;

  /// Axis each tile lays its label and value on.
  ///
  /// [Axis.vertical] is the designed grid — label above value, the label owning
  /// the tile's full width. [Axis.horizontal] puts them on one line, label left
  /// and value right, which reads at widths where the vertical tile would give a
  /// localized label a couple of characters per line (measured: 23.1px per label
  /// three-across in `usp_firewall_overview_card.dart`, where `ru` then wants 8
  /// lines).
  final Axis axis;

  /// Tightens every tile from [BlockConstants.paddingMd] to `paddingSm`.
  ///
  /// Opt-in per call site and deliberately not implied by [axis]: the 4px per
  /// side it buys back is load-bearing where the narrow arrangement has to fit a
  /// measured viewport (`firewall_overview`: a 112-130px stack in 205px;
  /// `ethernet_ports`: 120px in 121px) and unnecessary where the card has
  /// vertical budget to spare (`connected_devices`: 96px in 261px), which would
  /// pay for a cramped tile and get nothing back (#1275).
  final bool compact;

  /// Caps each tile's label, which is otherwise unbounded, and ellipsizes it.
  ///
  /// Per call site for the same reason. The value is what the metric *is*, so
  /// the label is what yields — but how far it may yield is a per-card
  /// measurement, not a property of the grid:
  /// `usp_firewall_overview_card.dart` allows two lines because at one line six
  /// locales clip mid-glyph, and at three the row grows past its tab viewport.
  final int? labelMaxLines;

  const InfoGrid({
    super.key,
    required this.items,
    this.crossAxisCount = 2,
    this.axis = Axis.vertical,
    this.compact = false,
    this.labelMaxLines,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <List<InfoGridItem>>[];
    var currentRow = <InfoGridItem>[];

    for (final item in items) {
      if (item.fullWidth) {
        if (currentRow.isNotEmpty) {
          rows.add(currentRow);
          currentRow = [];
        }
        rows.add([item]);
      } else {
        currentRow.add(item);
        if (currentRow.length == crossAxisCount) {
          rows.add(currentRow);
          currentRow = [];
        }
      }
    }
    if (currentRow.isNotEmpty) {
      rows.add(currentRow);
    }

    return Column(
      children: rows.asMap().entries.map((entry) {
        final isLast = entry.key == rows.length - 1;
        final row = entry.value;

        if (row.length == 1 && row.first.fullWidth) {
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
            child: _tileFor(row.first),
          );
        }

        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < row.length; i++) ...[
                  Expanded(child: _tileFor(row[i])),
                  if (i < row.length - 1) AppGap.sm(),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// The grid's three arrangement settings travel to every tile together, so
  /// they are threaded in one place rather than at each of the two call sites
  /// above.
  Widget _tileFor(InfoGridItem item) => _InfoGridTile(
        item: item,
        axis: axis,
        compact: compact,
        labelMaxLines: labelMaxLines,
      );
}

/// Item for [InfoGrid].
class InfoGridItem {
  final String label;
  final String value;
  final bool fullWidth;
  final bool copyable;

  /// Optional widget rendered next to the label (e.g. an [Ipv6ScopeBadge]).
  final Widget? labelTrailing;

  const InfoGridItem({
    required this.label,
    required this.value,
    this.fullWidth = false,
    this.copyable = false,
    this.labelTrailing,
  });
}

/// Icon-only marker for an IPv6 link-local (`fe80::/10`) address.
///
/// Link-local addresses are only valid on a single link and are not routable.
/// Wherever an IPv6 address is surfaced (dashboard cards and the device/node
/// detail views), a link-local address is shown but tagged with this compact
/// icon (`public_off` — mirroring the routable `public` icon used for WAN
/// addresses) rather than hidden. The tooltip provides discoverability and
/// doubles as the semantic label for screen readers, since the icon alone
/// carries no text.
class Ipv6ScopeBadge extends StatelessWidget {
  final double? size;

  const Ipv6ScopeBadge({super.key, this.size});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: loc(context).ipv6ScopeLinkLocal,
      child: Icon(
        Icons.public_off,
        size: size ?? BlockConstants.iconSm,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// One [InfoGrid] cell, in either arrangement. See [InfoGrid.axis],
/// [InfoGrid.compact] and [InfoGrid.labelMaxLines] for what each setting is for
/// — the reasoning lives there, with the parameters, not duplicated here.
///
/// The label comes first in tree order either way, so a test that reads a tile's
/// `Text`s positionally gets the same answer in both arrangements.
class _InfoGridTile extends StatelessWidget {
  final InfoGridItem item;
  final Axis axis;
  final bool compact;
  final int? labelMaxLines;

  const _InfoGridTile({
    required this.item,
    this.axis = Axis.vertical,
    this.compact = false,
    this.labelMaxLines,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final label = AppText.labelSmall(
      item.label.toUpperCase(),
      color: colorScheme.onSurfaceVariant,
      maxLines: labelMaxLines,
      // Paired with the cap rather than offered separately: a capped label with
      // no ellipsis is clipped mid-glyph, which reads as a rendering fault where
      // an ellipsis reads as "there is more".
      overflow: labelMaxLines == null ? null : TextOverflow.ellipsis,
    );
    final labelled = item.labelTrailing == null
        ? label
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [label, AppGap.xs(), item.labelTrailing!],
          );
    final value = item.copyable
        ? _CopyableText(text: item.value)
        : AppText.labelMedium(item.value);

    return LayoutBlock(
      padding: compact ? BlockConstants.paddingSm : BlockConstants.paddingMd,
      child: switch (axis) {
        Axis.vertical => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [labelled, AppGap.xs(), value],
          ),
        // The label takes the residual width and the value keeps its intrinsic
        // one: the number *is* the metric, while a wrapped or ellipsized label
        // still names which metric it is. The gap is `sm` where the vertical
        // arrangement uses `xs`, because here it separates two things on one
        // line rather than two lines of one thing.
        Axis.horizontal => Row(
            children: [Expanded(child: labelled), AppGap.sm(), value],
          ),
      },
    );
  }
}

// =============================================================================
// Shared copyable text widget
// =============================================================================

class _CopyableText extends StatelessWidget {
  final String text;

  const _CopyableText({required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc(context).copiedValue(text)),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppSpacing.xxs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: AppText.bodyMedium(text)),
          AppGap.xs(),
          AppIcon.font(
            Icons.copy,
            size: BlockConstants.iconSm,
            color: colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
