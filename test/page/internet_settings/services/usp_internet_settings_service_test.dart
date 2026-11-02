import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/services/usp_internet_settings_service.dart';

import '../../../mocks/test_data/internet_settings_test_data.dart';

class MockUspClient extends Mock implements UspClient {}

// Test data — WAN singleton (new vendor paths)
const _wanResponse = <String, dynamic>{
  'Device.IP.Interface.2.IPv4Address.1.AddressingType': 'DHCP',
  'Device.IP.Interface.2.MaxMTUSize': '1500',
  'Device.IP.Interface.2.LowerLayers': 'Device.Ethernet.Link.2',
  'Device.IP.Interface.2.X_LINKSYS_MTUMode': 'Manual',
  'Device.IP.Interface.2.IPv4Address.1.IPAddress': '192.168.1.100',
  'Device.IP.Interface.2.IPv4Address.1.SubnetMask': '255.255.255.0',
  'Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DefaultGateway': '192.168.1.1',
  'Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DNSServers': '8.8.8.8,8.8.4.4',
  'Device.IP.Interface.2.Enable': true,
  'Device.Ethernet.Interface.1.MACAddress': '11:22:33:44:55:66',
};

/// Runs [body] and returns the warning lines the logger printed meanwhile.
///
/// The logger prints every line in a debug test run, so a print hook sees what
/// a field log would hold.
Future<List<String>> _warningsDuring(Future<void> Function() body) async {
  final lines = <String>[];
  await runZoned(
    () async {
      try {
        await body();
      } catch (_) {}
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        if (line.contains('[W]')) lines.add(line);
      },
    ),
  );
  return lines;
}

/// [_wanResponse] on a PPP connection type (`AddressingType` = `IPCP`).
Map<String, dynamic> _wanIpcp() => Map<String, dynamic>.from(_wanResponse)
  ..['Device.IP.Interface.2.IPv4Address.1.AddressingType'] = 'IPCP';

// Test data — PPP multi-instance
const _pppResponse = <String, dynamic>{
  'Device.PPP.Interface.1.Username': 'testuser',
  'Device.PPP.Interface.1.Password': 'testpass',
  'Device.PPP.Interface.1.PPPoE.ServiceName': '',
  'Device.PPP.Interface.1.ConnectionTrigger': 'AlwaysOn',
  'Device.PPP.Interface.1.IdleDisconnectTime': '0',
  'Device.PPP.Interface.1.LCPEcho': '30',
  'Device.PPP.Interface.1.LCPEchoRetry': '5',
  'Device.PPP.Interface.1.ConnectionStatus': 'Connected',
  'Device.PPP.Interface.1.LowerLayers': '',
};

// Test data — PPP with GRE LowerLayers (PPTP)
const _pppPptpResponse = <String, dynamic>{
  'Device.PPP.Interface.1.Username': 'vpnuser',
  'Device.PPP.Interface.1.Password': 'vpnpass',
  'Device.PPP.Interface.1.PPPoE.ServiceName': '',
  'Device.PPP.Interface.1.ConnectionTrigger': 'AlwaysOn',
  'Device.PPP.Interface.1.IdleDisconnectTime': '0',
  'Device.PPP.Interface.1.LCPEcho': '0',
  'Device.PPP.Interface.1.LCPEchoRetry': '5',
  'Device.PPP.Interface.1.ConnectionStatus': 'Connected',
  'Device.PPP.Interface.1.LowerLayers': 'Device.GRE.Tunnel.1.Interface.1',
};

// Test data — PPP with L2TPv2 LowerLayers (L2TP)
const _pppL2tpResponse = <String, dynamic>{
  'Device.PPP.Interface.1.Username': 'l2tpuser',
  'Device.PPP.Interface.1.Password': 'l2tppass',
  'Device.PPP.Interface.1.PPPoE.ServiceName': '',
  'Device.PPP.Interface.1.ConnectionTrigger': 'AlwaysOn',
  'Device.PPP.Interface.1.IdleDisconnectTime': '0',
  'Device.PPP.Interface.1.LCPEcho': '0',
  'Device.PPP.Interface.1.LCPEchoRetry': '5',
  'Device.PPP.Interface.1.ConnectionStatus': 'Connected',
  'Device.PPP.Interface.1.LowerLayers': 'Device.L2TPv2.Tunnel.1.Interface.1',
};

// Test data — GRE Tunnel
const _greResponse = <String, dynamic>{
  'Device.GRE.Tunnel.1.RemoteEndpoints': 'pptp.example.com',
};

// Test data — L2TP Tunnel
const _l2tpResponse = <String, dynamic>{
  'Device.L2TPv2.Tunnel.1.RemoteEndpoints': 'l2tp.example.com',
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
};

// Test data — DHCPv6 client bound to the WAN interface
const _dhcpv6Response = <String, dynamic>{
  'Device.DHCPv6.Client.1.Enable': true,
  'Device.DHCPv6.Client.1.Interface': 'Device.IP.Interface.2',
  'Device.DHCPv6.Client.1.DUID': '00:01:00:01:2a:3b:4c:5d',
};

// Test data — 6rd table
const _ipv6rdResponse = <String, dynamic>{
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
  Map<String, dynamic> wanResponse = _wanResponse,
  Map<String, dynamic> pppResponse = _pppResponse,
  Map<String, dynamic> vlanResponse = _vlanResponse,
  Map<String, dynamic> ipv6rdResponse = _ipv6rdResponse,
  // Tunnel responses default to null: a tunnel GET is only expected when the
  // resolved connectionType is PPTP/L2TP (Phase-2 conditional fetch). A test
  // exercising that path passes the matching response explicitly; any other
  // tunnel GET is a regression (unconditional fetch) and fails fast below.
  Map<String, dynamic>? greResponse,
  Map<String, dynamic>? l2tpResponse,
}) {
  return (List<String> paths) {
    // Alias resolution (must be checked first)
    if (paths.any((p) => p.contains('Ethernet.Link.*.Alias'))) {
      return _ethLinkAliasResponse;
    }
    if (paths.any((p) => p.contains('IP.Interface.*.Alias'))) {
      return _ipAliasResponse;
    }
    // Tunnel fetches — fail fast if requested without an expected response, so
    // a regression re-introducing an unconditional GRE/L2TP fetch cannot pass
    // silently on empty tunnel data.
    if (paths.any((p) => p.contains('GRE.Tunnel'))) {
      return greResponse ??
          (throw StateError('Unexpected GRE.Tunnel GET: Phase-2 must only '
              'fetch the tunnel matching connectionType (paths: $paths)'));
    }
    if (paths.any((p) => p.contains('L2TPv2.Tunnel'))) {
      return l2tpResponse ??
          (throw StateError('Unexpected L2TPv2.Tunnel GET: Phase-2 must only '
              'fetch the tunnel matching connectionType (paths: $paths)'));
    }
    // Other fetches
    if (paths.any((p) => p.contains('DHCPv6.Client'))) {
      return _dhcpv6Response;
    }
    if (paths.any((p) => p.contains('IPv6rd.InterfaceSetting'))) {
      return ipv6rdResponse;
    }
    if (paths.any((p) => p.contains('AddressingType'))) {
      return wanResponse;
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

    test('maps X_LINKSYS_MTUMode=Manual to mtuAuto false', () async {
      final handler = createFetchMockHandler();
      when(() => mockUsp.get(any())).thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
        return handler(paths);
      });

      final result = await service.fetchSettings();

      expect(result.form.mtuAuto, isFalse);
      expect(result.mtuModeSupported, isTrue);
    });

    test('maps X_LINKSYS_MTUMode=Auto to mtuAuto true, keeping effective MTU',
        () async {
      final handler = createFetchMockHandler(
        wanResponse: {
          ..._wanResponse,
          'Device.IP.Interface.2.X_LINKSYS_MTUMode': 'Auto',
        },
      );
      when(() => mockUsp.get(any())).thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
        return handler(paths);
      });

      final result = await service.fetchSettings();

      expect(result.form.mtuAuto, isTrue);
      // MaxMTUSize still reports the value netifd settled on — auto mode must
      // not blank it out, the UI shows it alongside the "Auto" label.
      expect(result.form.mtu, equals(1500));
      expect(result.mtuModeSupported, isTrue);
    });

    test('absent X_LINKSYS_MTUMode fetches fine and reports unsupported',
        () async {
      // Firmware predating feed_bbf#128 omits the key. The parameter is
      // `optional: true` in the YAML precisely so this does not trip the
      // generated required-leaf check (code 9998) and blank the whole page.
      final wanWithoutMode = Map<String, dynamic>.from(_wanResponse)
        ..remove('Device.IP.Interface.2.X_LINKSYS_MTUMode');
      final handler = createFetchMockHandler(wanResponse: wanWithoutMode);
      when(() => mockUsp.get(any())).thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
        return handler(paths);
      });

      final result = await service.fetchSettings();

      expect(result.mtuModeSupported, isFalse);
      expect(result.form.mtuAuto, isFalse);
      expect(result.form.mtu, equals(1500));
    });

    test(
        'loads with no WAN IPv4Address row, as bridge mode on FW 2.0.2 (#1597)',
        () async {
      // Bridge mode runs `ifdown wan`, so the firmware drops the whole
      // IPv4Address row. The table is a list, so that is an empty list — not
      // the 9998 that used to blank the page — and Enable=false decides bridge.
      final bridged = <String, dynamic>{
        'Device.IP.Interface.2.Enable': false,
        'Device.IP.Interface.2.MaxMTUSize': '1500',
        'Device.IP.Interface.2.LowerLayers': 'Device.Ethernet.Link.2',
        'Device.IP.Interface.2.X_LINKSYS_MTUMode': 'Auto',
      };
      final handler = createFetchMockHandler(wanResponse: bridged);
      when(() => mockUsp.get(any())).thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
        return handler(paths);
      });

      final result = await service.fetchSettings();

      expect(result.form.connectionType, equals(UspWanConnectionType.bridge));
      expect(result.form.staticIpAddress, isEmpty);
      expect(result.form.dnsServer1, isEmpty);
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

    test('two VLAN terminations read as none: which is the WAN is unknown',
        () async {
      // No leaf ties the WAN to its VLAN row on 2.0.3.26102008 (it has none
      // at all), so a second row is not guessed at.
      final handler = createFetchMockHandler(vlanResponse: {
        ..._vlanResponse,
        'Device.Ethernet.VLANTermination.3.Enable': true,
        'Device.Ethernet.VLANTermination.3.VLANID': '20',
      });
      when(() => mockUsp.get(any())).thenAnswer((invocation) async =>
          handler(invocation.positionalArguments[0] as List<String>));

      final result = await service.fetchSettings();

      expect(result.vlanInstancePath, isNull);
      expect(result.form.vlanEnabled, isFalse);
    });

    // Regression: a WAN that is not PPPoE/PPTP/L2TP has zero
    // Device.PPP.Interface instances, so any concrete PPP path in the
    // WanSettings GET comes back absent and trips the generated required-leaf
    // check with fault 9998 — which took the whole Internet Settings page, and
    // PnP's saveIspSettings, straight to an error view on every DHCP router.
    // WanSettings used to declare Device.PPP.Interface.1.{Username,Password}
    // and nothing read them: the credentials the form shows come from
    // PppInterface's wildcard query, which returns {} gracefully instead. The
    // test above passed throughout only because its WAN fixture supplied the
    // two keys the real router does not have, so assert on the request itself.
    test('the WAN GET requests no Device.PPP paths', () async {
      final handler = createFetchMockHandler(pppResponse: _pppEmptyResponse);
      final captured = <List<String>>[];
      when(() => mockUsp.get(any())).thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
        captured.add(paths);
        return handler(paths);
      });

      await service.fetchSettings();

      final wanQuery = captured
          .firstWhere((paths) => paths.any((p) => p.endsWith('MaxMTUSize')));
      expect(wanQuery.where((p) => p.startsWith('Device.PPP.')), isEmpty);
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
        // This test's PPP instance is empty → connectionType is not PPTP/L2TP,
        // so Phase-2 fetches no tunnel. A tunnel GET here is a regression.
        if (paths.any((p) => p.contains('GRE.Tunnel'))) {
          throw StateError('Unexpected GRE.Tunnel GET in DNS-split test');
        }
        if (paths.any((p) => p.contains('L2TPv2.Tunnel'))) {
          throw StateError('Unexpected L2TPv2.Tunnel GET in DNS-split test');
        }
        if (paths.any((p) => p.contains('DHCPv6.Client'))) {
          return _dhcpv6Response;
        }
        if (paths.any((p) => p.contains('IPv6rd.InterfaceSetting'))) {
          return _ipv6rdResponse;
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
    setUp(() {
      // Default GET: alias resolution for codegen _resolveInstance(), the WAN
      // row whose instancePath an IPv4 write targets, the DHCPv6 client, and
      // the one GRE and one L2TPv2 row a PPTP / L2TP save reads before it
      // writes (the bench's shape on 2.0.3.26102008: one row each, no server,
      // a DHCP underlay).
      final handler = createFetchMockHandler(
        greResponse: const {
          'Device.GRE.Tunnel.1.RemoteEndpoints': '',
          'Device.GRE.Tunnel.1.X_LINKSYS_UnderlayAddressingType': 'DHCP',
          'Device.GRE.Tunnel.1.Interface.1.Alias': 'cpe-1',
        },
        l2tpResponse: const {
          'Device.L2TPv2.Tunnel.1.RemoteEndpoints': '',
          'Device.L2TPv2.Tunnel.1.X_LINKSYS_UnderlayAddressingType': 'DHCP',
          'Device.L2TPv2.Tunnel.1.Interface.1.Alias': '',
        },
      );
      when(() => mockUsp.get(any())).thenAnswer((invocation) async =>
          handler(invocation.positionalArguments[0] as List<String>));
      when(() => mockUsp
              .setOrdered(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {
                'success': true,
                'result': {'data': <String, dynamic>{}}
              });
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

      final captured = verify(() => mockUsp.setOrdered(captureAny(),
          allowPartial: any(named: 'allowPartial'))).captured;
      final groups = captured.single as List<List<Map<String, String>>>;
      final dns = groups.expand((g) => g).singleWhere((p) =>
          p['path'] ==
          'Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DNSServers');
      expect(dns['value'], equals('1.1.1.1,9.9.9.9'));
    });

    test('a DHCPv6 change with no client on the WAN is refused, nothing sent',
        () async {
      // The only DHCPv6 client is bound to the LAN, so the change has nowhere
      // to go. It must not be dropped and reported as saved.
      final handler = createFetchMockHandler();
      when(() => mockUsp.get(any())).thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
        if (paths.any((p) => p.contains('DHCPv6.Client'))) {
          return {
            'Device.DHCPv6.Client.1.Enable': true,
            'Device.DHCPv6.Client.1.Interface': 'Device.IP.Interface.1',
            'Device.DHCPv6.Client.1.DUID': '',
          };
        }
        return handler(paths);
      });
      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
        dhcpv6Enabled: true,
        ipv6Enabled: true,
      );
      final edited =
          original.copyWith(dhcpv6Enabled: false, ipv6Enabled: false);

      await expectLater(
        service.saveAll(original, edited),
        throwsA(isA<ResourceNotFoundError>()),
      );
      verifyNever(
          () => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')));
    });

    test('IPv6, DHCPv6 and 6rd changes go out as one SET', () async {
      // Three generated models, one SET built from their write builders.
      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
        ipv6Enabled: true,
        dhcpv6Enabled: true,
      );
      final edited = original.copyWith(
        ipv6Enabled: false,
        dhcpv6Enabled: false,
        ipv6rdEnabled: true,
      );

      await service.saveAll(original, edited);

      final captured = verify(
        () =>
            mockUsp.set(captureAny(), allowPartial: any(named: 'allowPartial')),
      ).captured;
      final ipv6Sets = captured.whereType<Map<String, dynamic>>().where((m) =>
          m.keys.any((k) =>
              k.endsWith('IPv6Enable') ||
              k.startsWith('Device.DHCPv6.Client.') ||
              k.startsWith('Device.IPv6rd.')));
      expect(ipv6Sets, [
        {
          'Device.IP.Interface.2.IPv6Enable': false,
          'Device.DHCPv6.Client.1.Enable': false,
          'Device.IPv6rd.InterfaceSetting.1.Enable': true,
        }
      ]);
    });

    test('an unchanged IPv6 section sends no IPv6 SET', () async {
      final form = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
        ipv6Enabled: true,
        dhcpv6Enabled: true,
      );

      await service.saveAll(form, form.copyWith(mtu: form.mtu + 1));

      final captured = verify(
        () =>
            mockUsp.set(captureAny(), allowPartial: any(named: 'allowPartial')),
      ).captured;
      for (final params in captured.whereType<Map<String, dynamic>>()) {
        expect(
            params.keys.any((k) =>
                k.endsWith('IPv6Enable') ||
                k.startsWith('Device.DHCPv6.') ||
                k.startsWith('Device.IPv6rd.')),
            isFalse);
      }
    });

    test('IPv6 save uses allowPartial (cross-USP-service SET cannot be atomic)',
        () async {
      // IPv6 settings span IP.Interface, DHCPv6.Client and IPv6rd.Interface-
      // Setting. The OBUSPA broker rejects an atomic SET (allow_partial=false)
      // touching more than one service with 7005, failing the whole save.
      // Regression guard for that: the IPv6 SET must be sent with allowPartial.
      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
        ipv6Enabled: true,
        dhcpv6Enabled: true,
      );
      final edited = original.copyWith(
        ipv6Enabled: false,
        dhcpv6Enabled: false,
      );

      await service.saveAll(original, edited);

      // Every SET carrying IPv6/DHCPv6 params must pass allowPartial: true
      // (not the default false that triggers 7005). IPv6Enable and the DHCPv6
      // client are separate generated models, so each one is checked.
      final captured = verify(
        () => mockUsp.set(
          captureAny(),
          allowPartial: captureAny(named: 'allowPartial'),
        ),
      ).captured;
      final seen = <String>{};
      for (var i = 0; i < captured.length; i += 2) {
        final params = captured[i] as Map<String, dynamic>;
        final allowPartial = captured[i + 1] as bool;
        for (final key in params.keys) {
          if (key.endsWith('IPv6Enable')) seen.add('IPv6Enable');
          if (key.startsWith('Device.DHCPv6.Client.')) seen.add('DHCPv6');
        }
        if (params.keys
            .any((k) => k.contains('IPv6') || k.contains('DHCPv6'))) {
          expect(allowPartial, isTrue,
              reason: 'IPv6 SET must use allowPartial to avoid 7005');
        }
      }
      expect(seen, {'IPv6Enable', 'DHCPv6'},
          reason: 'both the IPv6Enable and the DHCPv6 SET should be issued');
      // The DHCPv6 write targets the client bound to the WAN interface.
      final dhcpv6 = captured
          .whereType<Map<String, dynamic>>()
          .firstWhere((m) => m.containsKey('Device.DHCPv6.Client.1.Enable'));
      expect(dhcpv6['Device.DHCPv6.Client.1.Enable'], isFalse);
    });

    test('adds PPP instance when switching to PPPoE without existing instance',
        () async {
      when(() => mockUsp.add(any())).thenAnswer((_) async => {
            'success': true,
            'result': {
              'data': {
                'instances': ['Device.PPP.Interface.1.'],
              },
            },
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
      // The link is written on the instance the Add created.
      final captured = verify(
        () =>
            mockUsp.set(captureAny(), allowPartial: any(named: 'allowPartial')),
      ).captured;
      expect(
        captured.whereType<Map<String, dynamic>>(),
        contains(equals({
          'Device.PPP.Interface.1.LowerLayers': '',
          'Device.PPP.Interface.1.Username': 'user',
          'Device.PPP.Interface.1.Password': 'pass',
        })),
      );
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

      final captured = verify(() => mockUsp.setOrdered(captureAny(),
          allowPartial: any(named: 'allowPartial'))).captured;
      final groups = captured.single as List<List<Map<String, String>>>;
      expect(groups, [
        [
          {
            'path': 'Device.IP.Interface.2.IPv4Address.1.AddressingType',
            'value': 'DHCP',
          }
        ]
      ]);
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

    test(
        'switching to PPPoE sends IPCP alone, then LowerLayers "" with the '
        'credentials in one PPP batch', () async {
      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
      );
      final edited = original.copyWith(
        connectionType: UspWanConnectionType.pppoe,
        pppUsername: 'myuser',
        pppPassword: 'mypass',
      );

      await service.saveAll(
        original,
        edited,
        pppInstancePath: 'Device.PPP.Interface.1.',
      );

      // SET 1 (#762 comment 5987286082): AddressingType alone.
      final ordered = verify(() => mockUsp.setOrdered(captureAny(),
          allowPartial: any(named: 'allowPartial'))).captured;
      expect(ordered.single, [
        [
          {
            'path': 'Device.IP.Interface.2.IPv4Address.1.AddressingType',
            'value': 'IPCP',
          }
        ]
      ]);

      // SET 2: LowerLayers cleared, plus the credentials, as one PPP batch.
      final captured = verify(
        () =>
            mockUsp.set(captureAny(), allowPartial: any(named: 'allowPartial')),
      ).captured;
      final pppSets = captured
          .whereType<Map<String, dynamic>>()
          .where((m) => m.keys.any((k) => k.startsWith('Device.PPP.')))
          .toList();
      expect(pppSets.first, {
        'Device.PPP.Interface.1.LowerLayers': '',
        'Device.PPP.Interface.1.Username': 'myuser',
        'Device.PPP.Interface.1.Password': 'mypass',
      });
    });

    test('switching to Bridge sends only Enable=false', () async {
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
      final bridgeParams = captured
          .whereType<Map<String, dynamic>>()
          .where((m) => m.containsKey('Device.IP.Interface.2.Enable'));
      expect(bridgeParams.length, equals(1));
      expect(bridgeParams.first['Device.IP.Interface.2.Enable'], isFalse);
      expect(bridgeParams.first.length, equals(1));
      // AddressingType is no longer part of entering bridge at all.
      verifyNever(() =>
          mockUsp.setOrdered(any(), allowPartial: any(named: 'allowPartial')));
    });

    test('switching to Bridge sends neither MaxMTUSize nor X_LINKSYS_MTUMode',
        () async {
      // MTU has no meaning once the WAN port joins br-lan, and the bridge SET is
      // terminal (the transport drops mid-request), so an extra MTU SET would
      // only add a way for saveAll to abort before the bridge SET goes out.
      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
        mtu: 1500,
      );
      final edited = original.copyWith(
        connectionType: UspWanConnectionType.bridge,
        mtuAuto: true,
      );

      await service.saveAll(original, edited);

      final captured = verify(
        () =>
            mockUsp.set(captureAny(), allowPartial: any(named: 'allowPartial')),
      ).captured;
      for (final params in captured.whereType<Map<String, dynamic>>()) {
        expect(params.containsKey('Device.IP.Interface.2.MaxMTUSize'), isFalse,
            reason: 'bridge mode must not push MaxMTUSize');
        expect(params.containsKey('Device.IP.Interface.2.X_LINKSYS_MTUMode'),
            isFalse,
            reason: 'bridge mode must not push X_LINKSYS_MTUMode');
      }
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
        // then<void>, not bare then: without the type argument R infers to bool
        // from `done = true`, which then requires onError to return bool too.
        // It returns Object, and Future rejects that at RUNTIME with
        // "ArgumentError: The error handler of Future.then must return a value
        // of the returned future's type" — an uncaught async error, not this
        // test's assertion. Dart 3.13 reports it as invalid_return_type_for_then.
        service.saveAll(original, edited).then<void>(
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
                    'Device.IP.Interface.2.Enable': {
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
      final bridgeIndex = captureOrder
          .indexWhere((m) => m.containsKey('Device.IP.Interface.2.Enable'));

      expect(ipv6Index, greaterThanOrEqualTo(0),
          reason: 'IPv6 change should have produced a SET');
      expect(bridgeIndex, greaterThanOrEqualTo(0),
          reason: 'bridge switch should have produced a SET');
      expect(bridgeIndex, greaterThan(ipv6Index),
          reason: 'bridge SET must be sent after the IPv6 SET');
    });

    /// Every write saveAll sends, in order: a `set` map, or the flat
    /// `{path: value}` of a `setOrdered`'s groups.
    List<Map<String, dynamic>> recordWrites() {
      final writes = <Map<String, dynamic>>[];
      Map<String, dynamic> ok() => {
            'success': true,
            'result': {'data': <String, dynamic>{}}
          };
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((invocation) async {
        writes.add(invocation.positionalArguments[0] as Map<String, dynamic>);
        return ok();
      });
      when(() => mockUsp.setOrdered(any(),
              allowPartial: any(named: 'allowPartial')))
          .thenAnswer((invocation) async {
        final groups = invocation.positionalArguments[0]
            as List<List<Map<String, String>>>;
        writes.add({
          for (final p in groups.expand((g) => g)) p['path']!: p['value'],
        });
        return ok();
      });
      return writes;
    }

    test('leaving bridge into Static writes the target mode, then Enable=true',
        () async {
      // The WAN IPv4Address row stays while bridged (FW 2.0.3) and the exit
      // script never touches network.wan, so the mode written here is the one
      // the WAN comes back in.
      final writes = recordWrites();
      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.bridge,
      );
      final edited = original.copyWith(
        connectionType: UspWanConnectionType.staticIp,
        staticIpAddress: '10.0.0.1',
        subnetMask: '255.255.255.0',
        defaultGateway: '10.0.0.254',
        dnsServer1: '8.8.8.8',
      );

      await service.saveAll(original, edited);

      expect(writes.first, {
        'Device.IP.Interface.2.IPv4Address.1.AddressingType': 'Static',
        'Device.IP.Interface.2.IPv4Address.1.IPAddress': '10.0.0.1',
        'Device.IP.Interface.2.IPv4Address.1.SubnetMask': '255.255.255.0',
        'Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DefaultGateway':
            '10.0.0.254',
        'Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DNSServers': '8.8.8.8',
      });
      expect(writes.last, {'Device.IP.Interface.2.Enable': true});
    });

    test('leaving bridge into PPPoE writes the PPP link before Enable=true',
        () async {
      final writes = recordWrites();
      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.bridge,
      );
      final edited = original.copyWith(
        connectionType: UspWanConnectionType.pppoe,
        pppUsername: 'user',
        pppPassword: 'pass',
      );

      await service.saveAll(
        original,
        edited,
        pppInstancePath: 'Device.PPP.Interface.1.',
      );

      expect(writes, [
        {'Device.IP.Interface.2.IPv4Address.1.AddressingType': 'IPCP'},
        {
          'Device.PPP.Interface.1.LowerLayers': '',
          'Device.PPP.Interface.1.Username': 'user',
          'Device.PPP.Interface.1.Password': 'pass',
        },
        // Keep Alive, the form's default, resent with the PPP link.
        {
          'Device.PPP.Interface.1.LCPEcho': 30,
          'Device.PPP.Interface.1.LCPEchoRetry': 5,
          'Device.PPP.Interface.1.LCPEchoAdaptive': false,
        },
        {'Device.IP.Interface.2.Enable': true},
      ]);
    });

    for (final (type, lowerLayers, tunnel) in [
      (
        UspWanConnectionType.pptp,
        'Device.GRE.Tunnel.1.Interface.1',
        'Device.GRE.Tunnel.1.RemoteEndpoints',
      ),
      (
        UspWanConnectionType.l2tp,
        'Device.L2TPv2.Tunnel.1.Interface.1',
        'Device.L2TPv2.Tunnel.1.RemoteEndpoints',
      ),
    ]) {
      test(
          'leaving bridge into ${type.name} writes the tunnel before Enable=true',
          () async {
        final writes = recordWrites();
        final original = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.bridge,
        );
        final edited = original.copyWith(
          connectionType: type,
          pppUsername: 'user',
          pppPassword: 'pass',
          serverAddress: '203.0.113.10',
        );

        await service.saveAll(
          original,
          edited,
          pppInstancePath: 'Device.PPP.Interface.1.',
        );

        final tunnelAt = writes.indexWhere((m) => m.containsKey(tunnel));
        final linkAt = writes.indexWhere(
            (m) => m['Device.PPP.Interface.1.LowerLayers'] == lowerLayers);
        expect(linkAt, greaterThanOrEqualTo(0));
        expect(writes[tunnelAt][tunnel], '203.0.113.10');
        expect(writes.last, {'Device.IP.Interface.2.Enable': true});
        expect(writes.length - 1, greaterThan(tunnelAt),
            reason: 'Enable=true must follow the tunnel write');
      });
    }

    test('leaving bridge sends Enable=true as the very last write', () async {
      // Whatever the target mode and whatever else changed, the boundary SET
      // drops the connection, so nothing may be sent after it.
      final writes = recordWrites();
      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.bridge,
        ipv6Enabled: true,
        vlanEnabled: false,
      );
      final edited = original.copyWith(
        connectionType: UspWanConnectionType.dhcp,
        ipv6Enabled: false,
        vlanEnabled: true,
        vlanId: 10,
      );

      await service.saveAll(
        original,
        edited,
        vlanInstancePath: 'Device.Ethernet.VLANTermination.1.',
      );

      expect(writes.where((m) => m.containsKey('Device.IP.Interface.2.Enable')),
          hasLength(1));
      expect(writes.last, {'Device.IP.Interface.2.Enable': true});
    });

    test('leaving bridge sends Enable=true after the IPv6 SET', () async {
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
        connectionType: UspWanConnectionType.bridge,
        ipv6Enabled: true,
      );
      final edited = original.copyWith(
        connectionType: UspWanConnectionType.dhcp,
        ipv6Enabled: false,
      );

      await service.saveAll(original, edited);

      final ipv6Index =
          captureOrder.indexWhere((m) => m.keys.any((k) => k.contains('IPv6')));
      final exitIndex = captureOrder
          .indexWhere((m) => m.containsKey('Device.IP.Interface.2.Enable'));
      expect(ipv6Index, greaterThanOrEqualTo(0));
      expect(captureOrder[exitIndex]['Device.IP.Interface.2.Enable'], isTrue);
      expect(exitIndex, greaterThan(ipv6Index),
          reason: 'Enable=true must be the last SET');
    });

    test('leaving bridge treats a transport error on the exit SET as success',
        () async {
      // Same disconnect signature as entering: the exit script bounces the
      // ports and restarts lighttpd, so the response never arrives.
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenThrow('Set failed: Transport error: Request timeout');

      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.bridge,
      );
      final edited = original.copyWith(
        connectionType: UspWanConnectionType.dhcp,
      );

      await expectLater(service.saveAll(original, edited), completes);
    });

    test('leaving bridge rethrows a real fault on the exit SET', () async {
      // A fault code on Enable means the router rejected the exit before any
      // disconnect — a genuine failure the user must see.
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {
                'success': false,
                'result': {
                  'data': <String, dynamic>{},
                  'error': {
                    'Device.IP.Interface.2.Enable': {
                      'errorCode': 7006,
                      'errorMessage': 'Invalid value',
                    },
                  },
                },
              });

      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.bridge,
      );
      final edited = original.copyWith(
        connectionType: UspWanConnectionType.dhcp,
      );

      await expectLater(
        service.saveAll(original, edited),
        throwsA(isA<ServiceError>()),
      );
    });

    test('editing while staying in bridge crosses no boundary', () async {
      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.bridge,
        ipv6Enabled: true,
      );
      final edited = original.copyWith(ipv6Enabled: false);

      await service.saveAll(original, edited);

      final captured = verify(
        () =>
            mockUsp.set(captureAny(), allowPartial: any(named: 'allowPartial')),
      ).captured;
      for (final params in captured.whereType<Map<String, dynamic>>()) {
        expect(params.containsKey('Device.IP.Interface.2.Enable'), isFalse,
            reason: 'no type change means no boundary SET');
      }
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

    test('switching Manual to Auto sends only X_LINKSYS_MTUMode=Auto',
        () async {
      // MaxMTUSize must not ride along: 0 is outside the TR-181 range
      // 64..65535 and the firmware rejects it with fault 9007, and any other
      // number would immediately put UCI back into Manual (Architecture#122).
      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
        mtu: 1500,
      );
      final edited = original.copyWith(mtuAuto: true);

      await service.saveAll(original, edited);

      final captured = verify(
        () =>
            mockUsp.set(captureAny(), allowPartial: any(named: 'allowPartial')),
      ).captured;
      final params = captured.whereType<Map<String, dynamic>>().where(
          (m) => m.containsKey('Device.IP.Interface.2.X_LINKSYS_MTUMode'));
      expect(params.length, equals(1));
      expect(
        params.first['Device.IP.Interface.2.X_LINKSYS_MTUMode'],
        equals('Auto'),
      );
      expect(params.first.length, equals(1),
          reason: 'auto mode must not push MaxMTUSize alongside the mode');
    });

    test('leaving Auto writes MaxMTUSize even when the number is unchanged',
        () async {
      // Regression guard: a plain original-vs-edited diff on mtu returns null
      // here (1500 both sides), so a diff-only save would send nothing and the
      // device would silently stay in Auto. Writing MaxMTUSize is what puts UCI
      // back into Manual, so it must be forced when leaving auto.
      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
        mtu: 1500,
        mtuAuto: true,
      );
      final edited = original.copyWith(mtuAuto: false);

      await service.saveAll(original, edited);

      final captured = verify(
        () =>
            mockUsp.set(captureAny(), allowPartial: any(named: 'allowPartial')),
      ).captured;
      final params = captured
          .whereType<Map<String, dynamic>>()
          .where((m) => m.containsKey('Device.IP.Interface.2.MaxMTUSize'));
      expect(params.length, equals(1));
      expect(
        params.first['Device.IP.Interface.2.MaxMTUSize'],
        equals(1500),
      );
      // 'Manual' is a firmware no-op, so it is never sent.
      expect(params.first.length, equals(1));
    });

    test('MTU change in Manual mode never sends X_LINKSYS_MTUMode', () async {
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
      for (final params in captured.whereType<Map<String, dynamic>>()) {
        expect(params.containsKey('Device.IP.Interface.2.X_LINKSYS_MTUMode'),
            isFalse,
            reason: 'writing MaxMTUSize is what selects Manual on the device');
      }
    });

    test('staying in Auto with no change sends no MTU params at all', () async {
      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
        mtu: 1500,
        mtuAuto: true,
      );

      await service.saveAll(original, original);

      // Nothing changed anywhere in the form, so saveAll issues no SET at all.
      verifyNever(
        () => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')),
      );
    });

    test('switching to PPTP sets LowerLayers, RemoteEndpoints, and IPCP',
        () async {
      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
      );
      final edited = original.copyWith(
        connectionType: UspWanConnectionType.pptp,
        serverAddress: '203.0.113.10',
        pppUsername: 'vpnuser',
        pppPassword: 'vpnpass',
      );

      await service.saveAll(
        original,
        edited,
        pppInstancePath: 'Device.PPP.Interface.1.',
      );

      final captured = verify(
        () =>
            mockUsp.set(captureAny(), allowPartial: any(named: 'allowPartial')),
      ).captured;
      final allParams = captured.whereType<Map<String, dynamic>>().toList();

      // Verify LowerLayers was set to GRE
      final lowerLayersSet = allParams
          .where((m) => m.containsKey('Device.PPP.Interface.1.LowerLayers'));
      expect(lowerLayersSet, isNotEmpty);
      expect(lowerLayersSet.first['Device.PPP.Interface.1.LowerLayers'],
          equals('Device.GRE.Tunnel.1.Interface.1'));

      // AddressingType=IPCP first, then RemoteEndpoints on the tunnel row
      final ordered = verify(() => mockUsp.setOrdered(captureAny(),
          allowPartial: any(named: 'allowPartial'))).captured;
      expect(ordered, [
        [
          [
            {
              'path': 'Device.IP.Interface.2.IPv4Address.1.AddressingType',
              'value': 'IPCP',
            }
          ]
        ],
        [
          [
            {
              'path': 'Device.GRE.Tunnel.1.RemoteEndpoints',
              'value': '203.0.113.10',
            }
          ]
        ],
      ]);

      // LowerLayers and the credentials share one PPP batch.
      expect(lowerLayersSet.first['Device.PPP.Interface.1.Username'],
          equals('vpnuser'));
      expect(lowerLayersSet.first['Device.PPP.Interface.1.Password'],
          equals('vpnpass'));
    });

    test('switching to L2TP sets LowerLayers to L2TPv2', () async {
      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
      );
      final edited = original.copyWith(
        connectionType: UspWanConnectionType.l2tp,
        serverAddress: '203.0.113.20',
        pppUsername: 'l2tpuser',
        pppPassword: 'l2tppass',
      );

      await service.saveAll(
        original,
        edited,
        pppInstancePath: 'Device.PPP.Interface.1.',
      );

      final captured = verify(
        () =>
            mockUsp.set(captureAny(), allowPartial: any(named: 'allowPartial')),
      ).captured;
      final allParams = captured.whereType<Map<String, dynamic>>().toList();

      // Verify LowerLayers was set to L2TPv2
      final lowerLayersSet = allParams
          .where((m) => m.containsKey('Device.PPP.Interface.1.LowerLayers'));
      expect(lowerLayersSet, isNotEmpty);
      expect(lowerLayersSet.first['Device.PPP.Interface.1.LowerLayers'],
          equals('Device.L2TPv2.Tunnel.1.Interface.1'));

      // L2TP RemoteEndpoints on the tunnel row, after AddressingType=IPCP
      final ordered = verify(() => mockUsp.setOrdered(captureAny(),
          allowPartial: any(named: 'allowPartial'))).captured;
      expect(ordered.last, [
        [
          {
            'path': 'Device.L2TPv2.Tunnel.1.RemoteEndpoints',
            'value': '203.0.113.20',
          }
        ]
      ]);
    });

    test('fetch detects PPTP from lowerLayers containing GRE.Tunnel', () async {
      final wanIpcp = Map<String, dynamic>.from(_wanResponse);
      wanIpcp['Device.IP.Interface.2.IPv4Address.1.AddressingType'] = 'IPCP';

      // Only GRE is expected; leaving l2tpResponse null asserts (via the
      // handler's fail-fast) that a PPTP connection never fetches L2TP.
      final handler = createFetchMockHandler(
        wanResponse: wanIpcp,
        pppResponse: _pppPptpResponse,
        greResponse: _greResponse,
      );
      when(() => mockUsp.get(any())).thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
        return handler(paths);
      });

      final result = await service.fetchSettings();

      expect(result.form.connectionType, equals(UspWanConnectionType.pptp));
      expect(result.form.serverAddress, equals('pptp.example.com'));
      expect(result.form.pppUsername, equals('vpnuser'));
    });

    test('fetch detects L2TP from lowerLayers containing L2TPv2.Tunnel',
        () async {
      final wanIpcp = Map<String, dynamic>.from(_wanResponse);
      wanIpcp['Device.IP.Interface.2.IPv4Address.1.AddressingType'] = 'IPCP';

      // Only L2TP is expected; leaving greResponse null asserts (via the
      // handler's fail-fast) that an L2TP connection never fetches GRE.
      final handler = createFetchMockHandler(
        wanResponse: wanIpcp,
        pppResponse: _pppL2tpResponse,
        l2tpResponse: _l2tpResponse,
      );
      when(() => mockUsp.get(any())).thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
        return handler(paths);
      });

      final result = await service.fetchSettings();

      expect(result.form.connectionType, equals(UspWanConnectionType.l2tp));
      expect(result.form.serverAddress, equals('l2tp.example.com'));
      expect(result.form.pppUsername, equals('l2tpuser'));
    });

    test(
        'DHCP WAN fetch issues NO GRE/L2TP tunnel GET (#1184 regression guard)',
        () async {
      // The load-bearing regression this PR fixes. GreTunnel/L2tpTunnel are
      // generated with concrete paths (Device.GRE.Tunnel.1.*), so — now that
      // #1198 removed _rawGet's null back-fill — fetching them on a DHCP WAN
      // (zero tunnel instances) fires the codegen required-leaf check (9998).
      // Phase-2 must fetch ONLY the tunnel the connectionType uses; a DHCP WAN
      // must fetch none. If someone reverts the conditional fetch to an
      // unconditional one, a tunnel path appears here and this fails.
      final handler = createFetchMockHandler(); // default DHCP WAN
      when(() => mockUsp.get(any())).thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
        return handler(paths);
      });

      final result = await service.fetchSettings();
      expect(result.form.connectionType, equals(UspWanConnectionType.dhcp));

      // Directly assert intent (not just the handler's fail-fast): no GET this
      // fetch issued touched a GRE or L2TPv2 tunnel path.
      final allRequestedPaths = verify(() => mockUsp.get(captureAny()))
          .captured
          .cast<List<String>>()
          .expand((paths) => paths)
          .toList();
      expect(
        allRequestedPaths,
        isNot(contains(contains('GRE.Tunnel'))),
        reason: 'DHCP WAN must not fetch the GRE tunnel',
      );
      expect(
        allRequestedPaths,
        isNot(contains(contains('L2TPv2.Tunnel'))),
        reason: 'DHCP WAN must not fetch the L2TPv2 tunnel',
      );
    });

    test('PPTP WAN with absent GRE Tunnel.1 row reads an empty server address',
        () async {
      // GreTunnels is a table, so a PPTP WAN whose Tunnel.1 row is absent is
      // an empty list rather than a 9998 that blanks the whole page. The empty
      // server address fails form validation, prompting the user to re-enter.
      final wanIpcp = Map<String, dynamic>.from(_wanResponse);
      wanIpcp['Device.IP.Interface.2.IPv4Address.1.AddressingType'] = 'IPCP';

      final handler = createFetchMockHandler(
        wanResponse: wanIpcp,
        pppResponse: _pppPptpResponse,
        greResponse: const {}, // Tunnel.1 row absent
      );
      when(() => mockUsp.get(any())).thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
        return handler(paths);
      });

      final result = await service.fetchSettings();

      expect(result.form.connectionType, equals(UspWanConnectionType.pptp));
      expect(result.form.serverAddress, isEmpty);
    });
  });

  group('UspInternetSettingsService — PPP connection mode', () {
    // A PPPoE WAN on firmware with linksys/feed_usp#68: LCPEchoAdaptive is
    // served, so LCPEcho holds the Keep Alive interval and is writable.
    Map<String, dynamic> ppp({
      String trigger = 'AlwaysOn',
      String idleSeconds = '0',
      String lcpEcho = '45',
      String lcpEchoRetry = '5',
      bool? adaptive = false,
    }) =>
        {
          ..._pppResponse,
          'Device.PPP.Interface.1.ConnectionTrigger': trigger,
          'Device.PPP.Interface.1.IdleDisconnectTime': idleSeconds,
          'Device.PPP.Interface.1.LCPEcho': lcpEcho,
          'Device.PPP.Interface.1.LCPEchoRetry': lcpEchoRetry,
          if (adaptive != null)
            'Device.PPP.Interface.1.LCPEchoAdaptive': adaptive,
        };
    Future<InternetSettingsFetchResult> fetchWith(
        Map<String, dynamic> pppResponse) {
      final handler = createFetchMockHandler(
          wanResponse: _wanIpcp(), pppResponse: pppResponse);
      when(() => mockUsp.get(any())).thenAnswer((invocation) async =>
          handler(invocation.positionalArguments[0] as List<String>));
      return service.fetchSettings();
    }

    group('fetch', () {
      test('reads the idle time in minutes', () async {
        final result =
            await fetchWith(ppp(trigger: 'OnDemand', idleSeconds: '900'));
        expect(result.form.idleDisconnectTime, 15);
      });

      test('rounds a partial minute up, so On Demand never reads 0', () async {
        final result =
            await fetchWith(ppp(trigger: 'OnDemand', idleSeconds: '30'));
        expect(result.form.idleDisconnectTime, 1);
      });

      test('reads the Keep Alive interval', () async {
        final result = await fetchWith(ppp(lcpEcho: '45'));
        expect(result.form.lcpEchoInterval, 45);
      });

      test('shows 30 for an out-of-range interval (1.0 default)', () async {
        expect((await fetchWith(ppp(lcpEcho: '1'))).form.lcpEchoInterval, 30);
        expect((await fetchWith(ppp(lcpEcho: '600'))).form.lcpEchoInterval, 30);
      });
    });

    group('save', () {
      const pppPath = 'Device.PPP.Interface.1.';
      const keepAlive = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.pppoe,
        pppUsername: 'user',
        pppPassword: 'pass',
        connectionTrigger: 'AlwaysOn',
        lcpEchoInterval: 30,
        mtu: 1492,
      );
      final onDemand = keepAlive.copyWith(
          connectionTrigger: 'OnDemand', idleDisconnectTime: 15);

      setUp(() {
        final handler = createFetchMockHandler(wanResponse: _wanIpcp());
        when(() => mockUsp.get(any())).thenAnswer((invocation) async =>
            handler(invocation.positionalArguments[0] as List<String>));
        when(() => mockUsp
                .setOrdered(any(), allowPartial: any(named: 'allowPartial')))
            .thenAnswer((_) async => {
                  'success': true,
                  'result': {'data': <String, dynamic>{}}
                });
        when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
            .thenAnswer((_) async => {
                  'success': true,
                  'result': {'data': <String, dynamic>{}}
                });
      });

      /// Every PPP leaf the save wrote, merged across its Sets.
      Map<String, dynamic> pppWrites() {
        final writes = <String, dynamic>{};
        for (final call in verify(() => mockUsp.set(captureAny(),
                allowPartial: any(named: 'allowPartial')))
            .captured
            .whereType<Map<String, dynamic>>()) {
          writes.addAll({
            for (final e in call.entries)
              if (e.key.startsWith(pppPath))
                e.key.substring(pppPath.length): e.value,
          });
        }
        return writes;
      }

      Future<void> save(UspInternetSettingsForm original,
              UspInternetSettingsForm edited) =>
          service.saveAll(original, edited, pppInstancePath: pppPath);

      test('Keep Alive to On Demand sends the idle time in seconds', () async {
        await save(keepAlive, onDemand);
        expect(pppWrites(), {
          'ConnectionTrigger': 'OnDemand',
          'IdleDisconnectTime': 900,
        });
      });

      test('an idle time change alone is sent in seconds', () async {
        await save(onDemand, onDemand.copyWith(idleDisconnectTime: 20));
        expect(pppWrites(), {'IdleDisconnectTime': 1200});
      });

      test(
          'On Demand to Keep Alive sends the three LCP echo leaves and no '
          'idle time', () async {
        // netmngr 050: a later IdleDisconnectTime in the same save would turn
        // On Demand back on. feed_usp#68: 1.0's KeepAlive is LCPEcho N,
        // LCPEchoRetry 5, LCPEchoAdaptive false, in one Set.
        await save(onDemand, keepAlive.copyWith(lcpEchoInterval: 60));
        expect(pppWrites(), {
          'ConnectionTrigger': 'AlwaysOn',
          'LCPEcho': 60,
          'LCPEchoRetry': 5,
          'LCPEchoAdaptive': false,
        });
      });

      test('an interval change alone sends the three LCP echo leaves',
          () async {
        await save(keepAlive, keepAlive.copyWith(lcpEchoInterval: 90));
        expect(pppWrites(), {
          'LCPEcho': 90,
          'LCPEchoRetry': 5,
          'LCPEchoAdaptive': false,
        });
      });

      test('a Keep Alive save that touches the PPP link resends the interval',
          () async {
        // "Sent on every KeepAlive save" (FWDEV#212).
        await save(keepAlive, keepAlive.copyWith(pppPassword: 'new'));
        expect(pppWrites(), {
          'Password': 'new',
          'LCPEcho': 30,
          'LCPEchoRetry': 5,
          'LCPEchoAdaptive': false,
        });
      });

      test(
          'every Keep Alive save sends the interval, even one that changes '
          'no PPP field', () async {
        // "sent on every KeepAlive save" (FWDEV#212): a router holding an
        // out-of-range LCPEcho reads as 30, and only a write makes it so.
        await save(keepAlive, keepAlive.copyWith(mtu: 1400));
        expect(pppWrites(), {
          'LCPEcho': 30,
          'LCPEchoRetry': 5,
          'LCPEchoAdaptive': false,
        });
      });

      test('an On Demand save that changes no PPP field writes none', () async {
        await save(onDemand, onDemand.copyWith(mtu: 1400));
        expect(pppWrites(), isEmpty);
      });
    });
  });

  group('UspInternetSettingsService — 6rd row', () {
    // Rows 3 and 5: the first row is not row 1, so a write naming .1 fails.
    const ipv6rd = <String, dynamic>{
      'Device.IPv6rd.InterfaceSetting.3.Enable': true,
      'Device.IPv6rd.InterfaceSetting.3.SPIPv6Prefix': '2001:db8::/32',
      'Device.IPv6rd.InterfaceSetting.3.IPv4MaskLength': '8',
      'Device.IPv6rd.InterfaceSetting.3.BorderRelayIPv4Addresses': '192.0.2.1',
      'Device.IPv6rd.InterfaceSetting.5.Enable': false,
      'Device.IPv6rd.InterfaceSetting.5.SPIPv6Prefix': '',
      'Device.IPv6rd.InterfaceSetting.5.IPv4MaskLength': '0',
      'Device.IPv6rd.InterfaceSetting.5.BorderRelayIPv4Addresses': '',
    };
    void answer(Map<String, dynamic> response) {
      final handler = createFetchMockHandler(ipv6rdResponse: response);
      when(() => mockUsp.get(any())).thenAnswer((invocation) async =>
          handler(invocation.positionalArguments[0] as List<String>));
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {
                'success': true,
                'result': {'data': <String, dynamic>{}}
              });
    }

    test('reads the first row the table lists', () async {
      answer(ipv6rd);
      final form = (await service.fetchSettings()).form;
      expect(form.ipv6rdEnabled, isTrue);
      expect(form.ipv6rdPrefix, '2001:db8::/32');
      expect(form.ipv6rdBorderRelay, '192.0.2.1');
    });

    test('writes the first row the table lists', () async {
      answer(ipv6rd);
      const original = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp, ipv6rdEnabled: true);
      await service.saveAll(
          original, original.copyWith(ipv6rdBorderRelay: '192.0.2.9'));
      final sets = verify(() => mockUsp.set(captureAny(),
              allowPartial: any(named: 'allowPartial')))
          .captured
          .whereType<Map<String, dynamic>>()
          .where((m) => m.keys.any((k) => k.startsWith('Device.IPv6rd.')));
      expect(sets.single, {
        'Device.IPv6rd.InterfaceSetting.3.BorderRelayIPv4Addresses':
            '192.0.2.9',
      });
    });

    test('a 6rd change with no 6rd row is refused, nothing sent', () async {
      answer(const {});
      const original =
          UspInternetSettingsForm(connectionType: UspWanConnectionType.dhcp);
      await expectLater(
          service.saveAll(original, original.copyWith(ipv6rdEnabled: true)),
          throwsA(isA<ResourceNotFoundError>()));
      verifyNever(
          () => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')));
      expect(
        await _warningsDuring(() =>
            service.saveAll(original, original.copyWith(ipv6rdEnabled: true))),
        [contains('Device.IPv6rd.InterfaceSetting has no row')],
      );
    });
  });

  group('UspInternetSettingsService — PPTP / L2TP tunnel and underlay', () {
    // The tunnel sits on row 3, so a write that still names Tunnel.1 fails.
    const tunnel = 'Device.GRE.Tunnel.3.';
    const l2tpTunnel = 'Device.L2TPv2.Tunnel.4.';
    Map<String, dynamic> gre({
      String base = tunnel,
      String server = '203.0.113.10',
      String? type = 'Static',
      String ip = '198.51.100.10',
      String mask = '255.255.255.0',
      String gateway = '198.51.100.1',
      String dns = '8.8.8.8, 1.1.1.1',
      bool hasInterface = true,
    }) =>
        {
          '${base}RemoteEndpoints': server,
          // The tunnel's interface on row 2, so a write naming .1 fails.
          if (hasInterface) '${base}Interface.2.Alias': 'cpe-1',
          if (type != null) ...{
            '${base}X_LINKSYS_UnderlayAddressingType': type,
            '${base}X_LINKSYS_UnderlayIPAddress': ip,
            '${base}X_LINKSYS_UnderlaySubnetMask': mask,
            '${base}X_LINKSYS_UnderlayDefaultGateway': gateway,
            '${base}X_LINKSYS_UnderlayDNSServers': dns,
          },
        };
    final l2tpRow = gre(
        base: l2tpTunnel,
        server: '203.0.113.20',
        type: 'DHCP',
        ip: '',
        mask: '',
        gateway: '',
        dns: '');
    void answer({
      Map<String, dynamic>? greResponse,
      Map<String, dynamic>? l2tpResponse,
      Map<String, dynamic>? ppp,
      Map<String, dynamic>? wan,
    }) {
      final handler = createFetchMockHandler(
        wanResponse: wan ?? _wanIpcp(),
        pppResponse: ppp ?? _pppPptpResponse,
        greResponse: greResponse,
        l2tpResponse: l2tpResponse ?? l2tpRow,
      );
      when(() => mockUsp.get(any())).thenAnswer((invocation) async =>
          handler(invocation.positionalArguments[0] as List<String>));
    }

    group('fetch', () {
      test('reads the server and a static underlay from the only row',
          () async {
        answer(greResponse: gre());
        final result = await service.fetchSettings();
        expect(result.form.serverAddress, '203.0.113.10');
        expect(result.form.underlayStatic, isTrue);
        expect(result.form.underlayIpAddress, '198.51.100.10');
        expect(result.form.underlaySubnetMask, '255.255.255.0');
        expect(result.form.underlayGateway, '198.51.100.1');
        expect(result.form.underlayDns1, '8.8.8.8');
        expect(result.form.underlayDns2, '1.1.1.1');
        expect(result.form.underlayDns3, '');
        // The WAN IPv4 row (the tunnel address) stays in the Static fields.
        expect(result.form.staticIpAddress, '192.168.1.100');
      });

      test('a DHCP underlay reads as not static', () async {
        answer(greResponse: gre(type: 'DHCP'));
        expect((await service.fetchSettings()).form.underlayStatic, isFalse);
      });

      test('two tunnel rows read as no tunnel: which is the WAN is unknown',
          () async {
        answer(greResponse: {
          ...gre(),
          ...gre(base: 'Device.GRE.Tunnel.5.', server: '203.0.113.99'),
        });
        expect((await service.fetchSettings()).form.serverAddress, isEmpty);
      });
    });

    group('save', () {
      const pppPath = 'Device.PPP.Interface.1.';
      const dhcpWan = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp, mtu: 1460);
      final pptpStatic = dhcpWan.copyWith(
        connectionType: UspWanConnectionType.pptp,
        serverAddress: '203.0.113.10',
        pppUsername: 'user',
        pppPassword: 'pass',
        underlayStatic: true,
        underlayIpAddress: '198.51.100.10',
        underlaySubnetMask: '255.255.255.0',
        underlayGateway: '198.51.100.1',
        underlayDns1: '8.8.8.8',
        underlayDns2: '1.1.1.1',
      );
      final pptpDhcp = pptpStatic.copyWith(underlayStatic: false);

      setUp(() {
        answer(
            greResponse: gre(
                server: '',
                type: 'DHCP',
                ip: '',
                mask: '',
                gateway: '',
                dns: ''));
        when(() => mockUsp
                .setOrdered(any(), allowPartial: any(named: 'allowPartial')))
            .thenAnswer((_) async => {
                  'success': true,
                  'result': {'data': <String, dynamic>{}}
                });
        when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
            .thenAnswer((_) async => {
                  'success': true,
                  'result': {'data': <String, dynamic>{}}
                });
      });

      /// The ordered groups that wrote a tunnel row, as `[[path: value]]`.
      List<List<Map<String, String>>> tunnelGroups() => [
            for (final call in verify(() => mockUsp.setOrdered(captureAny(),
                    allowPartial: any(named: 'allowPartial')))
                .captured
                .cast<List<List<Map<String, String>>>>())
              for (final group in call)
                if (group.first['path']!.startsWith('Device.GRE.') ||
                    group.first['path']!.startsWith('Device.L2TPv2.'))
                  [
                    for (final p in group) {p['path']!: p['value']!}
                  ],
          ];

      void expectNothingSent() {
        verifyNever(
            () => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')));
        verifyNever(() => mockUsp.setOrdered(any(),
            allowPartial: any(named: 'allowPartial')));
        verifyNever(() => mockUsp.add(any()));
      }

      test(
          'entering PPTP with a static underlay writes the type first, in '
          'the Set that writes the server, through the row it read', () async {
        await service.saveAll(dhcpWan, pptpStatic, pppInstancePath: pppPath);
        expect(tunnelGroups(), [
          [
            {'${tunnel}RemoteEndpoints': '203.0.113.10'},
            {'${tunnel}X_LINKSYS_UnderlayAddressingType': 'Static'},
          ],
          [
            {'${tunnel}X_LINKSYS_UnderlayIPAddress': '198.51.100.10'}
          ],
          [
            {'${tunnel}X_LINKSYS_UnderlaySubnetMask': '255.255.255.0'}
          ],
          [
            {'${tunnel}X_LINKSYS_UnderlayDefaultGateway': '198.51.100.1'},
            {'${tunnel}X_LINKSYS_UnderlayDNSServers': '8.8.8.8,1.1.1.1'},
          ],
        ]);
      });

      test('entering PPTP with a DHCP underlay sends the server alone',
          () async {
        // The row already reads DHCP (the bench's GRE row on a DHCP WAN).
        await service.saveAll(dhcpWan, pptpDhcp, pppInstancePath: pppPath);
        expect(tunnelGroups(), [
          [
            {'${tunnel}RemoteEndpoints': '203.0.113.10'}
          ],
        ]);
      });

      test(
          'entering PPTP with a DHCP underlay over a leftover Static one '
          'sends DHCP with the server', () async {
        answer(greResponse: gre(server: ''));
        await service.saveAll(dhcpWan, pptpDhcp, pppInstancePath: pppPath);
        expect(tunnelGroups(), [
          [
            {'${tunnel}RemoteEndpoints': '203.0.113.10'},
            {'${tunnel}X_LINKSYS_UnderlayAddressingType': 'DHCP'},
          ],
        ]);
      });

      test('the server is not resent when the row already holds it', () async {
        answer(greResponse: gre(type: 'DHCP'));
        await service.saveAll(dhcpWan, pptpDhcp, pppInstancePath: pppPath);
        expect(tunnelGroups(), isEmpty);
      });

      test('a gateway change on a static underlay sends only the gateway',
          () async {
        answer(greResponse: gre());
        await service.saveAll(
            pptpStatic, pptpStatic.copyWith(underlayGateway: '198.51.100.254'),
            pppInstancePath: pppPath);
        expect(tunnelGroups(), [
          [
            {'${tunnel}X_LINKSYS_UnderlayDefaultGateway': '198.51.100.254'}
          ],
        ]);
      });

      test('turning the static underlay on sends all of it, type first',
          () async {
        answer(greResponse: gre(type: 'DHCP'));
        await service.saveAll(pptpDhcp, pptpStatic, pppInstancePath: pppPath);
        final groups = tunnelGroups();
        expect(groups.first, [
          {'${tunnel}X_LINKSYS_UnderlayAddressingType': 'Static'}
        ]);
        expect(groups, hasLength(4));
      });

      test('turning it off sends DHCP alone', () async {
        answer(greResponse: gre());
        await service.saveAll(pptpStatic, pptpDhcp, pppInstancePath: pppPath);
        expect(tunnelGroups(), [
          [
            {'${tunnel}X_LINKSYS_UnderlayAddressingType': 'DHCP'}
          ],
        ]);
      });

      test('entering L2TP resets the shared underlay to DHCP', () async {
        // netmngr 039 keeps the GRE and L2TPv2 underlay in the same WAN
        // section, so the L2TPv2 row reads the Static the PPTP WAN left, and
        // the page offers the underlay on PPTP only.
        answer(
            greResponse: gre(),
            l2tpResponse: gre(base: l2tpTunnel, server: '203.0.113.20'));
        final l2tp = pptpStatic.copyWith(
            connectionType: UspWanConnectionType.l2tp,
            serverAddress: '203.0.113.20');
        await service.saveAll(pptpStatic, l2tp, pppInstancePath: pppPath);
        expect(tunnelGroups(), [
          [
            {'${l2tpTunnel}X_LINKSYS_UnderlayAddressingType': 'DHCP'},
          ],
        ]);
      });

      test('no tunnel row is refused, nothing sent', () async {
        answer(greResponse: const {});
        await expectLater(
            service.saveAll(dhcpWan, pptpDhcp, pppInstancePath: pppPath),
            throwsA(isA<ResourceNotFoundError>()));
        expectNothingSent();
      });

      test('a refused save says why in the log', () async {
        // The error's toString() is its class name alone, so without this
        // line a field log reads "Resource not found" for every refusal.
        answer(greResponse: const {});
        expect(
          await _warningsDuring(() =>
              service.saveAll(dhcpWan, pptpDhcp, pppInstancePath: pppPath)),
          [contains('pptp needs exactly one Device.GRE.Tunnel row, found 0')],
        );
        answer(greResponse: gre(hasInterface: false));
        expect(
          await _warningsDuring(() =>
              service.saveAll(dhcpWan, pptpDhcp, pppInstancePath: pppPath)),
          [contains('${tunnel}Interface has no row')],
        );
      });

      test('two tunnel rows are refused, nothing sent', () async {
        answer(greResponse: {
          ...gre(),
          ...gre(base: 'Device.GRE.Tunnel.5.'),
        });
        await expectLater(
            service.saveAll(dhcpWan, pptpDhcp, pppInstancePath: pppPath),
            throwsA(isA<ResourceNotFoundError>()));
        expectNothingSent();
      });

      /// Every `PPP.Interface.{i}.LowerLayers` the save wrote.
      List<Object?> lowerLayersWrites() => [
            for (final call in verify(() => mockUsp.set(captureAny(),
                    allowPartial: any(named: 'allowPartial')))
                .captured
                .whereType<Map<String, dynamic>>())
              if (call.containsKey('${pppPath}LowerLayers'))
                call['${pppPath}LowerLayers'],
          ];

      test('PPTP links PPP to the interface of the row it read', () async {
        answer(greResponse: gre(server: '', type: 'DHCP'));
        await service.saveAll(dhcpWan, pptpDhcp, pppInstancePath: pppPath);
        expect(lowerLayersWrites(), ['${tunnel}Interface.2']);
      });

      test('L2TP links PPP to the interface of the row it read', () async {
        answer(
            greResponse: gre(server: '', type: 'DHCP'),
            l2tpResponse: gre(base: l2tpTunnel, server: '', type: 'DHCP'));
        await service.saveAll(
            dhcpWan,
            pptpDhcp.copyWith(
                connectionType: UspWanConnectionType.l2tp,
                serverAddress: '203.0.113.20'),
            pppInstancePath: pppPath);
        expect(lowerLayersWrites(), ['${l2tpTunnel}Interface.2']);
      });

      test('a tunnel with no interface is refused, nothing sent', () async {
        answer(greResponse: gre(server: '', type: 'DHCP', hasInterface: false));
        await expectLater(
            service.saveAll(dhcpWan, pptpDhcp, pppInstancePath: pppPath),
            throwsA(isA<ResourceNotFoundError>()));
        expectNothingSent();
      });
    });

    group('the PPP row the WAN runs on', () {
      /// Two PPP rows, 1 and 4. [wanLowerLayers] is what the WAN reports.
      Future<InternetSettingsFetchResult> fetchWithTwoPppRows(
          String wanLowerLayers) {
        answer(
          greResponse: gre(),
          wan: Map<String, dynamic>.from(_wanIpcp())
            ..['Device.IP.Interface.2.LowerLayers'] = wanLowerLayers,
          ppp: {
            ..._pppPptpResponse,
            for (final e in _pppPptpResponse.entries)
              e.key.replaceFirst('Interface.1.', 'Interface.4.'): e.value,
            'Device.PPP.Interface.4.Username': 'wanuser',
          },
        );
        return service.fetchSettings();
      }

      test('is the row the WAN runs on', () async {
        final result = await fetchWithTwoPppRows('Device.PPP.Interface.4');
        expect(result.pppInstancePath, 'Device.PPP.Interface.4.');
        expect(result.form.pppUsername, 'wanuser');
      });

      test('two rows the WAN names neither of read as none', () async {
        final result = await fetchWithTwoPppRows('Device.Ethernet.Link.2');
        expect(result.pppInstancePath, isNull);
      });

      test('a WAN on Ethernet uses the only PPP row', () async {
        answer(greResponse: gre());
        final result = await service.fetchSettings();
        expect(result.pppInstancePath, 'Device.PPP.Interface.1.');
      });
    });

    group('refusals (fault 7012 with netmngr\'s message)', () {
      const pppPath = 'Device.PPP.Interface.1.';
      final pptpStatic = const UspInternetSettingsForm(
              connectionType: UspWanConnectionType.dhcp, mtu: 1460)
          .copyWith(
        connectionType: UspWanConnectionType.pptp,
        serverAddress: '203.0.113.10',
        pppUsername: 'user',
        pppPassword: 'pass',
        underlayStatic: true,
        underlayIpAddress: '198.51.100.10',
        underlaySubnetMask: '255.255.255.0',
        underlayGateway: '198.51.100.1',
        underlayDns1: '8.8.8.8',
      );

      /// The tunnel Set refuses [refused] with [message] (the leaf's own
      /// `fault_msg`, measured on 2.0.3.26102008) and reports the rest of the
      /// group as "group set failed", as obuspa does (FWDEV#213).
      void refuseTunnelSet(String refused, String message) {
        answer(
            greResponse: gre(
                server: '',
                type: 'DHCP',
                ip: '',
                mask: '',
                gateway: '',
                dns: ''));
        when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
            .thenAnswer((_) async => {
                  'success': true,
                  'result': {'data': <String, dynamic>{}}
                });
        when(() => mockUsp.setOrdered(any(),
                allowPartial: any(named: 'allowPartial')))
            .thenAnswer((invocation) async {
          final paths = (invocation.positionalArguments[0]
                  as List<List<Map<String, String>>>)
              .expand((g) => g)
              .map((p) => p['path']!)
              .toList();
          if (!paths.any((p) => p.endsWith(refused))) {
            return {
              'success': true,
              'result': {'data': <String, dynamic>{}}
            };
          }
          return {
            'success': false,
            'result': {
              'data': <String, dynamic>{},
              'error': {
                for (final p in paths)
                  p: {
                    'errorCode': 7012,
                    'errorMessage': p.endsWith(refused)
                        ? message
                        : "SetParameterGroup: group set failed at '$tunnel$refused' "
                            '(Invalid value)',
                  },
              },
            },
          };
        });
      }

      for (final (leaf, message) in [
        ('RemoteEndpoints', 'Invalid server'),
        ('X_LINKSYS_UnderlayIPAddress', 'Invalid IP address'),
        ('X_LINKSYS_UnderlaySubnetMask', 'Invalid network prefix length'),
        ('X_LINKSYS_UnderlayDefaultGateway', 'Invalid gateway'),
        ('X_LINKSYS_UnderlayDNSServers', 'Invalid primary DNS server'),
      ]) {
        test('"$message" on $leaf names the check', () async {
          refuseTunnelSet(leaf, message);
          await expectLater(
            service.saveAll(
                const UspInternetSettingsForm(
                    connectionType: UspWanConnectionType.dhcp, mtu: 1460),
                pptpStatic,
                pppInstancePath: pppPath),
            throwsA(isA<InvalidInputError>()
                .having((e) => e.field, 'field', message)
                .having((e) => e.code, 'code', 7012)),
          );
        });
      }

      test('"Invalid DNS server" is not read as "Invalid IP address"',
          () async {
        refuseTunnelSet('X_LINKSYS_UnderlayDNSServers', 'Invalid DNS server');
        await expectLater(
          service.saveAll(
              const UspInternetSettingsForm(
                  connectionType: UspWanConnectionType.dhcp, mtu: 1460),
              pptpStatic,
              pppInstancePath: pppPath),
          throwsA(isA<InvalidInputError>()
              .having((e) => e.field, 'field', 'Invalid DNS server')),
        );
      });

      test('a refusal with no known message keeps the USP failure', () async {
        refuseTunnelSet('RemoteEndpoints',
            "'x' value is not within range (min: '60' max: '599940')");
        await expectLater(
          service.saveAll(
              const UspInternetSettingsForm(
                  connectionType: UspWanConnectionType.dhcp, mtu: 1460),
              pptpStatic,
              pppInstancePath: pppPath),
          throwsA(isA<UspCompleteFailureError>()),
        );
      });
    });
  });

  group('bridge boundary timing', () {
    setUp(() {
      final handler = createFetchMockHandler();
      when(() => mockUsp.get(any())).thenAnswer((invocation) async =>
          handler(invocation.positionalArguments[0] as List<String>));
    });

    final original = UspInternetSettingsForm(
      connectionType: UspWanConnectionType.dhcp,
    );
    final edited = original.copyWith(
      connectionType: UspWanConnectionType.bridge,
    );

    test('a rejected bridge SET fails at once, without waiting', () {
      fakeAsync((async) {
        when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
            .thenAnswer((_) async => {
                  'success': false,
                  'result': {
                    'data': <String, dynamic>{},
                    'error': {
                      'Device.IP.Interface.2.Enable': {
                        'errorCode': 7006,
                        'errorMessage': 'Invalid value',
                      },
                    },
                  },
                });

        Object? error;
        service
            .saveAll(original, edited)
            .then<void>((_) {}, onError: (Object e) => error = e);

        async.flushMicrotasks();
        expect(error, isA<ServiceError>());
      });
    });

    test('leaving bridge does not wait', () {
      fakeAsync((async) {
        when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
            .thenAnswer((_) async => {
                  'success': true,
                  'result': {'data': <String, dynamic>{}}
                });
        // Leaving into DHCP writes the WAN row before Enable=true.
        when(() => mockUsp
                .setOrdered(any(), allowPartial: any(named: 'allowPartial')))
            .thenAnswer((_) async => {
                  'success': true,
                  'result': {'data': <String, dynamic>{}}
                });

        var done = false;
        service
            .saveAll(
              edited,
              edited.copyWith(connectionType: UspWanConnectionType.dhcp),
            )
            .then<void>((_) => done = true);

        async.flushMicrotasks();
        expect(done, isTrue);
      });
    });
  });

  group('renewDhcpLease', () {
    // The WAN is on Interface.5; DHCPv{4,6}.Client.3 runs on the LAN and
    // Client.6 on the WAN, so a renew of a guessed Client.1 cannot pass.
    void stubRenew({bool hasWanClient = true}) {
      when(() => mockUsp.get(any())).thenAnswer((invocation) async =>
          InternetSettingsTestData.renewAnswer(
              invocation.positionalArguments[0] as List<String>,
              hasWanClient: hasWanClient));
      // WASM v0.11.0 format for OPERATE success
      when(() => mockUsp.operate(any())).thenAnswer((_) async => {
            'success': true,
            'result': {'data': <String, dynamic>{}},
          });
    }

    test('renews the DHCPv4 client bound to the WAN interface', () async {
      stubRenew();

      await service.renewDhcpLease();

      verify(() => mockUsp.operate('Device.DHCPv4.Client.6.Renew()')).called(1);
    });

    test('a client on Interface.50 is not the WAN on Interface.5', () async {
      when(() => mockUsp.get(any())).thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
        if (paths.any((p) => p.startsWith('Device.DHCPv4.Client.'))) {
          return {
            'Device.DHCPv4.Client.6.Enable': true,
            'Device.DHCPv4.Client.6.Interface': 'Device.IP.Interface.50',
            'Device.DHCPv4.Client.6.Status': 'Enabled',
          };
        }
        return InternetSettingsTestData.renewAnswer(paths);
      });
      when(() => mockUsp.operate(any())).thenAnswer((_) async => {
            'success': true,
            'result': {'data': <String, dynamic>{}},
          });

      await expectLater(
          service.renewDhcpLease(), throwsA(isA<ResourceNotFoundError>()));
      verifyNever(() => mockUsp.operate(any()));
    });

    test('a WAN with no DHCPv4 client renews nothing and says so', () async {
      stubRenew(hasWanClient: false);

      await expectLater(
          service.renewDhcpLease(), throwsA(isA<ResourceNotFoundError>()));
      verifyNever(() => mockUsp.operate(any()));
    });
  });

  group('renewDhcpv6Lease', () {
    void stubRenew({bool hasWanClient = true}) {
      when(() => mockUsp.get(any())).thenAnswer((invocation) async =>
          InternetSettingsTestData.renewAnswer(
              invocation.positionalArguments[0] as List<String>,
              hasWanClient: hasWanClient));
      when(() => mockUsp.operate(any())).thenAnswer((_) async => {
            'success': true,
            'result': {'data': <String, dynamic>{}},
          });
    }

    test('renews the DHCPv6 client bound to the WAN interface', () async {
      stubRenew();

      await service.renewDhcpv6Lease();

      verify(() => mockUsp.operate('Device.DHCPv6.Client.6.Renew()')).called(1);
    });

    test('a WAN with no DHCPv6 client renews nothing and says so', () async {
      stubRenew(hasWanClient: false);

      await expectLater(
          service.renewDhcpv6Lease(), throwsA(isA<ResourceNotFoundError>()));
      verifyNever(() => mockUsp.operate(any()));
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
      when(() => mockUsp.get(any())).thenAnswer((invocation) async =>
          InternetSettingsTestData.renewAnswer(
              invocation.positionalArguments[0] as List<String>));
      when(() => mockUsp.operate(any()))
          .thenThrow('Operate failed: Transport error: Connection refused');

      expect(
        () => service.renewDhcpLease(),
        throwsA(isA<ServiceError>()),
      );
    });

    test('renewDhcpv6Lease maps USP error to ServiceError', () async {
      when(() => mockUsp.get(any())).thenAnswer((invocation) async =>
          InternetSettingsTestData.renewAnswer(
              invocation.positionalArguments[0] as List<String>));
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
