// The VPN models, read from and written to the router.
//
// No 1.x firmware implements the VPN actions yet (they are plans), so the
// shapes here are the ones the app reads and writes: each `toValue` names the
// value on the wire, and `VPNService` takes each model from the key it reads.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/vpn/models/vpn_models.dart';

/// `GetVPNUser`'s `credentials`.
const _credentials = <String, dynamic>{
  'username': 'alice@example.com',
  'authMode': 'EAP',
  'secret': 'eap-secret',
};

/// `GetVPNGateway`'s `settings`.
const _gateway = <String, dynamic>{
  'gatewayAddress': '203.0.113.10',
  'dnsName': 'vpn.example.com',
  'ikeMode': 'ikev1',
  'ikeProposal': 'aes256-sha256-modp2048',
  'espProposal': 'aes256-sha256',
};

const _statistics = <String, dynamic>{
  'uptime': 3600,
  'packetsSent': 1024,
  'packetsReceived': 2048,
  'bytesSent': 1048576,
  'bytesReceived': 2097152,
  'currentBandwidth': 51200,
  'activeSAs': 2,
  'rekeyCount': 1,
};

/// `GetVPNService`'s `settings`.
const _service = <String, dynamic>{
  'enabled': true,
  'autoConnect': false,
  'statistics': _statistics,
  'tunnelStatus': 'Connected',
};

void main() {
  group('IPsecStatus', () {
    test('reads each tunnel status the router names', () {
      expect(
        [
          for (final value in [
            'Disconnected',
            'Connecting',
            'Connected',
            'Failed',
            'Unknown',
          ])
            IPsecStatus.fromJson(value),
        ],
        [
          IPsecStatus.disconnected,
          IPsecStatus.connecting,
          IPsecStatus.connected,
          IPsecStatus.failed,
          IPsecStatus.unknown,
        ],
      );
    });

    test('reads a status it does not know as unknown', () {
      expect(IPsecStatus.fromJson('Rekeying'), IPsecStatus.unknown);
      expect(IPsecStatus.fromJson('connected'), IPsecStatus.unknown,
          reason: 'the value on the wire is capitalised');
    });

    test(
        'shows a connected tunnel green, a connecting one orange and a '
        'failed one red', () {
      expect(IPsecStatus.connected.color, Colors.green);
      expect(IPsecStatus.connecting.color, Colors.orange);
      expect(IPsecStatus.failed.color, Colors.red);
      expect(IPsecStatus.disconnected.color, Colors.grey);
      expect(IPsecStatus.unknown.color, Colors.grey);
    });
  });

  group('IKEMode', () {
    test('reads IKEv1 and IKEv2, and anything else as IKEv2', () {
      expect(IKEMode.fromJson('ikev1'), IKEMode.ikev1);
      expect(IKEMode.fromJson('ikev2'), IKEMode.ikev2);
      expect(IKEMode.fromJson('IKEv1'), IKEMode.ikev2);
    });
  });

  group('AuthMode', () {
    test('reads PSK, EAP and Certificate, and anything else as PSK', () {
      expect(AuthMode.fromJson('PSK'), AuthMode.psk);
      expect(AuthMode.fromJson('EAP'), AuthMode.eap);
      expect(AuthMode.fromJson('Certificate'), AuthMode.certificate);
      expect(AuthMode.fromJson('eap'), AuthMode.psk);
    });
  });

  testWidgets(
      'names each status, IKE mode and auth mode as the page shows '
      'them', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (built) {
        context = built;
        return const SizedBox();
      }),
    ));

    expect([for (final s in IPsecStatus.values) s.toDisplayName(context)],
        ['Disconnected', 'Connecting', 'Connected', 'Failed', 'Unknown']);
    expect([for (final m in IKEMode.values) m.toDisplayName(context)],
        ['IKEv1', 'IKEv2']);
    expect([for (final m in AuthMode.values) m.toDisplayName(context)],
        ['PSK', 'EAP', 'Certificate']);
  });

  group('VPNUserCredentials', () {
    test('reads the user the router holds', () {
      final credentials = VPNUserCredentials.fromMap(_credentials);

      expect(credentials.username, 'alice@example.com');
      expect(credentials.authMode, AuthMode.eap);
      expect(credentials.secret, 'eap-secret');
    });

    test('reads a user with nothing set as a blank PSK user', () {
      expect(
        VPNUserCredentials.fromMap(const {}),
        const VPNUserCredentials(
            username: '', authMode: AuthMode.psk, secret: ''),
      );
    });

    test('writes the user as the router reads it', () {
      expect(VPNUserCredentials.fromMap(_credentials).toMap(), _credentials);
    });

    test('a changed secret keeps the user and the auth mode', () {
      final edited =
          VPNUserCredentials.fromMap(_credentials).copyWith(secret: 'new');

      expect(edited.toMap(), {..._credentials, 'secret': 'new'});
    });
  });

  group('VPNGatewaySettings', () {
    test('reads the gateway the router holds', () {
      final gateway = VPNGatewaySettings.fromMap(_gateway);

      expect(gateway.gatewayAddress, '203.0.113.10');
      expect(gateway.dnsName, 'vpn.example.com');
      expect(gateway.ikeMode, IKEMode.ikev1);
      expect(gateway.ikeProposal, 'aes256-sha256-modp2048');
      expect(gateway.espProposal, 'aes256-sha256');
    });

    test('writes the gateway as the router reads it', () {
      expect(VPNGatewaySettings.fromMap(_gateway).toMap(), _gateway);
    });

    test('an edit to one field keeps the others', () {
      final gateway = VPNGatewaySettings.fromMap(_gateway);

      expect(
        gateway
            .copyWith(gatewayAddress: '198.51.100.1')
            .copyWith(dnsName: 'vpn2.example.com')
            .copyWith(ikeMode: IKEMode.ikev2)
            .copyWith(ikeProposal: 'aes128-sha1-modp1024')
            .copyWith(espProposal: 'aes128-sha1')
            .toMap(),
        {
          'gatewayAddress': '198.51.100.1',
          'dnsName': 'vpn2.example.com',
          'ikeMode': 'ikev2',
          'ikeProposal': 'aes128-sha1-modp1024',
          'espProposal': 'aes128-sha1',
        },
      );
      expect(gateway.copyWith(), gateway);
    });
  });

  group('VPNServiceSettings', () {
    test('reads the service, its tunnel status and its statistics', () {
      final service = VPNServiceSettings.fromMap(_service);

      expect(service.enabled, isTrue);
      expect(service.autoConnect, isFalse);
      expect(service.tunnelStatus, IPsecStatus.connected);
      expect(
        service.statistics,
        const VPNStatistics(
          uptime: 3600,
          packetsSent: 1024,
          packetsReceived: 2048,
          bytesSent: 1048576,
          bytesReceived: 2097152,
          currentBandwidth: 51200,
          activeSAs: 2,
          rekeyCount: 1,
        ),
      );
    });

    test('reads a service with no tunnel up as having no statistics', () {
      final service = VPNServiceSettings.fromMap(const {
        'enabled': false,
        'autoConnect': false,
        'tunnelStatus': 'Disconnected',
      });

      expect(service.statistics, isNull);
      expect(service.tunnelStatus, IPsecStatus.disconnected);
    });
  });

  group('VPNServiceSetSettings', () {
    test('writes the two switches the page sets', () {
      expect(
        const VPNServiceSetSettings(enabled: true, autoConnect: false)
            .copyWith(autoConnect: true)
            .toMap(),
        {'enabled': true, 'autoConnect': true},
      );
    });

    test('turning the service on keeps auto-connect as it was', () {
      expect(
        const VPNServiceSetSettings(enabled: false, autoConnect: true)
            .copyWith(enabled: true),
        const VPNServiceSetSettings(enabled: true, autoConnect: true),
      );
    });

    test('reads the two switches back', () {
      expect(
        VPNServiceSetSettings.fromMap(const {
          'enabled': false,
          'autoConnect': true,
        }),
        const VPNServiceSetSettings(enabled: false, autoConnect: true),
      );
    });
  });

  group('VPNTestResult', () {
    test('reads a passed test with its latency', () {
      final result = VPNTestResult.fromMap(const {
        'success': true,
        'statusMessage': 'IPsec SA established',
        'latency': 42,
      });

      expect(result.success, isTrue);
      expect(result.statusMessage, 'IPsec SA established');
      expect(result.latency, 42);
    });

    test('reads a failed test, which has no latency', () {
      final result = VPNTestResult.fromMap(const {
        'success': false,
        'statusMessage': 'No response from peer',
      });

      expect(result.success, isFalse);
      expect(result.latency, isNull);
    });
  });

  // Each model's JSON is its map; reading it back gives an equal model, built
  // at run time so that the comparison goes through props.
  group('reading a model back from the JSON it writes', () {
    test('a user', () {
      final user = VPNUserCredentials.fromMap(_credentials);

      expect(user.toJson(), _credentials);
      expect(VPNUserCredentials.fromJson(jsonEncode(user.toJson())), user);
    });

    test('a gateway', () {
      final gateway = VPNGatewaySettings.fromMap(_gateway);

      expect(gateway.toJson(), _gateway);
      expect(
          VPNGatewaySettings.fromJson(jsonEncode(gateway.toJson())), gateway);
    });

    test('statistics', () {
      final statistics = VPNStatistics.fromMap(_statistics);

      expect(statistics.toMap(), _statistics);
      expect(statistics.toJson(), _statistics);
      expect(
          VPNStatistics.fromJson(jsonEncode(statistics.toJson())), statistics);
    });

    test('the service switches', () {
      final switches = VPNServiceSetSettings.fromMap(
          const {'enabled': true, 'autoConnect': false});

      expect(switches.toJson(), {'enabled': true, 'autoConnect': false});
      expect(VPNServiceSetSettings.fromJson(jsonEncode(switches.toJson())),
          switches);
    });

    test('the service, with and without statistics', () {
      final service = VPNServiceSettings.fromMap(_service);

      expect(service.toMap(), _service);
      expect(
          VPNServiceSettings.fromJson(jsonEncode(service.toJson())), service);

      final down = VPNServiceSettings.fromMap(const {
        'enabled': false,
        'autoConnect': false,
        'tunnelStatus': 'Disconnected',
      });
      expect(down.toMap(), {
        'enabled': false,
        'autoConnect': false,
        'statistics': null,
        'tunnelStatus': 'Disconnected',
      });
    });

    test('a test result', () {
      final result = VPNTestResult.fromMap(const {
        'success': true,
        'statusMessage': 'IPsec SA established',
        'latency': 42,
      });

      expect(result.toMap(), {
        'success': true,
        'statusMessage': 'IPsec SA established',
        'latency': 42,
      });
      expect(VPNTestResult.fromJson(jsonEncode(result.toJson())), result);
    });
  });

  group('equality and edits', () {
    test('a service read twice is the same service; a changed field is not',
        () {
      final service = VPNServiceSettings.fromMap(_service);

      expect(VPNServiceSettings.fromMap(_service), service);
      for (final edited in [
        service.copyWith(enabled: false),
        service.copyWith(autoConnect: true),
        service.copyWith(tunnelStatus: IPsecStatus.failed),
        service.copyWith(statistics: service.statistics!.copyWith(uptime: 1)),
      ]) {
        expect(edited, isNot(service));
      }
    });

    test('an edit to the service keeps the fields it does not name', () {
      final service = VPNServiceSettings.fromMap(_service);

      final failed = service.copyWith(tunnelStatus: IPsecStatus.failed);

      expect(failed.toMap(), {..._service, 'tunnelStatus': 'Failed'});
    });

    test('an edit to the statistics keeps the counters it does not name', () {
      final statistics = VPNStatistics.fromMap(_statistics);

      expect(
        statistics
            .copyWith(uptime: 7200)
            .copyWith(packetsSent: 1)
            .copyWith(packetsReceived: 2)
            .copyWith(bytesSent: 3)
            .copyWith(bytesReceived: 4)
            .copyWith(currentBandwidth: 5)
            .copyWith(activeSAs: 6)
            .copyWith(rekeyCount: 7)
            .toMap(),
        {
          'uptime': 7200,
          'packetsSent': 1,
          'packetsReceived': 2,
          'bytesSent': 3,
          'bytesReceived': 4,
          'currentBandwidth': 5,
          'activeSAs': 6,
          'rekeyCount': 7,
        },
      );
      expect(statistics.copyWith(), statistics);
      expect(statistics.copyWith(), isNot(same(statistics)));
    });

    test('an edit to a test result keeps the fields it does not name', () {
      final result = VPNTestResult.fromMap(const {
        'success': true,
        'statusMessage': 'IPsec SA established',
        'latency': 42,
      });

      expect(
        result.copyWith(latency: 10).toMap(),
        {
          'success': true,
          'statusMessage': 'IPsec SA established',
          'latency': 10
        },
      );
      expect(
        result.copyWith(success: false, statusMessage: 'Timed out').toMap(),
        {'success': false, 'statusMessage': 'Timed out', 'latency': 42},
      );
    });

    test('a changed user name or auth mode keeps the secret', () {
      final user = VPNUserCredentials.fromMap(_credentials);

      expect(user.copyWith(username: 'bob').toMap(),
          {..._credentials, 'username': 'bob'});
      expect(user.copyWith(authMode: AuthMode.psk).toMap(),
          {..._credentials, 'authMode': 'PSK'});
    });
  });
}
