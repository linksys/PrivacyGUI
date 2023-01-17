part of 'panel_bases.dart';

enum AppDevicePanelStyle {
  normal,
  speed,
  bandwidth,
  offline,
}

class AppDevicePanel extends StatelessWidget {
  final AppDevicePanelStyle style;
  final String title;
  final String? place;
  final String? frequency;
  final ImageProvider? deviceImage;
  final ImageProvider? signalImage;
  final double? upload;
  final double? download;
  final double? bandwidth;

  const AppDevicePanel({
    Key? key,
    required this.style,
    required this.title,
    this.place,
    this.frequency,
    this.deviceImage,
    this.signalImage,
    this.upload,
    this.download,
    this.bandwidth,
  }) : super(key: key);

  factory AppDevicePanel.normal({
    required String title,
    required String place,
    required String frequency,
    required ImageProvider deviceImage,
    required ImageProvider signalImage,
  }) {
    return AppDevicePanel(
      style: AppDevicePanelStyle.normal,
      title: title,
      place: place,
      frequency: frequency,
      deviceImage: deviceImage,
      signalImage: signalImage,
    );
  }

  factory AppDevicePanel.speed({
    required String title,
    required String place,
    required String frequency,
    required ImageProvider deviceImage,
    required ImageProvider signalImage,
    required double upload,
    required double download,
  }) {
    return AppDevicePanel(
      style: AppDevicePanelStyle.speed,
      title: title,
      place: place,
      frequency: frequency,
      deviceImage: deviceImage,
      signalImage: signalImage,
      upload: upload,
      download: download,
    );
  }

  factory AppDevicePanel.bandwidth({
    required String title,
    required ImageProvider deviceImage,
    required double bandwidth,
  }) {
    return AppDevicePanel(
      style: AppDevicePanelStyle.bandwidth,
      title: title,
      deviceImage: deviceImage,
      bandwidth: bandwidth,
    );
  }

  factory AppDevicePanel.offline({
    required String title,
    required ImageProvider deviceImage,
  }) {
    return AppDevicePanel(
      style: AppDevicePanelStyle.offline,
      title: title,
      deviceImage: deviceImage,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget titleWidget;
    Widget? descriptionWidget;
    Widget? deviceImageWidget;
    Widget? signalImageWidget;
    Widget? tailWidget;

    Widget? getDescriptionWidget() {
      final place = this.place;
      final frequency = this.frequency;

      List<Widget> children = [];
      if (place != null) {
        children.add(AppText.descriptionSub(
          place,
          color: AppTheme.of(context).colors.ctaPrimaryDisable,
        ));
      }
      if (frequency != null) {
        children.add(AppText.descriptionSub(
          frequency,
          color: AppTheme.of(context).colors.ctaPrimaryDisable,
        ));
      }

      return children.isNotEmpty ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ) : null;
    }

    switch (style) {
      case AppDevicePanelStyle.normal:
        titleWidget = AppText.descriptionMain(
          title,
        );
        descriptionWidget = getDescriptionWidget();
        deviceImageWidget = Image(
          image: deviceImage!,
          width: 50,
          height: 50,
        );
        signalImageWidget = Image(
          image: signalImage!,
          width: 24,
          height: 24,
        );
        break;
      case AppDevicePanelStyle.speed:
        titleWidget = AppText.descriptionMain(
          title,
        );
        descriptionWidget = getDescriptionWidget();
        deviceImageWidget = Image(
          image: deviceImage!,
          width: 50,
          height: 50,
        );
        signalImageWidget = Image(
          image: signalImage!,
          width: 24,
          height: 24,
        );
        tailWidget = Row(
          children: [
            AppIcon(
              icon: AppTheme.of(context).icons.characters.arrowDown,
              color: ConstantColors.secondaryElectricGreen,
            ),
            const AppGap.small(),
            AppText.descriptionMain(
              '$download',
            ),
            const AppGap.semiSmall(),
            AppIcon(
              icon: AppTheme.of(context).icons.characters.arrowUp,
              color: ConstantColors.secondaryCyberPurple,
            ),
            const AppGap.small(),
            AppText.descriptionMain(
              '$upload',
            ),
          ],
        );
        break;
      case AppDevicePanelStyle.bandwidth:
        titleWidget = AppText.descriptionMain(
          title,
        );
        deviceImageWidget = Image(
          image: deviceImage!,
          width: 50,
          height: 50,
        );
        tailWidget = Row(
          children: [
            AppText.descriptionMain(
              '$bandwidth',
              color: ConstantColors.primaryLinksysWhite,
            ),
            const AppGap.small(),
            AppText.descriptionMain(
              'MB',
              color: AppTheme.of(context).colors.textBoxStrokeHovered,
            ),
          ],
        );
        break;
      case AppDevicePanelStyle.offline:
        titleWidget = AppText.descriptionMain(
          title,
          color: AppTheme.of(context).colors.ctaPrimaryDisable,
        );
        deviceImageWidget = Image(
          image: deviceImage!,
          width: 50,
          height: 50,
        );
        break;
    }

    return TapBuilder(
      builder: (context, state, hasFocus) {
        switch (state) {
          case TapState.inactive:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppPanelLayout.inactive(
                head: titleWidget,
                tail: tailWidget,
                description: descriptionWidget,
                iconOne: deviceImageWidget,
                iconTwo: signalImageWidget,
                isHidingAccessory: true,
              ),
            );
          case TapState.hover:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppPanelLayout.hovered(
                head: titleWidget,
                tail: tailWidget,
                description: descriptionWidget,
                iconOne: deviceImageWidget,
                iconTwo: signalImageWidget,
                isHidingAccessory: true,
              ),
            );
          case TapState.pressed:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppPanelLayout.pressed(
                head: titleWidget,
                tail: tailWidget,
                description: descriptionWidget,
                iconOne: deviceImageWidget,
                iconTwo: signalImageWidget,
                isHidingAccessory: true,
              ),
            );
          case TapState.disabled:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppPanelLayout.disabled(
                head: titleWidget,
                tail: tailWidget,
                description: descriptionWidget,
                iconOne: deviceImageWidget,
                iconTwo: signalImageWidget,
                isHidingAccessory: true,
              ),
            );
        }
      },
    );
  }
}
