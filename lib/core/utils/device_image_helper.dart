import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Device image helper to get router images using ui_kit Assets
///
/// Replaces the functionality of CustomTheme.getRouterImage() and getByName()
/// from privacygui_widgets with ui_kit Assets-based implementation.
class DeviceImageHelper {
  /// Get router image by model name with size preference
  ///
  /// [modelName] - The model name returned by routerIconTestByModel()
  /// [xl] - Whether to prefer XL size (120x120) over standard size (100x100)
  ///
  /// Returns an ImageProvider for the router image, fallback to MX6200 if not found
  static ImageProvider getRouterImage(String modelName, {bool xl = true}) {
    // Try XL first if preferred, then fallback to standard
    if (xl) {
      final xlImage = _getDeviceXlImage(modelName);
      if (xlImage != null) return xlImage;
    }

    // Try standard size
    final standardImage = _getDeviceImage(modelName);
    if (standardImage != null) return standardImage;

    // Fallback to MX6200 (default router)
    return _getDeviceImage('routerMx6200') ??
        _getDeviceXlImage('routerMx6200') ??
        _getGenericRouterImage(); // Ultimate fallback to generic router
  }

  /// Get generic router image as fallback
  static ImageProvider _getGenericRouterImage() {
    return Assets.images.devices.routerMx6200.provider();
  }

  /// Get standard device image (100x100) by model name
  static ImageProvider? _getDeviceImage(String modelName) {
    switch (modelName) {
      case 'routerWhw01':
        return Assets.images.devices.routerWhw01.provider();
      case 'routerWhw03':
        return Assets.images.devices.routerWhw03.provider();
      case 'routerMr7350':
        return Assets.images.devices.routerMr7350.provider();
      case 'routerEa8300':
        return Assets.images.devices.routerEa8300.provider();
      case 'routerMx6200':
        return Assets.images.devices.routerMx6200.provider();
      case 'routerWhw03b':
        return Assets.images.devices.routerWhw03b.provider();
      case 'routerEa9350':
        return Assets.images.devices.routerEa9350.provider();
      case 'routerLn12':
        return Assets.images.devices.routerLn12.provider();
      case 'routerWhw01p':
        return Assets.images.devices.routerWhw01p.provider();
      case 'routerLn11':
        return Assets.images.devices.routerLn11.provider();
      case 'routerMx5300':
        return Assets.images.devices.routerMx5300.provider();
      case 'routerWhw01b':
        return Assets.images.devices.routerWhw01b.provider();
      case 'routerMr7500':
        return Assets.images.devices.routerMr7500.provider();
      case 'routerMr6350':
        return Assets.images.devices.routerMr6350.provider();
      default:
        return null;
    }
  }

  /// Get XL device image (120x120) by model name
  static ImageProvider? _getDeviceXlImage(String modelName) {
    switch (modelName) {
      case 'routerMx6200':
        return Assets.images.devicesXl.routerMx6200.provider();
      case 'routerLn12':
        return Assets.images.devicesXl.routerLn12.provider();
      // Add more XL variants as they become available in ui_kit
      default:
        return null;
    }
  }
}
