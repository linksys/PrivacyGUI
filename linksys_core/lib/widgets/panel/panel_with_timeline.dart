part of 'panel_bases.dart';

class AppPanelWithTimeline extends StatelessWidget {
  final String title;
  final String? description;
  final String time;
  final String profileName;
  final ImageProvider? brandImage;
  final ImageProvider? profileImage;

  const AppPanelWithTimeline({
    Key? key,
    required this.title,
    this.description,
    required this.time,
    required this.profileName,
    this.brandImage,
    this.profileImage,
  }) : super(key: key);

  Widget get _titleWidget => AppText.descriptionMain(title);

  Widget? _getDescriptionWidget(BuildContext context) {
    final description = this.description;
    return description != null
        ? AppText.descriptionMain(description,
        color: AppTheme.of(context).colors.ctaPrimaryDisable)
        : null;
  }

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
                description: _getDescriptionWidget(context),
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
                description: _getDescriptionWidget(context),
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
                description: _getDescriptionWidget(context),
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
                description: _getDescriptionWidget(context),
                iconOne: _getBrandImage(context),
                isHidingAccessory: true,
              ),
            );
        }
      },
    );
  }
}
