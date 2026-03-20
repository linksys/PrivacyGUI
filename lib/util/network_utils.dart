import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:privacy_gui/util/uuid.dart';

class NetworkUtils {
  static String formatBits(int bits, {int decimals = 0}) {
    final result = formatBitsWithUnit(bits, decimals: decimals);
    return '${result.value} ${result.unit}';
  }

  static ({String value, String unit}) formatBitsWithUnit(int bits,
      {int decimals = 0}) {
    if (bits <= 0) return (value: '0', unit: "b");
    const suffixes = ["b", "kb", "Mb", "Gb", "Tb", "Pb"];
    var i = (log(bits) / log(1000)).floor();
    var number = (bits / pow(1000, i));
    return (
      value: number
          .toStringAsFixed(number.truncateToDouble() == number ? 0 : decimals),
      unit: suffixes[i]
    );
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
