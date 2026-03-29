import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_settings_settings.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_settings_status.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_state.dart';

import '../../../../test/mocks/test_data/wifi_settings_test_data.dart';

void main() {
  group('UspWifiSettingsState', () {
    // -----------------------------------------------------------------------
    // initial()
    // -----------------------------------------------------------------------

    test('initial state has empty networks and loading status', () {
      final state = UspWifiSettingsState.initial();

      expect(state.settings.current.networks, isEmpty);
      expect(state.settings.original.networks, isEmpty);
      expect(state.status.isLoading, isTrue);
      expect(state.isDirty, isFalse);
      expect(state.canSave, isFalse);
    });

    // -----------------------------------------------------------------------
    // isDirty
    // -----------------------------------------------------------------------

    group('isDirty', () {
      test('false when original and current are identical', () {
        final networks = WifiSettingsTestData.createNetworks();
        final settings = WifiSettingsSettings(
          networks: networks,
          quickSetupEnabled: false,
        );
        final state = UspWifiSettingsState(
          settings: Preservable(original: settings, current: settings),
          status: const WifiSettingsStatus(),
        );

        expect(state.isDirty, isFalse);
      });

      test('true when a network field is changed', () {
        final networks = WifiSettingsTestData.createNetworks();
        final original = WifiSettingsSettings(
          networks: networks,
          quickSetupEnabled: false,
        );
        final modifiedNetworks = networks.map((n) {
          if (n.ssidInstancePath == 'Device.WiFi.SSID.1.') {
            return n.copyWith(ssid: 'ChangedSSID');
          }
          return n;
        }).toList();
        final current = original.copyWith(networks: modifiedNetworks);

        final state = UspWifiSettingsState(
          settings: Preservable(original: original, current: current),
          status: const WifiSettingsStatus(),
        );

        expect(state.isDirty, isTrue);
      });

      test('false when only quickSetupEnabled changes', () {
        final networks = WifiSettingsTestData.createNetworks();
        final original = WifiSettingsSettings(
          networks: networks,
          quickSetupEnabled: false,
        );
        final current = original.copyWith(quickSetupEnabled: true);

        final state = UspWifiSettingsState(
          settings: Preservable(original: original, current: current),
          status: const WifiSettingsStatus(),
        );

        expect(state.isDirty, isFalse);
      });

      test('true when quickSetupMain changes from null to non-null', () {
        final networks = WifiSettingsTestData.createNetworks();
        final original = WifiSettingsSettings(
          networks: networks,
          quickSetupEnabled: true,
        );
        final current = original.copyWith(
          quickSetupMain: const WifiQuickSetupSettings(
            isGuest: false,
            enabled: true,
            ssid: 'Home',
            password: 'newpass1',
            securityMode: 'WPA2-Personal',
            supportedSecurityModes: ['WPA2-Personal', 'WPA3-Personal'],
          ),
        );

        final state = UspWifiSettingsState(
          settings: Preservable(original: original, current: current),
          status: const WifiSettingsStatus(),
        );

        expect(state.isDirty, isTrue);
      });

      test('true when quickSetupGuest password changes', () {
        const qsGuest = WifiQuickSetupSettings(
          isGuest: true,
          enabled: true,
          ssid: 'Guest',
          password: '',
          securityMode: 'WPA2-Personal',
          supportedSecurityModes: ['WPA2-Personal'],
        );
        final networks = WifiSettingsTestData.createNetworks();
        final original = WifiSettingsSettings(
          networks: networks,
          quickSetupEnabled: true,
          quickSetupGuest: qsGuest,
        );
        final current = original.copyWith(
          quickSetupGuest: qsGuest.copyWith(password: 'guestpass'),
        );

        final state = UspWifiSettingsState(
          settings: Preservable(original: original, current: current),
          status: const WifiSettingsStatus(),
        );

        expect(state.isDirty, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // canSave
    // -----------------------------------------------------------------------

    group('canSave', () {
      test('false when not dirty', () {
        final networks = WifiSettingsTestData.createNetworks();
        final settings = WifiSettingsSettings(
          networks: networks,
          quickSetupEnabled: false,
        );
        final state = UspWifiSettingsState(
          settings: Preservable(original: settings, current: settings),
          status: const WifiSettingsStatus(),
        );

        expect(state.canSave, isFalse);
      });

      test('true in advanced mode when dirty', () {
        final networks = WifiSettingsTestData.createNetworks();
        final original = WifiSettingsSettings(
          networks: networks,
          quickSetupEnabled: false,
        );
        final modifiedNetworks = networks.map((n) {
          if (n.ssidInstancePath == 'Device.WiFi.SSID.1.') {
            return n.copyWith(ssid: 'Changed');
          }
          return n;
        }).toList();
        final current = original.copyWith(networks: modifiedNetworks);

        final state = UspWifiSettingsState(
          settings: Preservable(original: original, current: current),
          status: const WifiSettingsStatus(),
        );

        expect(state.canSave, isTrue);
      });

      test('true in quick setup mode when main group changed and valid', () {
        final networks = WifiSettingsTestData.createNetworks();
        final original = WifiSettingsSettings(
          networks: networks,
          quickSetupEnabled: true,
        );
        final current = original.copyWith(
          quickSetupMain: const WifiQuickSetupSettings(
            isGuest: false,
            enabled: true,
            ssid: 'Home',
            password: 'validpass',
            securityMode: 'WPA2-Personal',
            supportedSecurityModes: ['WPA2-Personal'],
          ),
        );

        final state = UspWifiSettingsState(
          settings: Preservable(original: original, current: current),
          status: const WifiSettingsStatus(),
        );

        expect(state.canSave, isTrue);
      });

      test('false in quick setup mode when password too short', () {
        final networks = WifiSettingsTestData.createNetworks();
        final original = WifiSettingsSettings(
          networks: networks,
          quickSetupEnabled: true,
        );
        final current = original.copyWith(
          quickSetupMain: const WifiQuickSetupSettings(
            isGuest: false,
            enabled: true,
            ssid: 'Home',
            password: 'short', // < 8 chars
            securityMode: 'WPA2-Personal',
            supportedSecurityModes: ['WPA2-Personal'],
          ),
        );

        final state = UspWifiSettingsState(
          settings: Preservable(original: original, current: current),
          status: const WifiSettingsStatus(),
        );

        expect(state.canSave, isFalse);
      });

      test('false in quick setup mode when no group actually changed', () {
        const qsMain = WifiQuickSetupSettings(
          isGuest: false,
          enabled: true,
          ssid: 'Home',
          password: 'validpass',
          securityMode: 'WPA2-Personal',
          supportedSecurityModes: ['WPA2-Personal'],
        );
        final networks = WifiSettingsTestData.createNetworks();
        final settings = WifiSettingsSettings(
          networks: networks,
          quickSetupEnabled: true,
          quickSetupMain: qsMain,
        );

        final state = UspWifiSettingsState(
          settings: Preservable(original: settings, current: settings),
          status: const WifiSettingsStatus(),
        );

        // isDirty is false because original == current, so canSave is false
        expect(state.canSave, isFalse);
      });

      test('true in quick setup mode with open security and empty password',
          () {
        final networks = WifiSettingsTestData.createNetworks();
        final original = WifiSettingsSettings(
          networks: networks,
          quickSetupEnabled: true,
        );
        final current = original.copyWith(
          quickSetupMain: const WifiQuickSetupSettings(
            isGuest: false,
            enabled: true,
            ssid: 'OpenNet',
            password: '',
            securityMode: 'None',
            supportedSecurityModes: ['None', 'WPA2-Personal'],
          ),
        );

        final state = UspWifiSettingsState(
          settings: Preservable(original: original, current: current),
          status: const WifiSettingsStatus(),
        );

        expect(state.canSave, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // copyWith
    // -----------------------------------------------------------------------

    test('copyWith preserves unchanged fields', () {
      final state = UspWifiSettingsState.initial();
      final newStatus = WifiSettingsTestData.createStatus(isSaving: true);

      final updated = state.copyWith(status: newStatus);

      expect(updated.settings, state.settings);
      expect(updated.status.isSaving, isTrue);
    });
  });
}
