import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/utils/device_classifier.dart';
import 'package:privacy_gui/core/utils/oui_lookup.dart';

import '../../../mocks/test_data/devices_test_data.dart';

void main() {
  // OUI database for testing (subset needed by DeviceClassifier tests)
  const testOuiDatabase = <String, String>{
    '0017AB': 'Nintendo Co., Ltd.',
    '080581': 'Roku, Inc.',
    '000E58': 'Sonos, Inc.',
    '5CCF7F': 'Espressif Inc.',
    '503EAA': 'TP-Link Technologies Co.,Ltd',
    '001422': 'Dell Inc.',
    '000393': 'Apple, Inc.',
  };

  setUpAll(() {
    OuiLookup.initializeForTesting(testOuiDatabase);
  });

  tearDownAll(() {
    OuiLookup.reset();
  });
  group('DeviceClassifier hostname patterns', () {
    test('iPhone variations', () {
      expect(
        DeviceClassifier.classify(hostname: 'iPhone', mac: '00:00:00:00:00:00'),
        DeviceCategory.phone,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'Austins-iPhone', mac: '00:00:00:00:00:00'),
        DeviceCategory.phone,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'iPhone-14-Pro', mac: '00:00:00:00:00:00'),
        DeviceCategory.phone,
      );
    });

    test('iPad variations', () {
      expect(
        DeviceClassifier.classify(hostname: 'iPad', mac: '00:00:00:00:00:00'),
        DeviceCategory.tablet,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'iPad-Pro', mac: '00:00:00:00:00:00'),
        DeviceCategory.tablet,
      );
    });

    test('Mac computers', () {
      expect(
        DeviceClassifier.classify(
            hostname: 'MacBook-Pro', mac: '00:00:00:00:00:00'),
        DeviceCategory.computer,
      );
      expect(
        DeviceClassifier.classify(hostname: 'iMac', mac: '00:00:00:00:00:00'),
        DeviceCategory.computer,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'Mac-Mini', mac: '00:00:00:00:00:00'),
        DeviceCategory.computer,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'Mac-Studio', mac: '00:00:00:00:00:00'),
        DeviceCategory.computer,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'TW-AUSTINC-MAC', mac: '00:00:00:00:00:00'),
        DeviceCategory.computer,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'Johns-Mac', mac: '00:00:00:00:00:00'),
        DeviceCategory.computer,
      );
    });

    test('Android phones', () {
      expect(
        DeviceClassifier.classify(
            hostname: 'android-abc123', mac: '00:00:00:00:00:00'),
        DeviceCategory.phone,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'Galaxy-S23', mac: '00:00:00:00:00:00'),
        DeviceCategory.phone,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'Pixel-7', mac: '00:00:00:00:00:00'),
        DeviceCategory.phone,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'OnePlus-10', mac: '00:00:00:00:00:00'),
        DeviceCategory.phone,
      );
    });

    test('Android tablets', () {
      expect(
        DeviceClassifier.classify(
            hostname: 'Galaxy-Tab-S8', mac: '00:00:00:00:00:00'),
        DeviceCategory.tablet,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'Surface-Pro-9', mac: '00:00:00:00:00:00'),
        DeviceCategory.tablet,
      );
    });

    test('Windows computers', () {
      expect(
        DeviceClassifier.classify(
            hostname: 'ThinkPad-X1', mac: '00:00:00:00:00:00'),
        DeviceCategory.computer,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'Dell-XPS-15', mac: '00:00:00:00:00:00'),
        DeviceCategory.computer,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'HP-Pavilion', mac: '00:00:00:00:00:00'),
        DeviceCategory.computer,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'DESKTOP-ABC123', mac: '00:00:00:00:00:00'),
        DeviceCategory.computer,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'Surface-Laptop', mac: '00:00:00:00:00:00'),
        DeviceCategory.computer,
      );
    });

    test('Game consoles', () {
      expect(
        DeviceClassifier.classify(
            hostname: 'PlayStation5', mac: '00:00:00:00:00:00'),
        DeviceCategory.gameConsole,
      );
      expect(
        DeviceClassifier.classify(hostname: 'PS5', mac: '00:00:00:00:00:00'),
        DeviceCategory.gameConsole,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'Xbox-Series-X', mac: '00:00:00:00:00:00'),
        DeviceCategory.gameConsole,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'Nintendo-Switch', mac: '00:00:00:00:00:00'),
        DeviceCategory.gameConsole,
      );
    });

    test('TVs', () {
      expect(
        DeviceClassifier.classify(
            hostname: 'Samsung-TV', mac: '00:00:00:00:00:00'),
        DeviceCategory.tv,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'LG-OLED55', mac: '00:00:00:00:00:00'),
        DeviceCategory.tv,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'Sony-Bravia', mac: '00:00:00:00:00:00'),
        DeviceCategory.tv,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'SmartTV', mac: '00:00:00:00:00:00'),
        DeviceCategory.tv,
      );
    });

    test('Media players', () {
      expect(
        DeviceClassifier.classify(
            hostname: 'Apple-TV', mac: '00:00:00:00:00:00'),
        DeviceCategory.mediaPlayer,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'Chromecast', mac: '00:00:00:00:00:00'),
        DeviceCategory.mediaPlayer,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'Fire-TV-Stick', mac: '00:00:00:00:00:00'),
        DeviceCategory.mediaPlayer,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'Roku-Ultra', mac: '00:00:00:00:00:00'),
        DeviceCategory.mediaPlayer,
      );
    });

    test('Smart speakers', () {
      expect(
        DeviceClassifier.classify(
            hostname: 'Echo-Dot', mac: '00:00:00:00:00:00'),
        DeviceCategory.smartSpeaker,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'Google-Home', mac: '00:00:00:00:00:00'),
        DeviceCategory.smartSpeaker,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'HomePod', mac: '00:00:00:00:00:00'),
        DeviceCategory.smartSpeaker,
      );
      expect(
        DeviceClassifier.classify(hostname: 'Sonos', mac: '00:00:00:00:00:00'),
        DeviceCategory.smartSpeaker,
      );
    });

    test('Cameras', () {
      expect(
        DeviceClassifier.classify(
            hostname: 'Ring-Doorbell', mac: '00:00:00:00:00:00'),
        DeviceCategory.camera,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'Nest-Cam', mac: '00:00:00:00:00:00'),
        DeviceCategory.camera,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'Wyze-Cam', mac: '00:00:00:00:00:00'),
        DeviceCategory.camera,
      );
    });

    test('Printers', () {
      expect(
        DeviceClassifier.classify(
            hostname: 'HP-OfficeJet-Pro', mac: '00:00:00:00:00:00'),
        DeviceCategory.printer,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'Epson-EcoTank', mac: '00:00:00:00:00:00'),
        DeviceCategory.printer,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'Canon-PIXMA', mac: '00:00:00:00:00:00'),
        DeviceCategory.printer,
      );
    });

    test('IoT devices', () {
      expect(
        DeviceClassifier.classify(
            hostname: 'ESP32-Sensor', mac: '00:00:00:00:00:00'),
        DeviceCategory.iot,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'Shelly1', mac: '00:00:00:00:00:00'),
        DeviceCategory.iot,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'Smart-Plug', mac: '00:00:00:00:00:00'),
        DeviceCategory.iot,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'Hue-Bridge', mac: '00:00:00:00:00:00'),
        DeviceCategory.iot,
      );
    });

    test('Wearables', () {
      expect(
        DeviceClassifier.classify(
            hostname: 'Apple-Watch', mac: '00:00:00:00:00:00'),
        DeviceCategory.wearable,
      );
      expect(
        DeviceClassifier.classify(
            hostname: 'Galaxy-Watch', mac: '00:00:00:00:00:00'),
        DeviceCategory.wearable,
      );
      expect(
        DeviceClassifier.classify(hostname: 'Fitbit', mac: '00:00:00:00:00:00'),
        DeviceCategory.wearable,
      );
    });
  });

  group('DeviceClassifier OUI vendor inference', () {
    test('Nintendo OUI -> gameConsole (definitive)', () {
      // Nintendo OUI: 00:17:AB
      expect(
        DeviceClassifier.classify(hostname: '', mac: '00:17:AB:12:34:56'),
        DeviceCategory.gameConsole,
      );
    });

    test('Roku OUI -> mediaPlayer (definitive)', () {
      // Roku OUI: 08:05:81
      expect(
        DeviceClassifier.classify(hostname: '', mac: '08:05:81:12:34:56'),
        DeviceCategory.mediaPlayer,
      );
    });

    test('Sonos OUI -> smartSpeaker (definitive)', () {
      // Sonos OUI: 00:0E:58
      expect(
        DeviceClassifier.classify(hostname: '', mac: '00:0E:58:12:34:56'),
        DeviceCategory.smartSpeaker,
      );
    });

    test('Espressif OUI -> iot (definitive)', () {
      // Espressif OUI: 5C:CF:7F
      expect(
        DeviceClassifier.classify(hostname: '', mac: '5C:CF:7F:12:34:56'),
        DeviceCategory.iot,
      );
    });

    test('TP-Link OUI -> networkDevice (definitive)', () {
      // TP-Link OUI: 50:3E:AA
      expect(
        DeviceClassifier.classify(hostname: '', mac: '50:3E:AA:12:34:56'),
        DeviceCategory.networkDevice,
      );
    });

    test('Dell OUI -> computer (probable)', () {
      // Dell OUI: 00:14:22
      expect(
        DeviceClassifier.classify(hostname: '', mac: '00:14:22:12:34:56'),
        DeviceCategory.computer,
      );
    });

    test('Apple OUI with unknown hostname -> unknown (ambiguous vendor)', () {
      // Apple OUI: 00:03:93 — could be iPhone, iPad, Mac, AppleTV, etc.
      expect(
        DeviceClassifier.classify(hostname: '', mac: '00:03:93:12:34:56'),
        DeviceCategory.unknown,
      );
    });
  });

  group('DeviceClassifier randomized MAC', () {
    test('Randomized MAC (second digit 2) -> phone', () {
      // Locally administered: x2:xx:xx
      expect(
        DeviceClassifier.classify(hostname: '', mac: '02:00:00:00:00:00'),
        DeviceCategory.phone,
      );
    });

    test('Randomized MAC (second digit 6) -> phone', () {
      expect(
        DeviceClassifier.classify(hostname: '', mac: '06:00:00:00:00:00'),
        DeviceCategory.phone,
      );
    });

    test('Randomized MAC (second digit A) -> phone', () {
      expect(
        DeviceClassifier.classify(hostname: '', mac: 'BA:16:44:9F:EB:8B'),
        DeviceCategory.phone,
      );
    });

    test('Randomized MAC (second digit E) -> phone', () {
      expect(
        DeviceClassifier.classify(hostname: '', mac: 'FE:00:00:00:00:00'),
        DeviceCategory.phone,
      );
    });
  });

  group('DeviceClassifier priority', () {
    test('Hostname takes priority over OUI', () {
      // Nintendo OUI but hostname says "MacBook"
      expect(
        DeviceClassifier.classify(
            hostname: 'MacBook-Pro', mac: '00:17:AB:12:34:56'),
        DeviceCategory.computer,
      );
    });

    test('Hostname takes priority over randomized MAC', () {
      // Randomized MAC but hostname says "iPad"
      expect(
        DeviceClassifier.classify(
            hostname: 'My-iPad', mac: 'BA:16:44:9F:EB:8B'),
        DeviceCategory.tablet,
      );
    });
  });

  group('DeviceClassifier mDNS suffix stripping', () {
    test('strips ._device-info._tcp.local suffix', () {
      expect(
        DeviceClassifier.classify(
            hostname: 'MacBook-Pro._device-info._tcp.local',
            mac: '00:00:00:00:00:00'),
        DeviceCategory.computer,
      );
    });

    test('strips ._tcp.local suffix', () {
      expect(
        DeviceClassifier.classify(
            hostname: 'iPhone._tcp.local', mac: '00:00:00:00:00:00'),
        DeviceCategory.phone,
      );
    });

    test('strips ._udp suffix', () {
      expect(
        DeviceClassifier.classify(
            hostname: 'iPad._udp', mac: '00:00:00:00:00:00'),
        DeviceCategory.tablet,
      );
    });

    test('handles complex mDNS hostname', () {
      expect(
        DeviceClassifier.classify(
            hostname: 'Austins-MacBook-Pro._device-info._tcp.local',
            mac: '00:00:00:00:00:00'),
        DeviceCategory.computer,
      );
    });

    test('normal hostname without suffix still works', () {
      expect(
        DeviceClassifier.classify(
            hostname: 'PlayStation5', mac: '00:00:00:00:00:00'),
        DeviceCategory.gameConsole,
      );
    });
  });

  // The order of #1693: the type the user set, then the type the firmware
  // detected, and today's heuristics only when neither maps.
  group('DeviceClassifier classifyClient (#1693)', () {
    test('the firmware type wins over the host name', () {
      final device = DevicesTestData.createWifiClient(
        hostName: 'MacBook-Pro',
        deviceType: 'Phone',
      );
      expect(DeviceClassifier.classifyClient(device), DeviceCategory.phone);
    });

    test('a type the user set wins over the firmware type', () {
      final device = DevicesTestData.createWifiClient(
        deviceType: 'Phone',
        userDeviceType: 'Tablet',
      );
      expect(DeviceClassifier.classifyClient(device), DeviceCategory.tablet);
    });

    test('a user type with no category falls through to the firmware type', () {
      final device = DevicesTestData.createWifiClient(
        deviceType: 'Computer',
        userDeviceType: 'Toaster',
      );
      expect(DeviceClassifier.classifyClient(device), DeviceCategory.computer);
    });

    // devregex.json types a Kindle and an iPod Touch as `Mobile`, and only the
    // model tells them apart from a phone — as `icon_rules_data.dart` does.
    test('a Mobile Kindle is a tablet, as its host name says today', () {
      final device = DevicesTestData.createWifiClient(
        hostName: 'kindle-1a2b3c',
        deviceType: 'Mobile',
        modelName: 'Kindle',
      );
      expect(DeviceClassifier.classifyClient(device), DeviceCategory.tablet);
    });

    test('a Mobile iPod Touch is a media player', () {
      final device = DevicesTestData.createWifiClient(
        hostName: '',
        deviceType: 'Mobile',
        modelName: 'iPod Touch',
      );
      expect(
          DeviceClassifier.classifyClient(device), DeviceCategory.mediaPlayer);
    });

    test('name patterns match FriendlyName before HostName', () {
      final device = DevicesTestData.createWifiClient(
        friendlyName: "Austin's iPad",
        hostName: 'MacBook-Pro',
      );
      expect(DeviceClassifier.classifyClient(device), DeviceCategory.tablet);
    });

    test('a FriendlyName no pattern matches falls through to HostName', () {
      final device = DevicesTestData.createWifiClient(
        friendlyName: 'Living room',
        hostName: 'MacBook-Pro',
      );
      expect(DeviceClassifier.classifyClient(device), DeviceCategory.computer);
    });

    test('with neither type set, the host name decides as today', () {
      final device = DevicesTestData.createWifiClient(hostName: 'PlayStation5');
      expect(
          DeviceClassifier.classifyClient(device), DeviceCategory.gameConsole);
    });

    // Every distinct "type" in devidentd's devregex.json at feed_premium
    // 0e0cf583 (the FWDEV#207 merge), with the category it shows as.
    const devregexTypes = <String, DeviceCategory>{
      'Phone': DeviceCategory.phone,
      'Mobile': DeviceCategory.phone,
      'Tablet': DeviceCategory.tablet,
      'Computer': DeviceCategory.computer,
      'MediaPlayer': DeviceCategory.mediaPlayer,
      'Wearable': DeviceCategory.wearable,
      'Camera': DeviceCategory.camera,
      'WeMoNetCam': DeviceCategory.camera,
      'Infrastructure': DeviceCategory.networkDevice,
      'Storage': DeviceCategory.networkDevice,
      'GameConsole': DeviceCategory.gameConsole,
      'GameDevice': DeviceCategory.gameConsole,
      'DigitalAssistant': DeviceCategory.smartSpeaker,
      'Printer': DeviceCategory.printer,
      'DeviceHub': DeviceCategory.iot,
      'WeMoAirPurifier': DeviceCategory.iot,
      'WeMoBaby': DeviceCategory.iot,
      'WeMoBridge': DeviceCategory.iot,
      'WeMoCoffeeMaker': DeviceCategory.iot,
      'WeMoCrockPot': DeviceCategory.iot,
      'WeMoDimmer': DeviceCategory.iot,
      'WeMoHeaterA': DeviceCategory.iot,
      'WeMoHeaterB': DeviceCategory.iot,
      'WeMoHumidifier': DeviceCategory.iot,
      'WeMoHumidifierB': DeviceCategory.iot,
      'WeMoInsight': DeviceCategory.iot,
      'WeMoLightSwitch': DeviceCategory.iot,
      'WeMoLink': DeviceCategory.iot,
      'WeMoMaker': DeviceCategory.iot,
      'WeMoPetfeeder': DeviceCategory.iot,
      'WeMoSensor': DeviceCategory.iot,
      'WeMoSocket': DeviceCategory.iot,
    };
    for (final entry in devregexTypes.entries) {
      test('firmware type "${entry.key}" shows as ${entry.value.name}', () {
        // No host name, and a MAC with no OUI entry that is not randomised:
        // the heuristics alone say unknown, so the test fails if the type is
        // ignored.
        final device = DevicesTestData.createWifiClient(
          hostName: '',
          deviceType: entry.key,
        );
        final expected = entry.value;
        expect(DeviceClassifier.classifyClient(device), expected);
      });
    }
  });

  // The icon a user picks is stored in X_LINKSYS_UserDeviceType as a number the
  // app owns, so the app defines the categories, not the firmware (#1691).
  group('DeviceCategory user type codes (#1691)', () {
    // Pinned literals: a stored code must keep its meaning across releases,
    // so reordering the enum must not change any of these.
    const pinned = <DeviceCategory, String>{
      DeviceCategory.phone: '1',
      DeviceCategory.tablet: '2',
      DeviceCategory.computer: '3',
      DeviceCategory.tv: '4',
      DeviceCategory.gameConsole: '5',
      DeviceCategory.mediaPlayer: '6',
      DeviceCategory.smartSpeaker: '7',
      DeviceCategory.camera: '8',
      DeviceCategory.printer: '9',
      DeviceCategory.networkDevice: '10',
      DeviceCategory.iot: '11',
      DeviceCategory.wearable: '12',
    };

    test('each category has its pinned code', () {
      for (final entry in pinned.entries) {
        expect(entry.key.userTypeCode, entry.value, reason: entry.key.name);
      }
    });

    test('unknown has no code: picking it clears the user type', () {
      expect(DeviceCategory.unknown.userTypeCode, '');
    });

    test('a code reads back as its category', () {
      for (final entry in pinned.entries) {
        expect(DeviceCategory.fromUserTypeCode(entry.value), entry.key);
      }
    });

    test('a value that is not a code reads as no category', () {
      for (final value in [null, '', '0', '13', 'phone', ' 4', '4.0']) {
        expect(DeviceCategory.fromUserTypeCode(value), isNull, reason: value);
      }
    });

    test('a user type code wins over the firmware type', () {
      final device = DevicesTestData.createWifiClient(
        deviceType: 'Phone',
        userDeviceType: '4',
      );
      expect(DeviceClassifier.classifyClient(device), DeviceCategory.tv);
    });
  });

  // The firmware's manufacturer first, the OUI only when it has none (#1693).
  group('DeviceClassifier manufacturerOf (#1693)', () {
    test('the firmware manufacturer wins over the OUI', () {
      final device = DevicesTestData.createWifiClient(
        mac: '00:14:22:12:34:56', // Dell by OUI
        manufacturer: 'Apple',
      );
      expect(DeviceClassifier.manufacturerOf(device), 'Apple');
    });

    test('an iPhone with a randomised MAC shows Apple, not Private/Random', () {
      final device = DevicesTestData.createWifiClient(
        mac: 'BA:16:44:9F:EB:8B',
        manufacturer: 'Apple',
      );
      expect(DeviceClassifier.manufacturerOf(device), 'Apple');
    });

    test('with no firmware manufacturer, the OUI decides as today', () {
      expect(
        DeviceClassifier.manufacturerOf(
            DevicesTestData.createWifiClient(mac: '00:14:22:12:34:56')),
        'Dell Inc.',
      );
      expect(
        DeviceClassifier.manufacturerOf(
            DevicesTestData.createWifiClient(mac: 'BA:16:44:9F:EB:8B')),
        'Private/Random',
      );
      expect(
        DeviceClassifier.manufacturerOf(
            DevicesTestData.createWifiClient(mac: '11:22:33:44:55:01')),
        isNull,
      );
    });
  });
}
