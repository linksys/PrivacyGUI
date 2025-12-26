import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/models/_models.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/providers/ddns_state.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/services/_services.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';

final ddnsProvider =
    NotifierProvider<DDNSNotifier, DDNSState>(() => DDNSNotifier());

final preservableDDNSProvider = Provider<PreservableContract>(
  (ref) => ref.watch(ddnsProvider.notifier),
);

/// DDNS feature notifier
///
/// Uses Service layer for JNAP communication per constitution Article V & VI.
/// Only handles state management and UI coordination.
class DDNSNotifier extends Notifier<DDNSState>
    with
        PreservableNotifierMixin<DDNSSettingsUIModel, DDNSStatusUIModel,
            DDNSState> {
  @override
  DDNSState build() {
    const settings = DDNSSettingsUIModel(provider: NoDDNSProviderUIModel());
    return DDNSState(
      settings: Preservable(original: settings, current: settings),
      status: const DDNSStatusUIModel(
        supportedProviders: [],
        status: '',
        ipAddress: '',
      ),
    );
  }

  @override
  Future<(DDNSSettingsUIModel?, DDNSStatusUIModel?)> performFetch(
      {bool forceRemote = false, bool updateStatusOnly = false}) async {
    final service = ref.read(ddnsServiceProvider);
    final result = await service.fetchDDNSData(forceRemote: forceRemote);

    logger.d('[State]:[DDNS]: ${state.toJson()}');
    return (result.settings, result.status);
  }

  /// Refreshes DDNS status only
  Future<void> getStatus() async {
    final service = ref.read(ddnsServiceProvider);
    final status = await service.refreshStatus();
    state = state.copyWith(status: state.status.copyWith(status: status));
  }

  @override
  Future<void> performSave() async {
    final service = ref.read(ddnsServiceProvider);
    await service.saveDDNSSettings(state.settings.current);
  }

  /// Sets the DDNS provider type
  void setProvider(String value) {
    state = state.copyWith(
      settings: state.settings.copyWith(
        current: state.settings.current.copyWith(
          provider: DDNSProviderUIModel.create(value),
        ),
      ),
    );
  }

  /// Updates provider-specific settings
  void setProviderSettings(DDNSProviderUIModel settings) {
    final provider = state.settings.current.provider.applySettings(settings);
    state = state.copyWith(
      settings: state.settings.copyWith(
        current: state.settings.current.copyWith(provider: provider),
      ),
    );
  }

  /// Validates current settings
  bool isDataValid() {
    final service = ref.read(ddnsServiceProvider);
    return service.validateSettings(state.settings.current.provider);
  }
}
