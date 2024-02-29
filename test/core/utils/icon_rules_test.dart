import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:linksys_app/core/utils/icon_rules.dart';

void main() {
  group('test iconTest series', () {
    test('test iconTest - Unknown model number', () {
      const deviceJson = '''
    {"model": {"deviceType": "Infrastructure", "manufacturer": "Linksys", "modelNumber": "MX57CF", "hardwareVersion": "1"}}
    ''';
      final result = iconTest(jsonDecode(deviceJson));
      expect(result, 'genericDevice');
    });
    test('test iconTest - MR9600', () {
      const deviceJson = '''
    {"model": {"deviceType": "Infrastructure", "manufacturer": "Linksys", "modelNumber": "MR9600", "hardwareVersion": "1"}}
    ''';
      final result = iconTest(jsonDecode(deviceJson));
      expect(result, 'routerEa9350');
    });
    test('test iconTest - Oak', () {
      const deviceJson = '''
    {"model": {"deviceType": "Infrastructure", "manufacturer": "Linksys", "modelNumber": "MBE7000", "hardwareVersion": "1"}}
    ''';
      final result = iconTest(jsonDecode(deviceJson));
      expect(result, 'routerMx6200');
    });
    test('test iconTest - Maple', () {
      const deviceJson = '''
    {"model": {"deviceType": "Infrastructure", "manufacturer": "Linksys", "modelNumber": "MX6200", "hardwareVersion": "1"}}
    ''';
      final result = iconTest(jsonDecode(deviceJson));
      expect(result, 'routerMx6200');
    });
    test('test iconTest - Cherry', () {
      const deviceJson = '''
    {"model": {"deviceType": "Infrastructure", "manufacturer": "Linksys", "modelNumber": "LN12", "hardwareVersion": "1"}}
    ''';
      final result = iconTest(jsonDecode(deviceJson));
      expect(result, 'routerLn12');
    });
    test('test iconTest - Elm', () {
      const deviceJson = '''
    {"model": {"deviceType": "Infrastructure", "manufacturer": "Linksys", "modelNumber": "LN11", "hardwareVersion": "1"}}
    ''';
      final result = iconTest(jsonDecode(deviceJson));
      expect(result, 'routerLn11');
    });
    test('test iconTest - iPhone', () {
      const device = {
        "model": {
          "deviceType": "Phone",
          "manufacturer": "Apple Inc.",
          "modelNumber": "iPhone",
          "hardwareVersion": null,
          "modelDescription": null
        },
      };
      final result = iconTest(device);
      expect(result, 'smartphone');
    });
    test('test iconTest - Android', () {
      const device = {
        "model": {
          "deviceType": "Mobile",
          "manufacturer": null,
          "modelNumber": null,
          "hardwareVersion": null,
          "modelDescription": null
        },
        "friendlyName": "Android",
      };
      final result = iconTest(device);
      expect(result, 'smartphone');
    });
    test('test iconTest - MacBook', () {
      const device = {
        "unit": {
          "serialNumber": null,
          "firmwareVersion": null,
          "firmwareDate": null,
          "operatingSystem": "macOS"
        },
        "model": {
          "deviceType": "Computer",
          "manufacturer": "Apple, Inc.",
          "modelNumber": "MacBook Air",
          "hardwareVersion": null,
          "modelDescription": null
        },
      };
      final result = iconTest(device);
      expect(result, 'laptopMac');
    });
  });

  group('test testRouterIcon series', () {
    test('test routerIconTest - Unknown model number', () {
      final result = routerIconTest(modelNumber: 'MR9500');
      expect(result, 'genericDevice');
    });
    test('test routerIconTest - MR9600', () {
      final result = routerIconTest(modelNumber: 'MR9600');
      expect(result, 'routerEa9350');
    });
    test('test routerIconTest - Oak', () {
      final result = routerIconTest(modelNumber: 'MBE7000');
      expect(result, 'routerMx6200');
    });
    test('test routerIconTest - Maple', () {
      final result = routerIconTest(modelNumber: 'MX6200');
      expect(result, 'routerMx6200');
    });
    test('test routerIconTest - Cherry', () {
      final result = routerIconTest(modelNumber: 'LN12');
      expect(result, 'routerLn12');
    });
    test('test routerIconTest - Elm', () {
      final result = routerIconTest(modelNumber: 'LN11');
      expect(result, 'routerLn11');
    });
  });

  group('test testDeviceIcon series', () {
    test('test device icon', () {
      const device = {
        'model': {
          'deviceType': 'Mobile',
          'manufacturer': 'TCL|极光TV',
          'modelNumber': 'DMR',
        },
        'friendlyName': 'GoogleTV1713',
      };
      final result = deviceIconTest(device);
      print(result);
    });
  });
}
