// The list pages say when a row has no router path yet (#1212).
//
// The Preservable delegate gates the save after an unconfirmed add on
// `HasUnconfirmedRows`: a row added on the page has no instance path until the
// router creates it, and saving such a row again adds it a second time. DMZ's
// getter is pinned through its notifier; these four have the same shape over a
// list, and a getter that answers `false` would let the duplicate add through
// with every other test green.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/dhcp/models/dhcp_reservation_list.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_rule_list.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_forwarding_page_settings.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';
import 'package:privacy_gui/page/static_routing/models/static_route_list.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_ui_model.dart';

StaticRouteUIModel _route(String? path) => StaticRouteUIModel(
      instancePath: path,
      enabled: true,
      name: 'r',
      destIpAddress: '10.0.0.0',
      destSubnetMask: '255.255.255.0',
      gatewayIpAddress: '192.168.1.254',
      interfaceName: 'LAN',
    );

DhcpReservationUIModel _reservation(String? path) => DhcpReservationUIModel(
      instancePath: path,
      mac: 'AA:BB:CC:DD:EE:FF',
      ip: '192.168.1.50',
      enable: true,
    );

Ipv6PortServiceRuleUIModel _ipv6Rule(String? path) =>
    Ipv6PortServiceRuleUIModel(
      instancePath: path,
      enabled: true,
      description: 'r',
      ipv6Address: '2001:db8::1',
      protocol: 'TCP',
      startPort: 80,
      endPort: 80,
    );

PortForwardingRuleUIModel _forward(String? path) => PortForwardingRuleUIModel(
      instancePath: path,
      description: 'r',
      externalPort: 8080,
      internalPort: 80,
      internalClient: '192.168.1.50',
      protocol: 'TCP',
      enabled: true,
    );

PortTriggeringRuleUIModel _trigger(String? path) => PortTriggeringRuleUIModel(
      instancePath: path,
      enabled: true,
      description: 'r',
      triggerPort: 6000,
      triggerProtocol: 'TCP',
    );

void main() {
  const saved = 'Device.X.1.';

  test('StaticRouteList', () {
    expect(StaticRouteList(routes: [_route(saved)]).hasUnconfirmedRows,
        isFalse);
    expect(
        StaticRouteList(routes: [_route(saved), _route(null)])
            .hasUnconfirmedRows,
        isTrue);
  });

  test('DhcpReservationList', () {
    expect(
        DhcpReservationList(reservations: [_reservation(saved)])
            .hasUnconfirmedRows,
        isFalse);
    expect(
        DhcpReservationList(
            reservations: [_reservation(saved), _reservation(null)])
            .hasUnconfirmedRows,
        isTrue);
  });

  test('Ipv6PortServiceRuleList', () {
    expect(
        Ipv6PortServiceRuleList(rules: [_ipv6Rule(saved)]).hasUnconfirmedRows,
        isFalse);
    expect(
        Ipv6PortServiceRuleList(rules: [_ipv6Rule(saved), _ipv6Rule(null)])
            .hasUnconfirmedRows,
        isTrue);
  });

  test('PortForwardingPageSettings — either list', () {
    expect(
        PortForwardingPageSettings(
          forwardingRules: [_forward(saved)],
          triggeringRules: [_trigger(saved)],
        ).hasUnconfirmedRows,
        isFalse);
    expect(
        PortForwardingPageSettings(
          forwardingRules: [_forward(null)],
          triggeringRules: [_trigger(saved)],
        ).hasUnconfirmedRows,
        isTrue,
        reason: 'a new forwarding rule');
    expect(
        PortForwardingPageSettings(
          forwardingRules: [_forward(saved)],
          triggeringRules: [_trigger(null)],
        ).hasUnconfirmedRows,
        isTrue,
        reason: 'a new triggering rule');
  });

  test('an empty list has nothing unconfirmed', () {
    expect(const StaticRouteList(routes: []).hasUnconfirmedRows, isFalse);
  });
}
