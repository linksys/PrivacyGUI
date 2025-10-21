import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_advanced_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';

import 'instant_privacy_test_state.dart';
import 'wifi_advanced_settings_test_state.dart';
import 'wifi_list_test_state.dart';

// This file composes the individual test states into a single bundle
// for testing the new consolidated WifiBundleState.

final wifiBundleTestState = {
  'settings': {
    'wifiList': WiFiListSettings.fromMap(wifiListTestState).toMap(),
    'advanced': WifiAdvancedSettingsState.fromMap(wifiAdvancedSettingsTestState).toMap(),
    'privacy': InstantPrivacySettings.fromMap(instantPrivacyTestState['settings']?['original'] as Map<String, dynamic>).toMap(),
  },
  'status': {
    'wifiList': WiFiListStatus.fromMap({'canDisableMainWiFi': wifiListTestState['canDisableMainWiFi']}).toMap(),
    'privacy': InstantPrivacyStatus.fromMap(instantPrivacyTestState['status'] as Map<String, dynamic>).toMap(),
  }
};
