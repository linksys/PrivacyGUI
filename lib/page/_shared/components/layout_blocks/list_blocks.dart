import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks/status_blocks.dart';
import 'package:ui_kit_library/ui_kit.dart';

// =============================================================================
// InfoList - Vertical key-value list (simple, full-width rows)
// =============================================================================

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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
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
          AppIcon.font(Icons.copy, size: 14, color: colorScheme.primary),
        ],
      ),
    );
  }
}

// =============================================================================
// InfoGrid - 2-column key-value grid
// =============================================================================

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
    // Group items into rows for height alignment
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
// ListPreview - Preview list with "View All" action
// =============================================================================

class ListPreview extends StatelessWidget {
  final List<ListPreviewItem> items;
  final int maxItems;
  final int totalCount;
  final String viewAllLabel;
  final VoidCallback? onViewAll;

  const ListPreview({
    super.key,
    required this.items,
    this.maxItems = 3,
    required this.totalCount,
    this.viewAllLabel = 'View all',
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayItems = items.take(maxItems).toList();
    final hasMore = totalCount > maxItems;

    return Block(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ...displayItems.asMap().entries.map((entry) {
            final isLast = entry.key == displayItems.length - 1 && !hasMore;
            return _ListPreviewTile(item: entry.value, showDivider: !isLast);
          }),
          if (hasMore)
            InkWell(
              onTap: onViewAll,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppSpacing.sm),
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: colorScheme.surfaceContainer),
                  ),
                ),
                child: Center(
                  child: AppText.labelMedium(
                    '$viewAllLabel $totalCount',
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ListPreviewItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const ListPreviewItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });
}

class _ListPreviewTile extends StatelessWidget {
  final ListPreviewItem item;
  final bool showDivider;

  const _ListPreviewTile({required this.item, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: showDivider
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colorScheme.surfaceContainer),
              ),
            )
          : null,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AppIcon.font(item.icon,
                  size: 18, color: colorScheme.onSurfaceVariant),
            ),
          ),
          AppGap.sm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelMedium(item.title),
                if (item.subtitle != null)
                  AppText.bodySmall(
                    item.subtitle!,
                    color: colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
          if (item.trailing != null) item.trailing!,
        ],
      ),
    );
  }
}
