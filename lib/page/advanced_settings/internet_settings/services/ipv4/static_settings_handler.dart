import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/wan_settings.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv4_settings_handler.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';
import 'package:privacy_gui/utils.dart';

class StaticSettingsHandler implements Ipv4SettingsHandler {
  @override
  WanType get wanType => WanType.static;

  @override
  Ipv4Setting getIpv4Setting(RouterWANSettings? wanSettings) {
    final staticSettings = wanSettings?.staticSettings;

    return Ipv4Setting(
      ipv4ConnectionType: WanType.static.type,
      mtu: wanSettings?.mtu ?? 0,
      staticIpAddress: staticSettings?.ipAddress,
      staticGateway: staticSettings?.gateway,
      staticDns1: staticSettings?.dnsServer1,
      staticDns2: staticSettings?.dnsServer2,
      staticDns3: staticSettings?.dnsServer3,
      networkPrefixLength: staticSettings?.networkPrefixLength,
      domainName: staticSettings?.domainName,
    );
  }

  @override
  RouterWANSettings createWanSettings(Ipv4Setting ipv4Setting) {
    final mtu = NetworkUtils.isMtuValid(wanType.type, ipv4Setting.mtu)
        ? ipv4Setting.mtu
        : 0;
    const diabledWanTaggingSettings =
        SinglePortVLANTaggingSettings(isEnabled: false);

    return RouterWANSettings.static(
      mtu: mtu,
      staticSettings: _createStaticSettings(ipv4Setting),
      wanTaggingSettings: diabledWanTaggingSettings,
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
    return currentSetting.copyWith(
      ipv4ConnectionType: newValues.ipv4ConnectionType,
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
