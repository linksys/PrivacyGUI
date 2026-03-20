import 'package:flutter/material.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';

class WiFiUtils {
  static IconData getWifiSignalIconData(
      BuildContext context, int? signalStrength) {
    switch (getWifiSignalLevel(signalStrength)) {
      case NodeSignalLevel.excellent:
        return AppFontIcons.signalWifi4Bar;
      case NodeSignalLevel.good:
        return AppFontIcons.networkWifi3Bar;
      case NodeSignalLevel.fair:
        return AppFontIcons.networkWifi2Bar;
      case NodeSignalLevel.poor:
        return AppFontIcons.networkWifi1Bar;
      case NodeSignalLevel.none:
        return AppFontIcons.signalWifi0Bar;
      case NodeSignalLevel.wired:
        return AppFontIcons.ethernet;
    }
  }
}

extension NodeSignalLevelExt on NodeSignalLevel {
  String resolveLabel(BuildContext context) {
    return switch (this) {
      NodeSignalLevel.excellent => loc(context).excellent,
      NodeSignalLevel.good => loc(context).good,
      NodeSignalLevel.poor => loc(context).poor,
      NodeSignalLevel.fair => loc(context).fair,
      NodeSignalLevel.wired => loc(context).wired,
      NodeSignalLevel.none => '',
    };
  }

  Color? resolveColor(BuildContext context) {
    final appColorScheme = Theme.of(context).extension<AppColorScheme>();
    return switch (this) {
      NodeSignalLevel.excellent =>
        appColorScheme?.semanticSuccess ?? Colors.green,
      NodeSignalLevel.good => appColorScheme?.semanticSuccess ?? Colors.green,
      NodeSignalLevel.poor => Theme.of(context).colorScheme.error,
      NodeSignalLevel.fair => Theme.of(context).colorScheme.error,
      NodeSignalLevel.wired => Theme.of(context).colorScheme.onSurface,
      NodeSignalLevel.none => Colors.black,
    };
  }
}
