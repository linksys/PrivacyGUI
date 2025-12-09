import 'package:privacy_gui/core/jnap/models/ipv6_settings.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv6_settings_handler.dart';

class DefaultIpv6SettingsHandler implements Ipv6SettingsHandler {
  final WanIPv6Type _wanType;

  DefaultIpv6SettingsHandler(this._wanType);

  @override
  WanIPv6Type get wanType => _wanType;

  @override
  Ipv6Setting getIpv6Setting(GetIPv6Settings? ipv6Settings) {
    return Ipv6Setting(
      ipv6ConnectionType: _wanType.type,
      isIPv6AutomaticEnabled: ipv6Settings?.ipv6AutomaticSettings?.isIPv6AutomaticEnabled ?? false,
    );
  }

  @override
  SetIPv6Settings createSetIPv6Settings(Ipv6Setting ipv6Setting) {
    return SetIPv6Settings(wanType: _wanType.type);
  }

  @override
  Ipv6Setting updateIpv6Setting(Ipv6Setting currentSetting, Ipv6Setting newValues) {
    return currentSetting.copyWith(
      ipv6ConnectionType: newValues.ipv6ConnectionType,
    );
  }
}
