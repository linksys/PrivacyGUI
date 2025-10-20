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
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';

import 'administration_settings_state.dart';

final administrationSettingsProvider = NotifierProvider<
    AdministrationSettingsNotifier,
    AdministrationSettingsState>(() => AdministrationSettingsNotifier());

class AdministrationSettingsNotifier
    extends Notifier<AdministrationSettingsState>
    with
        PreservableNotifierMixin<AdministrationSettings, AdministrationStatus,
            AdministrationSettingsState> {
  @override
  AdministrationSettingsState build() {
    return const AdministrationSettingsState(
      settings: AdministrationSettings(
        managementSettings: ManagementSettings(
          canManageUsingHTTP: false,
          canManageUsingHTTPS: false,
          isManageWirelesslySupported: false,
          canManageRemotely: false,
        ),
        enabledALG: false,
        enabledExpressForwarfing: false,
        isUPnPEnabled: false,
        canUsersConfigure: false,
        canUsersDisableWANAccess: false,
      ),
      status: AdministrationStatus(isExpressForwardingSupported: false),
    );
  }

  @override
  Future<void> performFetch() async {
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

    state = state.copyWith(
      settings: state.settings.copyWith(
        managementSettings: managementSettings,
        isUPnPEnabled: upnpSettings?.isUPnPEnabled,
        canUsersConfigure: upnpSettings?.canUsersConfigure,
        canUsersDisableWANAccess: upnpSettings?.canUsersDisableWANAccess,
        enabledALG: algSettings?.isSIPEnabled,
        enabledExpressForwarfing:
            expressForwardingSettings?.isExpressForwardingEnabled,
        canDisAllowLocalMangementWirelessly: hasLanPort,
      ),
      status: AdministrationStatus(
        isExpressForwardingSupported:
            expressForwardingSettings?.isExpressForwardingSupported ?? false,
      ),
    );
  }

  @override
  Future<void> performSave() async {
    final repo = ref.read(routerRepositoryProvider);
    await repo.transaction(
      JNAPTransactionBuilder(commands: [
        MapEntry(
          JNAPAction.setManagementSettings,
          state.settings.managementSettings.toMap()
            ..remove('isManageWirelesslySupported'),
        ),
        MapEntry(
          JNAPAction.setUPnPSettings,
          {
            'isUPnPEnabled': state.settings.isUPnPEnabled,
            'canUsersConfigure': state.settings.canUsersConfigure,
            'canUsersDisableWANAccess': state.settings.canUsersDisableWANAccess,
          },
        ),
        MapEntry(
          JNAPAction.setALGSettings,
          {'isSIPEnabled': state.settings.enabledALG},
        ),
        MapEntry(
          JNAPAction.setExpressForwardingSettings,
          {
            'isExpressForwardingEnabled':
                state.settings.enabledExpressForwarfing
          },
        ),
      ], auth: true),
    );
  }

  void setManagementSettings(bool value) {
    state = state.copyWith(
        settings: state.settings.copyWith(
            managementSettings: state.settings.managementSettings
                .copyWith(canManageWirelessly: value)));
  }

  void setUPnPEnabled(bool value) {
    state =
        state.copyWith(settings: state.settings.copyWith(isUPnPEnabled: value));
  }

  void setCanUsersConfigure(bool value) {
    state = state.copyWith(
        settings: state.settings.copyWith(canUsersConfigure: value));
  }



  void setCanUsersDisableWANAccess(bool value) {
    state = state.copyWith(
        settings: state.settings.copyWith(canUsersDisableWANAccess: value));
  }

  void setALGEnabled(bool value) {
    state = state.copyWith(settings: state.settings.copyWith(enabledALG: value));
  }

  void setExpressForwarding(bool value) {
    state = state.copyWith(
        settings: state.settings.copyWith(enabledExpressForwarfing: value));
  }
}

final preservableAdministrationSettingsProvider = Provider.autoDispose<
    PreservableContract<AdministrationSettings,
        AdministrationStatus>>((ref) {
  return ref.watch(administrationSettingsProvider.notifier);
});
