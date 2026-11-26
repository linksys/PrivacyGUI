import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/management_settings.dart';
import 'package:privacy_gui/page/advanced_settings/administration/providers/administration_settings_state.dart';

const _state = AdministrationSettingsState(
  managementSettings: ManagementSettings(
    canManageUsingHTTP: true,
    canManageUsingHTTPS: true,
    isManageWirelesslySupported: true,
    canManageWirelessly: false,
    canManageRemotely: false,
  ),
  enabledALG: true,
  isExpressForwardingSupported: true,
  enabledExpressForwarfing: false,
  isUPnPEnabled: true,
  canUsersConfigure: false,
  canUsersDisableWANAccess: true,
  canDisAllowLocalMangementWirelessly: false,
);

void main() {
  test('survives a trip through JSON text', () {
    expect(AdministrationSettingsState.fromJson(_state.toJson()), _state);
  });

  test('offers to block wireless management when the map does not say', () {
    final map = _state.toMap()..remove('canDisAllowLocalMangementWirelessly');

    final read = AdministrationSettingsState.fromMap(map);

    expect(read.canDisAllowLocalMangementWirelessly, isTrue);
  });

  test('copyWith changes only what it names', () {
    final changed = _state.copyWith(enabledALG: false);

    expect(changed.enabledALG, isFalse);
    expect(changed.copyWith(enabledALG: true), _state);
  });
}
