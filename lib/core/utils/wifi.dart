import 'package:flutter/material.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_state.dart';
import 'package:linksys_widgets/theme/theme.dart';

NodeSignalLevel getWifiSignalLevel(int? signalStrength) {
  if (signalStrength == null) {
    return NodeSignalLevel.wired;
  } else if (signalStrength <= -80) {
    return NodeSignalLevel.weak;
  } else if (signalStrength > -80 && signalStrength <= -70) {
    return NodeSignalLevel.fair;
  } else if (signalStrength > -70 && signalStrength <= -60) {
    return NodeSignalLevel.good;
  } else if (signalStrength > -60 && signalStrength <= 0) {
    return NodeSignalLevel.excellent;
  } else {
    return NodeSignalLevel.none;
  }
}

IconData getWifiSignalIconData(BuildContext context, int signalStrength) {
  switch (getWifiSignalLevel(signalStrength)) {
    case NodeSignalLevel.excellent:
      return AppTheme.of(context).icons.characters.signalstrength4;
    case NodeSignalLevel.good:
      return AppTheme.of(context).icons.characters.signalstrength3;
    case NodeSignalLevel.fair:
      return AppTheme.of(context).icons.characters.signalstrength2;
    case NodeSignalLevel.weak:
      return AppTheme.of(context).icons.characters.signalstrength1;
    case NodeSignalLevel.none:
      return AppTheme.of(context).icons.characters.signalstrength0; // Default
    case NodeSignalLevel.wired:
      return AppTheme.of(context).icons.characters.ethernetDefault;
  }
}
