import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A standardized card wrapper for Internet Settings sections.
///
/// Provides a consistent header with leading icon, title, optional subtitle,
/// optional trailing widget, and a divider before the child content.
class UspSectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Widget? trailing;
  final Widget child;

  const UspSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.primary;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                if (leadingIcon != null) ...[
                  AppIcon.font(leadingIcon!, size: 20, color: iconColor),
                  AppGap.sm(),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.titleMedium(title),
                      if (subtitle != null) ...[
                        AppGap.xs(),
                        AppText.bodySmall(subtitle!),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            AppGap.md(),
            AppDivider(),
            AppGap.md(),
            // Section content
            child,
          ],
        ),
      ),
    );
  }
}
