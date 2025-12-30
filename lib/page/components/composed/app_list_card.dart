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

  /// Factory constructor for settings-style cards with String title/description.
  /// Replaces AppSettingCard usage.
  factory AppListCard.setting({
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
    final titleWidget = description != null
        ? AppText.bodyMedium(title)
        : AppText.labelLarge(title);

    Widget? descWidget;
    if (description != null) {
      descWidget = selectableDescription
          ? SelectableText(description)
          : AppText.labelLarge(description);
    }

    return AppListCard(
      key: key,
      leading: leading,
      trailing: trailing,
      title: titleWidget,
      description: descWidget != null
          ? Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: descWidget,
            )
          : null,
      padding: padding ??
          EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.xxl,
          ),
      onTap: onTap,
      color: color,
      borderColor: borderColor,
      margin: margin,
    );
  }

  /// Factory for noBorder variant (replaces AppSettingCard.noBorder)
  factory AppListCard.settingNoBorder({
    Key? key,
    Widget? leading,
    Widget? trailing,
    required String title,
    String? description,
    VoidCallback? onTap,
    EdgeInsets? padding,
    Color? color,
    EdgeInsets? margin,
    bool selectableDescription = false,
  }) {
    return AppListCard.setting(
      key: key,
      leading: leading,
      trailing: trailing,
      title: title,
      description: description,
      onTap: onTap,
      padding: padding ??
          EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.xxl,
          ),
      color: color,
      borderColor: Colors.transparent,
      margin: margin,
      selectableDescription: selectableDescription,
    );
  }

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
    final theme = Theme.of(context).extension<AppDesignTheme>();

    // Determine if border should be hidden
    final hideBorder = !showBorder || borderColor == Colors.transparent;

    // Create style override if needed
    SurfaceStyle? effectiveStyle;
    if (theme != null && (hideBorder || color != null || borderColor != null)) {
      effectiveStyle = theme.surfaceBase.copyWith(
        borderWidth: hideBorder ? 0 : null,
        borderColor: (!hideBorder && borderColor != null) ? borderColor : null,
        backgroundColor: color,
      );
    }

    return Container(
      margin: margin,
      child: AppCard(
        onTap: onTap,
        style: effectiveStyle,
        padding: padding ??
            EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.xl,
            ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
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
