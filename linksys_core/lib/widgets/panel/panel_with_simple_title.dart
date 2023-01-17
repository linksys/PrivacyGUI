part of 'panel_bases.dart';

class AppPanelWithSimpleTitle extends StatelessWidget {
  final String title;
  final AppWidgetStateColorSet? titleColorSet;
  final String? description;
  final VoidCallback? onTap;
  final bool forcedHidingAccessory;

  const AppPanelWithSimpleTitle({
    Key? key,
    required this.title,
    this.titleColorSet,
    this.description,
    this.onTap,
    this.forcedHidingAccessory = false,
  }) : super(key: key);

  Widget _getTitleWidgetByState(TapState state) {
    final titleColor = titleColorSet?.resolveByTapState(state);
    return (description != null)
        ? AppText.descriptionSub(title, color: titleColor)
        : AppText.descriptionMain(title, color: titleColor);
  }

  Widget? _getDescriptionWidget(BuildContext context) {
    final description = this.description;
    return description != null
        ? AppText.descriptionMain(description,
            color: AppTheme.of(context).colors.ctaPrimaryDisable)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return TapBuilder(
      onTap: onTap,
      builder: (context, state, hasFocus) {
        switch (state) {
          case TapState.inactive:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppPanelLayout.inactive(
                head: _getTitleWidgetByState(state),
                description: _getDescriptionWidget(context),
                isHidingAccessory: (forcedHidingAccessory || onTap == null),
              ),
            );
          case TapState.hover:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppPanelLayout.hovered(
                head: _getTitleWidgetByState(state),
                description: _getDescriptionWidget(context),
                isHidingAccessory: (forcedHidingAccessory || onTap == null),
              ),
            );
          case TapState.pressed:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppPanelLayout.pressed(
                head: _getTitleWidgetByState(state),
                description: _getDescriptionWidget(context),
                isHidingAccessory: (forcedHidingAccessory || onTap == null),
              ),
            );
          case TapState.disabled:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppPanelLayout.disabled(
                head: _getTitleWidgetByState(state),
                description: _getDescriptionWidget(context),
                isHidingAccessory: (forcedHidingAccessory || onTap == null),
              ),
            );
        }
      },
    );
  }
}
