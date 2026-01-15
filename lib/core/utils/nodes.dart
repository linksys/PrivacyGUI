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

        Oak Node (Cognitive Mesh) -

            MBE7000          Official Model Number (currently not used)
            MBE7000 Series   Model Number to show for all SKU Variants (when modelNumber starts with 'MBE70')

        Oak SP1  (Cognitive Mesh) -

            MBE7100          Official Model Number (currently not used)
            MBE7100 Series   Model Number to show for all SKU Variants (when modelNumber starts with 'MBE71')

        Elm (Cognitive Mesh) -

            LN11             Official Model Number (currently not used)
            LN11 Series      Model Number to show for all SKU Variants (when modelNumber starts with 'LN11')

        Cherry (Cognitive Mesh) -

            LN12             Official Model Number (currently not used)
            LN12 Series      Model Number to show for all SKU Variants (when modelNumber starts with 'LN12')

        Pinnacle -

            SPNM60

    */
import 'package:collection/collection.dart';
import 'package:privacy_gui/core/cache/linksys_cache_manager.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/main.dart';

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
    'model': 'MX5600',
    'baseModel': 'MX5600',
    'seriesModel': 'MX5600',
    'isMeshRouter': false,
    'pattern': 'mx56'
  },
  {
    'model': 'MX5700',
    'baseModel': 'MX5700',
    'seriesModel': 'MX5700',
    'isMeshRouter': false,
    'pattern': '^mx57'
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
    'model': 'MBE7100',
    'baseModel': 'MBE7100',
    'seriesModel': 'MBE7100',
    'isMeshRouter': false,
    'isCognitiveMesh': true,
    'pattern': '^mbe71',
  },
  {
    'model': 'LN11',
    'baseModel': 'LN11',
    'seriesModel': 'LN11',
    'isMeshRouter': false,
    'isCognitiveMesh': true,
    'isHorizontalPorts': true,
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
    'model': 'LN14',
    'baseModel': 'LN14',
    'seriesModel': 'LN14',
    'isMeshRouter': false,
    'isCognitiveMesh': true,
    'pattern': 'ln14',
  },
  {
    'model': 'LN15',
    'baseModel': 'LN15',
    'seriesModel': 'LN15',
    'isMeshRouter': false,
    'isCognitiveMesh': true,
    'pattern': 'ln15',
  },
  {
    'model': 'LN16',
    'baseModel': 'LN16',
    'seriesModel': 'LN16',
    'isMeshRouter': false,
    'isCognitiveMesh': true,
    'pattern': 'ln16',
  },
  {
    'model': 'SPNM60',
    'baseModel': 'SPNM60',
    'seriesModel': 'SPNM60',
    'isMeshRouter': false,
    'isCognitiveMesh': true,
    'pattern': '^spnm60',
  },
  {
    'model': 'SPNM61',
    'baseModel': 'SPNM61',
    'seriesModel': 'SPNM61',
    'isMeshRouter': false,
    'isCognitiveMesh': true,
    'pattern': '^spnm61',
  },
  {
    'model': 'SPNM62',
    'baseModel': 'SPNM62',
    'seriesModel': 'SPNM62',
    'isMeshRouter': false,
    'isCognitiveMesh': true,
    'pattern': '^spnm62',
  },
  {
    'model': 'M60',
    'baseModel': 'M60',
    'seriesModel': 'M60',
    'isMeshRouter': false,
    'isCognitiveMesh': true,
    'pattern': '^m60',
  },
  {
    'model': 'M61',
    'baseModel': 'M61',
    'seriesModel': 'M61',
    'isMeshRouter': false,
    'isCognitiveMesh': true,
    'pattern': '^m61',
  },
  {
    'model': 'M62',
    'baseModel': 'M62',
    'seriesModel': 'M62',
    'isMeshRouter': false,
    'isCognitiveMesh': true,
    'pattern': '^m62',
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

bool isServiceSupport(JNAPService service, [List<String>? services]) {
  final provider = container.read(linksysCacheManagerProvider);

  if (services != null ||
      provider.data[JNAPAction.getDeviceInfo.actionValue] != null) {
    final currentServices = services ??
        provider.data[JNAPAction.getDeviceInfo.actionValue]['data']['output']
            ['services'] as List<dynamic>? ??
        [];
    return currentServices.contains(service.value);
  }
  return false;
}

bool isHorizontalPorts({
  required String modelNumber,
  required String hardwareVersion,
}) =>
    doVelopModelTests(
        modelNumber: modelNumber,
        hardwareVersion: hardwareVersion,
        paramName: 'isHorizontalPorts') ??
    false;

bool isShowSpeedTest({
  required String modelNumber,
  String hardwareVersion = '1',
}) {
  return !(doVelopModelTests(
          modelNumber: modelNumber,
          hardwareVersion: hardwareVersion,
          paramName: 'noSpeedTest') ??
      false);
}
