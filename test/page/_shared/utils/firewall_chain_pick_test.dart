import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/utils/firewall_chain_pick.dart';

void main() {
  group('defaultFirewallChainOf', () {
    test('picks the Defaults Configuration chain, wherever it is', () {
      final chains = [
        'UPnP Port Mapping (dynamic rules)',
        'Defaults Configuration'
      ];

      expect(
          defaultFirewallChainOf(chains, (c) => c), 'Defaults Configuration');
    });

    test('is null when the router lists no such chain', () {
      expect(
          defaultFirewallChainOf(
              ['UPnP Port Mapping (dynamic rules)'], (c) => c),
          isNull);
    });
  });
}
