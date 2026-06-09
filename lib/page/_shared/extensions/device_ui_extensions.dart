import 'package:flutter/material.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';

/// Extension to get [IconData] for [DeviceConnectionType].
extension DeviceConnectionTypeExt on DeviceConnectionType {
  IconData get icon => switch (this) {
        DeviceConnectionType.wifi => Icons.wifi,
        DeviceConnectionType.wired => Icons.settings_ethernet,
      };
}
