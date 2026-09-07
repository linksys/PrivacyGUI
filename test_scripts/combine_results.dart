// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'overflow_details.dart';

part 'html_generate_functions.dart';

const _coverageIgnore = ['apps', 'system_log', 'test_console'];

/// Strip the report folder prefix so [path] is relative to the report location.
String _relativeToReport(String path, String folderStr) {
  if (path.startsWith('$folderStr/')) {
    return path.substring(folderStr.length + 1);
  }
  return path;
}

/// Buckets [records] into the Test Summary panel's numbers.
///
/// `total` is the record count, i.e. the number of rows the report renders, so
/// `total == success + fail` is a check on the parser rather than an identity. On
/// the 2026-08-28 dev run it read 14716 against Pass 13572 because the parser kept
/// the framework's hidden records; it holds now that the parser deletes them
/// (#1404).
///
/// `fail` counts `'error'` and nothing else, deliberately. A golden mismatch
/// reports `result: "error"` — measured against 5016 real failures in the
/// published 2026-08-22..24 dev reports, and mechanically because every golden
/// case is a `testWidgets`, where flutter_test routes both a failed `expect` and
/// a thrown exception through `FlutterErrorDetails` (only a plain `test()`
/// yields `'failure'`). `PrivacyGUI-golden-ci` keys off that same string in
/// `detect_golden_failures.sh` and cross-checks
/// `report_counting.fail == errors_total` in the triage playbook, so widening
/// `fail` here would manufacture anomalies there.
Map<String, int> computeCounting(List<Map<String, dynamic>> records) {
  var success = 0;
  var fail = 0;
  for (final record in records) {
    switch (record['result']) {
      case 'success':
        success++;
      case 'error':
        fail++;
    }
  }
  return {
    'success': success,
    'fail': fail,
    'total': records.length,
  };
}

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

  // Process failure image paths — make them relative to the report location
  for (final test in jsonObjects) {
    final failureImages = test['failureImages'] as Map<String, dynamic>?;
    if (failureImages == null) continue;
    for (final key in ['expected', 'actual', 'diff']) {
      final path = failureImages[key] as String?;
      if (path == null) continue;
      failureImages[key] = _relativeToReport(path, folderStr);
    }
  }

  // Attach the golden image path for every test (including passing ones) so the
  // report can link to the original golden. Goldens live in a `goldens/`
  // directory next to the test file, named `{tsName}-{deviceType}-{locale}.png`.
  for (final test in jsonObjects) {
    final testCaseFilePath = test['testCaseFilePath'] as String?;
    final tsName = test['tsName'] as String?;
    final deviceType = test['deviceType'] as String?;
    final locale = test['locale'] as String?;
    if (testCaseFilePath == null ||
        tsName == null ||
        deviceType == null ||
        locale == null) {
      continue;
    }
    final relativeTestPath = testCaseFilePath.startsWith('/')
        ? testCaseFilePath.substring(1)
        : testCaseFilePath;
    // Strip a trailing slash first, otherwise `/[^/]+$` won't match the last
    // segment and testDir keeps the full path → double-slash goldenPath (404).
    final cleanTestPath = relativeTestPath.endsWith('/')
        ? relativeTestPath.substring(0, relativeTestPath.length - 1)
        : relativeTestPath;
    final testDir = cleanTestPath.replaceFirst(RegExp(r'/[^/]+$'), '');
    final goldenPath = '$testDir/goldens/$tsName-$deviceType-$locale.png';
    test['goldenPath'] = _relativeToReport(goldenPath, folderStr);
  }

  // Scan coverage
  final coverage = scanCoverage();

  // Load overflow warnings
  final overflowReport = loadOverflowReport();
  final overflowDetails = overflowReport.byGolden;

  // Annotate tests with overflow info by reconstructing golden name
  for (final test in jsonObjects) {
    final tsName = test['tsName'] as String? ?? '';
    final deviceType = test['deviceType'] as String? ?? '';
    final locale = test['locale'] as String? ?? '';
    final goldenName = '$tsName-$deviceType-$locale';
    final sites = overflowDetails[goldenName] ?? const [];
    // `false` here is read by golden CI's triage agent as "this golden is clean"
    // and by nothing else (`triage-agent/collector.py`, which never looks at
    // `overflowSites`). When the report could not be read, that reading is not
    // available for any row — see `overflowReportUnreadable` below, which is the
    // flag a consumer has to check before believing this one.
    test['hasOverflow'] = sites.isNotEmpty;
    // Carry the site detail so the row can name the culprit instead of only
    // flagging that something overflowed (#1197).
    test['overflowSites'] = sites.map((s) => s.toJson()).toList();
  }

  final resultObj = <String, dynamic>{};
  resultObj['counting'] = computeCounting(jsonObjects);
  resultObj['tests'] = jsonObjects;
  resultObj['locales'] = locales;
  resultObj['devices'] = devices;
  resultObj['coverage'] = coverage;
  // Count affected goldens, not raw records: Flutter reports an overflow per
  // RenderObject, so counting records inflated the stat and disagreed with the
  // gallery report's own count for the same run (#1197).
  resultObj['overflowCount'] = overflowDetails.length;
  // One table for the whole report, referenced by index from each site: the same
  // culprit appears in every golden that renders it, and a dump runs 2-4KB
  // (#1197).
  resultObj['overflowLogs'] = overflowReport.logs;
  // Present only when the overflow half of this report is unknown, so a reader
  // that does not know the key still sees nothing surprising, and one that checks
  // it can tell "0 overflows" from "0 overflows readable". Absent is the normal
  // case, including a run that genuinely overflowed nothing.
  if (overflowReport.unreadable != null) {
    resultObj['overflowReportUnreadable'] = overflowReport.unreadable;
  }
  resultObj['version'] = version;
  resultObj['timestamp'] = DateTime.now().toIso8601String();

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
