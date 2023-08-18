import 'package:linksys_app/utils.dart';
import 'package:test/test.dart';

void main() {
  group('test ip conveter', () {
    test('test ip to num and convert back #1', () async {
      const ipAddress = '127.0.0.1';
      final num = Utils.ipToNum(ipAddress);
      expect(num, 127 * 256 * 256 * 256 + 0 * 256 * 256 + 0 * 256 + 1);
      expect(ipAddress, Utils.numToIp(num));
    });
    test('test ip to num and convert back #2', () async {
      const ipAddress = '255.255.255.0';
      final num = Utils.ipToNum(ipAddress);
      expect(num, 255 * 256 * 256 * 256 + 255 * 256 * 256 + 255 * 256 + 0);
      expect(ipAddress, Utils.numToIp(num));
    });
    test('test is valid subnet mask', () async {
      const ipAddress = '255.255.255.0';
      expect(Utils.isValidSubnetMask(ipAddress), true);
    });
    test('test prefix length to subnet mask and convert back #1', () async {
      final actual = Utils.prefixLengthToSubnetMask(30);
      expect(actual, '255.255.255.252');
      expect(Utils.subnetMaskToPrefixLength(actual), 30);
    });
  });
}
