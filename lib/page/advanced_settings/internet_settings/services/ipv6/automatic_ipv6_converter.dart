import 'package:privacy_gui/core/jnap/models/ipv6_automatic_settings.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_settings.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/_models.dart';

class AutomaticIpv6Converter {
  static Ipv6SettingsUIModel fromJNAP(GetIPv6Settings? ipv6Settings) {
    return Ipv6SettingsUIModel(
      ipv6ConnectionType: WanIPv6Type.automatic.type,
      isIPv6AutomaticEnabled:
          ipv6Settings?.ipv6AutomaticSettings?.isIPv6AutomaticEnabled ?? false,
      ipv6rdTunnelMode: IPv6rdTunnelMode.resolve(
          ipv6Settings?.ipv6AutomaticSettings?.ipv6rdTunnelMode ?? ''),
      ipv6Prefix:
          ipv6Settings?.ipv6AutomaticSettings?.ipv6rdTunnelSettings?.prefix,
      ipv6PrefixLength: ipv6Settings
          ?.ipv6AutomaticSettings?.ipv6rdTunnelSettings?.prefixLength,
      ipv6BorderRelay: ipv6Settings
          ?.ipv6AutomaticSettings?.ipv6rdTunnelSettings?.borderRelay,
      ipv6BorderRelayPrefixLength: ipv6Settings?.ipv6AutomaticSettings
          ?.ipv6rdTunnelSettings?.borderRelayPrefixLength,
    );
  }

  static SetIPv6Settings toJNAP(Ipv6SettingsUIModel uiModel) {
    final hasIPv6rdTunnelSettings = !uiModel.isIPv6AutomaticEnabled &&
        uiModel.ipv6rdTunnelMode == IPv6rdTunnelMode.manual;

    return SetIPv6Settings(
      wanType: WanIPv6Type.automatic.type,
      ipv6AutomaticSettings: IPv6AutomaticSettings(
        isIPv6AutomaticEnabled: uiModel.isIPv6AutomaticEnabled,
        ipv6rdTunnelMode: uiModel.isIPv6AutomaticEnabled
            ? null
            : uiModel.ipv6rdTunnelMode?.value,
        ipv6rdTunnelSettings: hasIPv6rdTunnelSettings
            ? IPv6rdTunnelSettings(
                prefix: uiModel.ipv6Prefix ?? '',
                prefixLength: uiModel.ipv6PrefixLength ?? 0,
                borderRelay: uiModel.ipv6BorderRelay ?? '',
                borderRelayPrefixLength:
                    uiModel.ipv6BorderRelayPrefixLength ?? 0,
              )
            : null,
      ),
    );
  }

  static Ipv6SettingsUIModel updateFromForm(
      Ipv6SettingsUIModel currentSetting, Ipv6SettingsUIModel newValues) {
    return currentSetting.copyWith(
      ipv6ConnectionType: newValues.ipv6ConnectionType,
      isIPv6AutomaticEnabled: newValues.isIPv6AutomaticEnabled,
      ipv6rdTunnelMode: () =>
          newValues.ipv6rdTunnelMode ?? IPv6rdTunnelMode.disabled,
      ipv6Prefix: () => newValues.ipv6Prefix,
      ipv6PrefixLength: () => newValues.ipv6PrefixLength,
      ipv6BorderRelay: () => newValues.ipv6BorderRelay,
      ipv6BorderRelayPrefixLength: () => newValues.ipv6BorderRelayPrefixLength,
    );
  }
}
