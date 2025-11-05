import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/wan_settings.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv4_settings_handler.dart';
import 'package:privacy_gui/utils.dart';

class PptpSettingsHandler implements Ipv4SettingsHandler {
  @override
  WanType get wanType => WanType.pptp;

  @override
  Ipv4Setting getIpv4Setting(RouterWANSettings? wanSettings) {
    final tpSettings = wanSettings?.tpSettings;
    const defaultConnectionBehavior = PPPConnectionBehavior.keepAlive;
    const defaultMaxIdleMinutes = 15;
    const defaultReconnectAfterSeconds = 30;

    return Ipv4Setting(
      ipv4ConnectionType: WanType.pptp.type,
      mtu: wanSettings?.mtu ?? 0,
      behavior: tpSettings != null
          ? PPPConnectionBehavior.resolve(tpSettings.behavior) ??
              defaultConnectionBehavior
          : defaultConnectionBehavior,
      maxIdleMinutes: tpSettings?.maxIdleMinutes ?? defaultMaxIdleMinutes,
      reconnectAfterSeconds:
          tpSettings?.reconnectAfterSeconds ?? defaultReconnectAfterSeconds,
      serverIp: tpSettings?.server,
      useStaticSettings: tpSettings?.useStaticSettings,
      username: tpSettings?.username,
      password: tpSettings?.password,
      staticIpAddress: tpSettings?.staticSettings?.ipAddress,
      staticGateway: tpSettings?.staticSettings?.gateway,
      staticDns1: tpSettings?.staticSettings?.dnsServer1,
      staticDns2: tpSettings?.staticSettings?.dnsServer2,
      staticDns3: tpSettings?.staticSettings?.dnsServer3,
      domainName: tpSettings?.staticSettings?.domainName,
    );
  }

  @override
  RouterWANSettings createWanSettings(Ipv4Setting ipv4Setting) {
    final mtu = NetworkUtils.isMtuValid(wanType.type, ipv4Setting.mtu)
        ? ipv4Setting.mtu
        : 0;
    final diabledWanTaggingSettings =
        SinglePortVLANTaggingSettings(isEnabled: false);

    return RouterWANSettings.pptp(
      mtu: mtu,
      tpSettings: _createTPSettings(ipv4Setting, true),
      wanTaggingSettings: diabledWanTaggingSettings,
    );
  }

  TPSettings _createTPSettings(Ipv4Setting ipv4Setting, bool isPPTP) {
    final useStaticSettings =
        (ipv4Setting.useStaticSettings ?? false) && isPPTP;
    final behavior = ipv4Setting.behavior ?? PPPConnectionBehavior.keepAlive;
    return TPSettings(
      useStaticSettings: useStaticSettings,
      staticSettings:
          useStaticSettings ? _createStaticSettings(ipv4Setting) : null,
      server: ipv4Setting.serverIp ?? '',
      username: ipv4Setting.username ?? '',
      password: ipv4Setting.password ?? '',
      behavior: behavior.value,
      maxIdleMinutes: behavior == PPPConnectionBehavior.connectOnDemand
          ? ipv4Setting.maxIdleMinutes ?? 15
          : null,
      reconnectAfterSeconds: behavior == PPPConnectionBehavior.keepAlive
          ? ipv4Setting.reconnectAfterSeconds ?? 30
          : null,
    );
  }

  StaticSettings _createStaticSettings(Ipv4Setting ipv4Setting) {
    return StaticSettings(
      ipAddress: ipv4Setting.staticIpAddress ?? '',
      networkPrefixLength: ipv4Setting.networkPrefixLength ?? 24,
      gateway: ipv4Setting.staticGateway ?? '',
      dnsServer1: ipv4Setting.staticDns1 ?? '',
      dnsServer2: ipv4Setting.staticDns2,
      dnsServer3: ipv4Setting.staticDns3,
      domainName: ipv4Setting.domainName,
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
      serverIp: () => newValues.serverIp,
      username: () => newValues.username,
      password: () => newValues.password,
      serviceName: () => newValues.serviceName,
      behavior: () => newValues.behavior ?? defaultConnectionBehavior,
      maxIdleMinutes: () => newValues.maxIdleMinutes ?? defaultMaxIdleMinutes,
      reconnectAfterSeconds: () =>
          newValues.reconnectAfterSeconds ?? defaultReconnectAfterSeconds,
      useStaticSettings: () => newValues.useStaticSettings ?? false,
      staticIpAddress: () => newValues.staticIpAddress,
      networkPrefixLength: () => newValues.networkPrefixLength,
      staticGateway: () => newValues.staticGateway,
      staticDns1: () => newValues.staticDns1,
      staticDns2: () => newValues.staticDns2,
      staticDns3: () => newValues.staticDns3,
      domainName: () => newValues.domainName,
    );
  }
}
