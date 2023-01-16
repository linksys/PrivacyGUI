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

  Widget getTitleWidgetByState(TapState state) {
    final titleColor = titleColorSet?.resolveByTapState(state);
    return (description != null)
        ? AppText.descriptionSub(
            title,
            color: titleColor,
          )
        : AppText.descriptionMain(
            title,
            color: titleColor,
          );
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
                head: getTitleWidgetByState(state),
                description: description,
                isHidingAccessory: (forcedHidingAccessory || onTap == null),
              ),
            );
          case TapState.hover:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppPanelLayout.hovered(
                head: getTitleWidgetByState(state),
                description: description,
                isHidingAccessory: (forcedHidingAccessory || onTap == null),
              ),
            );
          case TapState.pressed:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppPanelLayout.pressed(
                head: getTitleWidgetByState(state),
                description: description,
                isHidingAccessory: (forcedHidingAccessory || onTap == null),
              ),
            );
          case TapState.disabled:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppPanelLayout.disabled(
                head: getTitleWidgetByState(state),
                description: description,
                isHidingAccessory: (forcedHidingAccessory || onTap == null),
              ),
            );
        }
      },
    );
  }
}
