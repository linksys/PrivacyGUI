import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Composed UI Kit version of AppListCard
///
/// This component combines ui_kit elements to replicate the functionality
/// of the original privacygui_widgets AppListCard.
///
/// Used for displaying list items with leading, title, description, and trailing widgets.
class AppListCard extends StatelessWidget {
  const AppListCard({
    super.key,
    this.leading,
    this.trailing,
    required this.title,
    this.description,
    this.showBorder = true,
    this.padding,
    this.onTap,
    this.color,
    this.borderColor,
    this.crossAxisAlignment,
    this.margin,
  });

  final Widget? leading;
  final Widget? trailing;
  final Widget title;
  final Widget? description;
  final VoidCallback? onTap;
  final bool showBorder;
  final EdgeInsets? padding;
  final Color? color;
  final Color? borderColor;
  final CrossAxisAlignment? crossAxisAlignment;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: AppCard(
        onTap: onTap,
        padding: padding ?? EdgeInsets.symmetric(
          vertical: AppSpacing.md, // was Spacing.medium (16px)
          horizontal: AppSpacing.xl, // was Spacing.large2 (24px)
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading!,
              AppGap.lg(), // was AppGap.medium()
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  if (description != null) ...[
                    description!,
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!
          ],
        ),
      ),
    );
  }
}