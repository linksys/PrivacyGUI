import 'package:flutter/material.dart';
import 'package:linksys_core/theme/_theme.dart';
import 'package:linksys_core/widgets/_widgets.dart';
import 'package:linksys_core/widgets/base/gap.dart';
import 'package:linksys_core/widgets/base/icon.dart';
import 'package:linksys_core/widgets/base/padding.dart';
import 'package:linksys_core/widgets/state.dart';

class AppButtonLayout extends StatelessWidget {
  const AppButtonLayout.inactive({
    Key? key,
    this.icon,
    this.title,
    this.padding,
    this.mainAxisSize = MainAxisSize.min,
    this.backgroundColorSet = const AppWidgetStateColorSet(),
    this.foregroundColorSet = const AppWidgetStateColorSet(),
    this.borderColorSet = const AppWidgetStateColorSet(),
  })
      : _state = AppWidgetState.inactive,
        assert(
        icon != null || title != null,
        ),
        super(key: key);

  const AppButtonLayout.hovered({
    Key? key,
    this.icon,
    this.title,
    this.padding,
    this.mainAxisSize = MainAxisSize.min,
    this.backgroundColorSet = const AppWidgetStateColorSet(),
    this.foregroundColorSet = const AppWidgetStateColorSet(),
    this.borderColorSet = const AppWidgetStateColorSet(),
  })
      : _state = AppWidgetState.hovered,
        assert(
        icon != null || title != null,
        ),
        super(key: key);

  const AppButtonLayout.pressed({
    Key? key,
    this.icon,
    this.title,
    this.padding,
    this.mainAxisSize = MainAxisSize.min,
    this.backgroundColorSet = const AppWidgetStateColorSet(),
    this.foregroundColorSet = const AppWidgetStateColorSet(),
    this.borderColorSet = const AppWidgetStateColorSet(),
  })
      : _state = AppWidgetState.pressed,
        assert(
        icon != null || title != null,
        ),
        super(key: key);

  const AppButtonLayout.disabled({
    Key? key,
    this.icon,
    this.title,
    this.padding,
    this.mainAxisSize = MainAxisSize.min,
    this.backgroundColorSet = const AppWidgetStateColorSet(),
    this.foregroundColorSet = const AppWidgetStateColorSet(),
    this.borderColorSet = const AppWidgetStateColorSet(),
  })
      : _state = AppWidgetState.disabled,
        assert(
        icon != null || title != null,
        ),
        super(key: key);

  final IconData? icon;
  final String? title;
  final MainAxisSize mainAxisSize;
  final AppEdgeInsets? padding;
  final AppWidgetState _state;
  final AppWidgetStateColorSet backgroundColorSet;
  final AppWidgetStateColorSet foregroundColorSet;
  final AppWidgetStateColorSet borderColorSet;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final title = this.title;
    final icon = this.icon;
    final hasBoth = (title != null && icon != null);
    final foregroundColor = () {
      final defaultSet = AppWidgetStateColorSet(
        inactive: theme.colors.ctaPrimary,
        hovered: theme.colors.ctaPrimary.withOpacity(0.6),
        pressed: theme.colors.ctaSecondary,
        disabled: theme.colors.ctaPrimaryDisable,
      );
      return foregroundColorSet.resolve(_state) ?? defaultSet.resolve(_state);
    }();

    final backgroundColor = () {
      final defaultSet = AppWidgetStateColorSet(
        inactive: ConstantColors.primaryLinksysBlue,
        hovered: theme.colors.ctaSecondary.withOpacity(0.6),
        pressed: theme.colors.ctaSecondary.withOpacity(0),
        disabled: theme.colors.ctaSecondaryDisable,
      );
      return backgroundColorSet.resolve(_state) ?? defaultSet.resolve(_state);
    }();
    final borderBackgroundColor = () {
      final defaultSet = AppWidgetStateColorSet(
        inactive: ConstantColors.primaryLinksysBlue,
        hovered: theme.colors.ctaSecondary,
        pressed: theme.colors.ctaSecondary,
        disabled: theme.colors.ctaSecondaryDisable,
      );
      return borderColorSet.resolve(_state) ?? defaultSet.resolve(_state);
    }();
    return AnimatedContainer(
      duration: theme.durations.quick,
      decoration: BoxDecoration(
        border: borderBackgroundColor == null ? null : Border.all(
            width: 1, color: borderBackgroundColor ?? ConstantColors.transparent),
        color: backgroundColor,
      ),
      child: AppPadding(
        padding: padding ?? AppEdgeInsets.all(title != null ? AppGapSize.semiBig : AppGapSize.semiSmall),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: mainAxisSize,
          children: [
            if (title != null)
              AppText.textLinkLarge(
                title,
                color: foregroundColor,
              ),
            if (hasBoth) const AppGap.semiSmall(),
            if (icon != null) AppIcon.regular(icon: icon, color: foregroundColor),
          ],
        ),
      ),
    );
  }
}

class AppActionButtonLayout extends StatelessWidget {
  final String title;
  final bool hasActions;
  final AppWidgetStateColorSet foregroundColorSet;
  final AppWidgetState _state;

  const AppActionButtonLayout.inactive({
    Key? key,
    required this.title,
    required this.hasActions,
    required this.foregroundColorSet,
  })  : _state = AppWidgetState.inactive,
        super(key: key);

  const AppActionButtonLayout.hovered({
    Key? key,
    required this.title,
    required this.hasActions,
    required this.foregroundColorSet,
  })  : _state = AppWidgetState.hovered,
        super(key: key);

  const AppActionButtonLayout.pressed({
    Key? key,
    required this.title,
    required this.foregroundColorSet,
    required this.hasActions,
  })  : _state = AppWidgetState.pressed,
        super(key: key);

  const AppActionButtonLayout.disabled({
    Key? key,
    required this.title,
    required this.foregroundColorSet,
    required this.hasActions,
  })  : _state = AppWidgetState.disabled,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final title = this.title;
    final icon = theme.icons.characters.chevronDown;
    final foregroundColor = foregroundColorSet.resolve(_state);

    return AnimatedContainer(
      duration: theme.durations.quick,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.textLinkLarge(
            title,
            color: foregroundColor,
          ),
          Offstage(
            offstage: !hasActions,
            child: Row(
              children: [
                const AppGap.semiSmall(),
                AppIcon.regular(icon: icon, color: foregroundColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
