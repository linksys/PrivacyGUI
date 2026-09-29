import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/usp/models/invalidation_domain.dart';

/// What is worth pinning about [InvalidationDomain], and what is not.
///
/// This file previously held three tests that could not fail for a reason anyone
/// would want to know about:
///
///   - `enum has 13 values` pinned the COUNT. Adding or removing a domain is normal
///     evolution, so that test went red for the change itself rather than for a
///     defect — pure friction during exactly the work that needs to touch this enum.
///   - `all values have unique names` asserted something the Dart compiler already
///     guarantees; two enum values cannot share a name. It could never fail, and it
///     pinned the count a second time as a side effect.
///   - `specific values exist` named all thirteen values. Each of those references
///     resolves at COMPILE time, so if a value were removed this file would not
///     compile and the test would never run. It tested the compiler.
///
/// The real invariant is the one the enum's own doc comments carry: **every domain
/// names the TR-181 subtree it stands for.** That is what makes the enum meaningful
/// rather than a bag of labels, and it is what `_mapToDomain` depends on. It is
/// asserted here as a mapping, so a new domain added without deciding its subtree
/// fails — which is a reason worth being red for.
///
/// The path→domain direction is covered separately and more precisely in
/// `test/core/usp/providers/sse_invalidation_provider_test.dart`; this file guards
/// the enum's own contract.
///
/// ONE THING THIS SHARES WITH THE OLD TESTS, KEPT DELIBERATELY. The `subtrees` map
/// below names every domain, so REMOVING a domain breaks compilation here — the same
/// mechanism that made `specific values exist` worthless. The difference is what the
/// compiler error asks you to do. There, it asked you to delete a line that asserted
/// nothing. Here, it tells you a second mapping exists and must be revisited, which
/// is the thing a removal would otherwise silently leave stale. Verified by mutation:
/// dropping `dmz` from the enum fails to compile, and adding a domain without a
/// subtree fails the first test at RUN time with a message saying what to do.
void main() {
  group('InvalidationDomain', () {
    // Each domain and the TR-181 subtree it stands for, transcribed from the doc
    // comments in `invalidation_domain.dart`. Adding a domain without adding it here
    // fails the exhaustiveness check below.
    const subtrees = <InvalidationDomain, String>{
      InvalidationDomain.connectedDevices: 'Device.Hosts.Host.',
      InvalidationDomain.wifiSsids: 'Device.WiFi.SSID.',
      InvalidationDomain.wifiRadios: 'Device.WiFi.Radio.',
      InvalidationDomain.portForwarding: 'Device.NAT.PortMapping.',
      InvalidationDomain.firewallRules: 'Device.Firewall.Chain.',
      InvalidationDomain.dhcpReservations:
          'Device.DHCPv4.Server.Pool.1.StaticAddress.',
      InvalidationDomain.dmz: 'Device.Firewall.DMZ.',
      InvalidationDomain.staticRouting:
          'Device.Routing.Router.1.IPv4Forwarding.',
      InvalidationDomain.wifiAccessPoints: 'Device.WiFi.AccessPoint.',
      InvalidationDomain.dhcpClients: 'Device.DHCPv4.Server.Pool.1.Client.',
      InvalidationDomain.wifiClients:
          'Device.WiFi.AccessPoint.*.AssociatedDevice.',
      InvalidationDomain.ethernetInterfaces: 'Device.Ethernet.Interface.',
      InvalidationDomain.wanStatus: 'Device.IP.Interface.',
    };

    test('every domain declares the TR-181 subtree it stands for', () {
      final undeclared = InvalidationDomain.values
          .where((d) => !subtrees.containsKey(d))
          .map((d) => d.name)
          .toList();
      expect(
        undeclared,
        isEmpty,
        reason:
            'a domain was added without recording its TR-181 subtree. Add it '
            'to `subtrees` above, and give `_mapToDomain` a branch plus a test in '
            'sse_invalidation_provider_test.dart — a domain nothing maps to is '
            'unreachable.',
      );
    });

    test('every declared subtree is rooted at Device.', () {
      for (final entry in subtrees.entries) {
        expect(
          entry.value,
          startsWith('Device.'),
          reason: '${entry.key.name} does not name a TR-181 path',
        );
      }
    });

    test('no two domains claim the same subtree', () {
      // Two domains CAN share a prefix — `wifiAccessPoints` and `wifiClients` do,
      // and `_mapToDomain` separates them by the longer path winning. What must not
      // happen is two domains claiming the IDENTICAL subtree, which would make the
      // mapping arbitrary.
      final seen = <String, InvalidationDomain>{};
      for (final entry in subtrees.entries) {
        final clash = seen[entry.value];
        expect(
          clash,
          isNull,
          reason: '${entry.key.name} and ${clash?.name} both claim '
              '${entry.value}; `_mapToDomain` could only pick one',
        );
        seen[entry.value] = entry.key;
      }
    });
  });
}
