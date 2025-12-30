import 'package:privacy_gui/core/jnap/models/wan_settings.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/_models.dart';
import 'package:privacy_gui/utils.dart';

class L2tpConverter {
  static Ipv4SettingsUIModel fromJNAP(RouterWANSettings? wanSettings) {
    final tpSettings = wanSettings?.tpSettings;
    const defaultConnectionBehavior = PPPConnectionBehavior.keepAlive;
    const defaultMaxIdleMinutes = 15;
    const defaultReconnectAfterSeconds = 30;

    return Ipv4SettingsUIModel(
      ipv4ConnectionType: WanType.l2tp.type,
      mtu: wanSettings?.mtu ?? 0,
      behavior: tpSettings != null
          ? PPPConnectionBehavior.resolve(tpSettings.behavior) ??
              defaultConnectionBehavior
          : defaultConnectionBehavior,
      maxIdleMinutes: tpSettings?.maxIdleMinutes ?? defaultMaxIdleMinutes,
      reconnectAfterSeconds:
          tpSettings?.reconnectAfterSeconds ?? defaultReconnectAfterSeconds,
      serverIp: tpSettings?.server,
      username: tpSettings?.username,
      password: tpSettings?.password,
    );
  }

  static RouterWANSettings toJNAP(Ipv4SettingsUIModel uiModel) {
    final mtu = NetworkUtils.isMtuValid(WanType.l2tp.type, uiModel.mtu)
        ? uiModel.mtu
        : 0;
    const disabledWanTaggingSettings =
        SinglePortVLANTaggingSettings(isEnabled: false);

    return RouterWANSettings.l2tp(
      mtu: mtu,
      tpSettings: _createTPSettings(uiModel, false),
      wanTaggingSettings: disabledWanTaggingSettings,
    );
  }

  static TPSettings _createTPSettings(
      Ipv4SettingsUIModel uiModel, bool isPPTP) {
    final useStaticSettings = (uiModel.useStaticSettings ?? false) && isPPTP;
    final behavior = uiModel.behavior ?? PPPConnectionBehavior.keepAlive;
    return TPSettings(
      useStaticSettings: useStaticSettings,
      staticSettings: useStaticSettings ? _createStaticSettings(uiModel) : null,
      server: uiModel.serverIp ?? '',
      username: uiModel.username ?? '',
      password: uiModel.password ?? '',
      behavior: behavior.value,
      maxIdleMinutes: behavior == PPPConnectionBehavior.connectOnDemand
          ? uiModel.maxIdleMinutes ?? 15
          : null,
      reconnectAfterSeconds: behavior == PPPConnectionBehavior.keepAlive
          ? uiModel.reconnectAfterSeconds ?? 30
          : null,
    );
  }

  static StaticSettings _createStaticSettings(Ipv4SettingsUIModel uiModel) {
    return StaticSettings(
      ipAddress: uiModel.staticIpAddress ?? '',
      networkPrefixLength: uiModel.networkPrefixLength ?? 24,
      gateway: uiModel.staticGateway ?? '',
      dnsServer1: uiModel.staticDns1 ?? '',
      dnsServer2: uiModel.staticDns2,
      dnsServer3: uiModel.staticDns3,
      domainName: uiModel.domainName,
    );
  }

  static Ipv4SettingsUIModel updateFromForm(
      Ipv4SettingsUIModel currentSetting, Ipv4SettingsUIModel newValues) {
    const defaultConnectionBehavior = PPPConnectionBehavior.keepAlive;
    const defaultMaxIdleMinutes = 15;
    const defaultReconnectAfterSeconds = 30;

    return currentSetting.copyWith(
      ipv4ConnectionType: newValues.ipv4ConnectionType,
      serverIp: () => newValues.serverIp,
      username: () => newValues.username,
      password: () => newValues.password,
      serviceName: () => newValues.serviceName,
      behavior: () => newValues.behavior ?? defaultConnectionBehavior,
      maxIdleMinutes: () => newValues.maxIdleMinutes ?? defaultMaxIdleMinutes,
      reconnectAfterSeconds: () =>
          newValues.reconnectAfterSeconds ?? defaultReconnectAfterSeconds,
      useStaticSettings: () => newValues.useStaticSettings ?? false,
    );
  }
}
