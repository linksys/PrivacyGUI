// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';

/// 0 -> input test result json file path
/// 1 -> locs
/// 2 -> screen sizes
/// 3 -> theme (optional)
void main(List<String> args) {
  print(args);
  var testResultJsonPath = './reports/tests.json';
  var fileSuffix = '';
  String? theme;
  // use default path if no args input
  if (args.isNotEmpty) {
    testResultJsonPath = args[0];
  }
  if (args.length > 1) {
    final locs = args[1];
    fileSuffix = '-$locs';
  }
  if (args.length > 3) {
    theme = args[3];
    fileSuffix = '$fileSuffix-$theme';
  }
  File file = File(testResultJsonPath);

  if (!file.existsSync()) {
    throw Exception('Test result does not exist!');
  }

  Stream<List<int>> inputStream = file.openRead();
  final Map<String, dynamic> testResult = {
    'counting': {
      'total': 0,
      'success': 0,
      'fail': 0,
    }
  };

  inputStream
      .transform(utf8.decoder) // Decode bytes to UTF-8.
      .transform(const LineSplitter()) // Convert stream to individual lines.
      .listen((String line) {
    handleTestRecord(line, testResult);
  }, onDone: () {
    // clean up
    final suites = testResult['suites'] as List<Map<String, dynamic>>;
    suites.removeWhere((suite) => suite['groups'] == null);
    for (var suite in suites) {
      final groups = suite['groups'] as List<Map<String, dynamic>>?;
      if (groups != null && groups.length > 1) {
        groups.removeWhere((element) => element['name'] == '');
      }
    }
    //
    // final htmlReport = generateHTMLReport(testResult);
    // final reportHTMLFile = File(testResultHtmlOutputPath);
    // if (!reportHTMLFile.existsSync()) {
    //   reportHTMLFile.createSync(recursive: true);
    // }
    // reportHTMLFile.writeAsStringSync(htmlReport);
    //
    final encoder = JsonEncoder.withIndent('  ');

    final reportJsonFile =
        File('snapshots/localizations-test-reports$fileSuffix.json');
    if (!reportJsonFile.existsSync()) {
      reportJsonFile.createSync(recursive: true);
    }

    // !!! For debug
    // final reportRawJsonFile =
    //     File('snapshots/localizations-test-reports-raw$fileSuffix.json');
    // if (!reportRawJsonFile.existsSync()) {
    //   reportRawJsonFile.createSync(recursive: true);
    // }
    // // RAW json files
    // reportRawJsonFile.writeAsStringSync(encoder.convert(testResult));

    // Extract all test cases as flat list
    final suitesJson = testResult['suites'] as List<Map<String, dynamic>>;
    final groupsJson = suitesJson
        .map((e) => List.from(e['groups']))
        .reduce((value, list) => value..addAll(list));
    final testsJson = groupsJson
        .map((e) => List.from(e['tests']))
        .reduce((value, list) => value..addAll(list));
    reportJsonFile.writeAsStringSync(encoder.convert(testsJson));

    //

    if (!testResult['result']['success']) {
      exit(1);
    }
  }, onError: (e) {
    print(e.toString());
  });
}

handleTestRecord(String record, Map<String, dynamic> testResult) {
  // Process results.
  final json = jsonDecode(record);
  if (json['suite'] != null) {
    // handle suite
    final suiteJson = json['suite'];
    final path = suiteJson['path'] as String? ?? '';
    suiteJson['path'] = path.substring(path.indexOf('/test/'));
    addOrAppendData<Map<String, dynamic>>(testResult, 'suites', suiteJson);
  } else if (json['group'] != null) {
    // handle group
    final groupJson = json['group'];
    final suiteID = groupJson['suiteID'];
    final suites = testResult['suites'] as List<Map<String, dynamic>>;
    final targetSuite =
        suites.firstWhereOrNull((element) => element['id'] == suiteID);
    if (targetSuite == null) {
      return;
    }
    if (groupJson['name'] == '') {
      final testCount = groupJson['testCount'];
      final currentCount = testResult['counting']['total'];
      testResult['counting']['total'] = currentCount + testCount;
      targetSuite['total'] = testCount;
    }
    addOrAppendData<Map<String, dynamic>>(targetSuite, 'groups', groupJson);
  } else if (json['test'] != null) {
    final Map<String, dynamic> testJson = json['test'];
    final suiteID = testJson['suiteID'];
    final groupIDs = List.from(testJson['groupIDs']);
    final suites = testResult['suites'] as List<Map<String, dynamic>>;
    final targetSuite =
        suites.firstWhereOrNull((element) => element['id'] == suiteID);
    if (targetSuite == null) {
      return;
    }
    final testFilePath = targetSuite['path'] ?? '';
    testJson['testCaseFilePath'] = testFilePath;

    final groups = targetSuite['groups'] as List<Map<String, dynamic>>?;
    if (groups == null) {
      return;
    }
    final targetGroups =
        groups.where((element) => groupIDs.contains(element['id']));
    var groupName = '';
    for (var element in targetGroups) {
      if (groupName.isEmpty) {
        groupName = element['name'];
      }
      testJson['name'] =
          (testJson['name'] as String? ?? '').replaceFirst(element['name'], '');
      addOrAppendData<Map<String, dynamic>>(element, 'tests', testJson);
    }
    testJson['groupName'] = groupName;
    // remove unwanted data
    testJson.remove('groupIDs');
    testJson.remove('line');
    testJson.remove('suiteID');
    testJson.remove('column');
    testJson.remove('url');
    testJson.remove('root_line');
    testJson.remove('root_column');
    testJson.remove('root_url');
    extractInfo(testJson);
  } else if (json['testID'] != null) {
    if (json['hidden'] ?? false) {
      return;
    }
    final int testID = json['testID'];
    // find tests by test ID
    final List<Map<String, dynamic>> result = [];
    findTests(testID, testResult, result);
    if (json['result'] != null) {
      if (json['result'] == 'success') {
        if (!json['skipped']) {
          final successCount = testResult['counting']['success'] ?? 0;
          testResult['counting']['success'] = successCount + 1;
        } else {
          final currentCount = testResult['counting']['total'];
          testResult['counting']['total'] = currentCount - 1;
        }
      } else {
        final failCount = testResult['counting']['fail'] ?? 0;
        testResult['counting']['fail'] = failCount + 1;
      }
      for (var element in result) {
        element['result'] = json['result'];
      }
    }
    if (json['message'] != null) {
      for (var element in result) {
        addOrAppendData<String>(element, 'messages', json['message']);
      }
    }
  } else if (json['success'] != null) {
    testResult['result'] = json;
  }
}

extractInfo(Map<String, dynamic> test) {
  final name = test['name'];

  // Try themed pattern first: name (variant: Device-locale-theme(...)
  // Example: "test name (variant: Device480w-en-glass-light(...)"
  // Example with region: "test name (variant: Device480w-zh-TW-glass-light(...)"
  final themedRegex = RegExp(r'(.*) \(variant: (Device\d+w)-([a-z]{2}(?:-[A-Z]{2})?)-([a-z]+-(?:light|dark))\(.*');
  var match = themedRegex.firstMatch(name);

  String? tsName;
  String? deviceType;
  String? locale;
  String? theme;

  if (match != null) {
    // Themed pattern matched
    tsName = match.group(1)?.trim();
    deviceType = match.group(2);
    locale = match.group(3);
    theme = match.group(4);
  } else {
    // Fall back to legacy pattern: name (variant: Device-locale_region(...)
    // Example: "test name (variant: Device480w-en_US(...)"
    final legacyRegex = RegExp(r'(.*) \(variant: (Device\d+w)-(.*)_(.*)\(.*');
    match = legacyRegex.firstMatch(name);
    tsName = match?.group(1)?.trim();
    deviceType = match?.group(2);
    final region = match?.group(4) ?? '';
    locale = (match?.group(3) ?? '').isNotEmpty
        ? '${match?.group(3)}${region.isNotEmpty ? '_$region' : ''}'
        : null;
  }

  String? link;
  if (tsName != null && locale != null && deviceType != null) {
    // Use relative path with optional theme subdirectory
    if (theme != null) {
      link = '$locale/$deviceType/$theme/$tsName-$deviceType-$locale-$theme.png';
      test['theme'] = theme;
    } else {
      link = '$locale/$deviceType/$tsName-$deviceType-$locale.png';
    }
    test['filePath'] = link;
    test['locale'] = locale;
    test['deviceType'] = deviceType;
    test['tsName'] = tsName;
  }
}

addOrAppendData<T>(Map<String, dynamic> json, String key, T data) {
  if (json[key] == null) {
    List<T> list = [];
    json[key] = list;
  }
  json[key].add(data);
}

findTests(
    int testID, Map<String, dynamic> json, List<Map<String, dynamic>> result) {
  if (json['id'] == testID) {
    result.add(json);
  } else {
    for (var entry in json.entries) {
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        findTests(testID, value, result);
      } else if (value is List<Map<String, dynamic>>) {
        for (var element in value) {
          findTests(testID, element, result);
        }
      }
    }
  }
}
