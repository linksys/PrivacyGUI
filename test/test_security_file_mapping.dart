import 'dart:convert';
import 'dart:io';

import 'package:linksys_moab/security/app_signature.dart';
import 'package:test/test.dart';
// TODO revise it
void main() {
  group('test security file mapping', () {
    test('test load fw file', () async {
      final file = File('assets/test/fcn_application.name.json');
      final fwJsonArray = List.from(jsonDecode(file.readAsStringSync()));
      expect(fwJsonArray.isNotEmpty, true);
    });

    test('test fw model transfer', () async {
      final file = File('assets/test/fcn_application.name.json');
      final fwJsonArray = List.from(jsonDecode(file.readAsStringSync()));
      final List<AppSignature> fwAppSignatureList =
          List.from(fwJsonArray.map((e) => AppSignature.fromJson(e)));
      expect(fwAppSignatureList.isNotEmpty, true);

      ///  {
      ///     "name": "GTunnel",
      ///     "id": "17540",
      ///     "category": "6",
      ///     "popularity": "1",
      ///     "risk": "5",
      ///     "weight": "10",
      ///     "technology": "2.Client-Server",
      ///     "behavior": "6.Tunneling",
      ///     "protocol": "1.TCP, 9.HTTP"
      ///   }
      ///
      expect(fwAppSignatureList[0].name, 'GTunnel');
      expect(fwAppSignatureList[0].id, '17540');
      expect(fwAppSignatureList[0].category, '6');
      expect(fwAppSignatureList[0].popularity, '1');
      expect(fwAppSignatureList[0].risk, '5');
      expect(fwAppSignatureList[0].weight, '10');
      expect(fwAppSignatureList[0].technology, '2.Client-Server');
      expect(fwAppSignatureList[0].behavior, '6.Tunneling');
      expect(fwAppSignatureList[0].protocol, '1.TCP, 9.HTTP');
    });

    test('test load cloud file', () async {
      final file = File('assets/test/app-signatures.json');
      final cloudJsonArray = List.from(jsonDecode(file.readAsStringSync()));
      expect(cloudJsonArray.isNotEmpty, true);
    });

    test('test cloud model transfer', () async {
      final file = File('assets/test/app-signatures.json');
      final cloudJsonArray = List.from(jsonDecode(file.readAsStringSync()));
      final List<CloudAppSignature> list =
          List.from(cloudJsonArray.map((e) => CloudAppSignature.fromJson(e)));
      expect(list.isNotEmpty, true);

      ///
      /// {
      ///     "name": "126.Mail",
      ///     "id": 16554,
      ///     "categoryName": "Email",
      ///     "category": 21,
      ///     "behavior": "",
      ///     "language": "Chinese",
      ///     "popularity": 4,
      ///     "risk": 3,
      ///     "technology": "Browser-Based",
      ///     "vendor": "Netease",
      ///     "isCloud": "No",
      ///     "requireSSLInspection": "No"
      ///   }
      ///
      expect(list[0].name, '126.Mail');
      expect(list[0].id, '16554');
      expect(list[0].categoryName, 'Email');
      expect(list[0].category, '21');
      expect(list[0].behavior, '');
      expect(list[0].language, 'Chinese');
      expect(list[0].popularity, '4');
      expect(list[0].risk, '3');
      expect(list[0].technology, 'Browser-Based');
      expect(list[0].vendor, 'Netease');
      expect(list[0].isCloud, 'No');
      expect(list[0].requireSSLInspection, 'No');
    });

    test('test load security presets', () async {
      final file = File('assets/test/security-category-presets.json');
      final presetsJsonArray = List.from(jsonDecode(file.readAsStringSync()));
      expect(presetsJsonArray.isNotEmpty, true);
    });

    test('test security presets model transfer', () async {
      final file = File('assets/test/security-category-presets.json');
      final presetsJsonArray = List.from(jsonDecode(file.readAsStringSync()));
      final List<SecurityPresets> list =
      List.from(presetsJsonArray.map((e) => SecurityPresets.fromJson(e)));
      expect(list.isNotEmpty, true);
      ///   Partial data
      ///   {
      ///     "name": "Adult & sexually explicit",
      ///     "identifier": "ADULT1",
      ///     "rules": [
      ///       {
      ///         "target": "webfilter",
      ///         "expression": {
      ///           "field": "categoryId",
      ///           "value": "13"
      ///         }
      ///       },
      ///       {
      ///         "target": "webfilter",
      ///         "expression": {
      ///           "field": "categoryId",
      ///           "value": "14"
      ///         }
      ///       },
      ///   }
      ///
      expect(list[0].name, 'Adult & sexually explicit');
      expect(list[0].identifier, 'ADULT1');
      expect(list[0].rules[0].target, 'webfilter');
      expect(list[0].rules[0].expression.field, 'categoryId');
      expect(list[0].rules[0].expression.value, '13');
      expect(list[0].rules[1].target, 'webfilter');
      expect(list[0].rules[1].expression.field, 'categoryId');
      expect(list[0].rules[1].expression.value, '14');
    });

    test('test mapping fw and cloud data', () async {
      final fwFile = File('assets/test/fcn_application.name.json');
      final fwJsonArray = List.from(jsonDecode(fwFile.readAsStringSync()));
      final fwList = List<MapEntry<String, AppSignature>>.from(fwJsonArray
          .map((e) => AppSignature.fromJson(e))
          .map((e) => MapEntry(e.id, e)));
      final Map<String, AppSignature> fwMap = Map.fromEntries(fwList);

      final cloudFile = File('assets/test/app-signatures.json');
      final cloudJsonArray =
          List.from(jsonDecode(cloudFile.readAsStringSync()));
      final cloudList = List<MapEntry<String, CloudAppSignature>>.from(
          cloudJsonArray
              .map((e) => CloudAppSignature.fromJson(e))
              .map((e) => MapEntry(e.id, e)));
      final Map<String, CloudAppSignature> cloudMap =
          Map.fromEntries(cloudList);

      // final result = cloudMap.map((key, value) =>
      //     MapEntry(key, fwMap.containsKey(key) ? value.copyWithAppSignature(signature: fwMap[key]!) : value));
      // print(result.length);
      // print('result: ${result.keys.first}');

      final result = fwMap.map((key, value) => MapEntry(
            key,
            cloudMap.containsKey(key)
                ? cloudMap[key]!.copyWithAppSignature(signature: value)
                : CloudAppSignature.fromAppSignature(value),
          ));

      print(result.length);
      print('result: ${result.keys.first}');
      File('assets/test/output.json').writeAsStringSync(jsonEncode(List.from(result.values)));
    });

    test('test mapping preset rules', () async {
      final fwFile = File('assets/test/fcn_application.name.json');
      final fwJsonArray = List.from(jsonDecode(fwFile.readAsStringSync()));
      final fwList = List<MapEntry<String, AppSignature>>.from(fwJsonArray
          .map((e) => AppSignature.fromJson(e))
          .map((e) => MapEntry(e.id, e)));
      final Map<String, AppSignature> fwMap = Map.fromEntries(fwList);

      final cloudFile = File('assets/test/app-signatures.json');
      final cloudJsonArray =
      List.from(jsonDecode(cloudFile.readAsStringSync()));
      final cloudList = List<MapEntry<String, CloudAppSignature>>.from(
          cloudJsonArray
              .map((e) => CloudAppSignature.fromJson(e))
              .map((e) => MapEntry(e.id, e)));
      final Map<String, CloudAppSignature> cloudMap =
      Map.fromEntries(cloudList);

      final result = fwMap.map((key, value) => MapEntry(
        key,
        cloudMap.containsKey(key)
            ? cloudMap[key]!.copyWithAppSignature(signature: value)
            : CloudAppSignature.fromAppSignature(value),
      ));

      final signatureList = result.values;

      print(result.length);
      print('result: ${result.keys.first}');



      final presetFile = File('assets/test/security-category-presets.json');
      final presetsJsonArray = List.from(jsonDecode(presetFile.readAsStringSync()));
      final List<SecurityPresets> presetList =
      List.from(presetsJsonArray.map((e) => SecurityPresets.fromJson(e)));

      List<CloudAppSignature> signatures = [];
      for (var preset in presetList) {
          for (var rule in preset.rules.where((element) => element.target == 'application')) {
            Iterable<CloudAppSignature> query = [];
            switch(rule.expression.field) {
              case 'categoryId':
                query = signatureList.where((element) {
                  print('categoryId:: ${element.category}, ${rule.expression.value}');
                  return element.category == rule.expression.value;
                });
                break;
              case 'vendor':
                query = signatureList.where((element) {
                  print('vendor:: ${element.vendor}, ${rule.expression.value}');
                  return element.vendor == rule.expression.value;
                });
                break;
            }
            if (query.isNotEmpty) {
              signatures.addAll(query);
            }
          }
      }
      print('application signature length: ${signatures.length}');
    });
  });
}
