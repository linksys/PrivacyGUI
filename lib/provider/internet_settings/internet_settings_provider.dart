import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/extensions/_extensions.dart';
import 'package:linksys_app/core/jnap/models/ipv6_automatic_settings.dart';
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

  fetch() async {
    final repo = ref.read(routerRepositoryProvider);
    final results = await repo.fetchInternetSettings();
    final wanSettings =
        JNAPTransactionSuccessWrap.getResult(JNAPAction.getWANSettings, results)
            ?.output;
    final ipv6Settings = JNAPTransactionSuccessWrap.getResult(
            JNAPAction.getIPv6Settings, results)
        ?.output;
    final wanStatusJson =
        JNAPTransactionSuccessWrap.getResult(JNAPAction.getWANStatus, results);
    final wanStatus = wanStatusJson == null
        ? null
        : RouterWANStatus.fromJson(wanStatusJson.output);
    final ipv6AutomaticSettings = ipv6Settings?['ipv6AutomaticSettings'] == null
        ? null
        : IPv6AutomaticSettings.fromJson(
            ipv6Settings!['ipv6AutomaticSettings']);
    final macAddressCloneSettings = JNAPTransactionSuccessWrap.getResult(
            JNAPAction.getMACAddressCloneSettings, results)
        ?.output;
    state = state.copyWith(
      ipv4ConnectionType: wanSettings?['wanType'] ?? '',
      ipv6ConnectionType: ipv6Settings?['wanType'] ?? '',
      supportedIPv4ConnectionType: wanStatus?.supportedWANTypes ?? [],
      supportedIPv6ConnectionType: wanStatus?.supportedIPv6WANTypes ?? [],
      supportedWANCombinations: wanStatus?.supportedWANCombinations ?? [],
      mtu: wanSettings?['mtu'] ?? 0,
      duid: ipv6Settings?['duid'] ?? '',
      isIPv6AutomaticEnabled:
          ipv6AutomaticSettings?.isIPv6AutomaticEnabled ?? false,
      macClone: macAddressCloneSettings?['isMACAddressCloneEnabled'] ?? false,
      macCloneAddress: macAddressCloneSettings?['macAddress'] ?? '',
    );
  }

  setIPv4ConnectionType(String connectionType) {
    state = state.copyWith(ipv4ConnectionType: connectionType);
  }

  setIPv6ConnectionType(String connectionType) {
    state = state.copyWith(ipv6ConnectionType: connectionType);
  }

  setMtu(int mtu) {
    state = state.copyWith(mtu: mtu);
  }

  setMacClone(bool isEnabled, String mac) {
    state = state.copyWith(macClone: isEnabled, macCloneAddress: mac);
  }
}
