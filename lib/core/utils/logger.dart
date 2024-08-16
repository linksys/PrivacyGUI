import 'dart:io';
import 'package:collection/collection.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:privacy_gui/core/utils/storage.dart';
import 'package:privacy_gui/utils.dart';
import 'package:package_info_plus/package_info_plus.dart';

final logger = Logger(
  filter: ProductionFilter(),
  printer: SimplePrinter(
    printTime: true,
    colors: kIsWeb ? false : stdout.supportsAnsiEscapes,
  ),
  output: CustomOutput(),
);

class CustomOutput extends LogOutput {
  final File _file = File.fromUri(Storage.logFileUri);

  @override
  void output(OutputEvent event) async {
    var output = '';
    for (var line in event.lines) {
      // Print every log message on the console in debug mode
      if (kDebugMode) {
        print(line);
      }
      // Log messages with levels lower than 'debug' will not be recorded in the log file
      if (event.level.value >= Level.debug.value) {
        output += line;
      }
    }
    if (!kIsWeb && output.isNotEmpty && _file.existsSync()) {
      await _file.writeAsBytes(
          "${Utils.maskSensitiveJsonValues(Utils.replaceHttpScheme(output.toString()))}\n"
              .codeUnits,
          mode: FileMode.writeOnlyAppend);
    } else if (kIsWeb && output.isNotEmpty) {
      // final SharedPreferences sp = await SharedPreferences.getInstance();
      // String content = sp.getString(pWebLog) ?? '';
      // await sp.setString(pWebLog,
      //     '$content\n${Utils.maskSensitiveJsonValues(Utils.replaceHttpScheme(output.toString()))}\n');
      _recordLog(
        Utils.maskUsernamePasswordBodyValue(
          Utils.maskSensitiveJsonValues(
            Utils.replaceHttpScheme(output.toString()),
          ),
        ),
      );
    }
  }
}

Map<String, List<(int, String)>> _webLogCache = {};
const int _maxLogSizeEachTag = 2000;
const String _logTagRegex = r'\[(\w*)\]:(.*)';

void _recordLog(String log) async {
  // Add every log message to the 'app' log list
  _addLogWithTag(message: log);
  // If a custom tag is specified, add to its log list
  final record = _splitTagAndMessage(log);
  if (record != null) {
    _addLogWithTag(message: record.$1, tag: record.$2);
  }
}

void _addLogWithTag({required String message, String tag = 'app'}) {
  final logList = _webLogCache[tag] ?? [];
  if (logList.length + 1 > _maxLogSizeEachTag) {
    logList.removeAt(0);
  }
  logList.add((DateTime.now().millisecondsSinceEpoch, message));
  _webLogCache[tag] = logList;
}

(String, String)? _splitTagAndMessage(String log) {
  final match = RegExp(_logTagRegex).firstMatch(log);
  if (match == null) {
    return null;
  }
  final tag = match.group(1);
  final message = match.group(2);
  if (message == null || tag == null) {
    return null;
  }
  return (message, tag);
}

String _getWebLogByTag({String tag = 'app'}) {
  final logList = _webLogCache[tag] ?? [];
  return logList
      .sorted((a, b) => a.$1.compareTo(b.$1))
      .map((e) => e.$2)
      .join('\n');
}

Future<String> outputFullWebLog(BuildContext context) async {
  final keys = List.from(_webLogCache.keys)..remove('app');
  return '''
${await getPackageInfo()}
${getScreenInfo(context)}
============================== Custom Tag Summary ==============================
${keys.map((e) => '[$e]\n${_getWebLogByTag(tag: e)}').join('\n\n')}
================================== Full Logs ===================================
${_getWebLogByTag()}\n
''';
}

Future<String> getPackageInfo() async {
  final packageInfo = await PackageInfo.fromPlatform();
  List<String> appInfo = [
    '================================= Package Info =================================',
    'App Name: ${packageInfo.appName}',
    'App ID: ${packageInfo.packageName}',
    'App Build Number: ${packageInfo.buildNumber}',
    'App Version: ${packageInfo.version}',
    if (!kIsWeb) 'Platform OS: ${Platform.operatingSystem}',
    if (!kIsWeb) 'OS version: ${Platform.operatingSystemVersion}',
  ];

  if (!kIsWeb) {
    appInfo.add(
      '================================= Device Info ==================================',
    );
    appInfo.add(await _getDeviceInfo(DeviceInfoPlugin()));
  }

  return appInfo.join('\n');
}

Future<String> _getDeviceInfo(DeviceInfoPlugin plugin) async {
  if (Platform.isIOS) {
    return _getIosDeviceInfo(await plugin.iosInfo).join('\n');
  } else if (Platform.isAndroid) {
    return _getAndroidDeviceInfo(await plugin.androidInfo).join('\n');
  } else {
    return '';
  }
}

List<String> _getIosDeviceInfo(IosDeviceInfo info) {
  return [
    'Phone name: ${info.name}',
    'System name: ${info.systemName}',
    'System version: ${info.systemVersion}',
    'Model: ${info.model}',
    'Localized model: ${info.localizedModel}',
    'Vendor identifier: ${info.identifierForVendor}',
    'isPhysicalDevice: ${info.isPhysicalDevice}',
    '(Utsname) System name: ${info.utsname.sysname}',
    '(Utsname) Network node name: ${info.utsname.nodename}',
    '(Utsname) Release level: ${info.utsname.release}',
    '(Utsname) Version level: ${info.utsname.version}',
    '(Utsname) Hardware type: ${info.utsname.machine}',
  ];
}

List<String> _getAndroidDeviceInfo(AndroidDeviceInfo info) {
  return [
    'version.securityPatch: ${info.version.securityPatch}',
    'version.sdkInt: ${info.version.sdkInt}',
    'version.release: ${info.version.release}',
    'brand: ${info.brand}',
    'device: ${info.device}',
    'hardware: ${info.hardware}',
    'host: ${info.host}',
    'id: ${info.id}',
    'manufacturer: ${info.manufacturer}',
    'model: ${info.model}',
    'product: ${info.product}',
    'isPhysicalDevice: ${info.isPhysicalDevice}',
  ];
}

String getScreenInfo(BuildContext context) {
  final List data = [
    '================================= Screen Info ==================================',
    'Screen size: ${MediaQueryUtils.getScreenSize(context)}',
    'Physical Screen size: ${MediaQueryUtils.getScreenSize(context)}',
    'Screen pixel ratio: ${MediaQueryUtils.getScreenRatio(context)}',
    'Font scale: ${MediaQueryUtils.getTextScaleFactor(context)}',
    'Top padding of safe area: ${MediaQueryUtils.getTopSafeAreaPadding(context)}',
    'Bottom padding of safe area: ${MediaQueryUtils.getBottomSafeAreaPadding(context)}',
  ];
  return data.join('\n');
}
