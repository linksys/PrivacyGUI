import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:privacy_gui/core/utils/icon_device_category.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';

extension IconDeviceCategoryExt on IconDeviceCategory {
  IconData reslove() => switch (this) {
        IconDeviceCategory.ethernet => LinksysIcons.ethernet,
        IconDeviceCategory.phone => LinksysIcons.smartPhone,
        IconDeviceCategory.computer => LinksysIcons.computer,
        IconDeviceCategory.tv => LinksysIcons.smartTv,
        IconDeviceCategory.speaker => LinksysIcons.musicSpeaker,
        IconDeviceCategory.camera => LinksysIcons.camera,
        IconDeviceCategory.doorbell => LinksysIcons.doorbell,
        IconDeviceCategory.lock => LinksysIcons.smartLock,
        IconDeviceCategory.watch => LinksysIcons.smartWatch,
        IconDeviceCategory.plug => LinksysIcons.smartPlug,
        IconDeviceCategory.bulb => LinksysIcons.lightBulb,
        IconDeviceCategory.vacuum => LinksysIcons.vacuum,
        IconDeviceCategory.gameConsole => LinksysIcons.stadiaController,
        _ => LinksysIcons.genericDevice,
      };

  static IconData resolveByName(String name) {
    final category =
        IconDeviceCategory.values.firstWhereOrNull((e) => e.name == name) ??
            IconDeviceCategory.unknown;
    return category.reslove();
  }
}
