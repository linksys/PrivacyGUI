import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_advanced_feature_state.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_advanced_settings.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_advanced_status.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_settings_settings.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_settings_status.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_advanced_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_state.dart';

class FixedWifiSettingsNotifier extends UspWifiSettingsNotifier {
  final UspWifiSettingsState _fixedState;

  FixedWifiSettingsNotifier(this._fixedState);

  @override
  UspWifiSettingsState build() => _fixedState;

  @override
  Future<(WifiSettingsSettings?, WifiSettingsStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async =>
      (null, null);

  @override
  Future<void> performSave() async {}
}

class FixedWifiAdvancedNotifier extends UspWifiAdvancedNotifier {
  final WifiAdvancedFeatureState _fixedState;

  FixedWifiAdvancedNotifier(this._fixedState);

  @override
  WifiAdvancedFeatureState build() => _fixedState;

  @override
  Future<(WifiAdvancedSettings?, WifiAdvancedStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async =>
      (null, null);

  @override
  Future<void> performSave() async {}

  @override
  void setDfsEnabled(bool enabled) {}
}

List<Override> wifiSettingsOverrides({
  required UspWifiSettingsState wifiState,
  required WifiAdvancedFeatureState advancedState,
}) =>
    [
      uspWifiSettingsProvider
          .overrideWith(() => FixedWifiSettingsNotifier(wifiState)),
      uspWifiAdvancedProvider
          .overrideWith(() => FixedWifiAdvancedNotifier(advancedState)),
    ];
