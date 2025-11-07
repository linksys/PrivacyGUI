import 'package:privacy_gui/utils.dart';
import 'package:test/test.dart';
import 'package:privacy_gui/core/utils/fernet_manager.dart';

import 'test_data/const_test_data.dart';

// TODO test supported languages
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

  group('test mask value', () {
    test('maskJsonValue: masks correctly single key in JSON string', () {
      const rawJson =
          '{"name": "John Doe", "age": 30, "address": "123 Main St."}';
      const keys = ['name'];
      const expected =
          '{"name": "************", "age": 30, "address": "123 Main St."}';

      final maskedJson = Utils.maskJsonValue(rawJson, keys);
      expect(maskedJson, expected);
    });

    test('maskJsonValue: masks correctly multiple keys in JSON string', () {
      const rawJson =
          '{"name": "John Doe", "age": 30, "address": "123 Main St.", "phone": "555-1212"}';
      const keys = ['name', 'phone'];
      const expected =
          '{"name": "************", "age": 30, "address": "123 Main St.", "phone": "************"}';

      final maskedJson = Utils.maskJsonValue(rawJson, keys);
      expect(maskedJson, expected);
    });

    test('maskJsonValue: handles empty keys list', () {
      const rawJson = '{"name": "John Doe", "age": 30}';
      const List<String> keys = [];
      const expected = rawJson; // No masking should occur

      final maskedJson = Utils.maskJsonValue(rawJson, keys);
      expect(maskedJson, expected);
    });

    test('maskJsonValue: handles invalid JSON format', () {
      const rawJson = 'invalid json';
      const keys = ['name'];

      final maskedJson = Utils.maskJsonValue(rawJson, keys);
      expect(maskedJson, rawJson);
    });

    test('maskJsonValue: username case', () async {
      final actual = Utils.maskJsonValue(sensitiveUsername, ['username']);
      expect(actual.indexOf('austin.chang@gmail.com'), -1);
    });

    test('maskJsonValue: password case', () async {
      final actual = Utils.maskJsonValue(sensitivePassword, ['password']);
      expect(actual.indexOf('Linksys123!'), -1);
    });

    test('maskUsernamePasswordBodyValue', () async {
      final actual = Utils.maskUsernamePasswordBodyValue(
          cloudLoginWithUsernamePasswordRequest);
      print(actual);
      expect(actual.indexOf('hank.yu%40linksys.com'), -1);
      expect(actual.indexOf('Linksys123%21'), -1);
    });

    test(
        'maskSensitiveJsonValues: masks specified keys correctly in JSON string',
        () {
      const rawJson =
          '{"username": "john_doe", "password": "123456", "email": "john.doe@example.com"}';
      const expected =
          '{"username": "************", "password": "************", "email": "john.doe@example.com"}';

      final maskedJson = Utils.maskSensitiveJsonValues(rawJson);
      expect(maskedJson, expected);
    });

    test('maskSensitiveJsonValues: handles empty JSON string', () {
      const rawJson = '';
      const expected = rawJson; // No masking should occur

      final maskedJson = Utils.maskSensitiveJsonValues(rawJson);
      expect(maskedJson, expected);
    });

    test('maskSensitiveJsonValues: handles invalid JSON format', () {
      const rawJson = 'invalid json';
      const expected = rawJson; // No masking should occur

      final maskedJson = Utils.maskSensitiveJsonValues(rawJson);
      expect(maskedJson, expected);
    });

    test('replaceHttpScheme: replaces http scheme correctly', () {
      const raw = 'https://www.example.com/path/to/resource';
      const expected =
          'https-//www-example-com/path/to/resource'; // Replaced ':' and '.' with '-'

      final result = Utils.replaceHttpScheme(raw);
      expect(result, expected);
    });

    test('replaceHttpScheme: replaces https scheme correctly', () {
      const raw = 'https://secure.example.com/login';
      const expected = 'https-//secure-example-com/login';

      final result = Utils.replaceHttpScheme(raw);
      expect(result, expected);
    });

    test('replaceHttpScheme: handles naked domain URL', () {
      const raw = 'www.google.com';
      const expected = 'www-google-com';

      final result = Utils.replaceHttpScheme(raw);
      expect(result, expected);
    });

    test('replaceHttpScheme: handles missing scheme', () {
      const raw = '//www.example.com/path';
      const expected = '//www-example-com/path';

      final result = Utils.replaceHttpScheme(raw);
      expect(result, expected);
    });

    test('replaceHttpScheme: handles empty string', () {
      const raw = '';
      const expected = '';

      final result = Utils.replaceHttpScheme(raw);
      expect(result, expected);
    });

    test('replaceHttpScheme: handles multiple occurrences', () {
      const raw =
          'https://example1.com:8080/path1 https://example2.com:443/path2';
      const expected =
          'https-//example1-com-8080/path1 https-//example2-com-443/path2';

      final result = Utils.replaceHttpScheme(raw);
      expect(result, expected);
    });

    test('replaceHttpScheme: handles invalid URL format', () {
      const raw = 'invalid_url';
      const expected = raw;

      final result = Utils.replaceHttpScheme(raw);
      expect(result, expected);
    });

    test('replaceHttpScheme: URL in http request', () async {
      final actual = Utils.replaceHttpScheme(selfNetworksHttpRequest);
      expect(
          actual.indexOf(
              'https://qa.linksyssmartwifi.com/cloud/device-service/rest/accounts/self/networks'),
          -1);
      expect(
          actual.indexOf(
                  'https-//qa-linksyssmartwifi-com/cloud/device-service/rest/accounts/self/networks') >
              1,
          true);
    });
    test('replaceHttpScheme: URL in http response', () async {
      final actual =
          Utils.replaceHttpScheme(isAdminPasswordDefaultHttpResponse);
      expect(
          actual.indexOf('http://linksys.com/jnap/core/IsAdminPasswordDefault'),
          -1);
      expect(
          actual.indexOf(
                  'http-//linksys-com/jnap/core/IsAdminPasswordDefault') >
              1,
          true);
    });

    test('replaceHttpScheme: URL in cache data', () async {
      final actual = Utils.replaceHttpScheme(pollingResponseCache);

      expect(actual.indexOf('http://linksys.com/jnap/'), -1);
    });
  });

  group('test string encode/decode', () {
    test('stringBase64Encode: encodes string to Base64 correctly', () {
      const value = 'Hello, world!';
      const expected = 'SGVsbG8sIHdvcmxkIQ==';

      final encoded = Utils.stringBase64Encode(value);
      expect(encoded, expected);
    });

    test('stringBase64Encode: handles empty string', () {
      const value = '';
      const expected = ''; // Empty string should result in empty Base64

      final encoded = Utils.stringBase64Encode(value);
      expect(encoded, expected);
    });

    test('stringBase64Encode: handles multibyte characters', () {
      const value = '日本語';
      const expected = '5pel5pys6Kqe';

      final encoded = Utils.stringBase64Encode(value);
      expect(encoded, expected);
    });

    test('stringBase64Decode: decodes Base64 string correctly', () {
      const base64String = 'SGVsbG8sIHdvcmxkIQ==';
      const expected = 'Hello, world!';

      final decoded = Utils.stringBase64Decode(base64String);
      expect(decoded, expected);
    });

    test('fullStringDecoded: handles invalid Base64 string', () {
      const invalidEncoded = 'invalid_base64';

      expect(
          () => Utils.fullStringDecoded(invalidEncoded), throwsFormatException);
    });
  });

  group('test date format utils', () {
    test('formatDuration: formats simple duration correctly', () {
      const duration = Duration(hours: 1, minutes: 30, seconds: 15);
      const expected = '1h 30m 15s';

      final formatted = DateFormatUtils.formatDuration(duration);
      expect(formatted, expected);
    });

    test('formatDuration: formats duration with multiple units', () {
      const duration = Duration(days: 2, hours: 5, minutes: 20, seconds: 30);
      const expected = '2d 5h 20m 30s';

      final formatted = DateFormatUtils.formatDuration(duration);
      expect(formatted, expected);
    });

    test('formatDuration: formats zero-value durations', () {
      const duration = Duration.zero;
      const expected = '0s';

      final formatted = DateFormatUtils.formatDuration(duration);
      expect(formatted, expected);
    });

    test('formatDuration: handles duration exceeding day unit', () {
      const duration = Duration(days: 100);
      const expected = '100d 0h 0m 0s';

      final formatted = DateFormatUtils.formatDuration(duration);
      expect(formatted, expected);
    });

    test('formatTimeMSS: formats single-digit minutes correctly', () {
      const timeInSecond = 123; // 2 minutes 3 seconds
      const expected = '2:03';

      final formattedTime = DateFormatUtils.formatTimeMSS(timeInSecond);
      expect(formattedTime, expected);
    });

    test('formatTimeMSS: formats double-digit minutes correctly', () {
      const timeInSecond = 620; // 10 minutes 20 seconds
      const expected = '10:20';

      final formattedTime = DateFormatUtils.formatTimeMSS(timeInSecond);
      expect(formattedTime, expected);
    });

    test('formatTimeMSS: formats zero minutes correctly', () {
      const timeInSecond = 59; // 59 seconds
      const expected = '0:59';

      final formattedTime = DateFormatUtils.formatTimeMSS(timeInSecond);
      expect(formattedTime, expected);
    });

    test('formatTimeAmPm: formats single-digit hours correctly', () {
      const timeInSecond = 3600; // 1:00 AM
      const expected = '01:00 am';

      final formattedTime = DateFormatUtils.formatTimeAmPm(timeInSecond);
      expect(formattedTime, expected);
    });

    test('formatTimeAmPm: formats double-digit hours correctly', () {
      const timeInSecond = 57600; // 4:00 PM
      const expected = '04:00 pm';

      final formattedTime = DateFormatUtils.formatTimeAmPm(timeInSecond);
      expect(formattedTime, expected);
    });

    test('formatTimeAmPm: formats midnight correctly', () {
      const timeInSecond = 0;
      const expected = '00:00 am';

      final formattedTime = DateFormatUtils.formatTimeAmPm(timeInSecond);
      expect(formattedTime, expected);
    });

    test('formatTimeAmPm: formats midday correctly', () {
      const timeInSecond = 43200; // 12:00 PM
      const expected = '12:00 pm';

      final formattedTime = DateFormatUtils.formatTimeAmPm(timeInSecond);
      expect(formattedTime, expected);
    });

    // test('formatTimeAmPm: handles negative input', () {
    //   expect(() => DateFormatUtils.formatTimeAmPm(-1), throwsArgumentError);
    // });

    // test('formatTimeAmPm: handles large input (exceeding 24 hours)', () {
    //   const timeInSecond = 86400 * 2; // 48 hours
    //   const expected = '12:00 PM next day'; // Should reset to midday and indicate next day

    //   final formattedTime = DateFormatUtils.formatTimeAmPm(timeInSecond);
    //   expect(formattedTime, expected);
    // });

    test('formatTimeInterval: formats same-day time interval correctly', () {
      const startTimeInSecond = 61200; // 5 PM
      const endTimeInSecond = 67500; // 6:45 PM
      const expected = '05:00 pm - 06:45 pm';

      final formattedInterval = DateFormatUtils.formatTimeInterval(
          startTimeInSecond, endTimeInSecond);
      expect(formattedInterval, expected);
    });

    test('formatTimeInterval: formats next-day time interval correctly', () {
      const startTimeInSecond = 86340; // 11:59 PM
      const endTimeInSecond = 3600; // 1:00 AM
      const expected = '11:59 pm - 01:00 am next day';

      final formattedInterval = DateFormatUtils.formatTimeInterval(
          startTimeInSecond, endTimeInSecond);
      expect(formattedInterval, expected);
    });

    test(
        'formatTimeInterval: formats time interval spanning midnight correctly',
        () {
      const startTimeInSecond = 79200; // 10 PM
      const endTimeInSecond = 10800; // 3 AM
      const expected = '10:00 pm - 03:00 am next day';

      final formattedInterval = DateFormatUtils.formatTimeInterval(
          startTimeInSecond, endTimeInSecond);
      expect(formattedInterval, expected);
    });

    test('formatTimeInterval: handles equal start and end times', () {
      const startTimeInSecond = 43200; // 12:00 PM
      const endTimeInSecond = 43200; // 12:00 PM
      const expected = '12:00 pm - 12:00 pm';

      final formattedInterval = DateFormatUtils.formatTimeInterval(
          startTimeInSecond, endTimeInSecond);
      expect(formattedInterval, expected);
    });

    test('formatTimeHM: formats single-digit hours correctly', () {
      const timeInSecond = 3600; // 1 hour
      const expected = '01 hr,00 min';

      final formattedTime = DateFormatUtils.formatTimeHM(timeInSecond);
      expect(formattedTime, expected);
    });

    test('formatTimeHM: formats double-digit hours correctly', () {
      const timeInSecond = 14400; // 4 hours
      const expected = '04 hr,00 min';

      final formattedTime = DateFormatUtils.formatTimeHM(timeInSecond);
      expect(formattedTime, expected);
    });

    test('formatTimeHM: formats single-digit minutes correctly', () {
      const timeInSecond = 60; // 1 minute
      const expected = '00 hr,01 min';

      final formattedTime = DateFormatUtils.formatTimeHM(timeInSecond);
      expect(formattedTime, expected);
    });

    test('formatTimeHM: formats double-digit minutes correctly', () {
      const timeInSecond = 1200; // 20 minutes
      const expected = '00 hr,20 min';

      final formattedTime = DateFormatUtils.formatTimeHM(timeInSecond);
      expect(formattedTime, expected);
    });

    test('formatTimeHM: formats zero time correctly', () {
      const timeInSecond = 0;
      const expected = '00 hr,00 min';

      final formattedTime = DateFormatUtils.formatTimeHM(timeInSecond);
      expect(formattedTime, expected);
    });

    // test('formatTimeHM: handles negative input', () {
    //   expect(() => DateFormatUtils.formatTimeHM(-1), throwsArgumentError);
    // });

    test('formatTimeHM: handles large input (exceeding 24 hours)', () {
      const timeInSecond = 86400 * 2; // 48 hours
      const expected = '48 hr,00 min'; // Resets to 0 minutes after 24 hours

      final formattedTime = DateFormatUtils.formatTimeHM(timeInSecond);
      expect(formattedTime, expected);
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
      const expected = '1.205 Kb';

      final formattedBits = NetworkUtils.formatBits(bits, decimals: 3);
      expect(formattedBits, expected);
    });

    test('formatBits: formats bits in megabytes range with specified decimals',
        () {
      const bits = 1234567;
      const expected = '1.1774 Mb';

      final formattedBits = NetworkUtils.formatBits(bits, decimals: 4);
      expect(formattedBits, expected);
    });

    test('formatBits: formats bits in gigabytes range with specified decimals',
        () {
      const bits = 1234567890;
      const expected = '1.15 Gb';

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
      const expected = '1.00 Pb';

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

    test('formats bits (less than 1Kb)', () {
      const bits = 500;
      final result = NetworkUtils.formatBitsWithUnit(bits);
      expect(result.value, '500');
      expect(result.unit, 'b');
    });

    test('formats kilobytes with 0 decimal places', () {
      const bits = 2048; // 2 Kb
      final result = NetworkUtils.formatBitsWithUnit(bits);
      expect(result.value, '2');
      expect(result.unit, 'Kb');
    });

    test('formats megabytes with 2 decimal places', () {
      const bits = 1.5 * 1024 * 1024; // 1.5 Mb
      final result = NetworkUtils.formatBitsWithUnit(bits.toInt(), decimals: 2);
      expect(result.value, '1.50');
      expect(result.unit, 'Mb');
    });

    test('formats gigabytes with 1 decimal place', () {
      const bits = 2.5 * 1024 * 1024 * 1024; // 2.5 Gb
      final result = NetworkUtils.formatBitsWithUnit(bits.toInt(), decimals: 1);
      expect(result.value, '2.5');
      expect(result.unit, 'Gb');
    });

    test('formats terabytes with 3 decimal places', () {
      const bits = 3.14159 * 1024 * 1024 * 1024 * 1024; // ~3.14159 Tb
      final result = NetworkUtils.formatBitsWithUnit(bits.toInt(), decimals: 3);
      expect(result.value, '3.142');
      expect(result.unit, 'Tb');
    });

    test('formats petabytes with 0 decimal places', () {
      const bits = 1024 * 1024 * 1024 * 1024 * 1024; // 1 Pb
      final result = NetworkUtils.formatBitsWithUnit(bits, decimals: 0);
      expect(result.value, '1');
      expect(result.unit, 'Pb');
    });

    test('handles exact power of 1024 values without decimal places', () {
      const bits = 1024 * 1024; // Exactly 1 Mb
      final result = NetworkUtils.formatBitsWithUnit(bits);
      expect(result.value, '1');
      expect(result.unit, 'Mb');
    });

    test('handles exactly 1 petabyte', () {
      final onePb = BigInt.from(1024).pow(5).toInt(); // Exactly 1 PiB
      final result = NetworkUtils.formatBitsWithUnit(onePb);
      expect(result.value, '1');
      expect(result.unit, 'Pb');
    });
  });
  group('Test Network Utils', () {
    test('isValidIpAddress: identifies valid IPv4 addresses', () {
      const validIps = [
        '192.168.1.1',
        '10.0.0.1',
        '255.255.255.255',
        '0.0.0.0',
      ];

      for (final ip in validIps) {
        final isValid = NetworkUtils.isValidIpAddress(ip);
        expect(isValid, true, reason: '$ip should be valid');
      }
    });

    test('isValidIpAddress: identifies invalid IP addresses', () {
      const invalidIps = [
        'invalid_ip', // Not in dotted-quad format
        '192.168.1', // Missing last octet
        '256.256.256.256', // Octets exceed valid range
        '1.2.3.4.5', // Too many octets
        '123.456', // Missing dots
        '-1.0.0.0', // Negative octet
        '0.256.0.0', // Octets exceeding range
      ];

      for (final ip in invalidIps) {
        final isValid = NetworkUtils.isValidIpAddress(ip);
        expect(isValid, false, reason: '$ip should be invalid');
      }
    });

    test('isValidIpAddress: handles empty input', () {
      expect(NetworkUtils.isValidIpAddress(''), false);
    });

    test('ipToNum: converts valid IPv4 address to numerical representation',
        () {
      const ipAddress = '192.168.1.1';
      const expected = 3232235777;

      final num = NetworkUtils.ipToNum(ipAddress);
      expect(num, expected);
    });

    test('ipToNum: handles leading zeros correctly', () {
      const ipAddress = '010.020.003.001';
      const expected = 169083649;

      final num = NetworkUtils.ipToNum(ipAddress);
      expect(num, expected);
    });

    test('ipToNum: returns 0 for invalid IP addresses', () {
      const invalidIps = [
        'invalid_ip', // Not in dotted-quad format
        '192.168.1', // Missing last octet
        '256.256.256.256', // Octets exceed valid range
        '1.2.3.4.5', // Too many octets
      ];

      for (final ip in invalidIps) {
        final num = NetworkUtils.ipToNum(ip);
        expect(num, 0);
      }
    });

    test('numToIp: converts valid numerical representation to IPv4 address',
        () {
      const num = 3232235521;
      const expected = '192.168.0.1';

      final ipAddress = NetworkUtils.numToIp(num);
      expect(ipAddress, expected);
    });

    test('numToIp: throws error for invalid input values', () {
      const expected = '0.0.0.0';
      expect(NetworkUtils.numToIp(-1), expected);
      expect(NetworkUtils.numToIp(4294967296), expected);
    });

    test('ipInRange: correctly identifies address within range (inclusive)',
        () {
      const ipAddress = '192.168.1.10';
      const ipAddressMin = '192.168.1.1';
      const ipAddressMax = '192.168.1.15';

      final isIn =
          NetworkUtils.ipInRange(ipAddress, ipAddressMin, ipAddressMax);
      expect(isIn, true);
    });

    test('ipInRange: correctly identifies address at lower boundary', () {
      const ipAddress = '192.168.1.1';
      const ipAddressMin = '192.168.1.1';
      const ipAddressMax = '192.168.1.10';

      final isIn =
          NetworkUtils.ipInRange(ipAddress, ipAddressMin, ipAddressMax);
      expect(isIn, true);
    });

    test('ipInRange: correctly identifies address at upper boundary', () {
      const ipAddress = '192.168.1.10';
      const ipAddressMin = '192.168.1.1';
      const ipAddressMax = '192.168.1.10';

      final isIn =
          NetworkUtils.ipInRange(ipAddress, ipAddressMin, ipAddressMax);
      expect(isIn, true);
    });

    test('ipInRange: correctly identifies address outside range', () {
      const ipAddress = '192.168.1.20';
      const ipAddressMin = '192.168.1.1';
      const ipAddressMax = '192.168.1.10';

      final isIn =
          NetworkUtils.ipInRange(ipAddress, ipAddressMin, ipAddressMax);
      expect(isIn, false);
    });

    test('ipInRange: handles invalid IP addresses', () {
      const invalidIp = 'invalid_ip';
      const ipAddressMin = '192.168.1.1';
      const ipAddressMax = '192.168.1.10';

      expect(
          () => NetworkUtils.ipInRange(invalidIp, ipAddressMin, ipAddressMax),
          throwsArgumentError);
      expect(
          () => NetworkUtils.ipInRange(ipAddressMin, invalidIp, ipAddressMax),
          throwsArgumentError);
      expect(
          () => NetworkUtils.ipInRange(ipAddressMin, ipAddressMax, invalidIp),
          throwsArgumentError);
    });

    test('ipInRange: handles reversed range (min > max)', () {
      const ipAddress = '192.168.1.5';
      const ipAddressMin = '192.168.1.10';
      const ipAddressMax = '192.168.1.5';

      expect(
          () => NetworkUtils.ipInRange(ipAddress, ipAddressMin, ipAddressMax),
          throwsArgumentError);
    });

    test('isValidSubnetMask: identifies valid subnet masks', () {
      const validSubnets = [
        '255.255.255.0',
        '255.255.255.128',
        '255.255.255.252',
        '255.0.0.0',
      ];

      for (final subnet in validSubnets) {
        final isValid = NetworkUtils.isValidSubnetMask(subnet);
        expect(isValid, true, reason: '$subnet should be valid');
      }
    });

    test('isValidSubnetMask: identifies invalid subnet masks', () {
      const invalidSubnets = [
        'invalid_mask', // Not an IP address
        '192.168.1', // Missing octets
        '256.256.256.256', // Invalid octet values
        '255.255.255.254', // Not a contiguous sequence of ones
        '255.255.255.191', // Not a power of 2
        '254.255.255.0', // Leading bits not all ones
        '0.0.0.0', // All zeros
        '255.255.255.255', // All ones
      ];

      for (final subnet in invalidSubnets) {
        var isValid = true;
        try {
          isValid = NetworkUtils.isValidSubnetMask(subnet);
        } catch (e) {
          isValid = false;
        }
        expect(isValid, false, reason: '$subnet should be invalid');
      }
    });

    test('isValidSubnetMask: handles empty input', () {
      expect(NetworkUtils.isValidSubnetMask(''), false);
    });

    test('throws exception for invalid maxNetworkPrefixLength', () {
      expect(
          () => NetworkUtils.isValidSubnetMask('255.255.255.0',
              maxNetworkPrefixLength: -1),
          throwsException);
    });

    test('isValidSubnetMask: throws error for invalid minNetworkPrefixLength',
        () {
      expect(
          () => NetworkUtils.isValidSubnetMask('255.255.255.0',
              minNetworkPrefixLength: 0),
          throwsException);
      expect(
          () => NetworkUtils.isValidSubnetMask('255.255.255.0',
              minNetworkPrefixLength: 32),
          throwsException);
    });

    test('isValidSubnetMask: throws error for invalid maxNetworkPrefixLength',
        () {
      expect(
          () => NetworkUtils.isValidSubnetMask('255.255.255.0',
              maxNetworkPrefixLength: 0),
          throwsException);
      expect(
          () => NetworkUtils.isValidSubnetMask('255.255.255.0',
              maxNetworkPrefixLength: 32),
          throwsException);
    });

    test('isValidSubnetMask: throws error for invalid min/max combination', () {
      expect(
          () => NetworkUtils.isValidSubnetMask('255.255.255.0',
              minNetworkPrefixLength: 24, maxNetworkPrefixLength: 23),
          throwsException);
    });

    test('isValidSubnetMask: handles valid subnet masks within specified range',
        () {
      expect(
          NetworkUtils.isValidSubnetMask('255.255.255.128',
              minNetworkPrefixLength: 25, maxNetworkPrefixLength: 27),
          true);
      expect(
          NetworkUtils.isValidSubnetMask('255.255.255.0',
              minNetworkPrefixLength: 24, maxNetworkPrefixLength: 24),
          true);
      expect(
          NetworkUtils.isValidSubnetMask('255.255.255.128',
              minNetworkPrefixLength: 25, maxNetworkPrefixLength: 30),
          true);
    });

    test(
        'isValidSubnetMask: handles invalid subnet masks outside specified range',
        () {
      expect(
          () => NetworkUtils.isValidSubnetMask('255.255.255.128',
              minNetworkPrefixLength: 26, maxNetworkPrefixLength: 30),
          throwsA(isA<FormatException>()));
      expect(
          () => NetworkUtils.isValidSubnetMask('255.255.255.0',
              minNetworkPrefixLength: 25, maxNetworkPrefixLength: 30),
          throwsA(isA<FormatException>()));
    });

    test('getIpPrefix: calculates correct prefix for valid IP and subnet mask',
        () {
      const ipAddress = '192.168.1.10';
      const subnetMask = '255.255.255.0';
      const expectedPrefix = '192.168.1.0';

      final prefix = NetworkUtils.getIpPrefix(ipAddress, subnetMask);
      expect(prefix, expectedPrefix);
    });

    test('getIpPrefix: handles leading zeros in IP address', () {
      const ipAddress = '010.020.003.001';
      const subnetMask = '255.255.255.0';
      const expectedPrefix = '10.20.3.0';

      final prefix = NetworkUtils.getIpPrefix(ipAddress, subnetMask);
      expect(prefix, expectedPrefix);
    });

    test('getIpPrefix: handles invalid IP address', () {
      const invalidIp = 'invalid_ip';
      const subnetMask = '255.255.255.0';

      expect(() => NetworkUtils.getIpPrefix(invalidIp, subnetMask),
          throwsArgumentError);
    });

    test('getIpPrefix: handles invalid subnet mask', () {
      const ipAddress = '192.168.1.10';
      const invalidMask = 'invalid_mask';

      expect(() => NetworkUtils.getIpPrefix(ipAddress, invalidMask),
          throwsArgumentError);
    });

    test('getIpPrefix: handles mismatched IP and subnet mask lengths', () {
      const ipAddress = '192.168.1.10';
      const invalidMask = '255.255'; // Missing last octet

      expect(() => NetworkUtils.getIpPrefix(ipAddress, invalidMask),
          throwsArgumentError);
    });

    test('getIpPrefix: handles non-contiguous subnet mask ones', () {
      const ipAddress = '192.168.1.10';
      const invalidMask = '255.255.255.191'; // Not a contiguous sequence

      expect(() => NetworkUtils.getIpPrefix(ipAddress, invalidMask),
          throwsArgumentError);
    });

    // test('getIpPrefix: handles invalid IP-subnet mask combinations', () {
    //   const ipAddress = '192.168.2.10';
    //   const subnetMask = '255.255.255.0'; // Subnet outside IP's range

    //   expect(() => NetworkUtils.getIpPrefix(ipAddress, subnetMask), throwsArgumentError);
    // });

    // Tests for getMinMtu
    test('getMinMtu: returns correct minimum MTU for known WAN types', () {
      expect(NetworkUtils.getMinMtu('dhcp'), 576);
      expect(NetworkUtils.getMinMtu('DHCP'), 576); // Test case-insensitivity
      expect(NetworkUtils.getMinMtu('pppoe'), 576);
      expect(NetworkUtils.getMinMtu('static'), 576);
      expect(NetworkUtils.getMinMtu('pptp'), 576);
      expect(NetworkUtils.getMinMtu('l2tp'), 576);
    });

    test('getMinMtu: returns 0 for unknown WAN type', () {
      expect(NetworkUtils.getMinMtu('unknown'), 0);
      expect(NetworkUtils.getMinMtu(''), 0);
    });

    // Tests for getMaxMtu
    test('getMaxMtu: returns correct maximum MTU for known WAN types', () {
      expect(NetworkUtils.getMaxMtu('dhcp'), 1500);
      expect(NetworkUtils.getMaxMtu('DHCP'), 1500); // Test case-insensitivity
      expect(NetworkUtils.getMaxMtu('pppoe'), 1492);
      expect(NetworkUtils.getMaxMtu('static'), 1500);
      expect(NetworkUtils.getMaxMtu('pptp'), 1460);
      expect(NetworkUtils.getMaxMtu('l2tp'), 1460);
    });

    test('getMaxMtu: returns 0 for unknown WAN type', () {
      expect(NetworkUtils.getMaxMtu('unknown'), 0);
      expect(NetworkUtils.getMaxMtu(''), 0);
    });

    // Tests for isMtuValid
    test('isMtuValid: returns true for MTU 0 regardless of WAN type', () {
      expect(NetworkUtils.isMtuValid('dhcp', 0), true);
      expect(NetworkUtils.isMtuValid('pppoe', 0), true);
      expect(NetworkUtils.isMtuValid('static', 0), true);
      expect(NetworkUtils.isMtuValid('pptp', 0), true);
      expect(NetworkUtils.isMtuValid('l2tp', 0), true);
      expect(
          NetworkUtils.isMtuValid('unknown', 0), true); // Also true for unknown
    });

    test('isMtuValid: returns true for valid MTU within range for DHCP', () {
      expect(NetworkUtils.isMtuValid('dhcp', 576), true); // Min
      expect(NetworkUtils.isMtuValid('dhcp', 1000), true); // Mid
      expect(NetworkUtils.isMtuValid('dhcp', 1500), true); // Max
    });

    test('isMtuValid: returns false for invalid MTU outside range for DHCP',
        () {
      expect(NetworkUtils.isMtuValid('dhcp', 575), false); // Below min
      expect(NetworkUtils.isMtuValid('dhcp', 1501), false); // Above max
    });

    test('isMtuValid: returns true for valid MTU within range for PPPoE', () {
      expect(NetworkUtils.isMtuValid('pppoe', 576), true); // Min
      expect(NetworkUtils.isMtuValid('pppoe', 1000), true); // Mid
      expect(NetworkUtils.isMtuValid('pppoe', 1492), true); // Max
    });

    test('isMtuValid: returns false for invalid MTU outside range for PPPoE',
        () {
      expect(NetworkUtils.isMtuValid('pppoe', 575), false); // Below min
      expect(NetworkUtils.isMtuValid('pppoe', 1500), false); // Above max
    });

    test('isMtuValid: returns true for valid MTU within range for Static', () {
      expect(NetworkUtils.isMtuValid('static', 576), true); // Min
      expect(NetworkUtils.isMtuValid('static', 1000), true); // Mid
      expect(NetworkUtils.isMtuValid('static', 1500), true); // Max
    });

    test('isMtuValid: returns false for invalid MTU outside range for Static',
        () {
      expect(NetworkUtils.isMtuValid('static', 575), false); // Below min
      expect(NetworkUtils.isMtuValid('static', 1501), false); // Above max
    });

    test('isMtuValid: returns true for valid MTU within range for PPTP', () {
      expect(NetworkUtils.isMtuValid('pptp', 576), true); // Min
      expect(NetworkUtils.isMtuValid('pptp', 1000), true); // Mid
      expect(NetworkUtils.isMtuValid('pptp', 1460), true); // Max
    });

    test('isMtuValid: returns false for invalid MTU outside range for PPTP',
        () {
      expect(NetworkUtils.isMtuValid('pptp', 575), false); // Below min
      expect(NetworkUtils.isMtuValid('pptp', 1461), false); // Above max
    });

    test('isMtuValid: returns true for valid MTU within range for L2TP', () {
      expect(NetworkUtils.isMtuValid('l2tp', 576), true); // Min
      expect(NetworkUtils.isMtuValid('l2tp', 1000), true); // Mid
      expect(NetworkUtils.isMtuValid('l2tp', 1460), true); // Max
    });

    test('isMtuValid: returns false for invalid MTU outside range for L2TP',
        () {
      expect(NetworkUtils.isMtuValid('l2tp', 575), false); // Below min
      expect(NetworkUtils.isMtuValid('l2tp', 1461), false); // Above max
    });

    test('isMtuValid: returns false for any non-zero MTU for unknown WAN type',
        () {
      expect(NetworkUtils.isMtuValid('unknown', 1), false);
      expect(NetworkUtils.isMtuValid('unknown', 1000), false);
      expect(
          NetworkUtils.isMtuValid('', 576), false); // Empty string as unknown
    });
  });

  group('encryptJNAPAuth', () {
    setUp(() {
      // Reset the fernet manager before each test in this group
      FernetManager().resetForTest();
    });

    test('should encrypt the JNAP authorization password when key is available', () {
      // Arrange
      FernetManager().updateKeyFromSerial('a-test-serial');
      const rawLog = 'Some log line... X-JNAP-Authorization: Basic YWRtaW46VmVsb3BAMTIzNA== ... some other log';
      const originalPassword = 'YWRtaW46VmVsb3BAMTIzNA==';
      
      // Act
      final processedLog = Utils.encryptJNAPAuth(rawLog);

      // Assert
      expect(processedLog, isNot(contains(originalPassword)));
      expect(processedLog, contains('X-JNAP-Authorization: Basic '));
      // The encrypted string will be long
      expect(processedLog.length, greaterThan(rawLog.length)); 
    });

    test('should mask the JNAP authorization password when key is NOT available', () {
      // Arrange
      // Key is not set, because of setUp call
      const rawLog = 'Another log... X-JNAP-Authorization: Basic YWRtaW46VmVsb3BAMTIzNA== ... end of log';
      const expectedLog = 'Another log... X-JNAP-Authorization: Basic ************ ... end of log';

      // Act
      final processedLog = Utils.encryptJNAPAuth(rawLog);

      // Assert
      expect(processedLog, expectedLog);
    });

    test('should not change the string if the pattern is not found', () {
      // Arrange
      const rawLog = 'This is a log line without any authorization header.';

      // Act
      final processedLog = Utils.encryptJNAPAuth(rawLog);

      // Assert
      expect(processedLog, rawLog);
    });
  });
}