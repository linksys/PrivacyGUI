import 'package:privacy_gui/core/jnap/models/ipv6_automatic_settings.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_settings.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv6_settings_handler.dart';

class AutomaticIpv6SettingsHandler implements Ipv6SettingsHandler {
  @override
  WanIPv6Type get wanType => WanIPv6Type.automatic;

  @override
  Ipv6Setting getIpv6Setting(GetIPv6Settings? ipv6Settings) {
    return Ipv6Setting(
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

  @override
  SetIPv6Settings createSetIPv6Settings(Ipv6Setting ipv6Setting) {
    final hasIPv6rdTunnelSettings = !ipv6Setting.isIPv6AutomaticEnabled &&
        ipv6Setting.ipv6rdTunnelMode == IPv6rdTunnelMode.manual;

    return SetIPv6Settings(
      wanType: wanType.type,
      ipv6AutomaticSettings: IPv6AutomaticSettings(
        isIPv6AutomaticEnabled: ipv6Setting.isIPv6AutomaticEnabled,
        ipv6rdTunnelMode: ipv6Setting.isIPv6AutomaticEnabled
            ? null
            : ipv6Setting.ipv6rdTunnelMode?.value,
        ipv6rdTunnelSettings: hasIPv6rdTunnelSettings
            ? IPv6rdTunnelSettings(
                prefix: ipv6Setting.ipv6Prefix ?? '',
                prefixLength: ipv6Setting.ipv6PrefixLength ?? 0,
                borderRelay: ipv6Setting.ipv6BorderRelay ?? '',
                borderRelayPrefixLength:
                    ipv6Setting.ipv6BorderRelayPrefixLength ?? 0,
              )
            : null,
      ),
    );
  }

  @override
  Ipv6Setting updateIpv6Setting(
      Ipv6Setting currentSetting, Ipv6Setting newValues) {
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
