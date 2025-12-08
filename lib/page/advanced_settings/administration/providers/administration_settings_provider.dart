import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/models/management_settings.dart';
import 'package:privacy_gui/page/advanced_settings/administration/services/administration_settings_service.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';

import 'administration_settings_state.dart';

final administrationSettingsProvider = NotifierProvider<
    AdministrationSettingsNotifier,
    AdministrationSettingsState>(() => AdministrationSettingsNotifier());

final preservableAdministrationSettingsProvider = Provider<PreservableContract>(
  (ref) => ref.watch(administrationSettingsProvider.notifier),
);

class AdministrationSettingsNotifier
    extends Notifier<AdministrationSettingsState>
    with
        PreservableNotifierMixin<AdministrationSettings, AdministrationStatus,
            AdministrationSettingsState> {
  @override
  AdministrationSettingsState build() => AdministrationSettingsState(
        settings: Preservable(
          original: const AdministrationSettings(
            managementSettings: ManagementSettings(
              canManageUsingHTTP: false,
              canManageUsingHTTPS: false,
              isManageWirelesslySupported: false,
              canManageRemotely: false,
            ),
            enabledALG: false,
            isExpressForwardingSupported: false,
            enabledExpressForwarfing: false,
            isUPnPEnabled: false,
            canUsersConfigure: false,
            canUsersDisableWANAccess: false,
          ),
          current: const AdministrationSettings(
            managementSettings: ManagementSettings(
              canManageUsingHTTP: false,
              canManageUsingHTTPS: false,
              isManageWirelesslySupported: false,
              canManageRemotely: false,
            ),
            enabledALG: false,
            isExpressForwardingSupported: false,
            enabledExpressForwarfing: false,
            isUPnPEnabled: false,
            canUsersConfigure: false,
            canUsersDisableWANAccess: false,
          ),
        ),
        status: const AdministrationStatus(),
      );

  @override
  Future<(AdministrationSettings?, AdministrationStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    final service = AdministrationSettingsService();
    final settings = await service.fetchAdministrationSettings(
      ref,
      forceRemote: forceRemote,
      updateStatusOnly: updateStatusOnly,
    );
    return (settings, const AdministrationStatus());
  }

  @override
  Future<void> performSave() async {
    final service = AdministrationSettingsService();
    await service.saveAdministrationSettings(ref, state.current);
  }

  void setManagementSettings(bool value) {
    state = state.copyWith(
      settings: state.settings.copyWith(
        current: state.current.copyWith(
          managementSettings: state.current.managementSettings.copyWith(
            canManageWirelessly: value,
          ),
        ),
      ),
    );
  }

  void setUPnPEnabled(bool value) {
    state = state.copyWith(
      settings: state.settings.copyWith(
        current: state.current.copyWith(isUPnPEnabled: value),
      ),
    );
  }

  void setCanUsersConfigure(bool value) {
    state = state.copyWith(
      settings: state.settings.copyWith(
        current: state.current.copyWith(canUsersConfigure: value),
      ),
    );
  }

  void setCanUsersDisableWANAccess(bool value) {
    state = state.copyWith(
      settings: state.settings.copyWith(
        current: state.current.copyWith(canUsersDisableWANAccess: value),
      ),
    );
  }

  void setALGEnabled(bool value) {
    state = state.copyWith(
      settings: state.settings.copyWith(
        current: state.current.copyWith(enabledALG: value),
      ),
    );
  }

  void setExpressForwarding(bool value) {
    state = state.copyWith(
      settings: state.settings.copyWith(
        current: state.current.copyWith(enabledExpressForwarfing: value),
      ),
    );
  }
}
