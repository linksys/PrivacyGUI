// VPN settings as the page compares them: the page holds the settings it
// loaded and calls itself changed while they differ from what it shows now.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/vpn/models/vpn_models.dart';
import 'package:privacy_gui/page/vpn/providers/vpn_state.dart';

const _user = VPNUserCredentials(
    username: 'alice@example.com', authMode: AuthMode.eap, secret: 's');

const _gateway = VPNGatewaySettings(
  gatewayAddress: '203.0.113.10',
  dnsName: 'vpn.example.com',
  ikeMode: IKEMode.ikev2,
  ikeProposal: 'aes256-sha256-modp2048',
  espProposal: 'aes256-sha256',
);

const _loaded = VPNSettings(
  userCredentials: _user,
  gatewaySettings: _gateway,
  serviceSettings: VPNServiceSetSettings(enabled: true, autoConnect: false),
);

void main() {
  group('VPNSettings', () {
    // Built at run time, as a fetch builds them, so that the comparison goes
    // through each class's props and not through one canonical const instance.
    test('settings read twice are the same settings', () {
      final readAgain = const VPNSettings(
        serviceSettings:
            VPNServiceSetSettings(enabled: false, autoConnect: false),
      ).copyWith(
        userCredentials: _user.copyWith(username: 'alice@example.com'),
        gatewaySettings: _gateway.copyWith(dnsName: 'vpn.example.com'),
        serviceSettings:
            const VPNServiceSetSettings(enabled: false, autoConnect: false)
                .copyWith(enabled: true),
      );

      expect(readAgain, isNot(same(_loaded)));
      expect(readAgain.userCredentials, isNot(same(_user)));
      expect(readAgain, _loaded);
    });

    test('an edit to any field makes them differ', () {
      final edits = [
        _loaded.copyWith(isEditingCredentials: true),
        _loaded.copyWith(userCredentials: _user.copyWith(secret: 'new')),
        _loaded.copyWith(gatewaySettings: _gateway.copyWith(dnsName: 'x')),
        _loaded.copyWith(
            serviceSettings:
                const VPNServiceSetSettings(enabled: true, autoConnect: true)),
        _loaded.copyWith(tunneledUserIP: '192.168.1.100'),
      ];

      for (final edited in edits) {
        expect(edited, isNot(_loaded));
      }
    });

    test('an edit keeps every field it does not name', () {
      final edited = _loaded.copyWith(tunneledUserIP: '192.168.1.100');

      expect(edited.userCredentials, same(_loaded.userCredentials));
      expect(edited.gatewaySettings, same(_loaded.gatewaySettings));
      expect(edited.serviceSettings, same(_loaded.serviceSettings));
      expect(edited.isEditingCredentials, isFalse);
    });
  });

  group('VPNStatus', () {
    test('a test result is added to the tunnel status it came with', () {
      const status = VPNStatus(tunnelStatus: IPsecStatus.connected);

      final tested = status.copyWith(
          testResult: const VPNTestResult(success: true, statusMessage: 'OK'));

      expect(tested.tunnelStatus, IPsecStatus.connected);
      expect(tested.testResult?.success, isTrue);
      expect(tested, isNot(status));
    });
  });

  group('VPNState', () {
    test('starts disconnected, with the service off and no settings', () {
      const state = VPNState.init();

      expect(state.status.tunnelStatus, IPsecStatus.disconnected);
      expect(state.status.statistics, isNull);
      expect(state.status.testResult, isNull);
      expect(state.settings.serviceSettings.enabled, isFalse);
      expect(state.settings.serviceSettings.autoConnect, isFalse);
      expect(state.settings.userCredentials, isNull);
      expect(state.settings.gatewaySettings, isNull);
      expect(state.settings.tunneledUserIP, isNull);
    });
  });
}
