import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';

part 'html_generate_functions.dart';

void main(List<String> args) {
  print(args);
  var testResultJsonPath = './reports/tests.json';
  var testResultHtmlOutputPath = './reports/reports.html';

  // use default path if no args input
  if (args.isNotEmpty) {
    testResultJsonPath = args[0];
  }
  if (args.length > 1) {
    testResultHtmlOutputPath = args[1];
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
    final htmlReport = generateHTMLReport(testResult);
    final reportHTMLFile = File(testResultHtmlOutputPath);
    if (!reportHTMLFile.existsSync()) {
      reportHTMLFile.createSync(recursive: true);
    }
    reportHTMLFile.writeAsStringSync(htmlReport);
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
    final testJson = json['test'];
    final suiteID = testJson['suiteID'];
    final groupIDs = List.from(testJson['groupIDs']);
    final suites = testResult['suites'] as List<Map<String, dynamic>>;
    final targetSuite =
        suites.firstWhereOrNull((element) => element['id'] == suiteID);
    if (targetSuite == null) {
      return;
    }
    final groups = targetSuite['groups'] as List<Map<String, dynamic>>?;
    if (groups == null) {
      return;
    }
    final targetGroups =
        groups.where((element) => groupIDs.contains(element['id']));
    for (var element in targetGroups) {
      testJson['name'] =
          (testJson['name'] as String? ?? '').replaceFirst(element['name'], '');
      addOrAppendData<Map<String, dynamic>>(element, 'tests', testJson);
    }
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
        final successCount = testResult['counting']['success'] ?? 0;
        testResult['counting']['success'] = successCount + 1;
      } else {
        final failCount = testResult['counting']['failed'] ?? 0;
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

String formatPercentage(double num, int postion) {
  if ((num.toString().length - num.toString().lastIndexOf(".") - 1) < postion) {
    return num.toStringAsFixed(postion)
        .substring(0, num.toString().lastIndexOf(".") + postion + 1)
        .toString();
  } else {
    return num.toString()
        .substring(0, num.toString().lastIndexOf(".") + postion + 1)
        .toString();
  }
}
