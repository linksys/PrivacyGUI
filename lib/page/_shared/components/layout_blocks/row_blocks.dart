import 'package:flutter/material.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks/status_blocks.dart';
import 'package:ui_kit_library/ui_kit.dart';

// =============================================================================
// NetworkRow - WiFi network row with badges and trailing widget
// =============================================================================

class NetworkRow extends StatelessWidget {
  final String title;
  final List<NetworkBadge> badges;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  const NetworkRow({
    super.key,
    required this.title,
    this.badges = const [],
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Block(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyLarge(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (badges.isNotEmpty) ...[
                    AppGap.xs(),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      children: badges
                          .map((b) => NetworkBadgeWidget(badge: b))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// NetworkBadge - Badge for network row
// =============================================================================

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

  static NetworkBadge fromBand(String band) {
    final b = band.toLowerCase();
    if (b.contains('2.4')) return const NetworkBadge.band2g();
    if (b.contains('6')) return const NetworkBadge.band6g();
    if (b.contains('5')) return const NetworkBadge.band5g();
    return NetworkBadge(label: band);
  }
}

class NetworkBadgeWidget extends StatelessWidget {
  final NetworkBadge badge;

  const NetworkBadgeWidget({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = badge.color ?? colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge.icon != null) ...[
            Icon(badge.icon, size: 12, color: color),
            AppGap.xxs(),
          ],
          AppText.labelSmall(badge.label, color: color),
        ],
      ),
    );
  }
}

// =============================================================================
// DataRow - Multi-column row with leading and trailing widgets
// =============================================================================

class DataRow extends StatelessWidget {
  final Widget? leading;
  final List<DataRowCell> cells;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  const DataRow({
    super.key,
    this.leading,
    required this.cells,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.5,
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                AppGap.sm(),
              ],
              ...cells.map((cell) => cell.flex != null
                  ? Expanded(
                      flex: cell.flex!, child: _DataRowCellWidget(cell: cell))
                  : SizedBox(
                      width: cell.width,
                      child: _DataRowCellWidget(cell: cell))),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class DataRowCell {
  final String text;
  final String? subtitle;
  final int? flex;
  final double? width;
  final TextAlign? textAlign;
  final bool secondary;

  const DataRowCell({
    required this.text,
    this.subtitle,
    this.flex,
    this.width,
    this.textAlign,
    this.secondary = false,
  });

  const DataRowCell.flex({
    required this.text,
    this.subtitle,
    int flex = 1,
    this.textAlign,
    this.secondary = false,
  })  : flex = flex,
        width = null;

  const DataRowCell.fixed({
    required this.text,
    this.subtitle,
    required double width,
    this.textAlign,
    this.secondary = false,
  })  : width = width,
        flex = null;
}

class _DataRowCellWidget extends StatelessWidget {
  final DataRowCell cell;

  const _DataRowCellWidget({required this.cell});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = cell.secondary ? colorScheme.onSurfaceVariant : null;

    if (cell.subtitle != null) {
      return Column(
        crossAxisAlignment: _alignment(cell.textAlign),
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.bodyMedium(
            cell.text,
            textAlign: cell.textAlign,
            color: textColor,
          ),
          AppText.bodySmall(
            cell.subtitle!,
            textAlign: cell.textAlign,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      );
    }

    return AppText.bodyMedium(
      cell.text,
      textAlign: cell.textAlign,
      color: textColor,
    );
  }

  CrossAxisAlignment _alignment(TextAlign? align) {
    return switch (align) {
      TextAlign.end || TextAlign.right => CrossAxisAlignment.end,
      TextAlign.center => CrossAxisAlignment.center,
      _ => CrossAxisAlignment.start,
    };
  }
}

// =============================================================================
// StatusRow - Row with status indicator and info
// =============================================================================

class StatusRow extends StatelessWidget {
  final bool isActive;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const StatusRow({
    super.key,
    required this.isActive,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorScheme>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? (appColors?.semanticSuccess ?? Colors.green)
                  : colorScheme.outline,
            ),
          ),
          AppGap.sm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyMedium(title),
                if (subtitle != null)
                  AppText.bodySmall(
                    subtitle!,
                    color: colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// =============================================================================
// DeviceRow - Device list item block with icon, name, subtitle, and trailing
// =============================================================================

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

    return Block(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Center(child: icon),
          ),
          AppGap.md(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyLarge(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  AppText.bodySmall(
                    subtitle!,
                    color: colorScheme.onSurfaceVariant,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            AppGap.sm(),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// ToggleListItem - List item with toggle switch
// =============================================================================

class ToggleListItem extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? trailing;

  const ToggleListItem({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            AppGap.sm(),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyMedium(title),
                if (subtitle != null)
                  AppText.bodySmall(
                    subtitle!,
                    color: colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            trailing!,
            AppGap.sm(),
          ],
          AppSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
