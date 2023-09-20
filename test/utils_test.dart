import 'package:linksys_app/utils.dart';
import 'package:test/test.dart';

// TODO test supported languages
void main() {
  group('test string converter', () {
    test('test encoded English', () async {
      const test = 'Timmy';
      final encoded = Utils.fullStringEncoded(test);
      expect(Utils.fullStringDecoded(encoded), test);
    });
    test('test encoded emoji', () async {
      const test = '😂😂😂';
      final encoded = Utils.fullStringEncoded(test);
      expect(Utils.fullStringDecoded(encoded), test);
    });
    test('test encoded Chinese', () async {
      const test = '中文';
      final encoded = Utils.fullStringEncoded(test);
      expect(Utils.fullStringDecoded(encoded), test);
    });
    test('test encoded Tai', () async {
      const test = 'ทดสอบ';
      final encoded = Utils.fullStringEncoded(test);
      expect(Utils.fullStringDecoded(encoded), test);
    });
  });
  group('test json mask', () {
    test('username case', () async {
      const str = '''
        [I] TIME: 2022-08-10T08:46:51.856634 
        REQUEST---------------------------------------------------
        URL: https://qa-us1-api.linksys.cloud/v1/auth/login/prepare, METHOD: POST
        HEADERS: {content-type: application/json; charset=utf-8, accept: application/json}
        BODY: {"username":"austin.chang@gmail.com"}
        ---------------------------------------------------REQUEST END
      ''';
      final actual = Utils.maskJsonValue(str, ['username']);
      expect(actual.indexOf('austin.chang@gmail.com'), -1);
    });

    test('password case', () async {
      const str = '''
        [I] TIME: 2022-08-09T23:27:33.687797
        REQUEST---------------------------------------------------
        URL: https://qa-us1-api.linksys.cloud/v1/auth/login/password, METHOD: POST
        HEADERS: {content-type: application/json; charset=utf-8, accept: application/json}
        BODY: {"token":"4EE7E2CE-356D-4538-B769-FEB4D41FB05C","password":"Linksys123!"}
        ---------------------------------------------------REQUEST END
      ''';
      final actual = Utils.maskJsonValue(str, ['password']);
      expect(actual.indexOf('Linksys123!'), -1);
    });

  });

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
