import 'package:collection/collection.dart';
import 'package:linksys_app/core/utils/extension.dart';

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
    'description': 'Linksys Cherry (LN12/Cherry Variants; "LN12 Series")',
    'test': {
      'model': {
        'manufacturer': 'Linksys',
        'modelNumber': '^ln12',
      },
    },
    'iconClass': 'routerLn12',
  },
  {
    'description': 'Linksys Elm (LN11/Elm Variants; "LN11 Series")',
    'test': {
      'model': {
        'manufacturer': 'Linksys',
        'modelNumber': '^ln11',
      },
    },
    'iconClass': 'routerLn11',
  },
  {
    'description': 'Linksys Router',
    'test': {
      'model': {
        'manufacturer': 'Cisco|Linksys|Belkin',
        'modelNumber': '^(E|EA|WRT|XAC|MR|MX).+\$',
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
        'modelNumber': ' /^(MR|MX).+\$',
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
    'description': 'WeMo Light Switch',
    'test': {
      'model': {
        'deviceType': 'WeMoLightSwitch',
      },
    },
    'iconClass': 'wemoLightswitch',
  },
  {
    'description': 'WeMo Insight',
    'test': {
      'model': {
        'deviceType': 'WeMoInsight',
      },
    },
    'iconClass': 'wemoInsight',
  },
  {
    'description': 'WeMo NetCam',
    'test': {
      'model': {
        'deviceType': 'WeMoNetCam',
      },
    },
    'iconClass': 'wemoNetcam',
  },
  {
    'description': 'WeMo Sensor',
    'test': {
      'model': {
        'deviceType': 'WeMoSensor',
      },
    },
    'iconClass': 'wemoSensor',
  },
  {
    'description': 'WeMo Mini',
    'test': {
      'model': {'deviceType': 'WeMoSocket'},
      'unit': {
        'firmwareVersion': 'snsv2',
      },
    },
    'iconClass': 'wemoMini',
  },
  {
    'description': 'WeMo Socket',
    'test': {
      'model': {
        'deviceType': 'WeMoSocket',
      },
    },
    'iconClass': 'wemoSocket',
  },
  {
    'description': 'WeMo Link',
    'test': {
      'model': {
        'deviceType': 'WeMoLink',
      },
    },
    'iconClass': 'wemoLink',
  },
  {
    'description': 'WeMo Maker',
    'test': {
      'model': {
        'deviceType': 'WeMoMaker',
      },
    },
    'iconClass': 'wemoMaker',
  },
  {
    'description': 'Jarden AirPurifier',
    'test': {
      'model': {
        'deviceType': 'WeMoAirPurifier',
      },
    },
    'iconClass': 'smartAirpurifier',
  },
  {
    'description': 'Jarden CrockPot',
    'test': {
      'model': {
        'deviceType': 'WeMoCrockPot',
      },
    },
    'iconClass': 'smartCrockpot',
  },
  {
    'description': 'Jarden CoffeeMaker',
    'test': {
      'model': {
        'deviceType': 'WeMoCoffeeMaker',
      },
    },
    'iconClass': 'smartMrcoffee',
  },
  {
    'description': 'Jarden Heater',
    'test': {
      'model': {
        'deviceType': 'WeMoHeaterA|WeMoHeaterB',
      },
    },
    'iconClass': 'smartHeater',
  },
  {
    'description': 'WeMo Fallback',
    'test': {
      'model': {
        'deviceType': 'WeMo',
      },
    },
    'iconClass': 'wemoDevice',
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
    'description': 'OS X/macOS - Desktop',
    'test': {
      'unit': {
        'operatingSystem': 'OS X|macOS',
      },
    },
    'iconClass': 'desktopMac',
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
    'description': 'Generic Fallback',
    'test': {},
    'iconClass': 'genericDevice',
  }
];

String _iconMapping(String iconClass, {String? fallback}) {
  switch (iconClass) {
    //
    case 'routerE4200':
    case 'routerEa4500':
    case 'routerEa6200':
    case 'routerXac1200':
    case 'routerEa4500v3':
      return 'routerEa4500';
    //
    case 'routerEa5800':
    case 'routerEa6100':
      return 'routerEa6100';
    //
    case 'routerEa6300':
    case 'routerEa6300v1':
    case 'routerEa6400':
    case 'routerEa6500':
    case 'routerEa6700':
      return 'routerEa6300';
    //
    case 'routerEa6900':
    case 'routerXac1900':
      return 'routerEa6900';

    //
    case 'routerEa7300':
    case 'routerEa7400':
    case 'routerEa7500':
      return 'routerEa7500';
    //
    case 'routerEa7500v3':
    case 'routerEa7250':
    case 'routerEa7430':
      return 'routerEa7500v3';
    //
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
      return 'routerMx6200';
    //
    case 'routerEa8100':
    case 'routerEa8500':
      return 'routerEa8500';
    //
    case 'routerEa9350':
    case 'routerEa9350v3':
    case 'routerMr9600':
      return 'routerEa9350';
    //
    case 'routerEa9400':
    case 'routerEa9500':
      return 'routerEa9500';
    //
    case 'routerWrt1900ac':
    case 'routerWrt1900asc':
    case 'routerWrt3200acm':
      return 'routerWrt1900ac';
    //
    case 'linksysVelop':
    case 'routerNd001':
    case 'routerNodes':
    case 'routerWhw0301':
    case 'routerWhw03':
    case 'routerMx5500':
    case 'routerMx5600':
    case 'routerMx2000':
      return 'linksysVelop';
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
      return 'routerLn11';
    case 'routerLn12':
      return 'routerLn12';
    default:
      // do router check
      return fallback ?? 'genericDevice';
  }
}

String routerIconTest({required String modelNumber, String? hardwareVersion}) {
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
    final capitalized = modelNumber.capitalized();
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
