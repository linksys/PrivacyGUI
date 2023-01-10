import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:linksys_core/theme/_theme.dart';
import 'package:linksys_core/widgets/_widgets.dart';
import 'package:linksys_core/widgets/base/gap.dart';
import 'package:linksys_core/widgets/base/icon.dart';
import 'package:tap_builder/tap_builder.dart';

class AppNavButton extends StatelessWidget {
  const AppNavButton({
    Key? key,
    this.icon,
    this.title,
    this.onTap,
    this.mainAxisSize = MainAxisSize.min,
  })
      : assert(
  icon != null || title != null,
  ),
        super(key: key);

  final IconData? icon;
  final String? title;
  final MainAxisSize mainAxisSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TapBuilder(
      onTap: onTap,
      builder: (context, state, hasFocus) {
        switch (state) {
          case TapState.hover:
            return Semantics(
              enabled: true,
              selected: false,
              child: AppButtonLayout.hovered(
                icon: icon,
                title: title,
                mainAxisSize: mainAxisSize,
              ),
            );
          case TapState.pressed:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppButtonLayout.pressed(
                icon: icon,
                title: title,
                mainAxisSize: mainAxisSize,
              ),
            );
          case TapState.inactive:
            return Semantics(
              enabled: true,
              selected: false,
              child: AppButtonLayout.inactive(
                icon: icon,
                title: title,
                mainAxisSize: mainAxisSize,
              ),
            );
          case TapState.disabled:
            return Semantics(
              enabled: false,
              selected: false,
              child: AppButtonLayout.disabled(
                icon: icon,
                title: title,
                mainAxisSize: mainAxisSize,
              ),
            );
        }
      },
    );
  }
}

enum AppButtonState {
  inactive,
  hovered,
  pressed,
  disabled,
}

class AppButtonLayout extends StatelessWidget {
  const AppButtonLayout.inactive({
    Key? key,
    this.icon,
    this.title,
    this.mainAxisSize = MainAxisSize.min,
    this.backgroundColorSet = const AppButtonColorSet(),
    this.foregroundColorSet = const AppButtonColorSet(),
    this.borderColorSet = const AppButtonColorSet(),
  })
      : _state = AppButtonState.inactive,
        assert(
        icon != null || title != null,
        ),
        super(key: key);

  const AppButtonLayout.hovered({
    Key? key,
    this.icon,
    this.title,
    this.mainAxisSize = MainAxisSize.min,
    this.backgroundColorSet = const AppButtonColorSet(),
    this.foregroundColorSet = const AppButtonColorSet(),
    this.borderColorSet = const AppButtonColorSet(),
  })
      : _state = AppButtonState.hovered,
        assert(
        icon != null || title != null,
        ),
        super(key: key);

  const AppButtonLayout.pressed({
    Key? key,
    this.icon,
    this.title,
    this.mainAxisSize = MainAxisSize.min,
    this.backgroundColorSet = const AppButtonColorSet(),
    this.foregroundColorSet = const AppButtonColorSet(),
    this.borderColorSet = const AppButtonColorSet(),
  })
      : _state = AppButtonState.pressed,
        assert(
        icon != null || title != null,
        ),
        super(key: key);

  const AppButtonLayout.disabled({
    Key? key,
    this.icon,
    this.title,
    this.mainAxisSize = MainAxisSize.min,
    this.backgroundColorSet = const AppButtonColorSet(),
    this.foregroundColorSet = const AppButtonColorSet(),
    this.borderColorSet = const AppButtonColorSet(),
  })
      : _state = AppButtonState.disabled,
        assert(
        icon != null || title != null,
        ),
        super(key: key);

  final IconData? icon;
  final String? title;
  final MainAxisSize mainAxisSize;
  final AppButtonState _state;
  final AppButtonColorSet backgroundColorSet;
  final AppButtonColorSet foregroundColorSet;
  final AppButtonColorSet borderColorSet;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final title = this.title;
    final icon = this.icon;
    final hasBoth = (title != null && icon != null);
    final foregroundColor = () {
      final defaultSet = AppButtonColorSet(
        inactive: theme.colors.ctaPrimary,
        hovered: theme.colors.ctaPrimary.withOpacity(0.6),
        pressed: theme.colors.ctaSecondary,
        disabled: theme.colors.ctaPrimaryDisable,
      );
      return foregroundColorSet.resolve(_state) ?? defaultSet.resolve(_state);
    }();

    final backgroundColor = AppButtonColorSet.transparent().resolve(_state);
    final borderBackgroundColor = AppButtonColorSet.transparent().resolve(_state);
    return AnimatedContainer(
      duration: theme.durations.quick,
      decoration: BoxDecoration(
        border: Border.all(
            width: 1, color: borderBackgroundColor ?? ConstantColors.transparent),
        color: backgroundColor,
      ),
      padding: EdgeInsets.symmetric(
        vertical: theme.spacing.semiBig,
        horizontal:
        title != null ? theme.spacing.semiBig : theme.spacing.semiSmall,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) AppIcon.regular(icon: icon, color: foregroundColor),
          if (hasBoth) const AppGap.small(),
          if (title != null)
            AppText.textLinkTertiarySmall(
              title,
              color: foregroundColor,
            ),
        ],
      ),
    );
  }
}

class AppButtonColorSet extends Equatable {
  final Color? inactive;
  final Color? hovered;
  final Color? pressed;
  final Color? disabled;

  const AppButtonColorSet({
    this.inactive,
    this.hovered,
    this.pressed,
    this.disabled,
  });

  factory AppButtonColorSet.transparent() =>
      const AppButtonColorSet(inactive: ConstantColors.transparent,
        hovered: ConstantColors.transparent,
        pressed: ConstantColors.transparent,
        disabled: ConstantColors.transparent,);

  Color? resolve(AppButtonState state) {
    switch (state) {
      case AppButtonState.inactive:
        return inactive;
      case AppButtonState.hovered:
        return hovered;
      case AppButtonState.pressed:
        return pressed;
      case AppButtonState.disabled:
        return disabled;
    }
  }

  @override
  List<Object?> get props =>
      [
        inactive,
        hovered,
        pressed,
        disabled,
      ];

  AppButtonColorSet copyWith({
    Color? inactive,
    Color? hovered,
    Color? pressed,
    Color? disabled,
  }) {
    return AppButtonColorSet(
      inactive: inactive ?? this.inactive,
      hovered: hovered ?? this.hovered,
      pressed: pressed ?? this.pressed,
      disabled: disabled ?? this.disabled,
    );
  }
}
