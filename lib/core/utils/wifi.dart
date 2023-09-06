import 'package:flutter/material.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_state.dart';
import 'package:linksys_widgets/theme/theme.dart';

const signalThresholdSNR = [40, 25, 10];
const signalThresholdRSSI = [-60, -70, -80];

NodeSignalLevel getWifiSignalLevel(int? signalStrength) {
  if (signalStrength == null) {
    return NodeSignalLevel.wired;
  }
  var signalThreshold =
      signalStrength > 0 ? signalThresholdSNR : signalThresholdRSSI;
  var index = signalThreshold.indexWhere((element) => signalStrength > element);
  if (index == -1) {
    return NodeSignalLevel.weak;
  } else {
    switch (3 - index) {
      case 3:
        return NodeSignalLevel.excellent;
      case 2:
        return NodeSignalLevel.good;
      case 1:
        return NodeSignalLevel.fair;
      default:
        return NodeSignalLevel.none;
    }
  }
}

IconData getWifiSignalIconData(BuildContext context, int? signalStrength) {
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
