import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/firewall/models/firewall_verdict.dart';

/// The verdict the mascot's security dimension and the Firewall card's badge
/// both show (#1130). Expected values are the four states the 11-09 comment
/// names, case by case.
void main() {
  group('FirewallVerdict.of', () {
    test('both SPI firewalls on and DMZ off is Protected', () {
      expect(
        FirewallVerdict.of(ipv4SpiOn: true, ipv6SpiOn: true, dmzOn: false),
        FirewallVerdict.protected,
      );
    });

    test('IPv6 SPI off on its own is Basic', () {
      expect(
        FirewallVerdict.of(ipv4SpiOn: true, ipv6SpiOn: false, dmzOn: false),
        FirewallVerdict.basic,
      );
    });

    test('DMZ on with IPv4 SPI on is DMZ Active, whatever IPv6 is', () {
      expect(
        FirewallVerdict.of(ipv4SpiOn: true, ipv6SpiOn: true, dmzOn: true),
        FirewallVerdict.dmzActive,
      );
      expect(
        FirewallVerdict.of(ipv4SpiOn: true, ipv6SpiOn: false, dmzOn: true),
        FirewallVerdict.dmzActive,
      );
    });

    test('IPv4 SPI off is At Risk, and wins over DMZ', () {
      expect(
        FirewallVerdict.of(ipv4SpiOn: false, ipv6SpiOn: true, dmzOn: false),
        FirewallVerdict.atRisk,
      );
      expect(
        FirewallVerdict.of(ipv4SpiOn: false, ipv6SpiOn: false, dmzOn: true),
        FirewallVerdict.atRisk,
      );
    });
  });
}
