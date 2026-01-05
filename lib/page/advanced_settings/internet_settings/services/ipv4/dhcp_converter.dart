import 'package:privacy_gui/core/jnap/models/wan_settings.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/_models.dart';

class DhcpConverter {
  static Ipv4SettingsUIModel fromJNAP(RouterWANSettings? wanSettings) {
    return Ipv4SettingsUIModel(
      ipv4ConnectionType: 'DHCP',
      mtu: wanSettings?.mtu ?? 0,
    );
  }

  static RouterWANSettings toJNAP(Ipv4SettingsUIModel uiModel) {
    const disabledWanTaggingSettings =
        SinglePortVLANTaggingSettings(isEnabled: false);
    return RouterWANSettings.dhcp(
      mtu: uiModel.mtu,
      wanTaggingSettings: disabledWanTaggingSettings,
    );
  }

  static Ipv4SettingsUIModel updateFromForm(
      Ipv4SettingsUIModel currentSetting, Ipv4SettingsUIModel newValues) {
    return currentSetting.copyWith(
      ipv4ConnectionType: newValues.ipv4ConnectionType,
    );
  }
}
