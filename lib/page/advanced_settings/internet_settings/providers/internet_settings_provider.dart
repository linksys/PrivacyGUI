import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/extensions/_extensions.dart';
import 'package:linksys_app/core/jnap/models/get_port_connection_status.dart';
import 'package:linksys_app/core/jnap/models/ipv6_automatic_settings.dart';
import 'package:linksys_app/core/jnap/models/ipv6_settings.dart';
import 'package:linksys_app/core/jnap/models/mac_address_clone_settings.dart';
import 'package:linksys_app/core/jnap/models/remote_setting.dart';
import 'package:linksys_app/core/jnap/models/wan_port.dart';
import 'package:linksys_app/core/jnap/models/wan_settings.dart';
import 'package:linksys_app/core/jnap/models/wan_status.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';

final internetSettingsProvider =
    NotifierProvider<InternetSettingsNotifier, InternetSettingsState>(
        () => InternetSettingsNotifier());

class InternetSettingsNotifier extends Notifier<InternetSettingsState> {
  @override
  InternetSettingsState build() => InternetSettingsState.init();

  Future<InternetSettingsState> fetch({bool fetchRemote = false}) async {
    final repo = ref.read(routerRepositoryProvider);
    final results = await repo.fetchInternetSettings(fetchRemote: true);
    // Wan Settings
    final wanSettingsResult = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getWANSettings, Map.fromEntries(results));
    final wanSettings = wanSettingsResult == null
        ? null
        : RouterWANSettings.fromJson(wanSettingsResult.output);
    // IPv6 Settings
    final getIPv6SettingsResult = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getIPv6Settings, Map.fromEntries(results));
    final getIPv6Settings = getIPv6SettingsResult == null
        ? null
        : GetIPv6Settings.fromJson(getIPv6SettingsResult.output);
    // Wan Status
    final wanStatusResult = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getWANStatus, Map.fromEntries(results));
    final wanStatus = wanStatusResult == null
        ? null
        : RouterWANStatus.fromJson(wanStatusResult.output);
    // MAC Address Clone Setting
    final macAddressCloneSettingsResult = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getMACAddressCloneSettings, Map.fromEntries(results));
    final macAddressCloneSettings = macAddressCloneSettingsResult == null
        ? null
        : MACAddressCloneSettings.fromMap(macAddressCloneSettingsResult.output);

    switch (WanType.resolve(wanSettings?.wanType ?? '')) {
      case WanType.dhcp:
        break;
      case WanType.pppoe:
        final pppoeSettings = wanSettings?.pppoeSettings;
        if (pppoeSettings != null) {
          state = state.copyWith(
            ipv4Setting: state.ipv4Setting.copyWith(
              behavior: PPPConnectionBehavior.resolve(pppoeSettings.behavior) ??
                  PPPConnectionBehavior.keepAlive,
              maxIdleMinutes: pppoeSettings.maxIdleMinutes,
              reconnectAfterSeconds: pppoeSettings.reconnectAfterSeconds,
              username: pppoeSettings.username,
              password: pppoeSettings.password,
              serviceName: pppoeSettings.serviceName,
            ),
          );
        }
        break;
      case WanType.pptp:
        final tpSettings = wanSettings?.tpSettings;
        if (tpSettings != null) {
          state = state.copyWith(
            ipv4Setting: state.ipv4Setting.copyWith(
              behavior: PPPConnectionBehavior.resolve(tpSettings.behavior),
              maxIdleMinutes: tpSettings.maxIdleMinutes,
              reconnectAfterSeconds: tpSettings.reconnectAfterSeconds,
              serverIp: tpSettings.server,
              useStaticSettings: tpSettings.useStaticSettings,
              username: tpSettings.username,
              password: tpSettings.password,
              staticIpAddress: tpSettings.staticSettings?.ipAddress,
              staticGateway: tpSettings.staticSettings?.gateway,
              staticDns1: tpSettings.staticSettings?.dnsServer1,
              staticDns2: tpSettings.staticSettings?.dnsServer2,
              staticDns3: tpSettings.staticSettings?.dnsServer3,
            ),
          );
        }
        break;
      case WanType.l2tp:
        final tpSettings = wanSettings?.tpSettings;
        if (tpSettings != null) {
          state = state.copyWith(
            ipv4Setting: state.ipv4Setting.copyWith(
              behavior: PPPConnectionBehavior.resolve(tpSettings.behavior),
              maxIdleMinutes: tpSettings.maxIdleMinutes,
              reconnectAfterSeconds: tpSettings.reconnectAfterSeconds,
              serverIp: tpSettings.server,
              useStaticSettings: false,
              username: tpSettings.username,
              password: tpSettings.password,
            ),
          );
        }
        break;
      case WanType.static:
        final staticSettings = wanSettings?.staticSettings;
        if (staticSettings != null) {
          state = state.copyWith(
            ipv4Setting: state.ipv4Setting.copyWith(
              staticIpAddress: staticSettings.ipAddress,
              staticGateway: staticSettings.gateway,
              staticDns1: staticSettings.dnsServer1,
              staticDns2: staticSettings.dnsServer2,
              staticDns3: staticSettings.dnsServer3,
              networkPrefixLength: staticSettings.networkPrefixLength,
            ),
          );
        }
        break;
      case WanType.bridge:
        break;
      default:
        break;
    }

    return state = state.copyWith(
      ipv4Setting: state.ipv4Setting.copyWith(
        ipv4ConnectionType: wanSettings?.wanType ?? '',
        supportedIPv4ConnectionType: wanStatus?.supportedWANTypes ?? [],
        supportedWANCombinations: wanStatus?.supportedWANCombinations ?? [],
        mtu: wanSettings?.mtu ?? 0,
        vlanId: wanSettings?.wanTaggingSettings?.vlanTaggingSettings?.vlanID,
      ),
      ipv6Setting: state.ipv6Setting.copyWith(
        ipv6ConnectionType: getIPv6Settings?.wanType ?? '',
        supportedIPv6ConnectionType: wanStatus?.supportedIPv6WANTypes ?? [],
        duid: getIPv6Settings?.duid ?? '',
        isIPv6AutomaticEnabled:
            getIPv6Settings?.ipv6AutomaticSettings?.isIPv6AutomaticEnabled ??
                false,
        ipv6rdTunnelMode: IPv6rdTunnelMode.resolve(
            getIPv6Settings?.ipv6AutomaticSettings?.ipv6rdTunnelMode ?? ''),
        ipv6Prefix: getIPv6Settings
            ?.ipv6AutomaticSettings?.ipv6rdTunnelSettings?.prefix,
        ipv6PrefixLength: getIPv6Settings
            ?.ipv6AutomaticSettings?.ipv6rdTunnelSettings?.prefixLength,
        ipv6BorderRelay: getIPv6Settings
            ?.ipv6AutomaticSettings?.ipv6rdTunnelSettings?.borderRelay,
        ipv6BorderRelayPrefixLength: getIPv6Settings?.ipv6AutomaticSettings
            ?.ipv6rdTunnelSettings?.borderRelayPrefixLength,
      ),
      macClone: macAddressCloneSettings?.isMACAddressCloneEnabled ?? false,
      macCloneAddress: macAddressCloneSettings?.macAddress ?? '',
    );
  }

  Future saveIpv4(InternetSettingsState newState) async {
    final wanType = WanType.resolve(newState.ipv4Setting.ipv4ConnectionType);
    if (wanType != null) {
      final repo = ref.read(routerRepositoryProvider);
      MapEntry<JNAPAction, Map<String, dynamic>>? additionalSetting;
      RouterWANSettings wanSettings = RouterWANSettings(
          wanType: wanType.type, mtu: newState.ipv4Setting.mtu);
      switch (wanType) {
        case WanType.dhcp:
          break;
        case WanType.pppoe:
          final getPortConnectionStatusResult =
              await repo.send(JNAPAction.getPortConnectionStatus, auth: true);
          final getPortConnectionStatus = GetPortConnectionStatus.fromJson(
              getPortConnectionStatusResult.output);
          final connectedPortConnectionStatus =
              getPortConnectionStatus.portConnectionStatus.firstWhereOrNull(
                  (element) => element.connectionState == 'Connected');
          if (connectedPortConnectionStatus != null) {
            await repo.send(
              JNAPAction.setWANPort,
              data: WANPort(portId: connectedPortConnectionStatus.portId)
                  .toJson(),
              auth: true,
            );
          }
          final behavior =
              newState.ipv4Setting.behavior ?? PPPConnectionBehavior.keepAlive;
          wanSettings = wanSettings.copyWith(
            pppoeSettings: PPPoESettings(
              username: newState.ipv4Setting.username ?? '',
              password: newState.ipv4Setting.password ?? '',
              serviceName: newState.ipv4Setting.serviceName ?? '',
              behavior: behavior.value,
              maxIdleMinutes: behavior == PPPConnectionBehavior.connectOnDemand
                  ? newState.ipv4Setting.maxIdleMinutes
                  : null,
              reconnectAfterSeconds: behavior == PPPConnectionBehavior.keepAlive
                  ? newState.ipv4Setting.reconnectAfterSeconds
                  : null,
            ),
            wanTaggingSettings: SinglePortVLANTaggingSettings(
              isEnabled: true,
              vlanTaggingSettings: PortTaggingSettings(
                vlanID: newState.ipv4Setting.vlanId ?? 5,
                vlanStatus: TaggingStatus.tagged.value,
              ),
            ),
          );
          break;
        case WanType.pptp:
          final behavior =
              newState.ipv4Setting.behavior ?? PPPConnectionBehavior.keepAlive;
          final useStaticSettings =
              newState.ipv4Setting.useStaticSettings ?? false;
          wanSettings = wanSettings.copyWith(
            tpSettings: TPSettings(
              useStaticSettings: useStaticSettings,
              staticSettings: useStaticSettings
                  ? StaticSettings(
                      ipAddress: newState.ipv4Setting.staticIpAddress ?? '',
                      networkPrefixLength: 24,
                      gateway: newState.ipv4Setting.staticGateway ?? '',
                      dnsServer1: newState.ipv4Setting.staticDns1 ?? '',
                      dnsServer2: newState.ipv4Setting.staticDns2,
                      dnsServer3: newState.ipv4Setting.staticDns3,
                    )
                  : null,
              server: newState.ipv4Setting.serverIp ?? '',
              username: newState.ipv4Setting.username ?? '',
              password: newState.ipv4Setting.password ?? '',
              behavior: behavior.value,
              maxIdleMinutes: behavior == PPPConnectionBehavior.connectOnDemand
                  ? newState.ipv4Setting.maxIdleMinutes
                  : null,
              reconnectAfterSeconds: behavior == PPPConnectionBehavior.keepAlive
                  ? newState.ipv4Setting.reconnectAfterSeconds
                  : null,
            ),
            wanTaggingSettings:
                const SinglePortVLANTaggingSettings(isEnabled: false),
          );
          break;
        case WanType.l2tp:
          final behavior =
              newState.ipv4Setting.behavior ?? PPPConnectionBehavior.keepAlive;
          wanSettings = wanSettings.copyWith(
            tpSettings: TPSettings(
              useStaticSettings: false,
              server: newState.ipv4Setting.serverIp ?? '',
              username: newState.ipv4Setting.username ?? '',
              password: newState.ipv4Setting.password ?? '',
              behavior: behavior.value,
              maxIdleMinutes: behavior == PPPConnectionBehavior.connectOnDemand
                  ? newState.ipv4Setting.maxIdleMinutes
                  : null,
              reconnectAfterSeconds: behavior == PPPConnectionBehavior.keepAlive
                  ? newState.ipv4Setting.reconnectAfterSeconds
                  : null,
            ),
          );
          break;
        case WanType.static:
          wanSettings = wanSettings.copyWith(
            staticSettings: StaticSettings(
              ipAddress: newState.ipv4Setting.staticIpAddress ?? '',
              networkPrefixLength:
                  newState.ipv4Setting.networkPrefixLength ?? 24,
              gateway: newState.ipv4Setting.staticGateway ?? '',
              dnsServer1: newState.ipv4Setting.staticDns1 ?? '',
              dnsServer2: newState.ipv4Setting.staticDns2,
              dnsServer3: newState.ipv4Setting.staticDns3,
            ),
            wanTaggingSettings:
                const SinglePortVLANTaggingSettings(isEnabled: false),
          );
          break;
        case WanType.bridge:
          wanSettings = wanSettings.copyWith(
            bridgeSettings: const BridgeSettings(useStaticSettings: false),
            mtu: 0,
          );
          additionalSetting = MapEntry(
              JNAPAction.setRemoteSetting,
              const RemoteSetting(
                isEnabled: false,
              ).toJson());
          break;
        default:
          return;
      }

      List<MapEntry<JNAPAction, Map<String, dynamic>>> transactions = [];
      transactions.add(MapEntry(
        JNAPAction.setWANSettings,
        wanSettings.toJson(),
      ));
      if (additionalSetting != null) {
        transactions.add(additionalSetting);
      }

      await repo
          .doTransaction(transactions, fetchRemote: true)
          .then((_) => fetch(fetchRemote: true));
    }
  }

  Future saveIpv6(InternetSettingsState newState) async {
    final wanType =
        WanIPv6Type.resolve(newState.ipv6Setting.ipv6ConnectionType);
    if (wanType != null) {
      final repo = ref.read(routerRepositoryProvider);
      SetIPv6Settings settings = SetIPv6Settings(wanType: wanType.type);
      switch (wanType) {
        case WanIPv6Type.automatic:
          settings = settings.copyWith(
              ipv6AutomaticSettings: IPv6AutomaticSettings(
            isIPv6AutomaticEnabled: newState.ipv6Setting.isIPv6AutomaticEnabled,
            ipv6rdTunnelMode: newState.ipv6Setting.isIPv6AutomaticEnabled
                ? null
                : newState.ipv6Setting.ipv6rdTunnelMode?.value,
          ));
          if (!newState.ipv6Setting.isIPv6AutomaticEnabled &&
              newState.ipv6Setting.ipv6rdTunnelMode ==
                  IPv6rdTunnelMode.manual) {
            settings = settings.copyWith(
              ipv6AutomaticSettings: settings.ipv6AutomaticSettings?.copyWith(
                ipv6rdTunnelSettings: IPv6rdTunnelSettings(
                  prefix: newState.ipv6Setting.ipv6Prefix ?? '',
                  prefixLength: newState.ipv6Setting.ipv6PrefixLength ?? 0,
                  borderRelay: newState.ipv6Setting.ipv6BorderRelay ?? '',
                  borderRelayPrefixLength:
                      newState.ipv6Setting.ipv6BorderRelayPrefixLength ?? 0,
                ),
              ),
            );
          }
          break;
        case WanIPv6Type.pppoe:
          break;
        case WanIPv6Type.passThrough:
          break;
        default:
          break;
      }

      await repo
          .send(JNAPAction.setIPv6Settings, data: settings.toJson(), auth: true)
          .then((_) => fetch(fetchRemote: true));
    }
  }

  Future setMacAddressClone(bool isMACAddressCloneEnabled, String? macAddress) {
    final repo = ref.read(routerRepositoryProvider);
    return repo
        .send(
      JNAPAction.setMACAddressCloneSettings,
      auth: true,
      timeoutMs: 3000,
      data: MACAddressCloneSettings(
        isMACAddressCloneEnabled: isMACAddressCloneEnabled,
        macAddress: isMACAddressCloneEnabled ? macAddress : null,
      ).toMap(),
    )
        .then((_) {
      state = state.copyWith(
        macClone: isMACAddressCloneEnabled,
        macCloneAddress: macAddress,
      );
    });
  }
}
