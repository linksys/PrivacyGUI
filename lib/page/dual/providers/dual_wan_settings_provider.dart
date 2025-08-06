import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dual/models/balance_ratio.dart';
import 'package:privacy_gui/page/dual/models/logging_option.dart';
import 'package:privacy_gui/page/dual/models/mode.dart';
import 'package:privacy_gui/page/dual/models/wan_configuration.dart';
import 'package:privacy_gui/page/dual/providers/dual_wan_settings_state.dart';

final dualWANSettingsProvider =
    NotifierProvider<DualWANSettingsNotifier, DualWANSettingsState>(
        () => DualWANSettingsNotifier());

class DualWANSettingsNotifier extends Notifier<DualWANSettingsState> {
  @override
  DualWANSettingsState build() {
    return DualWANSettingsState.mock();
  }

  Future<DualWANSettingsState> fetch([bool fetchRemote = true]) async {
    return Future.delayed(const Duration(seconds: 1)).then((_) => state);
  }

  Future<DualWANSettingsState> save() async {
    return Future.delayed(const Duration(seconds: 1)).then((_) => state);
  }

  void updateDualWANEnable(bool enable) {
    state = state.copyWith(enable: enable);
  }

  void updateOperationMode(DualWANMode mode) {
    state = state.copyWith(mode: mode);
  }

  void updateBalanceRatio(DualWANBalanceRatio ratio) {
    state = state.copyWith(balanceRatio: ratio);
  }
  void updatePrimaryWAN(DualWANConfiguration wan) {
    state = state.copyWith(primaryWAN: wan);
  }
  void updateSecondaryWAN(DualWANConfiguration wan) {
    state = state.copyWith(secondaryWAN: wan);
  }

  void updateLoggingOptions(LoggingOptions options) {
    state = state.copyWith(loggingOptions: options);
  }
}
