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
      final file = File('assets/test/fg_applications_20.317.json');
      final cloudJsonArray = List.from(jsonDecode(file.readAsStringSync()));
      expect(cloudJsonArray.isNotEmpty, true);
    });

    test('test cloud model transfer', () async {
      final file = File('assets/test/fg_applications_20.317.json');
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

    test('test mapping fw and cloud data', () async {
      final fwFile = File('assets/test/fcn_application.name.json');
      final fwJsonArray = List.from(jsonDecode(fwFile.readAsStringSync()));
      final fwList = List<MapEntry<String, AppSignature>>.from(fwJsonArray
          .map((e) => AppSignature.fromJson(e))
          .map((e) => MapEntry(e.id, e)));
      final Map<String, AppSignature> fwMap = Map.fromEntries(fwList);

      final cloudFile = File('assets/test/fg_applications_20.317.json');
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
  });
}
