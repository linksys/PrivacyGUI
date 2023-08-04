import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:linksys_moab/core/utils/icon_rules.dart';

void main() {
  test('test isPlainJsonObj', () {
    const Map<String, dynamic> testJson = {
      'description': 'Linksys Router',
      'test': {
        'model': {
          'manufacturer': 'Cisco|Linksys|Belkin',
          'modelNumber': '^(E|EA|WRT|XAC|MR|MX).+\$',
          'deviceType': 'Infrastructure'
        }
      },
      'iconClass': {'lookup': 'model.modelNumber'}
    };
    const deviceJson = '''
    {"model": {"deviceType": "Infrastructure", "manufacturer": "Linksys", "modelNumber": "MR9500", "hardwareVersion": "1"}}
    ''';
    // final result = isPlainObject(testJson);
    // print(result);
    List<bool> list = [];
    // doAttributesTests(jsonDecode(deviceJson), testJson['test']!, list);
    // print('$list');
    final result = iconTest(jsonDecode(deviceJson));
    print(result);

  });
}
