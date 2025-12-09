import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/models/alg_settings.dart';
import 'package:privacy_gui/core/jnap/models/express_forwarding_settings.dart';
import 'package:privacy_gui/core/jnap/models/management_settings.dart';
import 'package:privacy_gui/core/jnap/models/unpn_settings.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
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
    final repo = ref.read(routerRepositoryProvider);
    final result = await repo.transaction(
      JNAPTransactionBuilder(commands: [
        const MapEntry(
          JNAPAction.getManagementSettings,
          {},
        ),
        const MapEntry(
          JNAPAction.getUPnPSettings,
          {},
        ),
        const MapEntry(
          JNAPAction.getALGSettings,
          {},
        ),
        const MapEntry(
          JNAPAction.getExpressForwardingSettings,
          {},
        ),
      ], auth: true),
      fetchRemote: forceRemote,
    );
    final resultMap = Map.fromEntries(result.data);
    final managementSettingsResult = JNAPTransactionSuccessWrap.getResult(
            JNAPAction.getManagementSettings, resultMap)
        ?.output;
    final managementSettings = managementSettingsResult != null
        ? ManagementSettings.fromMap(managementSettingsResult)
        : null;
    final upnpSettingsResult = JNAPTransactionSuccessWrap.getResult(
            JNAPAction.getUPnPSettings, resultMap)
        ?.output;
    final upnpSettings = upnpSettingsResult != null
        ? UPnPSettings.fromMap(upnpSettingsResult)
        : null;

    final algSettingsResult = JNAPTransactionSuccessWrap.getResult(
            JNAPAction.getALGSettings, resultMap)
        ?.output;
    final algSettings = algSettingsResult != null
        ? ALGSettings.fromMap(algSettingsResult)
        : null;

    final expressForwardingSettingsResult =
        JNAPTransactionSuccessWrap.getResult(
                JNAPAction.getExpressForwardingSettings, resultMap)
            ?.output;
    final expressForwardingSettings = expressForwardingSettingsResult != null
        ? ExpressForwardingSettings.fromMap(expressForwardingSettingsResult)
        : null;

    final hasLanPort =
        ref.read(dashboardHomeProvider).lanPortConnections.isNotEmpty;

    final newSettings = AdministrationSettings(
      managementSettings: managementSettings!,
      isUPnPEnabled: upnpSettings?.isUPnPEnabled ?? false,
      canUsersConfigure: upnpSettings?.canUsersConfigure ?? false,
      canUsersDisableWANAccess: upnpSettings?.canUsersDisableWANAccess ?? false,
      enabledALG: algSettings?.isSIPEnabled ?? false,
      isExpressForwardingSupported:
          expressForwardingSettings?.isExpressForwardingSupported ?? false,
      enabledExpressForwarfing:
          expressForwardingSettings?.isExpressForwardingEnabled ?? false,
      canDisAllowLocalMangementWirelessly: hasLanPort,
    );

    return (newSettings, const AdministrationStatus());
  }

  @override
  Future<void> performSave() async {
    final repo = ref.read(routerRepositoryProvider);
    await repo.transaction(
      JNAPTransactionBuilder(commands: [
        MapEntry(
          JNAPAction.setManagementSettings,
          state.current.managementSettings.toMap()
            ..remove('isManageWirelesslySupported'),
        ),
        MapEntry(
          JNAPAction.setUPnPSettings,
          {
            'isUPnPEnabled': state.current.isUPnPEnabled,
            'canUsersConfigure': state.current.canUsersConfigure,
            'canUsersDisableWANAccess': state.current.canUsersDisableWANAccess,
          },
        ),
        MapEntry(
          JNAPAction.setALGSettings,
          {'isSIPEnabled': state.current.enabledALG},
        ),
        MapEntry(
          JNAPAction.setExpressForwardingSettings,
          {
            'isExpressForwardingEnabled': state.current.enabledExpressForwarfing
          },
        ),
      ], auth: true),
    );
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
