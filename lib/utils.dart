import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/util/uuid.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'core/utils/logger.dart';
import 'core/utils/storage.dart';
import '../../../util/export_selector/export_base.dart'
    if (dart.library.io) '../../../util/export_selector/export_mobile.dart'
    if (dart.library.html) '../../../util/export_selector/export_web.dart';
import '../../../util/get_log_selector/get_log_base.dart'
    if (dart.library.io) '../../../util/get_log_selector/get_log_mobile.dart'
    if (dart.library.html) '../../../util/get_log_selector/get_log_web.dart';

class Utils {
  static Future exportLogFile(BuildContext context) async {
    final content = await getLog(context);
    final String shareLogFilename =
        'log-${DateFormat("yyyy-MM-dd_HH_mm_ss").format(DateTime.now())}.txt';

    await exportFile(
      content: content,
      fileName: shareLogFilename,
      text: 'Linksys Log',
      subject: 'Log file',
    ).then((result) {
      if (result?.status == ShareResultStatus.success && !kIsWeb) {
        Storage.deleteFile(Storage.logFileUri);
        Storage.createLoggerFile();
      }
      showSnackBar(context, content: Text("Log exported - $shareLogFilename"));
    });
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

  static String maskUsernamePasswordBodyValue(String raw) {
    List<String> keys = ['username', 'password'];
    final pattern = '(${keys.join('|')})\\s*=\\s*([\\S]*?)(?=&|\\n)';
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
      'adminPassword',
      'passphrase',
    ];
    return maskJsonValue(raw, keys);
  }

  static String replaceHttpScheme(String raw) {
    const pattern =
        r'(https?:\/\/)?((www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b)([-a-zA-Z0-9()@:%_\+.~#?&\/\/=]*)';
    RegExp regex = RegExp(pattern, multiLine: true);
    String result = raw;
    int idx = 0;
    regex.allMatches(result).forEach((element) {
      element.groups([1, 2, 4]).whereNotNull().forEach((group) {
            int start = raw.indexOf(group, idx);
            int end = start + group.length;
            final replaced = group.replaceAll(':', '-').replaceAll('.', '-');
            result = result.replaceRange(start, end, replaced);
            idx = end;
          });
    });
    return result;
  }

  static String stringBase64Encode(String value) {
    return utf8.fuse(base64).encode(value);
  }

  static String stringBase64Decode(String base64String) {
    return utf8.fuse(base64).decode(base64String);
  }

  // String converter
  static String fullStringEncoded(String value) {
    final utf8Encoded =
        String.fromCharCodes(Uint8List.fromList(utf8.encode(value)));
    final b64 = base64Encode(utf8Encoded.codeUnits);
    final uriFull = Uri.encodeQueryComponent(b64);
    logger.d('u: $utf8Encoded, b: $b64, i: $uriFull');
    return uriFull;
  }

  static String fullStringDecoded(String encoded) {
    final uriBack = Uri.decodeComponent(encoded);
    final b64Back = String.fromCharCodes(base64Decode(uriBack));
    final utf8Back = utf8.decode(b64Back.codeUnits);
    logger.d('i: $uriBack, b: $b64Back, u: $utf8Back');
    return utf8Back;
  }

  static Future<bool> isUIVersionChanged() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final uiVersion = packageInfo.version;
    final fileUIVersion = await getVersion();
    return uiVersion.compareToVersion(fileUIVersion) < 0;
  }
}

extension DateFormatUtils on Utils {
  static String formatDuration(Duration d,
      [BuildContext? context, bool excludeSecs = false]) {
    var seconds = d.inSeconds;
    final days = seconds ~/ Duration.secondsPerDay;
    seconds -= days * Duration.secondsPerDay;
    final hours = seconds ~/ Duration.secondsPerHour;
    seconds -= hours * Duration.secondsPerHour;
    final minutes = seconds ~/ Duration.secondsPerMinute;
    seconds -= minutes * Duration.secondsPerMinute;

    final List<String> tokens = [];
    if (days != 0) {
      final token = context == null ? '${days}d' : loc(context).nDays(days);
      tokens.add(token);
    }
    if (tokens.isNotEmpty || hours != 0) {
      final token = context == null ? '${hours}h' : loc(context).nHours(hours);
      tokens.add(token);
    }
    if (tokens.isNotEmpty || minutes != 0) {
      final token =
          context == null ? '${minutes}m' : loc(context).nMinutes(minutes);
      tokens.add(token);
    }
    if (!excludeSecs) {
      final token =
          context == null ? '${seconds}s' : loc(context).nSeconds(seconds);
      tokens.add(token);
    }

    return tokens.join(' ');
  }

  static String formatTimeMSS(int timeInSecond) {
    final Duration timeAmount = Duration(seconds: timeInSecond);
    final String m = timeAmount.inMinutes.remainder(60).toString();
    final String s =
        timeAmount.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static String formatTimeInterval(int startTimeInSecond, int endTimeInSecond) {
    bool isNextDay = startTimeInSecond > endTimeInSecond;
    return '${formatTimeAmPm(startTimeInSecond)} - ${formatTimeAmPm(endTimeInSecond)}${isNextDay ? ' next day' : ''}';
  }

  static String formatTimeAmPm(int timeInSecond) {
    final Duration timeAmount = Duration(seconds: timeInSecond);
    final String h = timeAmount.inHours == 12
        ? timeAmount.inHours.toString()
        : timeAmount.inHours.remainder(12).toString().padLeft(2, '0');
    final String m =
        timeAmount.inMinutes.remainder(60).toString().padLeft(2, '0');
    final String ampm = timeAmount.inHours.remainder(24) >= 12 ? 'pm' : 'am';
    return '$h:$m $ampm';
  }

  static String formatTimeHM(int timeInSecond) {
    final Duration timeAmount = Duration(seconds: timeInSecond);
    // final String h =
    //     timeAmount.inHours.remainder(24).toString().padLeft(2, '0');
    final String h = timeAmount.inHours.toString().padLeft(2, '0');
    final String m =
        timeAmount.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '$h hr,$m min';
  }
}

// TODO: Unit test
extension MediaQueryUtils on Utils {
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

  // static Future<String> getTimeZone() async {
  //   return await FlutterNativeTimezone.getLocalTimezone();
  // }

  static String getLanguageCode() {
    List<String> localeNames = Platform.localeName.split('_');

    return localeNames.length > 1 ? localeNames.first : Platform.localeName;
  }

  static String getCountryCode() {
    List<String> localeNames = Platform.localeName.split('_');

    return localeNames.length > 1 ? localeNames.last : Platform.localeName;
  }
}

extension NetworkUtils on Utils {
  static String formatBytes(int bytes, {int decimals = 0}) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "Kb", "Mb", "Gb", "Tb", "Pb"];
    var i = (log(bytes) / log(1024)).floor();
    var number = (bytes / pow(1024, i));
    return '${(number).toStringAsFixed(number.truncateToDouble() == number ? 0 : decimals)} ${suffixes[i]}';
  }

  static String generateMqttClintId() {
    final platform = Platform.isIOS ? 'iOS' : 'Android';
    return '$platform-${uuid.v1()}';
  }

  static bool isValidIpAddress(String ipAddress) {
    final octets = ipAddress.split('.');
    if (octets.length != 4) return false;
    final octet1 = int.tryParse(octets[0]);
    if (octet1 == null || octet1 > 255 || octet1 < 0) return false;
    final octet2 = int.tryParse(octets[1]);
    if (octet2 == null || octet2 > 255 || octet2 < 0) return false;
    final octet3 = int.tryParse(octets[2]);
    if (octet3 == null || octet3 > 255 || octet3 < 0) return false;
    final octet4 = int.tryParse(octets[3]);
    if (octet4 == null || octet4 > 255 || octet4 < 0) return false;

    return true;
  }

  static int ipToNum(String ipAddress) {
    final octets = ipAddress.split('.');
    if (isValidIpAddress(ipAddress) == false) {
      return 0;
    }
    return (((((int.parse(octets[0]) * 256) + int.parse(octets[1])) * 256) +
                int.parse(octets[2])) *
            256) +
        int.parse(octets[3]);
  }

  static String numToIp(int num) {
    if (num < 0 || num > 4294967295) return '0.0.0.0';
    var octets = '${num % 256}';
    for (var _ in [1, 2, 3]) {
      num = (num / 256).floor();
      octets = '${num % 256}.$octets';
    }
    return octets;
  }

  static bool ipInRange(ipAddress, ipAddressMin, ipAddressMax) {
    if (isValidIpAddress(ipAddress) == false ||
        isValidIpAddress(ipAddressMin) == false ||
        isValidIpAddress(ipAddressMax) == false) {
      throw ArgumentError();
    }
    if (ipToNum(ipAddressMin) > ipToNum(ipAddressMax)) {
      throw ArgumentError('Range error');
    }
    return ipToNum(ipAddress) >= ipToNum(ipAddressMin) &&
        ipToNum(ipAddress) <= ipToNum(ipAddressMax);
  }

  static bool isValidSubnetMask(String subnetMask,
      {int minNetworkPrefixLength = 8, int maxNetworkPrefixLength = 30}) {
    if (isValidIpAddress(subnetMask) == false) {
      return false;
    }

    if (minNetworkPrefixLength < 1 || minNetworkPrefixLength > 31) {
      throw const FormatException(
        'Invalid minNetworkPrefixLength passed, must be between 1 and 31',
      );
    }
    if (maxNetworkPrefixLength < 1 || maxNetworkPrefixLength > 31) {
      throw const FormatException(
        'Invalid maxNetworkPrefixLength passed, must be between 1 and 31',
      );
    }
    if (maxNetworkPrefixLength < minNetworkPrefixLength) {
      throw const FormatException(
        'maxNetworkPrefixLength cannot be less than minNetworkPrefixLength',
      );
    }

    var subnetMaskBits = ipToNum(subnetMask).toRadixString(2);
    var prefixLength = subnetMaskBits.indexOf('0');
    if (prefixLength == -1 ||
        prefixLength < minNetworkPrefixLength ||
        prefixLength > maxNetworkPrefixLength) {
      throw FormatException(
        'Invalid network prefix length, must be between $minNetworkPrefixLength and $maxNetworkPrefixLength',
      );
    }
    final subnetMaskTestBits =
        List.filled(prefixLength, '1').join().padRight(32, '0');
    if (subnetMaskBits != subnetMaskTestBits) {
      return false;
    }
    return true;
  }

  static String getIpPrefix(String ipAddress, String subnetMask) {
    if (!isValidIpAddress(ipAddress) || !isValidSubnetMask(subnetMask)) {
      throw ArgumentError();
    }
    final subnetMaskToken = subnetMask.split('.');
    return ipAddress
        .split('.')
        .mapIndexed(
            (index, e) => int.parse(e) & int.parse(subnetMaskToken[index]))
        .join('.');
  }

  static String prefixLengthToSubnetMask(int prefixLength) {
    final subnetMaskTestBits =
        List.filled(prefixLength, '1').join().padRight(32, '0');
    return RegExp(r'.{1,8}')
        .allMatches(subnetMaskTestBits)
        .map((e) => int.parse(e.group(0)!, radix: 2))
        .toList()
        .join('.');
  }

  static int subnetMaskToPrefixLength(String subnetMask) {
    final prefixLength = ipToNum(subnetMask).toRadixString(2).indexOf('0');

    if (!isValidSubnetMask(subnetMask,
        minNetworkPrefixLength: 1, maxNetworkPrefixLength: 31)) {
      throw Exception('Invalid subnet mask passed');
    }

    return prefixLength == -1 ? 32 : prefixLength;
  }

  /*
     * @description returns a Boolean for whether the Router's IP Address is within the DHCP Range (explicit or calculated)
     * @params {String} routerIPAddress - A string representing the current IP of the Router
     * @params {String} firstClientIPAddress - A string representing the starting IP of the DHCP Range
     * @params {String} lastClientIPAddress [optional] - A string representing the end IP of the DHCP Range
     * @params {Integer} maxUsers [optional] - An integer containing the current # of users the DHCP Range should allow; used if lastClientIPAddress is not passed in
     * @return {Boolean}
  */
  static bool isRouterIPInDHCPRange(
      String routerIPAddress, String firstClientIPAddress,
      [String? lastClientIPAddress, int? maxUsers]) {
    final ipAddressNum = ipToNum(routerIPAddress);
    final firstClientIPAddressNum = ipToNum(firstClientIPAddress);
    final lastClientIPAddressNum = lastClientIPAddress != null
        ? ipToNum(lastClientIPAddress)
        : firstClientIPAddressNum + maxUsers! - 1;
    return ipAddressNum >= firstClientIPAddressNum &&
        ipAddressNum <= lastClientIPAddressNum;
  }

  /*
     * @description returns an Integer for the max # of users allowed by the current DHCP Range
     * @params {String} routerIPAddress - A string representing the current IP of the Router
     * @params {String} firstClientIPAddress - A string representing the starting IP of the DHCP Range
     * @params {String} lastClientIPAddress - A string representing the end IP of the DHCP Range
     * @return {Integer}
  */
  static int getMaxUserAllowedInDHCPRange(String routerIPAddress,
      String firstClientIPAddress, String lastClientIPAddress) {
    final firstClientIPAddressNum = ipToNum(firstClientIPAddress);
    final lastClientIPAddressNum = ipToNum(lastClientIPAddress);
    var maxUsers = lastClientIPAddressNum - firstClientIPAddressNum;

    if (!isRouterIPInDHCPRange(
      routerIPAddress,
      firstClientIPAddress,
      lastClientIPAddress,
    )) {
      maxUsers++;
    }
    return maxUsers;
  }

  /*
     * @description returns a String representing the last IP of the DHCP Range
     * @params {String} firstClientIPAddress - A string representing the starting IP of the DHCP Range
     * @params {Integer} maxUsers - An integer containing the current # of users the DHCP Range should allow
     * @return {String}
  */
  static String getEndDHCPRangeForMaxUsers(
      String firstClientIPAddress, int maxUsers) {
    final firstClientIPAddressNum = ipToNum(firstClientIPAddress);
    final lastClientIPAddressNum = firstClientIPAddressNum + maxUsers - 1;

    return numToIp(lastClientIPAddressNum);
  }

  static String getEndingIpAddress(
    String routerIpAddress,
    String firstClientIpAddress,
    int maxUserAllowed,
  ) {
    final firstClientIpAddressNum = ipToNum(firstClientIpAddress);
    var lastClientIpAddressNum = firstClientIpAddressNum + maxUserAllowed - 1;
    if (isRouterIPInDHCPRange(
      routerIpAddress,
      firstClientIpAddress,
      null,
      maxUserAllowed,
    )) {
      lastClientIpAddressNum++;
    }
    return numToIp(lastClientIpAddressNum);
  }

  /*
     * @description returns an Integer for the max # of users that could be set, based on the 1st DHCP Client IP Address and the SubnetMask of the Router
     * @params {String} routerIPAddress - A string representing the current IP of the Router
     * @params {String} firstClientIPAddress - A string representing the starting IP of the DHCP Range
     * @params {String} subnetMask - A string representing the end IP of the DHCP Range
     * @params {Integer} maxUsers - An integer containing the current # of users the DHCP Range should allow
     * @return {Integer}
  */
  static int getMaxUserLimit(
    String routerIPAddress,
    String firstClientIPAddress,
    String subnetMask,
    int maxUsers,
  ) {
    final currentPrefixLength = subnetMaskToPrefixLength(subnetMask);
    int maxUserLimit = pow(2, 32 - currentPrefixLength).toInt();
    final subnetMaskNum = ipToNum(subnetMask);
    final firstClientIPAddressNum = ipToNum(firstClientIPAddress);
    final firstClientIPAddressBinary = firstClientIPAddressNum.toRadixString(2);

    final startingIPAddress = int.parse(
            subnetMaskNum.toRadixString(2).substring(0, currentPrefixLength) +
                firstClientIPAddressBinary.substring(
                    firstClientIPAddressBinary.length -
                        (32 - currentPrefixLength),
                    firstClientIPAddressBinary.length),
            radix: 2) -
        subnetMaskNum;
    if (isRouterIPInDHCPRange(
        routerIPAddress, firstClientIPAddress, null, maxUsers)) {
      maxUserLimit--;
    }

    return maxUserLimit - startingIPAddress - 1;
  }

  static bool isMtuValid(String wanType, int mtu) {
    return mtu == 0 || (getMinMtu(wanType) <= mtu && mtu <= getMaxMtu(wanType));
  }

  static int getMinMtu(String wanType) {
    return switch (wanType.toLowerCase()) {
      'dhcp' => 576,
      'pppoe' => 576,
      'static' => 576,
      'pptp' => 576,
      'l2tp' => 576,
      _ => 0,
    };
  }

  static int getMaxMtu(String wanType) {
    return switch (wanType.toLowerCase()) {
      'dhcp' => 1500,
      'pppoe' => 1492,
      'static' => 1500,
      'pptp' => 1460,
      'l2tp' => 1460,
      _ => 0,
    };
  }
}

extension WiFiUtils on Utils {
  static IconData getWifiSignalIconData(
      BuildContext context, int? signalStrength) {
    switch (getWifiSignalLevel(signalStrength)) {
      case NodeSignalLevel.excellent:
        return LinksysIcons.signalWifi4Bar;
      case NodeSignalLevel.good:
        return LinksysIcons.networkWifi3Bar;
      case NodeSignalLevel.fair:
        return LinksysIcons.networkWifi2Bar;
      case NodeSignalLevel.poor:
        return LinksysIcons.networkWifi1Bar;
      case NodeSignalLevel.none:
        return LinksysIcons.signalWifi0Bar;
// Default
      case NodeSignalLevel.wired:
        return LinksysIcons.ethernet;
    }
  }
}

extension NodeSignalLevelExt on NodeSignalLevel {
  String resolveLabel(BuildContext context) {
    return switch (this) {
      NodeSignalLevel.excellent => loc(context).excellent,
      NodeSignalLevel.good => loc(context).good,
      NodeSignalLevel.poor => loc(context).poor,
      NodeSignalLevel.fair => loc(context).fair,
      NodeSignalLevel.wired => loc(context).wired,
      NodeSignalLevel.none => '',
    };
  }

  Color? resolveColor(BuildContext context) {
    return switch (this) {
      NodeSignalLevel.excellent => Theme.of(context).colorSchemeExt.green,
      NodeSignalLevel.good => Theme.of(context).colorSchemeExt.green,
      NodeSignalLevel.poor => Theme.of(context).colorScheme.error,
      NodeSignalLevel.fair => Theme.of(context).colorScheme.error,
      NodeSignalLevel.wired => Theme.of(context).colorScheme.onSurface,
      NodeSignalLevel.none => Colors.black,
    };
  }
}
