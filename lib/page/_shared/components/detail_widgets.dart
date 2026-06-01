import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:privacy_gui/page/_shared/components/usp_status_dot.dart';
import 'package:privacy_gui/util/network_utils.dart';
import 'package:ui_kit_library/ui_kit.dart';

// =============================================================================
// Card Header
// =============================================================================

/// Standard card header with icon and title.
class DetailCardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const DetailCardHeader({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        AppGap.sm(),
        Expanded(child: AppText.titleMedium(title)),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// =============================================================================
// Status Badge
// =============================================================================

/// Pill-shaped status badge showing Online/Offline state.
class DetailStatusBadge extends StatelessWidget {
  final bool isActive;
  final String? activeLabel;
  final String? inactiveLabel;

  const DetailStatusBadge({
    super.key,
    required this.isActive,
    this.activeLabel,
    this.inactiveLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          UspStatusDot(isActive: isActive, size: 8),
          AppGap.xs(),
          AppText.labelMedium(
            isActive ? (activeLabel ?? 'Online') : (inactiveLabel ?? 'Offline'),
            color: isActive
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Info Tiles
// =============================================================================

/// Info tile with icon, label, and value (vertical layout).
class DetailInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const DetailInfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        AppGap.sm(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.labelSmall(label, color: colorScheme.onSurfaceVariant),
              AppText.bodyMedium(value),
            ],
          ),
        ),
      ],
    );
  }
}

/// Info tile with optional tap action and trailing widget.
class DetailNavigableTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const DetailNavigableTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        AppGap.sm(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.labelSmall(label, color: colorScheme.onSurfaceVariant),
              AppText.bodyMedium(value),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: content,
      ),
    );
  }
}

/// Info tile with copyable value.
class DetailCopyableTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const DetailCopyableTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        AppGap.sm(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.labelSmall(label, color: colorScheme.onSurfaceVariant),
              DetailCopyableText(text: value),
            ],
          ),
        ),
      ],
    );
  }
}

/// Compact info tile with background (for grouped display).
class DetailCompactInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const DetailCompactInfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          AppGap.sm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelSmall(label, color: colorScheme.onSurfaceVariant),
                AppText.bodyMedium(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Copyable Text
// =============================================================================

/// Text that can be tapped to copy to clipboard.
class DetailCopyableText extends StatelessWidget {
  final String text;

  const DetailCopyableText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
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
          Icon(
            Icons.copy,
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Speed Card
// =============================================================================

/// Card displaying speed value with auto-formatted unit.
class DetailSpeedCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int speedBps;
  final Color color;

  const DetailSpeedCard({
    super.key,
    required this.icon,
    required this.label,
    required this.speedBps,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = speedBps > 0;
    final (:value, :unit) = hasData
        ? NetworkUtils.formatBitsWithUnit(speedBps)
        : (value: '--', unit: '');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              AppGap.xs(),
              AppText.labelSmall(label, color: color),
            ],
          ),
          AppGap.xs(),
          AppText.titleLarge(value),
          AppText.labelSmall(
            unit,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Grid Layout Helpers
// =============================================================================

/// A row of two equal-width cards with height alignment.
class DetailGridRow extends StatelessWidget {
  final Widget left;
  final Widget right;

  const DetailGridRow({
    super.key,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          AppGap.gutter(),
          Expanded(child: right),
        ],
      ),
    );
  }
}
