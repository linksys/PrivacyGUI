import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/lan_network_info.g.dart';
import 'package:privacy_gui/page/local_network/models/local_network_ui_model.dart';
import 'package:privacy_gui/page/local_network/services/usp_local_network_service.dart';

class MockUspClient extends Mock implements UspClient {}

LanNetworkInfo _lanInfo({
  String ipAddress = '192.168.1.1',
  String subnetMask = '255.255.255.0',
  bool dhcpEnabled = true,
  String minAddress = '192.168.1.100',
  String maxAddress = '192.168.1.200',
  int leaseTime = 86400,
  String dnsServers = '8.8.8.8,8.8.4.4',
  String hostName = 'MyRouter',
  bool ipv6Enabled = false,
}) =>
    LanNetworkInfo(
      ipAddress: ipAddress,
      subnetMask: subnetMask,
      dhcpEnabled: dhcpEnabled,
      minAddress: minAddress,
      maxAddress: maxAddress,
      leaseTime: leaseTime,
      dnsServers: dnsServers,
      hostName: hostName,
      ipv6Enabled: ipv6Enabled,
    );

LocalNetworkUIModel _model({
  String hostName = 'MyRouter',
  String ipAddress = '192.168.1.1',
  String subnetMask = '255.255.255.0',
  bool dhcpEnabled = true,
  String minAddress = '192.168.1.100',
  String maxAddress = '192.168.1.200',
  int leaseTimeMinutes = 1440,
  String dnsServer1 = '8.8.8.8',
  String dnsServer2 = '8.8.4.4',
  String dnsServer3 = '',
}) =>
    LocalNetworkUIModel(
      hostName: hostName,
      ipAddress: ipAddress,
      subnetMask: subnetMask,
      dhcpEnabled: dhcpEnabled,
      minAddress: minAddress,
      maxAddress: maxAddress,
      leaseTimeMinutes: leaseTimeMinutes,
      dnsServer1: dnsServer1,
      dnsServer2: dnsServer2,
      dnsServer3: dnsServer3,
    );

void main() {
  late MockUspClient mockUsp;
  late UspLocalNetworkService service;

  setUp(() {
    mockUsp = MockUspClient();
    service = UspLocalNetworkService(mockUsp);
  });

  // ---------------------------------------------------------------------------
  // buildUIModel
  // ---------------------------------------------------------------------------

  group('UspLocalNetworkService — buildUIModel', () {
    test('maps all fields correctly', () {
      final data = _lanInfo(
        ipAddress: '192.168.1.1',
        subnetMask: '255.255.255.0',
        dhcpEnabled: true,
        minAddress: '192.168.1.100',
        maxAddress: '192.168.1.200',
        leaseTime: 7200,
        dnsServers: '1.1.1.1,8.8.8.8,9.9.9.9',
        hostName: 'Router',
      );

      final result = service.buildUIModel(data);

      expect(result.hostName, 'Router');
      expect(result.ipAddress, '192.168.1.1');
      expect(result.subnetMask, '255.255.255.0');
      expect(result.dhcpEnabled, isTrue);
      expect(result.minAddress, '192.168.1.100');
      expect(result.maxAddress, '192.168.1.200');
      expect(result.leaseTimeMinutes, 120); // 7200s / 60
      expect(result.dnsServer1, '1.1.1.1');
      expect(result.dnsServer2, '8.8.8.8');
      expect(result.dnsServer3, '9.9.9.9');
    });

    test('splits DNS: single server', () {
      final data = _lanInfo(dnsServers: '1.1.1.1');
      final result = service.buildUIModel(data);
      expect(result.dnsServer1, '1.1.1.1');
      expect(result.dnsServer2, '');
      expect(result.dnsServer3, '');
    });

    test('splits DNS: empty string yields one empty field', () {
      final data = _lanInfo(dnsServers: '');
      final result = service.buildUIModel(data);
      expect(result.dnsServer1, '');
    });

    test('lease time rounds correctly', () {
      // 90 seconds → 2 minutes (rounds 1.5)
      final data = _lanInfo(leaseTime: 90);
      expect(service.buildUIModel(data).leaseTimeMinutes, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // joinDnsServers
  // ---------------------------------------------------------------------------

  group('UspLocalNetworkService — joinDnsServers', () {
    test('joins non-empty servers', () {
      expect(service.joinDnsServers('1.1.1.1', '8.8.8.8', '9.9.9.9'),
          '1.1.1.1,8.8.8.8,9.9.9.9');
    });

    test('skips empty servers', () {
      expect(
          service.joinDnsServers('1.1.1.1', '', '9.9.9.9'), '1.1.1.1,9.9.9.9');
    });

    test('all empty returns empty string', () {
      expect(service.joinDnsServers('', '', ''), '');
    });

    test('whitespace-only servers are excluded', () {
      expect(service.joinDnsServers(' 1.1.1.1 ', '  ', ' 9.9.9.9'),
          ' 1.1.1.1 , 9.9.9.9');
    });
  });

  // ---------------------------------------------------------------------------
  // validateHostName
  // ---------------------------------------------------------------------------

  group('UspLocalNetworkService — validateHostName', () {
    test('valid hostname returns null', () {
      expect(service.validateHostName('MyRouter'), isNull);
    });

    test('empty hostname returns error', () {
      expect(service.validateHostName(''), isNotNull);
    });

    test('over 15 chars returns error', () {
      expect(service.validateHostName('A' * 16), isNotNull);
    });

    test('exactly 15 chars is valid', () {
      expect(service.validateHostName('A' * 15), isNull);
    });

    test('leading hyphen rejected', () {
      expect(service.validateHostName('-router'), isNotNull);
    });

    test('trailing hyphen rejected', () {
      expect(service.validateHostName('router-'), isNotNull);
    });

    test('hyphens in middle allowed', () {
      expect(service.validateHostName('my-router'), isNull);
    });

    test('single character valid', () {
      expect(service.validateHostName('R'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // validateIpAddress
  // ---------------------------------------------------------------------------

  group('UspLocalNetworkService — validateIpAddress', () {
    test('valid IP returns null', () {
      expect(service.validateIpAddress('192.168.1.1'), isNull);
    });

    test('empty IP returns error', () {
      expect(service.validateIpAddress(''), isNotNull);
    });

    test('invalid format returns error', () {
      expect(service.validateIpAddress('not.an.ip'), isNotNull);
    });

    test('0.0.0.0 returns reserved error', () {
      expect(service.validateIpAddress('0.0.0.0'), contains('Reserved'));
    });

    test('255.255.255.255 returns reserved error', () {
      expect(
          service.validateIpAddress('255.255.255.255'), contains('Reserved'));
    });
  });

  // ---------------------------------------------------------------------------
  // validateSubnetMask
  // ---------------------------------------------------------------------------

  group('UspLocalNetworkService — validateSubnetMask', () {
    test('valid mask returns null', () {
      expect(service.validateSubnetMask('255.255.255.0'), isNull);
    });

    test('empty mask returns error', () {
      expect(service.validateSubnetMask(''), isNotNull);
    });

    test('invalid mask returns error', () {
      expect(service.validateSubnetMask('255.0.255.0'), isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // validateLeaseTime
  // ---------------------------------------------------------------------------

  group('UspLocalNetworkService — validateLeaseTime', () {
    test('1 minute is valid', () {
      expect(service.validateLeaseTime(1), isNull);
    });

    test('525600 minutes is valid', () {
      expect(service.validateLeaseTime(525600), isNull);
    });

    test('0 minutes returns error', () {
      expect(service.validateLeaseTime(0), isNotNull);
    });

    test('525601 minutes returns error', () {
      expect(service.validateLeaseTime(525601), isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // validateDns
  // ---------------------------------------------------------------------------

  group('UspLocalNetworkService — validateDns', () {
    test('empty string is valid (optional)', () {
      expect(service.validateDns(''), isNull);
    });

    test('whitespace-only is valid (optional)', () {
      expect(service.validateDns('   '), isNull);
    });

    test('valid IP is valid', () {
      expect(service.validateDns('8.8.8.8'), isNull);
    });

    test('invalid IP returns error', () {
      expect(service.validateDns('not-ip'), isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // lockedOctetCount
  // ---------------------------------------------------------------------------

  group('UspLocalNetworkService — lockedOctetCount', () {
    test('/24 → 3', () {
      expect(service.lockedOctetCount('255.255.255.0'), 3);
    });

    test('/16 → 2', () {
      expect(service.lockedOctetCount('255.255.0.0'), 2);
    });

    test('/8 → 1', () {
      expect(service.lockedOctetCount('255.0.0.0'), 1);
    });

    test('invalid mask → 0', () {
      expect(service.lockedOctetCount('invalid'), 0);
    });
  });

  // ---------------------------------------------------------------------------
  // ipPrefix
  // ---------------------------------------------------------------------------

  group('UspLocalNetworkService — ipPrefix', () {
    test('3 locked octets', () {
      expect(service.ipPrefix('192.168.1.100', 3), '192.168.1');
    });

    test('2 locked octets', () {
      expect(service.ipPrefix('10.0.0.1', 2), '10.0');
    });

    test('0 locked octets returns empty', () {
      expect(service.ipPrefix('192.168.1.1', 0), '');
    });

    test('invalid IP returns empty', () {
      expect(service.ipPrefix('invalid', 3), '');
    });
  });

  // ---------------------------------------------------------------------------
  // syncPrefix
  // ---------------------------------------------------------------------------

  group('UspLocalNetworkService — syncPrefix', () {
    test('replaces locked octets from router IP', () {
      expect(
          service.syncPrefix('10.0.0.100', '192.168.1.1', 3), '192.168.1.100');
    });

    test('2 locked octets', () {
      expect(service.syncPrefix('10.0.0.100', '172.16.0.1', 2), '172.16.0.100');
    });

    test('0 locked octets returns original', () {
      expect(service.syncPrefix('10.0.0.100', '192.168.1.1', 0), '10.0.0.100');
    });

    test('empty ip returns empty', () {
      expect(service.syncPrefix('', '192.168.1.1', 3), '');
    });

    test('invalid IP parts returns original', () {
      expect(service.syncPrefix('invalid', '192.168.1.1', 3), 'invalid');
    });
  });

  // ---------------------------------------------------------------------------
  // validateAll
  // ---------------------------------------------------------------------------

  group('UspLocalNetworkService — validateAll', () {
    test('valid model with DHCP enabled returns no errors', () {
      final errors = service.validateAll(_model());
      // All values should be null (no errors)
      expect(errors.values.where((v) => v != null), isEmpty);
    });

    test('DHCP disabled skips pool/DNS validation', () {
      final errors = service.validateAll(_model(
        dhcpEnabled: false,
        minAddress: '', // would fail if validated
        maxAddress: '',
        dnsServer1: 'not-an-ip', // would fail if validated
      ));
      expect(errors['minAddress'], isNull);
      expect(errors['maxAddress'], isNull);
      expect(errors['dnsServer1'], isNull);
    });

    test('validates hostName, ipAddress, subnetMask independently', () {
      final errors = service.validateAll(_model(
        hostName: '',
        ipAddress: '',
        subnetMask: '',
      ));
      expect(errors['hostName'], isNotNull);
      expect(errors['ipAddress'], isNotNull);
      expect(errors['subnetMask'], isNotNull);
    });

    test('pool validation cascades after IP/subnet are valid', () {
      final errors = service.validateAll(_model(
        ipAddress: '192.168.1.1',
        subnetMask: '255.255.255.0',
        minAddress: '10.0.0.1', // wrong subnet
        maxAddress: '192.168.1.200',
      ));
      expect(errors['minAddress'], isNotNull);
    });

    test('pool validation skipped when IP is invalid', () {
      final errors = service.validateAll(_model(
        ipAddress: 'invalid',
        minAddress: '10.0.0.1', // would fail subnet check
      ));
      // Pool validation not run because IP itself is invalid
      expect(errors['minAddress'], isNull);
    });

    test('min >= max returns error', () {
      final errors = service.validateAll(_model(
        minAddress: '192.168.1.200',
        maxAddress: '192.168.1.100',
      ));
      expect(errors['maxAddress'], isNotNull);
    });

    test('pool containing router IP returns error', () {
      final errors = service.validateAll(_model(
        ipAddress: '192.168.1.150',
        minAddress: '192.168.1.100',
        maxAddress: '192.168.1.200',
      ));
      expect(errors['minAddress'], contains('router IP'));
    });

    test('pool address equal to router IP returns error', () {
      final errors = service.validateAll(_model(
        ipAddress: '192.168.1.1',
        minAddress: '192.168.1.1',
      ));
      expect(errors['minAddress'], contains('router IP'));
    });
  });

  // ---------------------------------------------------------------------------
  // save
  // ---------------------------------------------------------------------------

  group('UspLocalNetworkService — save', () {
    test('save succeeds when firmware returns success', () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => {
            'success': true,
            'result': {'data': <String, dynamic>{}},
          });

      await service.save(
        original: _model(),
        pending: _model(hostName: 'NewRouter'),
      );

      verify(() => mockUsp.set(any())).called(1);
    });

    test('save throws UspCompleteFailureError on firmware failure', () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => {
            'success': false,
            'result': {
              'data': <String, dynamic>{},
              'error': {
                'Device.DHCPv4.Server.Pool.1.MinAddress': {
                  'errorCode': 7004,
                  'errorMessage': 'Parameter not writable'
                }
              }
            },
          });

      expect(
        () => service.save(
          original: _model(),
          pending: _model(minAddress: '192.168.1.50'),
        ),
        throwsA(isA<UspCompleteFailureError>()),
      );
    });

    test('save throws UspPartialFailureError on partial success', () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => {
            'success': true,
            'result': {
              'data': {
                'Device.DHCPv4.Server.Pool.1.MinAddress': '192.168.1.50'
              },
              'error': {
                'Device.DHCPv4.Server.Pool.1.MaxAddress': {
                  'errorCode': 7004,
                  'errorMessage': 'Parameter not writable'
                }
              }
            },
          });

      expect(
        () => service.save(
          original: _model(),
          pending:
              _model(minAddress: '192.168.1.50', maxAddress: '192.168.1.250'),
        ),
        throwsA(isA<UspPartialFailureError>()),
      );
    });

    test('save maps transport error to ServiceError', () async {
      when(() => mockUsp.set(any()))
          .thenThrow('Set failed: Transport error: Connection refused');

      expect(
        () => service.save(
          original: _model(),
          pending: _model(hostName: 'NewRouter'),
        ),
        throwsA(isA<ServiceError>()),
      );
    });
  });
}
