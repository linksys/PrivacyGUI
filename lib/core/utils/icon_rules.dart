import 'package:collection/collection.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/core/utils/icon_device_category.dart';
import 'package:privacy_gui/core/utils/icon_rules_data.dart';

/// Resolves an icon class name to a consolidated asset name via [iconMappingTable].
String _iconMapping(String iconClass, {String? fallback}) {
  return iconMappingTable[iconClass] ?? fallback ?? defaultRouterIcon;
}

/// Determines a router's icon based on its model number and hardware version.
///
/// Returns 'node' if [modelNumber] is empty.
String routerIconTestByModel(
    {required String modelNumber, String? hardwareVersion}) {
  if (modelNumber.isEmpty) {
    return 'node';
  }
  final data = {
    'model': {
      'deviceType': 'Infrastructure',
      'manufacturer': 'Linksys',
      'modelNumber': modelNumber,
      'hardwareVersion': hardwareVersion ?? '1',
    }
  };
  final result = iconTest(data);
  return result == 'genericDevice' ? defaultRouterIcon : result;
}

/// A wrapper for [iconTest] specifically for testing router devices.
String routerIconTest(Map<String, dynamic> target) {
  return iconTest(target);
}

/// Determines a generic device category icon for a given device.
///
/// Maps specific icon classes to broader [IconDeviceCategory] values.
String deviceIconTest(Map<String, dynamic> target) {
  const regex =
      r'^.*((digitalMediaPlayer)|(phone)|(android)|(iphone)|(mobile)|(desktop)|(laptop)|(windows)|(mac)|(pc)|(tv)|(vacauum)|(plug)|(gameConsole)|(generic)).*$';
  final test = iconTest(target);
  final check = RegExp(regex, caseSensitive: false)
      .firstMatch(test)
      ?.group(1)
      ?.toLowerCase();
  return switch (check) {
    'tv' => IconDeviceCategory.tv,
    'digitalmediaplayer' => IconDeviceCategory.speaker,
    'plug' => IconDeviceCategory.plug,
    'vacauum' => IconDeviceCategory.vacuum,
    'gameconsole' => IconDeviceCategory.gameConsole,
    'phone' || 'android' || 'iphone' || 'mobile' => IconDeviceCategory.phone,
    'desktop' ||
    'laptop' ||
    'windows' ||
    'mac' ||
    'pc' =>
      IconDeviceCategory.computer,
    _ => IconDeviceCategory.unknown
  }
      .name;
}

/// The core icon testing function that evaluates a device against the [iconRules].
///
/// Iterates through [iconRules], applying each rule's `test` conditions to [target].
/// The first matching rule determines the icon.
String iconTest(Map<String, dynamic> target) {
  final result = iconRules.firstWhereOrNull((iconRule) {
    List<bool> testResults = [];
    doAttributesTests(
        target, Map<String, dynamic>.from(iconRule['test']), testResults);
    return !testResults.contains(false);
  });
  if (result == null) {
    return _iconMapping('genericDevice');
  }
  final iconClass = result['iconClass'];

  if (iconClass is Map<String, dynamic>) {
    final modelNumber = target.getValueByPath<String>(iconClass['lookup']);
    final capitalized = modelNumber.toLowerCase().capitalize();
    return _iconMapping('router$capitalized');
  } else if (iconClass is String) {
    return _iconMapping(iconClass, fallback: iconClass);
  }
  return _iconMapping(result['iconClass'] as String? ?? 'genericDevice');
}

/// Recursively performs attribute tests on a nested map structure.
///
/// Traverses the `test` rule map and the `target` device data map in parallel.
/// At leaf nodes, performs regex matching against corresponding target values.
doAttributesTests(Map<String, dynamic> target, Map<String, dynamic> test,
    List<bool> results) {
  if (isPlainObject(test)) {
    test.forEach((key, value) {
      doAttributesTests(
          target[key] ?? {}, value is String ? {key: value} : value, results);
    });
  } else {
    final result = !test.entries.any((element) {
      if (element.value == null) {
        return true;
      }
      final regex = RegExp('${element.value}', caseSensitive: false);
      bool isMatch = regex.hasMatch(target[element.key] ?? '');
      return !isMatch;
    });
    results.add(result);
  }
}

/// Checks if a map contains at least one value that is also a map.
bool isPlainObject(Map<String, dynamic> json) {
  return json.values.any((element) => element is Map<String, dynamic>);
}
