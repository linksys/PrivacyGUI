import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/wan_settings.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv4_settings_handler.dart';
import 'package:privacy_gui/utils.dart';

class PppoeSettingsHandler implements Ipv4SettingsHandler {
  @override
  WanType get wanType => WanType.pppoe;

  @override
  Ipv4Setting getIpv4Setting(RouterWANSettings? wanSettings) {
    final pppoeSettings = wanSettings?.pppoeSettings;
    const defaultConnectionBehavior = PPPConnectionBehavior.keepAlive;
    const defaultMaxIdleMinutes = 15;
    const defaultReconnectAfterSeconds = 30;

    return Ipv4Setting(
      ipv4ConnectionType: WanType.pppoe.type,
      mtu: wanSettings?.mtu ?? 0,
      behavior: pppoeSettings != null
          ? PPPConnectionBehavior.resolve(pppoeSettings.behavior) ??
              defaultConnectionBehavior
          : defaultConnectionBehavior,
      maxIdleMinutes: pppoeSettings?.maxIdleMinutes ?? defaultMaxIdleMinutes,
      reconnectAfterSeconds:
          pppoeSettings?.reconnectAfterSeconds ?? defaultReconnectAfterSeconds,
      username: pppoeSettings?.username,
      password: pppoeSettings?.password,
      serviceName: pppoeSettings?.serviceName,
      wanTaggingSettingsEnable: wanSettings?.wanTaggingSettings?.isEnabled,
      vlanId: wanSettings?.wanTaggingSettings?.vlanTaggingSettings?.vlanID,
    );
  }

  @override
  RouterWANSettings createWanSettings(Ipv4Setting ipv4Setting) {
    final mtu = NetworkUtils.isMtuValid(wanType.type, ipv4Setting.mtu)
        ? ipv4Setting.mtu
        : 0;
    final behavior = ipv4Setting.behavior ?? PPPConnectionBehavior.keepAlive;
    final vlanId = ipv4Setting.vlanId;
    bool wanTaggingSettingsEnabled = false;
    if (vlanId != null) {
      wanTaggingSettingsEnabled = (vlanId >= 5) && (vlanId <= 4094);
    }

    return RouterWANSettings.pppoe(
      mtu: mtu,
      pppoeSettings: PPPoESettings(
        username: ipv4Setting.username ?? '',
        password: ipv4Setting.password ?? '',
        serviceName: ipv4Setting.serviceName ?? '',
        behavior: behavior.value,
        maxIdleMinutes: behavior == PPPConnectionBehavior.connectOnDemand
            ? ipv4Setting.maxIdleMinutes ?? 15
            : null,
        reconnectAfterSeconds: behavior == PPPConnectionBehavior.keepAlive
            ? ipv4Setting.reconnectAfterSeconds ?? 30
            : null,
      ),
      wanTaggingSettings: SinglePortVLANTaggingSettings(
        isEnabled: wanTaggingSettingsEnabled,
        vlanTaggingSettings: wanTaggingSettingsEnabled
            ? PortTaggingSettings(
                vlanID: ipv4Setting.vlanId ?? 5,
                vlanStatus: TaggingStatus.tagged.value,
              )
            : null,
      ),
    );
  }

  @override
  MapEntry<JNAPAction, Map<String, dynamic>>? getAdditionalSetting() {
    return null;
  }

  @override
  Ipv4Setting updateIpv4Setting(
      Ipv4Setting currentSetting, Ipv4Setting newValues) {
    const defaultConnectionBehavior = PPPConnectionBehavior.keepAlive;
    const defaultMaxIdleMinutes = 15;
    const defaultReconnectAfterSeconds = 30;

    return currentSetting.copyWith(
      ipv4ConnectionType: newValues.ipv4ConnectionType,
      username: () => newValues.username,
      password: () => newValues.password,
      serviceName: () => newValues.serviceName,
      behavior: () => newValues.behavior ?? defaultConnectionBehavior,
      maxIdleMinutes: () => newValues.maxIdleMinutes ?? defaultMaxIdleMinutes,
      reconnectAfterSeconds: () =>
          newValues.reconnectAfterSeconds ?? defaultReconnectAfterSeconds,
      wanTaggingSettingsEnable: () => newValues.wanTaggingSettingsEnable,
      vlanId: () => newValues.vlanId,
    );
  }
}
