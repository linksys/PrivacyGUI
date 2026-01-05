import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/internet_settings_service.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv4/dhcp_converter.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv4/pppoe_converter.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv4/pptp_converter.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv4/l2tp_converter.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv4/static_converter.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv4/bridge_converter.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv6/automatic_ipv6_converter.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv6/default_ipv6_converter.dart';
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

  @override
  Future<(InternetSettings?, InternetSettingsStatus?)> performFetch(
      {bool forceRemote = false, bool updateStatusOnly = false}) async {
    try {
      final service = ref.read(internetSettingsServiceProvider);
      final (settings, status) =
          await service.fetchSettings(forceRemote: forceRemote);
      return (settings, status);
    } on ServiceError catch (e) {
      logger.e('Failed to fetch internet settings: $e');
      rethrow;
    }
  }

  @override
  Future<void> performSave() async {
    try {
      final service = ref.read(internetSettingsServiceProvider);
      final redirectionMap = await service.saveSettings(state.settings.current);

      final originalWanType = WanType.resolve(
          state.settings.original.ipv4Setting.ipv4ConnectionType);

      final finalRedirectionMap = originalWanType == WanType.bridge
          ? {'hostName': 'www.myrouter', 'domain': 'info'}
          : redirectionMap;

      _handleWebRedirection(finalRedirectionMap);
    } on ServiceError catch (e) {
      logger.e('Failed to save internet settings: $e');
      rethrow;
    }
  }

  Future savePnpIpv4(InternetSettings data) async {
    try {
      final service = ref.read(internetSettingsServiceProvider);
      await service.saveSettings(data);
      await fetch();
    } on ServiceError catch (e) {
      logger.e('Failed to save PnP IPv4 settings: $e');
      rethrow;
    }
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

  Future<String?> getMyMACAddress() async {
    try {
      final service = ref.read(internetSettingsServiceProvider);
      return await service.getMyMACAddress();
    } on ServiceError catch (e) {
      logger.e('Failed to get MAC address: $e');
      rethrow;
    }
  }

  Future renewDHCPWANLease() async {
    try {
      final service = ref.read(internetSettingsServiceProvider);
      await service.renewDHCPWANLease();
      // Note: forcePolling() is already called inside service layer
    } on ServiceError catch (e) {
      logger.e('Failed to renew DHCP WAN lease: $e');
      rethrow;
    }
  }

  Future renewDHCPIPv6WANLease() async {
    try {
      final service = ref.read(internetSettingsServiceProvider);
      await service.renewDHCPIPv6WANLease();
      // Note: forcePolling() is already called inside service layer
    } on ServiceError catch (e) {
      logger.e('Failed to renew DHCP IPv6 WAN lease: $e');
      rethrow;
    }
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
    if (wanType == null) return;

    final updatedIpv4Setting = switch (wanType) {
      WanType.dhcp => DhcpConverter.updateFromForm(
          state.settings.current.ipv4Setting, ipv4Setting),
      WanType.pppoe => PppoeConverter.updateFromForm(
          state.settings.current.ipv4Setting, ipv4Setting),
      WanType.pptp => PptpConverter.updateFromForm(
          state.settings.current.ipv4Setting, ipv4Setting),
      WanType.l2tp => L2tpConverter.updateFromForm(
          state.settings.current.ipv4Setting, ipv4Setting),
      WanType.static => StaticConverter.updateFromForm(
          state.settings.current.ipv4Setting, ipv4Setting),
      WanType.bridge => BridgeConverter.updateFromForm(
          state.settings.current.ipv4Setting, ipv4Setting),
      _ => state.settings.current.ipv4Setting,
    };

    state = state.copyWith(
        settings: state.settings.update(
            state.settings.current.copyWith(ipv4Setting: updatedIpv4Setting)));
  }

  void updateIpv6Settings(Ipv6Setting ipv6Setting) {
    final wanIpv6Type = WanIPv6Type.resolve(ipv6Setting.ipv6ConnectionType);
    if (wanIpv6Type == null) return;

    final updatedIpv6Setting = switch (wanIpv6Type) {
      WanIPv6Type.automatic => AutomaticIpv6Converter.updateFromForm(
          state.settings.current.ipv6Setting, ipv6Setting),
      _ => DefaultIpv6Converter.updateFromForm(
          state.settings.current.ipv6Setting, ipv6Setting),
    };

    state = state.copyWith(
        settings: state.settings.update(
            state.settings.current.copyWith(ipv6Setting: updatedIpv6Setting)));
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
