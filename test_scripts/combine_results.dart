import 'dart:convert';
import 'dart:io';

part 'html_generate_functions.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('No folder path provided');
    exit(1);
  }
  final folderStr = args[0];
  final folder = Directory(folderStr);
  if (!folder.existsSync()) {
    print('Folder<$folderStr> does not exist');
    exit(1);
  }
  final version = args[1];
  // find json files on target folder
  final files = folder.listSync().where((e) => e.path.endsWith('.json'));
  // convert json object from files
  final jsonObjects = files
      .map((e) => List.from(jsonDecode(File(e.path).readAsStringSync())))
      .reduce((value, list) => value..addAll(list))
      .map((e) => e as Map<String, dynamic>)
      .toList();
  // collect all the screens
  final Set<String> localeSet = {};
  for (final jsonObject in jsonObjects) {
    final locale = jsonObject['locale'];
    if (locale != null) {
      localeSet.add(locale);
    }
  }
  final locales = localeSet.toList();
  // collect all the devices
  final Set<String> deviceSet = {};
  for (final jsonObject in jsonObjects) {
    final device = jsonObject['deviceType'];
    if (device != null) {
      deviceSet.add(device);
    }
  }
  final devices = deviceSet.toList();

  final resultObj = <String, dynamic>{};
  resultObj['counting'] = {
    'success': jsonObjects.where((e) => e['result'] == 'success').length,
    'fail': jsonObjects.where((e) => e['result'] == 'error').length,
    'total': jsonObjects.length,
  };
  resultObj['tests'] = jsonObjects;
  resultObj['locales'] = locales;
  resultObj['devices'] = devices;
  // write combined json object to file
  // File('$folderStr/combined.json')
  //     .writeAsStringSync(JsonEncoder.withIndent('  ').convert(resultObj));

  final htmlReport = generateHTMLReport(resultObj, version);
  final reportHTMLFile =
      File('$folderStr/screenshot_test_reports_$version.html');
  if (!reportHTMLFile.existsSync()) {
    reportHTMLFile.createSync(recursive: true);
  }
  reportHTMLFile.writeAsStringSync(htmlReport);
}

Map<String, dynamic> combineJsonObjects(
    List<Map<String, dynamic>> jsonObjects) {
  final result = <String, dynamic>{};
  for (final jsonObject in jsonObjects) {
    final keys = jsonObject.keys;
    for (final key in keys) {
      if (result[key] == null) {
        result[key] = jsonObject[key];
      } else {
        if (result[key] is List && jsonObject[key] is List) {
          result[key] = [...result[key] as List, ...jsonObject[key] as List];
        } else if (result[key] is Map && jsonObject[key] is Map) {
          result[key] = {...result[key] as Map, ...jsonObject[key] as Map};
        } else {
          result[key] = jsonObject[key];
        }
      }
    }
  }
  return result;
}
