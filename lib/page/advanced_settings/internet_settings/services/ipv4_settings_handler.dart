import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/wan_settings.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';

abstract class Ipv4SettingsHandler {
  WanType get wanType;

  // For fetching settings
  Ipv4Setting getIpv4Setting(RouterWANSettings? wanSettings);

  // For creating settings to send to JNAP
  RouterWANSettings createWanSettings(Ipv4Setting ipv4Setting);
  MapEntry<JNAPAction, Map<String, dynamic>>? getAdditionalSetting();

  // For updating state based on UI input (copyWith logic)
  Ipv4Setting updateIpv4Setting(
      Ipv4Setting currentSetting, Ipv4Setting newValues);
}
