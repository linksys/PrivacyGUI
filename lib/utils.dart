import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:linksys_moab/bloc/node/state.dart';
import 'package:linksys_moab/constants/pref_key.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/model/router/device.dart';
import 'package:linksys_moab/network/http/model/cloud_app.dart';
import 'package:linksys_moab/network/http/model/cloud_login_certs.dart';
import 'package:linksys_moab/util/uuid.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bloc/device/state.dart';
import 'validator_rules/_validator_rules.dart';

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

  static String formatTimeInterval(int startTimeInSecond, int endTimeInSecond) {
    bool isNextDay = startTimeInSecond > endTimeInSecond;
    return '${formatTimeAmPm(startTimeInSecond)} - ${formatTimeAmPm(
        endTimeInSecond)} ${isNextDay ? 'next day' : ''}';
  }

  static String formatTimeAmPm(int timeInSecond) {
    final Duration timeAmount = Duration(seconds: timeInSecond);
    final String h =
    timeAmount.inHours.remainder(12).toString().padLeft(2, '0');
    final String m =
    timeAmount.inMinutes.remainder(60).toString().padLeft(2, '0');
    final String ampm = timeAmount.inHours.remainder(24) >= 12 ? 'pm' : 'am';
    return '$h:$m $ampm';
  }

  static String formatTimeHM(int timeInSecond) {
    final Duration timeAmount = Duration(seconds: timeInSecond);
    final String h =
    timeAmount.inHours.remainder(24).toString().padLeft(2, '0');
    final String m =
    timeAmount.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '$h hr,$m min';
  }

  static Map<String, bool> weeklyTransform(BuildContext context,
      List<bool> weeklyBool) {
    final weeklyStr = [
      getAppLocalizations(context).weekly_sunday,
      getAppLocalizations(context).weekly_monday,
      getAppLocalizations(context).weekly_tuesday,
      getAppLocalizations(context).weekly_wednesday,
      getAppLocalizations(context).weekly_thursday,
      getAppLocalizations(context).weekly_friday,
      getAppLocalizations(context).weekly_saturday,
    ];
    return weeklyBool
        .asMap()
        .map((key, value) => MapEntry(weeklyStr[key], value));
  }

  static List<String> toWeeklyStringList(BuildContext context,
      List<bool> weeklyBool) {
    final weeklyStr = [
      getAppLocalizations(context).weekly_sunday,
      getAppLocalizations(context).weekly_monday,
      getAppLocalizations(context).weekly_tuesday,
      getAppLocalizations(context).weekly_wednesday,
      getAppLocalizations(context).weekly_thursday,
      getAppLocalizations(context).weekly_friday,
      getAppLocalizations(context).weekly_saturday,
    ];
    return List.from(weeklyBool
        .asMap()
        .map((key, value) => MapEntry(weeklyStr[key], value))
        .entries
        .where((element) => element.value)
        .map((e) => e.key));
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
    return MediaQuery
        .of(context)
        .size;
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery
        .of(context)
        .size
        .width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery
        .of(context)
        .size
        .height;
  }

  static double getScreenRatio(BuildContext context) {
    return MediaQuery
        .of(context)
        .devicePixelRatio;
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
    return MediaQuery
        .of(context)
        .textScaleFactor;
  }

  static double getTopSafeAreaPadding(BuildContext context) {
    return MediaQuery
        .of(context)
        .padding
        .top;
  }

  static double getBottomSafeAreaPadding(BuildContext context) {
    return MediaQuery
        .of(context)
        .padding
        .bottom;
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

    return localeNames.length > 1 ? localeNames.first : Platform.localeName;
  }

  static String getCountryCode() {
    List<String> localeNames = Platform.localeName.split('_');

    return localeNames.length > 1 ? localeNames.last : Platform.localeName;
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
      'passphrase',
    ];
    return maskJsonValue(raw, keys);
  }

  static String replaceHttpScheme(String raw) {
    const pattern = '(^https?:)//';
    RegExp regex = RegExp(pattern, multiLine: true);
    String result = raw;
    regex.allMatches(raw).forEach((element) {
      final target = element.group(1);
      if (element.groupCount > 0 && target != null) {
        result = raw.replaceFirst(target, target.replaceFirst(':', '-'));
      }
    });
    return result;
  }

  static Future<bool> canUseBiometrics() async {
    final LocalAuthentication auth = LocalAuthentication();
    final List<BiometricType> availableBiometrics =
    await auth.getAvailableBiometrics();
    return await auth.canCheckBiometrics && availableBiometrics.isNotEmpty;
  }

  // TODO
  static Future<bool> doLocalAuthenticate() async {
    final LocalAuthentication auth = LocalAuthentication();
    final bool didAuthenticate = await auth.authenticate(
        localizedReason: "Please authenticate to go to next step");
    return didAuthenticate;
  }

  static Future<bool> checkCertValidation() async {
    const storage = FlutterSecureStorage();
    String? privateKey = await storage.read(key: moabPrefCloudPrivateKey);
    String? cert = await storage.read(key: moabPrefCloudCertDataKey);

    final prefs = await SharedPreferences.getInstance();
    bool isKeyExist = prefs.containsKey(moabPrefCloudPublicKey) &
    (privateKey != null) &
    (cert != null);
    if (!isKeyExist) {
      return false;
    }
    final certData = CloudDownloadCertData.fromJson(jsonDecode(cert ?? ''));
    final expiredDate = DateTime.parse(certData.expiration);
    if (expiredDate.millisecondsSinceEpoch -
        DateTime
            .now()
            .millisecondsSinceEpoch <
        0) {
      return false;
    }
    return true;
  }

  static String stringBase64Encode(String value) {
    return utf8.fuse(base64).encode(value);
  }

  static String stringBase64Decode(String base64String) {
    return utf8.fuse(base64).decode(base64String);
  }

  static String generateMqttClintId() {
    final platform = Platform.isIOS ? 'iOS' : 'Android';
    return '$platform-${uuid.v1()}';
  }

  static int ipToNum(String ipAddress) {
    final octets = ipAddress.split('.');
    if (octets.length < 4) {
      return 0;
    }
    return (((((int.parse(octets[0]) * 256) + int.parse(octets[1])) * 256) +
        int.parse(octets[2])) *
        256) +
        int.parse(octets[3]);
  }

  static String numToIp(int num) {
    var octets = '${num % 256}';
    for (var _ in [1, 2, 3]) {
      num = (num / 256).floor();
      octets = '${num % 256}.$octets';
    }
    return octets;
  }

  static bool ipInRange(ipAddress, ipAddressMin, ipAddressMax) {
    return ipToNum(ipAddress) >= ipToNum(ipAddressMin) &&
        ipToNum(ipAddress) <= ipToNum(ipAddressMax);
  }

  static bool isValidSubnetMask(String subnetMask,
      {int minNetworkPrefixLength = 8, int maxNetworkPrefixLength = 30}) {
    if (subnetMask.isEmpty) {
      return false;
    }

    if (minNetworkPrefixLength < 1 || minNetworkPrefixLength > 31) {
      throw Exception(
          'Invalid minNetworkPrefixLength passed, must be between 1 and 31');
    }
    if (maxNetworkPrefixLength < 1 || maxNetworkPrefixLength > 31) {
      throw Exception(
          'Invalid maxNetworkPrefixLength passed, must be between 1 and 31');
    }
    if (maxNetworkPrefixLength < minNetworkPrefixLength) {
      throw Exception(
          'maxNetworkPrefixLength cannot be less than minNetworkPrefixLength');
    }

    var subnetMaskBits = ipToNum(subnetMask).toRadixString(2);
    var prefixLength = subnetMaskBits.indexOf('0');
    if (prefixLength == -1) {
      return false;
    }
    final subnetMaskTestBits =
    List.filled(prefixLength, '1').join().padRight(32, '0');
    if (subnetMaskBits != subnetMaskTestBits ||
        prefixLength < minNetworkPrefixLength ||
        prefixLength > maxNetworkPrefixLength) {
      return false;
    }

    return true;
  }

  static String prefixLengthToSubnetMask(int prefixLength) {
    final subnetMaskTestBits =
    List.filled(prefixLength, '1').join().padRight(32, '0');
    return RegExp(r'.{1,8}')
        .allMatches(subnetMaskTestBits)
        .map((e) => int.parse(e.group(0)!, radix: 2))
        .toList().join('.');
  }

  static int subnetMaskToPrefixLength(String subnetMask) {
    final prefixLength = ipToNum(subnetMask).toRadixString(2).indexOf('0');

    if (!isValidSubnetMask(
        subnetMask, minNetworkPrefixLength: 1, maxNetworkPrefixLength: 31)) {
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
  static bool isRouterIPInDHCPRange(String routerIPAddress, String firstClientIPAddress, [String? lastClientIPAddress, int? maxUsers]) {
    final ipAddressNum = ipToNum(routerIPAddress);
    final firstClientIPAddressNum = ipToNum(firstClientIPAddress);
    final lastClientIPAddressNum = lastClientIPAddress != null ? ipToNum(lastClientIPAddress) : firstClientIPAddressNum + maxUsers! - 1;
    return ipAddressNum >= firstClientIPAddressNum && ipAddressNum <= lastClientIPAddressNum;
  }

  /*
     * @description returns an Integer for the max # of users allowed by the current DHCP Range
     * @params {String} routerIPAddress - A string representing the current IP of the Router
     * @params {String} firstClientIPAddress - A string representing the starting IP of the DHCP Range
     * @params {String} lastClientIPAddress - A string representing the end IP of the DHCP Range
     * @return {Integer}
  */
  static int getMaxUserForDHCPRange(String routerIPAddress, String firstClientIPAddress, String lastClientIPAddress) {
    final firstClientIPAddressNum = ipToNum(firstClientIPAddress);
    final lastClientIPAddressNum = ipToNum(lastClientIPAddress);
    var maxUsers = lastClientIPAddressNum - firstClientIPAddressNum;

    if (!isRouterIPInDHCPRange(routerIPAddress, firstClientIPAddress, lastClientIPAddress)) {
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
  static String getEndDHCPRangeForMaxUsers(String firstClientIPAddress, int maxUsers) {
    final firstClientIPAddressNum = ipToNum(firstClientIPAddress);
    final lastClientIPAddressNum = firstClientIPAddressNum + maxUsers - 1;

    return numToIp(lastClientIPAddressNum);
  }


  /*
     * @description returns an Integer for the max # of users that could be set, based on the 1st DHCP Client IP Address and the SubnetMask of the Router
     * @params {String} routerIPAddress - A string representing the current IP of the Router
     * @params {String} firstClientIPAddress - A string representing the starting IP of the DHCP Range
     * @params {String} subnetMask - A string representing the end IP of the DHCP Range
     * @params {Integer} maxUsers - An integer containing the current # of users the DHCP Range should allow
     * @return {Integer}
  */
  static int getMaxUserLimit(String routerIPAddress,
      String firstClientIPAddress, String subnetMask, int maxUsers) {
    final currentPrefixLength = subnetMaskToPrefixLength(subnetMask);
    int maxUserLimit = pow(2, 32 - currentPrefixLength).toInt();
    final subnetMaskNum = ipToNum(subnetMask);
    final firstClientIPAddressNum = ipToNum(firstClientIPAddress);
    final firstClientIPAddressBinary = firstClientIPAddressNum.toRadixString(2);

    final startingIPAddress = int.parse(
        subnetMaskNum.toRadixString(2).substring(0, currentPrefixLength) +
            firstClientIPAddressBinary.substring(firstClientIPAddressBinary.length - (32 -currentPrefixLength), firstClientIPAddressBinary.length), radix: 2) - subnetMaskNum;
    if (isRouterIPInDHCPRange(routerIPAddress, firstClientIPAddress, null, maxUsers)) {
      maxUserLimit--;
    }

    return maxUserLimit - startingIPAddress - 1;
  }

  static String getDevicePlace(RouterDevice device) {
    String place = '';
    for (PropertyDevice property in device.properties) {
      if (property.name == 'userDeviceLocation') {
        place = property.value;
        break;
      }
    }

    if (place.isEmpty) {
      place = getDeviceName(device);
    }
    return place;
  }

  static String getDeviceName(RouterDevice device) {
    for (PropertyDevice property in device.properties) {
      if (property.name == 'userDeviceName') {
        if (property.value.isNotEmpty) {
          return property.value;
        }
      }
    }

    String? deviceName;
    final friendlyName = device.friendlyName;
    final manufacturer = device.model.manufacturer;
    final modelNumber = device.model.modelNumber;
    final operatingSystem = device.unit.operatingSystem;
    String deviceType = device.model.deviceType;
    bool? isGuest;
    bool isAndroidName = false;

    for (ConnectionDevice connection in device.connections) {
      if (connection.isGuest != null) {
        isGuest = connection.isGuest;
        break;
      }
    }

    if (friendlyName != null) {
      isAndroidName =
          InputValidator([AndroidNameRule()]).validate(friendlyName);
    }

    if (['Mobile', 'Phone', 'Tablet'].contains(deviceType) && isAndroidName) {
      if (manufacturer != null && modelNumber != null) {
        deviceName = '$manufacturer $modelNumber';
      } else if (operatingSystem != null) {
        deviceName = '$operatingSystem $deviceType';
        if (manufacturer != null) {
          deviceName = '$manufacturer $deviceName';
        }
      }
    }

    if (deviceName != null) {
      return deviceName;
    } else if (friendlyName != null) {
      return friendlyName;
    } else if (modelNumber != null) {
      return modelNumber;
    } else if (isGuest != null) {
      return isGuest ? 'guestNetworkDevice' : 'networkDevice';
    } else {
      return 'networkDevice';
    }
  }

  static String getDeviceSignalImageString(DeviceDetailInfo deviceInfo) {
    String icon = 'icon_signal_wired';
    if (deviceInfo.connection == 'Wired') {
      icon = 'icon_signal_wired';
    } else {
      final signal = deviceInfo.signal;
      if (signal > 0) {
        if (signal > 40) {
          icon = 'icon_signal_excellent';
        } else if (signal > 30) {
          icon = 'icon_signal_good';
        } else if (signal > 20) {
          icon = 'icon_signal_fair';
        } else {
          icon = 'icon_signal_weak';
        }
      } else {
        if (signal > -50) {
          icon = 'icon_signal_excellent';
        } else if (signal > -60) {
          icon = 'icon_signal_good';
        } else if (signal > -70) {
          icon = 'icon_signal_fair';
        } else {
          icon = 'icon_signal_weak';
        }
      }
    }

    return icon;
  }

  static NodeSignalLevel getWifiSignalLevel(int signalStrength) {
    if (signalStrength <= -70) {
      return NodeSignalLevel.weak;
    } else if (signalStrength > -70 && signalStrength <= -60) {
      return NodeSignalLevel.fair;
    } else if (signalStrength > -60 && signalStrength <= -50) {
      return NodeSignalLevel.good;
    } else if (signalStrength > -50 && signalStrength <= 0) {
      return NodeSignalLevel.excellent;
    } else {
      return NodeSignalLevel.none;
    }
  }

  static String getWifiSignalImage(int signalStrength) {
    switch (getWifiSignalLevel(signalStrength)) {
      case NodeSignalLevel.excellent:
        return 'assets/images/icon_signal_excellent.png';
      case NodeSignalLevel.good:
        return 'assets/images/icon_signal_good.png';
      case NodeSignalLevel.fair:
        return 'assets/images/icon_signal_fair.png';
      case NodeSignalLevel.weak:
        return 'assets/images/icon_signal_weak.png';
      case NodeSignalLevel.none:
        return 'assets/images/icon_signal_excellent.png';  // Default
    }
  }

  static bool checkIfWiredConnection(RouterDevice device) {
    bool isWired = false;
    final interfaces = device.knownInterfaces;
    if (interfaces != null) {
      for (final interface in interfaces) {
        if (interface.interfaceType == 'Wired') {
          isWired = true;
        }
      }
    }
    return isWired;
  }

  //TODO: Check duplicate functions
  static String getDeviceLocation(RouterDevice device) {
    for (final property in device.properties) {
      if (property.name == 'userDeviceLocation' && property.value.isNotEmpty) {
        return property.value;
      }
    }
    return getDeviceName_(device);
  }

  static String getDeviceName_(RouterDevice device) {
    for (final property in device.properties) {
      if (property.name == 'userDeviceName' && property.value.isNotEmpty) {
        return property.value;
      }
    }

    bool isAndroidDevice = false;
    if (device.friendlyName != null) {
      final regExp = RegExp(r'^Android$|^android-[a-fA-F0-9]{16}.*|^Android-[0-9]+');
      isAndroidDevice = regExp.hasMatch(device.friendlyName!);
    }

    String? androidDeviceName;
    if (isAndroidDevice &&
        ['Mobile', 'Phone', 'Tablet'].contains(device.model.deviceType)) {
      final manufacturer = device.model.manufacturer;
      final modelNumber = device.model.modelNumber;
      if (manufacturer != null && modelNumber != null) {
        // e.g. 'Samsung Galaxy S8'
        androidDeviceName = manufacturer + ' ' + modelNumber;
      } else if (device.unit.operatingSystem != null) {
        // e.g. 'Android Oreo Mobile'
        androidDeviceName =
            device.unit.operatingSystem! + ' ' + device.model.deviceType;
        if (manufacturer != null) {
          // e.g. 'Samsung Android Oreo Mobile'
          androidDeviceName = manufacturer! + androidDeviceName!;
        }
      }
    }

    if (androidDeviceName != null) {
      return androidDeviceName;
    } else if (device.friendlyName != null) {
      return device.friendlyName!;
    } else if (device.model.modelNumber != null) {
      return device.model.modelNumber!;
    } else {
      // Check if it's a guest device
      bool isGuest = false;
      for (final connectionDevice in device.connections) {
        isGuest = connectionDevice.isGuest ?? false;
      }
      return isGuest ? 'Guest Network Device' : 'Network Device';
    }
  }

  // String converter
  static String fullStringEncoded(String value) {
    final utf8Encoded = String.fromCharCodes(Uint8List.fromList(utf8.encode(value)));
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
}
