/// Static icon rule definitions and mapping tables for device icon resolution.
///
/// This file contains only DATA — no logic. See `icon_rules.dart` for the
/// matching engine that consumes these rules.

/// A list of rules used to determine the appropriate icon for a network device.
///
/// Each rule in the list is a `Map` with the following structure:
/// - `description`: A `String` describing the rule's purpose.
/// - `test`: A `Map` defining the conditions to match against a device's data.
///   The keys in this map correspond to properties of the device (e.g., 'model',
///   'friendlyName'), and the values are `RegExp` patterns to test against.
///   The structure can be nested to match properties within nested objects.
/// - `iconClass`: A `String` or `Map` representing the icon to be used if the
///   test passes. If it's a string, it's the name of the icon class. If it's a
///   map (e.g., `{'lookup': 'model.modelNumber'}`), the icon name is derived
///   dynamically from the device's data.
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
    'description': 'Linksys LN14 (LN14/Oak SP1 Variants; "LN14 Series")',
    'test': {
      'model': {
        'manufacturer': 'Linksys',
        'modelNumber': '^ln14',
      },
    },
    'iconClass': 'routerLn14',
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
    'description': 'Linksys M61 (M61/Pinnacle 2.1)',
    'test': {
      'model': {
        'manufacturer': 'Linksys',
        'modelNumber': '^m61',
      },
    },
    'iconClass': 'routerM61',
  },
  {
    'description': 'Linksys M62 (M62/Pinnacle 2.2)',
    'test': {
      'model': {
        'manufacturer': 'Linksys',
        'modelNumber': '^m62',
      },
    },
    'iconClass': 'routerM62',
  },
  {
    'description': 'Linksys M60 (M60/Pinnacle 2.0)',
    'test': {
      'model': {
        'manufacturer': 'Linksys',
        'modelNumber': '^m60',
      },
    },
    'iconClass': 'routerM60',
  },
  {
    'description': 'Linksys Router (modelNumber passthrough)',
    'test': {
      'model': {
        'manufacturer': 'Cisco|Linksys|Belkin',
        'modelNumber': r'^(E|EA|WRT|XAC|MR|MX|LN|MBE).+$',
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
        'modelNumber': r' /^(MR|MX|LN|MBE).+$',
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

/// A smaller, sample list of icon rules, likely used for testing purposes.
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

/// Maps a specific `iconClass` to a consolidated icon asset name.
///
/// Multiple router model icon classes may map to the same final icon asset,
/// reducing the number of unique icon assets required.
const Map<String, String> iconMappingTable = {
  'routerMr7350': 'routerMr7350',
  'routerMr5500': 'routerMr7350',
  'routerMr2000': 'routerMr7350',
  'routerMr7500': 'routerMr7500',
  'routerEa8250': 'routerEa8300',
  'routerEa8300': 'routerEa8300',
  'routerMr8250': 'routerEa8300',
  'routerMr8300': 'routerEa8300',
  'routerMr8900': 'routerEa8300',
  'routerMr8950': 'routerEa8300',
  'routerMr9000': 'routerEa8300',
  'routerMr9100': 'routerEa8300',
  'linksysMesh': 'routerEa8300',
  'routerMx5400': 'routerMx5300',
  'routerMx5300': 'routerMx5300',
  'routerMx4200': 'routerMx5300',
  'routerMx8500': 'routerMx5300',
  'routerMx6200': 'routerMx6200',
  'routerMbe7000': 'routerMx6200',
  'routerMbe7100': 'routerMx6200',
  'routerLN6001': 'routerMx6200',
  'routerLN6002': 'routerMx6200',
  'routerLn14': 'routerMx6200',
  'routerSpnm60': 'routerMx6200',
  'routerSpnm61': 'routerMx6200',
  'routerSpnm62': 'routerMx6200',
  'routerM60': 'routerMx6200',
  'routerM61': 'routerMx6200',
  'routerM62': 'routerMx6200',
  'routerEa9350': 'routerEa9350',
  'routerEa9350v3': 'routerEa9350',
  'routerMr9600': 'routerEa9350',
  'linksysVelop': 'routerWhw03',
  'routerNd001': 'routerWhw03',
  'routerNodes': 'routerWhw03',
  'routerWhw0301': 'routerWhw03',
  'routerWhw03': 'routerWhw03',
  'routerMx5500': 'routerWhw03',
  'routerMx5600': 'routerWhw03',
  'routerMx5700': 'routerWhw03',
  'routerMx2000': 'routerWhw03',
  'routerWhw01': 'routerWhw01',
  'routerVlp01': 'routerWhw01',
  'routerA01': 'routerWhw01',
  'routerWhw01b': 'routerWhw01b',
  'routerVlp01b': 'routerWhw01b',
  'routerLn11': 'routerLn11',
  'routerLn15': 'routerLn11',
  'routerLn12': 'routerLn12',
  'routerLn16': 'routerLn12',
};

/// Default fallback icon when no mapping is found.
const String defaultRouterIcon = 'routerLn12';
