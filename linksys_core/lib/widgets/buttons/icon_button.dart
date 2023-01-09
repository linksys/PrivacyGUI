part of 'button.dart';

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    Key? key,
    this.icon,
    this.onTap,
    this.padding,
    this.mainAxisSize = MainAxisSize.min,
  })
      : assert(
  icon != null,
  ),
        super(key: key);

  final IconData? icon;
  final MainAxisSize mainAxisSize;
  final AppEdgeInsets? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TapBuilder(
      onTap: onTap,
      builder: (context, state, hasFocus) {
        final theme = AppTheme.of(context);
        final backgroundColorSet = AppWidgetStateColorSet.transparent();
        final foregroundColorSet = AppWidgetStateColorSet(
            inactive: theme.colors.ctaPrimary,
            pressed: theme.colors.ctaSecondary,
            hovered: theme.colors.ctaSecondary.withOpacity(0.6),
            disabled: theme.colors.ctaPrimaryDisable);
        final borderColorSet = AppWidgetStateColorSet.transparent();
        switch (state) {
          case TapState.hover:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppButtonLayout.hovered(
                icon: icon,
                mainAxisSize: mainAxisSize,
                padding: padding,
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
                icon: icon,
                mainAxisSize: mainAxisSize,
                padding: padding,
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
                icon: icon,
                mainAxisSize: mainAxisSize,
                padding: padding,
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
                icon: icon,
                mainAxisSize: mainAxisSize,
                padding: padding,
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