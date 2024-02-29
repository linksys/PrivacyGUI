import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:linksys_app/core/utils/icon_device_category.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:material_symbols_icons/symbols.dart';

extension IconDeviceCategoryExt on IconDeviceCategory {
  IconData reslove() => switch (this) {
        IconDeviceCategory.mobile => Symbols.phone_iphone,
        IconDeviceCategory.desktop => Symbols.computer,
        IconDeviceCategory.tv => Symbols.tv,
        IconDeviceCategory.vacuum => Symbols.vacuum,
        IconDeviceCategory.gameConsole => Symbols.stadia_controller,
        IconDeviceCategory.plug => Symbols.outlet,
        _ => Symbols.devices,
      };

  static IconData resloveByName(String name) {
    final category =
        IconDeviceCategory.values.firstWhereOrNull((e) => e.name == name) ??
            IconDeviceCategory.unknown;
    return category.reslove();
  }
}
