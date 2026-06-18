// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';

/// 0 -> input test result json file path
/// 1 -> locs
/// 2 -> screen sizes
void main(List<String> args) {
  print(args);
  var testResultJsonPath = './reports/tests.json';
  var fileSuffix = '';
  // use default path if no args input
  if (args.isNotEmpty) {
    testResultJsonPath = args[0];
  }
  if (args.length > 1) {
    final locs = args[1];
    fileSuffix = '-$locs';
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

    final outputDir = File(testResultJsonPath).parent.path;
    final reportJsonFile =
        File('$outputDir/localizations-test-reports$fileSuffix.json');
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
    final suitesJson =
        testResult['suites'] as List<Map<String, dynamic>>? ?? [];
    if (suitesJson.isEmpty) {
      reportJsonFile.writeAsStringSync(encoder.convert([]));
      print('No test suites found in results');
      return;
    }
    final groupsJson = suitesJson
        .where((e) => e['groups'] != null)
        .map((e) => List.from(e['groups']))
        .fold<List>([], (value, list) => value..addAll(list));
    final testsJson = groupsJson
        .where((e) => e['tests'] != null)
        .map((e) => List.from(e['tests']))
        .fold<List>([], (value, list) => value..addAll(list));

    // Extract failure images for failed tests (after all metadata is populated)
    for (final test in testsJson) {
      if (test is Map<String, dynamic> && test['result'] == 'error') {
        extractFailureImages(test);
      }
    }

    reportJsonFile.writeAsStringSync(encoder.convert(testsJson));

    //

    if (testResult['result'] != null && !testResult['result']['success']) {
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

  // New golden framework format: " viewName - state - device - locale (variant: ...)"
  final newRegex =
      RegExp(r'\s*(\w+)\s*-\s*(\w+)\s*-\s*(\w+)\s*-\s*(\w+)\s*\(variant:');
  final newMatch = newRegex.firstMatch(name);
  if (newMatch != null) {
    final viewName = newMatch.group(1)!;
    final state = newMatch.group(2)!;
    final deviceType = newMatch.group(3)!;
    final locale = newMatch.group(4)!;
    final tsName = '$viewName-$state';
    test['filePath'] = '$locale/$deviceType/$tsName-$deviceType-$locale.png';
    test['locale'] = locale;
    test['deviceType'] = deviceType;
    test['tsName'] = tsName;
    return;
  }

  // Legacy format: "name (variant: device-locale_region(...)"
  final regex = RegExp(r'(.*) \(variant: (.*)-(.*)_(.*)\(.*');
  final match = regex.firstMatch(name);
  final tsName = match?.group(1)?.trim();
  final deviceType = match?.group(2);
  final region = match?.group(4) ?? '';
  final locale = (match?.group(3) ?? '').isNotEmpty
      ? '${match?.group(3)}${region.isNotEmpty ? '_$region' : ''}'
      : null;
  if (tsName != null && locale != null && deviceType != null) {
    test['filePath'] = '$locale/$deviceType/$tsName-$deviceType-$locale.png';
    test['locale'] = locale;
    test['deviceType'] = deviceType;
    test['tsName'] = tsName;
  }
}

extractFailureImages(Map<String, dynamic> test) {
  final messages = test['messages'] as List<String>?;
  if (messages == null || messages.isEmpty) return;

  final fullMessage = messages.join('\n');

  // Strategy 1: Parse failure image paths from error message
  final failurePathRegex = RegExp(r'([\w/._-]+/failures/[\w._-]+\.png)');
  final matches = failurePathRegex.allMatches(fullMessage);

  String? diffPath;
  String? actualPath;
  String? expectedPath;

  if (matches.isNotEmpty) {
    for (final match in matches) {
      final path = match.group(1)!;
      if (path.contains('isolatedDiff') || path.contains('maskedDiff')) {
        diffPath = path;
      } else if (path.contains('testImage')) {
        actualPath = path;
      } else if (path.contains('masterImage')) {
        expectedPath = path;
      }
    }
  }

  // Strategy 2: Infer paths from test metadata (for Alchemist golden tests)
  if (actualPath == null && expectedPath == null) {
    final testCaseFilePath = test['testCaseFilePath'] as String?;
    final tsName = test['tsName'] as String?;
    final deviceType = test['deviceType'] as String?;
    final locale = test['locale'] as String?;
    if (testCaseFilePath != null &&
        tsName != null &&
        deviceType != null &&
        locale != null) {
      // testCaseFilePath starts with /test/... — strip leading slash for relative path
      final relativePath = testCaseFilePath.startsWith('/')
          ? testCaseFilePath.substring(1)
          : testCaseFilePath;
      final testDir = relativePath.replaceFirst(RegExp(r'/[^/]+$'), '');
      final goldenName = '$tsName-$deviceType-$locale';
      final failureDir = '$testDir/failures';
      final testImagePath = '$failureDir/${goldenName}_testImage.png';
      final masterImagePath = '$failureDir/${goldenName}_masterImage.png';
      final isolatedDiffPath = '$failureDir/${goldenName}_isolatedDiff.png';
      if (File(testImagePath).existsSync()) actualPath = testImagePath;
      if (File(masterImagePath).existsSync()) expectedPath = masterImagePath;
      if (File(isolatedDiffPath).existsSync()) diffPath = isolatedDiffPath;
    }
  }

  if (diffPath != null || actualPath != null || expectedPath != null) {
    test['failureImages'] = <String, String?>{
      'expected': expectedPath,
      'actual': actualPath,
      'diff': diffPath,
    };
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
