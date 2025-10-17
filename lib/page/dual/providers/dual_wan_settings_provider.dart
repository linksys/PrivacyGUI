import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/models/dual_wan_status.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/jnap/models/dual_wan_settings.dart';
import 'package:privacy_gui/core/jnap/models/dual_wan_ethernet_port.dart';
import 'package:privacy_gui/page/dual/models/balance_ratio.dart';
import 'package:privacy_gui/page/dual/models/logging_option.dart';
import 'package:privacy_gui/page/dual/models/mode.dart';
import 'package:privacy_gui/page/dual/models/port.dart';
import 'package:privacy_gui/page/dual/models/port_type.dart';
import 'package:privacy_gui/page/dual/models/wan_configuration.dart';
import 'package:privacy_gui/page/dual/providers/dual_wan_settings_state.dart';

final dualWANSettingsProvider =
    NotifierProvider<DualWANSettingsNotifier, DualWANSettingsState>(
        () => DualWANSettingsNotifier());

class DualWANSettingsNotifier extends Notifier<DualWANSettingsState> {
  @override
  DualWANSettingsState build() {
    return DualWANSettingsState.init();
  }

  Future<DualWANSettingsState> fetch(
      [bool fetchRemote = true, bool statusOnly = false]) async {
    final repo = ref.read(routerRepositoryProvider);
    final settings = await repo
        .send(JNAPAction.getDualWANSettings,
            auth: true, fetchRemote: fetchRemote)
        .then((result) {
      return RouterDualWANSettings.fromMap(result.output);
    });
    RouterDualWANStatus? status;
    List<DualWANPort> ports = [];
    if (settings.enabled) {
      final builder = JNAPTransactionBuilder(commands: [
        MapEntry(JNAPAction.getDualWANStatus, {}),
        MapEntry(JNAPAction.getDualWANEthernetPortConnections, {}),
      ], auth: true);

      await repo.transaction(builder).then((result) {
        final dualWANStatusData = (result.data
                .firstWhereOrNull(
                    (entry) => entry.key == JNAPAction.getDualWANStatus)
                ?.value as JNAPSuccess?)
            ?.output;
        final portsData = (result.data
                .firstWhereOrNull((entry) =>
                    entry.key == JNAPAction.getDualWANEthernetPortConnections)
                ?.value as JNAPSuccess?)
            ?.output;

        if (dualWANStatusData != null) {
          status = RouterDualWANStatus.fromMap(dualWANStatusData);
        }
        if (portsData != null) {
          final dualWANPorts =
              DualWANEthernetPortConnections.fromMap(portsData);
          ports = [
            DualWANPort(
                type: PortType.wan1,
                speed: dualWANPorts.primaryWANPortConnection),
            DualWANPort(
                type: PortType.wan2,
                speed: dualWANPorts.secondaryWANPortConnection),
            ...dualWANPorts.lanPortConnections
                .map((e) => DualWANPort(type: PortType.lan, speed: e)),
          ];
        }
      });
    }
    // TODO: Log options
    DualWANSettings dualWANSettings = DualWANSettings.fromData(settings);
    // TODO: Speed data
    DualWANStatus? dualWANStatus = status != null
        ? DualWANStatus.fromData(data: status!, ports: ports)
        : null;
    if (statusOnly) {
      state = state.copyWith(
        status: dualWANStatus,
      );
    } else {
      state = state.copyWith(
        settings: dualWANSettings,
        status: dualWANStatus,
      );
    }
    return state;
  }

  Future<DualWANSettingsState> save() async {
    final settings = RouterDualWANSettings(
      enabled: state.settings.enable,
      mode: DualWANModeData.fromJson(state.settings.mode.toValue()),
      ratio: state.settings.balanceRatio != null
          ? DualWANRatioData.fromJson(state.settings.balanceRatio!.toValue())
          : null,
      primaryWAN: state.settings.primaryWAN.toData(),
      secondaryWAN: state.settings.secondaryWAN.toData(),
    );
    final repo = ref.read(routerRepositoryProvider);
    await repo.send(JNAPAction.setDualWANSettings,
        auth: true, data: settings.toMap());

    // Not sure why the GetDualWANSettings can't be used after setDualWANSettings
    // Try to delay for 3 second
    await Future.delayed(const Duration(seconds: 3));
    return fetch(true);
  }

  void updateDualWANEnable(bool enable) {
    state = state.copyWith(settings: state.settings.copyWith(enable: enable));
  }

  void updateOperationMode(DualWANMode mode) {
    state = state.copyWith(settings: state.settings.copyWith(mode: mode));
  }

  void updateBalanceRatio(DualWANBalanceRatio ratio) {
    state =
        state.copyWith(settings: state.settings.copyWith(balanceRatio: ratio));
  }

  void updatePrimaryWAN(DualWANConfiguration wan) {
    state = state.copyWith(settings: state.settings.copyWith(primaryWAN: wan));
  }

  void updateSecondaryWAN(DualWANConfiguration wan) {
    state =
        state.copyWith(settings: state.settings.copyWith(secondaryWAN: wan));
  }

  void updateLoggingOptions(LoggingOptions options) {
    state = state.copyWith(
        settings: state.settings.copyWith(loggingOptions: options));
  }
}
