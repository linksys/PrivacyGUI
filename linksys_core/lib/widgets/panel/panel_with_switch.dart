part of 'panel_bases.dart';

class AppPanelWithSwitch extends StatefulWidget {
  final bool value;
  final String title;
  final String? description;
  final ImageProvider? image;
  final Function(bool)? onChangedEvent;
  final VoidCallback? onInfoEvent;

  const AppPanelWithSwitch({
    Key? key,
    required this.value,
    required this.title,
    this.description,
    this.image,
    this.onChangedEvent,
    this.onInfoEvent,
  }) : super(key: key);

  @override
  State<AppPanelWithSwitch> createState() => _AppPanelWithSwitchState();
}

class _AppPanelWithSwitchState extends State<AppPanelWithSwitch> {
  bool _value = false;
  Widget get _titleWidget => AppText.descriptionMain(widget.title);

  Widget? _getDescriptionWidget(BuildContext context) {
    final description = widget.description;
    return description != null
        ? AppText.descriptionMain(description,
        color: AppTheme.of(context).colors.ctaPrimaryDisable)
        : null;
  }

  Widget _getSwitchWidget(BuildContext context) {
    final onChangedEvent = widget.onChangedEvent;
    final onInfoEvent = widget.onInfoEvent;

    return Row(children: [
      if (onInfoEvent != null)
        AppIconButton(
          icon: AppTheme.of(context).icons.characters.infoRound,
          padding: const AppEdgeInsets.only(right: AppGapSize.semiSmall),
          onTap: onInfoEvent,
        ),
      AppSwitch.full(
        value: _value,
        onChanged: (newValue) {
          setState(() {
            _value = newValue;
            if (onChangedEvent != null) onChangedEvent(_value);
          });
        },
      )
    ]);
  }

  Widget? _getImage(BuildContext context) {
    final image = widget.image;
    if (image != null) {
      return ClipRRect(
        borderRadius: AppTheme.of(context).radius.asBorderRadius().small,
        child: Image(
          image: image,
          width: 40,
          height: 40, //TODO: Check Image size spec.
        ),
      );
    }
    return null;
  }

  @override
  void initState() {
    _value = widget.value;
    super.initState();
  }

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
                head: _titleWidget,
                tail: _getSwitchWidget(context),
                description: _getDescriptionWidget(context),
                iconOne: _getImage(context),
                isHidingAccessory: true,
              ),
            );
          case TapState.hover:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppPanelLayout.hovered(
                head: _titleWidget,
                tail: _getSwitchWidget(context),
                description: _getDescriptionWidget(context),
                iconOne: _getImage(context),
                isHidingAccessory: true,
              ),
            );
          case TapState.pressed:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppPanelLayout.pressed(
                head: _titleWidget,
                tail: _getSwitchWidget(context),
                description: _getDescriptionWidget(context),
                iconOne: _getImage(context),
                isHidingAccessory: true,
              ),
            );
          case TapState.disabled:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppPanelLayout.disabled(
                head: _titleWidget,
                tail: _getSwitchWidget(context),
                description: _getDescriptionWidget(context),
                iconOne: _getImage(context),
                isHidingAccessory: true,
              ),
            );
        }
      },
    );
  }
}
