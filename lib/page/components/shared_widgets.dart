import 'package:flutter/material.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/utils.dart';
import 'package:ui_kit_library/ui_kit.dart';

abstract class SharedWidgets {
  static Widget resolveSignalStrengthIcon(
      BuildContext context, int signalStrength,
      {bool isOnline = true, bool isWired = false}) {
    return AppIcon.font(
      !isOnline
          ? AppFontIcons.signalWifiNone
          : isWired
              ? WiFiUtils.getWifiSignalIconData(context, null)
              : WiFiUtils.getWifiSignalIconData(context, signalStrength),
      color: !isOnline
          ? Theme.of(context).colorScheme.outline
          : getWifiSignalLevel(isWired ? null : signalStrength)
              .resolveColor(context),
    );
  }

  static Widget resolveRouterImage(BuildContext context, String iconName,
      {double size = 40}) {
    return AppImage.provider(
      imageProvider: DeviceImageHelper.getRouterImage(iconName, xl: size > 80),
      width: size,
      height: size,
    );
  }

  static Widget nodeFirmwareStatusWidget(
    BuildContext context,
    bool hasNewFirmware, [
    VoidCallback? onTap,
    bool isOffline = false,
  ]) {
    return InkWell(
      onTap: hasNewFirmware ? onTap : null,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AppIcon.font(
            hasNewFirmware ? AppFontIcons.cloudDownload : AppFontIcons.check,
            color: hasNewFirmware
                ? Theme.of(context).colorScheme.error
                : Theme.of(context)
                        .extension<AppColorScheme>()
                        ?.semanticSuccess ??
                    Colors.green,
            size: 20,
          ),
          Padding(
            padding: EdgeInsets.only(left: AppSpacing.sm),
            child: AppText.labelMedium(
              hasNewFirmware
                  ? loc(context).updateAvailable
                  : loc(context).upToDate,
              color: hasNewFirmware
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context)
                          .extension<AppColorScheme>()
                          ?.semanticSuccess ??
                      Colors.green,
            ),
          )
        ],
      ),
    );
  }

  static Widget geolocationWidget(
      BuildContext context, String name, String location) {
    return AppStyledText(text: '<b>$name</b> • $location');
  }
}
