// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

part 'html_generate_functions.dart';

const _coverageIgnore = ['apps', 'system_log', 'test_console'];

Map<String, dynamic> scanCoverage() {
  final viewDir = Directory('lib/page');
  final testDir = Directory('test/golden_test/page');

  if (!viewDir.existsSync()) {
    return {
      'total': 0,
      'covered': 0,
      'percentage': 0.0,
      'missing': [],
      'covered_list': []
    };
  }

  final viewFiles = viewDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) =>
          f.path.contains('/views/usp_') && f.path.endsWith('_view.dart'))
      .toList();

  final List<String> coveredViews = [];
  final List<String> missingViews = [];

  for (final viewFile in viewFiles) {
    final pathParts = viewFile.path.split('/');
    final pageIndex = pathParts.indexOf('page');
    if (pageIndex == -1 || pageIndex + 1 >= pathParts.length) continue;
    final feature = pathParts[pageIndex + 1];

    if (_coverageIgnore.contains(feature)) continue;

    final testPattern = Directory('${testDir.path}/$feature/localizations');
    if (testPattern.existsSync()) {
      final testFiles = testPattern
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('_test.dart'));
      if (testFiles.isNotEmpty) {
        if (!coveredViews.contains(feature)) coveredViews.add(feature);
        continue;
      }
    }
    if (!missingViews.contains(feature)) missingViews.add(feature);
  }

  final total = coveredViews.length + missingViews.length;
  final percentage = total > 0 ? (coveredViews.length / total * 100.0) : 0.0;

  return {
    'total': total,
    'covered': coveredViews.length,
    'percentage': double.parse(percentage.toStringAsFixed(1)),
    'missing': missingViews..sort(),
    'covered_list': coveredViews..sort(),
  };
}

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
  final version = args.length > 1 ? args[1] : '0.0.0';
  final embedImages = args.contains('--embed');

  // find parsed test report json files on target folder
  final files = folder.listSync().where((e) =>
      e.path.endsWith('.json') &&
      e.uri.pathSegments.last.startsWith('localizations-test-reports'));
  if (files.isEmpty) {
    print('No JSON files found in $folderStr');
    exit(1);
  }
  // convert json object from files
  final jsonObjects = files
      .map((e) => List.from(jsonDecode(File(e.path).readAsStringSync())))
      .reduce((value, list) => value..addAll(list))
      .map((e) => e as Map<String, dynamic>)
      .toList();

  // collect all the locales
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

  // Process failure image paths
  for (final test in jsonObjects) {
    final failureImages = test['failureImages'] as Map<String, dynamic>?;
    if (failureImages == null) continue;
    for (final key in ['expected', 'actual', 'diff']) {
      final path = failureImages[key] as String?;
      if (path == null) continue;
      if (embedImages) {
        final file = File(path);
        if (file.existsSync()) {
          final bytes = file.readAsBytesSync();
          final b64 = base64Encode(bytes);
          failureImages[key] = 'data:image/png;base64,$b64';
        }
      } else {
        // Strip folder prefix so path is relative to the report location
        if (path.startsWith('$folderStr/')) {
          failureImages[key] = path.substring(folderStr.length + 1);
        } else {
          failureImages[key] = path;
        }
      }
    }
  }

  // Scan coverage
  final coverage = scanCoverage();

  final resultObj = <String, dynamic>{};
  resultObj['counting'] = {
    'success': jsonObjects.where((e) => e['result'] == 'success').length,
    'fail': jsonObjects.where((e) => e['result'] == 'error').length,
    'total': jsonObjects.length,
  };
  resultObj['tests'] = jsonObjects;
  resultObj['locales'] = locales;
  resultObj['devices'] = devices;
  resultObj['coverage'] = coverage;
  resultObj['version'] = version;
  resultObj['timestamp'] = DateTime.now().toIso8601String();
  resultObj['embedImages'] = embedImages;

  final htmlReport = generateHTMLReport(resultObj, version);
  final reportHTMLFile = File('$folderStr/golden_verify_report.html');
  if (!reportHTMLFile.existsSync()) {
    reportHTMLFile.createSync(recursive: true);
  }
  reportHTMLFile.writeAsStringSync(htmlReport);
  print('Report generated: ${reportHTMLFile.path}');
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
