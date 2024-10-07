import 'package:flutter/material.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/hook/icon_hooks.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';

abstract class SharedWidgets {
  static Icon resolveSignalStrengthIcon(
      BuildContext context, int signalStrength,
      {bool isOnline = true, bool isWired = false}) {
    return Icon(
      !isOnline
          ? LinksysIcons.signalWifiNone
          : isWired
              ? WiFiUtils.getWifiSignalIconData(context, null)
              : WiFiUtils.getWifiSignalIconData(context, signalStrength),
      color: !isOnline
          ? Theme.of(context).colorScheme.outline
          : getWifiSignalLevel(isWired ? null : signalStrength)
              .resolveColor(context),
      semanticLabel: 'signal strength icon',
    );
  }

  static Image resolveRouterImage(BuildContext context, String iconName,
      {double size = 40}) {
    return Image(
      image: CustomTheme.of(context).images.devices.getByName(iconName) ??
          CustomTheme.of(context).images.devices.routerLn11,
      semanticLabel: 'router image',
      width: size,
      height: size,
    );
  }

  static Widget nodeFirmwareStatusWidget(
    BuildContext context,
    bool hasNewFirmware,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: hasNewFirmware ? onTap : null,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(
            hasNewFirmware ? LinksysIcons.cloudDownload : LinksysIcons.check,
            color: hasNewFirmware
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorSchemeExt.green,
            size: 20,
          ),
          Padding(
            padding: const EdgeInsets.only(left: Spacing.small2),
            child: AppText.labelMedium(
              hasNewFirmware
                  ? loc(context).updateAvailable
                  : loc(context).upToDate,
              color: hasNewFirmware
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorSchemeExt.green,
            ),
          )
        ],
      ),
    );
  }

  static geolocationWidget(BuildContext context, String name, String location) {
    return AppStyledText.bold('<b>$name</b> • $location',
        defaultTextStyle: Theme.of(context).textTheme.bodyMedium!, tags: const ['b']);
  }
}
