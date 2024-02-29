import 'package:flutter/material.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_state.dart';
import 'package:material_symbols_icons/symbols.dart';

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
      return Symbols.signal_wifi_4_bar;
    case NodeSignalLevel.good:
      return Symbols.network_wifi_3_bar;
    case NodeSignalLevel.fair:
      return Symbols.network_wifi_2_bar;
    case NodeSignalLevel.weak:
      return Symbols.network_wifi_1_bar;
    case NodeSignalLevel.none:
            return Symbols.signal_wifi_0_bar;
// Default
    case NodeSignalLevel.wired:
      return Symbols.settings_ethernet;
  }
}
