import 'dart:convert';
import 'dart:io';

import 'package:privacy_gui/utils.dart';

abstract class ValidationRule {
  String get name => runtimeType.toString();

  bool validate(String input);
}

abstract class RegExValidationRule extends ValidationRule {
  RegExp get _rule;

  bool get notCheck => false;

  RegExp get rule => _rule;

  @override
  bool validate(String input) =>
      notCheck ? !_rule.hasMatch(input) : _rule.hasMatch(input);
}

class EmailRule extends RegExValidationRule {
  @override
  String get name => 'EmailRule';

  @override
  RegExp get _rule => RegExp(
      r"^[a-zA-Z0-9.!#$%&‘*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$");
}

class DigitalCheckRule extends RegExValidationRule {
  @override
  String get name => 'DigitalCheckRule';

  @override
  RegExp get _rule => RegExp(r".*\d+.*");
}

class SpecialCharCheckRule extends RegExValidationRule {
  @override
  String get name => 'SpecialCharCheckRule';

  @override
  RegExp get _rule => RegExp(r".*[^a-zA-Z0-9 ]+.*");
// From current linksys app
// RegExp regEx = RegExp(
//     r"(?=.*?[\x20-\x29\x2A-\x2F\x3A-\x3F\x40\x5B-\x5F\x60\x7D-\x7E])\w+");
}

class WiFiPasswordRule extends RegExValidationRule {
  @override
  String get name => 'WiFiPasswordRule';

  final bool ignoreLength;
  final bool ignoreWhiteSpaceSurround;
  WiFiPasswordRule({
    this.ignoreLength = false,
    this.ignoreWhiteSpaceSurround = false,
  });
  @override
  RegExp get _rule => RegExp(ignoreLength
      ? r"^(?! )[\x20-\x7e]+(?<! )$"
      : r"^(?! )[\x20-\x7e]{8,64}(?<! )$");
}

class WiFiSsidRule extends RegExValidationRule {
  @override
  String get name => 'WiFiSsidRule';

  @override
  RegExp get _rule => RegExp(r"^(?!\s).{0,31}\S$");
}

class IpAddressRule extends RegExValidationRule {
  @override
  String get name => 'IpAddressRule';

  @override
  RegExp get _rule => RegExp(
      r"^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$");
}

class NoSurroundWhitespaceRule extends RegExValidationRule {
  @override
  String get name => 'NoSurroundWhitespaceRule';

  @override
  bool notCheck = true;

  @override
  RegExp get _rule => RegExp(r'^\s+|\s+$');
}

class AndroidNameRule extends RegExValidationRule {
  @override
  String get name => 'AndroidNameRule';

  @override
  RegExp get _rule =>
      RegExp(r"^Android$|^android-[a-fA-F0-9]{16}.*|^Android-[0-9]+");
}

class AsciiRule extends RegExValidationRule {
  @override
  String get name => 'AsciiRule';

  @override
  RegExp get _rule => RegExp(r'^[\x20-\x7E]+$');
}

class WhiteSpaceRule extends RegExValidationRule {
  @override
  String get name => 'WhiteSpaceRule';

  @override
  RegExp get _rule => RegExp(r'.*[\s]+.*');
}

class HostNameRule extends RegExValidationRule {
  @override
  String get name => 'HostNameRule';

  @override
  RegExp get _rule => RegExp(r'[^a-zA-Z0-9-]+|^-|-$');
}

class ConsecutiveCharRule extends RegExValidationRule {
  @override
  String get name => 'ConsecutiveCharRule';

  @override
  RegExp get _rule => RegExp(r'(.)\1{1}');
}

class MACAddressRule extends RegExValidationRule {
  @override
  String get name => 'MACAddressRule';

  @override
  RegExp get _rule => RegExp(r"^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$");
}

class IPv6WithReservedRule extends ValidationRule {
  @override
  String get name => 'IPv6WithReservedRule';

  @override
  bool validate(String input) {
    try {
      final InternetAddress ipv6;
      try {
        // Attempt to parse the string as an IPv6 address.
        // InternetAddress will throw an ArgumentError if the format is invalid.
        ipv6 = InternetAddress(input, type: InternetAddressType.IPv6);
      } on ArgumentError {
        return false;
      }

      // Ensure the parsed address is indeed an IPv6 type, not IPv4 or invalid.
      if (ipv6.type != InternetAddressType.IPv6) {
        return false;
      }

      // --- Rule Checks based on IPv6 Address Properties/Bytes ---

      // Rule: Must not be from reserved/special ranges

      // 1. Loopback (::1)
      if (ipv6.isLoopback) {
        return false;
      }

      // 2. Link-local (fe80::/10)
      // dart:io provides this property directly.
      if (ipv6.isLinkLocal) {
        return false;
      }

      // 3. Multicast (ff00::/8)
      // dart:io provides this property directly.
      if (ipv6.isMulticast) {
        return false;
      }

      // Get the raw bytes for manual prefix checks
      final rawAddress = ipv6.rawAddress; // Uint8List of 16 bytes

      // 4. ULA (Unique Local Address) fc00::/7
      // ULA addresses start with binary 1111 110 (FCxx or FDxx).
      // This means the first byte will be 0xFC or 0xFD.
      if (rawAddress[0] == 0xFC || rawAddress[0] == 0xFD) {
        return false;
      }

      // Rule: Must not be :: or all-zeros prefix ::/0 (Unspecified address)
      // InternetAddress doesn't have a direct `isUnspecified` property.
      // We check if all 16 bytes are zero.
      if (rawAddress.every((byte) => byte == 0)) {
        return false;
      }

      // Rule: Should not come from unallocated or deprecated address space
      // Check for ffff::/16 (unallocated)
      if (rawAddress[0] == 0xFF && rawAddress[1] == 0xFF) {
        return false;
      }

      // Check for 3ffe::/16 (6bone - deprecated IPv6 testing network)
      if (rawAddress[0] == 0x3F && rawAddress[1] == 0xFE) {
        return false;
      }

      // Check for other reserved ranges within 2000::/3
      // 5F00::/12 - 5FFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF
      if (rawAddress[0] == 0x5F ||
          (rawAddress[0] >= 0x60 && rawAddress[0] <= 0x7F)) {
        return false;
      }

      // Rule: Must be a Global Unicast
      // After excluding all the specific reserved/special addresses,
      // a common characteristic of Global Unicast addresses is they fall within 2000::/3.
      // This means the first byte (most significant 8 bits) starts with binary '001'.
      // So, the first byte's value should be between 0x20 and 0x3F (inclusive).
      if (rawAddress[0] < 0x20 || rawAddress[0] > 0x3F) {
        return false;
      }

      // If all checks pass, the address is considered a valid global unicast.
      return true;
    } catch (e) {
      // Catch any other unexpected errors during the process
      return false;
    }
  }
}

class MACAddressWithReservedRule extends ValidationRule {
  @override
  String get name => 'MACAddressWithReservedRule';

  @override
  bool validate(String input) {
    // 1. check if mac address is in a valid format
    if (!MACAddressRule().validate(input)) {
      return false;
    }
    // 2. check if it's all zeros
    if (input == '00:00:00:00:00:00') {
      return false;
    }
    // 3. check if it's a multicast (the least significant bit of the most significant address octet is set to 1)
    var firstOctet = input.split(':')[0],
        firstOctetInBinary =
            int.parse(firstOctet, radix: 16).toString().padRight(2),
        leastSignificantBit =
            firstOctetInBinary.substring(firstOctetInBinary.length - 1);
    if (leastSignificantBit == '1') {
      return false;
    }
    // 4. check if second character is 0, 2, 4, 6, 8, A, C, E
    var secondCharacter =
        firstOctet.substring(firstOctet.length - 1).toUpperCase();
    if (secondCharacter != '0' &&
        secondCharacter != '2' &&
        secondCharacter != '4' &&
        secondCharacter != '6' &&
        secondCharacter != '8' &&
        secondCharacter != 'A' &&
        secondCharacter != 'C' &&
        secondCharacter != 'E') {
      return false;
    }
    return true;
  }
}

class LengthRule extends ValidationRule {
  final int min;
  final int max;

  LengthRule({this.min = 10, this.max = 0});
  @override
  String get name => 'LengthRule';

  @override
  bool validate(String input) {
    final encoded = utf8.encode(input);
    return max > 0
        ? encoded.length >= min && encoded.length <= max
        : encoded.length >= min;
  }
}

class HybridCaseRule extends ValidationRule {
  @override
  String get name => 'HybridCaseRule';

  @override
  bool validate(String input) {
    return input != input.toUpperCase() && input != input.toLowerCase();
  }
}

class IpAddressHasFourOctetsRule extends ValidationRule {
  @override
  String get name => 'IpAddressHasFourOctetsRule';

  @override
  bool validate(String input) => input.split('.').length == 4;
}

class SubnetMaskRule extends ValidationRule {
  @override
  String get name => 'SubnetMaskRule';

  final int minNetworkPrefixLength;
  final int maxNetworkPrefixLength;

  SubnetMaskRule({
    this.minNetworkPrefixLength = 8,
    this.maxNetworkPrefixLength = 30,
  });

  @override
  bool validate(String input) {
    try {
      return NetworkUtils.isValidSubnetMask(
        input,
        minNetworkPrefixLength: minNetworkPrefixLength,
        maxNetworkPrefixLength: maxNetworkPrefixLength,
      );
    } catch (e) {
      return false;
    }
  }
}

class RequiredRule extends ValidationRule {
  @override
  String get name => 'RequiredRule';
  @override
  bool validate(String input) {
    return input.isNotEmpty;
  }
}

/// Validates an IPv4 address string against specified rules:
/// 1. Must be a correct IPv4 format.
/// 2. Cannot be from reserved or special-use ranges:
///    - 0.0.0.0/8 (Current Network / Unspecified)
///    - 127.0.0.0/8 (Loopback)
///    - 224.0.0.0/4 (Multicast)
///    - 255.255.255.255 (Broadcast)
class IpAddressNoReservedRule extends ValidationRule {
  @override
  String get name => 'IpAddressNoReservedRule';
  @override
  bool validate(String input) {
    try {
      final InternetAddress ipv4;
      try {
        // Attempt to parse the string as an IPv4 address.
        // InternetAddress will throw an ArgumentError if the format is invalid.
        ipv4 = InternetAddress(input, type: InternetAddressType.IPv4);
      } on ArgumentError {
        print(
            'Reject: Invalid IPv4 format (ArgumentError caught during parsing).');
        return false;
      }

      // Ensure the parsed address is indeed an IPv4 type.
      if (ipv4.type != InternetAddressType.IPv4) {
        print(
            'Reject: Input is not an IPv4 address after parsing (unexpected type).');
        return false;
      }

      // Get the raw bytes of the IPv4 address for prefix and specific value checks.
      final rawAddress = ipv4.rawAddress; // Uint8List of 4 bytes

      // --- Rule Checks based on IPv4 Address Properties/Bytes ---

      // 1. Check for 0.0.0.0/8 (Current Network / Unspecified / This Host)
      // This range includes any address where the first octet is 0.
      if (rawAddress[0] == 0x00) {
        print(
            'Reject: Falls within 0.0.0.0/8 range (Unspecified/Current Network).');
        return false;
      }

      // 2. Check for 127.0.0.0/8 (Loopback)
      // dart:io provides this property directly.
      if (ipv4.isLoopback) {
        print('Reject: Loopback address (127.0.0.0/8).');
        return false;
      }

      // 3. Check for 224.0.0.0/4 (Multicast)
      // dart:io provides this property directly.
      if (ipv4.isMulticast) {
        print('Reject: Multicast address (224.0.0.0/4).');
        return false;
      }

      // 4. Check for 255.255.255.255 (Limited Broadcast)
      // Manually check if all four bytes are 255 (0xFF).
      if (rawAddress[0] == 0xFF &&
          rawAddress[1] == 0xFF &&
          rawAddress[2] == 0xFF &&
          rawAddress[3] == 0xFF) {
        print('Reject: Limited Broadcast address (255.255.255.255).');
        return false;
      }

      // If all checks pass, the address is considered valid.
      print(
          'Accept: IPv4 address is valid and not from specified reserved/special ranges.');
      return true;
    } catch (e) {
      // Catch any other unexpected errors during the process (e.g., if rawAddress access fails unexpectedly)
      print('An unexpected error occurred during IPv4 validation: $e');
      return false;
    }
  }
}

class HostValidForGivenRouterIPAddressAndSubnetMaskRule extends ValidationRule {
  @override
  String get name => 'HostValidForGivenRouterIPAddressAndSubnetMaskRule';
  final String routerIPAddress;
  final String subnetMask;

  HostValidForGivenRouterIPAddressAndSubnetMaskRule(
      this.routerIPAddress, this.subnetMask);

  @override
  bool validate(String input) {
    final hostIPAddressNum = NetworkUtils.ipToNum(input);
    final routerIPAddressNum = NetworkUtils.ipToNum(routerIPAddress);
    final subnetMaskNum = NetworkUtils.ipToNum(subnetMask);
    final hostSubnet = (hostIPAddressNum & subnetMaskNum) >>> 0;
    final routerSubnet = (routerIPAddressNum & subnetMaskNum) >>> 0;

    return (hostSubnet == routerSubnet) &&
        _isIPValidForSubnet(hostIPAddressNum, subnetMaskNum);
  }

  bool _isIPValidForSubnet(int ipAddressNum, int subnetMaskNum) {
    final networkIdNum = (ipAddressNum & subnetMaskNum) >>> 0;
    final broadcastIdNum = (~subnetMaskNum | networkIdNum) >>> 0;
    return ipAddressNum != networkIdNum && ipAddressNum != broadcastIdNum;
  }
}

class NotRouterIpAddressRule extends ValidationRule {
  final String routerIpAddress;

  bool get notCheck => true;
  @override
  String get name => 'NotRouterIpAddressRule';

  NotRouterIpAddressRule(this.routerIpAddress);

  @override
  bool validate(String input) {
    final ipAddressOctets = input.split('.');
    final routerIPAddressOctets = routerIpAddress.split('.');
    if (ipAddressOctets.length < 4) {
      return true;
    }
    if (routerIPAddressOctets.length < 4) {
      return true;
    }
    for (var i = 0; i < 4; i++) {
      if (routerIPAddressOctets[i] != ipAddressOctets[i]) {
        return true;
      }
    }
    return false;
  }
}

class IntegerRule extends ValidationRule {
  final int min;
  final int max;

  IntegerRule({this.min = -1, this.max = -1});
  @override
  String get name => 'IntegerRule';
  @override
  bool validate(String input) {
    final num = int.tryParse(input);
    if (num != null) {
      return (min == -1 ? true : num >= min) && (max == -1 ? true : num <= max);
    }
    return false;
  }
}
