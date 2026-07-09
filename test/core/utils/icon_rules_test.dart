import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/icon_device_category.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';

void main() {
  group('test iconTest series', () {
    test('test iconTest - MX57CF', () {
      const deviceJson = '''
    {"model": {"deviceType": "Infrastructure", "manufacturer": "Linksys", "modelNumber": "MX57CF", "hardwareVersion": "1"}}
    ''';
      final result = iconTest(jsonDecode(deviceJson));
      expect(result, 'routerWhw03');
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
    test('test iconTest - Cherry7', () {
      const deviceJson = '''
    {"model": {"deviceType": "Infrastructure", "manufacturer": "Linksys", "modelNumber": "LN16", "hardwareVersion": "1"}}
    ''';
      final result = iconTest(jsonDecode(deviceJson));
      expect(result, 'routerLn12');
    });
    test('test iconTest - Pinnacle 2.0', () {
      const deviceJson = '''
    {"model": {"deviceType": "Infrastructure", "manufacturer": "Linksys", "modelNumber": "SPNM60", "hardwareVersion": "1"}}
    ''';
      final result = iconTest(jsonDecode(deviceJson));
      expect(result, 'routerMx6200');
    });
    test('test iconTest - Pinnacle 2.1', () {
      const deviceJson = '''
    {"model": {"deviceType": "Infrastructure", "manufacturer": "Linksys", "modelNumber": "SPNM61", "hardwareVersion": "1"}}
    ''';
      final result = iconTest(jsonDecode(deviceJson));
      expect(result, 'routerMx6200');
    });
    test('test iconTest - Pinnacle 2.2', () {
      const deviceJson = '''
    {"model": {"deviceType": "Infrastructure", "manufacturer": "Linksys", "modelNumber": "SPNM62", "hardwareVersion": "1"}}
    ''';
      final result = iconTest(jsonDecode(deviceJson));
      expect(result, 'routerMx6200');
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

  group('test routerIconTest series', () {
    test('test routerIconTest - Unknown model number (should default)', () {
      const deviceJson = '''
      {"model": {"deviceType": "Infrastructure", "manufacturer": "Linksys", "modelNumber": "MX987CF", "hardwareVersion": "1"}}
      ''';
      // Since MX57CF doesn't have a specific rule, it falls back via iconTest -> _iconMapping
      // iconTest finds no specific rule, returns 'genericDevice'
      // _iconMapping('genericDevice') returns 'routerLn12'
      final result = routerIconTest(jsonDecode(deviceJson));
      expect(result, 'routerLn12');
    });

    test('test routerIconTest - MX57CF', () {
      const deviceJson = '''
      {"model": {"deviceType": "Infrastructure", "manufacturer": "Linksys", "modelNumber": "MX57CF", "hardwareVersion": "1"}}
      ''';

      final result = routerIconTest(jsonDecode(deviceJson));
      expect(result, 'routerWhw03');
    });

    test('test routerIconTest - MR9600', () {
      const deviceJson = '''
      {"model": {"deviceType": "Infrastructure", "manufacturer": "Linksys", "modelNumber": "MR9600", "hardwareVersion": "1"}}
      ''';
      // iconTest finds rule for '^(E|EA|WRT|XAC|MR|MX|LN|MBE).+\$' -> lookup 'model.modelNumber' -> 'MR9600'
      // _iconMapping('routerMr9600') returns 'routerEa9350'
      final result = routerIconTest(jsonDecode(deviceJson));
      expect(result, 'routerEa9350');
    });

    test('test routerIconTest - Oak (MBE7000)', () {
      const deviceJson = '''
      {"model": {"deviceType": "Infrastructure", "manufacturer": "Linksys", "modelNumber": "MBE7000", "hardwareVersion": "1"}}
      ''';
      // iconTest finds rule for '^mbe70' -> 'routerMbe7000'
      // _iconMapping('routerMbe7000') returns 'routerMx6200'
      final result = routerIconTest(jsonDecode(deviceJson));
      expect(result, 'routerMx6200');
    });

    test('test routerIconTest - Oak SP1 (LN14)', () {
      const deviceJson = '''
      {"model": {"deviceType": "Infrastructure", "manufacturer": "Linksys", "modelNumber": "LN14", "hardwareVersion": "1"}}
      ''';
      // iconTest finds rule for '^ln14' -> 'routerLn14'
      // _iconMapping('routerLn14') returns 'routerMx6200'
      final result = routerIconTest(jsonDecode(deviceJson));
      expect(result, 'routerMx6200');
    });

    test('test routerIconTest - Maple (MX6200)', () {
      const deviceJson = '''
      {"model": {"deviceType": "Infrastructure", "manufacturer": "Linksys", "modelNumber": "MX6200", "hardwareVersion": "1"}}
      ''';
      // iconTest finds rule for '^mx62' -> 'routerMx6200'
      // _iconMapping('routerMx6200') returns 'routerMx6200'
      final result = routerIconTest(jsonDecode(deviceJson));
      expect(result, 'routerMx6200');
    });

    test('test routerIconTest - Cherry (LN12)', () {
      const deviceJson = '''
      {"model": {"deviceType": "Infrastructure", "manufacturer": "Linksys", "modelNumber": "LN12", "hardwareVersion": "1"}}
      ''';
      // iconTest finds rule for '^(E|EA|WRT|XAC|MR|MX|LN|MBE).+\$' -> lookup 'model.modelNumber' -> 'LN12'
      // _iconMapping('routerLn12') returns 'routerLn12'
      final result = routerIconTest(jsonDecode(deviceJson));
      expect(result, 'routerLn12');
    });

    test('test routerIconTest - Elm (LN11)', () {
      const deviceJson = '''
      {"model": {"deviceType": "Infrastructure", "manufacturer": "Linksys", "modelNumber": "LN11", "hardwareVersion": "1"}}
      ''';
      // iconTest finds rule for '^(E|EA|WRT|XAC|MR|MX|LN|MBE).+\$' -> lookup 'model.modelNumber' -> 'LN11'
      // _iconMapping('routerLn11') returns 'routerLn11'
      final result = routerIconTest(jsonDecode(deviceJson));
      expect(result, 'routerLn11');
    });

    test('test routerIconTest - Pinnacle 2.0 (SPNM60)', () {
      const deviceJson = '''
      {"model": {"deviceType": "Infrastructure", "manufacturer": "Linksys", "modelNumber": "SPNM60", "hardwareVersion": "1"}}
      ''';
      // iconTest finds rule for '^spnm60' -> 'routerSpnm60'
      // _iconMapping('routerSpnm60') returns 'routerMx6200'
      final result = routerIconTest(jsonDecode(deviceJson));
      expect(result, 'routerMx6200');
    });

    test('test routerIconTest - Pinnacle 2.1 (SPNM61)', () {
      const deviceJson = '''
      {"model": {"deviceType": "Infrastructure", "manufacturer": "Linksys", "modelNumber": "SPNM61", "hardwareVersion": "1"}}
      ''';
      // iconTest finds rule for '^spnm61' -> 'routerSpnm61'
      // _iconMapping('routerSpnm61') returns 'routerMx6200'
      final result = routerIconTest(jsonDecode(deviceJson));
      expect(result, 'routerMx6200');
    });

    test('test routerIconTest - Pinnacle 2.2 (SPNM62)', () {
      const deviceJson = '''
      {"model": {"deviceType": "Infrastructure", "manufacturer": "Linksys", "modelNumber": "SPNM62", "hardwareVersion": "1"}}
      ''';
      // iconTest finds rule for '^spnm62' -> 'routerSpnm62'
      // _iconMapping('routerSpnm62') returns 'routerMx6200'
      final result = routerIconTest(jsonDecode(deviceJson));
      expect(result, 'routerMx6200');
    });

    test('test routerIconTest - Pinnacle 2.0 (M60)', () {
      const deviceJson = '''
      {"model": {"deviceType": "Infrastructure", "manufacturer": "Linksys", "modelNumber": "M60", "hardwareVersion": "1"}}
      ''';
      // iconTest finds rule for '^spnm60' -> 'routerSpnm60'
      // _iconMapping('routerSpnm60') returns 'routerMx6200'
      final result = routerIconTest(jsonDecode(deviceJson));
      expect(result, 'routerMx6200');
    });

    test('test routerIconTest - Pinnacle 2.1 (M61)', () {
      const deviceJson = '''
      {"model": {"deviceType": "Infrastructure", "manufacturer": "Linksys", "modelNumber": "M61", "hardwareVersion": "1"}}
      ''';
      // iconTest finds rule for '^spnm61' -> 'routerSpnm61'
      // _iconMapping('routerSpnm61') returns 'routerMx6200'
      final result = routerIconTest(jsonDecode(deviceJson));
      expect(result, 'routerMx6200');
    });

    test('test routerIconTest - Pinnacle 2.2 (M62)', () {
      const deviceJson = '''
      {"model": {"deviceType": "Infrastructure", "manufacturer": "Linksys", "modelNumber": "M62", "hardwareVersion": "1"}}
      ''';
      // iconTest finds rule for '^spnm62' -> 'routerSpnm62'
      // _iconMapping('routerSpnm62') returns 'routerMx6200'
      final result = routerIconTest(jsonDecode(deviceJson));
      expect(result, 'routerMx6200');
    });

    test('test routerIconTest - Velop (WHW03)', () {
      const deviceJson = '''
      {"model": {"deviceType": "Infrastructure", "manufacturer": "Linksys", "modelNumber": "WHW03", "hardwareVersion": "1"}}
      ''';
      // iconTest finds rule for 'nd0001|nodes|whw0301|whw03|a03' -> 'routerWhw03'
      // _iconMapping('routerWhw03') returns 'routerWhw03'
      final result = routerIconTest(jsonDecode(deviceJson));
      expect(result, 'routerWhw03');
    });

    test('test routerIconTest - Velop Jr (WHW01)', () {
      const deviceJson = '''
      {"model": {"deviceType": "Infrastructure", "manufacturer": "Linksys", "modelNumber": "WHW01", "hardwareVersion": "1"}}
      ''';
      // iconTest finds rule for 'whw01|vlp01|a01' -> 'routerWhw01'
      // _iconMapping('routerWhw01') returns 'routerWhw01'
      final result = routerIconTest(jsonDecode(deviceJson));
      expect(result, 'routerWhw01');
    });

    // Add more router-specific test cases as needed
  });

  group('test deviceIconTest series', () {
    test('test deviceIconTest - TV (Google TV)', () {
      const device = {
        'model': {
          'deviceType': 'MediaPlayer', // Example, might vary
          'manufacturer': 'Google',
          'modelNumber': 'Google TV',
        },
        'friendlyName': 'Living Room TV', // Name that triggers the rule
      };
      // deviceIconTest regex extracts 'speaker' -> IconDeviceCategory.speaker.name
      final result = deviceIconTest(device);
      expect(result, IconDeviceCategory.speaker.name);
    });
    test('test deviceIconTest - TV (Google TV)', () {
      const device = {
        'model': {
          'manufacturer': 'Google',
          'modelNumber': 'Google TV',
        },
        'friendlyName': 'Living Room TV', // Name that triggers the rule
      };
      // deviceIconTest regex extracts 'tv' -> IconDeviceCategory.tv.name
      final result = deviceIconTest(device);
      expect(result, IconDeviceCategory.tv.name);
    });

    test('test deviceIconTest - TV (TCL)', () {
      const device = {
        'model': {
          'deviceType': 'Mobile',
          'manufacturer': 'TCL|极光TV',
          'modelNumber': 'DMR',
        },
        'friendlyName': 'GoogleTV1713',
      };
      // iconTest rule '.*TV|GoogleTV.*' matches friendlyName -> 'tv'
      // deviceIconTest regex extracts 'tv' -> IconDeviceCategory.tv.name
      final result = deviceIconTest(device);
      expect(result, IconDeviceCategory.tv.name);
    });

    test('test deviceIconTest - Plug', () {
      const device = {
        'model': {
          'deviceType': 'SmartPlug', // Example
          'manufacturer': 'Belkin',
          'modelNumber': 'WemoPlug',
        },
        'friendlyName': 'Smart plug kitchen', // Name that triggers the rule
      };
      // iconTest rule '.*plug.*' matches friendlyName -> 'plug'
      // deviceIconTest regex extracts 'plug' -> IconDeviceCategory.plug.name
      final result = deviceIconTest(device);
      expect(result, IconDeviceCategory.plug.name);
    });

    test('test deviceIconTest - Vacuum', () {
      const device = {
        'model': {
          'deviceType': 'HomeAppliance', // Example
          'manufacturer': 'iRobot',
          'modelNumber': 'Roomba',
        },
        'friendlyName': 'Downstairs vacuum', // Name that triggers the rule
      };
      // iconTest rule '.*vacuum.*' matches friendlyName -> 'vacauum'
      // deviceIconTest regex extracts 'vacauum' -> IconDeviceCategory.vacuum.name
      final result = deviceIconTest(device);
      expect(result, IconDeviceCategory.vacuum.name);
    });

    test('test deviceIconTest - Game Console (PS5)', () {
      const device = {
        'model': {
          'deviceType': 'GameConsole',
          'manufacturer': 'Sony',
          'modelNumber': 'PlayStation 5',
        },
        'friendlyName': 'My PS5', // Name that triggers the rule
      };
      // iconTest rule '.*PS5.*' matches friendlyName -> 'gameConsole'
      // deviceIconTest regex extracts 'gameConsole' -> IconDeviceCategory.gameConsole.name
      final result = deviceIconTest(device);
      expect(result, IconDeviceCategory.gameConsole.name);
    });

    test('test deviceIconTest - Game Console (Nintendo)', () {
      const device = {
        'model': {
          'deviceType': 'GameConsole',
          'manufacturer': 'Nintendo', // Manufacturer triggers the rule
          'modelNumber': 'Switch',
        },
        'friendlyName': 'Switch',
      };
      // iconTest rule for manufacturer 'Nintendo' -> 'gameConsole'
      // deviceIconTest regex extracts 'gameConsole' -> IconDeviceCategory.gameConsole.name
      final result = deviceIconTest(device);
      expect(result, IconDeviceCategory.gameConsole.name);
    });

    test('test deviceIconTest - Phone (iPhone by model)', () {
      const device = {
        "model": {
          "deviceType": "Phone",
          "manufacturer": "Apple Inc.",
          "modelNumber": "iPhone", // ModelNumber triggers the rule
          "hardwareVersion": null,
          "modelDescription": null
        },
      };
      // iconTest rule for modelNumber 'iPhone' -> 'smartphone'
      // deviceIconTest regex extracts 'phone' (from smartphone) -> IconDeviceCategory.phone.name
      final result = deviceIconTest(device);
      expect(result, IconDeviceCategory.phone.name);
    });

    test('test deviceIconTest - Phone (Android by friendlyName)', () {
      const device = {
        "model": {
          "deviceType": "Mobile",
          "manufacturer": null,
          "modelNumber": null,
          "hardwareVersion": null,
          "modelDescription": null
        },
        "friendlyName": "Android Phone", // friendlyName triggers the rule
      };
      // iconTest rule for friendlyName 'Android|iPhone' -> 'smartphone'
      // deviceIconTest regex extracts 'phone' (from smartphone) -> IconDeviceCategory.phone.name
      final result = deviceIconTest(device);
      expect(result, IconDeviceCategory.phone.name);
    });

    test('test deviceIconTest - Phone (Android by OS)', () {
      const device = {
        "unit": {
          "operatingSystem": "Android", // OS triggers the rule
        },
        "model": {
          "deviceType": "Mobile",
          "manufacturer": "Samsung",
          "modelNumber": "Galaxy S21",
        },
        "friendlyName": "Galaxy S21",
      };
      // iconTest rule for OS 'Android' -> 'smartphone'
      // deviceIconTest regex extracts 'phone' (from smartphone) -> IconDeviceCategory.phone.name
      final result = deviceIconTest(device);
      expect(result, IconDeviceCategory.phone.name);
    });

    test('test deviceIconTest - Computer (MacBook by model)', () {
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
          "modelNumber": "MacBook Air", // ModelNumber 'Book' triggers rule
          "hardwareVersion": null,
          "modelDescription": null
        },
      };
      // iconTest rule for Apple Computer + 'Book' -> 'laptopMac'
      // deviceIconTest regex extracts 'laptop' -> IconDeviceCategory.computer.name
      final result = deviceIconTest(device);
      expect(result, IconDeviceCategory.computer.name);
    });

    test('test deviceIconTest - Computer (Windows Desktop by OS)', () {
      const device = {
        "unit": {
          "operatingSystem": "Windows", // OS triggers the rule
        },
        "model": {
          "deviceType": "Computer",
          "manufacturer": "Dell",
          "modelNumber": "OptiPlex",
        },
        "friendlyName": "Work PC",
      };
      // iconTest rule for OS 'Windows' -> 'desktopPc'
      // deviceIconTest regex extracts 'desktop' -> IconDeviceCategory.computer.name
      final result = deviceIconTest(device);
      expect(result, IconDeviceCategory.computer.name);
    });

    test('test deviceIconTest - Computer (PC Laptop by friendlyName)', () {
      const device = {
        "unit": {
          "operatingSystem": "Linux", // OS doesn't match specific rules
        },
        "model": {
          "deviceType": "Computer",
          "manufacturer": "Lenovo",
          "modelNumber": "ThinkPad",
        },
        "friendlyName": "My Linux Laptop", // friendlyName triggers rule
      };
      // iconTest rule for friendlyName 'Laptop|Book' -> 'laptopPc'
      // deviceIconTest regex extracts 'laptop' -> IconDeviceCategory.computer.name
      final result = deviceIconTest(device);
      expect(result, IconDeviceCategory.computer.name);
    });

    test('test deviceIconTest - Unknown (Generic Device)', () {
      const device = {
        'model': {
          'deviceType': 'UnknownDeviceType',
          'manufacturer': 'GenericCorp',
          'modelNumber': 'XYZ123',
        },
        'friendlyName': 'Some Device',
      };
      // iconTest falls through to 'genericDevice'
      // deviceIconTest regex extracts 'generic' -> default case -> IconDeviceCategory.unknown.name
      final result = deviceIconTest(device);
      expect(result, IconDeviceCategory.unknown.name);
    });

    test('test deviceIconTest - Unknown (Router)', () {
      const deviceJson = '''
      {"model": {"deviceType": "Infrastructure", "manufacturer": "Linksys", "modelNumber": "WHW03", "hardwareVersion": "1"}}
      ''';
      // iconTest maps WHW03 to 'routerWhw03'
      // deviceIconTest regex doesn't match 'routerWhw03' -> default case -> IconDeviceCategory.unknown.name
      final result = deviceIconTest(jsonDecode(deviceJson));
      expect(result, IconDeviceCategory.unknown.name);
    });

    test('test deviceIconTest - Unknown (Camera)', () {
      const device = {
        'model': {
          'deviceType': 'Camera', // deviceType triggers rule
          'manufacturer': 'Wyze',
          'modelNumber': 'Cam v3',
        },
        'friendlyName': 'Garage Cam',
      };
      // iconTest rule for deviceType 'Camera' -> 'netCamera'
      // deviceIconTest regex doesn't match 'netCamera' -> default case -> IconDeviceCategory.unknown.name
      final result = deviceIconTest(device);
      expect(result, IconDeviceCategory.unknown.name);
    });
  });
}
