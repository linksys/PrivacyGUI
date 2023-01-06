part of 'button.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton(
    this.title, {
    super.key,
    this.icon,
    this.onTap,
  });

  final String title;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TapBuilder(
      onTap: onTap,
      builder: (context, state, hasFocus) {
        final theme = AppTheme.of(context);
        final backgroundColorSet = AppButtonColorSet(
            inactive: ConstantColors.primaryLinksysBlue,
            pressed: theme.colors.ctaSecondary.withOpacity(0),
            hovered: theme.colors.ctaSecondary.withOpacity(0.6),
            disabled: ConstantColors.baseTextBoxBlueDisabled);
        final foregroundColorSet = AppButtonColorSet(
            inactive: ConstantColors.primaryLinksysWhite,
            pressed: theme.colors.ctaSecondary,
            hovered: theme.colors.ctaSecondary.withOpacity(0.6),
            disabled: theme.colors.ctaPrimaryDisable);
        final borderColorSet = AppButtonColorSet(
            inactive: ConstantColors.primaryLinksysBlue,
            pressed: theme.colors.ctaSecondary,
            hovered: theme.colors.ctaSecondary.withOpacity(0.6),
            disabled: ConstantColors.baseTextBoxBlueDisabled);
        switch (state) {
          case TapState.hover:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppButtonLayout.hovered(
                title: title,
                icon: icon,
                mainAxisSize: MainAxisSize.max,
                backgroundColorSet: backgroundColorSet,
                foregroundColorSet: foregroundColorSet,
                borderColorSet: borderColorSet,
              ),
            );
          case TapState.pressed:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppButtonLayout.pressed(
                title: title,
                icon: icon,
                mainAxisSize: MainAxisSize.max,
                backgroundColorSet: backgroundColorSet,
                foregroundColorSet: foregroundColorSet,
                borderColorSet: borderColorSet,
              ),
            );
          case TapState.inactive:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppButtonLayout.inactive(
                title: title,
                icon: icon,
                mainAxisSize: MainAxisSize.max,
                backgroundColorSet: backgroundColorSet,
                foregroundColorSet: foregroundColorSet,
                borderColorSet: borderColorSet,
              ),
            );
          case TapState.disabled:
            return Semantics(
              enabled: false,
              selected: false,
              child: AppButtonLayout.disabled(
                title: title,
                icon: icon,
                mainAxisSize: MainAxisSize.max,
                backgroundColorSet: backgroundColorSet,
                foregroundColorSet: foregroundColorSet,
                borderColorSet: borderColorSet,
              ),
            );
        }
      },
    );
  }
}
