import 'package:privacy_gui/core/jnap/models/wan_settings.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/_models.dart';
import 'package:privacy_gui/utils.dart';

class StaticConverter {
  static Ipv4SettingsUIModel fromJNAP(RouterWANSettings? wanSettings) {
    final staticSettings = wanSettings?.staticSettings;

    return Ipv4SettingsUIModel(
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

  static RouterWANSettings toJNAP(Ipv4SettingsUIModel uiModel) {
    final mtu = NetworkUtils.isMtuValid(WanType.static.type, uiModel.mtu)
        ? uiModel.mtu
        : 0;
    const disabledWanTaggingSettings =
        SinglePortVLANTaggingSettings(isEnabled: false);

    return RouterWANSettings.static(
      mtu: mtu,
      staticSettings: _createStaticSettings(uiModel),
      wanTaggingSettings: disabledWanTaggingSettings,
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
