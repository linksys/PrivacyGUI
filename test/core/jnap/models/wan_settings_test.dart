import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/wan_settings.dart';

/// [value] as the router receives it: JSON on the wire, nested models encoded
/// through their own `toJson`.
Object? _wire(Object? value) => jsonDecode(jsonEncode(value));

const _static = <String, dynamic>{
  'ipAddress': '203.0.113.10',
  'networkPrefixLength': 24,
  'gateway': '203.0.113.1',
  'dnsServer1': '203.0.113.53',
  'dnsServer2': '198.51.100.53',
  'dnsServer3': '192.0.2.53',
  'domainName': 'isp.example',
};

/// `GetWANSettings` output, one per connection type a router may report.
const _outputs = <String, Map<String, dynamic>>{
  'DHCP': {
    'wanType': 'DHCP',
    'mtu': 0,
    'wanTaggingSettings': {'isEnabled': false},
  },
  'PPPoE with a VLAN': {
    'wanType': 'PPPoE',
    'mtu': 1492,
    'pppoeSettings': {
      'username': 'isp-user',
      'password': 'isp-pass',
      'serviceName': 'svc',
      'behavior': 'ConnectOnDemand',
      'maxIdleMinutes': 10,
    },
    'wanTaggingSettings': {
      'isEnabled': true,
      'vlanTaggingSettings': {
        'vlanID': 100,
        'vlanPriority': 3,
        'vlanStatus': 'Tagged',
      },
      'vlanLowerLimit': 5,
      'vlanUpperLimit': 4094,
    },
  },
  'PPTP with a static address': {
    'wanType': 'PPTP',
    'mtu': 1460,
    'tpSettings': {
      'useStaticSettings': true,
      'staticSettings': _static,
      'server': '10.0.0.1',
      'username': 'vpn-user',
      'password': 'vpn-pass',
      'behavior': 'KeepAlive',
      'reconnectAfterSeconds': 30,
    },
  },
  'L2TP': {
    'wanType': 'L2TP',
    'mtu': 0,
    'tpSettings': {
      'useStaticSettings': false,
      'server': '10.0.0.2',
      'username': 'u',
      'password': 'p',
      'behavior': 'KeepAlive',
      'reconnectAfterSeconds': 30,
    },
  },
  'Telstra': {
    'wanType': 'Telstra',
    'mtu': 0,
    'telstraSettings': {'server': 'bpa', 'username': 'u', 'password': 'p'},
  },
  'Static': {
    'wanType': 'Static',
    'mtu': 1500,
    'staticSettings': _static,
    'domainName': 'home.example',
  },
  'Bridge with a static address': {
    'wanType': 'Bridge',
    'mtu': 0,
    'bridgeSettings': {'useStaticSettings': true, 'staticSettings': _static},
  },
  'DS-Lite with an AFTR URL': {
    'wanType': 'DSLite',
    'mtu': 0,
    'dsliteSettings': {
      'useManualSettings': true,
      'manualSettings': {'aftrURL': 'aftr.isp.example'},
    },
  },
  'Wireless bridge': {
    'wanType': 'WirelessBridge',
    'mtu': 0,
    'wirelessModeSettings': {
      'ssid': 'Upstream',
      'bssid': '00:11:22:33:44:55',
      'band': '5GHz',
      'security': 'WPA2-Personal',
      'password': 'upstream-pass',
    },
  },
};

void main() {
  group('RouterWANSettings', () {
    for (final MapEntry(key: name, value: output) in _outputs.entries) {
      test('$name: reads the router output and writes it back unchanged', () {
        expect(_wire(RouterWANSettings.fromJson(output).toJson()), output);
      });
    }

    test('reads the fields the internet settings page builds on', () {
      final pppoe = RouterWANSettings.fromJson(_outputs['PPPoE with a VLAN']!);

      expect(pppoe.pppoeSettings?.behavior, 'ConnectOnDemand');
      expect(pppoe.pppoeSettings?.reconnectAfterSeconds, isNull);
      expect(pppoe.wanTaggingSettings?.vlanTaggingSettings?.vlanID, 100);
      final pptp =
          RouterWANSettings.fromJson(_outputs['PPTP with a static address']!);
      expect(pptp.tpSettings?.staticSettings?.gateway, '203.0.113.1');
    });

    test('each named constructor writes its connection type', () {
      final untagged = SinglePortVLANTaggingSettings(isEnabled: false);
      const tp = TPSettings(
        useStaticSettings: false,
        server: 's',
        username: 'u',
        password: 'p',
        behavior: 'KeepAlive',
      );
      final settings = [
        RouterWANSettings.dhcp(mtu: 0),
        RouterWANSettings.pppoe(
          mtu: 0,
          pppoeSettings: PPPoESettings(
            username: 'u',
            password: 'p',
            serviceName: '',
            behavior: 'KeepAlive',
            maxIdleMinutes: null,
            reconnectAfterSeconds: 30,
          ),
          wanTaggingSettings: untagged,
        ),
        RouterWANSettings.pptp(
            mtu: 0, tpSettings: tp, wanTaggingSettings: untagged),
        RouterWANSettings.l2tp(mtu: 0, tpSettings: tp),
        RouterWANSettings.static(
          mtu: 0,
          staticSettings: StaticSettings.fromJson(_static),
          wanTaggingSettings: untagged,
        ),
        RouterWANSettings.bridge(
            bridgeSettings: const BridgeSettings(useStaticSettings: false)),
      ];

      expect(settings.map((s) => s.wanType),
          ['DHCP', 'PPPoE', 'PPTP', 'L2TP', 'Static', 'Bridge']);
    });

    test('copyWith changes only what it names', () {
      final settings = RouterWANSettings.fromJson(_outputs['Static']!);

      final changed = settings.copyWith(mtu: 1400, domainName: 'other');

      expect(_wire(changed.toJson()), {
        ..._outputs['Static']!,
        'mtu': 1400,
        'domainName': 'other',
      });
    });
  });

  group('the settings within', () {
    test('copyWith changes only what it names', () {
      final static = StaticSettings.fromJson(_static);
      expect(_wire(static.copyWith(gateway: '203.0.113.254').toJson()),
          {..._static, 'gateway': '203.0.113.254'});

      final pppoeOutput =
          _outputs['PPPoE with a VLAN']!['pppoeSettings'] as Map;
      final pppoe =
          PPPoESettings.fromJson(Map<String, dynamic>.from(pppoeOutput));
      expect(_wire(pppoe.copyWith(username: 'new').toJson()),
          {...pppoeOutput, 'username': 'new'});

      final tpOutput =
          _outputs['PPTP with a static address']!['tpSettings'] as Map;
      final tp = TPSettings.fromJson(Map<String, dynamic>.from(tpOutput));
      expect(_wire(tp.copyWith(server: '10.0.0.9').toJson()),
          {...tpOutput, 'server': '10.0.0.9'});

      const telstra =
          TelstraSettings(server: 'bpa', username: 'u', password: 'p');
      expect(telstra.copyWith(password: 'q'),
          const TelstraSettings(server: 'bpa', username: 'u', password: 'q'));

      const bridge = BridgeSettings(useStaticSettings: false);
      expect(
          bridge.copyWith(useStaticSettings: true).useStaticSettings, isTrue);

      const dslite = DSLiteSettings(useManualSettings: false);
      expect(
        dslite.copyWith(
            useManualSettings: true,
            manualSettings: const AFTRSettings(aftrURL: 'aftr.isp.example')),
        const DSLiteSettings(
            useManualSettings: true,
            manualSettings: AFTRSettings(aftrURL: 'aftr.isp.example')),
      );

      const aftr = AFTRSettings(aftrURL: 'a');
      expect(aftr.copyWith(aftrURL: 'b'), const AFTRSettings(aftrURL: 'b'));

      const wireless = WirelessModeSettings(
          ssid: 'Upstream', security: 'None', password: '');
      expect(wireless.copyWith(band: '5GHz').band, '5GHz');
      expect(wireless.copyWith(band: '5GHz').ssid, 'Upstream');
    });

    test('the VLAN settings write back what they read', () {
      final taggingOutput =
          _outputs['PPPoE with a VLAN']!['wanTaggingSettings'] as Map;
      final tagging = SinglePortVLANTaggingSettings.fromJson(
          Map<String, dynamic>.from(taggingOutput));

      expect(_wire(tagging.toJson()), taggingOutput);
      expect(_wire(tagging.copyWith(isEnabled: false).toJson()),
          {...taggingOutput, 'isEnabled': false});

      final port = tagging.vlanTaggingSettings!;
      expect(_wire(port.copyWith(vlanID: 200).toJson()), {
        'vlanID': 200,
        'vlanPriority': 3,
        'vlanStatus': 'Tagged',
      });
    });
  });
}
