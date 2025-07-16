import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';

enum NodeInstantActions {
  reboot,
  pair(true, [pairWired, pairWireless]),
  pairWired,
  pairWireless,
  blink,
  reset,
  ;

  final bool isSub;
  final List<NodeInstantActions> subActions;
  const NodeInstantActions([this.isSub = false, this.subActions = const []]);

  String resolveLabel(BuildContext context) => switch (this) {
        reboot => loc(context).rebootUnit,
        pair => loc(context).instantPair,
        pairWired => loc(context).pairWiredNode,
        pairWireless => loc(context).pairWirelessNode,
        blink => loc(context).blinkDeviceLight,
        reset => loc(context).resetToFactoryDefault,
      };
}
