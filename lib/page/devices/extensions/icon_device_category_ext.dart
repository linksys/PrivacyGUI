import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:linksys_app/core/utils/icon_device_category.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';

extension IconDeviceCategoryExt on IconDeviceCategory {
  IconData reslove() => switch (this) {
        IconDeviceCategory.mobile => LinksysIcons.phoneIphone,
        IconDeviceCategory.desktop => LinksysIcons.computer,
        IconDeviceCategory.tv => LinksysIcons.tvGen,
        IconDeviceCategory.vacuum => LinksysIcons.vacuum,
        IconDeviceCategory.gameConsole => LinksysIcons.stadiaController,
        IconDeviceCategory.plug => LinksysIcons.outlet,
        _ => LinksysIcons.devices,
      };

  static IconData resloveByName(String name) {
    final category =
        IconDeviceCategory.values.firstWhereOrNull((e) => e.name == name) ??
            IconDeviceCategory.unknown;
    return category.reslove();
  }
}
