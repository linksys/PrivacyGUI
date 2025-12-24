import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:privacy_gui/core/utils/icon_device_category.dart';
import 'package:ui_kit_library/ui_kit.dart';

extension IconDeviceCategoryExt on IconDeviceCategory {
  IconData reslove() => switch (this) {
        IconDeviceCategory.ethernet => AppFontIcons.ethernet,
        IconDeviceCategory.phone => AppFontIcons.smartPhone,
        IconDeviceCategory.computer => AppFontIcons.computer,
        IconDeviceCategory.tv => AppFontIcons.smartTv,
        IconDeviceCategory.speaker => AppFontIcons.musicSpeaker,
        IconDeviceCategory.camera => AppFontIcons.camera,
        IconDeviceCategory.doorbell => AppFontIcons.doorbell,
        IconDeviceCategory.lock => AppFontIcons.smartLock,
        IconDeviceCategory.watch => AppFontIcons.smartWatch,
        IconDeviceCategory.plug => AppFontIcons.smartPlug,
        IconDeviceCategory.bulb => AppFontIcons.lightBulb,
        IconDeviceCategory.vacuum => AppFontIcons.vacuum,
        IconDeviceCategory.gameConsole => AppFontIcons.stadiaController,
        _ => AppFontIcons.genericDevice,
      };

  static IconData resolveByName(String name) {
    final category =
        IconDeviceCategory.values.firstWhereOrNull((e) => e.name == name) ??
            IconDeviceCategory.unknown;
    return category.reslove();
  }
}
