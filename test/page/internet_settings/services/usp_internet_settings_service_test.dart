import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/services/usp_internet_settings_service.dart';

class MockUspClient extends Mock implements UspClient {}

// Test data — WAN singleton (new vendor paths)
const _wanResponse = <String, dynamic>{
  'Device.IP.Interface.2.IPv4Address.1.AddressingType': 'DHCP',
  'Device.IP.Interface.2.MaxMTUSize': '1500',
  'Device.IP.Interface.2.IPv4Address.1.IPAddress': '192.168.1.100',
  'Device.IP.Interface.2.IPv4Address.1.SubnetMask': '255.255.255.0',
  'Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DefaultGateway': '192.168.1.1',
  'Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DNSServers': '8.8.8.8,8.8.4.4',
  'Device.PPP.Interface.1.Username': 'testuser',
  'Device.PPP.Interface.1.Password': 'testpass',
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

// Alias resolution responses
const _ipAliasResponse = <String, dynamic>{
  'Device.IP.Interface.1.Alias': 'lan',
  'Device.IP.Interface.2.Alias': 'wan',
};

const _ethLinkAliasResponse = <String, dynamic>{
  'Device.Ethernet.Link.1.Alias': 'eth-lan',
  'Device.Ethernet.Link.2.Alias': 'eth-wan',
};

/// Helper to create a mock get handler that handles all codegen paths
Map<String, dynamic> Function(List<String>) createFetchMockHandler({
  Map<String, dynamic> pppResponse = _pppResponse,
  Map<String, dynamic> vlanResponse = _vlanResponse,
}) {
  return (List<String> paths) {
    // Alias resolution (must be checked first)
    if (paths.any((p) => p.contains('Ethernet.Link.*.Alias'))) {
      return _ethLinkAliasResponse;
    }
    if (paths.any((p) => p.contains('IP.Interface.*.Alias'))) {
      return _ipAliasResponse;
    }
    // Other fetches
    if (paths.any((p) => p.contains('AddressingType'))) {
      return _wanResponse;
    }
    if (paths.any((p) => p.contains('IPv6Enable'))) {
      return _ipv6Response;
    }
    if (paths.any((p) => p.contains('PPP.Interface'))) {
      return pppResponse;
    }
    if (paths.any((p) => p.contains('VLANTermination'))) {
      return vlanResponse;
    }
    if (paths.any((p) => p.contains('DeviceInfo.HostName'))) {
      return const {'Device.DeviceInfo.HostName': 'Community00080'};
    }
    return {};
  };
}

void main() {
  late MockUspClient mockUsp;
  late UspInternetSettingsService service;

  setUp(() {
    mockUsp = MockUspClient();
    service = UspInternetSettingsService(mockUsp);
  });

  group('fetchSettings', () {
    test('fetches WAN, IPv6, PPP, and VLAN settings in parallel', () async {
      final handler = createFetchMockHandler();
      when(() => mockUsp.get(any())).thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
        return handler(paths);
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

    test('fetches and exposes router hostName', () async {
      final handler = createFetchMockHandler();
      when(() => mockUsp.get(any())).thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
        return handler(paths);
      });

      final result = await service.fetchSettings();

      expect(result.readOnlyInfo.hostName, equals('Community00080'));
    });

    test('handles empty PPP and VLAN instances gracefully', () async {
      final handler = createFetchMockHandler(
        pppResponse: _pppEmptyResponse,
        vlanResponse: _vlanEmptyResponse,
      );
      when(() => mockUsp.get(any())).thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
        return handler(paths);
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
        // Alias resolution
        if (paths.any((p) => p.contains('Ethernet.Link.*.Alias'))) {
          return _ethLinkAliasResponse;
        }
        if (paths.any((p) => p.contains('IP.Interface.*.Alias'))) {
          return _ipAliasResponse;
        }
        if (paths.any((p) => p.contains('AddressingType'))) return wanWith3Dns;
        if (paths.any((p) => p.contains('IPv6Enable'))) return _ipv6Response;
        if (paths.any((p) => p.contains('PPP.Interface'))) {
          return _pppEmptyResponse;
        }
        if (paths.any((p) => p.contains('VLANTermination'))) {
          return _vlanEmptyResponse;
        }
        return {};
      });

      final result = await service.fetchSettings();

      expect(result.form.dnsServer1, equals('1.1.1.1'));
      expect(result.form.dnsServer2, equals('8.8.8.8'));
      expect(result.form.dnsServer3, equals('9.9.9.9'));
    });
  });

  group('saveAll', () {
    // Mock for _resolveInstance() calls in codegen update methods
    // UspClient.get() returns flat Map<String, dynamic>, not WASM format
    final aliasResponse = <String, dynamic>{
      'Device.IP.Interface.1.Alias': 'lan',
      'Device.IP.Interface.2.Alias': 'wan',
    };

    setUp(() {
      // Default mock for _resolveInstance() get calls
      when(() => mockUsp.get(any())).thenAnswer((_) async => aliasResponse);
      when(() => mockUsp.set(any())).thenAnswer((_) async => {
            'success': true,
            'result': {'data': <String, dynamic>{}}
          });
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {
                'success': true,
                'result': {'data': <String, dynamic>{}}
              });
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
      when(() => mockUsp.add(any())).thenAnswer((_) async => {
            'overallSuccess': true,
            'hasAnySuccess': true,
            'hasErrors': false,
            'results': [
              {
                'requestedPath': 'Device.PPP.Interface.',
                'success': true,
                'createdInstances': [
                  {
                    'affectedPath': 'Device.PPP.Interface.1.',
                    'initialParams': {}
                  }
                ]
              }
            ]
          });

      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
      );
      final edited = original.copyWith(
        connectionType: UspWanConnectionType.pppoe,
        pppUsername: 'user',
        pppPassword: 'pass',
      );

      await service.saveAll(original, edited);

      verify(() => mockUsp.add(any())).called(1);
    });

    test('enables VLAN via SET on existing instance', () async {
      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.pppoe,
        pppUsername: 'user',
        pppPassword: 'pass',
        vlanEnabled: false,
      );
      final edited = original.copyWith(vlanEnabled: true, vlanId: 100);

      await service.saveAll(
        original,
        edited,
        pppInstancePath: 'Device.PPP.Interface.1.',
        vlanInstancePath: 'Device.Ethernet.VLANTermination.1.',
      );

      final captured = verify(() => mockUsp.set(captureAny())).captured;
      final vlanSet = captured.lastWhere((params) => (params
              as Map<String, dynamic>)
          .keys
          .any((k) => k.contains('VLANTermination'))) as Map<String, dynamic>;
      expect(vlanSet['Device.Ethernet.VLANTermination.1.Enable'], isTrue);
      expect(vlanSet['Device.Ethernet.VLANTermination.1.VLANID'], equals(100));
    });

    test('disables VLAN via SET on existing instance', () async {
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
        pppInstancePath: 'Device.PPP.Interface.1.',
        vlanInstancePath: 'Device.Ethernet.VLANTermination.1.',
      );

      final captured = verify(() => mockUsp.set(captureAny())).captured;
      final vlanSet = captured.lastWhere((params) => (params
              as Map<String, dynamic>)
          .keys
          .any((k) => k.contains('VLANTermination'))) as Map<String, dynamic>;
      expect(vlanSet['Device.Ethernet.VLANTermination.1.Enable'], isFalse);
    });

    test('skips VLAN SET when no vlanInstancePath provided', () async {
      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.pppoe,
        pppUsername: 'user',
        pppPassword: 'pass',
        vlanEnabled: false,
        mtu: 1492,
      );
      final edited =
          original.copyWith(vlanEnabled: true, vlanId: 100, mtu: 1400);

      await service.saveAll(
        original,
        edited,
        pppInstancePath: 'Device.PPP.Interface.1.',
      );

      // MTU change triggers a set() call, but VLAN keys should not appear
      final setInvocations = verify(() => mockUsp.set(captureAny())).captured;
      for (final params in setInvocations) {
        final map = params as Map<String, dynamic>;
        expect(map.keys.any((k) => k.contains('VLANTermination')), isFalse);
      }
    });

    test('switching to DHCP sends only AddressingType', () async {
      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.staticIp,
        staticIpAddress: '10.0.0.1',
        subnetMask: '255.255.255.0',
        defaultGateway: '10.0.0.254',
        dnsServer1: '8.8.8.8',
      );
      final edited = original.copyWith(
        connectionType: UspWanConnectionType.dhcp,
      );

      await service.saveAll(original, edited);

      final captured = verify(
        () =>
            mockUsp.set(captureAny(), allowPartial: any(named: 'allowPartial')),
      ).captured;
      // Exactly 1 set call for WanDhcp.update (AddressingType only)
      // IPv6 and other calls may also use set, so find the one with AddressingType
      final dhcpParams = captured.whereType<Map<String, dynamic>>().where((m) =>
          m.containsKey('Device.IP.Interface.2.IPv4Address.1.AddressingType'));
      expect(dhcpParams.length, equals(1));
      expect(
        dhcpParams.first['Device.IP.Interface.2.IPv4Address.1.AddressingType'],
        equals('DHCP'),
      );
      expect(dhcpParams.first.length, equals(1));
    });

    test('switching to Static IP sends 5 params in 2 ordered groups', () async {
      when(() => mockUsp
              .setOrdered(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {
                'success': true,
                'result': {'data': <String, dynamic>{}}
              });

      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
      );
      final edited = original.copyWith(
        connectionType: UspWanConnectionType.staticIp,
        staticIpAddress: '10.0.0.1',
        subnetMask: '255.255.255.0',
        defaultGateway: '10.0.0.254',
        dnsServer1: '8.8.8.8',
      );

      await service.saveAll(original, edited);

      final captured = verify(
        () => mockUsp.setOrdered(captureAny(),
            allowPartial: any(named: 'allowPartial')),
      ).captured;
      final orderedGroups = captured.first as List<List<Map<String, String>>>;

      // Group 1: AddressingType only
      expect(orderedGroups[0].length, equals(1));
      expect(orderedGroups[0][0]['path'],
          equals('Device.IP.Interface.2.IPv4Address.1.AddressingType'));
      expect(orderedGroups[0][0]['value'], equals('Static'));

      // Group 2: 4 IP config fields
      expect(orderedGroups[1].length, equals(4));
      final group2Paths = orderedGroups[1].map((p) => p['path']).toSet();
      expect(
          group2Paths,
          containsAll([
            'Device.IP.Interface.2.IPv4Address.1.IPAddress',
            'Device.IP.Interface.2.IPv4Address.1.SubnetMask',
            'Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DefaultGateway',
            'Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DNSServers',
          ]));
    });

    test('switching to PPPoE sends 3 params (PPP creds + AddressingType)',
        () async {
      when(() => mockUsp.add(any())).thenAnswer((_) async => {
            'overallSuccess': true,
            'hasAnySuccess': true,
            'hasErrors': false,
            'results': [
              {
                'requestedPath': 'Device.PPP.Interface.',
                'success': true,
                'createdInstances': [
                  {
                    'affectedPath': 'Device.PPP.Interface.1.',
                    'initialParams': {}
                  }
                ]
              }
            ]
          });

      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
      );
      final edited = original.copyWith(
        connectionType: UspWanConnectionType.pppoe,
        pppUsername: 'myuser',
        pppPassword: 'mypass',
      );

      await service.saveAll(original, edited);

      final captured = verify(
        () =>
            mockUsp.set(captureAny(), allowPartial: any(named: 'allowPartial')),
      ).captured;
      // Find the set call that contains PPP credentials + AddressingType
      final pppoeParams = captured.whereType<Map<String, dynamic>>().where(
          (m) =>
              m.containsKey('Device.PPP.Interface.1.Username') ||
              m.containsKey(
                  'Device.IP.Interface.2.IPv4Address.1.AddressingType'));
      // WanPppoe.update sends all 3 in one set call
      final combinedParams = pppoeParams.firstWhere(
        (m) => m.containsKey('Device.PPP.Interface.1.Username'),
      );
      expect(combinedParams.length, equals(3));
      expect(
          combinedParams['Device.PPP.Interface.1.Username'], equals('myuser'));
      expect(
          combinedParams['Device.PPP.Interface.1.Password'], equals('mypass'));
      expect(
        combinedParams['Device.IP.Interface.2.IPv4Address.1.AddressingType'],
        equals('IPCP'),
      );
    });

    test('switching to Bridge sends only AddressingType as empty string',
        () async {
      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
      );
      final edited = original.copyWith(
        connectionType: UspWanConnectionType.bridge,
      );

      await service.saveAll(original, edited);

      final captured = verify(
        () =>
            mockUsp.set(captureAny(), allowPartial: any(named: 'allowPartial')),
      ).captured;
      final bridgeParams = captured.whereType<Map<String, dynamic>>().where(
          (m) => m.containsKey(
              'Device.IP.Interface.2.IPv4Address.1.AddressingType'));
      expect(bridgeParams.length, equals(1));
      expect(
        bridgeParams
            .first['Device.IP.Interface.2.IPv4Address.1.AddressingType'],
        equals(''),
      );
      expect(bridgeParams.first.length, equals(1));
    });

    test(
        'entering bridge treats a transport error on the bridge SET as success',
        () async {
      // The firmware applies bridge mode and drops this connection ~2s after
      // receiving the SET, so its response never arrives — the request fails
      // with a transport error. That is the expected signature of success, so
      // saveAll must complete normally (no throw), not surface a spurious error.
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenThrow('Set failed: Transport error: Request timeout');

      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
      );
      final edited = original.copyWith(
        connectionType: UspWanConnectionType.bridge,
      );

      await expectLater(service.saveAll(original, edited), completes);
    });

    test('entering bridge swallows a Dart timeout on the bridge SET', () {
      // When no transport error arrives first, the .timeout(4s) budget elapses
      // and throws TimeoutException — also the disconnect signature. Drive the
      // 4s with fake_async so the test does not actually wait.
      fakeAsync((async) {
        // Bridge SET never completes (connection gone); other SETs are no-ops.
        when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
            .thenAnswer((_) => Completer<Map<String, dynamic>>().future);

        final original = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
        );
        final edited = original.copyWith(
          connectionType: UspWanConnectionType.bridge,
        );

        Object? error;
        var done = false;
        service.saveAll(original, edited).then(
              (_) => done = true,
              onError: (Object e) => error = e,
            );

        async.elapse(const Duration(seconds: 5));

        expect(error, isNull,
            reason: 'a bridge-apply timeout must be treated as success');
        expect(done, isTrue);
      });
    });

    test('entering bridge rethrows a real fault on the bridge SET', () async {
      // A fault code means the router actively rejected the SET BEFORE any
      // disconnect — a genuine config failure that must still reach the user,
      // never swallowed by the fire-and-forget handling.
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {
                'success': false,
                'result': {
                  'data': <String, dynamic>{},
                  'error': {
                    'Device.IP.Interface.2.IPv4Address.1.AddressingType': {
                      'errorCode': 7006,
                      'errorMessage': 'Invalid value',
                    },
                  },
                },
              });

      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
      );
      final edited = original.copyWith(
        connectionType: UspWanConnectionType.bridge,
      );

      await expectLater(
        service.saveAll(original, edited),
        throwsA(isA<ServiceError>()),
      );
    });

    test('entering bridge sends the terminal bridge SET after the IPv6 SET',
        () async {
      // Part B: FW-spec SETs (here IPv6) must land on a live connection, so the
      // terminal bridge SET is deferred to last even when both change at once.
      final captureOrder = <Map<String, dynamic>>[];
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((invocation) async {
        captureOrder
            .add(invocation.positionalArguments[0] as Map<String, dynamic>);
        return {
          'success': true,
          'result': {'data': <String, dynamic>{}}
        };
      });

      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
        ipv6Enabled: true,
      );
      final edited = original.copyWith(
        connectionType: UspWanConnectionType.bridge,
        ipv6Enabled: false,
      );

      await service.saveAll(original, edited);

      final ipv6Index = captureOrder.indexWhere(
          (m) => m.keys.any((k) => k.contains('IPv6') || k.contains('DHCPv6')));
      final bridgeIndex = captureOrder.indexWhere((m) =>
          m.containsKey('Device.IP.Interface.2.IPv4Address.1.AddressingType'));

      expect(ipv6Index, greaterThanOrEqualTo(0),
          reason: 'IPv6 change should have produced a SET');
      expect(bridgeIndex, greaterThanOrEqualTo(0),
          reason: 'bridge switch should have produced a SET');
      expect(bridgeIndex, greaterThan(ipv6Index),
          reason: 'bridge SET must be sent after the IPv6 SET');
    });

    test('MTU change without type change sends only MTU param', () async {
      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
        mtu: 1500,
      );
      final edited = original.copyWith(mtu: 1400);

      await service.saveAll(original, edited);

      final captured = verify(
        () =>
            mockUsp.set(captureAny(), allowPartial: any(named: 'allowPartial')),
      ).captured;
      // Should have exactly 1 set call with MTU param
      final mtuParams = captured
          .whereType<Map<String, dynamic>>()
          .where((m) => m.containsKey('Device.IP.Interface.2.MaxMTUSize'));
      expect(mtuParams.length, equals(1));
      expect(
        mtuParams.first['Device.IP.Interface.2.MaxMTUSize'],
        equals(1400),
      );
      expect(mtuParams.first.length, equals(1));
    });
  });

  group('renewDhcpLease', () {
    test('calls WanOperations.renewDhcpLease', () async {
      // WASM v0.11.0 format for OPERATE success
      when(() => mockUsp.operate(any())).thenAnswer((_) async => {
            'success': true,
            'result': {'data': <String, dynamic>{}},
          });

      await service.renewDhcpLease();

      verify(() => mockUsp.operate('Device.DHCPv4.Client.1.Renew()')).called(1);
    });
  });

  group('renewDhcpv6Lease', () {
    test('calls WanOperations.renewDhcpv6Lease', () async {
      // WASM v0.11.0 format for OPERATE success
      when(() => mockUsp.operate(any())).thenAnswer((_) async => {
            'success': true,
            'result': {'data': <String, dynamic>{}},
          });

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

  // ---------------------------------------------------------------------------
  // UspResultParser failure scenarios
  // ---------------------------------------------------------------------------

  group('UspInternetSettingsService — UspResultParser failure handling', () {
    // Mock for _resolveInstance() calls in codegen update methods
    // UspClient.get() returns flat Map<String, dynamic>, not WASM format
    final aliasResponse = <String, dynamic>{
      'Device.IP.Interface.1.Alias': 'lan',
      'Device.IP.Interface.2.Alias': 'wan',
    };

    test('saveAll throws UspCompleteFailureError on SET failure', () async {
      // Mock for _resolveInstance()
      when(() => mockUsp.get(any())).thenAnswer((_) async => aliasResponse);
      // WASM v0.11.0 format: success=false
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {
                'success': false,
                'result': {
                  'data': <String, dynamic>{},
                  'error': {
                    'Device.IP.Interface.2.MaxMTUSize': {
                      'errorCode': 7004,
                      'errorMessage': 'Parameter not writable',
                    },
                  },
                },
              });

      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
        mtu: 1500,
      );
      final edited = original.copyWith(mtu: 1400);

      expect(
        () => service.saveAll(original, edited),
        throwsA(isA<UspCompleteFailureError>()),
      );
    });

    test('saveAll throws UspPartialFailureError on SET partial failure',
        () async {
      // Mock for _resolveInstance()
      when(() => mockUsp.get(any())).thenAnswer((_) async => aliasResponse);
      // WASM v0.11.0 format: success=true but has error field
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {
                'success': true,
                'result': {
                  'data': {
                    'Device.IP.Interface.2.MaxMTUSize': 1400,
                  },
                  'error': {
                    'Device.IP.Interface.2.SomeOtherParam': {
                      'errorCode': 7026,
                      'errorMessage': 'Parameter does not exist',
                    },
                  },
                },
              });

      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
        mtu: 1500,
      );
      final edited = original.copyWith(mtu: 1400);

      expect(
        () => service.saveAll(original, edited),
        throwsA(isA<UspPartialFailureError>()),
      );
    });

    test('renewDhcpLease throws UspCompleteFailureError on OPERATE failure',
        () async {
      // WASM v0.11.0 format: success=false for OPERATE
      when(() => mockUsp.operate(any())).thenAnswer((_) async => {
            'success': false,
            'result': {
              'data': <String, dynamic>{},
              'error': {
                'Device.DHCPv4.Client.1.Renew()': {
                  'errorCode': 7012,
                  'errorMessage': 'Command failure',
                },
              },
            },
          });

      expect(
        () => service.renewDhcpLease(),
        throwsA(isA<UspCompleteFailureError>()),
      );
    });

    test('UspCompleteFailureError contains correct error message', () async {
      // Mock for _resolveInstance()
      when(() => mockUsp.get(any())).thenAnswer((_) async => aliasResponse);
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {
                'success': false,
                'result': {
                  'data': <String, dynamic>{},
                  'error': {
                    'Device.IP.Interface.2.MaxMTUSize': {
                      'errorCode': 7004,
                      'errorMessage': 'Parameter not writable',
                    },
                  },
                },
              });

      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
        mtu: 1500,
      );
      final edited = original.copyWith(mtu: 1400);

      try {
        await service.saveAll(original, edited);
        fail('Expected UspCompleteFailureError');
      } on UspCompleteFailureError catch (e) {
        expect(e.summary, contains('WAN update failed'));
        expect(e.summary, contains('Parameter not writable'));
        expect(e.failedPaths, contains('Device.IP.Interface.2.MaxMTUSize'));
        // Verify toString() returns the summary for View layer display
        expect(e.toString(), equals(e.summary));
      }
    });

    test('UspPartialFailureError contains success and failure paths', () async {
      // Mock for _resolveInstance()
      when(() => mockUsp.get(any())).thenAnswer((_) async => aliasResponse);
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {
                'success': true,
                'result': {
                  'data': {
                    'Device.IP.Interface.2.MaxMTUSize': 1400,
                  },
                  'error': {
                    'Device.IP.Interface.2.SomeOtherParam': {
                      'errorCode': 7026,
                      'errorMessage': 'Parameter does not exist',
                    },
                  },
                },
              });

      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
        mtu: 1500,
      );
      final edited = original.copyWith(mtu: 1400);

      try {
        await service.saveAll(original, edited);
        fail('Expected UspPartialFailureError');
      } on UspPartialFailureError catch (e) {
        expect(e.summary, contains('WAN update partial failure'));
        expect(e.summary, contains('Parameter does not exist'));
        expect(e.successPaths, isNotEmpty);
        expect(e.failedPaths, contains('Device.IP.Interface.2.SomeOtherParam'));
        // Verify toString() includes "(Partial)" prefix for View layer display
        expect(e.toString(), startsWith('(Partial)'));
      }
    });
  });
}
