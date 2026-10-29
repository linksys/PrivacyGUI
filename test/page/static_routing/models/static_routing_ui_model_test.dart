import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_ui_model.dart';

StaticRouteUIModel _route(String name, {String? instancePath}) =>
    StaticRouteUIModel(
      instancePath: instancePath,
      enabled: true,
      name: name,
      destIpAddress: '10.0.0.0',
      destSubnetMask: '255.255.255.0',
      gatewayIpAddress: '192.168.1.50',
      interfaceName: 'LAN',
    );

List<StaticRouteUIModel> _saved(int count) => [
      for (var i = 1; i <= count; i++)
        _route('Route $i',
            instancePath: 'Device.Routing.Router.1.IPv4Forwarding.$i.'),
    ];

void main() {
  // FWDEV#213: FW checks a name each time a route's Alias is written, against
  // the names the other routes hold on the router then; and the 20 when a new
  // route gets its destination. The page saves Delete, then Set, then Add, so
  // the check replays that order over the routes the save writes.
  group('StaticRouteUIModel — validateList', () {
    String? check(List<StaticRouteUIModel> original,
            List<StaticRouteUIModel> current) =>
        StaticRouteUIModel.validateList(original: original, current: current);

    test('a save FW would take returns null', () {
      final saved = _saved(19);
      expect(check(saved, [...saved, _route('New')]), isNull);
    });

    test('two unsaved routes with the same name return duplicateName', () {
      final saved = _saved(2);
      expect(check(saved, [...saved, _route('New'), _route('New')]),
          StaticRoutingErrorKeys.duplicateName);
    });

    test('an unsaved route named like a saved one returns duplicateName', () {
      final saved = _saved(2);
      expect(check(saved, [...saved, _route('Route 2')]),
          StaticRoutingErrorKeys.duplicateName);
    });

    test('an edit renamed to a saved route returns duplicateName', () {
      final saved = _saved(2);
      expect(check(saved, [saved[0].copyWith(name: 'Route 2'), saved[1]]),
          StaticRoutingErrorKeys.duplicateName);
    });

    // The Set reaches FW while the other route still holds its old name.
    test('two saved routes swapping names return duplicateName', () {
      final saved = _saved(2);
      expect(
          check(saved, [
            saved[0].copyWith(name: 'Route 2'),
            saved[1].copyWith(name: 'Route 1'),
          ]),
          StaticRoutingErrorKeys.duplicateName);
    });

    test('two saved routes renamed to one new name return duplicateName', () {
      final saved = _saved(2);
      expect(
          check(saved, [
            saved[0].copyWith(name: 'Same'),
            saved[1].copyWith(name: 'Same'),
          ]),
          StaticRoutingErrorKeys.duplicateName);
    });

    // Set runs before Add, so the old name is free by the time the Add lands.
    test('a name freed by a rename in the same save can be added', () {
      final saved = _saved(2);
      expect(
          check(saved, [
            saved[0].copyWith(name: 'Renamed'),
            saved[1],
            _route('Route 1'),
          ]),
          isNull);
    });

    test('a name freed by a delete in the same save can be reused', () {
      final saved = _saved(2);
      expect(check(saved, [saved[0].copyWith(name: 'Route 2')]), isNull);
      expect(check(saved, [saved[0], _route('Route 2')]), isNull);
    });

    // FW checks a name only when it is written, so two routes an older build
    // saved under one name do not stop a save that writes neither.
    test('two saved routes already sharing a name do not block other changes',
        () {
      final saved = [
        _route('Dup',
            instancePath: 'Device.Routing.Router.1.IPv4Forwarding.1.'),
        _route('Dup',
            instancePath: 'Device.Routing.Router.1.IPv4Forwarding.2.'),
      ];
      expect(check(saved, saved), isNull);
      expect(check(saved, [...saved, _route('New')]), isNull);
    });

    test('writing one of two routes that share a name returns duplicateName',
        () {
      final saved = [
        _route('Dup',
            instancePath: 'Device.Routing.Router.1.IPv4Forwarding.1.'),
        _route('Dup',
            instancePath: 'Device.Routing.Router.1.IPv4Forwarding.2.'),
      ];
      expect(check(saved, [saved[0].copyWith(enabled: false), saved[1]]),
          StaticRoutingErrorKeys.duplicateName);
    });

    test('a 21st route added on the page returns tooManyRoutes', () {
      final saved = _saved(19);
      expect(check(saved, [...saved, _route('New 1'), _route('New 2')]),
          StaticRoutingErrorKeys.tooManyRoutes);
    });

    // Delete runs first, so a deleted route frees its slot for an Add.
    test('delete one and add one at 20 returns null', () {
      final saved = _saved(20);
      expect(check(saved, [...saved.skip(1), _route('New')]), isNull);
    });

    // FW counts only on a route that has no destination yet, so routes past 20
    // from an older build stay editable (feed_usp#56).
    test('more than 20 saved routes and nothing added returns null', () {
      final saved = _saved(22);
      expect(
          check(saved, [saved[0].copyWith(enabled: false), ...saved.skip(1)]),
          isNull);
    });

    test('an Add on a list already past 20 returns tooManyRoutes', () {
      final saved = _saved(21);
      expect(check(saved, [...saved, _route('New')]),
          StaticRoutingErrorKeys.tooManyRoutes);
    });
  });

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

    // FWDEV#213: 1.0's dialog takes /8 to /30. FW itself takes /31 as well
    // (feed_usp#56), so /31 is the GUI's own limit, as on 1.0.
    test('mask outside /8../30 returns error, without throwing', () {
      for (final mask in [
        '254.0.0.0', // /7
        '255.255.255.254', // /31
        '255.255.255.255', // /32
      ]) {
        final errors = StaticRouteUIModel.validateRoute(
          name: 'Route1',
          destIp: '10.0.0.0',
          subnetMask: mask,
          gateway: '192.168.1.50',
        );
        expect(errors['subnetMask'], StaticRoutingErrorKeys.invalidSubnetMask,
            reason: mask);
      }
    });

    test('masks /8 and /30 are valid', () {
      for (final mask in ['255.0.0.0', '255.255.255.252']) {
        final errors = StaticRouteUIModel.validateRoute(
          name: 'Route1',
          destIp: '10.0.0.0',
          subnetMask: mask,
          gateway: '192.168.1.50',
        );
        expect(errors.containsKey('subnetMask'), isFalse, reason: mask);
      }
    });

    // FWDEV#213: 1.0's util.isReservedAddress. The first and last address of
    // each block, so the edges are covered.
    const reservedAddresses = [
      '0.0.0.1', '0.255.255.255', // 0/8
      '127.0.0.1', '127.255.255.255', // 127/8
      '169.254.0.1', '169.254.255.255', // 169.254/16
      '224.0.0.1', '239.255.255.255', // 224/4
      '240.0.0.1', '255.255.255.255', // 240/4
    ];

    test('reserved destination returns error', () {
      for (final ip in reservedAddresses) {
        final errors = StaticRouteUIModel.validateRoute(
          name: 'Route1',
          destIp: ip,
          subnetMask: '255.255.255.0',
          gateway: '192.168.1.50',
        );
        expect(errors['destIp'], StaticRoutingErrorKeys.reservedAddress,
            reason: ip);
      }
    });

    test('reserved gateway returns error, on either interface', () {
      for (final interfaceName in StaticRouteUIModel.interfaceOptions) {
        for (final ip in reservedAddresses) {
          final errors = StaticRouteUIModel.validateRoute(
            name: 'Route1',
            destIp: '10.0.0.0',
            subnetMask: '255.255.255.0',
            gateway: ip,
            interfaceName: interfaceName,
            lanIp: '192.168.1.1',
            lanSubnetMask: '255.255.255.0',
          );
          expect(errors['gateway'], StaticRoutingErrorKeys.reservedAddress,
              reason: '$interfaceName $ip');
        }
      }
    });

    test('addresses next to the reserved blocks are valid', () {
      for (final ip in [
        '1.0.0.0',
        '126.255.255.255',
        '128.0.0.0',
        '169.253.255.255',
        '169.255.0.0',
        '223.255.255.255',
      ]) {
        final errors = StaticRouteUIModel.validateRoute(
          name: 'Route1',
          destIp: ip,
          subnetMask: '255.255.255.0',
          gateway: '192.168.1.50',
        );
        expect(errors.containsKey('destIp'), isFalse, reason: ip);
      }
    });

    // FWDEV#213 / 1.x IpAddressAsLocalIpValidator: a destination may not be a
    // host of the LAN, except the router's own address.
    test('destination that is a LAN host returns error', () {
      for (final ip in ['192.168.1.2', '192.168.1.100', '192.168.1.254']) {
        final errors = StaticRouteUIModel.validateRoute(
          name: 'Route1',
          destIp: ip,
          subnetMask: '255.255.255.252',
          gateway: '192.168.1.50',
          interfaceName: 'LAN',
          lanIp: '192.168.1.1',
          lanSubnetMask: '255.255.255.0',
        );
        expect(errors['destIp'], StaticRoutingErrorKeys.destIpInLanSubnet,
            reason: ip);
      }
    });

    test(
        "the router's own address, and addresses off the LAN, are valid "
        'destinations', () {
      for (final ip in ['192.168.1.1', '192.168.2.0', '10.0.0.0']) {
        final errors = StaticRouteUIModel.validateRoute(
          name: 'Route1',
          destIp: ip,
          subnetMask: '255.255.255.0',
          gateway: '192.168.1.50',
          interfaceName: 'LAN',
          lanIp: '192.168.1.1',
          lanSubnetMask: '255.255.255.0',
        );
        expect(errors.containsKey('destIp'), isFalse, reason: ip);
      }
    });

    // FW counts the LAN's network and broadcast addresses as inside the LAN
    // (feed_usp#56 `in_lan`), so neither is an Internet gateway. A refused
    // Add drops Interface and turns the route into a LAN route.
    test(
        "Internet interface: the LAN's network or broadcast address as "
        'gateway returns error', () {
      for (final gateway in ['192.168.1.0', '192.168.1.255']) {
        final errors = StaticRouteUIModel.validateRoute(
          name: 'Route1',
          destIp: '10.0.0.0',
          subnetMask: '255.255.255.0',
          gateway: gateway,
          interfaceName: 'Internet',
          lanIp: '192.168.1.1',
          lanSubnetMask: '255.255.255.0',
        );
        expect(errors['gateway'],
            StaticRoutingErrorKeys.gatewayMustBeOutsideLanSubnet,
            reason: gateway);
      }
    });

    // Inside the LAN, so not "must be within the LAN subnet".
    test('LAN interface: the router itself as gateway returns gatewayIsRouter',
        () {
      final errors = StaticRouteUIModel.validateRoute(
        name: 'Route1',
        destIp: '10.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: '192.168.1.1',
        interfaceName: 'LAN',
        lanIp: '192.168.1.1',
        lanSubnetMask: '255.255.255.0',
      );
      expect(errors['gateway'], StaticRoutingErrorKeys.gatewayIsRouter);
    });

    test(
        "LAN interface: the LAN's network or broadcast address as gateway "
        'returns error', () {
      for (final gateway in ['192.168.1.0', '192.168.1.255']) {
        final errors = StaticRouteUIModel.validateRoute(
          name: 'Route1',
          destIp: '10.0.0.0',
          subnetMask: '255.255.255.0',
          gateway: gateway,
          interfaceName: 'LAN',
          lanIp: '192.168.1.1',
          lanSubnetMask: '255.255.255.0',
        );
        expect(errors['gateway'],
            StaticRoutingErrorKeys.gatewayMustBeWithinLanSubnet,
            reason: gateway);
      }
    });

    // FWDEV#213: ErrorDuplicateEntryName. FW compares names exactly.
    test('name another route already has returns error', () {
      final errors = StaticRouteUIModel.validateRoute(
        name: 'Office',
        destIp: '10.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: '192.168.1.50',
        otherNames: const {'VPN', 'Office'},
      );
      expect(errors['name'], StaticRoutingErrorKeys.duplicateName);
    });

    test('name differing only in case from another route is valid', () {
      final errors = StaticRouteUIModel.validateRoute(
        name: 'office',
        destIp: '10.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: '192.168.1.50',
        otherNames: const {'Office'},
      );
      expect(errors.containsKey('name'), isFalse);
    });

    // FWDEV#213: 1.0 needs a gateway on LAN and Internet routes alike.
    test('empty gateway returns error, on either interface', () {
      for (final interfaceName in StaticRouteUIModel.interfaceOptions) {
        final errors = StaticRouteUIModel.validateRoute(
          name: 'Route1',
          destIp: '10.0.0.0',
          subnetMask: '255.255.255.0',
          gateway: '',
          interfaceName: interfaceName,
        );
        expect(errors['gateway'], StaticRoutingErrorKeys.gatewayRequired,
            reason: interfaceName);
      }
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
