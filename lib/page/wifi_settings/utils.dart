import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_item.dart';

String getWifiSecurityTypeTitle(BuildContext context, WifiSecurityType type) {
  final locProvider = loc(context);
  switch (type) {
    case WifiSecurityType.wpa2:
      return locProvider.wpa2;
    case WifiSecurityType.wpa3:
      return locProvider.wpa3;
    case WifiSecurityType.wpa2Wpa3:
      return locProvider.wpa2wpa3;
    case WifiSecurityType.open:
      return locProvider.open;
    default:
      return type.value;
  }
}