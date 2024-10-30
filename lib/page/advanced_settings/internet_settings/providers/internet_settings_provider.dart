import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/extensions/_extensions.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_automatic_settings.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_settings.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/jnap/models/mac_address_clone_settings.dart';
import 'package:privacy_gui/core/jnap/models/remote_setting.dart';
import 'package:privacy_gui/core/jnap/models/wan_settings.dart';
import 'package:privacy_gui/core/jnap/models/wan_status.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/providers/redirection/redirection_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final internetSettingsProvider =
    NotifierProvider<InternetSettingsNotifier, InternetSettingsState>(
        () => InternetSettingsNotifier());

class InternetSettingsNotifier extends Notifier<InternetSettingsState> {
  String? _hostname;
  String? get hostname => _hostname;

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
        : RouterWANStatus.fromMap(wanStatusResult.output);
    // MAC Address Clone Setting
    final macAddressCloneSettingsResult = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getMACAddressCloneSettings, Map.fromEntries(results));
    final macAddressCloneSettings = macAddressCloneSettingsResult == null
        ? null
        : MACAddressCloneSettings.fromMap(macAddressCloneSettingsResult.output);
    // LAN settings
    final lanResult = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getLANSettings, Map.fromEntries(results));
    final lanSettings =
        lanResult == null ? null : RouterLANSettings.fromMap(lanResult.output);
    _hostname = lanSettings?.hostName;

    InternetSettingsState newState = InternetSettingsState.init();
    switch (WanType.resolve(wanSettings?.wanType ?? '')) {
      case WanType.dhcp:
        break;
      case WanType.pppoe:
        final pppoeSettings = wanSettings?.pppoeSettings;
        if (pppoeSettings != null) {
          newState = newState.copyWith(
            ipv4Setting: newState.ipv4Setting.copyWith(
              behavior: () =>
                  PPPConnectionBehavior.resolve(pppoeSettings.behavior) ??
                  PPPConnectionBehavior.keepAlive,
              maxIdleMinutes: () => pppoeSettings.maxIdleMinutes,
              reconnectAfterSeconds: () => pppoeSettings.reconnectAfterSeconds,
              username: () => pppoeSettings.username,
              password: () => pppoeSettings.password,
              serviceName: () => pppoeSettings.serviceName,
              wanTaggingSettingsEnable: () =>
                  wanSettings?.wanTaggingSettings?.isEnabled,
              vlanId: () =>
                  wanSettings?.wanTaggingSettings?.vlanTaggingSettings?.vlanID,
            ),
          );
        }
        break;
      case WanType.pptp:
        final tpSettings = wanSettings?.tpSettings;
        if (tpSettings != null) {
          newState = newState.copyWith(
            ipv4Setting: newState.ipv4Setting.copyWith(
              behavior: () =>
                  PPPConnectionBehavior.resolve(tpSettings.behavior),
              maxIdleMinutes: () => tpSettings.maxIdleMinutes,
              reconnectAfterSeconds: () => tpSettings.reconnectAfterSeconds,
              serverIp: () => tpSettings.server,
              useStaticSettings: () => tpSettings.useStaticSettings,
              username: () => tpSettings.username,
              password: () => tpSettings.password,
              staticIpAddress: () => tpSettings.staticSettings?.ipAddress,
              staticGateway: () => tpSettings.staticSettings?.gateway,
              staticDns1: () => tpSettings.staticSettings?.dnsServer1,
              staticDns2: () => tpSettings.staticSettings?.dnsServer2,
              staticDns3: () => tpSettings.staticSettings?.dnsServer3,
            ),
          );
        }
        break;
      case WanType.l2tp:
        final tpSettings = wanSettings?.tpSettings;
        if (tpSettings != null) {
          newState = newState.copyWith(
            ipv4Setting: newState.ipv4Setting.copyWith(
              behavior: () =>
                  PPPConnectionBehavior.resolve(tpSettings.behavior),
              maxIdleMinutes: () => tpSettings.maxIdleMinutes,
              reconnectAfterSeconds: () => tpSettings.reconnectAfterSeconds,
              serverIp: () => tpSettings.server,
              useStaticSettings: () => false,
              username: () => tpSettings.username,
              password: () => tpSettings.password,
            ),
          );
        }
        break;
      case WanType.static:
        final staticSettings = wanSettings?.staticSettings;
        if (staticSettings != null) {
          newState = newState.copyWith(
            ipv4Setting: newState.ipv4Setting.copyWith(
              staticIpAddress: () => staticSettings.ipAddress,
              staticGateway: () => staticSettings.gateway,
              staticDns1: () => staticSettings.dnsServer1,
              staticDns2: () => staticSettings.dnsServer2,
              staticDns3: () => staticSettings.dnsServer3,
              networkPrefixLength: () => staticSettings.networkPrefixLength,
            ),
          );
        }
        break;
      case WanType.bridge:
        SharedPreferences.getInstance().then((prefs) {
          final redirection = prefs.getString(pRedirection);
          newState = newState.copyWith(
            ipv4Setting: newState.ipv4Setting.copyWith(
              redirection: () => redirection,
            ),
          );
        });
        break;
      default:
        break;
    }

    state = newState.copyWith(
      ipv4Setting: newState.ipv4Setting.copyWith(
        ipv4ConnectionType: wanSettings?.wanType ?? '',
        supportedIPv4ConnectionType: wanStatus?.supportedWANTypes ?? [],
        supportedWANCombinations: wanStatus?.supportedWANCombinations ?? [],
        mtu: wanSettings?.mtu ?? 0,
      ),
      ipv6Setting: newState.ipv6Setting.copyWith(
        ipv6ConnectionType: getIPv6Settings?.wanType ?? '',
        supportedIPv6ConnectionType: wanStatus?.supportedIPv6WANTypes ?? [],
        duid: getIPv6Settings?.duid ?? '',
        isIPv6AutomaticEnabled:
            getIPv6Settings?.ipv6AutomaticSettings?.isIPv6AutomaticEnabled ??
                false,
        ipv6rdTunnelMode: () => IPv6rdTunnelMode.resolve(
            getIPv6Settings?.ipv6AutomaticSettings?.ipv6rdTunnelMode ?? ''),
        ipv6Prefix: () => getIPv6Settings
            ?.ipv6AutomaticSettings?.ipv6rdTunnelSettings?.prefix,
        ipv6PrefixLength: () => getIPv6Settings
            ?.ipv6AutomaticSettings?.ipv6rdTunnelSettings?.prefixLength,
        ipv6BorderRelay: () => getIPv6Settings
            ?.ipv6AutomaticSettings?.ipv6rdTunnelSettings?.borderRelay,
        ipv6BorderRelayPrefixLength: () => getIPv6Settings
            ?.ipv6AutomaticSettings
            ?.ipv6rdTunnelSettings
            ?.borderRelayPrefixLength,
      ),
      macClone: macAddressCloneSettings?.isMACAddressCloneEnabled ?? false,
      macCloneAddress: () => macAddressCloneSettings?.macAddress ?? '',
    );
    return state;
  }

  Future saveIpv4(InternetSettingsState newState) async {
    final wanType = WanType.resolve(newState.ipv4Setting.ipv4ConnectionType);
    if (wanType != null) {
      // Create settings
      RouterWANSettings wanSettings =
          _createIpv4WanSettings(newState.ipv4Setting, wanType);
      MapEntry<JNAPAction, Map<String, dynamic>>? additionalSetting =
          _getIpv4AdditionalSetting(wanType);
      // Create transactions
      List<MapEntry<JNAPAction, Map<String, dynamic>>> transactions = [];
      transactions.add(MapEntry(
        JNAPAction.setWANSettings,
        wanSettings.toJson(),
      ));
      if (additionalSetting != null) {
        transactions.add(additionalSetting);
      }
      final currentWanType =
          WanType.resolve(state.ipv4Setting.ipv4ConnectionType);
      if (currentWanType == WanType.bridge) {
        ref.read(redirectionProvider.notifier).state = 'https://localhost';
      } else {
        ref.read(redirectionProvider.notifier).state = null;
      }
      return ref
          .read(routerRepositoryProvider)
          .doTransaction(transactions, fetchRemote: true)
          .then((results) async {
        _handleWebRedirection(results);
      }).catchError(
        (error) {
          final sideEffectError = error as JNAPSideEffectError;
          if (sideEffectError.attach is JNAPTransactionSuccessWrap) {
            JNAPTransactionSuccessWrap result =
                sideEffectError.attach as JNAPTransactionSuccessWrap;
            _handleWebRedirection(result.data);
          }
        },
        test: (error) => error is JNAPSideEffectError,
      ).whenComplete(() async {
        await fetch(fetchRemote: true);
      });
    } else {
      throw const JNAPError(result: 'Empty wanType', error: 'Empty wanType');
    }
  }

  void _handleWebRedirection(List<MapEntry<JNAPAction, JNAPResult>> data) {
    final setWanSettingsResult = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.setWANSettings, Map.fromEntries(data));
    final redirection = setWanSettingsResult?.output["redirection"];
    if (kIsWeb && redirection != null) {
      final redirectionUrl =
          'https://${redirection["hostName"]}.${redirection["domain"]}';
      ref.read(redirectionProvider.notifier).state = redirectionUrl;
      logger.d('Set Bridge: $redirectionUrl');
      return;
    }
    ref.read(redirectionProvider.notifier).state = null;
  }

  RouterWANSettings _createIpv4WanSettings(
      Ipv4Setting ipv4Setting, WanType wanType) {
    final mtu = ipv4Setting.mtu;
    final behavior = ipv4Setting.behavior ?? PPPConnectionBehavior.keepAlive;
    final vlanId = ipv4Setting.vlanId;
    bool wanTaggingSettingsEnabled = false;
    if (vlanId != null) {
      wanTaggingSettingsEnabled = (vlanId >= 5) && (vlanId <= 4094);
    }
    return switch (wanType) {
      WanType.dhcp => RouterWANSettings.dhcp(mtu: mtu),
      WanType.pppoe => RouterWANSettings.pppoe(
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
        ),
      WanType.pptp => RouterWANSettings.pptp(
          mtu: mtu,
          tpSettings: _createTPSettings(ipv4Setting, true),
          wanTaggingSettings:
              const SinglePortVLANTaggingSettings(isEnabled: false),
        ),
      WanType.l2tp => RouterWANSettings.l2tp(
          mtu: mtu,
          tpSettings: _createTPSettings(ipv4Setting, false),
        ),
      WanType.static => RouterWANSettings.static(
          mtu: mtu,
          staticSettings: _createStaticSettings(ipv4Setting),
          wanTaggingSettings:
              const SinglePortVLANTaggingSettings(isEnabled: false),
        ),
      WanType.bridge => RouterWANSettings.bridge(
          bridgeSettings: const BridgeSettings(useStaticSettings: false),
        ),
      _ => RouterWANSettings(wanType: wanType.type, mtu: ipv4Setting.mtu),
    };
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
          ? ipv4Setting.maxIdleMinutes
          : null,
      reconnectAfterSeconds: behavior == PPPConnectionBehavior.keepAlive
          ? ipv4Setting.reconnectAfterSeconds
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
    );
  }

  MapEntry<JNAPAction, Map<String, dynamic>>? _getIpv4AdditionalSetting(
      WanType wanType) {
    return switch (wanType) {
      WanType.bridge => MapEntry(
          JNAPAction.setRemoteSetting,
          const RemoteSetting(
            isEnabled: false,
          ).toJson()),
      _ => null,
    };
  }

  Future saveIpv6(InternetSettingsState newState) {
    final wanType =
        WanIPv6Type.resolve(newState.ipv6Setting.ipv6ConnectionType);
    if (wanType != null) {
      // Create settings
      SetIPv6Settings settings =
          _createSetIPv6Settings(newState.ipv6Setting, wanType);

      return ref
          .read(routerRepositoryProvider)
          .send(JNAPAction.setIPv6Settings, data: settings.toJson(), auth: true)
          .then((_) async => await fetch(fetchRemote: true));
    } else {
      throw const JNAPError(result: 'Empty wanType', error: 'Empty wanType');
    }
  }

  SetIPv6Settings _createSetIPv6Settings(
      Ipv6Setting ipv6Setting, WanIPv6Type wanType) {
    final hasIPv6rdTunnelSettings = !ipv6Setting.isIPv6AutomaticEnabled &&
        ipv6Setting.ipv6rdTunnelMode == IPv6rdTunnelMode.manual;
    return switch (wanType) {
      WanIPv6Type.automatic => SetIPv6Settings(
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
        ),
      _ => SetIPv6Settings(wanType: wanType.type),
    };
  }

  Future setMacAddressClone(bool isMACAddressCloneEnabled, String? macAddress) {
    final repo = ref.read(routerRepositoryProvider);
    return repo
        .send(
      JNAPAction.setMACAddressCloneSettings,
      auth: true,
      data: MACAddressCloneSettings(
        isMACAddressCloneEnabled: isMACAddressCloneEnabled,
        macAddress: isMACAddressCloneEnabled ? macAddress : null,
      ).toMap(),
    )
        .then((_) async {
      await getMacAddressClone();
    });
  }

  Future getMacAddressClone() {
    final repo = ref.read(routerRepositoryProvider);
    return repo
        .send(
      JNAPAction.getMACAddressCloneSettings,
      auth: true,
      fetchRemote: true,
    )
        .then((success) {
      final macAddressCloneSettings =
          MACAddressCloneSettings.fromMap(success.output);
      state = state.copyWith(
        macClone: macAddressCloneSettings.isMACAddressCloneEnabled,
        macCloneAddress: () => macAddressCloneSettings.macAddress,
      );
    });
  }

  Future<String?> getMyMACAddress() {
    final repo = ref.read(routerRepositoryProvider);
    return repo
        .send(JNAPAction.getLocalDevice, auth: true, fetchRemote: true)
        .then((result) {
      final deviceID = result.output['deviceID'];
      return ref
          .read(deviceManagerProvider)
          .deviceList
          .firstWhereOrNull((device) => device.deviceID == deviceID)
          ?.getMacAddress();
    });
  }
}
