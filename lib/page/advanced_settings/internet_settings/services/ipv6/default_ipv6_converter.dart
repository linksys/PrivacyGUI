import 'package:privacy_gui/core/jnap/models/ipv6_settings.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/_models.dart';

class DefaultIpv6Converter {
  static Ipv6SettingsUIModel fromJNAP(
      GetIPv6Settings? ipv6Settings, WanIPv6Type wanType) {
    return Ipv6SettingsUIModel(
      ipv6ConnectionType: wanType.type,
      isIPv6AutomaticEnabled:
          ipv6Settings?.ipv6AutomaticSettings?.isIPv6AutomaticEnabled ?? false,
    );
  }

  static SetIPv6Settings toJNAP(
      Ipv6SettingsUIModel uiModel, WanIPv6Type wanType) {
    return SetIPv6Settings(wanType: wanType.type);
  }

  static Ipv6SettingsUIModel updateFromForm(
      Ipv6SettingsUIModel currentSetting, Ipv6SettingsUIModel newValues) {
    return currentSetting.copyWith(
      ipv6ConnectionType: newValues.ipv6ConnectionType,
    );
  }
}
