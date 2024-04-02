/*
        For Velop/Genesis project:

        Original Velop -

            nd0001      HW1/sample units
            Nodes       HW2
            WHW0301     HW3
            WHW03       Official Model Number
            WHW03B      Black Model Number
            A03         Apple SKU

        Velop Jr -

            WHW01       Official Model Number
            WHW01B      Black Model Number
            VLP01       Walmart SKU
            VLP01B      Black Walmart SKU
            A01         Apple SKU

        Velop Plugin -

            WHW01P      Official Model Number

        Rhodes Node -

            MX2000          Official Model Number (currently not used)
            MX2000 Series   Model Number to show for all SKU Variants (when modelNumber starts with 'MX20')

        Chiron Node -

            MX4200          Official Model Number (currently not used)
            MX4000 Series   Model Number to show for all SKU Variants (when modelNumber starts with 'MX42')

        Bronx Node -

            MX5400      HW1/sample units
            MX5300      Official Model Number

        Dominica Node -

            MX5500          Official Model Number (currently not used)
            MX5500 Series   Model Number to show for all SKU Variants (when modelNumber is 'MX5500')

        Boston Node - uses same data as Dominica

            MX5500ST        Official Model Number (currently not used)
            MX5500 Series   Model Number to show for all SKU Variants (when modelNumber is 'MX5500ST')

        Maple Node (Cognitive Mesh) -

            MX6200          Official Model Number (currently not used)
            MX6200 Series   Model Number to show for all SKU Variants (when modelNumber starts with 'MX62')

        Diablo Node -

            MX8500      Official Model Number

        Veyron Mesh Router -

            MR2000          Official Model Number (currently not used)
            MR2000 Series   Model Number to show for all SKU Variants (when modelNumber starts with 'MR20')

        Jamaica Mesh Router -

            MR5500      Official Model Number

        Fiat Mesh Router -

            MR6350      Official Model Number
            MR6320      Club SKU (Sam's Club, Walmart, Costco, etc.)
            MR6330      "
            MR6340      "

        Elise Mesh Router -

            MR7350          Official Model Number (currently not used)
            MR7300 Series   Model Number to show for all SKU Variants (when modelNumber starts with 'MR73')

        Divo Mesh Router -

            MR7500          Official Model Number (currently not used)
            MR7500 Series   Model Number to show for all SKU Variants (when modelNumber starts with 'MR75')
            MR75WH          Costco SKU

        Rogue Mesh Router -

            MR8300   Official Model Number
            MR8250   Walmart SKU

        Lion Mesh Router -

            MR9000   Official Model Number
            MR8900   Club SKU (Sam's Club, Walmart, Costco, etc.)
            MR8950   "
            MR9100   "

        Bobcat Mesh Router -

            MR9600          Official Model Number (currently not used)
            MR9600 Series   Model Number to show for all SKU Variants

        Watercar Mesh Router -

            EA9350v3        Official Model Number

    */
import 'package:collection/collection.dart';
import 'package:linksys_app/core/cache/linksys_cache_manager.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/main.dart';

const List<Map<String, dynamic>> _velopModelMap = [
  {
    'model': 'WHW03B',
    'baseModel': 'WHW03',
    'isMeshRouter': false,
    'pattern': 'whw03b'
  },
  {
    'model': 'WHW03',
    'baseModel': 'WHW03',
    'isMeshRouter': false,
    'pattern': 'nd0001|nodes|whw0301|whw03|a03'
  },
  {
    'model': 'WHW01P',
    'baseModel': 'WHW01',
    'isMeshRouter': false,
    'pattern': 'whw01p'
  },
  {
    'model': 'WHW01B',
    'baseModel': 'WHW01',
    'isMeshRouter': false,
    'pattern': 'whw01b|vlp01b'
  },
  {
    'model': 'WHW01',
    'baseModel': 'WHW01',
    'isMeshRouter': false,
    'pattern': 'whw01|vlp01|a01'
  },
  {
    'model': 'MR7350',
    'baseModel': 'MR7350',
    'isMeshRouter': true,
    'pattern': 'mr7350'
  },
  {
    'model': 'MR7350',
    'baseModel': 'MR7350',
    'seriesModel': 'MR7300',
    'isMeshRouter': true,
    'pattern': '^mr73'
  },
  {
    'model': 'MR6350',
    'baseModel': 'MR6350',
    'isMeshRouter': true,
    'pattern': 'mr6350|mr6320|mr6330|mr6340'
  },
  {
    'model': 'MR8300',
    'baseModel': 'MR8300',
    'isMeshRouter': true,
    'pattern': 'mr8300|mr8250|mr9000|mr8900|mr8950|mr9100'
  },
  {
    'model': 'MR9600',
    'baseModel': 'MR9600',
    'seriesModel': 'MR9600',
    'isMeshRouter': true,
    'pattern': 'mr9600'
  },
  {
    'model': 'MR7500',
    'baseModel': 'MR7500',
    'seriesModel': 'MR7500',
    'isMeshRouter': true,
    'pattern': '^mr75'
  },
  {
    'model': 'MR5500',
    'baseModel': 'MR5500',
    'isMeshRouter': true,
    'pattern': 'mr5500'
  },
  {
    'model': 'MR2000',
    'baseModel': 'MR2000',
    'seriesModel': 'MR2000',
    'isMeshRouter': true,
    'pattern': '^mr20'
  },
  {
    'model': 'MX5300',
    'baseModel': 'MX5300',
    'isMeshRouter': false,
    'pattern': 'mx5400|mx5300'
  },
  {
    'model': 'MX4200',
    'baseModel': 'MX4200',
    'seriesModel': 'MX4000',
    'isMeshRouter': false,
    'pattern': '^mx42|mx4000'
  },
  {
    'model': 'MX8500',
    'baseModel': 'MX8500',
    'seriesModel': 'MX8500',
    'isMeshRouter': false,
    'pattern': '^mx85'
  },
  {
    'model': 'MX5500',
    'baseModel': 'MX5500',
    'seriesModel': 'MX5500',
    'isMeshRouter': false,
    'pattern': 'mx5500'
  },
  {
    'model': 'MX2000',
    'baseModel': 'MX2000',
    'seriesModel': 'MX2000',
    'isMeshRouter': false,
    'pattern': '^mx20'
  },
  {
    'model': 'MX6200',
    'baseModel': 'MX6200',
    'seriesModel': 'MX6200',
    'isMeshRouter': false,
    'isCognitiveMesh': true,
    'pattern': '^mx62'
  },
  {
    'model': 'MBE7000',
    'baseModel': 'MBE7000',
    'seriesModel': 'MBE7000',
    'isMeshRouter': false,
    'isCognitiveMesh': true,
    'pattern': '^mbe70',
  },
  {
    'model': 'LN11',
    'baseModel': 'LN11',
    'seriesModel': 'LN11',
    'isMeshRouter': false,
    'isCognitiveMesh': true,
    'pattern': 'ln11',
  },
  {
    'model': 'LN12',
    'baseModel': 'LN12',
    'seriesModel': 'LN12',
    'isMeshRouter': false,
    'isCognitiveMesh': true,
    'pattern': 'ln12',
  },
  {
    'model': 'EA9350',
    'hardwareVersions': ['3'],
    'baseModel': 'EA9350',
    'isMeshRouter': true,
    'pattern': 'ea9350'
  },
  {
    'model': 'WHW03', // Node fallback
    'baseModel': 'WHW03',
    'isMeshRouter': false,
    'pattern': '^a|^mx|^whw|^vlp'
  },
  {
    'model': 'MR8300', // Mesh Router fallback
    'baseModel': 'MR8300',
    'isMeshRouter': true,
    'pattern': '^mr'
  }
];

// array describing the Children that are compatible with a given Parent Cognitive Mesh Node
const List<Map<String, dynamic>> _cognitiveMeshCompatibilityMap = [
  {
    'parentModel': 'MX6200',
    'compatibleChildren': [
      {'model': 'MX6200'},
      {'model': 'MBE7000'}
    ]
  },
  {
    'parentModel': 'MBE7000',
    'compatibleChildren': [
      {'model': 'MBE7000'},
      {'model': 'MX6200'}
    ]
  },
  {
    'parentModel': 'LN11',
    'compatibleChildren': [
      {'model': 'LN11'},
      {'model': 'LN12'}
    ]
  },
  {
    'parentModel': 'LN12',
    'compatibleChildren': [
      {'model': 'LN12'},
      {'model': 'LN11'}
    ]
  }
];

dynamic doVelopModelTests({
  required String modelNumber,
  required String hardwareVersion,
  required String paramName,
  String? paramAlt,
}) {
  var out = _velopModelMap.firstWhereOrNull((rule) {
    final List<String>? hwVersions = rule['hardwareVersions'];
    return RegExp(rule['pattern'], caseSensitive: false)
            .hasMatch(modelNumber) &&
        ((hwVersions?.indexOf(hardwareVersion) ?? 0) > -1);
  })?[paramName];

  if (paramAlt != null && out == null) {
    out = paramAlt;
  }
  return out;
}

String? treatAsModes({
  required String modelNumber,
  required String hardwareVersion,
}) {
  return doVelopModelTests(
    modelNumber: modelNumber,
    hardwareVersion: hardwareVersion,
    paramName: 'model',
  );
}

String baseModel({
  required String modelNumber,
  required String hardwareVersion,
}) {
  return doVelopModelTests(
    modelNumber: modelNumber,
    hardwareVersion: hardwareVersion,
    paramName: 'baseModel',
  );
}

String seriesModel({
  required String modelNumber,
  required String hardwareVersion,
}) {
  return doVelopModelTests(
    modelNumber: modelNumber,
    hardwareVersion: hardwareVersion,
    paramName: 'seriesModel',
    paramAlt: '',
  );
}

bool isNodeModel({
  required String modelNumber,
  required String hardwareVersion,
}) {
  return treatAsModes(
        modelNumber: modelNumber,
        hardwareVersion: hardwareVersion,
      ) !=
      null;
}

bool isMeshRouter({
  required String modelNumber,
  required String hardwareVersion,
}) {
  return doVelopModelTests(
          modelNumber: modelNumber,
          hardwareVersion: hardwareVersion,
          paramName: 'isMeshRouter') ??
      false;
}

bool isCognitiveMeshRouter({
  required String modelNumber,
  required String hardwareVersion,
}) {
  return doVelopModelTests(
          modelNumber: modelNumber,
          hardwareVersion: hardwareVersion,
          paramName: 'isCognitiveMesh') ??
      false;
}

bool isServiceSupport(JNAPService service) {
  final provider = container.read(linksysCacheManagerProvider);
  if (provider.data[JNAPAction.getDeviceInfo.actionValue] != null) {
    for (var item in provider.data[JNAPAction.getDeviceInfo.actionValue]['data']
        ['output']['services']) {
      if ((item as String).contains(service.value)) {
        return true;
      }
    }
    return false;
  }
  return false;
}
