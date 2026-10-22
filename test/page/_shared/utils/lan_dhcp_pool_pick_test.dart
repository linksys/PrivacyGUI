import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/utils/lan_dhcp_pool_pick.dart';

void main() {
  group('lanDhcpPoolOf', () {
    test('picks the pool whose Alias is dhcp-lan, wherever it is', () {
      final pools = [('cpe-2', 'guest'), ('dhcp-lan', 'lan')];

      expect(lanDhcpPoolOf(pools, (p) => p.$1), ('dhcp-lan', 'lan'));
    });

    test('is null when no pool is the LAN pool', () {
      expect(lanDhcpPoolOf([('cpe-2', 'guest')], (p) => p.$1), isNull);
    });
  });
}
