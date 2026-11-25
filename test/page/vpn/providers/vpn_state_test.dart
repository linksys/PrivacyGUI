// VPN settings as the page compares them: the page holds the settings it
// loaded and calls itself changed while they differ from what it shows now.

import 'dart:convert';

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

/// The settings map as VPNSettings writes it.
const _loadedMap = <String, dynamic>{
  'isEditingCredentials': true,
  'userCredentials': {
    'username': 'alice@example.com',
    'authMode': 'EAP',
    'secret': 's',
  },
  'gatewaySettings': {
    'gatewayAddress': '203.0.113.10',
    'dnsName': 'vpn.example.com',
    'ikeMode': 'ikev2',
    'ikeProposal': 'aes256-sha256-modp2048',
    'espProposal': 'aes256-sha256',
  },
  'serviceSettings': {'enabled': true, 'autoConnect': false},
  'tunneledUserIP': '192.168.1.100',
};

const _statusMap = <String, dynamic>{
  'statistics': {
    'uptime': 3600,
    'packetsSent': 1024,
    'packetsReceived': 2048,
    'bytesSent': 1048576,
    'bytesReceived': 2097152,
    'currentBandwidth': 51200,
    'activeSAs': 2,
    'rekeyCount': 1,
  },
  'tunnelStatus': 'Connected',
  'testResult': {
    'success': true,
    'statusMessage': 'IPsec SA established',
    'latency': 42,
  },
};

const _stateMap = <String, dynamic>{
  'status': _statusMap,
  'settings': _loadedMap,
};

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

    test('a state read twice is the same state; a changed half is not', () {
      final state = VPNState.fromMap(_stateMap);

      expect(VPNState.fromMap(_stateMap), state);
      expect(
          state.copyWith(
              status: state.status.copyWith(tunnelStatus: IPsecStatus.failed)),
          isNot(state));
      expect(
          state.copyWith(
              settings: state.settings.copyWith(isEditingCredentials: false)),
          isNot(state));
    });
  });

  group('the settings as a map', () {
    test('write every field the page holds', () {
      final settings = _loaded.copyWith(
          isEditingCredentials: true, tunneledUserIP: '192.168.1.100');

      expect(settings.toMap(), _loadedMap);
      expect(settings.toJson(), _loadedMap);
    });

    test('leave out the user, the gateway and the tunneled user when unset',
        () {
      const blank = VPNSettings(
          serviceSettings:
              VPNServiceSetSettings(enabled: false, autoConnect: false));

      expect(blank.toMap(), {
        'isEditingCredentials': false,
        'serviceSettings': {'enabled': false, 'autoConnect': false},
      });
    });

    test('read back as the same settings', () {
      final settings = VPNSettings.fromMap(_loadedMap);

      expect(settings.userCredentials?.authMode, AuthMode.eap);
      expect(settings.gatewaySettings?.gatewayAddress, '203.0.113.10');
      expect(settings.tunneledUserIP, '192.168.1.100');
      expect(VPNSettings.fromJson(jsonEncode(settings.toJson())), settings);
    });

    test('read with nothing set as the service off and no user or gateway', () {
      final settings = VPNSettings.fromMap(const {});

      expect(settings.isEditingCredentials, isFalse);
      expect(settings.userCredentials, isNull);
      expect(settings.gatewaySettings, isNull);
      expect(settings.serviceSettings.enabled, isFalse);
      expect(settings.serviceSettings.autoConnect, isFalse);
    });
  });

  group('the status as a map', () {
    test('writes the statistics, the tunnel and the test result', () {
      final status = VPNStatus.fromMap(_statusMap);

      expect(status.toMap(), _statusMap);
      expect(VPNStatus.fromJson(jsonEncode(status.toJson())), status);
    });

    test('leaves out the statistics and the test result when there are none',
        () {
      final status = VPNStatus.fromMap(const {'tunnelStatus': 'Disconnected'});

      expect(status.statistics, isNull);
      expect(status.testResult, isNull);
      expect(status.toMap(), {'tunnelStatus': 'Disconnected'});
    });

    test('reads a tunnel status it does not know as unknown', () {
      expect(VPNStatus.fromMap(const {'tunnelStatus': 'Rekeying'}).tunnelStatus,
          IPsecStatus.unknown);
    });
  });

  test('the whole state reads back from the JSON it writes', () {
    final state = VPNState.fromMap(_stateMap);

    expect(state.toMap(), _stateMap);
    expect(state.toJson(), _stateMap);
    expect(VPNState.fromJson(jsonEncode(state.toJson())), state);
  });
}
