import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/extensions/_extensions.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_automatic_settings.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_settings.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/jnap/models/mac_address_clone_settings.dart';
import 'package:privacy_gui/core/jnap/models/remote_setting.dart';
import 'package:privacy_gui/core/jnap/models/wan_settings.dart';
import 'package:privacy_gui/core/jnap/models/wan_status.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/providers/redirection/redirection_provider.dart';
import 'package:privacy_gui/utils.dart';
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
    final results = await repo.fetchInternetSettings(fetchRemote: fetchRemote);
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

    // Default value
    const defaultConnectionBehavior = PPPConnectionBehavior.keepAlive;
    const defaultMaxIdleMinutes = 15;
    const defaultReconnectAfterSeconds = 30;

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
                  defaultConnectionBehavior,
              maxIdleMinutes: () =>
                  pppoeSettings.maxIdleMinutes ?? defaultMaxIdleMinutes,
              reconnectAfterSeconds: () =>
                  pppoeSettings.reconnectAfterSeconds ??
                  defaultReconnectAfterSeconds,
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
                  PPPConnectionBehavior.resolve(tpSettings.behavior) ??
                  defaultConnectionBehavior,
              maxIdleMinutes: () =>
                  tpSettings.maxIdleMinutes ?? defaultMaxIdleMinutes,
              reconnectAfterSeconds: () =>
                  tpSettings.reconnectAfterSeconds ??
                  defaultReconnectAfterSeconds,
              serverIp: () => tpSettings.server,
              useStaticSettings: () => tpSettings.useStaticSettings,
              username: () => tpSettings.username,
              password: () => tpSettings.password,
              staticIpAddress: () => tpSettings.staticSettings?.ipAddress,
              staticGateway: () => tpSettings.staticSettings?.gateway,
              staticDns1: () => tpSettings.staticSettings?.dnsServer1,
              staticDns2: () => tpSettings.staticSettings?.dnsServer2,
              staticDns3: () => tpSettings.staticSettings?.dnsServer3,
              domainName: () => tpSettings.staticSettings?.domainName,
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
                  PPPConnectionBehavior.resolve(tpSettings.behavior) ??
                  defaultConnectionBehavior,
              maxIdleMinutes: () =>
                  tpSettings.maxIdleMinutes ?? defaultMaxIdleMinutes,
              reconnectAfterSeconds: () =>
                  tpSettings.reconnectAfterSeconds ??
                  defaultReconnectAfterSeconds,
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
              domainName: () => staticSettings.domainName,
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

    // Remove redirection url
    if (WanType.resolve(wanSettings?.wanType ?? '') != WanType.bridge) {
      await SharedPreferences.getInstance().then((prefs) {
        prefs.remove(pRedirection);
      });
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
      macCloneAddress: () => macAddressCloneSettings?.macAddress,
    );
    return state;
  }

  Future saveInternetSettings(
      InternetSettingsState newState, InternetSettingsState? originalState) {
    List<MapEntry<JNAPAction, Map<String, dynamic>>> transactions = [
      getMacAddressCloneTransaction(
          newState.macClone, newState.macCloneAddress),
      ...getSaveIpv4Transactions(newState),
      ...getSaveIpv6Transactions(newState),
    ];
    return ref
        .read(routerRepositoryProvider)
        .transaction(
          JNAPTransactionBuilder(commands: transactions, auth: true),
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
        )
        .then((successWrap) => successWrap.data)
        .then((results) async {
      // Fetch
      await fetch(fetchRemote: true);
      // Handle redirection
      final originalWanType =
          WanType.resolve(originalState?.ipv4Setting.ipv4ConnectionType ?? '');
      final redirectionMap = originalWanType == WanType.bridge
          ? {'hostName': 'www.myrouter', 'domain': 'info'}
          : _getRedirectionMap(results);
      _handleWebRedirection(redirectionMap);
    }).catchError(
      (error) {
        final sideEffectError = error as JNAPSideEffectError;
        if (sideEffectError.attach is JNAPTransactionSuccessWrap) {
          // Handle redirection
          JNAPTransactionSuccessWrap result =
              sideEffectError.attach as JNAPTransactionSuccessWrap;
          final originalWanType = WanType.resolve(
              originalState?.ipv4Setting.ipv4ConnectionType ?? '');
          final redirectionMap = originalWanType == WanType.bridge
              ? {'hostName': 'www.myrouter', 'domain': 'info'}
              : _getRedirectionMap(result.data);
          _handleWebRedirection(redirectionMap);
        } else {
          throw error;
        }
      },
      test: (error) => error is JNAPSideEffectError,
    );
  }

  List<MapEntry<JNAPAction, Map<String, dynamic>>> getSaveIpv4Transactions(
      InternetSettingsState newState) {
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
      return transactions;
    } else {
      throw const JNAPError(
          result: 'Empty ipv4ConnectionType',
          error: 'Empty ipv4ConnectionType');
    }
  }

  Future savePnpIpv4(InternetSettingsState newState) {
    // Create transactions
    List<MapEntry<JNAPAction, Map<String, dynamic>>> transactions =
        getSaveIpv4Transactions(newState);
    return ref
        .read(routerRepositoryProvider)
        .transaction(
          JNAPTransactionBuilder(commands: transactions, auth: true),
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
        )
        .then((successWrap) => successWrap.data)
        .then((results) async {
      await fetch(fetchRemote: true);
      return results;
    });
  }

  Map<String, dynamic>? _getRedirectionMap(
      List<MapEntry<JNAPAction, JNAPResult>> data) {
    final setWanSettingsResult = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.setWANSettings, Map.fromEntries(data));
    return setWanSettingsResult?.output["redirection"];
  }

  void _handleWebRedirection(Map<String, dynamic>? redirectionMap) {
    if (kIsWeb && redirectionMap != null) {
      final redirectionUrl =
          'https://${redirectionMap["hostName"]}.${redirectionMap["domain"]}';
      // Update state
      updateIpv4Settings(
          state.ipv4Setting.copyWith(redirection: () => redirectionUrl));
      // Save redirectionUrl
      if (WanType.resolve(state.ipv4Setting.ipv4ConnectionType) ==
          WanType.bridge) {
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString(pRedirection, redirectionUrl);
        });
      }
      // Update redirectionProvider
      ref.read(redirectionProvider.notifier).state = redirectionUrl;
      logger.d('Redirect to: $redirectionUrl');
      return;
    }
    ref.read(redirectionProvider.notifier).state = null;
  }

  RouterWANSettings _createIpv4WanSettings(
      Ipv4Setting ipv4Setting, WanType wanType) {
    final mtu = NetworkUtils.isMtuValid(wanType.type, ipv4Setting.mtu)
        ? ipv4Setting.mtu
        : 0;
    final behavior = ipv4Setting.behavior ?? PPPConnectionBehavior.keepAlive;
    final vlanId = ipv4Setting.vlanId;
    bool wanTaggingSettingsEnabled = false;
    if (vlanId != null) {
      wanTaggingSettingsEnabled = (vlanId >= 5) && (vlanId <= 4094);
    }
    final diabledWanTaggingSettings =
        SinglePortVLANTaggingSettings(isEnabled: false);
    return switch (wanType) {
      WanType.dhcp => RouterWANSettings.dhcp(
          mtu: mtu,
          wanTaggingSettings: diabledWanTaggingSettings,
        ),
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
          wanTaggingSettings: diabledWanTaggingSettings,
        ),
      WanType.l2tp => RouterWANSettings.l2tp(
          mtu: mtu,
          tpSettings: _createTPSettings(ipv4Setting, false),
          wanTaggingSettings: diabledWanTaggingSettings,
        ),
      WanType.static => RouterWANSettings.static(
          mtu: mtu,
          staticSettings: _createStaticSettings(ipv4Setting),
          wanTaggingSettings: diabledWanTaggingSettings,
        ),
      WanType.bridge => RouterWANSettings.bridge(
          bridgeSettings: const BridgeSettings(useStaticSettings: false),
          wanTaggingSettings: diabledWanTaggingSettings,
        ),
      _ => RouterWANSettings(
          wanType: wanType.type,
          mtu: ipv4Setting.mtu,
          wanTaggingSettings: diabledWanTaggingSettings,
        ),
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

  List<MapEntry<JNAPAction, Map<String, dynamic>>> getSaveIpv6Transactions(
      InternetSettingsState newState) {
    final wanType =
        WanIPv6Type.resolve(newState.ipv6Setting.ipv6ConnectionType);
    if (wanType != null) {
      // Create settings
      SetIPv6Settings settings =
          _createSetIPv6Settings(newState.ipv6Setting, wanType);
      return [MapEntry(JNAPAction.setIPv6Settings, settings.toJson())];
    } else {
      throw const JNAPError(
          result: 'Empty ipv6ConnectionType',
          error: 'Empty ipv6ConnectionType');
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
            ipv6rdTunnelMode: ipv6Setting.ipv6rdTunnelMode?.value,
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

  MapEntry<JNAPAction, Map<String, dynamic>> getMacAddressCloneTransaction(
      bool isMACAddressCloneEnabled, String? macAddress) {
    return MapEntry(
        JNAPAction.setMACAddressCloneSettings,
        MACAddressCloneSettings(
          isMACAddressCloneEnabled: isMACAddressCloneEnabled,
          macAddress: isMACAddressCloneEnabled ? macAddress : null,
        ).toMap());
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

  Future renewDHCPWANLease() async {
    final repo = ref.read(routerRepositoryProvider);
    await repo
        .send(
      JNAPAction.renewDHCPWANLease,
      auth: true,
      fetchRemote: true,
      cacheLevel: CacheLevel.noCache,
    )
        .then((result) async {
      await ref.read(pollingProvider.notifier).forcePolling();
    });
  }

  Future renewDHCPIPv6WANLease() async {
    final repo = ref.read(routerRepositoryProvider);
    await repo
        .send(
      JNAPAction.renewDHCPIPv6WANLease,
      auth: true,
      fetchRemote: true,
      cacheLevel: CacheLevel.noCache,
    )
        .then((result) async {
      await ref.read(pollingProvider.notifier).forcePolling();
    });
  }

  void updateState(InternetSettingsState newState) {
    state = newState.copyWith();
  }

  void updateMtu(int mtu) {
    state = state.copyWith(ipv4Setting: state.ipv4Setting.copyWith(mtu: mtu));
  }

  void updateMacAddressCloneEnable(bool enable) {
    state = state.copyWith(macClone: enable);
  }

  void updateMacAddressClone(String? macAddress) {
    state = state.copyWith(macCloneAddress: () => macAddress);
  }

  void updateIpv4Settings(Ipv4Setting ipv4Setting) {
    Ipv4Setting newIpv4Setting = Ipv4Setting(
      ipv4ConnectionType: ipv4Setting.ipv4ConnectionType,
      supportedIPv4ConnectionType: ipv4Setting.supportedIPv4ConnectionType,
      supportedWANCombinations: ipv4Setting.supportedWANCombinations,
      mtu: ipv4Setting.mtu,
    );
    // Default value
    const defaultConnectionBehavior = PPPConnectionBehavior.keepAlive;
    const defaultMaxIdleMinutes = 15;
    const defaultReconnectAfterSeconds = 30;
    final wanType = WanType.resolve(ipv4Setting.ipv4ConnectionType);
    newIpv4Setting = switch (wanType) {
      WanType.dhcp => newIpv4Setting,
      WanType.pppoe => newIpv4Setting.copyWith(
          username: () => ipv4Setting.username,
          password: () => ipv4Setting.password,
          serviceName: () => ipv4Setting.serviceName,
          behavior: () => ipv4Setting.behavior ?? defaultConnectionBehavior,
          maxIdleMinutes: () =>
              ipv4Setting.maxIdleMinutes ?? defaultMaxIdleMinutes,
          reconnectAfterSeconds: () =>
              ipv4Setting.reconnectAfterSeconds ?? defaultReconnectAfterSeconds,
          wanTaggingSettingsEnable: () => ipv4Setting.wanTaggingSettingsEnable,
          vlanId: () => ipv4Setting.vlanId,
        ),
      WanType.pptp || WanType.l2tp => newIpv4Setting.copyWith(
          serverIp: () => ipv4Setting.serverIp,
          username: () => ipv4Setting.username,
          password: () => ipv4Setting.password,
          serviceName: () => ipv4Setting.serviceName,
          behavior: () => ipv4Setting.behavior ?? defaultConnectionBehavior,
          maxIdleMinutes: () =>
              ipv4Setting.maxIdleMinutes ?? defaultMaxIdleMinutes,
          reconnectAfterSeconds: () =>
              ipv4Setting.reconnectAfterSeconds ?? defaultReconnectAfterSeconds,
          useStaticSettings: () => ipv4Setting.useStaticSettings ?? false,
        ),
      WanType.static => newIpv4Setting,
      WanType.bridge =>
        newIpv4Setting.copyWith(redirection: () => ipv4Setting.redirection),
      _ => newIpv4Setting,
    };
    if (ipv4Setting.useStaticSettings == true || wanType == WanType.static) {
      newIpv4Setting = newIpv4Setting.copyWith(
        staticIpAddress: () => ipv4Setting.staticIpAddress,
        networkPrefixLength: () => ipv4Setting.networkPrefixLength,
        staticGateway: () => ipv4Setting.staticGateway,
        staticDns1: () => ipv4Setting.staticDns1,
        staticDns2: () => ipv4Setting.staticDns2,
        staticDns3: () => ipv4Setting.staticDns3,
        domainName: () => ipv4Setting.domainName,
      );
    }
    state = state.copyWith(ipv4Setting: newIpv4Setting);
  }

  void updateIpv6Settings(Ipv6Setting ipv6Setting) {
    Ipv6Setting newIpv6Setting = Ipv6Setting(
      ipv6ConnectionType: ipv6Setting.ipv6ConnectionType,
      supportedIPv6ConnectionType: ipv6Setting.supportedIPv6ConnectionType,
      duid: ipv6Setting.duid,
      isIPv6AutomaticEnabled: ipv6Setting.isIPv6AutomaticEnabled,
    );
    final wanIpv6Type = WanIPv6Type.resolve(ipv6Setting.ipv6ConnectionType);
    newIpv6Setting = switch (wanIpv6Type) {
      WanIPv6Type.automatic => newIpv6Setting.copyWith(
          ipv6rdTunnelMode: () =>
              ipv6Setting.ipv6rdTunnelMode ?? IPv6rdTunnelMode.disabled,
          ipv6Prefix: () => ipv6Setting.ipv6Prefix,
          ipv6PrefixLength: () => ipv6Setting.ipv6PrefixLength,
          ipv6BorderRelay: () => ipv6Setting.ipv6BorderRelay,
          ipv6BorderRelayPrefixLength: () =>
              ipv6Setting.ipv6BorderRelayPrefixLength,
        ),
      _ => newIpv6Setting,
    };
    state = state.copyWith(ipv6Setting: newIpv6Setting);
  }
}
