import 'package:collection/collection.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/core/utils/icon_device_category.dart';

const List<Map<String, dynamic>> iconRules = [
  {
    'description': 'Linksys EA6350v4',
    'test': {
      'model': {
        'hardwareVersion': '4',
        'manufacturer': 'Linksys|Belkin',
        'modelNumber': 'ea6350',
        'deviceType': 'Infrastructure',
      },
    },
    'iconClass': 'routerEa6350v4',
  },
  {
    'description': 'Linksys EA7450',
    'test': {
      'model': {
        'manufacturer': 'Linksys|Belkin',
        'modelNumber': 'ea7450',
        'deviceType': 'Infrastructure',
      },
    },
    'iconClass': 'routerEa7300',
  },
  {
    'description': 'Linksys EA7500v3',
    'test': {
      'model': {
        'hardwareVersion': '3',
        'manufacturer': 'Linksys|Belkin',
        'modelNumber': 'ea7500',
        'deviceType': 'Infrastructure',
      },
    },
    'iconClass': 'routerEa7500v3',
  },
  {
    'description': 'Linksys EA7250/7430',
    'test': {
      'model': {
        'manufacturer': 'Linksys|Belkin',
        'modelNumber': 'ea7250|ea7430',
        'deviceType': 'Infrastructure',
      },
    },
    'iconClass': 'routerEa7500v3',
  },
  {
    'description': 'Linksys EA9350v3',
    'test': {
      'model': {
        'hardwareVersion': '3',
        'manufacturer': 'Linksys|Belkin',
        'modelNumber': 'ea9350',
        'deviceType': 'Infrastructure',
      },
    },
    'iconClass': 'routerEa9350v3',
  },
  {
    'description':
        'Linksys MR7350 (MR7350 + MR73/Elise and Elise Variants; "MR7300 Series")',
    'test': {
      'model': {
        'manufacturer': 'Linksys|Belkin',
        'modelNumber': '^mr73',
      },
    },
    'iconClass': 'routerMr7350',
  },
  {
    'description':
        'Linksys MR7500 (MR7500 + MR75WH/Divo and Divo Variants; "MR7500 Series")',
    'test': {
      'model': {
        'manufacturer': 'Linksys|Belkin',
        'modelNumber': '^mr75',
      },
    },
    'iconClass': 'routerMr7500',
  },
  {
    'description': 'Linksys MX4200 (MX42/Chiron Variants; "MX4000 Series")',
    'test': {
      'model': {
        'manufacturer': 'Linksys|Belkin',
        'modelNumber': '^mx42|mx4000',
      },
    },
    'iconClass': 'routerMx4200',
  },
  {
    'description': 'Linksys MR2000 (MR20/Veyron Variants; "MR2000 Series")',
    'test': {
      'model': {
        'manufacturer': 'Linksys|Belkin',
        'modelNumber': '^mr20',
      },
    },
    'iconClass': 'routerMr2000',
  },
  {
    'description': 'Linksys MX2000 (MX20/Rhodes Variants; "MX2000 Series")',
    'test': {
      'model': {
        'manufacturer': 'Linksys|Belkin',
        'modelNumber': '^mx20',
      },
    },
    'iconClass': 'routerMx2000',
  },
  {
    'description':
        'Linksys MX5500/MX5500ST (MX5500/Dominica & MX5500ST/Boston & Variants; "MX5500 Series")',
    'test': {
      'model': {
        'manufacturer': 'Linksys|Belkin',
        'modelNumber': 'mx5500',
      },
    },
    'iconClass': 'routerMx5500',
  },
  {
    'description': 'Linksys MX5600 (MX56/Palm Variants; "MX5600 Series")',
    'test': {
      'model': {'manufacturer': 'Linksys|Belkin', 'modelNumber': '^mx56'}
    },
    'iconClass': 'routerMx5600'
  },
  {
    'description': 'Linksys MX5700 (MX57/Palm 1.5 Variants; "MX5700 Series")',
    'test': {
      'model': {'manufacturer': 'Linksys|Belkin', 'modelNumber': '^mx57'}
    },
    'iconClass': 'routerMx5700'
  },
  {
    'description': 'Linksys MX6200 (MX62/Maple Variants; "MX6200 Series")',
    'test': {
      'model': {
        'manufacturer': 'Linksys',
        'modelNumber': '^mx62',
      },
    },
    'iconClass': 'routerMx6200',
  },
  {
    'description': 'Linksys MBE7000 (MBE70/Oak Variants; "MBE7000 Series")',
    'test': {
      'model': {
        'manufacturer': 'Linksys',
        'modelNumber': '^mbe70',
      },
    },
    'iconClass': 'routerMbe7000',
  },
  {
    'description': 'Linksys MBE7100 (MBE71/Oak SP1 Variants; "MBE7100 Series")',
    'test': {
      'model': {
        'manufacturer': 'Linksys',
        'modelNumber': '^mbe71',
      },
    },
    'iconClass': 'routerMbe7100',
  },
  {
    'description': 'Linksys SPNM61 (SPNM61/Pinnacle 2.1)',
    'test': {
      'model': {
        'manufacturer': 'Linksys',
        'modelNumber': '^spnm61',
      },
    },
    'iconClass': 'routerSpnm61',
  },
  {
    'description': 'Linksys SPNM62 (SPNM62/Pinnacle 2.2)',
    'test': {
      'model': {
        'manufacturer': 'Linksys',
        'modelNumber': '^spnm62',
      },
    },
    'iconClass': 'routerSpnm62',
  },
  {
    'description': 'Linksys SPNM60 (SPNM60/Pinnacle 2.0)',
    'test': {
      'model': {
        'manufacturer': 'Linksys',
        'modelNumber': '^spnm60',
      },
    },
    'iconClass': 'routerSpnm60',
  },
  {
    'description': 'Linksys Router (modelNumber passthrough)',
    'test': {
      'model': {
        'manufacturer': 'Cisco|Linksys|Belkin',
        'modelNumber': '^(E|EA|WRT|XAC|MR|MX|LN|MBE).+\$',
        'deviceType': 'Infrastructure',
      },
    },
    'iconClass': {
      'lookup': 'model.modelNumber',
    },
  },
  {
    'description':
        'Linksys Node/Mesh Router (workaround for LION-90, CHIRON-40)',
    'test': {
      'model': {
        'manufacturer': 'Linksys|Belkin',
        'modelNumber': ' /^(MR|MX|LN|MBE).+\$',
      },
    },
    'iconClass': {
      'lookup': 'model.modelNumber',
    },
  },
  {
    'description': 'Linksys Velop - Black (WHW03B)',
    'test': {
      'model': {
        'manufacturer': 'Linksys|Belkin',
        'modelNumber': 'whw03b',
      },
    },
    'iconClass': 'routerWhw03b',
  },
  {
    'description': 'Linksys Velop (WHW03)',
    'test': {
      'model': {
        'manufacturer': 'Linksys|Belkin',
        'modelNumber': 'nd0001|nodes|whw0301|whw03|a03',
      },
    },
    'iconClass': 'routerWhw03',
  },
  {
    'description': 'Linksys Velop Plugin (WHW01P)',
    'test': {
      'model': {
        'manufacturer': 'Linksys|Belkin',
        'modelNumber': 'whw01p',
      },
    },
    'iconClass': 'routerWhw01p',
  },
  {
    'description': 'Linksys Velop Jr - Black (WHW01B)',
    'test': {
      'model': {
        'manufacturer': 'Linksys|Belkin',
        'modelNumber': 'whw01b|vlp01b',
      },
    },
    'iconClass': 'routerWhw01b',
  },
  {
    'description': 'Linksys Velop Jr (WHW01)',
    'test': {
      'model': {
        'manufacturer': 'Linksys|Belkin',
        'modelNumber': 'whw01|vlp01|a01',
      },
    },
    'iconClass': 'routerWhw01',
  },
  {
    'description': 'Linksys Extender',
    'test': {
      'model': {
        'manufacturer': 'Cisco|Linksys|Belkin',
        'modelNumber': 'RE|Extender',
      },
    },
    'iconClass': 'linksysExtender',
  },
  {
    'description': 'Linksys Bridge - WET',
    'test': {
      'model': {
        'manufacturer': 'Cisco|Linksys|Belkin',
        'modelNumber': 'WET',
        'deviceType': 'Infrastructure',
      },
    },
    'iconClass': 'linksysBridge',
  },
  {
    'description': 'Linksys Bridge - WUMC710',
    'test': {
      'friendlyName': 'WUMC710',
    },
    'iconClass': 'linksysBridge',
  },
  {
    'description': 'Camera',
    'test': {
      'model': {
        'deviceType': 'Camera',
      },
    },
    'iconClass': 'netCamera',
  },
  {
    'description': 'Computer - Laptop Mac',
    'test': {
      'model': {
        'manufacturer': 'Apple',
        'deviceType': 'Computer',
        'modelNumber': 'Book',
      },
    },
    'iconClass': 'laptopMac',
  },
  {
    'description': 'Computer - Desktop Mac',
    'test': {
      'model': {
        'manufacturer': 'Apple',
        'deviceType': 'Computer',
      },
    },
    'iconClass': 'desktopMac',
  },
  {
    'description': 'DigitalAssistant - Amazon Echo',
    'test': {
      'model': {
        'deviceType': 'DigitalAssistant',
        'modelNumber': 'Echo',
      },
    },
    'iconClass': 'amazonEcho',
  },
  {
    'description': 'DigitalAssistant - Apple HomePod',
    'test': {
      'model': {
        'manufacturer': 'Apple',
        'deviceType': 'DigitalAssistant',
        'modelNumber': 'HomePod',
      },
    },
    'iconClass': 'appleHomepod',
  },
  {
    'description': 'DigitalAssistant - Google Home',
    'test': {
      'model': {
        'deviceType': 'DigitalAssistant',
        'modelNumber': 'Google Home',
      },
    },
    'iconClass': 'googleHome',
  },
  {
    'description': 'Game Console',
    'test': {
      'model': {
        'deviceType': 'GameConsole',
      },
    },
    'iconClass': 'gameConsoles',
  },
  {
    'description': 'Media Player - ChromeCast',
    'test': {
      'model': {
        'deviceType': 'MediaPlayer',
        'modelNumber': 'ChromeCast',
      },
    },
    'iconClass': 'mediaStick',
  },
  {
    'description': 'Media Player',
    'test': {
      'model': {'deviceType': 'MediaPlayer'}
    },
    'iconClass': 'digitalMediaPlayer'
  },
  {
    'description': 'Mobile/Phone - iPad',
    'test': {
      'model': {
        'deviceType': 'Mobile|Phone',
        'modelNumber': 'iPad',
      },
    },
    'iconClass': 'tabletEreader',
  },
  {
    'description': 'Mobile/Phone - iPhone',
    'test': {
      'model': {
        'deviceType': 'Mobile|Phone',
        'modelNumber': 'iPhone',
      },
    },
    'iconClass': 'smartphone',
  },
  {
    'description': 'Mobile/Phone - iPod',
    'test': {
      'model': {
        'deviceType': 'Mobile|Phone',
        'modelNumber': 'iPod',
      },
    },
    'iconClass': 'digitalMediaPlayer',
  },
  {
    'description': 'Mobile/Phone - Kindle',
    'test': {
      'model': {
        'deviceType': 'Mobile|Phone',
        'modelNumber': 'Kindle',
      },
    },
    'iconClass': 'tabletPc',
  },
  {
    'description': 'Phone',
    'test': {
      'model': {
        'deviceType': 'Phone',
      },
    },
    'iconClass': 'genericCellphone',
  },
  {
    'description': 'Printer',
    'test': {
      'model': {
        'deviceType': 'Printer',
      },
    },
    'iconClass': 'printerInkjet',
  },
  {
    'description': 'Storage',
    'test': {
      'model': {
        'deviceType': 'Storage',
      },
    },
    'iconClass': 'netDrive',
  },
  {
    'description': 'Tablet - iPad',
    'test': {
      'model': {
        'deviceType': 'Tablet',
        'modelNumber': 'iPad',
      },
    },
    'iconClass': 'tabletEreader',
  },
  {
    'description': 'Tablet',
    'test': {
      'model': {
        'deviceType': 'Tablet',
      },
    },
    'iconClass': 'tabletPc',
  },
  {
    'description': 'OS X/macOS - iBook/MacBook',
    'test': {
      'unit': {
        'operatingSystem': 'OS X|macOS',
      },
      'model': {
        'modelNumber': 'Book',
      },
    },
    'iconClass': 'laptopMac',
  },
  {
    'description':
        'Display Name includes Laptop or Book and Apple device - Apple Laptop',
    'test': {
      'deviceName': 'Laptop|Book',
      'model': {
        'manufacturer': 'Apple',
      },
    },
    'iconClass': 'laptopMac',
  },
  {
    'description': 'Display Name includes MacBook - Apple Laptop',
    'test': {
      'deviceName': 'MacBook',
    },
    'iconClass': 'laptopMac',
  },
  {
    'description': 'Windows OS - UltraBook/NoteBook/ChromeBook',
    'test': {
      'unit': {
        'operatingSystem': 'Windows',
      },
      'model': {
        'modelNumber': 'Book',
      },
    },
    'iconClass': 'laptopPc',
  },
  {
    'description': 'Display Name includes Laptop or Book - PC Laptop',
    'test': {
      'deviceName': 'Laptop|Book',
    },
    'iconClass': 'laptopPc',
  },
  {
    'description': 'Name includes Android or iPhone',
    'test': {
      'friendlyName': 'Android|iPhone',
    },
    'iconClass': 'smartphone',
  },
  {
    'description': 'Name includes Apple TV or iPod',
    'test': {
      'friendlyName': 'Apple.*TV|iPod',
    },
    'iconClass': 'digitalMediaPlayer',
  },
  {
    'description': 'Name includes iPad, Kindle, or Tablet',
    'test': {
      'friendlyName': 'iPad|Kindle|Tablet',
    },
    'iconClass': 'tabletEreader',
  },
  {
    'description': 'Display Name includes iMac - Mac Desktop',
    'test': {
      'deviceName': 'iMac',
    },
    'iconClass': 'desktopMac',
  },
  {
    'description': 'Computer - Desktop PC',
    'test': {
      'model': {
        'deviceType': 'Computer',
      },
    },
    'iconClass': 'desktopPc',
  },
  {
    'description': 'Game console - Nintendo',
    'test': {
      'model': {
        'manufacturer': 'Nintendo',
      },
    },
    'iconClass': 'gameConsole',
  },
  {
    'description': 'Google TV',
    'test': {
      'friendlyName': '.*TV|GoogleTV.*',
    },
    'iconClass': 'tv',
  },
  {
    'description': 'Vacauum',
    'test': {
      'friendlyName': '.*vacuum.*',
    },
    'iconClass': 'vacauum',
  },
  {
    'description': 'SmartPlug',
    'test': {
      'friendlyName': '.*plug.*',
    },
    'iconClass': 'plug',
  },
  {
    'description': 'Game Console - PS5',
    'test': {
      'friendlyName': '.*PS5.*',
    },
    'iconClass': 'gameConsole',
  },
  {
    'description': 'OS X/macOS - Desktop',
    'test': {
      'unit': {
        'operatingSystem': 'OS X|macOS',
      },
    },
    'iconClass': 'desktopMac',
  },
  {
    'description': 'Windows OS - Desktop',
    'test': {
      'unit': {
        'operatingSystem': 'Windows',
      },
    },
    'iconClass': 'desktopPc',
  },
  {
    'description': 'Android OS',
    'test': {
      'unit': {
        'operatingSystem': 'Android',
      },
    },
    'iconClass': 'smartphone',
  },
  {
    'description': 'Generic Fallback',
    'test': {},
    'iconClass': 'genericDevice',
  }
];

const List<Map<String, dynamic>> iconTestRules = [
  {
    'description': 'Google TV',
    'test': {
      'friendlyName': '.*TV|GoogleTV.*',
    },
    'iconClass': 'tv',
  },
  {
    'description': 'Generic Fallback',
    'test': {},
    'iconClass': 'genericDevice',
  }
];

String _iconMapping(String iconClass, {String? fallback}) {
  switch (iconClass) {
    case 'routerMr7350':
    case 'routerMr5500':
    case 'routerMr2000':
      return 'routerMr7350';
    //
    case 'routerMr7500':
      return 'routerMr7500';
    //
    case 'routerEa8250':
    case 'routerEa8300':
    case 'routerMr8250':
    case 'routerMr8300':
    case 'routerMr8900':
    case 'routerMr8950':
    case 'routerMr9000':
    case 'routerMr9100':
    case 'linksysMesh':
      return 'routerEa8300';
    //
    case 'routerMx5400':
    case 'routerMx5300':
    case 'routerMx4200':
    case 'routerMx8500':
      return 'routerMx5300';
    //
    case 'routerMx6200':
    case 'routerMbe7000':
    case 'routerMbe7100':
    case 'routerLN6001':
    case 'routerLN6002':
    case 'routerLn14':
      return 'routerMx6200';
    //

    case 'routerEa9350':
    case 'routerEa9350v3':
    case 'routerMr9600':
      return 'routerEa9350';
    //
    case 'linksysVelop':
    case 'routerNd001':
    case 'routerNodes':
    case 'routerWhw0301':
    case 'routerWhw03':
    case 'routerMx5500':
    case 'routerMx5600':
    case 'routerMx5700':
    case 'routerMx2000':
      return 'routerWhw03';
    //
    case 'routerWhw01':
    case 'routerVlp01':
    case 'routerA01':
      return 'routerWhw01';
    //
    case 'routerWhw01b':
    case 'routerVlp01b':
      return 'routerWhw01b';
    //
    case 'routerLn11':
    case 'routerLn15':
      return 'routerLn11';
    case 'routerLn12':
    case 'routerLn16':
    case 'routerSpnm60':
    case 'routerSpnm61':
    case 'routerSpnm62':
      return 'routerLn12';
    default:
      // do router check
      return fallback ?? 'routerLn12';
  }
}

String routerIconTestByModel(
    {required String modelNumber, String? hardwareVersion}) {
  if (modelNumber.isEmpty) {
    return 'node';
  }
  final data = {
    'model': {
      'deviceType': 'Infrastructure',
      'manufacturer': 'Linksys',
      'modelNumber': modelNumber,
      'hardwareVersion': hardwareVersion ?? '1',
    }
  };
  return iconTest(data);
}

String routerIconTest(Map<String, dynamic> target) {
  return iconTest(target);
}

String deviceIconTest(Map<String, dynamic> target) {
  const regex =
      r'^.*((phone)|(android)|(iphone)|(mobile)|(desktop)|(laptop)|(windows)|(mac)|(pc)|(tv)|(vacauum)|(plug)|(gameConsole)|(generic)).*$';
  final test = iconTest(target);
  final check = RegExp(regex).firstMatch(test)?.group(1);
  return switch (check) {
    'tv' => IconDeviceCategory.tv,
    'plug' => IconDeviceCategory.plug,
    'vacauum' => IconDeviceCategory.vacuum,
    'gameConsole' => IconDeviceCategory.gameConsole,
    'phone' || 'android' || 'iphone' || 'mobile' => IconDeviceCategory.phone,
    'desktop' ||
    'laptop' ||
    'windows' ||
    'mac' ||
    'pc' =>
      IconDeviceCategory.computer,
    _ => IconDeviceCategory.unknown
  }
      .name;
}

///
/// Please use #deviceIconTest or routerIconTest instead
///
String iconTest(Map<String, dynamic> target) {
  final result = iconRules.firstWhereOrNull((iconRule) {
    List<bool> testResults = [];
    doAttributesTests(
        target, Map<String, dynamic>.from(iconRule['test']), testResults);
    return !testResults.contains(false);
  });
  if (result == null) {
    return _iconMapping('genericDevice');
  }
  final iconClass = result['iconClass'];

  if (iconClass is Map<String, dynamic>) {
    final modelNumber = target.getValueByPath<String>(iconClass['lookup']);
    final capitalized = modelNumber.toLowerCase().capitalize();
    return _iconMapping('router$capitalized');
  } else if (iconClass is String) {
    return _iconMapping(iconClass, fallback: iconClass);
  }
  return _iconMapping(result['iconClass'] as String? ?? 'genericDevice');
}

doAttributesTests(Map<String, dynamic> target, Map<String, dynamic> test,
    List<bool> results) {
  if (isPlainObject(test)) {
    test.forEach((key, value) {
      doAttributesTests(
          target[key] ?? {}, value is String ? {key: value} : value, results);
    });
  } else {
    final result = !test.entries.any((element) {
      if (element.value == null) {
        return true;
      }
      final regex = RegExp('${element.value}', caseSensitive: false);
      bool isMatch = regex.hasMatch(target[element.key] ?? '');
      return !isMatch;
    });
    results.add(result);
  }
}

bool isPlainObject(Map<String, dynamic> json) {
  return json.values.any((element) => element is Map<String, dynamic>);
}
