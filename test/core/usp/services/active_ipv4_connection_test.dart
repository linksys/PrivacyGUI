import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/usp/services/active_ipv4_connection.dart';
import 'package:privacy_gui/page/internet_settings/services/usp_wan_data_service.dart';
import 'package:privacy_gui/page/unified_diagnostics/services/unified_diagnostics_service.dart';

class Client extends Mock implements UspClient {}

void main() {
  test('unsupported devices skip the connection read', () async {
    final client = Client();

    expect(
      await ActiveIpv4Connection.fetch(client, autoIPoESupported: false),
      isNull,
    );
    verifyZeroInteractions(client);
  });
  for (final kind in ['MAP-E', 'DS-Lite', 'IPIP']) {
    test(
        '$kind uses actual route, without requiring legacy WAN IPv4 or gateway',
        () async {
      final client = Client();
      when(() => client.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async => {
                ActiveIpv4Connection.path: jsonEncode({
                  'apiVersion': 1,
                  'available': true,
                  'state': 'Up',
                  'activeIPv4Route': true,
                  'tunnelType': kind,
                  'address': kind == 'DS-Lite' ? '' : '192.0.2.7',
                  'mtu': 1460,
                  'pointToPoint': true
                })
              });
      final wan =
          await UspWanDataService(client, autoIPoESupported: true).fetch();
      expect(wan.isUp, true);
      expect(wan.addressingType, kind);
      expect(wan.mtu, 1460);
      expect(wan.gateway, '');
      final diag = UnifiedDiagnosticsService(client, autoIPoESupported: true);
      expect((await diag.checkWanStatus()).hasIp, true);
      expect(await diag.pingGateway(), isNull);
    });
  }
  test('a down tunnel stays down without a legacy WAN fallback', () async {
    final client = Client();
    when(() => client.get(any(), priority: any(named: 'priority')))
        .thenAnswer((_) async => {
              ActiveIpv4Connection.path: jsonEncode({
                'apiVersion': 1,
                'available': true,
                'state': 'Up',
                'activeIPv4Route': false,
                'tunnelType': 'MAP-E',
                'address': '192.0.2.7',
              }),
            });

    final wan =
        await UspWanDataService(client, autoIPoESupported: true).fetch();
    final diagnostics =
        UnifiedDiagnosticsService(client, autoIPoESupported: true);

    expect(wan.isUp, isFalse);
    expect(wan.addressingType, 'MAP-E');
    expect((await diagnostics.checkWanStatus()).isUp, isFalse);
    await expectLater(
        diagnostics.pingGateway(), throwsA(isA<ConnectivityError>()));
    final requested =
        verify(() => client.get(captureAny(), priority: any(named: 'priority')))
            .captured;
    expect(requested, everyElement([ActiveIpv4Connection.path]));
  });
  test('stale tunnel address without route is down', () {
    final c = ActiveIpv4Connection({
      'available': true,
      'state': 'Up',
      'activeIPv4Route': false,
      'address': '192.0.2.7'
    });
    expect(c.isUp, false);
  });
  test('older firmware with absent optional path falls back', () async {
    final c = Client();
    when(() => c.get(any(), priority: any(named: 'priority')))
        .thenAnswer((_) async => {});
    expect(
        await ActiveIpv4Connection.fetch(c, autoIPoESupported: true), isNull);
  });
  test('authentication errors must not be turned into a legacy fallback',
      () async {
    final c = Client();
    when(() => c.get(any(), priority: any(named: 'priority')))
        .thenThrow(const NotAuthenticatedError());
    await expectLater(ActiveIpv4Connection.fetch(c, autoIPoESupported: true),
        throwsA(isA<NotAuthenticatedError>()));
  });
  test('ordinary DHCP uses real next hop and remains DHCP', () {
    final c = ActiveIpv4Connection({
      'available': true,
      'state': 'Up',
      'activeIPv4Route': true,
      'protocol': 'dhcp',
      'gateway': '198.51.100.254'
    });
    expect(c.label, 'DHCP');
    expect(c.gateway, '198.51.100.254');
    expect(c.isTunnel, false);
  });
}
