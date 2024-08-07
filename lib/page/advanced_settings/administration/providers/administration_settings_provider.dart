import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/models/alg_settings.dart';
import 'package:privacy_gui/core/jnap/models/express_forwarding_settings.dart';
import 'package:privacy_gui/core/jnap/models/management_settings.dart';
import 'package:privacy_gui/core/jnap/models/unpn_settings.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';

import 'administration_settings_state.dart';

final administrationSettingsProvider = NotifierProvider<
    AdministrationSettingsNotifier,
    AdministrationSettingsState>(() => AdministrationSettingsNotifier());

class AdministrationSettingsNotifier
    extends Notifier<AdministrationSettingsState> {
  @override
  AdministrationSettingsState build() => const AdministrationSettingsState(
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
      canUsersDisableWANAccess: false);

  Future<AdministrationSettingsState> fetch([bool force = false]) async {
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
      fetchRemote: force,
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

    state = state.copyWith(
        managementSettings: managementSettings,
        isUPnPEnabled: upnpSettings?.isUPnPEnabled,
        canUsersConfigure: upnpSettings?.canUsersConfigure,
        canUsersDisableWANAccess: upnpSettings?.canUsersDisableWANAccess,
        enabledALG: algSettings?.isSIPEnabled,
        isExpressForwardingSupported:
            expressForwardingSettings?.isExpressForwardingSupported,
        enabledExpressForwarfing:
            expressForwardingSettings?.isExpressForwardingEnabled);
    return state;
  }

  Future<AdministrationSettingsState> save() async {
    final repo = ref.read(routerRepositoryProvider);
    await repo.transaction(
      JNAPTransactionBuilder(commands: [
        MapEntry(
          JNAPAction.setManagementSettings,
          state.managementSettings.toMap()
            ..remove('isManageWirelesslySupported'),
        ),
        MapEntry(
          JNAPAction.setUPnPSettings,
          {
            'isUPnPEnabled': state.isUPnPEnabled,
            'canUsersConfigure': state.canUsersConfigure,
            'canUsersDisableWANAccess': state.canUsersDisableWANAccess,
          },
        ),
        MapEntry(
          JNAPAction.setALGSettings,
          {'isSIPEnabled': state.enabledALG},
        ),
        MapEntry(
          JNAPAction.setExpressForwardingSettings,
          {'isExpressForwardingEnabled': state.enabledExpressForwarfing},
        ),
      ], auth: true),
    );
    await fetch(true);
    return state;
  }

  void setManagementSettings(bool value) {
    state = state.copyWith(
        managementSettings:
            state.managementSettings.copyWith(canManageWirelessly: value));
  }

  void setUPnPEnabled(bool value) {
    state = state.copyWith(isUPnPEnabled: value);
  }

  void setCanUsersConfigure(bool value) {
    state = state.copyWith(canUsersConfigure: value);
  }

  void setCanUsersDisableWANAccess(bool value) {
    state = state.copyWith(canUsersDisableWANAccess: value);
  }

  void setALGEnabled(bool value) {
    state = state.copyWith(enabledALG: value);
  }

  void setExpressForwarding(bool value) {
    state = state.copyWith(enabledExpressForwarfing: value);
  }
}
