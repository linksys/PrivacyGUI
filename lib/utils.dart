import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:intl/intl.dart';
import 'package:linksys_moab/network/http/model/cloud_app.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Utils {
  static const String NoSpeedCalculationText = "-----";
  static const bool ReleaseMode =
      bool.fromEnvironment('dart.vm.product', defaultValue: false);

  static String formatDuration(Duration d) {
    var seconds = d.inSeconds;
    final days = seconds ~/ Duration.secondsPerDay;
    seconds -= days * Duration.secondsPerDay;
    final hours = seconds ~/ Duration.secondsPerHour;
    seconds -= hours * Duration.secondsPerHour;
    final minutes = seconds ~/ Duration.secondsPerMinute;
    seconds -= minutes * Duration.secondsPerMinute;

    final List<String> tokens = [];
    if (days != 0) {
      tokens.add('${days}d');
    }
    if (tokens.isNotEmpty || hours != 0) {
      tokens.add('${hours}h');
    }
    if (tokens.isNotEmpty || minutes != 0) {
      tokens.add('${minutes}m');
    }
    tokens.add('${seconds}s');

    return tokens.join(' ');
  }

  static String formatTimeMSS(int timeInSecond) {
    final Duration timeAmount = Duration(seconds: timeInSecond);
    final String m = timeAmount.inMinutes.remainder(60).toString();
    final String s =
        timeAmount.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static String formatBytes(int bytes, {int decimals = 0}) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "Kb", "Mb", "Gb", "Tb", "Pb"];
    var i = (log(bytes) / log(1024)).floor();
    var number = (bytes / pow(1024, i));
    return (number).toStringAsFixed(
            number.truncateToDouble() == number ? 0 : decimals) +
        ' ' +
        suffixes[i];
  }

  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static double getScreenRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }

  static Size getPhysicalScreenSize(BuildContext context) {
    return getScreenSize(context) * getScreenRatio(context);
  }

  static double getPhysicalScreenWidth(BuildContext context) {
    return getScreenWidth(context) * getScreenRatio(context);
  }

  static double getPhysicalScreenHeight(BuildContext context) {
    return getScreenHeight(context) * getScreenRatio(context);
  }

  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaleFactor;
  }

  static double getTopSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  static double getBottomSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  static double getSafeAreaHeight(BuildContext context) {
    return getScreenHeight(context) -
        getTopSafeAreaPadding(context) -
        getBottomSafeAreaPadding(context);
  }

  static Future<DeviceInfo> fetchDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final os = Platform.operatingSystem;
    final infoMap = await _deviceInfoMap(deviceInfo);
    infoMap['os'] = os;
    infoMap['systemLocale'] = Intl.systemLocale.replaceFirst('_', '-');
    return DeviceInfo.fromJson(infoMap);
  }

  static Future<Map<String, dynamic>> _deviceInfoMap(
      DeviceInfoPlugin deviceInfo) async {
    if (Platform.isIOS) {
      return _iosDeviceMap(await deviceInfo.iosInfo);
    } else if (Platform.isAndroid) {
      return _androidDeviceMap(await deviceInfo.androidInfo);
    } else {
      return {};
    }
  }

  static Future<Map<String, dynamic>> _androidDeviceMap(
      AndroidDeviceInfo build) async {
    return {
      'osVersion': build.version.release,
      'mobileManufacturer': build.manufacturer,
      'mobileModel': build.model,
    };
  }

  static Future<Map<String, dynamic>> _iosDeviceMap(IosDeviceInfo data) async {
    return {
      'osVersion': data.systemVersion,
      'mobileModel': data.utsname.machine,
      'mobileManufacturer': 'Apple'
    };
  }

  static Future<String> getTimeZone() async {
    return await FlutterNativeTimezone.getLocalTimezone();
  }

  static String getLanguageCode() {
    List<String> localeNames = Platform.localeName.split('_');

    return localeNames.length > 2
        ? '${localeNames[0]}_${localeNames[1]}'
        : localeNames.first;
  }

  static String getCountryCode() {
    return Platform.localeName.split('_').last;
  }

  static String maskJsonValue(String raw, List<String> keys) {
    final pattern = '"?(${keys.join('|')})"?\\s*:\\s*"?([\\s\\S]*?)"?(?=,|})';
    RegExp regex = RegExp(pattern, multiLine: true);
    String result = raw;

    regex.allMatches(raw).forEach((element) {
      for (final key in keys) {
        if (element.groupCount == 2 &&
            element.group(1)!.toLowerCase() == key.toLowerCase()) {
          final target = element.group(2)!;
          result = result.replaceFirst(target, '************');
        }
      }
    });
    return result;
  }

  static String maskSensitiveJsonValues(String raw) {
    final keys = [
      'username',
      'password',
      'privateKey',
      'X-Linksys-Moab-App-Secret',
      'adminPassword',
    ];
    return maskJsonValue(raw, keys);
  }
}
