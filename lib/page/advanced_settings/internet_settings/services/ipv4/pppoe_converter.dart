import 'package:privacy_gui/core/jnap/models/wan_settings.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/_models.dart';
import 'package:privacy_gui/utils.dart';

class PppoeConverter {
  static Ipv4SettingsUIModel fromJNAP(RouterWANSettings? wanSettings) {
    final pppoeSettings = wanSettings?.pppoeSettings;
    const defaultConnectionBehavior = PPPConnectionBehavior.keepAlive;
    const defaultMaxIdleMinutes = 15;
    const defaultReconnectAfterSeconds = 30;

    return Ipv4SettingsUIModel(
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

  static RouterWANSettings toJNAP(Ipv4SettingsUIModel uiModel) {
    final mtu = NetworkUtils.isMtuValid(WanType.pppoe.type, uiModel.mtu)
        ? uiModel.mtu
        : 0;
    final behavior = uiModel.behavior ?? PPPConnectionBehavior.keepAlive;
    final vlanId = uiModel.vlanId;
    bool wanTaggingSettingsEnabled = false;
    if (vlanId != null) {
      wanTaggingSettingsEnabled = (vlanId >= 5) && (vlanId <= 4094);
    }

    return RouterWANSettings.pppoe(
      mtu: mtu,
      pppoeSettings: PPPoESettings(
        username: uiModel.username ?? '',
        password: uiModel.password ?? '',
        serviceName: uiModel.serviceName ?? '',
        behavior: behavior.value,
        maxIdleMinutes: behavior == PPPConnectionBehavior.connectOnDemand
            ? uiModel.maxIdleMinutes ?? 15
            : null,
        reconnectAfterSeconds: behavior == PPPConnectionBehavior.keepAlive
            ? uiModel.reconnectAfterSeconds ?? 30
            : null,
      ),
      wanTaggingSettings: SinglePortVLANTaggingSettings(
        isEnabled: wanTaggingSettingsEnabled,
        vlanTaggingSettings: wanTaggingSettingsEnabled
            ? PortTaggingSettings(
                vlanID: uiModel.vlanId ?? 5,
                vlanStatus: TaggingStatus.tagged.value,
              )
            : null,
      ),
    );
  }

  static Ipv4SettingsUIModel updateFromForm(
      Ipv4SettingsUIModel currentSetting, Ipv4SettingsUIModel newValues) {
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
