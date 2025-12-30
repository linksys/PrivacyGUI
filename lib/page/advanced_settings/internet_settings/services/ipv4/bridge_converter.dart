import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/remote_setting.dart';
import 'package:privacy_gui/core/jnap/models/wan_settings.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/_models.dart';

class BridgeConverter {
  static Ipv4SettingsUIModel fromJNAP(RouterWANSettings? wanSettings) {
    return Ipv4SettingsUIModel(
      ipv4ConnectionType: WanType.bridge.type,
      mtu: wanSettings?.mtu ?? 0,
    );
  }

  static RouterWANSettings toJNAP(Ipv4SettingsUIModel uiModel) {
    const disabledWanTaggingSettings =
        SinglePortVLANTaggingSettings(isEnabled: false);

    return RouterWANSettings.bridge(
      bridgeSettings: const BridgeSettings(useStaticSettings: false),
      wanTaggingSettings: disabledWanTaggingSettings,
    );
  }

  /// Returns additional JNAP action for Bridge mode (disable remote settings)
  static MapEntry<JNAPAction, Map<String, dynamic>>? getAdditionalSetting() {
    return MapEntry(
      JNAPAction.setRemoteSetting,
      const RemoteSetting(
        isEnabled: false,
      ).toJson(),
    );
  }

  static Ipv4SettingsUIModel updateFromForm(
      Ipv4SettingsUIModel currentSetting, Ipv4SettingsUIModel newValues) {
    return currentSetting.copyWith(
      ipv4ConnectionType: newValues.ipv4ConnectionType,
      mtu: newValues.mtu,
    );
  }
}
