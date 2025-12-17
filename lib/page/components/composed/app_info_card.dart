import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A card that displays info with title and optional description.
/// Adapted from privacygui_widgets for full decoupling.
class AppInfoCard extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showBorder;
  final EdgeInsets? padding;
  final Color? color;
  final Color? borderColor;

  const AppInfoCard({
    Key? key,
    required this.title,
    this.description,
    this.trailing,
    this.onTap,
    this.showBorder = true,
    this.padding,
    this.color,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: padding ?? EdgeInsets.all(AppSpacing.lg),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelLarge(title),
                if (description != null) ...[
                  AppGap.xs(),
                  AppText.bodyMedium(description!),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
