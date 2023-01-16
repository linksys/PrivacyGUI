part of 'panel_bases.dart';

class AppPanelWithValueCheck extends StatelessWidget {
  final String title;
  final String valueText;
  final Color? valueTextColor;
  final bool isChecked;

  const AppPanelWithValueCheck({
    Key? key,
    required this.title,
    required this.valueText,
    this.valueTextColor,
    this.isChecked = false,
  }) : super(key: key);

  Widget getValueWidget(BuildContext context) {
    return Row(children: [
      AppText.descriptionMain(
        valueText,
        color: valueTextColor,
      ),
      if (isChecked)
        AppPadding(
          padding: const AppEdgeInsets.only(
            left: AppGapSize.semiSmall,
          ),
          child: AppIcon.regular(
            icon: AppTheme.of(context).icons.characters.checkDefault,
          ),
        )
    ]);
  }

  Widget get titleWidget => AppText.descriptionMain(title);

  @override
  Widget build(BuildContext context) {
    return TapBuilder(
      builder: (context, state, hasFocus) {
        switch (state) {
          case TapState.inactive:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppPanelLayout.inactive(
                head: titleWidget,
                tail: getValueWidget(context),
                isHidingAccessory: true,
              ),
            );
          case TapState.hover:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppPanelLayout.hovered(
                head: titleWidget,
                tail: getValueWidget(context),
                isHidingAccessory: true,
              ),
            );
          case TapState.pressed:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppPanelLayout.pressed(
                head: titleWidget,
                tail: getValueWidget(context),
                isHidingAccessory: true,
              ),
            );
          case TapState.disabled:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppPanelLayout.disabled(
                head: titleWidget,
                tail: getValueWidget(context),
                isHidingAccessory: true,
              ),
            );
        }
      },
    );
  }
}
