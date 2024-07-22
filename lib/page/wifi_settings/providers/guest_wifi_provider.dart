import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/wifi_settings/providers/guest_wifi_state.dart';

final guestWifiProvider = NotifierProvider<GuestWifiNotifier, GuestWiFiState>(
  () => GuestWifiNotifier(),
);

class GuestWifiNotifier extends Notifier<GuestWiFiState> {
  @override
  GuestWiFiState build() {
    // final dashboardManagerState = ref.watch(dashboardManagerProvider);
    // final deviceManagerState = ref.watch(deviceManagerProvider);
    // return _getWifiList(deviceManagerState, dashboardManagerState);
    return const GuestWiFiState(
        isEnabled: false, ssid: '', password: '', numOfDevices: 0);
  }

  Future<GuestWiFiState> fetch([bool force = false]) async {
    final guestRadioInfo = await ref
        .read(routerRepositoryProvider)
        .send(JNAPAction.getGuestRadioSettings, fetchRemote: force, auth: true)
        .then((response) => GuestRadioSettings.fromMap(response.output));
    state = state.copyWith(
        isEnabled: guestRadioInfo.isGuestNetworkEnabled,
        ssid: guestRadioInfo.radios.firstOrNull?.guestSSID ?? '',
        password: guestRadioInfo.radios.firstOrNull?.guestWPAPassphrase ?? '');
    return state;
  }

  Future<GuestWiFiState> save() async {
    final guestRadioInfo = await ref
        .read(routerRepositoryProvider)
        .send(JNAPAction.getGuestRadioSettings, auth: true)
        .then((response) => GuestRadioSettings.fromMap(response.output));
    final setGuestRadioSettings =
        SetGuestRadioSettings.fromGuestRadioSettings(guestRadioInfo);
    final newRadios = setGuestRadioSettings.radios
        .map((e) => e.copyWith(
            isEnabled: state.isEnabled,
            guestSSID: state.ssid,
            guestWPAPassphrase: state.password))
        .toList();
    final newSetGuestRadioSettings = setGuestRadioSettings.copyWith(
        isGuestNetworkEnabled: state.isEnabled, radios: newRadios);
    await ref.read(routerRepositoryProvider).send(
          JNAPAction.setGuestRadioSettings,
          data: newSetGuestRadioSettings.toMap(),
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
          auth: true,
        );
    return await fetch(true);
  }

  GuestWiFiState _getWifiList(
    DeviceManagerState deviceManagerState,
    DashboardManagerState dashboardManagerState,
  ) {
    final guestRadio = dashboardManagerState.guestRadios.firstOrNull;
    final state = GuestWiFiState(
      isEnabled: guestRadio?.isEnabled ?? false,
      ssid: guestRadio?.guestSSID ?? '',
      password: guestRadio?.guestWPAPassphrase ?? '',
      numOfDevices: deviceManagerState.guestWifiDevices
          .where((device) => device.connections.isNotEmpty)
          .length,
    );

    return state;
  }

  void setGuestSSID(String ssid) {
    state = state.copyWith(ssid: ssid);
  }

  void setGuestPassword(String password) {
    state = state.copyWith(password: password);
  }

  void setEnable(bool enable) {
    state = state.copyWith(isEnabled: enable);
  }
}
