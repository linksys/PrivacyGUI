import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/services/usp_internet_settings_service.dart';

class MockUspService extends Mock implements UspService {}

// Test data — WAN singleton (new vendor paths)
const _wanResponse = <String, dynamic>{
  'Device.IP.Interface.2.IPv4Address.1.AddressingType': 'DHCP',
  'Device.IP.Interface.2.MaxMTUSize': '1500',
  'Device.IP.Interface.2.IPv4Address.1.IPAddress': '192.168.1.100',
  'Device.IP.Interface.2.IPv4Address.1.SubnetMask': '255.255.255.0',
  'Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DefaultGateway': '192.168.1.1',
  'Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DNSServers': '8.8.8.8,8.8.4.4',
  'Device.Bridging.Bridge.1.Enable': false,
  'Device.Ethernet.Interface.1.MACAddress': '11:22:33:44:55:66',
};

// Test data — PPP multi-instance
const _pppResponse = <String, dynamic>{
  'Device.PPP.Interface.1.Username': 'testuser',
  'Device.PPP.Interface.1.Password': 'testpass',
  'Device.PPP.Interface.1.PPPoE.ServiceName': '',
  'Device.PPP.Interface.1.ConnectionTrigger': 'AlwaysOn',
  'Device.PPP.Interface.1.IdleDisconnectTime': '0',
  'Device.PPP.Interface.1.LCPEcho': '30',
  'Device.PPP.Interface.1.ConnectionStatus': 'Connected',
};

// Test data — PPP empty (no instances)
const _pppEmptyResponse = <String, dynamic>{};

// Test data — VLAN multi-instance
const _vlanResponse = <String, dynamic>{
  'Device.Ethernet.VLANTermination.1.Enable': false,
  'Device.Ethernet.VLANTermination.1.VLANID': '0',
};

// Test data — VLAN empty (no instances)
const _vlanEmptyResponse = <String, dynamic>{};

const _ipv6Response = <String, dynamic>{
  'Device.IP.Interface.2.IPv6Enable': true,
  'Device.DHCPv6.Client.1.Enable': true,
  'Device.DHCPv6.Client.1.DUID': '00:01:00:01:2a:3b:4c:5d',
  'Device.IPv6rd.InterfaceSetting.1.Enable': false,
  'Device.IPv6rd.InterfaceSetting.1.SPIPv6Prefix': '',
  'Device.IPv6rd.InterfaceSetting.1.IPv4MaskLength': '0',
  'Device.IPv6rd.InterfaceSetting.1.BorderRelayIPv4Addresses': '',
};

void main() {
  late MockUspService mockUsp;
  late UspInternetSettingsService service;

  setUp(() {
    mockUsp = MockUspService();
    service = UspInternetSettingsService(mockUsp);
  });

  group('fetchSettings', () {
    test('fetches WAN, IPv6, PPP, and VLAN settings in parallel', () async {
      when(() => mockUsp.get(any())).thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
        if (paths.any((p) => p.contains('AddressingType'))) {
          return _wanResponse;
        }
        if (paths.any((p) => p.contains('IPv6Enable'))) {
          return _ipv6Response;
        }
        if (paths.any((p) => p.contains('PPP.Interface'))) {
          return _pppResponse;
        }
        if (paths.any((p) => p.contains('VLANTermination'))) {
          return _vlanResponse;
        }
        return {};
      });

      final result = await service.fetchSettings();

      expect(result.form.connectionType, equals(UspWanConnectionType.dhcp));
      expect(result.form.mtu, equals(1500));
      expect(result.form.staticIpAddress, equals('192.168.1.100'));
      expect(result.form.defaultGateway, equals('192.168.1.1'));
      expect(result.form.dnsServer1, equals('8.8.8.8'));
      expect(result.form.dnsServer2, equals('8.8.4.4'));
      expect(result.form.dnsServer3, equals(''));
      expect(result.form.pppUsername, equals('testuser'));
      expect(result.form.pppPassword, equals('testpass'));
      expect(result.form.lcpEchoInterval, equals(30));
      expect(result.form.ipv6Enabled, isTrue);
      expect(result.form.dhcpv6Enabled, isTrue);
      expect(result.pppInstancePath, equals('Device.PPP.Interface.1.'));
      expect(result.readOnlyInfo.pppConnectionStatus, equals('Connected'));
    });

    test('handles empty PPP and VLAN instances gracefully', () async {
      when(() => mockUsp.get(any())).thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
        if (paths.any((p) => p.contains('AddressingType'))) {
          return _wanResponse;
        }
        if (paths.any((p) => p.contains('IPv6Enable'))) {
          return _ipv6Response;
        }
        if (paths.any((p) => p.contains('PPP.Interface'))) {
          return _pppEmptyResponse;
        }
        if (paths.any((p) => p.contains('VLANTermination'))) {
          return _vlanEmptyResponse;
        }
        return {};
      });

      final result = await service.fetchSettings();

      expect(result.form.pppUsername, equals(''));
      expect(result.form.pppPassword, equals(''));
      expect(result.form.connectionTrigger, equals('AlwaysOn'));
      expect(result.form.vlanEnabled, isFalse);
      expect(result.pppInstancePath, isNull);
      expect(result.vlanInstancePath, isNull);
    });

    test('splits comma-separated DNS into 3 fields', () async {
      final wanWith3Dns = Map<String, dynamic>.from(_wanResponse);
      wanWith3Dns['Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DNSServers'] =
          '1.1.1.1,8.8.8.8,9.9.9.9';

      when(() => mockUsp.get(any())).thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
        if (paths.any((p) => p.contains('AddressingType'))) return wanWith3Dns;
        if (paths.any((p) => p.contains('IPv6Enable'))) return _ipv6Response;
        if (paths.any((p) => p.contains('PPP.Interface')))
          return _pppEmptyResponse;
        if (paths.any((p) => p.contains('VLANTermination')))
          return _vlanEmptyResponse;
        return {};
      });

      final result = await service.fetchSettings();

      expect(result.form.dnsServer1, equals('1.1.1.1'));
      expect(result.form.dnsServer2, equals('8.8.8.8'));
      expect(result.form.dnsServer3, equals('9.9.9.9'));
    });
  });

  group('saveAll', () {
    setUp(() {
      when(() => mockUsp.set(any())).thenAnswer((_) async {});
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async {});
    });

    test('sends only changed WAN fields', () async {
      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
        mtu: 1500,
        staticIpAddress: '192.168.1.100',
        subnetMask: '255.255.255.0',
        defaultGateway: '192.168.1.1',
        dnsServer1: '8.8.8.8',
      );

      final edited = original.copyWith(mtu: 1400);

      await service.saveAll(original, edited);

      verify(() => mockUsp.set(any())).called(greaterThanOrEqualTo(1));
    });

    test('does not send unchanged fields', () async {
      final form = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
        mtu: 1500,
      );

      await service.saveAll(form, form);

      verifyNever(() => mockUsp.set(any()));
    });

    test('merges DNS fields into comma-separated string on save', () async {
      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.staticIp,
        dnsServer1: '8.8.8.8',
        dnsServer2: '8.8.4.4',
      );

      final edited = original.copyWith(
        dnsServer1: '1.1.1.1',
        dnsServer2: '9.9.9.9',
      );

      await service.saveAll(original, edited);

      final captured = verify(() => mockUsp.set(captureAny())).captured;
      final params = captured.first as Map<String, dynamic>;
      expect(
        params['Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DNSServers'],
        equals('1.1.1.1,9.9.9.9'),
      );
    });

    test('adds PPP instance when switching to PPPoE without existing instance',
        () async {
      when(() => mockUsp.add(any(), any()))
          .thenAnswer((_) async => 'Device.PPP.Interface.1.');

      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
      );
      final edited = original.copyWith(
        connectionType: UspWanConnectionType.pppoe,
        pppUsername: 'user',
        pppPassword: 'pass',
      );

      await service.saveAll(original, edited);

      verify(() => mockUsp.add('Device.PPP.Interface.', any())).called(1);
    });

    test('deletes PPP instance when switching away from PPPoE', () async {
      when(() => mockUsp.delete(any())).thenAnswer((_) async {});

      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.pppoe,
        pppUsername: 'user',
        pppPassword: 'pass',
      );
      final edited = original.copyWith(
        connectionType: UspWanConnectionType.dhcp,
      );

      await service.saveAll(
        original,
        edited,
        pppInstancePath: 'Device.PPP.Interface.1.',
      );

      verify(() => mockUsp.delete('Device.PPP.Interface.1.')).called(1);
    });

    test('adds VLAN instance when enabling VLAN without existing instance',
        () async {
      when(() => mockUsp.add(any(), any()))
          .thenAnswer((_) async => 'Device.Ethernet.VLANTermination.1.');

      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.pppoe,
        pppUsername: 'user',
        pppPassword: 'pass',
        vlanEnabled: false,
      );
      final edited = original.copyWith(vlanEnabled: true, vlanId: 100);

      await service.saveAll(original, edited);

      verify(() => mockUsp.add('Device.Ethernet.VLANTermination.', any()))
          .called(1);
    });

    test('deletes VLAN instance when disabling VLAN', () async {
      when(() => mockUsp.delete(any())).thenAnswer((_) async {});

      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.pppoe,
        pppUsername: 'user',
        pppPassword: 'pass',
        vlanEnabled: true,
        vlanId: 100,
      );
      final edited = original.copyWith(vlanEnabled: false);

      await service.saveAll(
        original,
        edited,
        vlanInstancePath: 'Device.Ethernet.VLANTermination.1.',
      );

      verify(() => mockUsp.delete('Device.Ethernet.VLANTermination.1.'))
          .called(1);
    });
  });

  group('renewDhcpLease', () {
    test('calls WanOperations.renewDhcpLease', () async {
      when(() => mockUsp.operate(any()))
          .thenAnswer((_) async => <String, dynamic>{});

      await service.renewDhcpLease();

      verify(() => mockUsp.operate('Device.DHCPv4.Client.1.Renew()')).called(1);
    });
  });

  group('renewDhcpv6Lease', () {
    test('calls WanOperations.renewDhcpv6Lease', () async {
      when(() => mockUsp.operate(any()))
          .thenAnswer((_) async => <String, dynamic>{});

      await service.renewDhcpv6Lease();

      verify(() => mockUsp.operate('Device.DHCPv6.Client.1.Renew()')).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // Error handling
  // ---------------------------------------------------------------------------

  group('UspInternetSettingsService — error handling', () {
    test('fetchSettings maps USP error to ServiceError', () async {
      when(() => mockUsp.get(any()))
          .thenThrow('Get failed: Transport error: HTTP error: HTTP 504');

      expect(
        () => service.fetchSettings(),
        throwsA(isA<ServiceError>()),
      );
    });

    test('saveAll maps USP error to ServiceError', () async {
      when(() => mockUsp.set(any()))
          .thenThrow('Set failed: Protocol error: invalid value (code: 9008)');

      final form = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
        mtu: 1500,
      );
      final edited = form.copyWith(mtu: 1400);

      expect(
        () => service.saveAll(form, edited),
        throwsA(isA<ServiceError>()),
      );
    });

    test('renewDhcpLease maps USP error to ServiceError', () async {
      when(() => mockUsp.operate(any()))
          .thenThrow('Operate failed: Transport error: Connection refused');

      expect(
        () => service.renewDhcpLease(),
        throwsA(isA<ServiceError>()),
      );
    });

    test('renewDhcpv6Lease maps USP error to ServiceError', () async {
      when(() => mockUsp.operate(any()))
          .thenThrow('Operate failed: Transport error: Connection refused');

      expect(
        () => service.renewDhcpv6Lease(),
        throwsA(isA<ServiceError>()),
      );
    });
  });
}
