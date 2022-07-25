import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:logger/logger.dart';
import 'package:moab_poc/util/storage.dart';
import 'package:moab_poc/utils.dart';
import 'package:package_info_plus/package_info_plus.dart';

final logger =
    Logger(printer: SimplePrinter(printTime: true, colors: false), output: CustomOutput());

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
  final packageInfo = await PackageInfo.fromPlatform();
  List<String> appInfo = [
    '\n----------- App Info ------------',
    'App name: ${packageInfo.appName}',
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
    'Screen size: ${Utils.getScreenSize(context)}',
    'Physical Screen size: ${Utils.getScreenSize(context)}',
    'Screen pixel ratio: ${Utils.getScreenRatio(context)}',
    'Font scale: ${Utils.getTextScaleFactor(context)}',
    'Top padding of safe area: ${Utils.getTopSafeAreaPadding(context)}',
    'Bottom padding of safe area: ${Utils.getBottomSafeAreaPadding(context)}',
    '---------------------------------',
  ];
  return data.join('\n');
}
