import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_feature_state.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_read_only_info.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_settings.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_status.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';

void main() {
  const dhcpForm = UspInternetSettingsForm(
    connectionType: UspWanConnectionType.dhcp,
    mtu: 1500,
    ipv6Enabled: true,
  );

  const staticForm = UspInternetSettingsForm(
    connectionType: UspWanConnectionType.staticIp,
    staticIpAddress: '192.168.1.100',
    subnetMask: '255.255.255.0',
    defaultGateway: '192.168.1.1',
    dnsServer1: '8.8.8.8',
  );

  const bridgeForm = UspInternetSettingsForm(
    connectionType: UspWanConnectionType.bridge,
  );

  const readOnlyInfo = InternetSettingsReadOnlyInfo(
    currentMacAddress: 'AA:BB:CC:DD:EE:FF',
    pppConnectionStatus: 'Connected',
    dhcpv6Duid: '00:01:02:03',
    staticIpAddress: '10.0.0.1',
  );

  InternetSettingsFeatureState createState({
    UspInternetSettingsForm? originalForm,
    UspInternetSettingsForm? currentForm,
    bool isEditing = false,
    InternetSettingsReadOnlyInfo info = const InternetSettingsReadOnlyInfo(),
  }) {
    final orig = originalForm ?? dhcpForm;
    final curr = currentForm ?? orig;
    return InternetSettingsFeatureState(
      settings: Preservable(
        original: InternetSettingsSettings(form: orig),
        current: InternetSettingsSettings(form: curr),
      ),
      status: InternetSettingsStatus(
        isLoading: false,
        isEditing: isEditing,
        readOnlyInfo: info,
      ),
    );
  }

  group('InternetSettingsFeatureState', () {
    // -----------------------------------------------------------------------
    // initial()
    // -----------------------------------------------------------------------

    test('initial state has loading status and empty form', () {
      final state = InternetSettingsFeatureState.initial();

      expect(state.status.isLoading, isTrue);
      expect(state.original.connectionType, UspWanConnectionType.dhcp);
      expect(state.edited.connectionType, UspWanConnectionType.dhcp);
      expect(state.isDirty, isFalse);
    });

    // -----------------------------------------------------------------------
    // Convenience getters
    // -----------------------------------------------------------------------

    test('original returns settings.original.form', () {
      final state =
          createState(originalForm: staticForm, currentForm: dhcpForm);

      expect(state.original, staticForm);
      expect(state.original.staticIpAddress, '192.168.1.100');
    });

    test('edited returns settings.current.form', () {
      final state =
          createState(originalForm: dhcpForm, currentForm: staticForm);

      expect(state.edited, staticForm);
      expect(state.edited.connectionType, UspWanConnectionType.staticIp);
    });

    test('isEditing reflects status.isEditing', () {
      final editing = createState(isEditing: true);
      final notEditing = createState(isEditing: false);

      expect(editing.isEditing, isTrue);
      expect(notEditing.isEditing, isFalse);
    });

    test('connectionType returns edited form connection type', () {
      final state = createState(currentForm: staticForm);
      expect(state.connectionType, UspWanConnectionType.staticIp);
    });

    test('isBridgeMode true when connection type is bridge', () {
      final state = createState(currentForm: bridgeForm);
      expect(state.isBridgeMode, isTrue);
    });

    test('isBridgeMode false when connection type is not bridge', () {
      final state = createState(currentForm: dhcpForm);
      expect(state.isBridgeMode, isFalse);
    });

    // -----------------------------------------------------------------------
    // Read-only info getters
    // -----------------------------------------------------------------------

    test('readOnlyInfo convenience getters delegate to status', () {
      final state = createState(info: readOnlyInfo);

      expect(state.currentMacAddress, 'AA:BB:CC:DD:EE:FF');
      expect(state.pppConnectionStatus, 'Connected');
      expect(state.dhcpv6Duid, '00:01:02:03');
    });

    // -----------------------------------------------------------------------
    // isDirty
    // -----------------------------------------------------------------------

    test('isDirty false when original and current match', () {
      final state = createState(originalForm: dhcpForm, currentForm: dhcpForm);
      expect(state.isDirty, isFalse);
    });

    test('isDirty true when form fields differ', () {
      final state =
          createState(originalForm: dhcpForm, currentForm: staticForm);
      expect(state.isDirty, isTrue);
    });

    // -----------------------------------------------------------------------
    // copyWith
    // -----------------------------------------------------------------------

    test('copyWith preserves unchanged fields', () {
      final state = createState(info: readOnlyInfo, isEditing: true);
      final updated = state.copyWith(
        status: state.status.copyWith(isSaving: true),
      );

      expect(updated.settings, state.settings);
      expect(updated.status.isSaving, isTrue);
      expect(updated.isEditing, isTrue);
      expect(updated.readOnlyInfo, readOnlyInfo);
    });
  });
}
