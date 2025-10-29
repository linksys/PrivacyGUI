import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/remote_setting.dart';
import 'package:privacy_gui/core/jnap/models/wan_settings.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv4_settings_handler.dart';

class BridgeSettingsHandler implements Ipv4SettingsHandler {
  @override
  WanType get wanType => WanType.bridge;

  @override
  Ipv4Setting getIpv4Setting(RouterWANSettings? wanSettings) {
    return Ipv4Setting(
      ipv4ConnectionType: WanType.bridge.type,
      mtu: wanSettings?.mtu ?? 0,
    );
  }

  @override
  RouterWANSettings createWanSettings(Ipv4Setting ipv4Setting) {
    const diabledWanTaggingSettings =
        SinglePortVLANTaggingSettings(isEnabled: false);

    return RouterWANSettings.bridge(
      bridgeSettings: const BridgeSettings(useStaticSettings: false),
      wanTaggingSettings: diabledWanTaggingSettings,
    );
  }

  @override
  MapEntry<JNAPAction, Map<String, dynamic>>? getAdditionalSetting() {
    return MapEntry(
      JNAPAction.setRemoteSetting,
      const RemoteSetting(
        isEnabled: false,
      ).toJson(),
    );
  }

  @override
  Ipv4Setting updateIpv4Setting(
      Ipv4Setting currentSetting, Ipv4Setting newValues) {
    return currentSetting.copyWith(
      ipv4ConnectionType: newValues.ipv4ConnectionType,
      mtu: newValues.mtu,
    );
  }
}
