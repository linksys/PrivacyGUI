import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/utils/device_classifier.dart';

/// UI extensions for [DeviceCategory].
extension DeviceCategoryUi on DeviceCategory {
  /// The category's name in the user's language. [DeviceCategory.displayName]
  /// is English only.
  String resolveLabel(BuildContext context) {
    final l = loc(context);
    return switch (this) {
      DeviceCategory.phone => l.deviceCategoryPhone,
      DeviceCategory.tablet => l.deviceCategoryTablet,
      DeviceCategory.computer => l.deviceCategoryComputer,
      DeviceCategory.tv => l.deviceCategoryTv,
      DeviceCategory.gameConsole => l.deviceCategoryGameConsole,
      DeviceCategory.mediaPlayer => l.deviceCategoryMediaPlayer,
      DeviceCategory.smartSpeaker => l.deviceCategorySmartSpeaker,
      DeviceCategory.camera => l.deviceCategoryCamera,
      DeviceCategory.printer => l.deviceCategoryPrinter,
      DeviceCategory.networkDevice => l.deviceCategoryNetworkDevice,
      DeviceCategory.iot => l.deviceCategorySmartHome,
      DeviceCategory.wearable => l.deviceCategoryWearable,
      DeviceCategory.unknown => l.unknown,
    };
  }
}
