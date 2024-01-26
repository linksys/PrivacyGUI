import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/extensions/_extensions.dart';
import 'package:linksys_app/core/jnap/models/get_port_connection_status.dart';
import 'package:linksys_app/core/jnap/models/ipv6_automatic_settings.dart';
import 'package:linksys_app/core/jnap/models/mac_address_clone_settings.dart';
import 'package:linksys_app/core/jnap/models/remote_setting.dart';
import 'package:linksys_app/core/jnap/models/wan_port.dart';
import 'package:linksys_app/core/jnap/models/wan_settings.dart';
import 'package:linksys_app/core/jnap/models/wan_status.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/provider/internet_settings/internet_settings_state.dart';

final internetSettingsProvider =
    NotifierProvider<InternetSettingsNotifier, InternetSettingsState>(
        () => InternetSettingsNotifier());

class InternetSettingsNotifier extends Notifier<InternetSettingsState> {
  @override
  InternetSettingsState build() => InternetSettingsState.init();

  Future<InternetSettingsState> fetch({bool fetchRemote = false}) async {
    final repo = ref.read(routerRepositoryProvider);
    final results = await repo.fetchInternetSettings(fetchRemote: true);
    final wanSettingsResult = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getWANSettings, Map.fromEntries(results));
    final wanSettings = wanSettingsResult == null
        ? null
        : RouterWANSettings.fromJson(wanSettingsResult.output);
    final ipv6Settings = JNAPTransactionSuccessWrap.getResult(
            JNAPAction.getIPv6Settings, Map.fromEntries(results))
        ?.output;
    final wanStatusResult = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getWANStatus, Map.fromEntries(results));
    final wanStatus = wanStatusResult == null
        ? null
        : RouterWANStatus.fromJson(wanStatusResult.output);
    final ipv6AutomaticSettings = ipv6Settings?['ipv6AutomaticSettings'] == null
        ? null
        : IPv6AutomaticSettings.fromJson(
            ipv6Settings!['ipv6AutomaticSettings']);
    final macAddressCloneSettingsResult = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getMACAddressCloneSettings, Map.fromEntries(results));
    final macAddressCloneSettings = macAddressCloneSettingsResult == null
        ? null
        : MACAddressCloneSettings.fromJson(
            macAddressCloneSettingsResult.output);

    switch (WanType.resolve(wanSettings?.wanType ?? '')) {
      case WanType.dhcp:
        break;
      case WanType.pppoe:
        final pppoeSettings = wanSettings?.pppoeSettings;
        if (pppoeSettings != null) {
          state = state.copyWith(
            behavior: PPPConnectionBehavior.resolve(pppoeSettings.behavior),
            maxIdleMinutes: pppoeSettings.maxIdleMinutes,
            reconnectAfterSeconds: pppoeSettings.reconnectAfterSeconds,
            username: pppoeSettings.username,
            password: pppoeSettings.password,
            serviceName: pppoeSettings.serviceName,
          );
        }
        break;
      case WanType.pptp:
        final tpSettings = wanSettings?.tpSettings;
        if (tpSettings != null) {
          state = state.copyWith(
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
          );
        }
        break;
      case WanType.l2tp:
        final tpSettings = wanSettings?.tpSettings;
        if (tpSettings != null) {
          state = state.copyWith(
            behavior: PPPConnectionBehavior.resolve(tpSettings.behavior),
            maxIdleMinutes: tpSettings.maxIdleMinutes,
            reconnectAfterSeconds: tpSettings.reconnectAfterSeconds,
            serverIp: tpSettings.server,
            useStaticSettings: false,
            username: tpSettings.username,
            password: tpSettings.password,
          );
        }
        break;
      case WanType.static:
        final staticSettings = wanSettings?.staticSettings;
        if (staticSettings != null) {
          state = state.copyWith(
            staticIpAddress: staticSettings.ipAddress,
            staticGateway: staticSettings.gateway,
            staticDns1: staticSettings.dnsServer1,
            staticDns2: staticSettings.dnsServer2,
            staticDns3: staticSettings.dnsServer3,
          );
        }
        break;
      case WanType.bridge:
        break;
      default:
        break;
    }

    return state = state.copyWith(
      ipv4ConnectionType: wanSettings?.wanType ?? '',
      ipv6ConnectionType: ipv6Settings?['wanType'] ?? '',
      supportedIPv4ConnectionType: wanStatus?.supportedWANTypes ?? [],
      supportedIPv6ConnectionType: wanStatus?.supportedIPv6WANTypes ?? [],
      supportedWANCombinations: wanStatus?.supportedWANCombinations ?? [],
      mtu: wanSettings?.mtu ?? 0,
      duid: ipv6Settings?['duid'] ?? '',
      isIPv6AutomaticEnabled:
          ipv6AutomaticSettings?.isIPv6AutomaticEnabled ?? false,
      macClone: macAddressCloneSettings?.isMACAddressCloneEnabled ?? false,
      macCloneAddress: macAddressCloneSettings?.macAddress ?? '',
      vlanId: wanSettings?.wanTaggingSettings?.vlanTaggingSettings?.vlanID,
    );
  }

  Future saveIpv4(InternetSettingsState newState) async {
    final wanType = WanType.resolve(newState.ipv4ConnectionType);
    if (wanType != null) {
      final repo = ref.read(routerRepositoryProvider);
      MapEntry<JNAPAction, Map<String, dynamic>>? additionalSetting;
      RouterWANSettings wanSettings =
          RouterWANSettings(wanType: wanType.type, mtu: newState.mtu);
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
          final behavior = newState.behavior ?? PPPConnectionBehavior.keepAlive;
          wanSettings = wanSettings.copyWith(
            pppoeSettings: PPPoESettings(
              username: newState.username ?? '',
              password: newState.password ?? '',
              serviceName: newState.serviceName ?? '',
              behavior: behavior.value,
              maxIdleMinutes: behavior == PPPConnectionBehavior.connectOnDemand
                  ? newState.maxIdleMinutes
                  : null,
              reconnectAfterSeconds: behavior == PPPConnectionBehavior.keepAlive
                  ? newState.reconnectAfterSeconds
                  : null,
            ),
            wanTaggingSettings: SinglePortVLANTaggingSettings(
              isEnabled: true,
              vlanTaggingSettings: PortTaggingSettings(
                vlanID: newState.vlanId ?? 5,
                vlanStatus: TaggingStatus.tagged.value,
              ),
            ),
          );
          break;
        case WanType.pptp:
          final behavior = newState.behavior ?? PPPConnectionBehavior.keepAlive;
          final useStaticSettings = newState.useStaticSettings ?? false;
          wanSettings = wanSettings.copyWith(
            tpSettings: TPSettings(
              useStaticSettings: useStaticSettings,
              staticSettings: useStaticSettings
                  ? StaticSettings(
                      ipAddress: newState.staticIpAddress ?? '',
                      networkPrefixLength: 24,
                      gateway: newState.staticGateway ?? '',
                      dnsServer1: newState.staticDns1 ?? '',
                      dnsServer2: newState.staticDns2,
                      dnsServer3: newState.staticDns3,
                    )
                  : null,
              server: newState.serverIp ?? '',
              username: newState.username ?? '',
              password: newState.password ?? '',
              behavior: behavior.value,
              maxIdleMinutes: behavior == PPPConnectionBehavior.connectOnDemand
                  ? newState.maxIdleMinutes
                  : null,
              reconnectAfterSeconds: behavior == PPPConnectionBehavior.keepAlive
                  ? newState.reconnectAfterSeconds
                  : null,
            ),
            wanTaggingSettings:
                const SinglePortVLANTaggingSettings(isEnabled: false),
          );
          break;
        case WanType.l2tp:
          final behavior = newState.behavior ?? PPPConnectionBehavior.keepAlive;
          wanSettings = wanSettings.copyWith(
            tpSettings: TPSettings(
              useStaticSettings: false,
              server: newState.serverIp ?? '',
              username: newState.username ?? '',
              password: newState.password ?? '',
              behavior: behavior.value,
              maxIdleMinutes: behavior == PPPConnectionBehavior.connectOnDemand
                  ? newState.maxIdleMinutes
                  : null,
              reconnectAfterSeconds: behavior == PPPConnectionBehavior.keepAlive
                  ? newState.reconnectAfterSeconds
                  : null,
            ),
          );
          break;
        case WanType.static:
          wanSettings = wanSettings.copyWith(
            staticSettings: StaticSettings(
              ipAddress: newState.staticIpAddress ?? '',
              networkPrefixLength: 24,
              gateway: newState.staticGateway ?? '',
              dnsServer1: newState.staticDns1 ?? '',
              dnsServer2: newState.staticDns2,
              dnsServer3: newState.staticDns3,
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
      transactions.add(MapEntry(
        JNAPAction.setMACAddressCloneSettings,
        MACAddressCloneSettings(
          isMACAddressCloneEnabled: newState.macClone,
          macAddress: newState.macClone ? newState.macCloneAddress : null,
        ).toJson(),
      ));

      await repo
          .doTransaction(transactions, fetchRemote: true)
          .then((_) => fetch(fetchRemote: true));
    }
  }

  Future saveIpv6(InternetSettingsState newState) async {}
}
