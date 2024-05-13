import 'dart:io';

import 'package:collection/collection.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:linksys_app/core/utils/storage.dart';
import 'package:linksys_app/utils.dart';
import 'package:package_info_plus/package_info_plus.dart';

final logger = Logger(
    filter: ProductionFilter(),
    printer: SimplePrinter(
        printTime: true, colors: kIsWeb ? false : stdout.supportsAnsiEscapes),
    output: CustomOutput());

class CustomOutput extends LogOutput {
  final File _file = File.fromUri(Storage.logFileUri);

  @override
  void output(OutputEvent event) async {
    var output = '';
    for (var line in event.lines) {
      printWrapped(line);
      // if (event.level == Level.info || event.level == Level.error) {
      //   output += line;
      // }
      output += line;
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

      recordLog(Utils.maskSensitiveJsonValues(
          Utils.replaceHttpScheme(output.toString())));
    }
  }

  void printWrapped(String text) {
    if (kDebugMode) {
      print(text);
    }
  }
}

initLog() async {
  if (kDebugMode && !kIsWeb) {
    print(await getAppInfoLogs());
  }
  // if (kIsWeb) {
  //   print('Init logs');
  //   final SharedPreferences sp = await SharedPreferences.getInstance();
  //   await sp.remove(pWebLog);
  // }
}

Future<String> getAppInfoLogs() async {
  final packageInfo = await PackageInfo.fromPlatform();
  List<String> appInfo = [
    '\n----------- App Info ------------',
    'App name: ${packageInfo.appName}',
    'App id: ${packageInfo.packageName}',
    'App build number: ${packageInfo.buildNumber}',
    'App version: ${packageInfo.version}',
    'Platform OS: ${Platform.operatingSystem}',
    'OS version: ${Platform.operatingSystemVersion}',
  ];

  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  appInfo.add('---------- Device Info ----------');
  appInfo.add(await _getDeviceInfo(deviceInfoPlugin));
  appInfo.add('---------------------------------');

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
    '---------- Screen info ----------',
    'Screen size: ${MediaQueryUtils.getScreenSize(context)}',
    'Physical Screen size: ${MediaQueryUtils.getScreenSize(context)}',
    'Screen pixel ratio: ${MediaQueryUtils.getScreenRatio(context)}',
    'Font scale: ${MediaQueryUtils.getTextScaleFactor(context)}',
    'Top padding of safe area: ${MediaQueryUtils.getTopSafeAreaPadding(context)}',
    'Bottom padding of safe area: ${MediaQueryUtils.getBottomSafeAreaPadding(context)}',
    '---------------------------------',
  ];
  return data.join('\n');
}

Map<String, List<(int, String)>> logCache = {};
const int maxLogSize = 2000;
const String tagRegex = r'\[(\w*)\]:(.*)';

void recordLog(String log) async {
  _recordLog(log);

  // tag record
  final extracted = _extratTagLog(log);
  if (extracted != null) {
    _recordLog(extracted.$2, tag: extracted.$1);
  }
}

void _recordLog(String log, {String tag = 'app'}) {
  final logList = logCache[tag] ?? [];
  if (logList.length + 1 >= maxLogSize) {
    logList.removeAt(0);
  }
  logList.add((DateTime.now().millisecondsSinceEpoch, log));
  logCache[tag] = logList;
}

String getLogs({String tag = 'app'}) {
  final logList = logCache[tag] ?? [];
  return logList
      .sorted((a, b) => a.$1.compareTo(b.$1))
      .map((e) => e.$2)
      .join('\n');
}

String getFullLogs() {
  final keys = List.from(logCache.keys)..remove('app');
  return '''
${keys.map((e) => '$e = [${getLogs(tag: e)}],\n')}
${getLogs()}\n
''';
}

(String, String)? _extratTagLog(String log) {
  final match = RegExp(tagRegex).firstMatch(log);
  if (match == null) {
    return null;
  }
  final tag = match.group(1);
  final message = match.group(2);
  if (tag == null) {
    return null;
  }
  if (message == null) {
    return null;
  }
  return (tag, message);
}
