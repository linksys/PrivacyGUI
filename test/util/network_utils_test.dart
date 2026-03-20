import 'package:privacy_gui/util/network_utils.dart';
import 'package:test/test.dart';

void main() {
  group('test ip conveter', () {
    test('test ip to num and convert back #1', () async {
      const ipAddress = '127.0.0.1';
      final num = NetworkUtils.ipToNum(ipAddress);
      expect(num, 127 * 256 * 256 * 256 + 0 * 256 * 256 + 0 * 256 + 1);
      expect(ipAddress, NetworkUtils.numToIp(num));
    });

    test('test ip to num and convert back #2', () async {
      const ipAddress = '255.255.255.0';
      final num = NetworkUtils.ipToNum(ipAddress);
      expect(num, 255 * 256 * 256 * 256 + 255 * 256 * 256 + 255 * 256 + 0);
      expect(ipAddress, NetworkUtils.numToIp(num));
    });

    test('test is valid subnet mask - 255.255.255.0', () async {
      const ipAddress = '255.255.255.0';
      expect(NetworkUtils.isValidSubnetMask(ipAddress), true);
    });

    test('test is valid subnet mask - 255.255.0.0', () async {
      const ipAddress = '255.255.0.0';
      expect(NetworkUtils.isValidSubnetMask(ipAddress), true);
    });

    test('test is valid subnet mask - 255.0.0.0', () async {
      const ipAddress = '255.0.0.0';
      expect(NetworkUtils.isValidSubnetMask(ipAddress), true);
    });

    test('test is invalid subnet mask - 255.1.0.0', () async {
      const ipAddress = '255.1.0.0';
      expect(NetworkUtils.isValidSubnetMask(ipAddress), false);
    });

    test('test is valid subnet mask - 255.254.0.0', () async {
      const ipAddress = '255.254.0.0';
      expect(NetworkUtils.isValidSubnetMask(ipAddress), true);
    });

    test('test is invalid subnet mask - 255.253.0.0', () async {
      const ipAddress = '255.253.0.0';
      expect(NetworkUtils.isValidSubnetMask(ipAddress), false);
    });

    test('test is valid subnet mask - 255.255.255.128', () async {
      const ipAddress = '255.255.255.128';
      expect(NetworkUtils.isValidSubnetMask(ipAddress), true);
    });

    test('test prefix length to subnet mask and convert back #1', () async {
      final actual = NetworkUtils.prefixLengthToSubnetMask(30);
      expect(actual, '255.255.255.252');
      expect(NetworkUtils.subnetMaskToPrefixLength(actual), 30);
    });

    test('test getMaxUserLimit', () async {
      expect(
          NetworkUtils.getMaxUserLimit(
              '192.168.1.1', '192.168.1.10', '255.255.255.0', 23),
          245);
      expect(
          NetworkUtils.getMaxUserLimit(
              '192.168.1.15', '192.168.1.10', '255.255.255.0', 23),
          244);
    });
  });

  group('Test Network Utils - formatBits', () {
    test('formatBits: formats zero bits correctly', () {
      const bits = 0;
      const expected = '0 b';

      final formattedBits = NetworkUtils.formatBits(bits);
      expect(formattedBits, expected);
    });

    test('formatBits: formats single-digit bits with specified decimals', () {
      const bits = 123;
      const expected = '123 b';

      final formattedBits = NetworkUtils.formatBits(bits, decimals: 0);
      expect(formattedBits, expected);
    });

    test('formatBits: formats bits in kilobytes range with specified decimals',
        () {
      const bits = 1234;
      const expected = '1.234 kb';

      final formattedBits = NetworkUtils.formatBits(bits, decimals: 3);
      expect(formattedBits, expected);
    });

    test('formatBits: formats bits in megabytes range with specified decimals',
        () {
      const bits = 1234567;
      const expected = '1.2346 Mb';

      final formattedBits = NetworkUtils.formatBits(bits, decimals: 4);
      expect(formattedBits, expected);
    });

    test('formatBits: formats bits in gigabytes range with specified decimals',
        () {
      const bits = 1234567890;
      const expected = '1.23 Gb';

      final formattedBits = NetworkUtils.formatBits(bits, decimals: 2);
      expect(formattedBits, expected);
    });

    test('formatBits: handles negative input', () {
      const expected = '0 b';

      final formattedBits = NetworkUtils.formatBits(-1);
      expect(formattedBits, expected);
    });

    test('formatBits: handles huge input (exceeding petabytes)', () {
      num bits = 1125899906842625; // 1 petabyte
      const expected = '1.13 Pb';

      final formattedBits = NetworkUtils.formatBits(bits.toInt(), decimals: 2);
      expect(formattedBits, expected);
    });
  });

  group('Test Network Utils - formatBitsWithUnit', () {
    test('returns 0 b for zero bytes', () {
      const bytes = 0;
      final result = NetworkUtils.formatBitsWithUnit(bytes);
      expect(result.value, '0');
      expect(result.unit, 'b');
    });

    test('returns 0 b for negative input', () {
      const bytes = -100;
      final result = NetworkUtils.formatBitsWithUnit(bytes);
      expect(result.value, '0');
      expect(result.unit, 'b');
    });

    test('formats bits (less than 1kb)', () {
      const bits = 500;
      final result = NetworkUtils.formatBitsWithUnit(bits);
      expect(result.value, '500');
      expect(result.unit, 'b');
    });

    test('formats kilobytes with 0 decimal places', () {
      const bits = 2000; // 2 kb
      final result = NetworkUtils.formatBitsWithUnit(bits);
      expect(result.value, '2');
      expect(result.unit, 'kb');
    });

    test('formats megabytes with 2 decimal places', () {
      const bits = 1.5 * 1000 * 1000; // 1.5 Mb
      final result = NetworkUtils.formatBitsWithUnit(bits.toInt(), decimals: 2);
      expect(result.value, '1.50');
      expect(result.unit, 'Mb');
    });

    test('formats gigabytes with 1 decimal place', () {
      const bits = 2.5 * 1000 * 1000 * 1000; // 2.5 Gb
      final result = NetworkUtils.formatBitsWithUnit(bits.toInt(), decimals: 1);
      expect(result.value, '2.5');
      expect(result.unit, 'Gb');
    });

    test('formats terabytes with 3 decimal places', () {
      const bits = 3.14159 * 1000 * 1000 * 1000 * 1000; // ~3.14159 Tb
      final result = NetworkUtils.formatBitsWithUnit(bits.toInt(), decimals: 3);
      expect(result.value, '3.142');
      expect(result.unit, 'Tb');
    });

    test('formats petabytes with 0 decimal places', () {
      const bits = 1000 * 1000 * 1000 * 1000 * 1000; // 1 Pb (SI)
      final result = NetworkUtils.formatBitsWithUnit(bits, decimals: 0);
      expect(result.value, '1');
      expect(result.unit, 'Pb');
    });

    test('handles exact power of 1000 values without decimal places', () {
      const bits = 1000 * 1000; // Exactly 1 Mb (SI)
      final result = NetworkUtils.formatBitsWithUnit(bits);
      expect(result.value, '1');
      expect(result.unit, 'Mb');
    });

    test('handles exactly 1 petabyte', () {
      final onePb = BigInt.from(1000).pow(5).toInt(); // Exactly 1 Pb (SI)
      final result = NetworkUtils.formatBitsWithUnit(onePb);
      expect(result.value, '1');
      expect(result.unit, 'Pb');
    });
  });

  group('Test Network Utils', () {
    test('isValidIpAddress: identifies valid IPv4 addresses', () {
      const validIps = ['192.168.1.1', '10.0.0.1', '255.255.255.255', '0.0.0.0'];
      for (final ip in validIps) {
        expect(NetworkUtils.isValidIpAddress(ip), true, reason: '$ip should be valid');
      }
    });

    test('isValidIpAddress: identifies invalid IP addresses', () {
      const invalidIps = ['invalid_ip', '192.168.1', '256.256.256.256', '1.2.3.4.5', '123.456', '-1.0.0.0', '0.256.0.0'];
      for (final ip in invalidIps) {
        expect(NetworkUtils.isValidIpAddress(ip), false, reason: '$ip should be invalid');
      }
    });

    test('isValidIpAddress: handles empty input', () {
      expect(NetworkUtils.isValidIpAddress(''), false);
    });

    test('ipToNum: converts valid IPv4 address to numerical representation', () {
      expect(NetworkUtils.ipToNum('192.168.1.1'), 3232235777);
    });

    test('ipToNum: handles leading zeros correctly', () {
      expect(NetworkUtils.ipToNum('010.020.003.001'), 169083649);
    });

    test('ipToNum: returns 0 for invalid IP addresses', () {
      for (final ip in ['invalid_ip', '192.168.1', '256.256.256.256', '1.2.3.4.5']) {
        expect(NetworkUtils.ipToNum(ip), 0);
      }
    });

    test('numToIp: converts valid numerical representation to IPv4 address', () {
      expect(NetworkUtils.numToIp(3232235521), '192.168.0.1');
    });

    test('numToIp: throws error for invalid input values', () {
      expect(NetworkUtils.numToIp(-1), '0.0.0.0');
      expect(NetworkUtils.numToIp(4294967296), '0.0.0.0');
    });

    test('ipInRange: correctly identifies address within range (inclusive)', () {
      expect(NetworkUtils.ipInRange('192.168.1.10', '192.168.1.1', '192.168.1.15'), true);
    });

    test('ipInRange: correctly identifies address at lower boundary', () {
      expect(NetworkUtils.ipInRange('192.168.1.1', '192.168.1.1', '192.168.1.10'), true);
    });

    test('ipInRange: correctly identifies address at upper boundary', () {
      expect(NetworkUtils.ipInRange('192.168.1.10', '192.168.1.1', '192.168.1.10'), true);
    });

    test('ipInRange: correctly identifies address outside range', () {
      expect(NetworkUtils.ipInRange('192.168.1.20', '192.168.1.1', '192.168.1.10'), false);
    });

    test('ipInRange: handles invalid IP addresses', () {
      expect(() => NetworkUtils.ipInRange('invalid_ip', '192.168.1.1', '192.168.1.10'), throwsArgumentError);
      expect(() => NetworkUtils.ipInRange('192.168.1.1', 'invalid_ip', '192.168.1.10'), throwsArgumentError);
      expect(() => NetworkUtils.ipInRange('192.168.1.1', '192.168.1.10', 'invalid_ip'), throwsArgumentError);
    });

    test('ipInRange: handles reversed range (min > max)', () {
      expect(() => NetworkUtils.ipInRange('192.168.1.5', '192.168.1.10', '192.168.1.5'), throwsArgumentError);
    });

    test('isValidSubnetMask: identifies valid subnet masks', () {
      for (final subnet in ['255.255.255.0', '255.255.255.128', '255.255.255.252', '255.0.0.0']) {
        expect(NetworkUtils.isValidSubnetMask(subnet), true, reason: '$subnet should be valid');
      }
    });

    test('isValidSubnetMask: identifies invalid subnet masks', () {
      const invalidSubnets = ['invalid_mask', '192.168.1', '256.256.256.256', '255.255.255.254', '255.255.255.191', '254.255.255.0', '0.0.0.0', '255.255.255.255'];
      for (final subnet in invalidSubnets) {
        var isValid = true;
        try { isValid = NetworkUtils.isValidSubnetMask(subnet); } catch (e) { isValid = false; }
        expect(isValid, false, reason: '$subnet should be invalid');
      }
    });

    test('isValidSubnetMask: handles empty input', () {
      expect(NetworkUtils.isValidSubnetMask(''), false);
    });

    test('throws exception for invalid maxNetworkPrefixLength', () {
      expect(() => NetworkUtils.isValidSubnetMask('255.255.255.0', maxNetworkPrefixLength: -1), throwsException);
    });

    test('isValidSubnetMask: throws error for invalid minNetworkPrefixLength', () {
      expect(() => NetworkUtils.isValidSubnetMask('255.255.255.0', minNetworkPrefixLength: 0), throwsException);
      expect(() => NetworkUtils.isValidSubnetMask('255.255.255.0', minNetworkPrefixLength: 32), throwsException);
    });

    test('isValidSubnetMask: throws error for invalid maxNetworkPrefixLength', () {
      expect(() => NetworkUtils.isValidSubnetMask('255.255.255.0', maxNetworkPrefixLength: 0), throwsException);
      expect(() => NetworkUtils.isValidSubnetMask('255.255.255.0', maxNetworkPrefixLength: 32), throwsException);
    });

    test('isValidSubnetMask: throws error for invalid min/max combination', () {
      expect(() => NetworkUtils.isValidSubnetMask('255.255.255.0', minNetworkPrefixLength: 24, maxNetworkPrefixLength: 23), throwsException);
    });

    test('isValidSubnetMask: handles valid subnet masks within specified range', () {
      expect(NetworkUtils.isValidSubnetMask('255.255.255.128', minNetworkPrefixLength: 25, maxNetworkPrefixLength: 27), true);
      expect(NetworkUtils.isValidSubnetMask('255.255.255.0', minNetworkPrefixLength: 24, maxNetworkPrefixLength: 24), true);
      expect(NetworkUtils.isValidSubnetMask('255.255.255.128', minNetworkPrefixLength: 25, maxNetworkPrefixLength: 30), true);
    });

    test('isValidSubnetMask: handles invalid subnet masks outside specified range', () {
      expect(() => NetworkUtils.isValidSubnetMask('255.255.255.128', minNetworkPrefixLength: 26, maxNetworkPrefixLength: 30), throwsA(isA<FormatException>()));
      expect(() => NetworkUtils.isValidSubnetMask('255.255.255.0', minNetworkPrefixLength: 25, maxNetworkPrefixLength: 30), throwsA(isA<FormatException>()));
    });

    test('getIpPrefix: calculates correct prefix for valid IP and subnet mask', () {
      expect(NetworkUtils.getIpPrefix('192.168.1.10', '255.255.255.0'), '192.168.1.0');
    });

    test('getIpPrefix: handles leading zeros in IP address', () {
      expect(NetworkUtils.getIpPrefix('010.020.003.001', '255.255.255.0'), '10.20.3.0');
    });

    test('getIpPrefix: handles invalid IP address', () {
      expect(() => NetworkUtils.getIpPrefix('invalid_ip', '255.255.255.0'), throwsArgumentError);
    });

    test('getIpPrefix: handles invalid subnet mask', () {
      expect(() => NetworkUtils.getIpPrefix('192.168.1.10', 'invalid_mask'), throwsArgumentError);
    });

    test('getIpPrefix: handles mismatched IP and subnet mask lengths', () {
      expect(() => NetworkUtils.getIpPrefix('192.168.1.10', '255.255'), throwsArgumentError);
    });

    test('getIpPrefix: handles non-contiguous subnet mask ones', () {
      expect(() => NetworkUtils.getIpPrefix('192.168.1.10', '255.255.255.191'), throwsArgumentError);
    });

    test('getMinMtu: returns correct minimum MTU for known WAN types', () {
      expect(NetworkUtils.getMinMtu('dhcp'), 576);
      expect(NetworkUtils.getMinMtu('DHCP'), 576);
      expect(NetworkUtils.getMinMtu('pppoe'), 576);
      expect(NetworkUtils.getMinMtu('static'), 576);
      expect(NetworkUtils.getMinMtu('pptp'), 576);
      expect(NetworkUtils.getMinMtu('l2tp'), 576);
    });

    test('getMinMtu: returns 0 for unknown WAN type', () {
      expect(NetworkUtils.getMinMtu('unknown'), 0);
      expect(NetworkUtils.getMinMtu(''), 0);
    });

    test('getMaxMtu: returns correct maximum MTU for known WAN types', () {
      expect(NetworkUtils.getMaxMtu('dhcp'), 1500);
      expect(NetworkUtils.getMaxMtu('DHCP'), 1500);
      expect(NetworkUtils.getMaxMtu('pppoe'), 1492);
      expect(NetworkUtils.getMaxMtu('static'), 1500);
      expect(NetworkUtils.getMaxMtu('pptp'), 1460);
      expect(NetworkUtils.getMaxMtu('l2tp'), 1460);
    });

    test('getMaxMtu: returns 0 for unknown WAN type', () {
      expect(NetworkUtils.getMaxMtu('unknown'), 0);
      expect(NetworkUtils.getMaxMtu(''), 0);
    });

    test('isMtuValid: returns true for MTU 0 regardless of WAN type', () {
      expect(NetworkUtils.isMtuValid('dhcp', 0), true);
      expect(NetworkUtils.isMtuValid('pppoe', 0), true);
      expect(NetworkUtils.isMtuValid('static', 0), true);
      expect(NetworkUtils.isMtuValid('pptp', 0), true);
      expect(NetworkUtils.isMtuValid('l2tp', 0), true);
      expect(NetworkUtils.isMtuValid('unknown', 0), true);
    });

    test('isMtuValid: returns true for valid MTU within range for DHCP', () {
      expect(NetworkUtils.isMtuValid('dhcp', 576), true);
      expect(NetworkUtils.isMtuValid('dhcp', 1000), true);
      expect(NetworkUtils.isMtuValid('dhcp', 1500), true);
    });

    test('isMtuValid: returns false for invalid MTU outside range for DHCP', () {
      expect(NetworkUtils.isMtuValid('dhcp', 575), false);
      expect(NetworkUtils.isMtuValid('dhcp', 1501), false);
    });

    test('isMtuValid: returns true for valid MTU within range for PPPoE', () {
      expect(NetworkUtils.isMtuValid('pppoe', 576), true);
      expect(NetworkUtils.isMtuValid('pppoe', 1000), true);
      expect(NetworkUtils.isMtuValid('pppoe', 1492), true);
    });

    test('isMtuValid: returns false for invalid MTU outside range for PPPoE', () {
      expect(NetworkUtils.isMtuValid('pppoe', 575), false);
      expect(NetworkUtils.isMtuValid('pppoe', 1500), false);
    });

    test('isMtuValid: returns true for valid MTU within range for Static', () {
      expect(NetworkUtils.isMtuValid('static', 576), true);
      expect(NetworkUtils.isMtuValid('static', 1000), true);
      expect(NetworkUtils.isMtuValid('static', 1500), true);
    });

    test('isMtuValid: returns false for invalid MTU outside range for Static', () {
      expect(NetworkUtils.isMtuValid('static', 575), false);
      expect(NetworkUtils.isMtuValid('static', 1501), false);
    });

    test('isMtuValid: returns true for valid MTU within range for PPTP', () {
      expect(NetworkUtils.isMtuValid('pptp', 576), true);
      expect(NetworkUtils.isMtuValid('pptp', 1000), true);
      expect(NetworkUtils.isMtuValid('pptp', 1460), true);
    });

    test('isMtuValid: returns false for invalid MTU outside range for PPTP', () {
      expect(NetworkUtils.isMtuValid('pptp', 575), false);
      expect(NetworkUtils.isMtuValid('pptp', 1461), false);
    });

    test('isMtuValid: returns true for valid MTU within range for L2TP', () {
      expect(NetworkUtils.isMtuValid('l2tp', 576), true);
      expect(NetworkUtils.isMtuValid('l2tp', 1000), true);
      expect(NetworkUtils.isMtuValid('l2tp', 1460), true);
    });

    test('isMtuValid: returns false for invalid MTU outside range for L2TP', () {
      expect(NetworkUtils.isMtuValid('l2tp', 575), false);
      expect(NetworkUtils.isMtuValid('l2tp', 1461), false);
    });

    test('isMtuValid: returns false for any non-zero MTU for unknown WAN type', () {
      expect(NetworkUtils.isMtuValid('unknown', 1), false);
      expect(NetworkUtils.isMtuValid('unknown', 1000), false);
      expect(NetworkUtils.isMtuValid('', 576), false);
    });
  });
}
