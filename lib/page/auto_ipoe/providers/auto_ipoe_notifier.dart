import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_state.dart';
import 'package:privacy_gui/page/auto_ipoe/service/auto_ipoe_service.dart';

final autoIPoEProvider = NotifierProvider<AutoIPoENotifier, AutoIPoEState>(
  AutoIPoENotifier.new,
);

class AutoIPoENotifier extends Notifier<AutoIPoEState> {
  @override
  AutoIPoEState build() => const AutoIPoEState.init();

  Future<AutoIPoEState> fetchAll() async {
    // The router has to advertise the AutoIPoE service before any of its
    // actions may be sent. Internet Settings fetches on entry, unconditionally,
    // so without this gate every router that lacks the service answers all four
    // calls with an error and takes the whole page's initial load down with it.
    // Staying at the init state is the honest answer: `isSupported == false` is
    // already how the rest of the code spells "this router cannot do AutoIPoE".
    if (!serviceHelper.isSupportAutoIPoE()) {
      return state;
    }
    final service = ref.read(autoIPoEServiceProvider);
    final capabilities = await service.getCapabilities();
    final settings = await service.getSettings();
    final status = await service.getStatus();
    final log = await service.getLog();
    state = state.copyWith(
      capabilities: capabilities,
      settings: settings,
      status: status,
      log: log,
    );
    return state;
  }

  Future<AutoIPoEState> refreshStatus() async {
    final status = await ref.read(autoIPoEServiceProvider).getStatus();
    state = state.copyWith(status: status);
    return state;
  }

  Future<AutoIPoEState> refreshRuntime() async {
    final service = ref.read(autoIPoEServiceProvider);
    final status = await service.getStatus();
    final log = await service.getLog();
    state = state.copyWith(status: status, log: log);
    return state;
  }

  void updateRuntime(AutoIPoEStatus status, AutoIPoELog log) {
    state = state.copyWith(status: status, log: log);
  }

  Future<AutoIPoEState> saveSettings(AutoIPoESettings settings) async {
    final service = ref.read(autoIPoEServiceProvider);
    await service.setSettings(settings);
    state = state.copyWith(settings: settings);
    return refreshStatus();
  }

  Future<AutoIPoEState> apply({bool resetFirst = false}) async {
    final status = await ref.read(autoIPoEServiceProvider).apply(
          resetFirst: resetFirst,
          settings: state.settings,
        );
    state = state.copyWith(status: status);
    return state;
  }

  Future<AutoIPoEState> reset() async {
    final status = await ref.read(autoIPoEServiceProvider).reset();
    final settings = state.settings.copyWith(
      isEnabled: false,
      selectedMode: AutoIPoEMode.disabled,
    );
    state = state.copyWith(settings: settings, status: status);
    return state;
  }

  void updateSettings(AutoIPoESettings settings) {
    state = state.copyWith(settings: settings);
  }
}
