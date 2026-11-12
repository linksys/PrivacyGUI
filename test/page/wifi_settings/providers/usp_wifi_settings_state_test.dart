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
            hasOpenNetwork: false,
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
          hasOpenNetwork: false,
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
          hasOpenNetwork: false,
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
            hasOpenNetwork: false,
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
            hasOpenNetwork: false,
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
          hasOpenNetwork: false,
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
          hasOpenNetwork: false,
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
          'true in quick setup mode when switching between WPA modes with no '
          'password (the router keeps its passphrase, #1720)', () {
        final networks = WifiSettingsTestData.createNetworks();
        const qsMain = WifiQuickSetupSettings(
          isGuest: false,
          enabled: true,
          ssid: 'Home',
          password: '',
          securityMode: 'WPA2-Personal',
          hasOpenNetwork: false,
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

        // Only ModeEnabled goes out; FW 2.0.4 keeps the key across WPA2 ↔
        // WPA3, so an empty password does not block Save.
        expect(state.isDirty, isTrue);
        expect(state.canSave, isTrue);
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
            hasOpenNetwork: true,
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
          hasOpenNetwork: true,
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
          hasOpenNetwork: false,
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

      test('true when only ssid changed (WPA2, empty password, unchanged mode)',
          () {
        final networks = WifiSettingsTestData.createNetworks();
        const mainOrig = WifiQuickSetupSettings(
          isGuest: false,
          enabled: true,
          ssid: 'Home',
          password: '',
          securityMode: 'WPA2-Personal',
          hasOpenNetwork: false,
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
        hasOpenNetwork: false,
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

      test('false when switching between WPA modes (#1720)', () {
        expect(
          wpa2Orig
              .copyWith(securityMode: 'WPA3-Personal')
              .isPasswordRequired(wpa2Orig),
          isFalse,
        );
      });

      // The card shows the first network's mode, so a group can read WPA2
      // while another band in it is open and has no passphrase to keep.
      const mixedOrig = WifiQuickSetupSettings(
        isGuest: false,
        enabled: true,
        ssid: 'Home',
        password: '',
        securityMode: 'WPA2-Personal',
        hasOpenNetwork: true,
        supportedSecurityModes: ['None', 'WPA2-Personal', 'WPA3-Personal'],
      );

      test('true when the mode changes and a network in the group is open', () {
        expect(
          mixedOrig
              .copyWith(securityMode: 'WPA3-Personal')
              .isPasswordRequired(mixedOrig),
          isTrue,
        );
      });

      test('true when switching from open to a WPA mode', () {
        const openMain = WifiQuickSetupSettings(
          isGuest: false,
          enabled: true,
          ssid: 'Home',
          password: '',
          securityMode: 'None',
          hasOpenNetwork: true,
          supportedSecurityModes: ['None', 'WPA2-Personal', 'WPA3-Personal'],
        );
        expect(
          openMain
              .copyWith(securityMode: 'WPA2-Personal')
              .isPasswordRequired(openMain),
          isTrue,
        );
      });

      test(
          "true when the original's own mode is open, whatever the flag says "
          '(a save to open kept as written)', () {
        const savedOpen = WifiQuickSetupSettings(
          isGuest: false,
          enabled: true,
          ssid: 'Home',
          password: '',
          securityMode: 'None',
          hasOpenNetwork: false,
          supportedSecurityModes: ['None', 'WPA2-Personal', 'WPA3-Personal'],
        );
        expect(
          savedOpen
              .copyWith(securityMode: 'WPA2-Personal')
              .isPasswordRequired(savedOpen),
          isTrue,
        );
      });

      test('a typed password must be valid on a WPA to WPA switch', () {
        final switched = wpa2Orig.copyWith(securityMode: 'WPA3-Personal');
        expect(switched.copyWith(password: 'short').isValid(wpa2Orig), isFalse);
        expect(switched.copyWith(password: 'longenough1').isValid(wpa2Orig),
            isTrue);
      });

      test(
          'false when a network in the group is open but only the name changes',
          () {
        expect(
          mixedOrig.copyWith(ssid: 'Renamed').isPasswordRequired(mixedOrig),
          isFalse,
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
          hasOpenNetwork: true,
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
          securityMode: 'OWE',
          hasOpenNetwork: true,
          supportedSecurityModes: ['None', 'OWE'],
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

  // -------------------------------------------------------------------------
  // WifiNetworkUIModel.isOpenSecurity
  //
  // 'OWE' is the TR-181 token for Enhanced Open — firmware advertises and
  // accepts only 'OWE' (see issue #1073). It must be treated as an open
  // (no-password) mode; 'Enhanced-Open' is not a valid firmware token.
  // -------------------------------------------------------------------------

  group('WifiNetworkUIModel.isOpenSecurity', () {
    test('true for None', () {
      final n = WifiSettingsTestData.createNetworkUIModel(securityMode: 'None');
      expect(n.isOpenSecurity, isTrue);
    });

    test('true for empty string', () {
      final n = WifiSettingsTestData.createNetworkUIModel(securityMode: '');
      expect(n.isOpenSecurity, isTrue);
    });

    test('true for OWE (Enhanced Open)', () {
      final n = WifiSettingsTestData.createNetworkUIModel(securityMode: 'OWE');
      expect(n.isOpenSecurity, isTrue);
    });

    test('false for WPA2-Personal', () {
      final n = WifiSettingsTestData.createNetworkUIModel(
          securityMode: 'WPA2-Personal');
      expect(n.isOpenSecurity, isFalse);
    });

    test('false for WPA3-Personal-Transition', () {
      final n = WifiSettingsTestData.createNetworkUIModel(
          securityMode: 'WPA3-Personal-Transition');
      expect(n.isOpenSecurity, isFalse);
    });
  });
}
