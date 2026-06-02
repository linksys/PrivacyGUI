import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    return Block(
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
class InfoGrid extends StatelessWidget {
  final List<InfoGridItem> items;
  final int crossAxisCount;

  const InfoGrid({
    super.key,
    required this.items,
    this.crossAxisCount = 2,
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
            child: _InfoGridTile(item: row.first),
          );
        }

        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < row.length; i++) ...[
                  Expanded(child: _InfoGridTile(item: row[i])),
                  if (i < row.length - 1) AppGap.sm(),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Item for [InfoGrid].
class InfoGridItem {
  final String label;
  final String value;
  final bool fullWidth;
  final bool copyable;

  const InfoGridItem({
    required this.label,
    required this.value,
    this.fullWidth = false,
    this.copyable = false,
  });
}

class _InfoGridTile extends StatelessWidget {
  final InfoGridItem item;

  const _InfoGridTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Block(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.labelSmall(
            item.label.toUpperCase(),
            color: colorScheme.onSurfaceVariant,
          ),
          AppGap.xs(),
          item.copyable
              ? _CopyableText(text: item.value)
              : AppText.labelMedium(item.value),
        ],
      ),
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
            content: Text('Copied: $text'),
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
