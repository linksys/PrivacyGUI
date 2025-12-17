import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Composed UI Kit version of AppSettingCard
///
/// This component combines ui_kit elements to replicate the functionality
/// of the original privacygui_widgets AppSettingCard.
///
/// Used for displaying settings list items with leading, title, description, and trailing widgets.
class AppSettingCard extends StatelessWidget {
  final Widget? leading;
  final Widget? trailing;
  final String title;
  final String? description;
  final VoidCallback? onTap;
  final bool showBorder;
  final EdgeInsets? padding;
  final Color? color;
  final Color? borderColor;
  final EdgeInsets? margin;
  final bool selectableDescription;

  const AppSettingCard({
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
    this.margin,
    this.selectableDescription = false,
  });

  factory AppSettingCard.noBorder({
    Key? key,
    Widget? leading,
    Widget? trailing,
    required String title,
    String? description,
    VoidCallback? onTap,
    EdgeInsets? padding,
    Color? color,
    Color? borderColor,
    EdgeInsets? margin,
    bool selectableDescription = false,
  }) {
    return AppSettingCard(
      key: key,
      leading: leading,
      trailing: trailing,
      title: title,
      description: description,
      showBorder: false,
      padding: padding ??
          EdgeInsets.symmetric(
            vertical: AppSpacing.lg, // was Spacing.medium (16px)
            horizontal: AppSpacing.xxl, // was Spacing.large2 (24px)
          ),
      onTap: onTap,
      color: color,
      borderColor: borderColor,
      margin: margin,
      selectableDescription: selectableDescription,
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleWidget = description != null
        ? AppText.bodyMedium(title)
        : AppText.labelLarge(title);
    final desc = description;
    final descWidget = desc != null
        ? (selectableDescription
            ? SelectableText(
                desc,
                style: Theme.of(context).textTheme.labelLarge,
              )
            : AppText.labelLarge(desc))
        : null;

    return Container(
      margin: margin,
      child: AppCard(
        onTap: onTap,
        padding: padding ??
            EdgeInsets.symmetric(
              vertical: AppSpacing.lg, // was Spacing.medium (16px)
              horizontal: AppSpacing.xxl, // was Spacing.large2 (24px)
            ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading!,
              AppGap.lg(),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleWidget,
                  if (descWidget != null) ...[
                    AppGap.xs(),
                    descWidget,
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
