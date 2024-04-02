import 'package:flutter/material.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_state.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';

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

//! TODO move out from core libs
IconData getWifiSignalIconData(BuildContext context, int? signalStrength) {
  switch (getWifiSignalLevel(signalStrength)) {
    case NodeSignalLevel.excellent:
      return LinksysIcons.signalWifi4Bar;
    case NodeSignalLevel.good:
      return LinksysIcons.networkWifi3Bar;
    case NodeSignalLevel.fair:
      return LinksysIcons.networkWifi2Bar;
    case NodeSignalLevel.weak:
      return LinksysIcons.networkWifi1Bar;
    case NodeSignalLevel.none:
            return LinksysIcons.signalWifi0Bar;
// Default
    case NodeSignalLevel.wired:
      return LinksysIcons.ethernet;
  }
}
