import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_ui_model.dart';

void main() {
  group('StaticRouteUIModel — validateRoute', () {
    test('valid route returns empty errors', () {
      final errors = StaticRouteUIModel.validateRoute(
        name: 'MyRoute',
        destIp: '10.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: '192.168.1.1',
      );
      expect(errors, isEmpty);
    });

    test('empty name returns error', () {
      final errors = StaticRouteUIModel.validateRoute(
        name: '',
        destIp: '10.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: '',
      );
      expect(errors['name'], StaticRoutingErrorKeys.nameRequired);
    });

    test('name over 32 chars returns error', () {
      final errors = StaticRouteUIModel.validateRoute(
        name: 'A' * 33,
        destIp: '10.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: '',
      );
      expect(errors['name'], StaticRoutingErrorKeys.nameTooLong);
    });

    test('name exactly 32 chars is valid', () {
      final errors = StaticRouteUIModel.validateRoute(
        name: 'A' * 32,
        destIp: '10.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: '',
      );
      expect(errors.containsKey('name'), isFalse);
    });

    test('empty destIp returns error', () {
      final errors = StaticRouteUIModel.validateRoute(
        name: 'Route1',
        destIp: '',
        subnetMask: '255.255.255.0',
        gateway: '',
      );
      expect(errors['destIp'], StaticRoutingErrorKeys.destIpRequired);
    });

    test('invalid destIp returns error', () {
      final errors = StaticRouteUIModel.validateRoute(
        name: 'Route1',
        destIp: '999.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: '',
      );
      expect(errors['destIp'], StaticRoutingErrorKeys.invalidIpAddress);
    });

    test('empty subnetMask returns error', () {
      final errors = StaticRouteUIModel.validateRoute(
        name: 'Route1',
        destIp: '10.0.0.0',
        subnetMask: '',
        gateway: '',
      );
      expect(errors['subnetMask'], StaticRoutingErrorKeys.subnetMaskRequired);
    });

    test('invalid subnetMask returns error', () {
      final errors = StaticRouteUIModel.validateRoute(
        name: 'Route1',
        destIp: '10.0.0.0',
        subnetMask: '255.255.0.128',
        gateway: '',
      );
      expect(errors['subnetMask'], StaticRoutingErrorKeys.invalidSubnetMask);
    });

    test('empty gateway is valid (optional)', () {
      final errors = StaticRouteUIModel.validateRoute(
        name: 'Route1',
        destIp: '10.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: '',
      );
      expect(errors.containsKey('gateway'), isFalse);
    });

    test('invalid gateway returns error', () {
      final errors = StaticRouteUIModel.validateRoute(
        name: 'Route1',
        destIp: '10.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: 'not-an-ip',
      );
      expect(errors['gateway'], StaticRoutingErrorKeys.invalidIpAddress);
    });

    test('multiple errors returned simultaneously', () {
      final errors = StaticRouteUIModel.validateRoute(
        name: '',
        destIp: '',
        subnetMask: '',
        gateway: 'bad',
      );
      expect(errors, hasLength(4));
    });

    // --- gateway subnet validation (issue #1082) ---

    test('LAN interface: gateway within LAN subnet is valid', () {
      final errors = StaticRouteUIModel.validateRoute(
        name: 'Route1',
        destIp: '10.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: '192.168.1.100',
        interfaceName: 'LAN',
        lanIp: '192.168.1.1',
        lanSubnetMask: '255.255.255.0',
      );
      expect(errors.containsKey('gateway'), isFalse);
    });

    test('LAN interface: gateway outside LAN subnet returns error', () {
      final errors = StaticRouteUIModel.validateRoute(
        name: 'Route1',
        destIp: '10.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: '8.8.8.8',
        interfaceName: 'LAN',
        lanIp: '192.168.1.1',
        lanSubnetMask: '255.255.255.0',
      );
      expect(errors['gateway'],
          StaticRoutingErrorKeys.gatewayMustBeWithinLanSubnet);
    });

    test('Internet interface: gateway outside LAN subnet is valid', () {
      final errors = StaticRouteUIModel.validateRoute(
        name: 'Route1',
        destIp: '10.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: '100.64.1.1',
        interfaceName: 'Internet',
        lanIp: '192.168.1.1',
        lanSubnetMask: '255.255.255.0',
      );
      expect(errors.containsKey('gateway'), isFalse);
    });

    test('Internet interface: gateway within LAN subnet returns error', () {
      final errors = StaticRouteUIModel.validateRoute(
        name: 'Route1',
        destIp: '10.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: '192.168.1.50',
        interfaceName: 'Internet',
        lanIp: '192.168.1.1',
        lanSubnetMask: '255.255.255.0',
      );
      expect(errors['gateway'],
          StaticRoutingErrorKeys.gatewayMustBeOutsideLanSubnet);
    });

    test('subnet validation skipped when lanIp/lanSubnetMask not provided', () {
      final errors = StaticRouteUIModel.validateRoute(
        name: 'Route1',
        destIp: '10.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: '8.8.8.8',
        interfaceName: 'LAN',
      );
      expect(errors.containsKey('gateway'), isFalse);
    });

    test(
        'empty-string lanIp/lanSubnetMask (LanData.empty fallback) skips subnet '
        'check — no false-positive Internet error', () {
      // Regression for W-NEW-1: LanData.empty() returns ipAddress:'' /
      // subnetMask:'' (empty strings, not null). ipToNum('') == 0, so the LAN
      // subnet rule would incorrectly report isInLan == true for ANY gateway,
      // firing a permanent false-positive gatewayMustBeOutsideLanSubnet error
      // on Internet-interface routes while LAN data is still loading.
      final errors = StaticRouteUIModel.validateRoute(
        name: 'Route1',
        destIp: '10.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: '8.8.8.8',
        interfaceName: 'Internet',
        lanIp: '',
        lanSubnetMask: '',
      );
      expect(errors.containsKey('gateway'), isFalse);
    });

    test('invalid gateway format takes precedence over subnet check', () {
      final errors = StaticRouteUIModel.validateRoute(
        name: 'Route1',
        destIp: '10.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: 'bad-ip',
        interfaceName: 'LAN',
        lanIp: '192.168.1.1',
        lanSubnetMask: '255.255.255.0',
      );
      expect(errors['gateway'], StaticRoutingErrorKeys.invalidIpAddress);
    });
  });
}
