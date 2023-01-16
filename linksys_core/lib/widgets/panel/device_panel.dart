part of 'panel_bases.dart';
/*
class AppDevicePanel extends StatelessWidget {
  final Widget title;
  final String? description;
  final ImageProvider? deviceImage;
  final ImageProvider? signalImage;

  const AppDevicePanel({
    Key? key,
    required this.title,
    this.description,
    this.deviceImage,
    this.signalImage,
  }) : super(key: key);

  factory AppDevicePanel.offline({
    required String title,
    ImageProvider? deviceImage,
  }) {
    return AppDevicePanel(
      title: AppText.descriptionMain(
        title,
        color: ,
      ),
      deviceImage: deviceImage,
    );
  }

  Widget get _titleWidget => AppText.descriptionMain(title);

  Widget _getTimelineWidget(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AppText.descriptionSub(
          time,
          color: AppTheme.of(context).colors.ctaPrimaryDisable,
        ),
        Row(
          children: [
            if (profileImage != null) AppPadding(
              padding: const AppEdgeInsets.only(
                right: AppGapSize.semiSmall,
              ),
              child: Image(
                image: profileImage!,
                width: 16,
                height: 16, //TODO: Check Image size spec.
              ),
            ),
            AppText.descriptionMain(
              profileName,
            )
          ],
        )
      ],
    );
  }

  Widget? _getBrandImage(BuildContext context) {
    final image = brandImage;
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
                tail: _getTimelineWidget(context),
                description: description,
                iconOne: _getBrandImage(context),
                isHidingAccessory: true,
              ),
            );
          case TapState.hover:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppPanelLayout.hovered(
                head: _titleWidget,
                tail: _getTimelineWidget(context),
                description: description,
                iconOne: _getBrandImage(context),
                isHidingAccessory: true,
              ),
            );
          case TapState.pressed:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppPanelLayout.pressed(
                head: _titleWidget,
                tail: _getTimelineWidget(context),
                description: description,
                iconOne: _getBrandImage(context),
                isHidingAccessory: true,
              ),
            );
          case TapState.disabled:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppPanelLayout.disabled(
                head: _titleWidget,
                tail: _getTimelineWidget(context),
                description: description,
                iconOne: _getBrandImage(context),
                isHidingAccessory: true,
              ),
            );
        }
      },
    );
  }
}

 */
