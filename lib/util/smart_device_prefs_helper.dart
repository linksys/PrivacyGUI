// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:shared_preferences/shared_preferences.dart';

import 'package:privacy_gui/constants/_constants.dart';

class SmartDevicesPrefsHelper {
  static String getNidKey(SharedPreferences prefs, {required String key}) {
    final nId = prefs.getString(pSelectedNetworkId);
    return '$key-$nId';
  }
}

class SmartDevicePreferenceException {
  final String code;
  SmartDevicePreferenceException({
    required this.code,
  });
}
