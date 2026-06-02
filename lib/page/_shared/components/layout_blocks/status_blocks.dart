import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

// =============================================================================
// Block - Base wrapper for all block components
// =============================================================================

class Block extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final bool showBorder;

  const Block({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final content = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: showBorder
            ? Border.all(color: colorScheme.outline.withValues(alpha: 0.2))
            : null,
      ),
      child: child,
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: content,
    );
  }
}

// =============================================================================
// CardHeader - Unified card header with consistent height
// =============================================================================

class CardHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const CardHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppText.titleMedium(title),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// =============================================================================
// StatusBlock - Connection status with icon indicator
// =============================================================================

enum StatusBlockVariant { online, offline, warning }

class StatusBlock extends StatelessWidget {
  final StatusBlockVariant variant;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const StatusBlock({
    super.key,
    required this.variant,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  const StatusBlock.online({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  }) : variant = StatusBlockVariant.online;

  const StatusBlock.offline({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  }) : variant = StatusBlockVariant.offline;

  const StatusBlock.warning({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  }) : variant = StatusBlockVariant.warning;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorScheme>();

    final (iconData, iconColor) = switch (variant) {
      StatusBlockVariant.online => (
          Icons.check,
          appColors?.semanticSuccess ?? Colors.green
        ),
      StatusBlockVariant.offline => (Icons.close, colorScheme.error),
      StatusBlockVariant.warning => (Icons.warning, Colors.orange),
    };

    return Block(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: AppIcon.font(iconData, color: iconColor, size: 24),
          ),
          AppGap.md(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleSmall(title),
                if (subtitle != null) ...[
                  AppGap.xxs(),
                  AppText.bodySmall(
                    subtitle!,
                    color: colorScheme.onSurfaceVariant,
                  ),
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

// =============================================================================
// AlertBanner - Info/Warning/Error message
// =============================================================================

enum AlertBannerVariant { info, success, warning, error }

class AlertBanner extends StatelessWidget {
  final AlertBannerVariant variant;
  final String title;
  final String? message;
  final VoidCallback? onDismiss;

  const AlertBanner({
    super.key,
    required this.variant,
    required this.title,
    this.message,
    this.onDismiss,
  });

  const AlertBanner.info({
    super.key,
    required this.title,
    this.message,
    this.onDismiss,
  }) : variant = AlertBannerVariant.info;

  const AlertBanner.success({
    super.key,
    required this.title,
    this.message,
    this.onDismiss,
  }) : variant = AlertBannerVariant.success;

  const AlertBanner.warning({
    super.key,
    required this.title,
    this.message,
    this.onDismiss,
  }) : variant = AlertBannerVariant.warning;

  const AlertBanner.error({
    super.key,
    required this.title,
    this.message,
    this.onDismiss,
  }) : variant = AlertBannerVariant.error;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorScheme>();

    final (iconData, accentColor) = switch (variant) {
      AlertBannerVariant.info => (Icons.info, colorScheme.primary),
      AlertBannerVariant.success => (
          Icons.check_circle,
          appColors?.semanticSuccess ?? Colors.green
        ),
      AlertBannerVariant.warning => (Icons.warning, Colors.orange),
      AlertBannerVariant.error => (Icons.error, colorScheme.error),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon.font(iconData, size: 20, color: accentColor),
          AppGap.sm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelMedium(title),
                if (message != null) ...[
                  AppGap.xxs(),
                  AppText.bodySmall(
                    message!,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
          if (onDismiss != null)
            InkWell(
              onTap: onDismiss,
              child: AppIcon.font(
                Icons.close,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
