import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
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
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/_models.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv4/dhcp_converter.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv4/pppoe_converter.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv4/pptp_converter.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv4/l2tp_converter.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv4/static_converter.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv4/bridge_converter.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv6/automatic_ipv6_converter.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv6/default_ipv6_converter.dart';
import 'package:shared_preferences/shared_preferences.dart';

final internetSettingsServiceProvider =
    Provider<InternetSettingsService>((ref) {
  return InternetSettingsService(
    ref.watch(routerRepositoryProvider),
    ref,
  );
});

class InternetSettingsService {
  final RouterRepository _routerRepository;
  final Ref _ref;

  InternetSettingsService(this._routerRepository, this._ref);

  /// Fetches internet settings from JNAP and converts to UI models
  Future<(InternetSettingsUIModel, InternetSettingsStatusUIModel)>
      fetchSettings({bool forceRemote = false}) async {
    try {
      final results =
          await _fetchInternetSettingsTransaction(forceRemote: forceRemote);

      // Parse JNAP responses
      final wanSettingsResult = JNAPTransactionSuccessWrap.getResult(
          JNAPAction.getWANSettings, Map.fromEntries(results));
      final wanSettings = wanSettingsResult == null
          ? null
          : RouterWANSettings.fromJson(wanSettingsResult.output);

      final ipv6SettingsResult = JNAPTransactionSuccessWrap.getResult(
          JNAPAction.getIPv6Settings, Map.fromEntries(results));
      final ipv6Settings = ipv6SettingsResult == null
          ? null
          : GetIPv6Settings.fromJson(ipv6SettingsResult.output);

      final wanStatusResult = JNAPTransactionSuccessWrap.getResult(
          JNAPAction.getWANStatus, Map.fromEntries(results));
      final wanStatus = wanStatusResult == null
          ? null
          : RouterWANStatus.fromMap(wanStatusResult.output);

      final macAddressCloneResult = JNAPTransactionSuccessWrap.getResult(
          JNAPAction.getMACAddressCloneSettings, Map.fromEntries(results));
      final macAddressCloneSettings = macAddressCloneResult == null
          ? null
          : MACAddressCloneSettings.fromMap(macAddressCloneResult.output);

      final lanResult = JNAPTransactionSuccessWrap.getResult(
          JNAPAction.getLANSettings, Map.fromEntries(results));
      final lanSettings = lanResult == null
          ? null
          : RouterLANSettings.fromMap(lanResult.output);

      // Convert to UI models
      InternetSettingsUIModel settings = InternetSettingsUIModel.init();

      // Convert IPv4 settings using appropriate converter
      final currentWanType = WanType.resolve(wanSettings?.wanType ?? '');
      if (currentWanType != null) {
        final ipv4UIModel = _convertIpv4FromJNAP(currentWanType, wanSettings);
        settings = settings.copyWith(ipv4Setting: ipv4UIModel);
      }

      // Convert IPv6 settings using appropriate converter
      final currentIpv6WanType =
          WanIPv6Type.resolve(ipv6Settings?.wanType ?? '');
      if (currentIpv6WanType != null) {
        final ipv6UIModel =
            _convertIpv6FromJNAP(currentIpv6WanType, ipv6Settings);
        settings = settings.copyWith(ipv6Setting: ipv6UIModel);
      }

      // Handle redirection for bridge mode
      String? redirection;
      if (currentWanType != WanType.bridge) {
        await SharedPreferences.getInstance().then((prefs) {
          prefs.remove(pRedirection);
        });
      } else {
        await SharedPreferences.getInstance().then((prefs) {
          redirection = prefs.getString(pRedirection);
        });
      }

      // Build status UI model
      final status = InternetSettingsStatusUIModel(
        supportedIPv4ConnectionType: wanStatus?.supportedWANTypes ?? [],
        supportedWANCombinations: (wanStatus?.supportedWANCombinations ?? [])
            .map((c) => SupportedWANCombinationUIModel(
                  wanType: c.wanType,
                  wanIPv6Type: c.wanIPv6Type,
                ))
            .toList(),
        supportedIPv6ConnectionType: wanStatus?.supportedIPv6WANTypes ?? [],
        duid: ipv6Settings?.duid ?? '',
        redirection: redirection,
        hostname: lanSettings?.hostName,
      );

      // Add MAC clone settings
      settings = settings.copyWith(
        ipv4Setting: settings.ipv4Setting.copyWith(
          ipv4ConnectionType: wanSettings?.wanType ?? '',
          mtu: wanSettings?.mtu ?? 0,
        ),
        macClone: macAddressCloneSettings?.isMACAddressCloneEnabled ?? false,
        macCloneAddress: () => macAddressCloneSettings?.macAddress,
      );

      return (settings, status);
    } on JNAPError catch (e) {
      throw UnexpectedError(originalError: e, message: e.error);
    } catch (e) {
      throw UnexpectedError(
          originalError: e, message: 'Failed to fetch settings');
    }
  }

  /// Saves internet settings to JNAP
  Future<Map<String, dynamic>?> saveSettings(
      InternetSettingsUIModel settings) async {
    try {
      List<MapEntry<JNAPAction, Map<String, dynamic>>> transactions = [
        _getMacAddressCloneTransaction(
            settings.macClone, settings.macCloneAddress),
        ..._getSaveIpv4Transactions(settings),
        ..._getSaveIpv6Transactions(settings),
      ];

      final result = await _routerRepository.transaction(
        JNAPTransactionBuilder(commands: transactions, auth: true),
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
      );

      return _getRedirectionMap(result.data);
    } on JNAPSideEffectError catch (e) {
      // Extract redirection from side effect error if available
      return _extractRedirectionFromSideEffectError(e);
    } on JNAPError catch (e) {
      throw UnexpectedError(originalError: e, message: e.error);
    } catch (e) {
      throw UnexpectedError(
          originalError: e, message: 'Failed to save settings');
    }
  }

  /// Renews DHCP WAN lease
  Future<void> renewDHCPWANLease() async {
    try {
      await _routerRepository.send(
        JNAPAction.renewDHCPWANLease,
        auth: true,
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
      );
      await _ref.read(pollingProvider.notifier).forcePolling();
    } on JNAPError catch (e) {
      throw UnexpectedError(originalError: e, message: e.error);
    }
  }

  /// Renews DHCP IPv6 WAN lease
  Future<void> renewDHCPIPv6WANLease() async {
    try {
      await _routerRepository.send(
        JNAPAction.renewDHCPIPv6WANLease,
        auth: true,
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
      );
      await _ref.read(pollingProvider.notifier).forcePolling();
    } on JNAPError catch (e) {
      throw UnexpectedError(originalError: e, message: e.error);
    }
  }

  /// Gets MAC address of the current device
  Future<String?> getMyMACAddress() async {
    try {
      final result = await _routerRepository.send(
        JNAPAction.getLocalDevice,
        auth: true,
        fetchRemote: true,
      );
      final deviceID = result.output['deviceID'];
      return _ref
          .read(deviceManagerProvider)
          .deviceList
          .firstWhereOrNull((device) => device.deviceID == deviceID)
          ?.getMacAddress();
    } on JNAPError catch (e) {
      throw UnexpectedError(originalError: e, message: e.error);
    }
  }

  // Private helper methods

  /// Fetches internet settings via JNAP transaction
  Future<List<MapEntry<JNAPAction, JNAPResult>>>
      _fetchInternetSettingsTransaction({bool forceRemote = false}) async {
    return _routerRepository
        .transaction(
          fetchRemote: forceRemote,
          JNAPTransactionBuilder(commands: [
            const MapEntry(JNAPAction.getIPv6Settings, {}),
            const MapEntry(JNAPAction.getWANSettings, {}),
            const MapEntry(JNAPAction.getWANStatus, {}),
            const MapEntry(JNAPAction.getMACAddressCloneSettings, {}),
            const MapEntry(JNAPAction.getLANSettings, {}),
          ], auth: true),
        )
        .then((successWrap) => successWrap.data);
  }

  Ipv4SettingsUIModel _convertIpv4FromJNAP(
      WanType wanType, RouterWANSettings? wanSettings) {
    return switch (wanType) {
      WanType.dhcp => DhcpConverter.fromJNAP(wanSettings),
      WanType.pppoe => PppoeConverter.fromJNAP(wanSettings),
      WanType.pptp => PptpConverter.fromJNAP(wanSettings),
      WanType.l2tp => L2tpConverter.fromJNAP(wanSettings),
      WanType.static => StaticConverter.fromJNAP(wanSettings),
      WanType.bridge => BridgeConverter.fromJNAP(wanSettings),
      _ => throw UnexpectedError(message: 'Unknown WAN type: ${wanType.type}'),
    };
  }

  Ipv6SettingsUIModel _convertIpv6FromJNAP(
      WanIPv6Type wanType, GetIPv6Settings? ipv6Settings) {
    return switch (wanType) {
      WanIPv6Type.automatic => AutomaticIpv6Converter.fromJNAP(ipv6Settings),
      _ => DefaultIpv6Converter.fromJNAP(ipv6Settings, wanType),
    };
  }

  List<MapEntry<JNAPAction, Map<String, dynamic>>> _getSaveIpv4Transactions(
      InternetSettingsUIModel data) {
    final wanType = WanType.resolve(data.ipv4Setting.ipv4ConnectionType);
    if (wanType == null) {
      throw UnexpectedError(message: 'Empty ipv4ConnectionType');
    }

    RouterWANSettings wanSettings;
    MapEntry<JNAPAction, Map<String, dynamic>>? additionalSetting;

    switch (wanType) {
      case WanType.dhcp:
        wanSettings = DhcpConverter.toJNAP(data.ipv4Setting);
        break;
      case WanType.pppoe:
        wanSettings = PppoeConverter.toJNAP(data.ipv4Setting);
        break;
      case WanType.pptp:
        wanSettings = PptpConverter.toJNAP(data.ipv4Setting);
        break;
      case WanType.l2tp:
        wanSettings = L2tpConverter.toJNAP(data.ipv4Setting);
        break;
      case WanType.static:
        wanSettings = StaticConverter.toJNAP(data.ipv4Setting);
        break;
      case WanType.bridge:
        wanSettings = BridgeConverter.toJNAP(data.ipv4Setting);
        additionalSetting = BridgeConverter.getAdditionalSetting();
        break;
      default:
        throw UnexpectedError(message: 'Unknown WAN type: ${wanType.type}');
    }

    List<MapEntry<JNAPAction, Map<String, dynamic>>> transactions = [
      MapEntry(JNAPAction.setWANSettings, wanSettings.toJson()),
    ];

    if (additionalSetting != null) {
      transactions.add(additionalSetting);
    }

    return transactions;
  }

  List<MapEntry<JNAPAction, Map<String, dynamic>>> _getSaveIpv6Transactions(
      InternetSettingsUIModel data) {
    final wanType = WanIPv6Type.resolve(data.ipv6Setting.ipv6ConnectionType);
    if (wanType == null) {
      throw UnexpectedError(message: 'Empty ipv6ConnectionType');
    }

    SetIPv6Settings settings;
    switch (wanType) {
      case WanIPv6Type.automatic:
        settings = AutomaticIpv6Converter.toJNAP(data.ipv6Setting);
        break;
      default:
        settings = DefaultIpv6Converter.toJNAP(data.ipv6Setting, wanType);
    }

    return [MapEntry(JNAPAction.setIPv6Settings, settings.toJson())];
  }

  MapEntry<JNAPAction, Map<String, dynamic>> _getMacAddressCloneTransaction(
      bool isMACAddressCloneEnabled, String? macAddress) {
    return MapEntry(
      JNAPAction.setMACAddressCloneSettings,
      MACAddressCloneSettings(
        isMACAddressCloneEnabled: isMACAddressCloneEnabled,
        macAddress: isMACAddressCloneEnabled ? macAddress : null,
      ).toMap(),
    );
  }

  Map<String, dynamic>? _getRedirectionMap(
      List<MapEntry<JNAPAction, JNAPResult>> data) {
    final setWanSettingsResult = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.setWANSettings, Map.fromEntries(data));
    return setWanSettingsResult?.output["redirection"];
  }

  Map<String, dynamic>? _extractRedirectionFromSideEffectError(
      JNAPSideEffectError error) {
    if (error.attach is JNAPTransactionSuccessWrap) {
      final successWrap = error.attach as JNAPTransactionSuccessWrap;
      return _getRedirectionMap(successWrap.data);
    }
    // If no attach or cannot extract redirection, rethrow
    throw error;
  }
}
