import 'package:flutter/material.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks/status_blocks.dart';
import 'package:ui_kit_library/ui_kit.dart';

// =============================================================================
// SplitRow - Left info / Right value or action
// =============================================================================

class SplitRow extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SplitRow({
    super.key,
    this.icon,
    required this.label,
    this.value,
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
          if (icon != null) ...[
            AppIcon.font(icon!, size: 20, color: colorScheme.onSurfaceVariant),
            AppGap.sm(),
          ],
          Expanded(child: AppText.labelMedium(label)),
          if (value != null)
            AppText.labelMedium(value!, color: colorScheme.primary),
          if (trailing != null) ...[
            if (value != null) AppGap.sm(),
            trailing!,
          ],
          if (onTap != null) ...[
            AppGap.xs(),
            AppIcon.font(
              Icons.chevron_right,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// ToggleRow - Feature on/off status with switch
// =============================================================================

class ToggleRow extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const ToggleRow({
    super.key,
    this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Block(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          if (icon != null) ...[
            AppIcon.font(icon!, size: 20, color: colorScheme.onSurfaceVariant),
            AppGap.sm(),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelMedium(label),
                if (subtitle != null)
                  AppText.bodySmall(
                    subtitle!,
                    color: colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
          AppSwitch(
            value: value,
            onChanged: onChanged ?? (_) {},
          ),
        ],
      ),
    );
  }
}
