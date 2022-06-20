import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:logger/logger.dart';
import 'package:moab_poc/util/storage.dart';
import 'package:moab_poc/utils.dart';
import 'package:package_info_plus/package_info_plus.dart';

final logger =
    Logger(printer: SimplePrinter(printTime: true), output: CustomOutput());

class CustomOutput extends LogOutput {
  final File _file = File.fromUri(Storage.logFileUri);

  @override
  void output(OutputEvent event) async {
    for (var line in event.lines) {
      printWrapped(line);
      if (_file.existsSync()) {
        await _file.writeAsString("${line.toString()}\n",
            mode: FileMode.writeOnlyAppend);
      }
    }
  }

  void printWrapped(String text) {
    final pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern.allMatches(text).forEach((match) => print(match.group(0)));
  }
}

initLog() async {
  logger.i(await getAppInfoLogs());
}

Future<String> getAppInfoLogs() async {
  final info = await PackageInfo.fromPlatform();
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  return [
    '\n-------------------------------------------------------------------------------------------------',
    'App Name: ${info.appName}',
    'App Version: ${info.version}',
    'OS: ${Platform.operatingSystem}, version: ${Platform.operatingSystemVersion}',
    'Device Info:',
    '${ await _deviceLog(deviceInfo)}',
    '-------------------------------------------------------------------------------------------------',
  ].join('\n');
}

// Future<List<String>> getAppInfoLogs(BuildContext context) async {
//   final info = await PackageInfo.fromPlatform();
//   DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
//   return [
//     '\n-------------------------------------------------------------------------------------------------',
//     'App Name: ${info.appName}',
//     'App Version: ${info.version}',
//     'OS: ${Platform.operatingSystem}, version: ${Platform.operatingSystemVersion}',
//     'Device Info:\n',
//     '-------------------------------------------------------------------------\n',
//     '${ await _deviceLog(deviceInfo)}\n',
//     '-------------------------------------------------------------------------',
//     'Screen Info:\n',
//     '-------------------------------------------------------------------------\n',
//     '${_screenLog(context)}\n',
//     '-------------------------------------------------------------------------',
//     '-------------------------------------------------------------------------------------------------\n',
//   ];
// }

screenInfoLog(BuildContext context) {
  logger.i(
      'Screen Info:\n'
          '-------------------------------------------------------------------------\n'
          '${_screenLog(context)}\n'
          '-------------------------------------------------------------------------');
}

Map<String, dynamic> _screenLog(BuildContext context) {
  return {
    'screen size': Utils.getScreenSize(context),
    'screen size physical': Utils.getPhysicalScreenSize(context),
    'screen ratio': Utils.getScreenRatio(context),
    'font scale': Utils.getTextScaleFactor(context),
    'safe area top padding': Utils.getTopSafeAreaPadding(context),
    'safe area bottom padding': Utils.getBottomSafeAreaPadding(context),
  };
}

Future<Map<String, dynamic>> _deviceLog(DeviceInfoPlugin deviceInfo) async {
  if (Platform.isIOS) {
    return _iosDeviceLog(await deviceInfo.iosInfo);
  } else if (Platform.isAndroid) {
    return _androidDeviceLog(await deviceInfo.androidInfo);
  } else {
    return {};
  }
}

Future<Map<String, dynamic>> _androidDeviceLog(AndroidDeviceInfo build) async {
  return {
    'version.securityPatch': build.version.securityPatch,
    'version.sdkInt': build.version.sdkInt,
    'version.release': build.version.release,
    'brand': build.brand,
    'device': build.device,
    'hardware': build.hardware,
    'host': build.host,
    'id': build.id,
    'manufacturer': build.manufacturer,
    'model': build.model,
    'product': build.product,
    'isPhysicalDevice': build.isPhysicalDevice,
  };
}

Future<Map<String, dynamic>> _iosDeviceLog(IosDeviceInfo data) async {
  return {
    'name': data.name,
    'systemName': data.systemName,
    'systemVersion': data.systemVersion,
    'model': data.model,
    'localizedModel': data.localizedModel,
    'identifierForVendor': data.identifierForVendor,
    'isPhysicalDevice': data.isPhysicalDevice,
    'utsname.sysname:': data.utsname.sysname,
    'utsname.nodename:': data.utsname.nodename,
    'utsname.release:': data.utsname.release,
    'utsname.version:': data.utsname.version,
    'utsname.machine:': data.utsname.machine,
  };
}
