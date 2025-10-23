import 'package:privacy_gui/core/jnap/models/ipv6_settings.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';

abstract class Ipv6SettingsHandler {
  WanIPv6Type get wanType;

  // For fetching settings
  Ipv6Setting getIpv6Setting(GetIPv6Settings? ipv6Settings);

  // For creating settings to send to JNAP
  SetIPv6Settings createSetIPv6Settings(Ipv6Setting ipv6Setting);

  // For updating state based on UI input (copyWith logic)
  Ipv6Setting updateIpv6Setting(Ipv6Setting currentSetting, Ipv6Setting newValues);
}
