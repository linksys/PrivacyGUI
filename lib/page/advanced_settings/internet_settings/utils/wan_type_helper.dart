import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';

String getWanConnectedTypeText(BuildContext context, String type) {
  return switch (type) {
    'DHCP' => loc(context).connectionTypeDhcp,
    'Static' => loc(context).connectionTypeStatic,
    'PPPoE' => loc(context).connectionTypePppoe,
    'PPTP' => loc(context).connectionTypePptp,
    'L2TP' => loc(context).connectionTypeL2tp,
    'Bridge' => loc(context).connectionTypeBridge,
    'Automatic' => loc(context).connectionTypeAutomatic,
    'Pass-through' => loc(context).connectionTypePassThrough,
    _ => ''
  };
}
