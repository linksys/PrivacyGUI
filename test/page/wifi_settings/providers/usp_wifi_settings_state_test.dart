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

      test(
          'false when quick setup is initialized with same values on both original and current',
          () {
        final networks = WifiSettingsTestData.createNetworks();
        const qsMain = WifiQuickSetupSettings(
          isGuest: false,
          enabled: true,
          ssid: 'Home',
          password: '',
          securityMode: 'WPA2-Personal',
          supportedSecurityModes: ['WPA2-Personal', 'WPA3-Personal'],
        );
        final settings = WifiSettingsSettings(
          networks: networks,
          quickSetupEnabled: true,
          quickSetupMain: qsMain,
        );

        final state = UspWifiSettingsState(
          settings: Preservable(original: settings, current: settings),
          status: const WifiSettingsStatus(),
        );

        expect(state.isDirty, isFalse);
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

      test('true in quick setup mode when only security mode changes to open',
          () {
        final networks = WifiSettingsTestData.createNetworks();
        const qsMain = WifiQuickSetupSettings(
          isGuest: false,
          enabled: true,
          ssid: 'Home',
          password: '',
          securityMode: 'WPA2-Personal',
          supportedSecurityModes: ['None', 'WPA2-Personal', 'WPA3-Personal'],
        );
        final settings = WifiSettingsSettings(
          networks: networks,
          quickSetupEnabled: true,
          quickSetupMain: qsMain,
        );
        final current = settings.copyWith(
          quickSetupMain: qsMain.copyWith(securityMode: 'None'),
        );

        final state = UspWifiSettingsState(
          settings: Preservable(original: settings, current: current),
          status: const WifiSettingsStatus(),
        );

        expect(state.isDirty, isTrue);
        expect(state.canSave, isTrue);
      });

      test(
          'false in quick setup mode when security mode changes but password still empty',
          () {
        final networks = WifiSettingsTestData.createNetworks();
        const qsMain = WifiQuickSetupSettings(
          isGuest: false,
          enabled: true,
          ssid: 'Home',
          password: '',
          securityMode: 'WPA2-Personal',
          supportedSecurityModes: ['WPA2-Personal', 'WPA3-Personal'],
        );
        final settings = WifiSettingsSettings(
          networks: networks,
          quickSetupEnabled: true,
          quickSetupMain: qsMain,
        );
        final current = settings.copyWith(
          quickSetupMain: qsMain.copyWith(securityMode: 'WPA3-Personal'),
        );

        final state = UspWifiSettingsState(
          settings: Preservable(original: settings, current: current),
          status: const WifiSettingsStatus(),
        );

        // isDirty because securityMode changed, but canSave false because
        // password is still empty and the new mode requires one.
        expect(state.isDirty, isTrue);
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

      test(
          'true when only guest enabled toggled off (open security, empty password)',
          () {
        final networks = WifiSettingsTestData.createNetworks();
        const guestOrig = WifiQuickSetupSettings(
          isGuest: true,
          enabled: true,
          ssid: 'Home-Guest',
          password: '',
          securityMode: 'None',
          supportedSecurityModes: [],
        );
        final original = WifiSettingsSettings(
          networks: networks,
          quickSetupEnabled: true,
          quickSetupGuest: guestOrig,
        );
        final current = original.copyWith(
          quickSetupGuest: guestOrig.copyWith(enabled: false),
        );

        final state = UspWifiSettingsState(
          settings: Preservable(original: original, current: current),
          status: const WifiSettingsStatus(),
        );

        // Only enabled toggled — password is not being written, so no
        // passphrase requirement even though current mode is 'None'.
        expect(state.isDirty, isTrue);
        expect(state.canSave, isTrue);
      });

      test(
          'true when only main enabled toggled (WPA2, empty password, unchanged mode)',
          () {
        final networks = WifiSettingsTestData.createNetworks();
        const mainOrig = WifiQuickSetupSettings(
          isGuest: false,
          enabled: true,
          ssid: 'Home',
          password: '',
          securityMode: 'WPA2-Personal',
          supportedSecurityModes: ['WPA2-Personal', 'WPA3-Personal'],
        );
        final original = WifiSettingsSettings(
          networks: networks,
          quickSetupEnabled: true,
          quickSetupMain: mainOrig,
        );
        final current = original.copyWith(
          quickSetupMain: mainOrig.copyWith(enabled: false),
        );

        final state = UspWifiSettingsState(
          settings: Preservable(original: original, current: current),
          status: const WifiSettingsStatus(),
        );

        // Toggle enable only — no AP write, so empty password is fine
        // even though the security mode is non-open.
        expect(state.isDirty, isTrue);
        expect(state.canSave, isTrue);
      });

      test(
          'true when only ssid changed (WPA2, empty password, unchanged mode)',
          () {
        final networks = WifiSettingsTestData.createNetworks();
        const mainOrig = WifiQuickSetupSettings(
          isGuest: false,
          enabled: true,
          ssid: 'Home',
          password: '',
          securityMode: 'WPA2-Personal',
          supportedSecurityModes: ['WPA2-Personal', 'WPA3-Personal'],
        );
        final original = WifiSettingsSettings(
          networks: networks,
          quickSetupEnabled: true,
          quickSetupMain: mainOrig,
        );
        final current = original.copyWith(
          quickSetupMain: mainOrig.copyWith(ssid: 'RenamedHome'),
        );

        final state = UspWifiSettingsState(
          settings: Preservable(original: original, current: current),
          status: const WifiSettingsStatus(),
        );

        // Only SSID name changed — no AP write triggered, so no password
        // requirement even under WPA2.
        expect(state.isDirty, isTrue);
        expect(state.canSave, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // WifiQuickSetupSettings.isPasswordRequired
    // -----------------------------------------------------------------------

    group('WifiQuickSetupSettings.isPasswordRequired', () {
      const wpa2Orig = WifiQuickSetupSettings(
        isGuest: false,
        enabled: true,
        ssid: 'Home',
        password: '',
        securityMode: 'WPA2-Personal',
        supportedSecurityModes: ['WPA2-Personal', 'WPA3-Personal'],
      );

      test('false when only enabled toggled (non-open mode)', () {
        expect(
          wpa2Orig.copyWith(enabled: false).isPasswordRequired(wpa2Orig),
          isFalse,
        );
      });

      test('false when only ssid changed (non-open mode)', () {
        expect(
          wpa2Orig.copyWith(ssid: 'Renamed').isPasswordRequired(wpa2Orig),
          isFalse,
        );
      });

      test('true when password changed and mode is non-open', () {
        expect(
          wpa2Orig.copyWith(password: 'newpass1').isPasswordRequired(wpa2Orig),
          isTrue,
        );
      });

      test('true when security mode changed to a non-open mode', () {
        expect(
          wpa2Orig
              .copyWith(securityMode: 'WPA3-Personal')
              .isPasswordRequired(wpa2Orig),
          isTrue,
        );
      });

      test('false when security mode changed to None (open)', () {
        expect(
          wpa2Orig.copyWith(securityMode: 'None').isPasswordRequired(wpa2Orig),
          isFalse,
        );
      });

      test('false on open mode with unchanged password', () {
        const openOrig = WifiQuickSetupSettings(
          isGuest: true,
          enabled: true,
          ssid: 'Home-Guest',
          password: '',
          securityMode: 'None',
          supportedSecurityModes: [],
        );
        expect(
          openOrig.copyWith(enabled: false).isPasswordRequired(openOrig),
          isFalse,
        );
      });

      test('true when original is null and mode is non-open', () {
        // Fresh pending with no baseline (e.g. freshly toggled Quick Setup).
        expect(wpa2Orig.isPasswordRequired(null), isTrue);
      });

      test('false when original is null but mode is open', () {
        const openPending = WifiQuickSetupSettings(
          isGuest: false,
          enabled: true,
          ssid: 'OpenNet',
          password: '',
          securityMode: 'Enhanced-Open',
          supportedSecurityModes: ['None', 'Enhanced-Open'],
        );
        expect(openPending.isPasswordRequired(null), isFalse);
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
