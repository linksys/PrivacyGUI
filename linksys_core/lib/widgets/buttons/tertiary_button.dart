part of 'button.dart';

class AppTertiaryButton extends StatelessWidget {
  const AppTertiaryButton(
    this.title, {
    super.key,
    this.icon,
    this.onTap,
    this.padding,
  });

  const AppTertiaryButton.noPadding(
    this.title, {
    Key? key,
    this.icon,
    this.onTap,
  })  : padding = const AppEdgeInsets.only(),
        super(key: key);

  final String title;
  final IconData? icon;
  final VoidCallback? onTap;
  final AppEdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return TapBuilder(
      onTap: onTap,
      builder: (context, state, hasFocus) {
        final theme = AppTheme.of(context);
        final backgroundColorSet = AppWidgetStateColorSet.transparent();
        final foregroundColorSet = AppWidgetStateColorSet(
            inactive: theme.colors.ctaSecondary,
            pressed: theme.colors.ctaPrimary,
            hovered: theme.colors.ctaPrimary.withOpacity(0.6),
            disabled: theme.colors.ctaSecondaryDisable);
        final borderColorSet = AppWidgetStateColorSet.transparent();
        switch (state) {
          case TapState.hover:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppButtonLayout.hovered(
                title: title,
                icon: icon,
                mainAxisSize: MainAxisSize.min,
                backgroundColorSet: backgroundColorSet,
                foregroundColorSet: foregroundColorSet,
                borderColorSet: borderColorSet,
                padding: padding,
              ),
            );
          case TapState.pressed:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppButtonLayout.pressed(
                title: title,
                icon: icon,
                mainAxisSize: MainAxisSize.min,
                backgroundColorSet: backgroundColorSet,
                foregroundColorSet: foregroundColorSet,
                borderColorSet: borderColorSet,
                padding: padding,
              ),
            );
          case TapState.inactive:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppButtonLayout.inactive(
                title: title,
                icon: icon,
                mainAxisSize: MainAxisSize.min,
                backgroundColorSet: backgroundColorSet,
                foregroundColorSet: foregroundColorSet,
                borderColorSet: borderColorSet,
                padding: padding,
              ),
            );
          case TapState.disabled:
            return Semantics(
              enabled: false,
              selected: false,
              child: AppButtonLayout.disabled(
                title: title,
                icon: icon,
                mainAxisSize: MainAxisSize.min,
                backgroundColorSet: backgroundColorSet,
                foregroundColorSet: foregroundColorSet,
                borderColorSet: borderColorSet,
                padding: padding,
              ),
            );
        }
      },
    );
  }
}
