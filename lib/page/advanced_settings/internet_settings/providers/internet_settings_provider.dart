import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/extensions/_extensions.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_settings.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/jnap/models/mac_address_clone_settings.dart';
import 'package:privacy_gui/core/jnap/models/wan_settings.dart';
import 'package:privacy_gui/core/jnap/models/wan_status.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv4_settings_handler.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv6_settings_handler.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv4/dhcp_settings_handler.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv4/pppoe_settings_handler.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv4/pptp_settings_handler.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv4/l2tp_settings_handler.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv4/static_settings_handler.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv4/bridge_settings_handler.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv6/automatic_ipv6_settings_handler.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv6/default_ipv6_settings_handler.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';
import 'package:privacy_gui/providers/redirection/redirection_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final internetSettingsProvider =
    NotifierProvider<InternetSettingsNotifier, InternetSettingsState>(
        () => InternetSettingsNotifier());

// The provider now needs to be generic to match the contract.
final preservableInternetSettingsProvider =
    Provider<PreservableContract<InternetSettings, InternetSettingsStatus>>(
        (ref) {
  return ref.watch(internetSettingsProvider.notifier);
});

class InternetSettingsNotifier extends Notifier<InternetSettingsState>
    with
        PreservableNotifierMixin<InternetSettings, InternetSettingsStatus,
            InternetSettingsState> {
  @override
  InternetSettingsState build() => InternetSettingsState.init();

  Ipv4SettingsHandler _getIpv4SettingsHandler(WanType wanType) {
    return switch (wanType) {
      WanType.dhcp => DhcpSettingsHandler(),
      WanType.pppoe => PppoeSettingsHandler(),
      WanType.pptp => PptpSettingsHandler(),
      WanType.l2tp => L2tpSettingsHandler(),
      WanType.static => StaticSettingsHandler(),
      WanType.bridge => BridgeSettingsHandler(),
      _ => throw UnimplementedError(
          'Ipv4SettingsHandler for ${wanType.type} not found'),
    };
  }

  Ipv6SettingsHandler _getIpv6SettingsHandler(WanIPv6Type wanType) {
    return switch (wanType) {
      WanIPv6Type.automatic => AutomaticIpv6SettingsHandler(),
      WanIPv6Type.static => DefaultIpv6SettingsHandler(WanIPv6Type.static),
      WanIPv6Type.bridge => DefaultIpv6SettingsHandler(WanIPv6Type.bridge),
      WanIPv6Type.sixRdTunnel =>
        DefaultIpv6SettingsHandler(WanIPv6Type.sixRdTunnel),
      WanIPv6Type.slaac => DefaultIpv6SettingsHandler(WanIPv6Type.slaac),
      WanIPv6Type.dhcpv6 => DefaultIpv6SettingsHandler(WanIPv6Type.dhcpv6),
      WanIPv6Type.pppoe => DefaultIpv6SettingsHandler(WanIPv6Type.pppoe),
      WanIPv6Type.passThrough =>
        DefaultIpv6SettingsHandler(WanIPv6Type.passThrough),
    };
  }

  @override
  Future<(InternetSettings?, InternetSettingsStatus?)> performFetch(
      {bool forceRemote = false, bool updateStatusOnly = false}) async {
    final repo = ref.read(routerRepositoryProvider);
    final results = await repo.fetchInternetSettings(forceRemote: forceRemote);
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

    InternetSettings newSettings = InternetSettings.init();
    final currentWanType = WanType.resolve(wanSettings?.wanType ?? '');
    if (currentWanType != null) {
      final ipv4Handler = _getIpv4SettingsHandler(currentWanType);
      newSettings = newSettings.copyWith(
        ipv4Setting: ipv4Handler.getIpv4Setting(wanSettings),
      );
    }

    final currentIpv6WanType =
        WanIPv6Type.resolve(getIPv6Settings?.wanType ?? '');
    if (currentIpv6WanType != null) {
      final ipv6Handler = _getIpv6SettingsHandler(currentIpv6WanType);
      newSettings = newSettings.copyWith(
        ipv6Setting: ipv6Handler.getIpv6Setting(getIPv6Settings),
      );
    }

    String? redirection;
    // Remove redirection url
    if (currentWanType != WanType.bridge) {
      await SharedPreferences.getInstance().then((prefs) {
        prefs.remove(pRedirection);
      });
    } else {
      // For bridge mode, retrieve redirection from shared preferences
      await SharedPreferences.getInstance().then((prefs) {
        redirection = prefs.getString(pRedirection);
      });
    }

    final newStatus = InternetSettingsStatus(
      supportedIPv4ConnectionType: wanStatus?.supportedWANTypes ?? [],
      supportedWANCombinations: wanStatus?.supportedWANCombinations ?? [],
      supportedIPv6ConnectionType: wanStatus?.supportedIPv6WANTypes ?? [],
      duid: getIPv6Settings?.duid ?? '',
      redirection: redirection,
      hostname: lanSettings?.hostName,
    );

    newSettings = newSettings.copyWith(
      ipv4Setting: newSettings.ipv4Setting.copyWith(
        ipv4ConnectionType: wanSettings?.wanType ?? '',
        mtu: wanSettings?.mtu ?? 0,
      ),
      macClone: macAddressCloneSettings?.isMACAddressCloneEnabled ?? false,
      macCloneAddress: () => macAddressCloneSettings?.macAddress,
    );

    return (newSettings, newStatus);
  }

  @override
  Future<void> performSave() {
    List<MapEntry<JNAPAction, Map<String, dynamic>>> transactions = [
      getMacAddressCloneTransaction(state.settings.current.macClone,
          state.settings.current.macCloneAddress),
      ...getSaveIpv4Transactions(state.settings.current),
      ...getSaveIpv6Transactions(state.settings.current),
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
      // Handle redirection

      _processSaveResultsAndHandleRedirection(results);
    }).catchError(
      (error) {
        final sideEffectError = error as JNAPSideEffectError;

        if (sideEffectError.attach is JNAPTransactionSuccessWrap) {
          // Handle redirection

          JNAPTransactionSuccessWrap result =
              sideEffectError.attach as JNAPTransactionSuccessWrap;
          _processSaveResultsAndHandleRedirection(result.data);
        } else {
          throw error;
        }
      },
      test: (error) => error is JNAPSideEffectError,
    );
  }

  void _processSaveResultsAndHandleRedirection(
      List<MapEntry<JNAPAction, JNAPResult>> results) {
    final originalWanType =
        WanType.resolve(state.settings.original.ipv4Setting.ipv4ConnectionType);

    final redirectionMap = originalWanType == WanType.bridge
        ? {'hostName': 'www.myrouter', 'domain': 'info'}
        : _getRedirectionMap(results);

    _handleWebRedirection(redirectionMap);
  }

  List<MapEntry<JNAPAction, Map<String, dynamic>>> getSaveIpv4Transactions(
      InternetSettings data) {
    final wanType = WanType.resolve(data.ipv4Setting.ipv4ConnectionType);
    if (wanType != null) {
      final handler = _getIpv4SettingsHandler(wanType);
      // Create settings
      RouterWANSettings wanSettings =
          handler.createWanSettings(data.ipv4Setting);
      MapEntry<JNAPAction, Map<String, dynamic>>? additionalSetting =
          handler.getAdditionalSetting();
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

  Future savePnpIpv4(InternetSettings data) {
    // Create transactions
    List<MapEntry<JNAPAction, Map<String, dynamic>>> transactions =
        getSaveIpv4Transactions(data);
    return ref
        .read(routerRepositoryProvider)
        .transaction(
          JNAPTransactionBuilder(commands: transactions, auth: true),
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
        )
        .then((successWrap) => successWrap.data)
        .then((results) async {
      await fetch();
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
      updateStatus(state.status.copyWith(redirection: () => redirectionUrl));
      // Save redirectionUrl
      if (WanType.resolve(
              state.settings.current.ipv4Setting.ipv4ConnectionType) ==
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

  List<MapEntry<JNAPAction, Map<String, dynamic>>> getSaveIpv6Transactions(
      InternetSettings data) {
    final wanType = WanIPv6Type.resolve(data.ipv6Setting.ipv6ConnectionType);
    if (wanType != null) {
      final handler = _getIpv6SettingsHandler(wanType);
      // Create settings
      SetIPv6Settings settings =
          handler.createSetIPv6Settings(data.ipv6Setting);
      return [MapEntry(JNAPAction.setIPv6Settings, settings.toJson())];
    } else {
      throw const JNAPError(
          result: 'Empty ipv6ConnectionType',
          error: 'Empty ipv6ConnectionType');
    }
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

  void updateStatus(InternetSettingsStatus newStatus) {
    state = state.copyWith(status: newStatus);
  }

  void updateMtu(int mtu) {
    state = state.copyWith(
        settings: state.settings.update(state.settings.current.copyWith(
            ipv4Setting:
                state.settings.current.ipv4Setting.copyWith(mtu: mtu))));
  }

  void updateMacAddressCloneEnable(bool enable) {
    state = state.copyWith(
        settings: state.settings
            .update(state.settings.current.copyWith(macClone: enable)));
  }

  void updateMacAddressClone(String? macAddress) {
    state = state.copyWith(
        settings: state.settings.update(state.settings.current
            .copyWith(macCloneAddress: () => macAddress)));
  }

  void updateIpv4Settings(Ipv4Setting ipv4Setting) {
    final wanType = WanType.resolve(ipv4Setting.ipv4ConnectionType);
    if (wanType != null) {
      final handler = _getIpv4SettingsHandler(wanType);
      final updatedIpv4Setting = handler.updateIpv4Setting(
          state.settings.current.ipv4Setting, ipv4Setting);
      state = state.copyWith(
          settings: state.settings.update(state.settings.current
              .copyWith(ipv4Setting: updatedIpv4Setting)));
    }
  }

  void updateIpv6Settings(Ipv6Setting ipv6Setting) {
    final wanIpv6Type = WanIPv6Type.resolve(ipv6Setting.ipv6ConnectionType);
    if (wanIpv6Type != null) {
      final handler = _getIpv6SettingsHandler(wanIpv6Type);
      final updatedIpv6Setting = handler.updateIpv6Setting(
          state.settings.current.ipv6Setting, ipv6Setting);
      state = state.copyWith(
          settings: state.settings.update(state.settings.current
              .copyWith(ipv6Setting: updatedIpv6Setting)));
    }
  }

  void setSettingsDefaultOnBrigdeMode() {
    // Set ipv6 to automatic
    updateIpv6Settings(Ipv6Setting(
      ipv6ConnectionType: WanIPv6Type.automatic.type,
      isIPv6AutomaticEnabled:
          state.settings.current.ipv6Setting.isIPv6AutomaticEnabled,
    ));
    // Mtu
    updateMtu(0);
    // Mac address clone
    updateMacAddressCloneEnable(false);
    updateMacAddressClone(null);
  }
}
